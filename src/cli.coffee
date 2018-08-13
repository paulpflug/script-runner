module.exports = (args, test) ->
  options = {}
  unit = {}
  cmdGroup = parallel: false, units: []
  cmdGroups = []
  for arg in args
    if arg[0] == "-"
      switch arg
        when "-s", "--sequential"
          cmdGroups.push cmdGroup if cmdGroup.units.length
          cmdGroup = parallel: false, units: []
        when "-p", "--parallel"
          cmdGroups.push cmdGroup if cmdGroup.units.length
          cmdGroup = parallel: true, units: []
        when "-w", "--wait"
          cmdGroup.wait = true
        when "-f", "--first"
          cmdGroup.first = true
        when "-m", "--master"
          unit.master = true
        when "-i", "--ignore"
          unit.ignore = true
        when "-v", "--verbose"
          options.verbose = true
        when "--silent"
          options.silent = true
        when "--no-errors"
          options.noErr = true
        when "-t", "--test"
          options.test = true
        when "-h", "--help"
          console.log """
            usage: run [<options> [cmd..]..]


            options:
            -h, --help         output usage information
            -v, --verbose      verbose logging (not implemented yet)
                --silent       suppress output of children
                --no-errors    also suppress error-output of children
            -t, --test         no running only show process structure
            -s, --sequential   following cmds will be run in sequence
            -p, --parallel     following cmds will be run in parallel
            -i, --ignore       the following cmd will be ignored for --first, --wait and errors
            -f, --first        only in parallel block: close all sibling processes after first exits
            -w, --wait         only in parallel block: will not close sibling processes on error
            -m, --master       only in parallel block: close all sibling processes when the following cmd exits. exitCode will only depend on master
            
            run also looks in node_modules/.bin for cmds
            run-para is a shorthand for run --parallel
            run-seq is a longhand for run
            run-npm will match cmd with npm script and replace them, usage of globs is allowed
            e.g. 
              run-npm -p build:* -s deploy
          """
          process.exit()
    else
      unit.cmd = arg
      cmdGroup.units.push unit 
      unit = {}

  cmdGroup.units.push unit if unit.cmd

  cmdGroups.push cmdGroup if cmdGroup.units.length
  if options.test
    return cmdGroups if test
    return console.log(JSON.stringify(cmdGroups))
  {close} = require("./api")(cmdGroups, options, process.exit)
  process.on "SIGTERM", => close "SIGTERM"
  process.on "SIGINT", => close "SIGINT"
  process.on "SIGHUP", => close "SIGHUP"

