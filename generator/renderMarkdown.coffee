Remarkable = require('remarkable');
md = new Remarkable
  html: true
  highlight: (code, lang) ->
    '<textarea class="code">' + code + '</textarea>'

module.exports = md