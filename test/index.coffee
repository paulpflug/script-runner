chai = require "chai"
should = chai.should()
spawn = require("better-spawn")

api = require("../src/index.coffee")

waitingProcess = (time=10000) -> "node -e 'setTimeout(function(){},#{time});'"
failingProcess = "node -e 'throw new Error();'"

options = silent: true

describe "parallelshell", ->
  describe "API", ->
    describe "sequential/parallel", ->
      it "should regulary close with exitCode 0", (done) ->
        api [{parallel:false, units: [{cmd:waitingProcess(10)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
      it "should regulary close with exitCode 0 in parallel mode", (done) ->
        api [{parallel:true, units: [{cmd:waitingProcess(10)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
      it "should close with exitCode 1 on error", (done) ->
        api [{parallel:false, units: [{cmd:failingProcess}]}],options, (exitCode) ->
          exitCode.should.equal 1
          done()
      it "should close with exitCode 1 on error in parallel mode", (done) ->
        api [{parallel:true, units: [{cmd:failingProcess}]}],options, (exitCode) ->
          exitCode.should.equal 1
          done()
      it "should run sequential", (done) ->
        closed = false
        close = api [{parallel:false, units: [{cmd:waitingProcess()},{cmd:failingProcess}]}],options, (exitCode) ->
          exitCode.should.equal 1
          closed = true
        setTimeout close, 80
        setTimeout (-> closed.should.be.true;done()),100
      it "should run parallel", (done) ->
        api [{parallel:true, units: [{cmd:waitingProcess()},{cmd:failingProcess}]}],options, (exitCode) ->
          exitCode.should.equal 1
          done()
      it "should run groups sequential", (done) ->
        closed = false
        api [
          {
            parallel:false
            units: [{cmd:waitingProcess(100)}]
          },{
            parallel:false
            units: [{cmd:waitingProcess(100)}]
          }
          ],options, (exitCode) ->
          exitCode.should.equal 0
          closed = true
          done()
        setTimeout (-> closed.should.be.false),150
      it "should close groups on error", (done) ->
        api [
          {
            parallel:false
            units: [{cmd:failingProcess}]
          },{
            parallel:false
            units: [{cmd:waitingProcess(1000)}]
          }
          ],options, (exitCode) ->
          exitCode.should.equal 1
          done()
    describe "--ignore", ->
      it "should work in sequential mode", (done) ->
        close = api [{parallel:false, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
      it "should work in parallel mode", (done) ->
        close = api [{parallel:true, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
    describe "--first", ->
      it "should work in parallel mode", (done) ->
        close = api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
      it "should respekt --ignore", (done) ->
        closed = false
        close = api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10),ignore:true}]}],options, (exitCode) ->
          exitCode.should.equal 1
          closed = true
        setTimeout (-> closed.should.be.false;close()),50
        setTimeout (-> closed.should.be.true;done()),100
    describe "--wait", ->
      it "should work in parallel mode", (done) ->
        closed = false
        close = api [{parallel:true,wait:true, units: [{cmd:failingProcess},{cmd:waitingProcess(60)}]}],options, (exitCode) ->
          exitCode.should.equal 1
          closed = true
        setTimeout (-> closed.should.be.false),50
        setTimeout (-> closed.should.be.true;done()),200
      it "should respekt --ignore", (done) ->
        closed = false
        close = api [{parallel:true,wait:true, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(60)}]}],options, (exitCode) ->
          exitCode.should.equal 0
          closed = true
        setTimeout (-> closed.should.be.false),50
        setTimeout (-> closed.should.be.true;done()),200
    describe "--master", ->
      it "should work in parallel mode", (done) ->
        close = api [{parallel:true,wait:true,units: [{cmd:failingProcess,master:true},{cmd:waitingProcess(100)}]}],options, (exitCode) ->
          exitCode.should.equal 1
          done()
      it "should work in parallel mode", (done) ->
        close = api [{parallel:true,units: [{cmd:waitingProcess()},{cmd:waitingProcess(80),master:true}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
    describe "nesting", ->
      it "should work", (done) ->
        api [{parallel:false,units: [{cmd:"./run.js \""+waitingProcess(10)+"\""}]}],options, (exitCode) ->
          exitCode.should.equal 0
          done()
  describe "CLI", ->
    testOutput = (cmd, expectedOutput, done, std="out") ->
      child = spawn cmd, stdio:"pipe"
      if std == "out"
        std = child.stdout
      else
        std = child.stderr
      std.setEncoding("utf8")
      output = []
      std.on "data", (data) ->
        lines = data.split("\n")
        lines.pop() if lines[lines.length-1] == ""
        output = output.concat(lines)
      std.on "end", () ->
        for line,i in expectedOutput
          line.should.equal output[i]
        done()
      return child
    describe "run", ->
      it "should work", (done) ->
        testOutput "./run.js --test", ['[]'], done

      it "should work with 1 cmd", (done) ->
        testOutput "./run.js --test cmd1", ['[{"parallel":false,"units":[{"cmd":"cmd1"}]}]'], done

      it "should work with 2 cmd", (done) ->
        testOutput "./run.js --test cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}]}]'], done

      it "should work with --parallel", (done) ->
        testOutput "./run.js --test --parallel cmd1 cmd2", ['[{"parallel":true,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}]}]'], done

      it "should work with multiple blocks", (done) ->
        testOutput "./run.js --test --parallel cmd1 --sequential cmd2", ['[{"parallel":true,"units":[{"cmd":"cmd1"}]},{"parallel":false,"units":[{"cmd":"cmd2"}]}]'], done

      it "should work with --wait", (done) ->
        testOutput "./run.js --test --wait cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}],"wait":true}]'], done

      it "should work with --first", (done) ->
        testOutput "./run.js --test --first cmd1 cmd2", ['[{"parallel":false,"units":[{"cmd":"cmd1"},{"cmd":"cmd2"}],"first":true}]'], done

      it "should work with --master", (done) ->
        testOutput "./run.js --test --master cmd1 cmd2", ['[{"parallel":false,"units":[{"master":true,"cmd":"cmd1"},{"cmd":"cmd2"}]}]'], done

      it "should work with --ignore", (done) ->
        testOutput "./run.js --test --ignore cmd1 cmd2", ['[{"parallel":false,"units":[{"ignore":true,"cmd":"cmd1"},{"cmd":"cmd2"}]}]'], done

      it "should work nested", (done) ->
        testOutput "./run.js --test \"run cmd1\"", ['[{"parallel":false,"units":[{"cmd":"run cmd1"}]}]'], done

    describe "run-para", ->
      it "should work", (done) ->
        testOutput "./run-para.js --test", ['[]'], done

      it "should work with 1 cmd", (done) ->
        testOutput "./run-para.js --test cmd1", ['[{"parallel":true,"units":[{"cmd":"cmd1"}]}]'], done

      it "should work with space in cmd", (done) ->
        testOutput "./run-para.js --test \"cmd 1\"", ['[{"parallel":true,"units":[{"cmd":"cmd 1"}]}]'], done

    describe "run-npm", ->
      it "should work", (done) ->
        testOutput "./run-npm.js --test", ['[]'], done

      it "should work with 1 cmd", (done) ->
        testOutput "./run-npm.js --test cmd1", ['[{"parallel":false,"units":[{"cmd":"cmd1"}]}]'], done

      it "should work with space in cmd", (done) ->
        testOutput "./run-npm.js --test \"cmd 1\"", ['[{"parallel":false,"units":[{"cmd":"cmd 1"}]}]'], done

      it "should match scripts", (done) ->
        testOutput "./run-npm.js --test test", ['[{"parallel":false,"units":[{"cmd":"mocha"}]}]'], done

      it "should work with space in scripts", (done) ->
        testOutput "./run-npm.js --test test2", ['[{"parallel":false,"units":[{"cmd":"nothing here 2"}]}]'], done

      it "should match subscripts", (done) ->
        testOutput "./run-npm.js --test test:*", ['[{"parallel":false,"units":[{"cmd":"nothingHere2"},{"cmd":"nothingHere3"}]}]'], done

      it "should work with 2 scripts", (done) ->
        testOutput "./run-npm.js --test test test2", ['[{"parallel":false,"units":[{"cmd":"mocha"},{"cmd":"nothing here 2"}]}]'], done

    describe "real run", ->
      child = null
      it "should work", (done) ->
        testOutput "./run.js 'echo 'test''", ["test"], done
      it "should be closeable by SIGTERM", (done) ->
        child = testOutput "./run.js 'sleep 5'", [], done
        child.close("SIGTERM")
      it "should be closeable by SIGHUP", (done) ->
        child = testOutput "./run.js 'sleep 5'", [], done
        child.close("SIGHUP")
      it "should be closeable by SIGINT", (done) ->
        child = testOutput "./run.js 'sleep 5'", [], done
        child.close("SIGINT")
      it "should be closeable running parallel", (done) ->
        child = testOutput "./run.js -p 'sleep 5' 'sleep 5'", [], done
        child.close()
      it "should be closeable using run-npm", (done) ->
        child = testOutput "./run-npm.js 'sleep 5'", [], done
        child.close()
      it "should be closeable using run-para", (done) ->
        child = testOutput "./run-para.js 'sleep 5' 'sleep 5'", [], done
        child.close()
