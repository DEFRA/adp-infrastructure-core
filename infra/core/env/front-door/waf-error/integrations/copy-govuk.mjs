import path from 'node:path';
import fs from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

/** @type {import('astro').AstroIntegration} */
export default {
    name: 'copyGovuk',
    hooks: {
        async "astro:build:generated"({ dir }) {
            const govukDir = path.dirname(fileURLToPath(import.meta.resolve('govuk-frontend/govuk/all.js')));
            const govukAssets = path.join(govukDir, 'assets');
            const outDir = fileURLToPath(dir);
            await fs.cp(govukAssets, outDir, { recursive: true });
        }
    }
}