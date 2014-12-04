#!/usr/bin/env coffee

generatePage = require "./generatePage"
readmeSrc = require ("../../bacon.js/readme-src")
generateApi = require "./generateApi"

pages = [
  output: "index.html"
  title: "Bacon.js - Functional Reactive Programming library for JavaScript"
,
  output: "api.html"
  title: "Bacon.js - API reference"
  content: generateApi readmeSrc
]

# Render pages
pages.forEach generatePage
