# Parte 2: Infraestrutura e Mensageria

## Escopo e arquitetura

O Compose inicia a aplicacao atual como servico de agendamento (`web`), uma aplicacao Rails API minima em `services/triagem`, um PostgreSQL para cada servico, RabbitMQ e um publicador Outbox por banco. As aplicacoes compartilham imagem, Gemfile/lockfile e biblioteca de transporte em `shared/`; nao compartilham tabelas, conexoes ou credenciais de banco. A triagem possui apenas endpoints de saude e a Outbox: os consumidores, validacoes e SAGA serao implementados na Parte 3.

Os nomes `web` e `db` continuam funcionando para os comandos existentes. O volume PostgreSQL anterior do agendamento e preservado. Os servicos `*-setup` executam migrations uma unica vez por subida e encerram com codigo zero; os servidores e workers aguardam sua conclusao. O `messaging-setup` declara a topologia antes dos publicadores. O agendamento aceita gravacoes mesmo durante uma indisponibilidade posterior do broker.

## Executar

```bash
docker compose up --build -d --wait
docker compose ps -a
curl --fail http://localhost:3000/ready
curl --fail http://localhost:3001/ready
```

- Agendamento/API: http://localhost:3000 (a home ainda nao foi implementada).
- Triagem: http://localhost:3001/ready (sem endpoints de negocio nesta etapa).
- RabbitMQ Management: http://localhost:15672, usuario `psiline`, senha `psiline_local`, vhost `psiline`.
- PostgreSQL: portas locais 5432 (agendamento) e 5433 (triagem).

`.env.example` lista portas e credenciais locais configuraveis; o Compose funciona sem arquivo `.env`. As portas sao publicadas apenas em loopback. Caso uma porta esteja ocupada, por exemplo, execute `WEB_PORT=3010 docker compose up -d`. A imagem contem o codigo, sem bind mount: refaca `docker compose up --build -d` depois de editar arquivos.

Para executar o publicador fora do Docker, configure `RABBITMQ_URL=amqp://psiline:psiline_local@localhost:5672/psiline` e execute `bundle exec rake messaging:publish` na raiz do servico desejado. `OUTBOX_POLL_SECONDS` controla o intervalo entre lotes (padrao 1 segundo). O Compose ja define a URL interna e o `SERVICE_NAME` correto para cada servico.

Healthchecks verificam os bancos, o processo RabbitMQ, os endpoints `/ready` com consulta ao banco de cada aplicacao e o heartbeat dos publicadores. `/up` verifica somente o boot Rails. O heartbeat indica progresso do worker, nao entrega garantida: acompanhe tambem quantidade de eventos pendentes, `attempts` e `last_error`.

```bash
docker compose logs -f agendamento-outbox triagem-outbox
docker compose exec web bin/rails runner 'puts Messaging::OutboxEvent.where(published_at: nil).group(:last_error).count'
docker compose exec rabbitmq rabbitmqctl list_queues -p psiline name messages_ready messages_unacknowledged
```

## Topologia RabbitMQ

Exchange topic duravel `psiline.events`. Cada consumidor possui uma fila propria, evitando que triagem e read model disputem a mesma mensagem.

| Fila duravel | Routing keys |
|---|---|
| `psiline.triagem` | `consulta.reserva_criada` |
| `psiline.agendamento` | `triagem.aprovada`, `triagem.reprovada` |
| `psiline.read_model` | Os cinco eventos do contrato |

Cada fila possui uma fila duravel `<nome>.dead`, ligada ao exchange topic `psiline.dead`. Um consumidor pode enviar mensagem invalida para ela usando `reject(requeue: false)` ou `nack(requeue: false)`. Falhas transitorias precisam de politica de retentativa do consumidor (Parte 3); nao ha loop de requeue automatico implementado aqui. Nao ha consumidores de negocio rodando nesta entrega, portanto as filas acumulam mensagens ate as proximas partes serem integradas.

Declaracoes sao idempotentes e tambem executadas pelo publicador ao conectar, permitindo recriar a topologia depois de recuperar o broker. As mensagens sao persistentes e a publicacao usa `mandatory: true`, verifica retornos sem rota e aguarda publisher confirms com limite de 10 segundos. Uma mensagem sem rota ou com confirm negativo nao e marcada como publicada.

## Contrato de eventos v1

Schema do envelope: [event-v1.schema.json](contracts/event-v1.schema.json). A routing key e igual a `event_type`; o AMQP `message_id` e igual a `event_id`. IDs de consulta no envelope sao strings, mesmo quando a chave do banco e inteira.

```json
{
  "event_id": "9bd5ea7a-3dfa-459f-91d5-a33c606d6781",
  "event_type": "consulta.reserva_criada",
  "consulta_id": "42",
  "occurred_at": "2026-11-18T13:00:00.000000Z",
  "version": 1,
  "producer": "agendamento",
  "data": {
    "estagiario_id": 4,
    "professor_id": 2,
    "inicio": "2026-11-20T13:00:00Z",
    "fim": "2026-11-20T13:50:00Z",
    "sala": "Sala 1",
    "status": "agendada",
    "paciente": { "nome": "Paciente de exemplo", "email": null, "telefone": null }
  }
}
```

O agendamento ja emite o snapshot acima na criacao da consulta e nas mudancas para `confirmada` ou `cancelada`, pelos services existentes. A integracao nao muda o fluxo sincrono atual: `agendada` ainda e o estado inicial. A Parte 1 deve evoluir isso para a reserva pendente de triagem e emitir os eventos finais pela SAGA. Edicoes sem mudanca de status e exclusoes nao emitem eventos neste contrato; a Parte 4 deve combinar eventos adicionais caso seu read model precise acompanhar essas operacoes. Registros anteriores a esta entrega nao sao reenviados automaticamente; eventual carga inicial da projecao deve ser combinada com a Parte 4.

Proposta para os resultados da Parte 3: `triagem.aprovada` usa `data.reserva_event_id` para correlacionar a reserva original; `triagem.reprovada` inclui tambem `data.motivo`. O envelope e validado pelo model e pelo banco; campos especificos do payload de triagem devem ser validados pelo produtor/consumidor implementado pela equipe. `consulta.reserva_cancelada` devera incluir `data.motivo` quando emitido pela compensacao. Estes campos sao o ponto de acordo para os colegas, nao uma implementacao da SAGA.

## API da Outbox e atomicidade

Em qualquer um dos servicos, grave o dominio e o evento no mesmo banco e na mesma transacao:

```ruby
ActiveRecord::Base.transaction do
  reserva.save!
  Messaging::Outbox.record!(
    event_type: "consulta.reserva_criada",
    consulta_id: reserva.id,
    data: { sala: reserva.sala }
  )
end
```

`record!` exige uma transacao aberta. A biblioteca nao conecta ao RabbitMQ no caminho de gravacao. Um rollback remove tanto a alteracao de dominio quanto seu evento. Nao publique diretamente do controller ou de callbacks `after_commit`, pois isso perderia a atomicidade entre dominio e registro do evento.

O publicador busca pendencias com `FOR UPDATE SKIP LOCKED`, mantendo o lock durante envio/confirmacao e atualizacao. Workers concorrentes pulam as linhas ja bloqueadas. Falhas deixam `published_at` vazio, incrementam `attempts` e programam uma retentativa exponencial entre 2 e 300 segundos, sem limite de tentativas. Um erro no banco apos o confirm causa rollback e permite reenvio.

A entrega e **pelo menos uma vez**, nao exatamente uma vez: se o broker confirmar e o processo cair antes de atualizar a Outbox, o mesmo evento sera reenviado. O `event_id` permanece identico; consumidores devem registrar um indice unico por `event_id` e aplicar seus efeitos na mesma transacao local, dando ACK somente depois do commit (Parte 3/4). Eventos distintos nao possuem garantia global de ordem; o read model/SAGA deve validar transicoes e tratar eventos fora de ordem. Uma nova versao do contrato sera necessaria caso a equipe exija sequenciamento por consulta.

Os eventos carregam dados do paciente para a integracao prevista do read model. Nao registre payloads em logs; controle acesso ao broker e defina retencao das filas e eventos publicados antes de usar dados reais. O Compose e um ambiente local de um unico no RabbitMQ, sem configuracao de alta disponibilidade.

## Demonstracao de falha e recuperacao

1. Suba o ambiente e pare apenas o broker: `docker compose stop rabbitmq`.
2. Crie uma consulta pela API atual, usando os acessos do README e um horario futuro livre. Ela deve ser salva; o evento fica na Outbox.
3. Confira as pendencias com o comando `runner` acima. Depois de uma tentativa, `attempts` e `last_error` registram a falha.
4. Execute `docker compose start rabbitmq`. O worker reconecta e reenvia automaticamente, respeitando `available_at` (ate 300 segundos).
5. Verifique `published_at` e a mensagem nas filas `psiline.triagem` e `psiline.read_model` no painel RabbitMQ.

Para processar uma rodada manualmente, use `docker compose exec web bundle exec rake messaging:publish_once`. Isso respeita os locks e a data da proxima tentativa. O worker pode estar executando ao mesmo tempo, portanto nao espere uma contagem fixa de mensagens processadas pelo comando manual.

## Testes

Testes normais (sem exigir RabbitMQ):

```bash
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec -e RAILS_ENV=test web bundle exec rspec
docker compose exec -e RAILS_ENV=test triagem ruby bin/rails db:prepare
docker compose exec -e RAILS_ENV=test triagem bundle exec rspec spec
```

Para habilitar os testes reais de publicacao/roteamento, crie um vhost exclusivo de teste (nao use o de desenvolvimento):

```bash
docker compose exec rabbitmq rabbitmqctl add_vhost psiline_test
docker compose exec rabbitmq rabbitmqctl set_permissions -p psiline_test psiline '.*' '.*' '.*'
docker compose exec -e RAILS_ENV=test -e RABBITMQ_TEST_URL=amqp://psiline:psiline_local@rabbitmq:5672/psiline_test web bundle exec rspec
```

Se alterar as credenciais locais, ajuste esses comandos. O CI usa um vhost de teste isolado e executa os testes reais. A suite cobre atomicidade, rollback, envelopes, eventos de dominio, retentativas, confirm negativo, mensagem sem rota, concorrencia entre workers, dead-letter e roteamento real para as filas. Sem `RABBITMQ_TEST_URL`, apenas os testes de integracao com broker ficam pendentes.

## Divisao com os colegas

- Parte 1: evoluir `Consultas::Agendar`/`Atualizar`, os estados e endpoints; manter `RegistrarEvento` dentro da transacao. Nao conectar ao banco da triagem.
- Parte 3: colocar os models/migrations/consumidores em `services/triagem`; consumir `psiline.triagem`, gravar efeitos e resultados na Outbox local. O consumidor de resultados da SAGA deve atuar no servico de agendamento, sem escrever no banco alheio.
- Parte 4: consumir `psiline.read_model` e armazenar sua projecao local; nao ler as tabelas do servico vizinho.

As migrations compartilhadas da infraestrutura estao em `shared/migrations`; cada app possui seu `db/schema.rb`. A triagem nao carrega os models, Devise ou assets do agendamento. Compartilhar a biblioteca nao autoriza acessos entre bancos.

Referencias tecnicas: [publisher confirms](https://www.rabbitmq.com/tutorials/tutorial-seven-ruby) e [publicadores, mensagens sem rota e seguranca de entrega](https://www.rabbitmq.com/docs/publishers).
