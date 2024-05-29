import fs from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';

/** @type {import('astro').AstroIntegration} */
export default {
    name: 'trim-css',
    hooks: {
        async "astro:build:done"({ routes }) {
            for (const route of routes) {
                if (!route.distURL?.toString().endsWith('.html'))
                    continue;

                const htmlFile = fileURLToPath(route.distURL);
                const contents = await fs.readFile(htmlFile);
                const dom = new JSDOM(contents);
                replaceStyleTags(dom.window);

                await fs.writeFile(htmlFile, dom.serialize());
            }
        }
    }
}

/**
 * @param {import('jsdom').DOMWindow} window 
 * @param {CSSRule} rule 
 * @returns 
 */
function isRuleUsed(window, rule) {
    if (rule.cssText.startsWith('@charset'))
        return true;
    if (rule instanceof window.CSSStyleRule) {
        // Remove unused styles
        try {
            return window.document.querySelectorAll(rule.selectorText.replace(/(> ?)?:.*/, '') || '*').length > 0;
        } catch (err) {
            console.error(err);
            return true;
        }
    }
    if (rule instanceof window.CSSMediaRule) {
        // Only include media rules if their contents are applicable
        return [...rule.cssRules].some(rule => isRuleUsed(window, rule));
    }
    return true;

}
/**
 * @param {import('jsdom').DOMWindow} window 
 * @returns 
 */
function getTrimmedStyles(window) {
    const document = window.document;
    const styles = [];
    for (const styleSheet of document.styleSheets) {
        for (let i = 0; i < styleSheet.cssRules.length; i++) {
            if (!isRuleUsed(window, styleSheet.cssRules[i])) {
                styleSheet.deleteRule(i--);
            }
        }
        styles.push(styleSheet.toString());
    }
    return styles.join('');
}

/**
 * @param {import('jsdom').DOMWindow} window 
 * @returns 
 */
function replaceStyleTags(window) {
    const styles = getTrimmedStyles(window);
    const document = window.document;
    for (const styleElem of [...document.head.getElementsByTagName('style')]) {
        styleElem.remove();
    }
    if (styles) {
        const newStyles = document.createElement('style');
        newStyles.appendChild(document.createTextNode(styles));
        document.head.appendChild(newStyles);
    }
}
