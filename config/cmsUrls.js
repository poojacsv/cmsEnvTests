/**
 * Utility function to get URLs for use in Playwright spec files.
 */

const cmsUrls = {
    dev: {
        eDocsDev: 'https://edocsdevps.testing.courts.vic.gov.au/ecourt/login.jsp',
        eDocsPortal: 'https://edocsportaldevps.testing.courts.vic.gov.au/edocsdevps/',
        cmsStg: 'https://cmsstg2.testing.courts.vic.gov.au/ecourt/login.jsp',
        cmsPortalStg: 'https://cmsportalstg2.testing.courts.vic.gov.au/cmsportal-stg2/'
    },
    staging: {
        // TODO: add staging URLs
    },
    prod: {
        cmsProd: 'https://cms.courts.vic.gov.au/ecourt/login.jsp',
        cmsPortalProd: 'https://cmsportal.courts.vic.gov.au/',
        eDocsProd: 'https://edocs.courts.vic.gov.au/ecourt/login.jsp',
        eDocsPortal: 'https://edocsportal.courts.vic.gov.au/'
    }
};

function getUrl(env = 'dev', entity = 'eDocsDev') {
    return cmsUrls[env]?.[entity] || cmsUrls.dev.eDocsDev;
}

module.exports = { getUrl };
