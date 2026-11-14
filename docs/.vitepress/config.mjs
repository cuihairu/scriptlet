import { defineConfig } from 'vitepress'

// Minimal docs site. Locales: root = English (/), /zh/ = Chinese.
// There is no automatic language redirect here; readers pick the locale via
// the nav link (see docs/index.md and docs/zh/index.md).

export default defineConfig({
  // Project Pages site: /scriptlet/. CI passes DOCS_BASE; local builds fall
  // back to the repository name.
  base: process.env.DOCS_BASE || '/scriptlet/',
  lang: 'en',
  title: 'scriptlet',
  description: 'A collection of miscellaneous ops scripts.',
  // The doc-consistency audit ledger is a maintainer record, not site content.
  srcExclude: ['**/审计-*.md', '审计-*.md'],
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      link: '/',
      themeConfig: {
        // Manual language switch only: VitePress renders the locale dropdown
        // from `locales` above. No client-side language detection is wired in.
        langMenuLabel: 'Language',
        nav: [
          { text: '简体中文', link: '/zh/' },
          { text: 'GitHub', link: 'https://github.com/cuihairu/scriptlet' }
        ]
      }
    },
    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/zh/',
      themeConfig: {
        langMenuLabel: '语言',
        nav: [
          { text: 'English', link: '/' },
          { text: 'GitHub', link: 'https://github.com/cuihairu/scriptlet' }
        ]
      }
    }
  }
})
