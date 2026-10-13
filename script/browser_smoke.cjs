// Execute apenas em banco de desenvolvimento descartável com db:seed.
// Dependência opcional: npm install --prefix tmp/browser-qa playwright
const { chromium } = require("../tmp/browser-qa/node_modules/playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const path = require("node:path");

(async () => {
  const baseURL = process.env.QA_BASE_URL || "http://localhost:3000";
  const output = path.resolve("tmp/screenshots");
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, locale: "pt-BR" });
  const page = await context.newPage();
  const errors = [];
  page.on("pageerror", error => errors.push(error.stack || error.message));
  page.on("console", message => {
    if (message.type() === "error" && !message.text().includes("Failed to load resource")) errors.push(message.text());
  });
  page.setDefaultTimeout(15000);
  async function capture(name) {
    await page.locator(".turbo-progress-bar").waitFor({ state: "hidden" });
    assert(!/translation missing/i.test(await page.locator("body").innerText()), `Tradução ausente: ${name}`);
    await page.screenshot({ path: path.join(output, name + ".png"), fullPage: true });
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `Overflow horizontal: ${name}`);
  }
  async function login(email) {
    await page.goto(baseURL + "/entrar");
    await page.getByLabel("E-mail", { exact: true }).fill(email);
    await page.getByLabel("Senha", { exact: true }).fill("senha123");
    await page.getByRole("button", { name: "Entrar", exact: true }).click();
    await page.waitForURL("**/painel");
  }
  async function logout() {
    await page.getByRole("button", { name: "Sair da conta" }).click();
    await page.waitForURL(baseURL + "/");
  }
  try {
    await page.goto(baseURL);
    await page.locator(".profile-card").first().waitFor();
    await page.keyboard.press("Escape");
    await capture("01-home-desktop");
    if (process.argv.includes("--probe")) {
      await page.getByRole("link", { name: /Acessar como estudante/ }).click();
      await page.waitForURL("**/entrar?perfil=estagiario");
      assert.deepEqual(errors, [], "Páginas públicas não devem produzir erros de JavaScript");
      return;
    }
    await page.setViewportSize({ width: 390, height: 844 });
    await capture("02-home-mobile");
    await page.getByRole("link", { name: /Acessar como estudante/ }).click();
    await page.waitForURL("**/entrar?perfil=estagiario");
    await capture("03-login-mobile");
    await page.getByLabel("E-mail", { exact: true }).fill("maria.estagiaria@unilavras.edu.br");
    await page.getByLabel("Senha", { exact: true }).fill("senha123");
    await page.getByRole("button", { name: "Entrar", exact: true }).click();
    await page.waitForURL("**/painel");
    await capture("04-estudante-mobile");
    const menu = page.getByRole("button", { name: "Abrir menu" });
    await menu.click();
    assert.equal(await menu.getAttribute("aria-expanded"), "true");
    await page.keyboard.press("Escape");
    assert.equal(await menu.getAttribute("aria-expanded"), "false");
    await page.setViewportSize({ width: 1440, height: 1000 });
    await capture("05-estudante-desktop");
    await page.getByRole("link", { name: "Consultas", exact: true }).click();
    await page.waitForURL("**/consultas");
    await page.evaluate(() => { window.qaFrameMarker = "preservado"; });
    await page.getByLabel("Paciente", { exact: true }).fill("Paciente que não existe QA");
    await page.getByRole("button", { name: "Filtrar", exact: true }).click();
    await page.getByRole("heading", { name: "Nenhuma consulta encontrada" }).waitFor();
    assert.equal(await page.evaluate(() => window.qaFrameMarker), "preservado", "Filtro deve atualizar Turbo Frame sem reload completo");
    await capture("06-consultas-vazio");
    await page.getByRole("link", { name: "Nova consulta", exact: true }).click();
    await page.waitForURL("**/consultas/new");
    await capture("07-consulta-formulario");
    const paciente = "Paciente fictício QA " + Date.now();
    const dia = new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10);
    await page.getByLabel("Nome do paciente", { exact: true }).fill(paciente);
    await page.getByLabel("Sala", { exact: true }).fill("Sala QA " + Date.now());
    await page.getByLabel("Início", { exact: true }).fill(dia + "T17:00");
    await page.getByLabel("Fim", { exact: true }).fill(dia + "T17:10");
    await page.getByRole("button", { name: "Salvar consulta" }).click();
    await page.getByRole("alert").filter({ hasText: "durar entre" }).waitFor();
    assert.equal(await page.getByLabel("Nome do paciente", { exact: true }).inputValue(), paciente);
    await capture("08-consulta-erro");
    await page.getByLabel("Fim", { exact: true }).fill(dia + "T17:50");
    await page.getByRole("button", { name: "Salvar consulta" }).click();
    await page.waitForURL(/\/consultas\/\d+$/);
    const consultaURL = page.url();
    await capture("09-consulta-detalhes");
    await logout();
    await login("ana.supervisora@unilavras.edu.br");
    await capture("10-professor-desktop");
    await page.goto(consultaURL + "/edit");
    assert.equal(await page.getByLabel("Sala", { exact: true }).count(), 0);
    await page.getByLabel("Status", { exact: true }).selectOption("confirmada");
    await page.getByLabel("Observações", { exact: true }).fill("Observação fictícia de validação do frontend.");
    await page.getByRole("button", { name: "Salvar consulta" }).click();
    await page.waitForURL(consultaURL);
    await logout();
    await login("admin@unilavras.edu.br");
    await capture("11-admin-desktop");
    await page.goto(consultaURL);
    await page.getByRole("button", { name: "Excluir consulta", exact: true }).click();
    await page.getByRole("dialog").waitFor();
    await capture("12-confirmacao");
    await page.getByRole("button", { name: "Cancelar", exact: true }).click();
    assert.equal(page.url(), consultaURL);
    await page.getByRole("button", { name: "Excluir consulta", exact: true }).click();
    await page.getByRole("button", { name: "Confirmar exclusão", exact: true }).click();
    await page.waitForURL("**/consultas");
    await page.getByRole("link", { name: "Professores", exact: true }).click();
    await page.waitForURL("**/professores");
    await capture("13-professores-desktop");
    await page.getByRole("link", { name: "Novo professor", exact: true }).click();
    await page.getByLabel("Nome", { exact: true }).fill("Professor fictício QA");
    await page.getByLabel("E-mail", { exact: true }).fill(`qa.${Date.now()}@example.test`);
    await page.getByLabel("Senha", { exact: true }).fill("senha123");
    await page.getByRole("button", { name: "Salvar professor" }).click();
    await page.waitForURL(/\/professores\/\d+$/);
    await page.getByRole("link", { name: "Editar professor", exact: true }).click();
    await page.getByLabel("Nome", { exact: true }).fill("Professor QA atualizado");
    await page.getByRole("button", { name: "Salvar professor" }).click();
    await page.waitForURL(/\/professores\/\d+$/);
    await page.getByRole("heading", { name: "Professor QA atualizado" }).waitFor();
    await page.getByRole("button", { name: "Excluir professor", exact: true }).click();
    await page.getByRole("button", { name: "Confirmar exclusão", exact: true }).click();
    await page.waitForURL("**/professores");
    await page.setViewportSize({ width: 320, height: 740 });
    await capture("14-professores-mobile-320");
    await page.goto(baseURL + "/painel");
    await capture("15-admin-mobile-320");
    await page.getByRole("button", { name: "Abrir menu" }).click();
    await logout();
    await capture("16-home-mobile-320");
    assert.deepEqual(errors, [], "Não deve haver erros JavaScript");
    console.log("PASS: home, login, 3 perfis, Turbo Frame, menu móvel, validação, CRUD, confirmação; 16 capturas; sem overflow ou erros JavaScript.");
  } catch (error) {
    console.error("Erros do navegador:", errors);
    await page.screenshot({ path: path.join(output, "falha.png"), fullPage: true });
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
