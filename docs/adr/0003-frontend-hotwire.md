# ADR 0003: Frontend Hotwire com autenticação por sessão

* Status: Aceito
* Data: 2026-10-08

## Contexto

A API implementada na parte 1 oferece os models, services e policies do agendamento. A parte 2 exige home com escolha de perfil, dashboards e CRUD visual com Tailwind e Hotwire. A API autentica com JWT e não verifica CSRF; simplesmente habilitar cookies para todos os controllers criaria uma segunda forma insegura de autenticar a API.

## Decisão

Implementar views ERB e controllers HTML na mesma aplicação Rails, reutilizando Pundit e `Consultas::Agendar` / `Consultas::Atualizar`. Não fazer chamadas HTTP internas para a própria API nem duplicar as regras de domínio.

O login web usa Devise e sessão, com proteção CSRF, logout por DELETE e redirecionamento ao painel. A escolha de perfil na home personaliza a apresentação do login; as permissões são sempre derivadas da conta autenticada. Na interface, Estudante corresponde a Estagiario. Contas desativadas perdem o acesso web; páginas privadas não são armazenadas pelo cache Turbo.

A API decodifica exclusivamente o JWT do header Authorization, verificando validade, revogação e conta ativa. Cookies não autorizam a API, mesmo que pertençam a um admin; quando cookie e JWT coexistem, vale a identidade do token.

Turbo Drive trata navegação e formulários; Turbo Frames atualizam listas e filtros sem recarregar a página inteira. Erros de formulário retornam 422, preservando os dados; sucesso redireciona com 303. Respostas sem o frame esperado (login expirado ou erro de filtro) são apresentadas como páginas completas. Stimulus controla o menu móvel; a confirmação de exclusão usa um dialog acessível integrado ao Turbo.

Tailwind organiza os componentes visuais; assets são servidos localmente com importmap, sem CDN. A interface usa português, o fuso America/Sao_Paulo, labels explícitos, foco visível, estados vazios e layout adaptável.

## Consequências

Uma única base de regras atende API e frontend. Professores continuam limitados a status e observações das consultas supervisionadas; apenas admin exclui registros. Professores com vínculos podem ser desativados, preservando o histórico. A suíte de integração precisa testar a fronteira entre sessão e JWT, além dos fluxos HTML e do comportamento JavaScript.

Não há alteração de schema nem novas gems. Playwright/Chromium são dependências opcionais de validação visual, instaladas em tmp e não usadas pela aplicação. Atualização do runtime e correções preexistentes de domínio/segredos permanecem tarefas separadas, explicitadas na entrega.
