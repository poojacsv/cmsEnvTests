# CMS, eCourt, and eEDocs Test Summary

## Latest Run

- Started: 05/18/2026 02:00:04
- Machine path: `C:\Users\vidhuad\CMS-Automation\CMS-env-tests`
- Browser projects: `chrome`, `edge`
- Mode: headed
- Command:

```powershell
npx playwright test tests/cms/cmsstg_login.spec.js tests/ecourt/ecourt_login.spec.js tests/edocs/edocs_portal_login.spec.js --project=chrome --project=edge --headed --reporter=json
```

## Overall Result

- Total test runs: 8
- Passed: 8
- Failed: 0
- Skipped: 0
- Duration: 34.7s
- JSON result: `C:\Users\vidhuad\CMS-Automation\CMS-env-tests\scheduled-test-logs\cms-ecourt-edocs-20260518-115959.json`
- Console log: `C:\Users\vidhuad\CMS-Automation\CMS-env-tests\scheduled-test-logs\cms-ecourt-edocs-20260518-115959.log`

## Test Results

| Browser | Spec | Test | Result | Duration |
| --- | --- | --- | --- | --- |
| chrome | `cms\cmsstg_login.spec.js` | cms staging login > smoke test navigations | passed | 14.3s |
| edge | `cms\cmsstg_login.spec.js` | cms staging login > smoke test navigations | passed | 12.8s |
| chrome | `ecourt\ecourt_login.spec.js` | ecourt login > smoke test navigations | passed | 11.8s |
| edge | `ecourt\ecourt_login.spec.js` | ecourt login > smoke test navigations | passed | 12.3s |
| chrome | `edocs\edocs_portal_login.spec.js` | eDocs portal login > dev login and my account URL works | passed | 14.2s |
| chrome | `edocs\edocs_portal_login.spec.js` | eDocs portal login > prod login and my account URL works | passed | 16.6s |
| edge | `edocs\edocs_portal_login.spec.js` | eDocs portal login > dev login and my account URL works | passed | 14.3s |
| edge | `edocs\edocs_portal_login.spec.js` | eDocs portal login > prod login and my account URL works | passed | 4.4s |
