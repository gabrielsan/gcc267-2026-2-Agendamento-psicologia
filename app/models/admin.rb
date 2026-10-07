# == Schema Information
#
# Table name: usuarios
#
#  id                 :bigint           not null, primary key
#  ativo              :boolean          default(TRUE), not null
#  email              :string           default(""), not null
#  encrypted_password :string           default(""), not null
#  matricula          :string
#  nome               :string           not null
#  telefone           :string
#  type               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  supervisor_id      :bigint
#
# Indexes
#
#  index_usuarios_on_email          (email) UNIQUE
#  index_usuarios_on_matricula      (matricula) UNIQUE WHERE (matricula IS NOT NULL)
#  index_usuarios_on_supervisor_id  (supervisor_id)
#  index_usuarios_on_type           (type)
#
# Foreign Keys
#
#  fk_rails_...  (supervisor_id => usuarios.id)
#
class Admin < Usuario
  def admin? = true
end
