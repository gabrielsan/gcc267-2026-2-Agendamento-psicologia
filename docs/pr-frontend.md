# feat: implementar frontend com Tailwind e Hotwire

## Problema e resultado

O backend tinha os recursos de agendamento, mas faltavam telas para utilizá-los. Esta entrega implementa a parte 2: home com escolha de perfil, login, dashboards e interfaces de consultas e professores, em português e adaptadas a desktop, tablet e celular.

## Implementação

- Views ERB com Tailwind, filtros com Turbo Frames e menu móvel com Stimulus.
- Consultas com criação, visualização e edição conforme o perfil; exclusão exclusiva do admin, com confirmação.
- Gestão de professores pelo admin, incluindo desativação e tratamento de exclusão bloqueada por vínculos.
- Formulários que preservam os dados após erro, mensagens em português e estados vazios.
- Reutilização de services e policies existentes, autorização no servidor e escopos por usuário.
- Sessão com CSRF no HTML; autenticação JWT explícita na API para impedir que cookies do frontend alterem a identidade ou autentiquem requisições da API.
- CI habilitado também para PRs destinados a `desafio-*`.

Decisão arquitetural: [ADR 0003](adr/0003-frontend-hotwire.md). Execução, permissões, comandos de teste e roteiro de demonstração de até seis minutos: [guia do frontend](frontend.md).

## Evidências e limites da validação

- RSpec: última execução completa com 155 exemplos e zero falhas, anterior aos ajustes finais de tradução, assertions de tradução e responsividade. Repetir no estado final antes do merge.
- Chromium: fluxo completo dos três perfis, CRUDs, validação, confirmação de exclusão, Turbo Frame e menu móvel; 16 capturas, sem erros JavaScript ou traduções ausentes.
- Responsividade após a correção: sete telas em seis larguras entre 320 e 2329 px, sem overflow horizontal e com cabeçalhos/cartões alinhados. Executar com `node script/responsive_smoke.cjs` após instalar a dependência opcional indicada no guia.
- Tailwind recompilado com sucesso após a correção de responsividade.
- Zeitwerk e Brakeman passaram na validação anterior. Brakeman usa as exceções preexistentes `EOLRuby,EOLRails`; não houve atualização desses runtimes.

## Checklist acadêmico e revisão

- [x] Descrição da mudança, decisão arquitetural e instruções de execução documentadas.
- [x] Roteiro para apresentação ao vivo e explicação do código disponível.
- [ ] Repetir RSpec no estado final e confirmar CI verde no GitHub.
- [ ] Obter revisão humana antes do merge.
- [ ] Conferir a entrega única do desafio, prazo e postagem do link no campus virtual.
- [ ] Regularizar requisitos herdados da base: repositório na organização da turma, licença e tratamento da chave já versionada e de arquivos gerados no histórico.

A implementação do frontend não resolve automaticamente essas pendências da entrega acadêmica. Não foram incluídas novas credenciais, logs ou caches nesta alteração.
