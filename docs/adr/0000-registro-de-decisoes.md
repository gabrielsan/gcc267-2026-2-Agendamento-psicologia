# ADR 0000: Instituição do Registro de Decisões de Arquitetura (ADR)

* Status: Aceito
* Data: 2026-08-26

## Contexto
O desenvolvimento envolve escolhas arquiteturais críticas ao longo do semestre (decomposição de serviços, mensageria, SAGA, CQRS). Decisões tomadas sem registro formal causam perda de contexto técnico e dificultam revisões da equipe.

## Decisão
Adotaremos o padrão de **Architectural Decision Records (ADR)** para documentar todas as decisões técnicas no diretório `docs/adr/` com numeração sequencial.

## Consequências
- **Positivas**: Rastreabilidade histórica de todas as decisões tomadas e clareza para a equipe.
- **Negativas**: Pequeno overhead de documentação a cada nova decisão relevante.