chai = require "chai"
should = chai.should()
spawn = require("better-spawn")

api = require("../src/index.coffee")

waitingProcess = (time=10000) => "node -e 'setTimeout(function(){},#{time});'"
failingProcess = "node -e 'throw new Error();'"

options = silent: true, noErr: true

describe "parallelshell", =>
  describe "API", =>
    describe "sequential/parallel", =>
      it "should regulary close with exitCode 0", =>
        api [{parallel:false, units: [{cmd:waitingProcess(10)}]}],options
        .then (exitCode) => exitCode.should.equal 0
      it "should regulary close with exitCode 0 in parallel mode", =>
        api [{parallel:true, units: [{cmd:waitingProcess(10)}]}],options
        .then (exitCode) => exitCode.should.equal 0
      it "should close with exitCode 1 on error", =>
        api [{parallel:false, units: [{cmd:failingProcess}]}],options
        .then (exitCode) => exitCode.should.equal 1
      it "should close with exitCode 1 on error in parallel mode", =>
        api [{parallel:true, units: [{cmd:failingProcess}]}],options
        .then (exitCode) => exitCode.should.equal 1
      it "should run sequential", (done) =>
        closed = false
        close = api [{parallel:false, units: [{cmd:waitingProcess()},{cmd:failingProcess}]}],options
        close.then (exitCode) =>
          exitCode.should.equal 1
          closed = true
        setTimeout close, 80
        setTimeout (=> closed.should.be.true;done()),100
      it "should run parallel", =>
        api [{parallel:true, units: [{cmd:waitingProcess()},{cmd:failingProcess}]}],options
        .then (exitCode) => exitCode.should.equal 1
      it "should run groups sequential", =>
        closed = false
        setTimeout (=> closed.should.be.false),150
        api [
          {
            parallel:false
            units: [{cmd:waitingProcess(100)}]
          },{
            parallel:false
            units: [{cmd:waitingProcess(100)}]
          }
          ],options
        .then (exitCode) => exitCode.should.equal 0; closed = true
       
      it "should close groups on error", =>
        api [
          {
            parallel:false
            units: [{cmd:failingProcess}]
          },{
            parallel:false
            units: [{cmd:waitingProcess(1000)}]
          }
          ],options
        .then (exitCode) => exitCode.should.equal 1
    describe "--ignore", =>
      it "should work in sequential mode", =>
        api [{parallel:false, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options
        .then (exitCode) => exitCode.should.equal 0
      it "should work in parallel mode", =>
        api [{parallel:true, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options
        .then (exitCode) => exitCode.should.equal 0
    describe "--first", =>
      it "should work in parallel mode", =>
        api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10)}]}],options
        .then (exitCode) => exitCode.should.equal 0
      it "should respekt --ignore", (done) =>
        closed = false
        close = api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10),ignore:true}]}],options
        close.then (exitCode) =>
          exitCode.should.equal 1
          closed = true
        setTimeout (=> closed.should.be.false;close()),50
        setTimeout (=> closed.should.be.true;done()),100
    describe "--wait", =>
      it "should work in parallel mode", (done) =>
        closed = false
        close = api [{parallel:true,wait:true, units: [{cmd:failingProcess},{cmd:waitingProcess(60)}]}],options
        close.then (exitCode) =>
          exitCode.should.equal 1
          closed = true
        setTimeout (=> closed.should.be.false),50
        setTimeout (=> closed.should.be.true;done()),200
      it "should respekt --ignore", (done) =>
        closed = false
        close = api [{parallel:true,wait:true, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(60)}]}],options
        .then (exitCode) =>
          exitCode.should.equal 0
          closed = true
        setTimeout (=> closed.should.be.false),50
        setTimeout (=> closed.should.be.true;done()),200
    describe "--master", =>
      it "should work in parallel mode", =>
        api [{parallel:true,wait:true,units: [{cmd:failingProcess,master:true},{cmd:waitingProcess(100)}]}],options
        .then (exitCode) =>
          exitCode.should.equal 1
      it "should work in parallel mode", =>
        close = api [{parallel:true,units: [{cmd:waitingProcess()},{cmd:waitingProcess(80),master:true}]}],options
        .then (exitCode) => exitCode.should.equal 0
    describe "nesting", =>
      it "should work", =>
        api [{parallel:false,units: [{cmd:"./run.js \""+waitingProcess(10)+"\""}]}],options
        .then (exitCode) => exitCode.should.equal 0
  describe "CLI", =>
    testOutput = (cmd, expectedOutput, std="out") => 
      child = spawn cmd, stdio:"pipe"
      if std == "out"
        std = child.stdout
      else
        std = child.stderr
      std.setEncoding("utf8")
      output = []
      finished = new Promise (resolve) =>
        std.on "data", (data) =>
          lines = data.split("\n")
          lines.pop() if lines[lines.length-1] == ""
          output = output.concat(lines)
        std.on "end", () =>
          for line,i in expectedOutput
            line.should.equal output[i]
          resolve()
      child.then = finished.then.bind(finished)
      child.catch = finished.catch.bind(finished)
      return child
    describe "run", =>
      it "should work", =>
        testOutput "./run.js --test", ['[]']

      it "should work with 1 cmd", =>
        testOutput "./run.js --test cmd1", ['[{"parallel":false,"units":[{"cmd":"cmd1"}]}]']

      it "should work with 2 cmd", =>
        testOutput "./run.js --test cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}]}]']

      it "should work with --parallel", =>
        testOutput "./run.js --test --parallel cmd1 cmd2", ['[{"parallel":true,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}]}]']

      it "should work with multiple blocks", =>
        testOutput "./run.js --test --parallel cmd1 --sequential cmd2", ['[{"parallel":true,"units":[{"cmd":"cmd1"}]},{"parallel":false,"units":[{"cmd":"cmd2"}]}]']

      it "should work with --wait", =>
        testOutput "./run.js --test --wait cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}],"wait":true}]']

      it "should work with --first", =>
        testOutput "./run.js --test --first cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}],"first":true}]']

      it "should work with --master", =>
        testOutput "./run.js --test --master cmd1 cmd2", ['[{"parallel":false,"units":[{"master":true,"cmd":"cmd1"},{"cmd":"cmd2"}]}]']

      it "should work with --ignore", =>
        testOutput "./run.js --test --ignore cmd1 cmd2", ['[{"parallel":false,"units":[{"ignore":true,"cmd":"cmd1"},{"cmd":"cmd2"}]}]']

      it "should work nested", =>
        testOutput "./run.js --test \"run cmd1\"", ['[{"parallel":false,"units":[{"cmd":"run cmd1"}]}]']

    describe "run-para", =>
      it "should work", =>
        testOutput "./run-para.js --test", ['[]']

      it "should work with 1 cmd", =>
        testOutput "./run-para.js --test cmd1", ['[{"parallel":true,"units":[{"cmd":"cmd1"}]}]']

      it "should work with space in cmd", =>
        testOutput "./run-para.js --test \"cmd 1\"", ['[{"parallel":true,"units":[{"cmd":"cmd 1"}]}]']

    describe "run-npm", =>
      it "should work", =>
        testOutput "./run-npm.js --test", ['[]']

      it "should work with 1 cmd", =>
        testOutput "./run-npm.js --test cmd1", ['[{"parallel":false,"units":[{"cmd":"cmd1"}]}]']

      it "should work with space in cmd", =>
        testOutput "./run-npm.js --test \"cmd 1\"", ['[{"parallel":false,"units":[{"cmd":"cmd 1"}]}]']

      it "should match scripts", =>
        testOutput "./run-npm.js --test test", ['[{"parallel":false,"units":[{"cmd":"mocha"}]}]']

      it "should work with space in scripts", =>
        testOutput "./run-npm.js --test test2", ['[{"parallel":false,"units":[{"cmd":"nothing here 2"}]}]']

      it "should match subscripts", =>
        testOutput "./run-npm.js --test test:*", ['[{"parallel":false,"units":[{"cmd":"nothingHere2"},{"cmd":"nothingHere3"}]}]']

      it "should work with 2 scripts", =>
        testOutput "./run-npm.js --test test test2", ['[{"parallel":false,"units":[{"cmd":"mocha"},{"cmd":"nothing here 2"}]}]']

    describe "real run", =>
      child = null
      it "should work", =>
        testOutput "./run.js 'echo 'test''", ["test"]
      it "should be closeable by SIGTERM", =>
        child = testOutput "./run.js 'sleep 5'", []
        child.close("SIGTERM")

      it "should be closeable by SIGHUP", =>
        child = testOutput "./run.js 'sleep 5'", []
        child.close("SIGHUP")
      it "should be closeable by SIGINT", =>
        child = testOutput "./run.js 'sleep 5'", []
        child.close("SIGINT")
      it "should be closeable running parallel", =>
        child = testOutput "./run.js -p 'sleep 5' 'sleep 5'", []
        child.close()
      it "should be closeable using run-npm", =>
        child = testOutput "./run-npm.js 'sleep 5'", []
        child.close()
      it "should be closeable using run-para", =>
        child = testOutput "./run-para.js 'sleep 5' 'sleep 5'", []
        child.close()
