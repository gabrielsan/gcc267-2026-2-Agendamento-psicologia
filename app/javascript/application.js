import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.config.forms.confirm = (message) => {
  const dialog = document.getElementById("confirmacao")
  dialog.querySelector("#confirmacao-mensagem").textContent = message
  dialog.returnValue = "cancel"
  dialog.showModal()
  return new Promise(resolve => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}

document.addEventListener("turbo:frame-missing", event => {
  // Sessão expirada ou filtro inválido: mostre a página completa de login/erro.
  event.preventDefault()
  event.detail.visit(event.detail.response)
})
