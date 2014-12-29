fs = require "fs"
mustache = require "mustache"
_ = require "lodash"
bluebird = require "bluebird"
request = bluebird.promisify require "request"
generateApi = require "./generateApi"
renderMarkdown = require "./renderMarkdown"
cheerio = require "cheerio"

pageTemplate = fs.readFileSync("templates/page.html").toString()
tocTemplate = fs.readFileSync("templates/toc.html").toString()

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

readFile = (fn) ->
  content = fs.readFileSync(fn).toString()
  if fn.slice(-3) == ".md"
    '<a id="' + fn + '">\n' + renderMarkdown.render(content)
  else
    content

toc = (data) ->
  data.files = data.files.map (filename) ->
    content = readFile filename
    title = cheerio(content).find("h2").text()
    { link: "#" + filename, title }
  html = mustache.render tocTemplate, data

readFiles = (page) ->
  fn = page.input
  files = if fs.lstatSync(fn).isDirectory()
    fs.readdirSync(fn).map (f) -> fn + "/" + f
  else
    [].concat(fn)
  contents = files.map(readFile).join("\n")
  if files.length > 1
    contents = toc({title: page.title, files}) + contents
  contents

module.exports = (page) ->
  envPromise.then (env) ->
    content = page.content || readFiles(page)
    data = _.extend {}, env,
      AUTOGENDISCLAIMER: "<!-- This file is generated. See package.json -->"
      title: page.title
      content: content
    html = mustache.render pageTemplate, data

    fs.writeFileSync page.output, html

