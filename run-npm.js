#!/usr/bin/env node
var pkg = require(process.cwd() + "/package.json")
var minimatch = require("minimatch")

var i, j, len, len2, identifier = [], args = process.argv.slice(2);

if (pkg.scripts) {
  var scripts = Object.keys(pkg.scripts)
  for (i = 0, len = scripts.length; i < len; i++) {
    identifier.push(scripts[i].replace(":", "/"))
  }
  for (i = 0, len = args.length; i < len; i++) {
    if (args[i][0] != '-') {
      cmd = args[i].replace(":", "/")
      var matched = []
      for (j = 0, len2 = identifier.length; j < len2; j++) {
        if (minimatch(identifier[j], cmd)) {
          matched.push(pkg.scripts[scripts[j]])
        }
      }
      if (matched.length) {
        args.splice(i, 1, matched)
        len = args.length
        i += matched.length - 1
      }
    }
  }
}

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