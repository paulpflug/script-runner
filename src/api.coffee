
module.exports = (cmdGroups, options, cb) =>
  betterSpawn = require "better-spawn"
  Promise = options.Promise or require "yaku"
  
  allChildren = []

  running = true
  _exitCode = 0

  _close = (children) =>
    closed = []
    for child in children
      closed.push child.close()
    return Promise.all(closed).then => 1

  closeGroup = (group) =>
    if group and not group.closed
      group.closed = true
      _close group.units.map (unit) => unit.child
    return Promise.resolve()

  close = =>
    if running = true
      running = false
      return _close(allChildren)
    return Promise.resolve(_exitCode)

  spawn = (unit, group, exitCode) =>
    if running
      if group and unit.master
        group.wait = true
      allChildren.push child = unit.child = betterSpawn(unit.cmd, noOut: options.silent, noErr: options.noErr)
      if unit.timeout
        setTimeout child.close, unit.timeout
      return child.closed.then (child) =>
        unless unit.ignore
          if child.exitCode
            if group and not group.closed
              await closeGroup(group) unless group.wait
            else 
              await close()
            return child.exitCode
          else 
            if group and not group.closed
              if group.first or unit.master
                unit.master = true
                await closeGroup(group)
        return 0
    return Promise.resolve(exitCode)



  done = cmdGroups.reduce(((acc, cur) =>
    return acc.then (exitCode) =>
      return Promise.resolve(exitCode) if exitCode
      if cur.parallel
        return Promise.all(cur.units.map((unit) => spawn(unit, cur, exitCode)))
          .then (exitCodes) =>
            for unit,i in cur.units
              if unit.master
                await close() if exitCodes[i]
                return exitCodes[i]
            for exitCode in exitCodes
              if exitCode 
                await close()
                return exitCode
            return 0
      else
        return cur.units.reduce ((acc2, cur2) =>
          return acc2.then (exitCode) => spawn cur2, null, exitCode
        ), Promise.resolve(0)
  ), Promise.resolve(0)
  ).then (exitCode) => 
    cb?(exitCode)
    return _exitCode = exitCode
  .catch (e) =>
    console.log e

  return close: close, done: done 
