# Visão do Produto: Sistema de Agendamento Psicológico (Unilavras)

## Problema
Alunos da instituição e a comunidade externa enfrentam dificuldades para encontrar horários e agendar atendimentos psicológicos na clínica-escola. Estagiários de psicologia e supervisores precisam de uma gestão eficiente de grade horária, prontuários e acompanhamento de frequência sem choques de horário.

## Público-Alvo
- **Pacientes**: Alunos da instituição e comunidade externa em busca de atendimento.
- **Estagiários**: Estudantes do curso de Psicologia que prestam atendimento supervisionado.
- **Supervisores**: Professores responsáveis por validar horas, escalas e supervisão clínica.

## Transação Distribuída (Atravessa Contextos)
A principal transação que atravessa contextos no sistema é a **Solicitação e Confirmação de Consulta**:
1. **Contexto de Agendamento**: O paciente solicita um horário na grade do estagiário (vaga fica temporariamente reservada).
2. **Contexto de Validação/Triagem**: O sistema valida os pré-requisitos do paciente e a disponibilidade de sala/supervisor.
3. **Contexto de Notificação**: Assim que aprovado na triagem, o agendamento é confirmado e notificações são enviadas.

*Fluxo de Compensação*: Se a triagem falhar (ex: ausência de supervisor ou conflito de sala), a reserva no Contexto de Agendamento é cancelada e o horário retorna vago para a grade pública.