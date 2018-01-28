#!/usr/bin/env coffee

generatePage = require "./generatePage"
readme1 = require ("../bacon.js/1.0/readme-src")
readme2 = require ("../bacon.js/2.0/readme-src")
generateApi = require "./generateApi"

pages = [
  output: "index.html"
  input: "content/index.html"
  title: "Bacon.js - Functional Reactive Programming library for JavaScript"
,
  output: "api.html"
  title: "Bacon.js 1.0 - API reference"
  content: generateApi.render readme1
  apiTocContent1: generateApi.renderToc readme1
,
  output: "api2.html"
  title: "Bacon.js 2.0 - API reference"
  content: generateApi.render readme2
  apiTocContent2: generateApi.renderToc readme2
,
  output: "tutorials.html"
  input: "content/tutorials"
  title: "Tutorials"
]

# Render pages
pages.forEach generatePage
