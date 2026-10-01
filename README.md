# Agendamento de Consultas Psicológicas - Unilavras

Base inicial em Rails para o sistema de agendamento da clínica-escola de Psicologia da Unilavras.

Este repositório está propositalmente só com a estrutura inicial da aplicação: Rails, PostgreSQL via Docker Compose, Hotwire/Tailwind, Devise, RSpec/Factory Bot/Shoulda e Annotate configurado para anotar apenas models. As entidades, regras de negócio, telas e testes do domínio serão implementados pela equipe.

## Stack

- Ruby 3.2.3
- Rails 7.1
- PostgreSQL
- Hotwire + Tailwind CSS
- Devise
- RSpec + Factory Bot + Shoulda Matchers
- Annotate, somente para models
- Docker Compose

## Rodando com Docker

```bash
docker compose up --build
```

A aplicação ficará em `http://localhost:3000`.

## Banco de dados

O PostgreSQL roda no serviço `db` do Docker Compose. Para preparar o banco manualmente:

```bash
docker compose run --rm web bin/rails db:prepare
```

## Testes

```bash
bundle exec rspec
```

Ou dentro do Docker:

```bash
docker compose run --rm web bundle exec rspec
```

## Annotate

A gem `annotate` está instalada no grupo de desenvolvimento e configurada em `lib/tasks/auto_annotate_models.rake` para anotar apenas arquivos em `app/models`.

Uso manual:

```bash
bundle exec annotate --models
```

## Próximos passos sugeridos

- Criar as entidades do domínio: administradores, professores, estagiários e consultas.
- Definir regras de autorização por perfil.
- Implementar services para regras de agendamento e conflitos de horário.
- Construir as telas com Hotwire/Turbo e Tailwind.
- Cobrir models, services e requests com RSpec.
