const { test, expect } = require('@playwright/test');
const { getUrl } = require('../../config/cmsUrls');

const username = process.env.EDOCS_USERNAME ;
const password = process.env.EDOCS_PASSWORD ;

const environments = [
  {
    name: 'dev',
    url: getUrl('dev', 'eDocsPortal'),
    hostPattern: /edocsportaldevps\.testing\.courts\.vic\.gov\.au/i,
  },
  {
    name: 'prod',
    url: getUrl('prod', 'eDocsPortal'),
    hostPattern: /edocsportal\.courts\.vic\.gov\.au/i,
  },
];

async function fillLoginForm(page) {
  await page.getByRole('textbox', { name: /user\s*name|username|e-?mail|email/i }).fill(username);
  await page.getByRole('textbox', { name: /password/i }).fill(password);

  const loginButton = page.getByRole('button', { name: /log\s*in|login|sign\s*in/i });
  await expect(loginButton).toBeVisible();
  await loginButton.click();
}

async function openLoginPage(page) {
  const loginLink = page.getByRole('link', { name: /log-?in|login|sign\s*in/i }).first();
  // Wait up to 15s for the primary login link to appear (CI can be slow).
  try { await loginLink.waitFor({ state: 'visible', timeout: 15000 }); } catch {}

  if ((await loginLink.count()) === 0) {
    // Fallbacks: try a login button, a link with 'login' in href, or navigate to /login
    const altButton = page.getByRole('button', { name: /log-?in|login|sign\s*in/i }).first();
    if ((await altButton.count()) > 0) {
      await altButton.waitFor({ state: 'visible', timeout: 5000 });
      await altButton.click();
    } else {
      const hrefLogin = page.locator('a[href*="login"]').first();
      if ((await hrefLogin.count()) > 0) {
        await hrefLogin.waitFor({ state: 'visible', timeout: 5000 });
        await hrefLogin.click();
      } else {
        const origin = new URL(page.url()).origin;
        await page.goto(`${origin}/login`, { waitUntil: 'domcontentloaded' });
      }
    }

    await page.getByRole('textbox', { name: /user\s*name|username|e-?mail|email/i }).waitFor({ state: 'visible', timeout: 10000 });
  } else {
    await loginLink.click();
    await page.getByRole('textbox', { name: /user\s*name|username|e-?mail|email/i }).waitFor({ state: 'visible', timeout: 10000 });
  }
}

async function openMyAccount(page) {
  const myAccountLink = page.getByRole('link', { name: /my\s*account/i }).first();
  await expect(myAccountLink).toBeVisible();
  await myAccountLink.click();
  await page.waitForLoadState('domcontentloaded');
}

test.describe('eDocs portal login', () => {
  for (const environment of environments) {
    test(`${environment.name} login and my account URL works`, async ({ page }) => {
      await page.goto(environment.url, { waitUntil: 'domcontentloaded' });
      await expect(page).toHaveURL(environment.hostPattern);

      await openLoginPage(page);
      await fillLoginForm(page);
      await expect(page.getByRole('link', { name: /log-?\s*out|logout/i })).toBeVisible();

      await openMyAccount(page);
      await expect(page).toHaveURL(/MyCases|my\s*account|myaccount|account/i);
      await expect(page).toHaveURL(environment.hostPattern);
    });
  }
});
