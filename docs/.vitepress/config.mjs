import { defineConfig } from 'vitepress'

// Minimal docs site. Locales: root = English (/), /zh/ = Chinese.
// There is no automatic language redirect here; readers pick the locale via
// the nav link (see docs/index.md and docs/zh/index.md).

export default defineConfig({
  lang: 'en',
  title: 'scriptlet',
  description: 'A collection of miscellaneous ops scripts.',
  // The doc-consistency audit ledger is a maintainer record, not site content.
  srcExclude: ['**/审计-*.md'],
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      link: '/',
      themeConfig: {
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
        nav: [
          { text: 'English', link: '/' },
          { text: 'GitHub', link: 'https://github.com/cuihairu/scriptlet' }
        ]
      }
    }
  }
})
