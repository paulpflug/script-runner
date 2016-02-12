#!/usr/bin/env node
var betterSpawn = require("better-spawn")
var cmd = __dirname+"/run.js --parallel \""+process.argv.slice(2).join("\" \"")+"\""
var child = betterSpawn(cmd,{stdio:"inherit",cwd:process.cwd()})
process.on("SIGINT", child.close)
