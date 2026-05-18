// tests/utils/login.js
require('dotenv').config();
const { getUrl } = require('../config/cmsUrls');

async function loginToEcourt(page) {
  await page.goto(getUrl('prod', 'cmsProd'));

  await page.getByRole('textbox', { name: 'Username' })
    .fill(process.env.ECOURT_USERNAME);

  await page.getByRole('textbox', { name: 'Password' })
    .fill(process.env.ECOURT_PASSWORD);

  await page.getByRole('button', { name: 'Log In' }).click();

  // Wait for successful login (adjust selector/URL)
  await page.waitForURL(/dashboard|home|landing/);
}

async function loginToCmsStg(page) {
  await page.goto(getUrl('dev', 'cmsStg'));

  await page.getByRole('textbox', { name: 'Username' })
    .fill(process.env.CMS_STG_USERNAME);

  await page.getByRole('textbox', { name: 'Password' })
    .fill(process.env.CMS_STG_PASSWORD);

  await page.getByRole('button', { name: 'Log In' }).click();

  // Wait for successful login (adjust selector/URL)
  await page.waitForURL(/dashboard|home|landing/);
}

module.exports = { loginToEcourt, loginToCmsStg };
