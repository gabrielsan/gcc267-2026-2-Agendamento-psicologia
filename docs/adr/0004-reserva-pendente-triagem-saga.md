# ADR 0004: Reserva pendente_triagem e SAGA de confirmação/compensação

* Status: Aceito
* Data: 2026-11-26

## Contexto

A Parte 2 (ADR 0003) preparou RabbitMQ, Outbox e o contrato de eventos v1, mas manteve o fluxo síncrono existente: a consulta nascia `agendada` e a fila `psiline.agendamento` (`triagem.aprovada`/`triagem.reprovada`) ficava sem consumidor. A divisão do trabalho (Parte 1) pede para evoluir isso para a reserva pendente de triagem, com confirmação e compensação pela SAGA.

## Decisão

A consulta nasce com status `pendente_triagem` (novo valor inicial do enum e da constraint de banco, no lugar de `agendada`). Nesse estado o horário já conta como ocupado (conflito de agenda e exclusion constraints não mudam) e o estagiário ainda pode editá-la ou cancelá-la — `pendente_triagem` entra em `em_aberto?`/`Consulta.em_aberto`.

`Consultas::Agendar` passou a atribuir `pendente_triagem` em vez de `agendada`; o restante do fluxo de criação (validações, conflito, `RegistrarEvento` com `consulta.reserva_criada`) não mudou.

A transição seguinte é feita só pela SAGA, nunca por `PATCH`: `Consultas::Saga::Confirmar` e `Consultas::Saga::Cancelar` levam `pendente_triagem` para `agendada` (emitindo `consulta.reserva_confirmada`) ou para `cancelada` (compensação, emitindo `consulta.reserva_cancelada` com `data.motivo`). Ambos são idempotentes por omissão: se a consulta já saiu de `pendente_triagem` (reentrega ou evento fora de ordem), apenas devolvem `:ignorado`. Não existe endpoint público para "confirmar": expor um exporia a aprovação da triagem a ser contornada por qualquer estagiário.

`Consultas::Saga::ProcessarResultadoTriagem` é o ponto de entrada: decodifica o envelope da fila `psiline.agendamento`, registra o `event_id` em `ProcessedEvent` (tabela local, fora de `shared/`) dentro da mesma transação da confirmação/compensação, e despacha para `Confirmar`/`Cancelar`. O insert em `ProcessedEvent` roda num savepoint (`transaction(requires_new: true)`); sem isso, a violação de unicidade de uma reentrega aborta toda a transação no Postgres, não só o registro duplicado. `Consultas::Saga::Consumidor` (worker Bunny, tarefa `saga:consumir`, serviço `agendamento-saga-consumer` no Compose) só faz a ponte: decodifica JSON, chama `ProcessarResultadoTriagem`, e dá ack/nack (uma reentrega antes de cair na dead-letter `psiline.agendamento.dead`).

O campo `data.motivo` do contrato é lido com fallback para `motivo_codigo`/`motivo_detalhe`, variações já observadas em implementações de triagem em andamento; o nome definitivo do campo continua sendo `data.motivo`, por ser o que está documentado em `docs/infraestrutura-mensageria.md` como ponto de acordo entre as partes.

## Consequências

Consultas recém-criadas não aparecem mais como `agendada` até a triagem responder; quem depender desse status (telas, specs, seeds) precisa esperar pela SAGA ou, em teste/demonstração, simular a resposta publicando `triagem.aprovada`/`triagem.reprovada` diretamente no broker. Testes existentes que exercitavam o ciclo pós-triagem (edição, confirmação por professor) foram ajustados para partir de `agendada` explicitamente, já que esse ciclo é anterior e não muda.

A SAGA depende do worker `agendamento-saga-consumer` estar no ar; sem ele, reservas ficam presas em `pendente_triagem` indefinidamente (o horário continua ocupado, sem confirmação nem liberação). Entrega pelo menos uma vez: a idempotência por `event_id` evita duplicar confirmação/compensação, mas não ordena eventos — um `triagem.reprovada` que chegue depois de um `triagem.aprovada` para a mesma consulta é ignorado, porque a consulta já não está mais `pendente_triagem`.
