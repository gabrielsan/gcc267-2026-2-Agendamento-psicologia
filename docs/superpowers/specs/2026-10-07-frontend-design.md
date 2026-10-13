# Frontend de agendamento psicológico

## Objetivo e escopo autorizado
Implementar a parte 2 solicitada: Tailwind e Hotwire, home com Professor/Estudante/Admin, dashboards por perfil, CRUD visual de consultas e professores, formulários, erros, estados vazios e responsividade. Estudante corresponde a Estagiario no domínio existente.

## Arquitetura
Manter uma aplicação Rails. Controllers HTML usam sessão Devise, CSRF, Pundit e os services existentes. A API JWT continua disponível. Escolher um perfil na home apenas personaliza o login; a autorização sempre vem do usuário autenticado. Não há cadastro público.

## Interface
Identidade clara de clínica-escola, azul-petróleo e verde suave; navegação lateral no desktop e menu acessível no celular. Home com três cartões; login por perfil; dashboard com contagens visíveis apenas no escopo autorizado e próximas consultas. Agenda com busca, status, data e paginação via Turbo Frame. Formulários preservam dados inválidos e apresentam erros. Ações destrutivas exigem confirmação. Datas no fuso America/Sao_Paulo.

## Permissões
Reutilizar as policies existentes. Estagiário cria e edita as próprias consultas em aberto. Professor edita status/observações das supervisionadas. Admin edita/exclui consultas e gerencia professores. Professor vinculado não pode ser excluído; oferecer desativação. Não ampliar as regras do backend nesta entrega.

## Qualidade e entrega
Requests e fluxos Capybara cobrem login/logout, isolamento por perfil, CRUD, erros e conflitos; suíte existente continua verde. Verificar desktop/celular e Turbo no navegador. Registrar ADR, README, roteiro de demo e descrição de PR com resultados reais. Não incluir segredos novos ou arquivos temporários. O PR da feature tem base desafio-01; não equivale à entrega final da disciplina.
