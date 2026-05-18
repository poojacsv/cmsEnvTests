# CMS, eCourt, and eEDocs Test Summary

## Latest Run

- Started: 05/18/2026 01:58:27
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
- Duration: 28.8s
- JSON result: `C:\Users\vidhuad\CMS-Automation\CMS-env-tests\scheduled-test-logs\cms-ecourt-edocs-20260518-115823.json`
- Console log: `C:\Users\vidhuad\CMS-Automation\CMS-env-tests\scheduled-test-logs\cms-ecourt-edocs-20260518-115823.log`

## Test Results

| Browser | Spec | Test | Result | Duration |
| --- | --- | --- | --- | --- |
| chrome | `cms\cmsstg_login.spec.js` | cms staging login > smoke test navigations | passed | 5.4s |
| edge | `cms\cmsstg_login.spec.js` | cms staging login > smoke test navigations | passed | 10.4s |
| chrome | `ecourt\ecourt_login.spec.js` | ecourt login > smoke test navigations | passed | 11s |
| edge | `ecourt\ecourt_login.spec.js` | ecourt login > smoke test navigations | passed | 10.3s |
| chrome | `edocs\edocs_portal_login.spec.js` | eDocs portal login > dev login and my account URL works | passed | 20.2s |
| chrome | `edocs\edocs_portal_login.spec.js` | eDocs portal login > prod login and my account URL works | passed | 10.5s |
| edge | `edocs\edocs_portal_login.spec.js` | eDocs portal login > dev login and my account URL works | passed | 14.7s |
| edge | `edocs\edocs_portal_login.spec.js` | eDocs portal login > prod login and my account URL works | passed | 4.9s |
