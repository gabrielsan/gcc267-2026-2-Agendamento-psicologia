# Backend — API de Agendamento Psicológico

API REST em **Ruby on Rails 8 (modo API)** com **PostgreSQL**, autenticação via **Devise + JWT** e autorização com **Pundit**.

- Endpoints, payloads e permissões: [`docs/api.md`](../docs/api.md)
- Decisões de arquitetura: [`docs/adr/0001-backend-rails-devise-jwt.md`](../docs/adr/0001-backend-rails-devise-jwt.md)

## Como rodar (só precisa de Docker)

```bash
cd backend
cp .env.example .env          # opcional em desenvolvimento
docker compose up --build     # sobe Postgres + API em http://localhost:3000
```

Em outro terminal, popule o banco com dados de exemplo:

```bash
docker compose run --rm api bin/rails db:seed
```

Usuários criados pelos seeds (todos com a senha `senha123`):

| Papel | E-mail |
|---|---|
| Admin | `admin@unilavras.edu.br` |
| Professor | `ana.supervisora@unilavras.edu.br`, `carlos.supervisor@unilavras.edu.br` |
| Estagiário | `maria.estagiaria@unilavras.edu.br`, `pedro.estagiario@unilavras.edu.br` (supervisora: Ana), `julia.estagiaria@unilavras.edu.br` (supervisor: Carlos) |

Teste rápido:

```bash
curl -i -X POST http://localhost:3000/api/v1/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"maria.estagiaria@unilavras.edu.br","senha":"senha123"}'
# copie o header "Authorization: Bearer ..." da resposta e use nas próximas chamadas
```

## Comandos úteis

| O quê | Comando |
|---|---|
| Testes | `docker compose run --rm -e RAILS_ENV=test api bash -c "bin/rails db:prepare && bundle exec rspec"` |
| Lint | `docker compose run --rm api bin/rubocop` |
| Segurança | `docker compose run --rm api bin/brakeman` |
| Console | `docker compose run --rm api bin/rails console` |
| Nova migration | `docker compose run --rm api bin/rails g migration NomeDaMigration` |
| Rotas | `docker compose run --rm api bin/rails routes -g api` |
| Zerar o banco | `docker compose run --rm api bin/rails db:reset` |

> Mudou o `Gemfile`? Rode `docker compose run --rm api bundle install` (as gems ficam num volume).

## Organização do código

```
app/
  models/          Usuario (STI) -> Admin, Professor, Estagiario; Consulta; JwtDenylist
  services/        Regras de negócio. Todo service devolve um Resultado (sucesso?/erros/codigo)
    consultas/     Agendar, Atualizar, VerificadorConflito, Disponibilidade
  policies/        Pundit: QUEM pode fazer O QUÊ (e o Scope de visibilidade de cada papel)
  serializers/     Formato JSON de saída (POROs simples)
  controllers/api/v1/
    base_controller.rb      Autenticação, Pundit, paginação e erros padronizados
    sessoes_controller.rb   POST /login, DELETE /logout
    usuarios_controller.rb  CRUD genérico herdado por Professores e Estagiarios
    consultas_controller.rb
spec/              RSpec: models, services, policies e requests
```

### Onde mexer para…

- **Mudar quem pode fazer algo** → `app/policies/*_policy.rb` (+ spec em `spec/policies`).
- **Mudar quais campos cada papel edita em uma consulta, ou quais status pode atribuir** → constantes `CAMPOS_POR_PAPEL` e `STATUS_POR_PAPEL` em `app/services/consultas/atualizar.rb`.
- **Mudar regras da consulta** (duração, transições de status) → constantes no topo de `app/models/consulta.rb`.
- **Expediente / blocos de horário da disponibilidade** → `app/services/consultas/disponibilidade.rb`.
- **Adicionar um recurso novo** → model + policy + serializer + controller herdando de `Api::V1::BaseController` + rota em `config/routes.rb` + specs.

## Variáveis de ambiente

| Variável | Padrão | Uso |
|---|---|---|
| `DEVISE_JWT_SECRET_KEY` | `secret_key_base` | Assinatura dos tokens JWT (**obrigatório definir em produção**; gere com `bin/rails secret`) |
| `JWT_EXPIRATION_MINUTES` | `480` | Validade do token |
| `CORS_ORIGINS` | `http://localhost:5173` | Origens do frontend liberadas (separadas por vírgula) |
| `DATABASE_HOST` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` / `DATABASE_PORT` | `localhost` / `postgres` / `postgres` / `5432` | Conexão com o Postgres (ou use `DATABASE_URL`) |
| `SECRET_KEY_BASE` | — | Obrigatória em produção (não usamos `credentials.yml.enc`) |
