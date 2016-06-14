# out: ../lib/index.js

betterSpawn = require "better-spawn"
module.exports = (cmdGroups,options,cb) ->
  spawn = (unit) ->
    stdio = "inherit"
    stdio = "pipe" if options.silent
    unit.child = betterSpawn(unit.cmd,stdio:stdio)
    if unit.timeout
      setTimeout unit.child.close, unit.timeout
    return unit

  isGracefully = (unit) ->
    return not unit.child.exitCode and not unit.child.signalCode

  processSequentialGroup = (cmdGroup,cb) ->
    i = 0
    next = () ->
      if cmdGroup.units[i]?
        unit = spawn cmdGroup.units[i]
        i += 1
        cmdGroup.close = (exitCode, signal="SIGTERM") ->
          unit.child.close(signal)
        unit.child.on "close", ->
          if isGracefully(unit) or unit.ignore
            next()
          else
            cb(1)
      else
        cb(0)
    next()

  processParallelGroup = (cmdGroup,cb) ->
    called = false
    cbOnce = (exitCode) ->
      cb(exitCode) unless called
      called = true
    units = []
    closeAll = (exitCode,signal="SIGTERM") ->
      for unit in units
        unit.child.close(signal)
      cbOnce(exitCode)
    cmdGroup.close = closeAll
    allClosed = ->
      closed = 0
      exitCode = 0
      for unit in units
        closed += 1 if unit.child.closed
        if unit.master
          if unit.child.closed
            return cbOnce(not isGracefully(unit))
          else
            return
        if not isGracefully(unit) and not unit.ignore
          exitCode = 1
      if closed == units.length
        cbOnce(exitCode)
    for unit in cmdGroup.units
      unit = spawn unit
      units.push unit
      unit.child.on "close", ->
        unless called
          if unit.master
            closeAll(not isGracefully(unit))
          else
            if isGracefully(unit)
              unless unit.ignore
                if cmdGroup.first
                  closeAll(0)
            else
              unless unit.ignore
                unless cmdGroup.wait
                  closeAll(1)
            allClosed()

  i = 0
  cmdGroup = null
  next = (exitCode) ->
    return cb(1) if exitCode
    if cmdGroups[i]?
      cmdGroup = cmdGroups[i]
      if cmdGroup.units.length > 0
        i += 1
        if cmdGroup.parallel
          processParallelGroup(cmdGroup,next)
        else
          processSequentialGroup(cmdGroup,next)
      else
        next(0)
    else
      return cb(0)
  next(0)
  return (signal) ->
    cmdGroup.close?(1, signal)
