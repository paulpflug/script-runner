#!/usr/bin/env node
var pkg = require(process.cwd()+"/package.json")
var minimatch = require("minimatch")

var i,j,len,len2,identifier = [], args = process.argv.slice(2);

if (pkg.scripts){
  var scripts = Object.keys(pkg.scripts)
  for (i = 0, len = scripts.length; i < len; i++) {
    identifier.push(scripts[i].replace(":","/"))
  }
  for (i = 0, len = args.length; i < len; i++) {
    if (args[i][0] != '-') {
      cmd = args[i].replace(":","/")
      var matched = []
      for (j = 0, len2 = identifier.length; j < len2; j++) {
        if (minimatch(identifier[j], cmd)) {
          matched.push(pkg.scripts[scripts[j]])
        }
      }
      if (matched.length) {
        var head = []
        if (i > 0) { head = args.slice(0,i) }
        var tail = []
        if (args.length > i) { tail = args.slice(i+1)}
        args = head.concat(matched,tail)
        len = args.length
        i += matched.length-1
      }
    }
  }
}

if (args.length) {
  var cmd = "\""+__dirname+"/run.js\" \""+args.join("\" \"")+"\""
  var betterSpawn = require("better-spawn")
  var child = betterSpawn(cmd,{stdio:"inherit",cwd:process.cwd()})
  process.on("SIGINT", function(){child.close("SIGINT")})
  process.on("SIGTERM", function(){child.close("SIGTERM")})
  process.on("SIGHUP", function(){child.close("SIGHUP")})
}
