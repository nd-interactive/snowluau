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
  - title: Resolve Roblox Require
    details: Transforms string-based and `.luaurc`-based `require` calls into Roblox-compatible instance-based `require` calls.
  - title: Rename Variables
    details: Renames all local variables to a sequence of generated variable names.
  - title: Cool
    details: It is pretty cool.
---

