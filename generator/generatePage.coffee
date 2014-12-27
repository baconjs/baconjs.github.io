fs = require "fs"
mustache = require "mustache"
_ = require "lodash"
bluebird = require "bluebird"
request = bluebird.promisify require "request"
generateApi = require "./generateApi"
renderMarkdown = require "./renderMarkdown"

pageTemplate = fs.readFileSync("templates/page.html").toString()

tagsRequest =
  url: "https://api.github.com/repos/baconjs/bacon.js/tags"
  headers:
    "User-Agent": "bacon.js github pages generator"

urlExists = (url) ->
  request(url)
    .spread (response, body) ->
      response.statusCode == 200
    .then null, ->
      false

firstExists = (list, idx) ->
  urlExists(list[idx]).then (result) ->
    if result
      idx
    else
      firstExists list, idx + 1

lastVersionInCDN = request(tagsRequest).spread (response, body) ->
  json = JSON.parse(response.body)
  tags = _.pluck json, "name"

  urls = _.map tags, (tag) ->
    "http://cdnjs.cloudflare.com/ajax/libs/bacon.js/" + tag + "/Bacon.js"

  firstExists(urls, 0).then (idx) ->
    tags[idx]

envPromise = if process.argv[2] == "dev"
  lastVersionInCDN.then (tag) ->
    fonts: "http://fonts.googleapis.com/css?family=Yanone+Kaffeesatz"
    jquery: "http://codeorigin.jquery.com/jquery-2.1.1.min.js"
    baconjs: "http://cdnjs.cloudflare.com/ajax/libs/bacon.js/" + tag + "/Bacon.min.js"
    version: tag
else
  lastVersionInCDN.then (tag) ->
    fonts: "//fonts.googleapis.com/css?family=Yanone+Kaffeesatz"
    jquery: "//codeorigin.jquery.com/jquery-2.1.1.min.js"
    baconjs: "//cdnjs.cloudflare.com/ajax/libs/bacon.js/" + tag + "/Bacon.min.js"
    version: tag

lastVersionInCDN.then (tag) ->
  console.log "Latest tag in cdn: ", tag

envPromise.then (env) ->
  console.log "Using environment", env

module.exports = (page) ->
  envPromise.then (env) ->
    content = page.content || fs.readFileSync(page.input).toString()
    if page.input?.slice(-3) == ".md"
      content = renderMarkdown.render(content)
    data = _.extend {}, env,
      AUTOGENDISCLAIMER: "<!-- This file is generated. See package.json -->"
      title: page.title
      content: content
    html = mustache.render pageTemplate, data

    fs.writeFileSync page.output, html

