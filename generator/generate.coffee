#!/usr/bin/env coffee

generatePage = require "./generatePage"
readmeSrc = require ("../../bacon.js/readme-src")
generateApi = require "./generateApi"

pages = [
  output: "index.html"
  input: "content/index.html"
  title: "Bacon.js - Functional Reactive Programming library for JavaScript"
,
  output: "api.html"
  title: "Bacon.js - API reference"
  content: generateApi.render readmeSrc
  apiTocContent: generateApi.renderToc readmeSrc
,
  output: "tutorials.html"
  input: "content/tutorials"
  title: "Tutorials"
]

# Render pages
pages.forEach generatePage
