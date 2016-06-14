(function() {
  var betterSpawn;

  betterSpawn = require("better-spawn");

  module.exports = function(cmdGroups, options, cb) {
    var cmdGroup, i, isGracefully, next, processParallelGroup, processSequentialGroup, spawn;
    spawn = function(unit) {
      var stdio;
      stdio = "inherit";
      if (options.silent) {
        stdio = "pipe";
      }
      unit.child = betterSpawn(unit.cmd, {
        stdio: stdio
      });
      if (unit.timeout) {
        setTimeout(unit.child.close, unit.timeout);
      }
      return unit;
    };
    isGracefully = function(unit) {
      return !unit.child.exitCode && !unit.child.signalCode;
    };
    processSequentialGroup = function(cmdGroup, cb) {
      var i, next;
      i = 0;
      next = function() {
        var unit;
        if (cmdGroup.units[i] != null) {
          unit = spawn(cmdGroup.units[i]);
          i += 1;
          cmdGroup.close = function(exitCode, signal) {
            if (signal == null) {
              signal = "SIGTERM";
            }
            return unit.child.close(signal);
          };
          return unit.child.on("close", function() {
            if (isGracefully(unit) || unit.ignore) {
              return next();
            } else {
              return cb(1);
            }
          });
        } else {
          return cb(0);
        }
      };
      return next();
    };
    processParallelGroup = function(cmdGroup, cb) {
      var allClosed, called, cbOnce, closeAll, j, len, ref, results, unit, units;
      called = false;
      cbOnce = function(exitCode) {
        if (!called) {
          cb(exitCode);
        }
        return called = true;
      };
      units = [];
      closeAll = function(exitCode, signal) {
        var j, len, unit;
        if (signal == null) {
          signal = "SIGTERM";
        }
        for (j = 0, len = units.length; j < len; j++) {
          unit = units[j];
          unit.child.close(signal);
        }
        return cbOnce(exitCode);
      };
      cmdGroup.close = closeAll;
      allClosed = function() {
        var closed, exitCode, j, len, unit;
        closed = 0;
        exitCode = 0;
        for (j = 0, len = units.length; j < len; j++) {
          unit = units[j];
          if (unit.child.closed) {
            closed += 1;
          }
          if (unit.master) {
            if (unit.child.closed) {
              return cbOnce(!isGracefully(unit));
            } else {
              return;
            }
          }
          if (!isGracefully(unit) && !unit.ignore) {
            exitCode = 1;
          }
        }
        if (closed === units.length) {
          return cbOnce(exitCode);
        }
      };
      ref = cmdGroup.units;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        unit = ref[j];
        unit = spawn(unit);
        units.push(unit);
        results.push(unit.child.on("close", function() {
          if (!called) {
            if (unit.master) {
              return closeAll(!isGracefully(unit));
            } else {
              if (isGracefully(unit)) {
                if (!unit.ignore) {
                  if (cmdGroup.first) {
                    closeAll(0);
                  }
                }
              } else {
                if (!unit.ignore) {
                  if (!cmdGroup.wait) {
                    closeAll(1);
                  }
                }
              }
              return allClosed();
            }
          }
        }));
      }
      return results;
    };
    i = 0;
    cmdGroup = null;
    next = function(exitCode) {
      if (exitCode) {
        return cb(1);
      }
      if (cmdGroups[i] != null) {
        cmdGroup = cmdGroups[i];
        if (cmdGroup.units.length > 0) {
          i += 1;
          if (cmdGroup.parallel) {
            return processParallelGroup(cmdGroup, next);
          } else {
            return processSequentialGroup(cmdGroup, next);
          }
        } else {
          return next(0);
        }
      } else {
        return cb(0);
      }
    };
    next(0);
    return function(signal) {
      return typeof cmdGroup.close === "function" ? cmdGroup.close(1, signal) : void 0;
    };
  };

}).call(this);
