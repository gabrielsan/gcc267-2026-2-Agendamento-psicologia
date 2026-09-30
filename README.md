# Agendamento de Consultas Psicológicas - Unilavras

Aplicação Rails para gestão de consultas psicológicas da clínica-escola Unilavras, com autenticação por administradores, professores e estagiários, agenda de consultas, professores supervisores e validação de conflitos de horário.

## Stack

- Ruby 3.2.3
- Rails 7.1
- PostgreSQL
- Hotwire + Tailwind CSS
- Devise
- RSpec + Factory Bot
- Docker Compose

## Rodando com Docker

```bash
docker compose up --build
```

A aplicação ficará em `http://localhost:3000`.

Usuários de seed:

- Admin: `admin@unilavras.edu.br` / `password123`
- Estagiário: `estagiario@unilavras.edu.br` / `password123`
- Professor: `helena.martins@unilavras.edu.br` / `password123`

## Testes

```bash
bundle exec rspec
```

Ou dentro do Docker:

```bash
docker compose run --rm web bundle exec rspec
```

## Regras atuais

- Admin cria, edita e exclui professores.
- Admin pode excluir consultas e visualizar a agenda completa.
- Professor visualiza apenas as consultas em que atua como supervisor.
- Estagiário cria e edita apenas suas próprias consultas.
- Consultas não podem sobrepor horários do mesmo estagiário ou professor.
- Consultas presenciais exigem sala.
