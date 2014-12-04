marked = require "marked"

renderer = new marked.Renderer
renderer.code = (code, lang) ->
  '<textarea class="code">' + code + '</textarea>'

marked.setOptions
  renderer: renderer

module.exports = marked
