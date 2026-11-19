# ADR 0003: Bancos independentes, RabbitMQ e Outbox

* Status: Aceito para a infraestrutura da Sprint 2
* Data: 2026-11-18

## Contexto

A Sprint 2 exige servicos de agendamento e triagem, broker, Outbox, consumidores idempotentes, SAGA e read model. A Parte 2 prepara o ambiente e o transporte sem assumir as regras de negocio das Partes 1, 3 e 4.

## Decisao

Preservar o Rails existente como servico de agendamento e criar uma base Rails API isolada para triagem. Cada servico utiliza seu PostgreSQL e sua tabela Outbox. Compartilhar imagem, dependencias e biblioteca Ruby de mensageria no monorepo; nao compartilhar models de dominio ou conexoes de banco.

Usar RabbitMQ com exchange topic, filas duraveis por consumidor, filas de dead-letter e mensagens persistentes. Gravar eventos na mesma transacao das mudancas de dominio. Publicadores separados usam locks PostgreSQL com SKIP LOCKED, confirmacao do broker, deteccao de mensagens sem rota e retentativa exponencial.

## Consequencias

O broker pode ficar indisponivel sem impedir a gravacao de reservas no agendamento. Entrega pelo menos uma vez exige idempotencia e transacoes locais nos consumidores. A SAGA e as projecoes devem lidar com duplicacao e possivel inversao de ordem. Uma queda depois do confirm e antes da atualizacao da Outbox pode produzir reenvio com o mesmo event_id.

A biblioteca compartilhada facilita esta entrega academica, mas vincula versoes dos dois servicos. O Compose tem um unico no RabbitMQ e credenciais apenas para desenvolvimento. A implementacao de negocio da triagem, estados de reserva pendente, consumidores e read model permanece nas outras partes. O guia [Infraestrutura e Mensageria](../infraestrutura-mensageria.md) descreve os contratos e os pontos de integracao.
