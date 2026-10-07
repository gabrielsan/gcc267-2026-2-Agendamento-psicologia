# Agendamento de Consultas Psicológicas - Unilavras

Aplicação Rails da disciplina GCC267 (2026/2), reunindo a base Hotwire/Tailwind e o backend de agendamentos na raiz do repositório.

## Stack

- Ruby 3.2.3
- Rails 7.1
- PostgreSQL
- Hotwire + Tailwind CSS
- Devise/JWT + Pundit + Pagy
- RSpec + Factory Bot + Faker + Shoulda Matchers
- Annotate, somente para models
- Docker Compose

## Rodando com Docker

```bash
docker compose up --build
```

A aplicação ficará em `http://localhost:3000`.

O serviço `web` prepara o banco, carrega os seeds e compila o Tailwind antes de iniciar. A API está em `/api/v1` e a verificação de saúde em `/up`. As telas Hotwire ainda serão implementadas nesta mesma aplicação.

## Acessos de desenvolvimento

Todos os usuários dos seeds usam a senha `senha123`:

| Perfil | E-mail |
|---|---|
| Admin | `admin@unilavras.edu.br` |
| Professor | `ana.supervisora@unilavras.edu.br` |
| Professor | `carlos.supervisor@unilavras.edu.br` |
| Estagiário | `maria.estagiaria@unilavras.edu.br` |
| Estagiário | `pedro.estagiario@unilavras.edu.br` |
| Estagiário | `julia.estagiaria@unilavras.edu.br` |

O login atual é pela API:

```bash
curl -i -X POST http://localhost:3000/api/v1/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"ana.supervisora@unilavras.edu.br","senha":"senha123"}'
```

Use o header `Authorization: Bearer <token>` retornado para autenticar as próximas requisições. `DELETE /api/v1/logout` revoga o token. Não há cadastro público.

## Banco de dados

O PostgreSQL roda no serviço `db` do Docker Compose. Para preparar o banco manualmente:

```bash
docker compose run --rm web bin/rails db:prepare db:seed
```

A aplicação integrada usa `agendamento_psicologia_unificada_development` e `agendamento_psicologia_unificada_test`. Os bancos da versão anterior são preservados, pois o backend usa um novo schema com usuários em STI. Não há migração automática dos dados antigos. Os nomes podem ser configurados com `DATABASE_NAME` e `DATABASE_TEST_NAME`.

## Testes

```bash
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

Ou dentro do Docker:

```bash
docker compose run --rm -e RAILS_ENV=test web bash -lc 'bin/rails db:prepare && bundle exec rspec'
```

## Annotate

A gem `annotate` está instalada no grupo de desenvolvimento e configurada em `lib/tasks/auto_annotate_models.rake` para anotar apenas arquivos em `app/models`.

Uso manual:

```bash
bundle exec annotate --models
```

## Organização

- `app/models`: Usuario (STI), Admin, Professor, Estagiario, Consulta e JwtDenylist.
- `app/services/consultas`: agendamento, atualização, disponibilidade e conflitos.
- `app/policies`: permissões e visibilidade por perfil.
- `app/controllers/api/v1` e `app/serializers`: endpoints e respostas JSON.
- `app/controllers/application_controller.rb` e `app/views`: base HTML para Hotwire, separada dos controllers da API.
- `spec`: testes de models, services, policies e requests.

Só o admin cria professores e exclui registros. Professores acompanham seus supervisionados; estagiários criam e editam suas consultas em aberto. Usuários com vínculos não podem ser excluídos e podem ser desativados pelo admin. Conflitos de agenda são verificados pelos services e por constraints do PostgreSQL.

- Referência da API e matriz de permissões: [docs/api.md](docs/api.md).
- Decisão atual de arquitetura: [ADR 0002](docs/adr/0002-aplicacao-rails-unificada.md).

## Variáveis de ambiente

| Variável | Padrão / uso |
|---|---|
| `DATABASE_HOST` | `localhost` (Docker: `db`) |
| `DATABASE_PORT` | `5432` |
| `DATABASE_USER` | `agendamento_psicologia`; aceita `DATABASE_USERNAME` como alternativa |
| `DATABASE_PASSWORD` | `agendamento_psicologia` em desenvolvimento |
| `DATABASE_NAME` | `agendamento_psicologia_unificada_development` |
| `DATABASE_TEST_NAME` | `agendamento_psicologia_unificada_test` |
| `DATABASE_URL` | URL de conexão em produção |
| `DEVISE_JWT_SECRET_KEY` | Usa `secret_key_base` como alternativa; configure em produção |
| `JWT_EXPIRATION_MINUTES` | `480` |
| `SECRET_KEY_BASE` | Configure em produção |

## Próximos passos

Construir a home de escolha de perfil e as telas de admin, professor e estudante com Hotwire/Tailwind, reutilizando os models, services e policies. A autenticação HTML por sessão deverá ser integrada ao Devise com proteção CSRF; os endpoints da API usam JWT.
