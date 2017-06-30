#!/usr/bin/env node
var args, i, len, cmdGroups, cmdGroup, options, unit
args = process.argv.slice(2)
options = {}
unit = {}
cmdGroup = { parallel: false, units: [] }
cmdGroups = []
for (i = 0, len = args.length; i < len; i++) {
  if (args[i][0] === '-') {
    switch (args[i]) {
      case '-s':
      case '--sequential':
        if (cmdGroup.units.length > 0) { cmdGroups.push(cmdGroup) }
        cmdGroup = { parallel: false, units: [] }
        break
      case '-p':
      case '--parallel':
        if (cmdGroup.units.length > 0) { cmdGroups.push(cmdGroup) }
        cmdGroup = { parallel: true, units: [] }
        break
      case '-w':
      case '--wait':
        cmdGroup.wait = true
        break
      case '-f':
      case '--first':
        cmdGroup.first = true
        break
      case '-m':
      case '--master':
        unit.master = true
        break
      case '-i':
      case '--ignore':
        unit.ignore = true
        break
      case '-v':
      case '--verbose':
        options.verbose = true
        break
      case '--silent':
        options.silent = true
        break
      case '--no-errors':
        options.noErr = true
        break
      case '-t':
      case '--test':
        options.test = true
        break
      case '-h':
      case '--help':
        console.log('usage: run [<options> [cmd..]..]')
        console.log('')
        console.log('options:')
        console.log('-h, --help         output usage information')
        console.log('-v, --verbose      verbose logging (not implemented yet)')
        console.log('    --silent       suppress output of children')
        console.log('    --no-errors    also suppress error-output of children')
        console.log('-t, --test         no running only show process structure')
        console.log('-s, --sequential   following cmds will be run in sequence')
        console.log('-p, --parallel     following cmds will be run in parallel')
        console.log('-i, --ignore       the following cmd will be ignored for --first, --wait and errors')
        console.log('-f, --first        only in parallel block: close all sibling processes after first exits (success/error)')
        console.log('-w, --wait         only in parallel block: will not close sibling processes on error')
        console.log('-m, --master       only in parallel block: close all sibling processes when the following cmd exits. exitCode will only depend on master')
        console.log('-f, --first        close all sibling processes after first exits (success/error)')
        console.log('')
        console.log('run also looks in node_modules/.bin for cmds')
        console.log('run-para is a shorthand for run --parallel')
        console.log('run-seq is a longhand for run')
        console.log('run-npm will match cmd with npm script and replace them, usage of globs is allowed')
        process.exit()
        break
    }
  } else {
    unit.cmd = args[i]
    cmdGroup.units.push(unit)
    unit = {}
  }
}
if (unit.cmd != null) { cmdGroup.units.push(unit) }
if (cmdGroup.units.length > 0) { cmdGroups.push(cmdGroup) }
if (options.test) {
  console.log(JSON.stringify(cmdGroups))
} else {
  close = require('./lib/index.js')(cmdGroups, options, process.exit)
  process.on("SIGTERM", function () { close("SIGTERM") })
  process.on("SIGINT", function () { close("SIGINT") })
  process.on("SIGHUP", function () { close("SIGHUP") })
}
