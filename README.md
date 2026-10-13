# API de Agendamento Psicológico

API RESTful desenvolvida em Ruby on Rails para gerenciamento de agendamentos de atendimento psicológico. Esta versão inclui autenticação via Devise/JWT, controle de acesso por papéis (RBAC) e suíte automatizada de testes com RSpec.

---

## Tecnologias Utilizadas

- **Ruby** 3.2+
- **Ruby on Rails** 7.1+ (Modo API)
- **PostgreSQL** 16
- **Docker** & **Docker Compose**
- **RSpec Rails** (Testes automatizados)
- **Devise** & **Devise-JWT** (Autenticação)

---

## Suíte de Testes (RSpec)

O projeto conta com uma suíte de testes cobrindo **Models**, **Services** e **Requests / Permissões**.

### Executando os testes via Docker

Para rodar a suíte completa de testes no ambiente isolado do Docker, execute:

```bash
docker compose run --rm -e RAILS_ENV=test web bash -c "bin/rails db:prepare && bundle exec rspec"
