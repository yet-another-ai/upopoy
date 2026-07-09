import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'upopoy Docs',
  description: 'Usage and deployment documentation for upopoy',
  lang: 'en-US',
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: 'Usage', link: '/guide/' },
      { text: 'Deployment', link: '/deploy/' }
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Usage',
          items: [
            { text: 'Overview', link: '/guide/' },
            { text: 'Local Development', link: '/guide/local-development' }
          ]
        }
      ],
      '/deploy/': [
        {
          text: 'Deployment',
          items: [
            { text: 'Overview', link: '/deploy/' },
            { text: 'SSO Login', link: '/deploy/sso' },
            { text: 'ActiveStorage', link: '/deploy/active-storage' },
            { text: 'Documentation Site', link: '/deploy/docs-site' }
          ]
        }
      ]
    },
    search: {
      provider: 'local'
    },
    outline: {
      level: [2, 3],
      label: 'On this page'
    },
    docFooter: {
      prev: 'Previous',
      next: 'Next'
    },
    footer: {
      message: 'upopoy documentation',
      copyright: 'Copyright © 2026'
    }
  }
})
