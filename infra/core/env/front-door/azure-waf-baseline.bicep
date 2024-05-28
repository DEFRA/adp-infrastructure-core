@description('Required. The name of the Front Door WAF Policy to create.')
param wafPolicyName string

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules array = []

@description('Optional. The list of managed rule sets to configure on the WAF (DRS).')
param managedRuleSets array = []

@description('Optional. The PolicySettings object (enabledState,mode) for policy.')
param policySettings object = {
  enabledState: 'Enabled'
  mode: 'Prevention'
}

@description('Required. Environment name.')
param environment string

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

var customBlockResponseBody = '<!DOCTYPE html><html lang="en" class="govuk-template"><head><meta charset="utf-8"><title>
      Defra Service Error
    </title><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><meta name="theme-color" content="#0b0c0c"><link rel="icon" sizes="48x48" href="/assets/images/favicon.ico"><link rel="mask-icon" href="/assets/images/govuk-mask-icon.svg" color="#0b0c0c"><link rel="apple-touch-icon" href="/assets/images/govuk-apple-touch-icon-180x180.png"><style>@charset "UTF-8";:root {--govuk-frontend-version: "4.8.0";}
@font-face {font-family: GDS Transport; font-style: normal; font-weight: 400; src: url(./assets/fonts/light-94a07e06a1-v2.woff2) format("woff2"),url(./assets/fonts/light-f591b13f7d-v2.woff) format("woff"); font-display: fallback;}
@font-face {font-family: GDS Transport; font-style: normal; font-weight: 700; src: url(./assets/fonts/bold-b542beb274-v2.woff2) format("woff2"),url(./assets/fonts/bold-affa96571d-v2.woff) format("woff"); font-display: fallback;}
.govuk-body,.govuk-body-m {color: #0b0c0c; font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 400; font-size: 1rem; line-height: 1.25; margin-top: 0; margin-bottom: 15px;}
@media print {.govuk-body,.govuk-body-m {color: #000;}}
@media print {.govuk-body,.govuk-body-m {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-body,.govuk-body-m {font-size: 1.1875rem; line-height: 1.3157894737;}}
@media print {.govuk-body,.govuk-body-m {font-size: 14pt; line-height: 1.15;}}
@media (min-width: 40.0625em) {.govuk-body,.govuk-body-m {margin-bottom: 20px;}}
.govuk-main-wrapper {display: block; padding-top: 20px; padding-bottom: 20px;}
@media (min-width: 40.0625em) {.govuk-main-wrapper {padding-top: 40px; padding-bottom: 40px;}}
.govuk-template {background-color: #f3f2f1; -webkit-text-size-adjust: 100%; -moz-text-size-adjust: 100%; text-size-adjust: 100%;}
@supports (position: -webkit-sticky) or (position: sticky) {.govuk-template {scroll-padding-top: 60px;}.govuk-template:not(:has(.govuk-exit-this-page)) {scroll-padding-top: 0;}}
@media screen {.govuk-template {overflow-y: scroll;}}
.govuk-template__body {margin: 0; background-color: #fff;}
.govuk-width-container {max-width: 960px; margin-right: 15px; margin-left: 15px;}
@supports (margin: max(0px)) {.govuk-width-container {margin-right: max(15px,calc(15px + env(safe-area-inset-right))); margin-left: max(15px,calc(15px + env(safe-area-inset-left)));}}
@media (min-width: 40.0625em) {.govuk-width-container {margin-right: 30px; margin-left: 30px;}@supports (margin: max(0px)) {.govuk-width-container {margin-right: max(30px,calc(15px + env(safe-area-inset-right))); margin-left: max(30px,calc(15px + env(safe-area-inset-left)));}}}
@media (min-width: 1020px) {.govuk-width-container {margin-right: auto; margin-left: auto;}@supports (margin: max(0px)) {.govuk-width-container {margin-right: auto; margin-left: auto;}}}
@supports (content-visibility: hidden) {.js-enabled .govuk-accordion__section-content[hidden] {content-visibility: hidden; display: inherit;}}
@supports (border-width: max(0px)) {.govuk-back-link:before {border-width: max(1px,.0625em) max(1px,.0625em) 0 0; font-size: max(16px,1em);}}
@supports (border-width: max(0px)) {.govuk-breadcrumbs__list-item:before {border-width: max(1px,.0625em) max(1px,.0625em) 0 0; font-size: max(16px,1em);}}
@supports not (caret-color: auto) {.govuk-fieldset,x:-moz-any-link {display: table-cell;}}
@supports (font-variant-numeric: tabular-nums) {.govuk-character-count__message {-webkit-font-feature-settings: normal; font-feature-settings: normal; font-variant-numeric: tabular-nums;}}
@supports (font-variant-numeric: tabular-nums) {.govuk-input--extra-letter-spacing {-webkit-font-feature-settings: normal; font-feature-settings: normal; font-variant-numeric: tabular-nums;}}
.govuk-error-summary {color: #0b0c0c; padding: 15px; margin-bottom: 30px; border: 5px solid #d4351c;}
@media print {.govuk-error-summary {color: #000;}}
@media (min-width: 40.0625em) {.govuk-error-summary {padding: 20px;}}
@media (min-width: 40.0625em) {.govuk-error-summary {margin-bottom: 50px;}}
.govuk-error-summary:focus {outline: 3px solid #ffdd00;}
.govuk-error-summary__title {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 700; font-size: 1.125rem; line-height: 1.1111111111; margin-top: 0; margin-bottom: 15px;}
@media print {.govuk-error-summary__title {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-error-summary__title {font-size: 1.5rem; line-height: 1.25;}}
@media print {.govuk-error-summary__title {font-size: 18pt; line-height: 1.15;}}
@media (min-width: 40.0625em) {.govuk-error-summary__title {margin-bottom: 20px;}}
.govuk-error-summary__body {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 400; font-size: 1rem; line-height: 1.25;}
@media print {.govuk-error-summary__body {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-error-summary__body {font-size: 1.1875rem; line-height: 1.3157894737;}}
@media print {.govuk-error-summary__body {font-size: 14pt; line-height: 1.15;}}
.govuk-error-summary__body p {margin-top: 0; margin-bottom: 15px;}
@media (min-width: 40.0625em) {.govuk-error-summary__body p {margin-bottom: 20px;}}
.govuk-footer {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 400; font-size: .875rem; line-height: 1.1428571429; padding-top: 25px; padding-bottom: 15px; border-top: 1px solid #b1b4b6; color: #0b0c0c; background: #f3f2f1;}
@media print {.govuk-footer {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-footer {font-size: 1rem; line-height: 1.25;}}
@media print {.govuk-footer {font-size: 14pt; line-height: 1.2;}}
@media (min-width: 40.0625em) {.govuk-footer {padding-top: 40px;}}
@media (min-width: 40.0625em) {.govuk-footer {padding-bottom: 25px;}}
.govuk-footer__link {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; text-decoration: underline;}
@media print {.govuk-footer__link {font-family: sans-serif;}}
.govuk-footer__link:focus {outline: 3px solid transparent; color: #0b0c0c; background-color: #fd0; box-shadow: 0 -2px #fd0,0 4px #0b0c0c; text-decoration: none; -webkit-box-decoration-break: clone; box-decoration-break: clone;}
.govuk-footer__link:link,.govuk-footer__link:visited {color: #0b0c0c;}
@media print {.govuk-footer__link:link,.govuk-footer__link:visited {color: #000;}}
.govuk-footer__link:hover {color: #0b0c0cfc;}
.govuk-footer__link:active,.govuk-footer__link:focus {color: #0b0c0c;}
@media print {.govuk-footer__link:active,.govuk-footer__link:focus {color: #000;}}
.govuk-footer__meta {display: flex; margin-right: -15px; margin-left: -15px; -ms-flex-wrap: wrap; flex-wrap: wrap; -ms-flex-align: end; align-items: flex-end; -ms-flex-pack: center; justify-content: center;}
.govuk-footer__meta-item {margin-right: 15px; margin-bottom: 25px; margin-left: 15px;}
.govuk-footer__meta-item--grow {-ms-flex: 1; flex: 1;}
@media (max-width: 40.0525em) {.govuk-footer__meta-item--grow {-ms-flex-preferred-size: 320px; flex-basis: 320px;}}
.govuk-footer__licence-logo {display: inline-block; margin-right: 10px; vertical-align: top; forced-color-adjust: auto;}
@media (max-width: 48.0525em) {.govuk-footer__licence-logo {margin-bottom: 15px;}}
.govuk-footer__licence-description {display: inline-block;}
.govuk-footer__copyright-logo {display: inline-block; min-width: 125px; padding-top: 112px; background-image: url(/assets/images/govuk-crest.png); background-repeat: no-repeat; background-position: 50% 0%; background-size: 125px 102px; text-align: center; white-space: nowrap;}
@media only screen and (-webkit-min-device-pixel-ratio: 2), only screen and (min-resolution: 192dpi), only screen and (min-resolution: 2dppx) {.govuk-footer__copyright-logo {background-image: url(/assets/images/govuk-crest-2x.png);}}
.govuk-header {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 400; font-size: .875rem; line-height: 1.1428571429; border-bottom: 10px solid #ffffff; color: #fff; background: #0b0c0c;}
@media print {.govuk-header {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-header {font-size: 1rem; line-height: 1.25;}}
@media print {.govuk-header {font-size: 14pt; line-height: 1.2;}}
.govuk-header__container {position: relative; margin-bottom: -10px; padding-top: 10px; border-bottom: 10px solid #1d70b8;}
.govuk-header__container:after {content: ""; display: block; clear: both;}
.govuk-header__logotype {display: inline-block; margin-right: 5px;}
@media (forced-colors: active) {.govuk-header__logotype {forced-color-adjust: none; color: linktext;}}
.govuk-header__logotype:last-child {margin-right: 0;}
.govuk-header__link {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; text-decoration: none;}
@media print {.govuk-header__link {font-family: sans-serif;}}
.govuk-header__link:link,.govuk-header__link:visited {color: #fff;}
.govuk-header__link:hover,.govuk-header__link:active {color: #fffffffc;}
.govuk-header__link:focus {color: #0b0c0c;}
.govuk-header__link:hover {text-decoration: underline; text-decoration-thickness: 3px; text-underline-offset: .1578em;}
.govuk-header__link:focus {outline: 3px solid transparent; color: #0b0c0c; background-color: #fd0; box-shadow: 0 -2px #fd0,0 4px #0b0c0c; text-decoration: none; -webkit-box-decoration-break: clone; box-decoration-break: clone;}
.govuk-header__link--homepage {font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; font-weight: 700; display: inline-block; margin-right: 10px; font-size: 30px; line-height: 1;}
@media print {.govuk-header__link--homepage {font-family: sans-serif;}}
@media (min-width: 40.0625em) {.govuk-header__link--homepage {display: inline;}.govuk-header__link--homepage:focus {box-shadow: 0 0 #fd0;}}
.govuk-header__link--homepage:link,.govuk-header__link--homepage:visited {text-decoration: none;}
.govuk-header__link--homepage:hover,.govuk-header__link--homepage:active {margin-bottom: -3px; border-bottom: 3px solid;}
.govuk-header__link--homepage:focus {margin-bottom: 0; border-bottom: 0;}
.govuk-header__logo,.govuk-header__content {box-sizing: border-box;}
.govuk-header__logo {margin-bottom: 10px; padding-right: 50px;}
@media (min-width: 48.0625em) {.govuk-header__logo {width: 33.33%; padding-right: 15px; float: left; vertical-align: top;}}
@media print {.govuk-header {border-bottom-width: 0; color: #0b0c0c; background: transparent;}.govuk-header__logotype-crown-fallback-image {display: none;}.govuk-header__link:link,.govuk-header__link:visited {color: #0b0c0c;}.govuk-header__link:after {display: none;}}
.govuk-skip-link {position: absolute !important; width: 1px !important; height: 1px !important; margin: 0 !important; overflow: hidden !important; clip: rect(0 0 0 0) !important; -webkit-clip-path: inset(50%) !important; clip-path: inset(50%) !important; white-space: nowrap !important; font-family: GDS Transport,arial,sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; text-decoration: underline; font-size: .875rem; line-height: 1.1428571429; display: block; padding: 10px 15px;}
.govuk-skip-link:active,.govuk-skip-link:focus {position: static !important; width: auto !important; height: auto !important; margin: inherit !important; overflow: visible !important; clip: auto !important; -webkit-clip-path: none !important; clip-path: none !important; white-space: inherit !important;}
@media print {.govuk-skip-link {font-family: sans-serif;}}
.govuk-skip-link:link,.govuk-skip-link:visited {color: #0b0c0c;}
@media print {.govuk-skip-link:link,.govuk-skip-link:visited {color: #000;}}
.govuk-skip-link:hover {color: #0b0c0cfc;}
.govuk-skip-link:active,.govuk-skip-link:focus {color: #0b0c0c;}
@media print {.govuk-skip-link:active,.govuk-skip-link:focus {color: #000;}}
@media (min-width: 40.0625em) {.govuk-skip-link {font-size: 1rem; line-height: 1.25;}}
@media print {.govuk-skip-link {font-size: 14pt; line-height: 1.2;}}
@supports (padding: max(0px)) {.govuk-skip-link {padding-right: max(15px,calc(15px + env(safe-area-inset-right))); padding-left: max(15px,calc(15px + env(safe-area-inset-left)));}}
.govuk-skip-link:focus {outline: 3px solid #ffdd00; outline-offset: 0; background-color: #fd0;}
@supports (font-variant-numeric: tabular-nums) {.govuk-table__cell--numeric {-webkit-font-feature-settings: normal; font-feature-settings: normal; font-variant-numeric: tabular-nums;}}
</style></head> <body class="govuk-template__body"> <a href="#main-content" class="govuk-skip-link" data-module="govuk-skip-link">Skip to main content</a> <header class="govuk-header" data-module="govuk-header"> <div class="govuk-header__container govuk-width-container"> <div class="govuk-header__logo"> <a href="/" class="govuk-header__link govuk-header__link--homepage"> <svg focusable="false" role="img" class="govuk-header__logotype" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 148 30" height="30" width="148" aria-label="GOV.UK" fill="white"> <title>GOV.UK</title> <path d="M22.6 10.4c-1 .4-2-.1-2.4-1-.4-.9.1-2 1-2.4.9-.4 2 .1 2.4 1s-.1 2-1 2.4m-5.9 6.7c-.9.4-2-.1-2.4-1-.4-.9.1-2 1-2.4.9-.4 2 .1 2.4 1s-.1 2-1 2.4m10.8-3.7c-1 .4-2-.1-2.4-1-.4-.9.1-2 1-2.4.9-.4 2 .1 2.4 1s0 2-1 2.4m3.3 4.8c-1 .4-2-.1-2.4-1-.4-.9.1-2 1-2.4.9-.4 2 .1 2.4 1s-.1 2-1 2.4M17 4.7l2.3 1.2V2.5l-2.3.7-.2-.2.9-3h-3.4l.9 3-.2.2c-.1.1-2.3-.7-2.3-.7v3.4L15 4.7c.1.1.1.2.2.2l-1.3 4c-.1.2-.1.4-.1.6 0 1.1.8 2 1.9 2.2h.7c1-.2 1.9-1.1 1.9-2.1 0-.2 0-.4-.1-.6l-1.3-4c-.1-.2 0-.2.1-.3m-7.6 5.7c.9.4 2-.1 2.4-1 .4-.9-.1-2-1-2.4-.9-.4-2 .1-2.4 1s0 2 1 2.4m-5 3c.9.4 2-.1 2.4-1 .4-.9-.1-2-1-2.4-.9-.4-2 .1-2.4 1s.1 2 1 2.4m-3.2 4.8c.9.4 2-.1 2.4-1 .4-.9-.1-2-1-2.4-.9-.4-2 .1-2.4 1s0 2 1 2.4m14.8 11c4.4 0 8.6.3 12.3.8 1.1-4.5 2.4-7 3.7-8.8l-2.5-.9c.2 1.3.3 1.9 0 2.7-.4-.4-.8-1.1-1.1-2.3l-1.2 4c.7-.5 1.3-.8 2-.9-1.1 2.5-2.6 3.1-3.5 3-1.1-.2-1.7-1.2-1.5-2.1.3-1.2 1.5-1.5 2.1-.1 1.1-2.3-.8-3-2-2.3 1.9-1.9 2.1-3.5.6-5.6-2.1 1.6-2.1 3.2-1.2 5.5-1.2-1.4-3.2-.6-2.5 1.6.9-1.4 2.1-.5 1.9.8-.2 1.1-1.7 2.1-3.5 1.9-2.7-.2-2.9-2.1-2.9-3.6.7-.1 1.9.5 2.9 1.9l.4-4.3c-1.1 1.1-2.1 1.4-3.2 1.4.4-1.2 2.1-3 2.1-3h-5.4s1.7 1.9 2.1 3c-1.1 0-2.1-.2-3.2-1.4l.4 4.3c1-1.4 2.2-2 2.9-1.9-.1 1.5-.2 3.4-2.9 3.6-1.9.2-3.4-.8-3.5-1.9-.2-1.3 1-2.2 1.9-.8.7-2.3-1.2-3-2.5-1.6.9-2.2.9-3.9-1.2-5.5-1.5 2-1.3 3.7.6 5.6-1.2-.7-3.1 0-2 2.3.6-1.4 1.8-1.1 2.1.1.2.9-.3 1.9-1.5 2.1-.9.2-2.4-.5-3.5-3 .6 0 1.2.3 2 .9l-1.2-4c-.3 1.1-.7 1.9-1.1 2.3-.3-.8-.2-1.4 0-2.7l-2.9.9C1.3 23 2.6 25.5 3.7 30c3.7-.5 7.9-.8 12.3-.8m28.3-11.6c0 .9.1 1.7.3 2.5.2.8.6 1.5 1 2.2.5.6 1 1.1 1.7 1.5.7.4 1.5.6 2.5.6.9 0 1.7-.1 2.3-.4s1.1-.7 1.5-1.1c.4-.4.6-.9.8-1.5.1-.5.2-1 .2-1.5v-.2h-5.3v-3.2h9.4V28H55v-2.5c-.3.4-.6.8-1 1.1-.4.3-.8.6-1.3.9-.5.2-1 .4-1.6.6s-1.2.2-1.8.2c-1.5 0-2.9-.3-4-.8-1.2-.6-2.2-1.3-3-2.3-.8-1-1.4-2.1-1.8-3.4-.3-1.4-.5-2.8-.5-4.3s.2-2.9.7-4.2c.5-1.3 1.1-2.4 2-3.4.9-1 1.9-1.7 3.1-2.3 1.2-.6 2.6-.8 4.1-.8 1 0 1.9.1 2.8.3.9.2 1.7.6 2.4 1s1.4.9 1.9 1.5c.6.6 1 1.3 1.4 2l-3.7 2.1c-.2-.4-.5-.9-.8-1.2-.3-.4-.6-.7-1-1-.4-.3-.8-.5-1.3-.7-.5-.2-1.1-.2-1.7-.2-1 0-1.8.2-2.5.6-.7.4-1.3.9-1.7 1.5-.5.6-.8 1.4-1 2.2-.3.8-.4 1.9-.4 2.7zM71.5 6.8c1.5 0 2.9.3 4.2.8 1.2.6 2.3 1.3 3.1 2.3.9 1 1.5 2.1 2 3.4s.7 2.7.7 4.2-.2 2.9-.7 4.2c-.4 1.3-1.1 2.4-2 3.4-.9 1-1.9 1.7-3.1 2.3-1.2.6-2.6.8-4.2.8s-2.9-.3-4.2-.8c-1.2-.6-2.3-1.3-3.1-2.3-.9-1-1.5-2.1-2-3.4-.4-1.3-.7-2.7-.7-4.2s.2-2.9.7-4.2c.4-1.3 1.1-2.4 2-3.4.9-1 1.9-1.7 3.1-2.3 1.2-.5 2.6-.8 4.2-.8zm0 17.6c.9 0 1.7-.2 2.4-.5s1.3-.8 1.7-1.4c.5-.6.8-1.3 1.1-2.2.2-.8.4-1.7.4-2.7v-.1c0-1-.1-1.9-.4-2.7-.2-.8-.6-1.6-1.1-2.2-.5-.6-1.1-1.1-1.7-1.4-.7-.3-1.5-.5-2.4-.5s-1.7.2-2.4.5-1.3.8-1.7 1.4c-.5.6-.8 1.3-1.1 2.2-.2.8-.4 1.7-.4 2.7v.1c0 1 .1 1.9.4 2.7.2.8.6 1.6 1.1 2.2.5.6 1.1 1.1 1.7 1.4.6.3 1.4.5 2.4.5zM88.9 28 83 7h4.7l4 15.7h.1l4-15.7h4.7l-5.9 21h-5.7zm28.8-3.6c.6 0 1.2-.1 1.7-.3.5-.2 1-.4 1.4-.8.4-.4.7-.8.9-1.4.2-.6.3-1.2.3-2v-13h4.1v13.6c0 1.2-.2 2.2-.6 3.1s-1 1.7-1.8 2.4c-.7.7-1.6 1.2-2.7 1.5-1 .4-2.2.5-3.4.5-1.2 0-2.4-.2-3.4-.5-1-.4-1.9-.9-2.7-1.5-.8-.7-1.3-1.5-1.8-2.4-.4-.9-.6-2-.6-3.1V6.9h4.2v13c0 .8.1 1.4.3 2 .2.6.5 1 .9 1.4.4.4.8.6 1.4.8.6.2 1.1.3 1.8.3zm13-17.4h4.2v9.1l7.4-9.1h5.2l-7.2 8.4L148 28h-4.9l-5.5-9.4-2.7 3V28h-4.2V7zm-27.6 16.1c-1.5 0-2.7 1.2-2.7 2.7s1.2 2.7 2.7 2.7 2.7-1.2 2.7-2.7-1.2-2.7-2.7-2.7z"></path> </svg> </a> </div> </div> </header> <div class="govuk-width-container">  <main class="govuk-main-wrapper" id="main-content"> <div class="govuk-error-summary"> <div role="alert"></div> <h1 class="govuk-error-summary__title">
Unfortunately, there is a problem with your request
</h1> <div class="govuk-error-summary__body"> <p class="govuk-body"> <b>Your request has been blocked.</b> Please contact the site administrator
          or the Defra helpdesk with the following information.
</p> <p class="govuk-body"> <b>Tracking Request ID</b>: {{azure-ref}} </p> </div> </div> </main>  </div> <footer class="govuk-footer"> <div class="govuk-width-container"> <div class="govuk-footer__meta"> <div class="govuk-footer__meta-item govuk-footer__meta-item--grow"> <svg aria-hidden="true" focusable="false" class="govuk-footer__licence-logo" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 483.2 195.7" height="17" width="41"> <path fill="currentColor" d="M421.5 142.8V.1l-50.7 32.3v161.1h112.4v-50.7zm-122.3-9.6A47.12 47.12 0 0 1 221 97.8c0-26 21.1-47.1 47.1-47.1 16.7 0 31.4 8.7 39.7 21.8l42.7-27.2A97.63 97.63 0 0 0 268.1 0c-36.5 0-68.3 20.1-85.1 49.7A98 98 0 0 0 97.8 0C43.9 0 0 43.9 0 97.8s43.9 97.8 97.8 97.8c36.5 0 68.3-20.1 85.1-49.7a97.76 97.76 0 0 0 149.6 25.4l19.4 22.2h3v-87.8h-80l24.3 27.5zM97.8 145c-26 0-47.1-21.1-47.1-47.1s21.1-47.1 47.1-47.1 47.2 21 47.2 47S123.8 145 97.8 145"></path> </svg> <span class="govuk-footer__licence-description">
All content is available under the
<a class="govuk-footer__link" href="https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/" rel="license">Open Government Licence v3.0</a>, except where otherwise stated
</span> </div> <div class="govuk-footer__meta-item"> <a class="govuk-footer__link govuk-footer__copyright-logo" href="https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/">
© Crown copyright
</a> </div> </div> </div> </footer> </body></html>'

module frontDoorWafPolicy 'br/SharedDefraRegistry:network.front-door-web-application-firewall-policy:0.4.1' = {
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
      rules: customRules
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
