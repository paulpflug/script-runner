{test} = require "snapy"
spawn = require("better-spawn")


cli = require "../src/cli.coffee"

getStream = (cmd) =>
  child = spawn cmd, stdio:"pipe"
  return child.stdout

test (snap) =>
  snap obj: cli ["--test"], true
  snap obj: cli ["-t"], true

test (snap) =>
  snap obj: cli ["--test", "cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "cmd1", "cmd2"], true

test (snap) =>
  snap obj: cli ["--test", "--parallel","cmd1"], true
  snap obj: cli ["--test", "-p","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "--sequential","cmd1"], true
  snap obj: cli ["--test", "-s","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "-p","cmd2","-s","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "--wait","cmd1"], true
  snap obj: cli ["--test", "-w","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "--first","cmd1"], true
  snap obj: cli ["--test", "-f","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "--master","cmd1"], true
  snap obj: cli ["--test", "-m","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "--ignore","cmd1"], true
  snap obj: cli ["--test", "-i","cmd1"], true

test (snap) =>
  snap obj: cli ["--test", "'test 1'"], true

test (snap) =>
  snap stream: getStream "./run.js --test"
  snap stream: getStream "./run.js --test cmd1"

test (snap) =>
  snap stream: getStream "./run-para.js --test"
  snap stream: getStream "./run-para.js --test cmd1"
  snap stream: getStream "./run-para.js --test 'cmd 1'"

test (snap) =>
  snap stream: getStream "./run-npm.js --test"
  snap stream: getStream "./run-npm.js --test test"
  snap stream: getStream "./run-npm.js --test -p test:* -s test2"

test (snap) =>
  snap stream: getStream "./run.js 'echo 'test''"

filter = ["resolved.isClosed","resolved.isKilled"]

test (snap) =>
  child = spawn "./run.js 'sleep 5'"
  snap promise: child.close(), filter: filter
  child = spawn "./run.js 'sleep 5'"
  snap promise: child.close("SIGHUP"), filter: filter
  child = spawn "./run.js 'sleep 5'"
  snap promise: child.close("SIGINT"), filter: filter


test (snap) =>
  child = spawn "./run.js -p 'sleep 5' 'sleep 5'"
  snap promise: child.close(), filter: filter