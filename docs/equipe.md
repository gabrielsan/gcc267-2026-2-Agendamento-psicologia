# Estrutura e Organização da Equipe

## Integrantes e Papéis

- **Ana Cecília Queiroz Andrade** - *Tech Lead / Backend Developer*
  - Responsável pela liderança técnica, modelagem dos contextos delimitados e desenvolvimento dos serviços centrais.
- **Gabriel Santos Silva** - *DevOps / Infrastructure Engineer*
  - Responsável pela infraestrutura Docker, criação das pipelines de CI/CD (GitHub Actions) e broker de mensageria.
- **Jhonatan Roque Couto** - *Frontend / Integration Developer*
  - Responsável pela interface do usuário / BFF, comunicação REST/gRPC e documentação das APIs.
- **João Victor Vieira Neto Matos** - *QA / Domain & Data Specialist*
  - Responsável pelas suítes de teste (unitários e de integração), rastreabilidade de eventos e validação do fluxo SAGA.

## Organização de Trabalho e Fluxo de Git

- **Branch Padrão**: `main` (protegida para commits diretos).
- **Branches de Feature/Desafio**: Padrão `desafio-0X`.
- **Code Review**: Todo Pull Request (PR) precisa de pelo menos 1 aprovação antes do merge.