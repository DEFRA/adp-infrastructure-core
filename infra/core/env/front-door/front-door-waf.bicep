@description('Required. The name of the Front Door WAF Policy to create.')
param wafPolicyName string

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules array = []

@description('Optional. The list of custom rule sets to configure on the WAF.')
param paloIPWAFcustomRule array = []

@description('Optional. The list of managed rule sets to configure on the WAF (DRS).')
param managedRuleSets array = []

@description('Optional. The PolicySettings object (enabledState,mode) for policy.')
param policySettings object = {
  enabledState: 'Enabled'
  mode: 'Prevention'
}

@description('Required. Environment name.')
param environment string

@description('Optional. Deploy the ADP Portal WAF Policy.')
param deployWAF string = 'false'

@description('Required. Purpose Tag.')
param purpose string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var location = 'global'

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var frontDoorWafTags = {
  Name: wafPolicyName
  Purpose: purpose
  Tier: 'Shared'
}

var customRule = (environment == 'PRD')? customRules : union(customRules,paloIPWAFcustomRule)
var customBlockResponseBody = '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#000000"><meta name="description" content="Backstage is an open platform for building developer portals"><link rel="icon" href="/favicon.ico"><link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png"><title>ADP Portal | Backstage</title><style>@charset "UTF-8";:root{--govuk-frontend-version:"4.7.0"}/*! Copyright (c) 2011 by Margaret Calvert & Henrik Kubel. All rights reserved. The font has been customised for exclusive use on gov.uk. This cut is not commercially available. */@font-face{font-family:"GDS Transport";font-style:normal;font-weight:400;src:url(/static/light-94a07e06a1-v2.bb962e0c1aef34ea7e4a.woff2) format("woff2"),url(/static/light-f591b13f7d-v2.f03d82c283b021916f42.woff) format("woff");font-display:fallback}@font-face{font-family:"GDS Transport";font-style:normal;font-weight:700;src:url(/static/bold-b542beb274-v2.616e5f212d1bb513477e.woff2) format("woff2"),url(/static/bold-affa96571d-v2.b092ddd69e01e5fb0b66.woff) format("woff");font-display:fallback}</style><style data-jss="" data-meta="MuiPaper">.MuiPaper-root-165{color:#fff;transition:box-shadow .3s cubic-bezier(.4, 0, .2, 1) 0s;background-color:#222;background-image:unset}.MuiPaper-elevation0-168{box-shadow:none}</style><style data-jss="" data-meta="MuiTypography">.MuiTypography-root-13{margin:0}.MuiTypography-body1-15{font-size:1rem;font-family:'GDS Transport',arial,sans-serif;font-weight:400;line-height:1.5}.MuiTypography-h1-18{font-size:54px;font-family:'GDS Transport',arial,sans-serif;font-weight:700;line-height:1.167;margin-bottom:10px}.MuiTypography-gutterBottom-33{margin-bottom:.35em}</style><style data-jss="" data-meta="MuiSvgIcon">.MuiSvgIcon-root-193{fill:currentColor;width:1em;height:1em;display:inline-block;font-size:1.5rem;transition:fill .2s cubic-bezier(.4, 0, .2, 1) 0s;flex-shrink:0;-moz-user-select:none}.MuiSvgIcon-fontSizeInherit-199{font-size:inherit}</style><style data-jss="" data-meta="MuiAlert">.MuiAlert-root-149{display:flex;padding:6px 16px;font-size:.875rem;font-family:'GDS Transport',arial,sans-serif;font-weight:400;line-height:1.43;border-radius:4px;background-color:transparent}.MuiAlert-standardSuccess-150 .MuiAlert-icon-162{color:#4caf50}.MuiAlert-standardInfo-151 .MuiAlert-icon-162{color:#2196f3}.MuiAlert-standardWarning-152 .MuiAlert-icon-162{color:#ff9800}.MuiAlert-standardError-153{background-color:#180605}.MuiAlert-standardError-153 .MuiAlert-icon-162{color:#f44336}.MuiAlert-outlinedSuccess-154 .MuiAlert-icon-162{color:#4caf50}.MuiAlert-outlinedInfo-155 .MuiAlert-icon-162{color:#2196f3}.MuiAlert-outlinedWarning-156 .MuiAlert-icon-162{color:#ff9800}.MuiAlert-outlinedError-157 .MuiAlert-icon-162{color:#f44336}.MuiAlert-icon-162{display:flex;opacity:.9;padding:7px 0;font-size:22px;margin-right:12px}.MuiAlert-message-163{padding:8px 0}</style><style data-jss="" data-meta="MuiGrid">.MuiGrid-container-44{width:100%;display:flex;flex-wrap:wrap;box-sizing:border-box}.MuiGrid-spacing-xs-4-69{width:calc(100% + 32px);margin:-16px}.MuiGrid-spacing-xs-4-69>.MuiGrid-item-45{padding:16px}</style><style data-jss="" data-meta="MuiCssBaseline">html{height:100%;box-sizing:border-box;font-family:'GDS Transport',arial,sans-serif;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}*,::after,::before{box-sizing:inherit}b{font-weight:700}body{color:#fff;height:100%;margin:0;font-size:.875rem;font-family:'GDS Transport',arial,sans-serif;font-weight:400;line-height:1.43;background-color:#313131;overscroll-behavior-y:none}@media print{body{background-color:#fff}}body::backdrop{background-color:#313131}</style><style data-jss="" data-meta="BackstageContent">.BackstageContent-root-146{grid-area:pageContent;min-width:0;padding-top:24px;padding-left:16px;padding-right:16px;padding-bottom:24px}@media (min-width:600px){.BackstageContent-root-146{padding-left:24px;padding-right:24px}}</style><style data-jss="" data-meta="BackstageHeader">.BackstageHeader-header-2{width:100%;display:flex;padding:24px;z-index:100;position:relative;grid-area:pageHeader;box-shadow:0 2px 4px -1px rgba(0,0,0,.2),0 4px 5px 0 rgba(0,0,0,.14),0 1px 10px 0 rgba(0,0,0,.12);align-items:center;border-bottom:4px solid #1d70b8;flex-direction:row;background-size:cover;background-image:none,linear-gradient(90deg,#171717,#171717);background-position:center}@media (max-width:959.95px){.BackstageHeader-header-2{flex-wrap:wrap}}.BackstageHeader-leftItemsBox-3{flex-grow:1;max-width:100%}.BackstageHeader-rightItemsBox-4{width:auto;align-items:center}.BackstageHeader-title-5{color:#fff;font-size:32px;word-break:break-word;margin-bottom:0}</style><style data-jss="" data-meta="BackstagePage">.BackstagePage-root-1{height:100vh;display:grid;overflow-y:auto;grid-template-rows:max-content auto 1fr;grid-template-areas:'pageHeader pageHeader pageHeader' 'pageSubheader pageSubheader pageSubheader' 'pageNav pageContent pageSidebar';grid-template-columns:auto 1fr auto}@media (max-width:599.95px){.BackstagePage-root-1{height:100%}}@media print{.BackstagePage-root-1{height:auto;display:block;overflow-y:inherit}}</style><style data-jss="" data-meta="MuiAlertTitle">.MuiAlertTitle-root-202{margin-top:-2px;font-weight:500}</style></head><body><div id="root"><main class="BackstagePage-root-1"><header class="BackstageHeader-header-2"><div class="BackstageHeader-leftItemsBox-3"><h1 class="MuiTypography-root-13 BackstageHeader-title-5 MuiTypography-h1-18" tabindex="-1">ADP Portal</h1></div><div class="BackstageHeader-rightItemsBox-4 MuiGrid-container-44 MuiGrid-spacing-xs-4-69"></div></header><article class="BackstageContent-root-146"><div class="MuiPaper-root-165 MuiAlert-root-149 MuiAlert-standardError-153 MuiPaper-elevation0-168" role="alert"><div class="MuiAlert-icon-162"><svg class="MuiSvgIcon-root-193 MuiSvgIcon-fontSizeInherit-199" focusable="false" viewBox="0 0 24 24" aria-hidden="true"><path d="M11 15h2v2h-2zm0-8h2v6h-2zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"></path></svg></div><div class="MuiAlert-message-163"><div class="MuiTypography-root-13 MuiAlertTitle-root-202 MuiTypography-body1-15 MuiTypography-gutterBottom-33">Unfortunately, there is a problem with your request</div><p><b>Your request has been blocked.</b> Please contact the site administrator or the Defra helpdesk with the following information.</p><p><b>Tracking Request ID</b>: {{azure-ref}}</p></div></div></article></main></div></body></html>'

module frontDoorWafPolicy 'br/SharedDefraRegistry:network.front-door-web-application-firewall-policy:0.4.1' = if(deployWAF == 'true') {
  name: 'fdwaf-${deploymentDate}'
  params: {
    name: wafPolicyName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, frontDoorWafTags)
    sku: 'Premium_AzureFrontDoor' // The Microsoft-managed WAF rule sets require the premium SKU of Front Door.
    policySettings: {
      enabledState: policySettings.enabledState
      mode: policySettings.mode
      redirectUrl: null
      customBlockResponseStatusCode: 403
      customBlockResponseBody: base64(customBlockResponseBody)
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: customRule
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
