import { defineConfig } from 'astro/config';
import trimCss from './integrations/trim-css.mjs';
import copyGovuk from './integrations/copy-govuk.mjs';

// https://astro.build/config
export default defineConfig({
    output: 'static',
    build: {
        inlineStylesheets: 'always'
    },
    integrations: [
        trimCss,
        copyGovuk
    ]
});
