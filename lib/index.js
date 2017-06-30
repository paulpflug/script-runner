(function() {
  var betterSpawn;

  betterSpawn = require("better-spawn");

  module.exports = function(cmdGroups, options, cb) {
    var _cb, close, cmdGroup, finished, i, isGracefully, next, processParallelGroup, processSequentialGroup, spawn;
    if (options.Promise == null) {
      options.Promise = Promise;
    }
    if (options.Promise) {
      _cb = cb;
      finished = new Promise((resolve) => {
        return cb = (exitCode) => {
          resolve(exitCode);
          return typeof _cb === "function" ? _cb(exitCode) : void 0;
        };
      });
    }
    spawn = function(unit) {
      unit.child = betterSpawn(unit.cmd, {
        noOut: options.silent,
        noErr: options.noErr
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
          cmdGroup.close = function(exitCode, signal = "SIGTERM") {
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
      closeAll = function(exitCode, signal = "SIGTERM") {
        var j, len, unit;
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
          if (unit.child.isClosed) {
            closed += 1;
          }
          if (unit.master) {
            if (unit.child.isClosed) {
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
    close = function(signal) {
      if (typeof cmdGroup.close === "function") {
        cmdGroup.close(1, signal);
      }
      return finished;
    };
    if (finished) {
      close.then = finished.then.bind(finished);
      close.catch = finished.catch.bind(finished);
    }
    return close;
  };

}).call(this);
