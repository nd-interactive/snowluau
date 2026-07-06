---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "Snowluau"
  text: "Luau transformer"
  tagline: A CLI-based Luau transformer built with Lute.
  actions:
    - theme: brand
      text: Getting Started
      link: /guide/installation
    - theme: alt
      text: Reference
      link: /cli

features:
  - title: Resolver
    details: Transforms string-based and `.luaurc`-based `require` calls into Roblox-compatible instance-based `require` calls.
  - title: Bundler
    details: Bundles a multi-file module into a single file by following its require graph.
  - title: Renamer
    details: Renames all local variables to a sequence of generated variable names.
---

