#!/usr/bin/env node

var args = process.argv.slice(2)
args.unshift("-p")
try {
  require("coffeescript/register")
  require("./src/cli.coffee")(args)
} catch (e) {
  if (e.code == "MODULE_NOT_FOUND") {
    require("./lib/cli.js")(args)
  } else {
    console.log(e)
  }
}