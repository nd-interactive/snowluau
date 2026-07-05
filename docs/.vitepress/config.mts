import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Snowluau",
  description: "A CLI-based Luau transformer built with Lute.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          { text: 'Guide', link: '/guide' },
          { text: 'CLI References', link: '/cli' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/nd-interactive/snowluau' }
    ]
  }
})
