import { defineConfig } from 'vitepress'
import { withSidebar } from 'vitepress-sidebar'

// https://vitepress.dev/reference/site-config

export default withSidebar(
  defineConfig({
    title: "Snowluau",
    base: "/snowluau/",
    description: "A CLI-based Luau transformer built with Lute.",
    themeConfig: {
      // https://vitepress.dev/reference/default-theme-config
      nav: [
        { text: 'Home', link: '/snowluau/' },
      ],
      search: { provider: 'local' },

      socialLinks: [
        { icon: 'github', link: 'https://github.com/nd-interactive/snowluau' }
      ]
    }
  }),
  {
    // ============ [ SIDEBAR OPTIONS ] ============
    useFolderLinkFromIndexFile: true,
    useFolderTitleFromIndexFile: true,
    useTitleFromFileHeading: true,
    useTitleFromFrontmatter: true,
    hyphenToSpace: true,
    sortMenusByFrontmatterOrder: true,
    excludeByGlobPattern: ['README.md'],
  }
)