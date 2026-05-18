const { test, expect } = require('@playwright/test');
const { getUrl } = require('../../config/cmsUrls');
const { loginToEcourt } = require('../../utils/login');

test.describe('ecourt login', () => {

  test('smoke test navigations', async ({ page }) => {

    // Step 1: Login to eCourt.
    await loginToEcourt(page);

    // Step 2: Validate eCourt authenticated landing page.
    await expect(page).toHaveURL(/\/ecourt\/.*(dashboard|home|landing)/i);
    await expect(page.getByRole('link', { name: /log out/i })).toBeVisible();

    // Step 3: Navigate AFTER login (business flow).
    await page.goto(getUrl('prod', 'cmsPortalProd'), {
      waitUntil: 'domcontentloaded'
    });

    // Step 4: Validate CMS Portal navigation.
    await expect(page).toHaveURL(/cmsportal\.courts\.vic\.gov\.au/i);

  });

});
