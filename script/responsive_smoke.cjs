const { chromium } = require('../tmp/browser-qa/node_modules/playwright');
const assert = require('node:assert/strict');

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto('http://localhost:3000/entrar');
    await page.getByLabel('E-mail', { exact: true }).fill('admin@unilavras.edu.br');
    await page.getByLabel('Senha', { exact: true }).fill('senha123');
    await page.getByRole('button', { name: 'Entrar', exact: true }).click();
    await page.waitForURL('**/painel');
    await page.goto('http://localhost:3000/consultas');
    const consulta = await page.locator('.appointment-name').first().getAttribute('href');
    await page.goto('http://localhost:3000/professores');
    const professor = await page.getByRole('link', { name: 'Ver cadastro' }).first().getAttribute('href');
    for (const width of [2329, 1440, 1024, 768, 390, 320]) {
      await page.setViewportSize({ width, height: 1000 });
      for (const route of [consulta, professor, consulta + '/edit', '/professores/new', '/painel', '/consultas', '/professores']) {
        await page.goto('http://localhost:3000' + route);
        assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `Overflow: ${route} @ ${width}`);
        const workspace = await page.locator('.workspace').boundingBox();
        assert(Math.abs(workspace.x + workspace.width - width) < 2, `Área principal não ocupa a largura: ${route} @ ${width}`);
        if (route === consulta || route === professor) {
          const header = await page.locator('.page-header').boundingBox();
          const panel = await page.locator('.detail-panel').boundingBox();
          assert(Math.abs(header.width - panel.width) < 2, `Cabeçalho e cartão desalinhados: ${route} @ ${width}: ${header.width}/${panel.width}`);
          await page.screenshot({ path: `tmp/screenshots/responsive-${route.split('/')[1]}-${width}.png`, fullPage: true });
        }
      }
    }
    console.log('PASS: 7 telas em 6 larguras (320–2329px), detalhes alinhados e sem overflow.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
