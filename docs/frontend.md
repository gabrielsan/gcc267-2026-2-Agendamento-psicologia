# Frontend: execução, permissões e demonstração

## Executar do zero

Pré-requisito: Docker e Docker Compose. Na raiz:

```bash
docker compose up --build
```

Acesse http://localhost:3000. O Compose prepara o banco, carrega dados fictícios e compila o Tailwind. As credenciais de desenvolvimento estão no README; não use esses seeds em produção. `.gitattributes` mantém os scripts executáveis com LF em clones no Windows.

## Telas e permissões

| Tela | Estudante | Professor | Admin |
|---|---|---|---|
| Home e login | Escolha de perfil; a conta determina o acesso real | Idem | Idem |
| Painel | Minha agenda e indicadores próprios | Agenda supervisionada | Agenda geral e professores ativos |
| Consultas | Cria e edita as próprias em aberto | Edita status/observações das supervisionadas | Edita e exclui qualquer consulta |
| Professores | Sem acesso | Próprio cadastro por URL | Lista, busca, cria, visualiza, edita, desativa e exclui sem vínculos |

As telas usam as permissões do backend; esconder um botão não é a proteção. Controllers também autorizam todas as ações. O backend continua impedindo conflitos de sala/estagiário, e o frontend apresenta as mensagens sem apagar os campos preenchidos.

## Validação automatizada

```bash
docker compose run --rm -e RAILS_ENV=test web bash -lc 'bin/rails db:prepare && bundle exec rspec'
docker compose run --rm web bin/rails zeitwerk:check
docker compose run --rm web bin/rails tailwindcss:build
docker compose run --rm web bundle exec brakeman --no-pager --except EOLRuby,EOLRails
```

O Brakeman mantém as exceções de fim de suporte já adotadas pelo projeto. Uma execução sem alertas com essas exceções não significa que Ruby/Rails foram atualizados.

### Chromium opcional

Use somente um ambiente de desenvolvimento descartável: o roteiro cria registros fictícios e os exclui ao concluir. Se interrompido, pode deixar registros QA para limpeza local.

```bash
npm install --prefix tmp/browser-qa playwright
node tmp/browser-qa/node_modules/playwright/cli.js install chromium
node script/browser_smoke.cjs
```

Com o servidor em execução, esse teste percorre os três perfis, os CRUDs, o erro de duração, o Turbo Frame, o menu móvel e a confirmação de exclusão. As capturas ficam em `tmp/screenshots/`. `QA_BASE_URL` permite apontar para outra porta local. `--probe` verifica home/login e o tratamento de Escape sem criar registros.

## Roteiro de vitrine (até 6 minutos)

1. **0:00–0:40:** mostrar `docker compose up`, abrir a home e explicar os três perfis.
2. **0:40–2:00:** entrar como estudante; criar uma consulta; provocar erro de duração/conflito e corrigir sem perder os dados.
3. **2:00–3:00:** entrar como professor; mostrar somente as supervisionadas e editar status/observações.
4. **3:00–4:10:** entrar como admin; cadastrar/editar um professor e demonstrar confirmação de exclusão. Explicar desativação quando há vínculos.
5. **4:10–5:00:** mostrar filtro Turbo e menu em largura móvel; apontar reutilização de service e policy no controller.
6. **5:00–6:00:** mostrar os testes e explicar a decisão do ADR 0003: sessão+CSRF no HTML e JWT exclusivo na API. Relatar o problema encontrado nos cookies e o teste que evita regressão.

Todos os integrantes precisam conseguir explicar o código. Este roteiro não substitui revisão humana, CI verde no GitHub nem postagem do link no campus virtual.
