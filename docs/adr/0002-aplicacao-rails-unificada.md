# ADR 0002: Aplicação Rails unificada na raiz

* Status: Aceito
* Data: 2026-10-07

## Contexto

A base existente usa Ruby 3.2.3, Rails 7.1, Hotwire, Tailwind e Annotate. O backend foi desenvolvido em uma segunda aplicação Rails 8.1 em `backend/`, com configurações próprias de banco, Docker e CI. As duas aplicações precisam ser integradas para que a equipe trabalhe no mesmo projeto.

## Decisão

Manter uma única aplicação Rails 7.1 na raiz. Incorporar models, migrations, services, policies, serializers e specs do backend, preservando os contratos de `/api/v1` e a autenticação JWT. Migrar os controllers da API para `Api::ApplicationController < ActionController::API`; o `ApplicationController < ActionController::Base` continua como base para views HTML e Hotwire.

Manter STI para usuários, Pundit, Pagy e constraints PostgreSQL contra conflitos de agenda. Usar o Docker Compose da raiz, com serviços `web` e `db`, e executar o CI na raiz. Remover a aplicação duplicada em `backend/`. Não usar CORS nesta etapa, pois as views serão servidas pela própria aplicação.

## Consequências

Uma única instalação de gems, banco e configuração de execução. As telas Hotwire poderão reutilizar o domínio e as policies sem chamadas HTTP internas. A autenticação HTML por sessão ainda deverá ser implementada com proteção CSRF; os endpoints da API continuam usando JWT. O ADR 0001 permanece como registro histórico das regras e da arquitetura original do backend.

Os bancos da aplicação unificada usam novos nomes para preservar bancos antigos com schema incompatível; os dados antigos não são migrados automaticamente. Ruby 3.2 e Rails 7.1 estão fora de suporte na data desta integração. O CI verifica segurança do código com Brakeman, excetuando apenas EOLRuby/EOLRails; a atualização do runtime permanece pendente.
