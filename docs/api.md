# API REST — v1

Base: `http://localhost:3000/api/v1` · JSON em UTF-8 · datas em ISO 8601 (fuso `America/Sao_Paulo`).

## Autenticação

Todas as rotas, exceto `POST /login`, exigem o header:

```
Authorization: Bearer <token>
```

| Método | Rota | Corpo | Resposta |
|---|---|---|---|
| `POST` | `/login` | `{ "email": "...", "senha": "..." }` | `200` `{ "usuario": {...} }` + header `Authorization` |
| `DELETE` | `/logout` | — | `204` (o token deixa de valer) |
| `GET` | `/me` | — | `200` `{ "usuario": {...} }` |

O token expira em `JWT_EXPIRATION_MINUTES` (padrão 8h). Clientes da API devem ler o header `Authorization` do login e reenviá-lo em todas as chamadas. A aplicação unificada serve o frontend na mesma origem e não configura CORS nesta etapa.

## Erros

Todas as falhas seguem o mesmo formato:

```json
{ "erros": ["Mensagem legível"], "codigo": "conflito_horario" }
```

| HTTP | `codigo` | Quando |
|---|---|---|
| 400 | `parametro_ausente`, `parametro_invalido` | Falta a chave raiz (ex.: `consulta`) ou a data/paginação está inválida |
| 401 | `nao_autenticado`, `credenciais_invalidas`, `usuario_inativo` | Sem token, token inválido/revogado/expirado, login incorreto |
| 403 | `sem_permissao` | O papel do usuário não permite a ação |
| 404 | `nao_encontrado` | Registro inexistente |
| 422 | `invalido` | Erros de validação |
| 422 | `conflito_horario` | Choque de horário do estagiário ou da sala |
| 422 | `campo_nao_permitido`, `status_nao_permitido` | O papel não pode alterar aquele campo ou atribuir aquele status |

## Paginação

As listagens aceitam `?pagina=1&por_pagina=20` (máximo 100) e devolvem:

```json
{ "consultas": [ ... ], "meta": { "pagina": 1, "por_pagina": 20, "total": 42, "paginas": 3 } }
```

## Permissões

| Ação | Admin | Professor | Estagiário |
|---|---|---|---|
| Professores: listar / criar / editar / excluir | ✔ | — | — |
| Professores: ver | ✔ | só a si mesmo | — |
| Estagiários: criar / editar / excluir | ✔ | — | — |
| Estagiários: listar / ver | todos | os que supervisiona | só a si mesmo (ver) |
| Consultas: listar / ver | todas | as que supervisiona | as próprias |
| Consultas: criar | — | — | ✔ (sempre em seu nome) |
| Consultas: editar | ✔ (todos os campos) | as que supervisiona (`status`, `observacoes`) | as próprias em aberto (paciente, horário, sala, observações; status só `cancelada`/`realizada`/`falta`) |
| Consultas: excluir | ✔ | — | — (cancela via status) |

Usuários com vínculos (professor com estagiários/consultas, estagiário com consultas) não podem ser excluídos (`422`); desative com `{ "ativo": false }`. Usuários inativos não conseguem fazer login.

## Usuários

### Objeto `usuario`

```json
{
  "id": 4, "tipo": "estagiario", "nome": "Maria Fernanda Souza",
  "email": "maria.estagiaria@unilavras.edu.br", "matricula": "E0001", "telefone": null, "ativo": true,
  "supervisor": { "id": 2, "nome": "Ana Paula Ribeiro" },
  "criado_em": "2026-10-07T07:56:24.412-03:00", "atualizado_em": "2026-10-07T07:56:24.412-03:00"
}
```

`tipo` é `admin`, `professor` ou `estagiario`; `supervisor` só aparece para estagiários.

### Professores — `/professores`

| Método | Rota | Corpo |
|---|---|---|
| `GET` | `/professores?busca=ana&ativo=true` | — |
| `GET` | `/professores/:id` | — |
| `POST` | `/professores` | `{ "professor": { "nome", "email", "senha", "matricula", "telefone", "ativo" } }` |
| `PATCH` | `/professores/:id` | mesmos campos; `senha` vazia ou ausente = não altera |
| `DELETE` | `/professores/:id` | — |

### Estagiários — `/estagiarios`

Iguais aos de professores, com a chave raiz `estagiario`, o campo obrigatório `supervisor_id` (id de um professor) e o filtro extra `?supervisor_id=`.

## Consultas — `/consultas`

### Objeto `consulta`

```json
{
  "id": 5, "status": "agendada",
  "inicio": "2026-10-10T15:00:00.000-03:00", "fim": "2026-10-10T15:50:00.000-03:00", "duracao_minutos": 50,
  "sala": "Sala 9",
  "paciente": { "nome": "Fulano", "telefone": "(35) 98888-0000", "email": null },
  "observacoes": null,
  "estagiario": { "id": 4, "nome": "Maria Fernanda Souza" },
  "professor": { "id": 2, "nome": "Ana Paula Ribeiro" },
  "criado_em": "...", "atualizado_em": "..."
}
```

### Rotas

| Método | Rota | Observações |
|---|---|---|
| `GET` | `/consultas` | Filtros: `de`, `ate` (`AAAA-MM-DD` ou ISO 8601), `status` (lista separada por vírgula), `estagiario_id`, `professor_id`, `sala`. Ordenadas por `inicio`. |
| `GET` | `/consultas/:id` | |
| `POST` | `/consultas` | Somente estagiário. Corpo abaixo. |
| `PATCH` | `/consultas/:id` | Envie só os campos que mudam, dentro de `consulta`. |
| `DELETE` | `/consultas/:id` | Somente admin. |
| `GET` | `/consultas/disponibilidade?data=AAAA-MM-DD[&estagiario_id=ID]` | Horários livres do estagiário no dia (expediente 8h–20h, blocos de 50 min a cada hora). Sem `estagiario_id`, usa o estagiário logado. |

Exemplo de criação:

```json
POST /api/v1/consultas
{
  "consulta": {
    "paciente_nome": "João da Silva",
    "paciente_telefone": "(35) 98888-0000",
    "paciente_email": "joao@email.com",
    "inicio": "2026-10-10T15:00:00-03:00",
    "fim": "2026-10-10T15:50:00-03:00",
    "sala": "Sala 1",
    "observacoes": "Primeira consulta"
  }
}
```

O professor responsável é definido automaticamente (o supervisor do estagiário) e o status inicial é `agendada`.

### Regras de negócio

- Duração entre **30 e 120 minutos**; `fim` deve ser depois de `inicio`; não é possível agendar no passado.
- **Sem conflitos**: o mesmo estagiário ou a mesma sala não podem ter duas consultas não canceladas sobrepostas. Uma consulta pode começar exatamente quando a outra termina. Consultas canceladas liberam o horário.
- **Status**: `agendada` ⇄ `confirmada` → `realizada` | `falta` | `cancelada`. Os três últimos são finais. `realizada` e `falta` só podem ser marcados depois do horário de início.
- Se o estagiário trocar de supervisor, as consultas futuras em aberto passam para o novo professor.
