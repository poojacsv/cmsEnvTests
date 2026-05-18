const { test, expect } = require('@playwright/test');
const { getUrl } = require('../../config/cmsUrls');

const username = process.env.EDOCS_USERNAME || 'edocs.support@courts.vic.gov.au';
const password = process.env.EDOCS_PASSWORD || 'P@55w0rd';

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
  await expect(loginLink).toBeVisible();
  await loginLink.click();
  await expect(page.getByRole('textbox', { name: /user\s*name|username|e-?mail|email/i })).toBeVisible();
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
