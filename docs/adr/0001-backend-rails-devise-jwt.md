# ADR 0001: Backend em Rails API com Devise-JWT, STI e Pundit

* Status: Aceito
* Data: 2026-10-07

## Contexto
Precisamos de um backend para o domínio de agendamento (Admin, Professor, Estagiário e Consulta) que a equipe consiga evoluir em paralelo: o frontend/BFF consome a API, o DevOps cuida de containers/CI e o QA amplia as suítes de teste. Requisitos centrais: autenticação, permissões por papel e **impedir choque de horário** de estagiários e salas.

## Decisão
1. **Ruby on Rails 8 em modo API** com **PostgreSQL**, rodando via **Docker Compose** (ninguém precisa instalar Ruby localmente).
2. **Autenticação com Devise + devise-jwt**: `POST /api/v1/login` devolve um JWT no header `Authorization`; `DELETE /api/v1/logout` revoga o token (estratégia *Denylist*, tabela `jwt_denylists`). Sem sessão/cookies, adequado para SPA/BFF e futuros serviços.
3. **Usuários em uma única tabela com STI** (`usuarios.type` = `Admin` | `Professor` | `Estagiario`): um único login, um único modelo Devise; cada subclasse tem suas associações (Estagiário `belongs_to :supervisor`, Professor `has_many :estagiarios`).
4. **Autorização com Pundit**: uma policy por recurso define as ações permitidas e o `Scope` (o que cada papel enxerga). O `BaseController` exige `authorize`/`policy_scope` em toda ação.
5. **Service layer** (`app/services`) para regras de agendamento/edição. Services retornam um `Resultado` (`sucesso?`, `erros`, `codigo`), em vez de exceções para erros de negócio.
6. **Conflito de horário em duas camadas**: o `Consultas::VerificadorConflito` gera mensagens amigáveis, e **exclusion constraints** do PostgreSQL (`btree_gist` + `tsrange`) garantem a integridade mesmo com requisições concorrentes. Consultas canceladas liberam o horário.
7. **Paciente como campos da Consulta** (`paciente_nome`, `paciente_telefone`, `paciente_email`) nesta etapa; um modelo `Paciente` pode ser extraído depois sem quebrar a API (o JSON já agrupa em `consulta.paciente`).

## Consequências
- **Positivas**: autenticação stateless pronta para o BFF; regras de permissão centralizadas e testáveis; integridade de agenda garantida pelo banco; ambiente reproduzível com um comando.
- **Negativas**: dependência de recursos específicos do PostgreSQL (exclusion constraints); STI exige cuidado se os papéis passarem a ter muitos atributos exclusivos; JWT revogado depende de consulta à denylist a cada requisição.
