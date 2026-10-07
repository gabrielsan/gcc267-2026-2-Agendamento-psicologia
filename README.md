# Agendamento de Consultas Psicológicas - Unilavras
Sistema distribuído para gestão e agendamento de consultas psicológicas com estagiários do curso de Psicologia na Unilavras.

Projeto desenvolvido para a disciplina **GCC267** (2026/2). 
## Entrega Desafio 01 

## Backend (Desafio 02)

API REST em Rails + PostgreSQL com autenticação Devise/JWT, em [`backend/`](backend/).

```bash
cd backend
docker compose up --build
docker compose run --rm api bin/rails db:seed   # em outro terminal
```

- Como rodar, testar e onde mexer: [`backend/README.md`](backend/README.md)
- Referência da API e matriz de permissões: [`docs/api.md`](docs/api.md)
- Decisão de arquitetura: [`docs/adr/0001-backend-rails-devise-jwt.md`](docs/adr/0001-backend-rails-devise-jwt.md)
