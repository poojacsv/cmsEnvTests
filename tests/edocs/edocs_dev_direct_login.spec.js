const { test, expect } = require('@playwright/test');
const { getUrl } = require('../../config/cmsUrls');

const username = process.env.EDOCS_DEV_DIRECT_USERNAME ;
const password = process.env.EDOCS_DEV_DIRECT_PASSWORD ;
const loginUrl = getUrl('dev', 'eDocsDev');
const hostPattern = /edocsdevps\.testing\.courts\.vic\.gov\.au/i;

async function login(page) {
  await page.goto(loginUrl, { waitUntil: 'domcontentloaded' });
  await expect(page).toHaveURL(hostPattern);

  await page.getByRole('textbox', { name: /user\s*name|username/i }).fill(username);
  await page.getByRole('textbox', { name: /password/i }).fill(password);
  await page.getByRole('button', { name: /log\s*in|login|sign\s*in/i }).click();

  await page.waitForURL(/\/ecourt\/.*(dashboard|home|landing)/i);
  await expect(page.getByText(/welcome/i)).toBeVisible();
  await expect(page.getByRole('link', { name: /dashboard/i })).toBeVisible();
}

async function checkLeftNavigationGroups(page) {
  const groups = [
    'Audit Log',
    'Workspace',
    'Magistrate View',
    'Finance',
    'Help Desk',
    'Searches',
    'Bulk Upload',
    'System Setup',
    'System Admin',
    'eCourt Setup',
  ];

  for (const group of groups) {
    await test.step(`left navigation group is available: ${group}`, async () => {
      const item = page.getByText(group, { exact: true }).first();
      await expect(item).toBeVisible();
      await item.click();
      await expect(page.locator('body')).not.toContainText(/404|500|internal server error|page not found/i);
    });
  }
}

test.describe('eDocs dev direct login', () => {
  test('logs in and primary navigation links work', async ({ page }) => {
    test.setTimeout(120000);

    await login(page);
    await checkLeftNavigationGroups(page);

    await page.getByRole('link', { name: /dashboard/i }).click();
    await expect(page).toHaveURL(/\/ecourt\/cms\/dashboard/i);
    await expect(page.locator('body')).not.toContainText(/internal server error|page not found/i);
  });
});
