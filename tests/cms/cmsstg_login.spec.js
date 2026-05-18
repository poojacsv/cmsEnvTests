const { test, expect } = require('@playwright/test');
const { getUrl } = require('../../config/cmsUrls');
const { loginToCmsStg } = require('../../utils/login');

test.describe('cms staging login', () => {

  test('smoke test navigations', async ({ page }) => {

    // Step 1: Login to CMS staging.
    await loginToCmsStg(page);

    // Step 2: Validate CMS staging authenticated landing page.
    await expect(page).toHaveURL(/\/ecourt\/.*(dashboard|home|landing)/i);
    await expect(page.getByRole('link', { name: /log out/i })).toBeVisible();

    // Step 3: Navigate AFTER login (business flow).
    await page.goto(getUrl('dev', 'cmsPortalStg'), {
      waitUntil: 'domcontentloaded'
    });

    // Step 4: Validate CMS Portal staging navigation.
    await expect(page).toHaveURL(/cmsportalstg2\.testing\.courts\.vic\.gov\.au/i);

  });

});
