# Serviço de Triagem e SAGA (Parte 3)

Serviço responsável por **validar as reservas de consulta** criadas pelo serviço de agendamento e por participar da **SAGA** que confirma ou cancela cada reserva. Tem banco de dados próprio e se comunica com os outros serviços apenas por eventos no RabbitMQ.

> **Status:** código completo, mas os testes (`bundle exec rspec`) **ainda não foram executados**. Rodar a suíte é o primeiro passo antes do merge.

## O que o serviço faz

- Consome `consulta.reserva_criada` do RabbitMQ.
- **Consumidor idempotente:** cada `event_id` é registrado em `processed_events` (índice único). A mesma mensagem nunca gera duas triagens nem dois efeitos.
- Valida sala, supervisor, horário e disponibilidade do estagiário e da sala.
- Publica `triagem.aprovada` ou `triagem.reprovada` pelo padrão **Outbox**.
- Acompanha a **SAGA** de cada reserva e libera o horário quando a reserva é cancelada (compensação).

## Fluxo

```text
consulta.reserva_criada
        ↓
Consumo idempotente (event_id)
        ↓
Triagem (sala, supervisor, horário, disponibilidade)
        ↓
Grava avaliação + SAGA + Outbox (uma única transação)
        ↓
Publicador envia triagem.aprovada | triagem.reprovada
        ↓
Agendamento confirma ou cancela (compensação)
        ↓
consulta.reserva_confirmada | consulta.reserva_cancelada
        ↓
Triagem fecha a SAGA e libera o horário, se cancelada
```

## Regras de triagem

| Código de reprovação | Regra |
|---|---|
| `PAYLOAD_INVALIDO` | dados do evento incompletos ou inválidos |
| `HORARIO_NO_PASSADO` | início já passou |
| `DURACAO_INVALIDA` | duração fora de 30 min a 2 h |
| `FORA_DO_EXPEDIENTE` | fora de 8h–20h |
| `SALA_INDISPONIVEL` | sala inexistente ou inativa |
| `SUPERVISOR_INVALIDO` | professor não é o supervisor ativo do estagiário |
| `ESTAGIARIO_OCUPADO` | estagiário já tem reserva aprovada no horário |
| `SALA_OCUPADA` | sala já reservada no horário |
| `HORARIO_CONFLITANTE` | duas aprovações simultâneas (barrada pelo banco) |

## Estados da SAGA

```text
AGUARDANDO_TRIAGEM ─▶ TRIAGEM_APROVADA ─▶ CONFIRMADA
                  │            └────────▶ CANCELADA
                  ├─▶ TRIAGEM_REPROVADA ─▶ COMPENSADA
                  └─▶ CANCELADA
```

## Contrato dos eventos

Todos os eventos têm: `event_id`, `event_type`, `event_version`, `consulta_id`, `occurred_at` e `data` (e opcionalmente `causation_id`).

| Evento | Produtor | `data` |
|---|---|---|
| `consulta.reserva_criada` | Agendamento | `paciente_nome`, `estagiario_id`, `professor_id`, `sala`, `inicio`, `fim` |
| `triagem.aprovada` | Triagem | `estagiario_id`, `professor_id`, `sala`, `inicio`, `fim` |
| `triagem.reprovada` | Triagem | os mesmos campos + `motivo_codigo`, `motivo_detalhe` |
| `consulta.reserva_confirmada` | Agendamento | livre |
| `consulta.reserva_cancelada` | Agendamento | livre |

## Broker (RabbitMQ)

| Item | Nome |
|---|---|
| Exchange (topic) | `psiline.events` |
| Fila da triagem | `triagem.eventos` |
| Dead-letter | `psiline.events.dlx` / `triagem.eventos.dlq` |

Os nomes podem ser trocados por variável de ambiente (`EVENTS_EXCHANGE`, `TRIAGEM_QUEUE`, `RABBITMQ_URL`). Se a infraestrutura já criar as filas, use `DECLARE_TOPOLOGY=false`.

## Como executar

```bash
cd triagem
docker compose up --build
```

- API de consulta: `http://localhost:3100/api/v1/triagens/:consulta_id`
- Painel do RabbitMQ: `http://localhost:15673` (guest / guest)

Cenários de demonstração (o simulador faz o papel do agendamento):

```bash
docker compose exec triagem-web bin/rails "triagem:simular[sucesso]"
docker compose exec triagem-web bin/rails "triagem:simular[sala_invalida]"
docker compose exec triagem-web bin/rails "triagem:simular[conflito]"
docker compose exec triagem-web bin/rails "triagem:simular[duplicada]"
docker compose exec triagem-web bin/rails "triagem:simular[confirmar,ID_DA_CONSULTA]"
docker compose exec triagem-web bin/rails "triagem:simular[cancelar,ID_DA_CONSULTA]"
```

## Testes

```bash
docker compose run --rm --no-deps -e RAILS_ENV=test triagem-web bash -lc "bin/rails db:prepare && bundle exec rspec"
```

Cobertura: sucesso, cada motivo de reprovação, reprocessamento da mesma mensagem, mesma consulta com outro `event_id`, compensação, liberação do horário, transições inválidas da SAGA, outbox, publicador e decisão de ack/DLQ.

## Pendências e dependências

- Rodar a suíte de testes e corrigir eventuais ajustes.
- **Parte 1:** consumir `triagem.reprovada` (cancelar a reserva) e `triagem.aprovada` (confirmar).
- **Parte 2:** criar filas e bindings do agendamento e do read model; incorporar estes serviços ao Docker Compose oficial.
- **Parte 4:** usar `motivo_codigo` e `motivo_detalhe` de `triagem.reprovada` no read model.
- Os dados de referência (`salas`, `supervisoes`) vêm de `db/seeds.rb` e assumem os ids dos seeds do agendamento.

Documentação detalhada: [`docs/triagem-saga.md`](../docs/triagem-saga.md).
