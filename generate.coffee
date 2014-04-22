#!/usr/bin/env coffee

fs = require "fs"
mustache = require "mustache"

readmeSrc = require "../bacon.js/readme-src"
generateApi = require "./generateApi"

pageTemplate = fs.readFileSync("inc/page.html").toString()

pages = [
  output: "index.html"
  title: "Bacon.js - Functional Reactive Programming library for JavaScript"
,
  output: "api.html"
  title: "Bacon.js - API reference"
  content: generateApi readmeSrc
]

# Render pages
pages.forEach (page) ->
  content = page.content || fs.readFileSync("inc/" + page.output).toString()
  html = mustache.render pageTemplate,
    title: page.title
    content: content

  fs.writeFileSync page.output, html
