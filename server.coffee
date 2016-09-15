#!/usr/bin/env coffee

express = require 'express'
app = express()
app.use express.static('.')
app.listen 3000, -> console.log "Site available at http://localhost:3000/"
