{test} = require "snapy"

api = require "../src/api.coffee"

waitingProcess = (time=10000) => "node -e 'setTimeout(function(){console.log(\"waiting #{time}\")},#{time});'"
failingProcess = "node -e 'throw new Error();'"
options = silent: false, noErr: false

test (snap) =>
  # success in sequenz
  {done} = api [{parallel:false, units: [{cmd:waitingProcess(10)}]}],options
  snap promise: done
  # success in parallel
  {done} = api [{parallel:true, units: [{cmd:waitingProcess(10)}]}],options
  snap promise: done

test (snap) =>
  # fail in sequenz
  {done} = api [{parallel:false, units: [{cmd:failingProcess}]}],options
  snap promise: done
  # fail in parallel
  {done} = api [{parallel:true, units: [{cmd:failingProcess}]}],options
  snap promise: done

test (snap) =>
  # fail in sequenz with multiple processes
  {done} = api [{parallel:false, units: [{cmd:failingProcess},{cmd:waitingProcess()}]}],options
  snap promise: done
  # fail in parallel with multiple processes
  {done} = api [{parallel:true, units: [{cmd:waitingProcess()},{cmd:failingProcess}]}],options
  snap promise: done

test (snap) =>
  # should fail because it is still running with multiple process groups
  {close} = api [
        {
          parallel:false
          units: [{cmd:waitingProcess(50)}]
        },{
          parallel:false
          units: [{cmd:waitingProcess(50)}]
        }
      ],options
  setTimeout (=>snap promise: close()),80
  # should fail because it is still running with multiple process groups
  {close} = api [
        {
          parallel:true
          units: [{cmd:waitingProcess(50)}]
        },{
          parallel:true
          units: [{cmd:waitingProcess(50)}]
        }
      ],options
  setTimeout (=>snap promise: close()),80

test (snap) =>
  # fail in sequenz with multiple process groups
  {done} = api [
        {
          parallel:false
          units: [{cmd:failingProcess}]
        },{
          parallel:false
          units: [{cmd:waitingProcess()}]
        }
      ],options
  snap promise: done
  # fail in parallel with multiple process groups
  {done} = api [
        {
          parallel:true
          units: [{cmd:failingProcess}]
        },{
          parallel:false
          units: [{cmd:waitingProcess()}]
        }
      ],options
  snap promise: done

test (snap) =>
  # exitcode 0 with ignore
  {done} = api [{parallel:false, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options
  snap promise: done
  # exitcode 0 with ignore in parellel
  {done} = api [{parallel:true, units: [{cmd:failingProcess,ignore:true},{cmd:waitingProcess(10)}]}],options
  snap promise: done

test (snap) =>
  # first should work successful
  {done} = api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10)}]}],options
  snap promise: done

  # first should respekt ignore and be still running while closing
  {close} = api [{parallel:true,first:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10),ignore:true}]}],options

  setTimeout (=>snap promise: close()),50

test (snap) =>
  # wait should keep process running
  {close} = api [{parallel:true,wait:true, units: [{cmd:failingProcess},{cmd:waitingProcess(100)}]}],options
  setTimeout (=>snap promise: close()),50

test (snap) =>
  # master should rule exitcode successful
  {done} = api [{parallel:true, units: [{cmd:failingProcess},{cmd:waitingProcess(10),master:true}]}],options
  snap promise: done
  # master should kill siblings, but return successful
  {done} = api [{parallel:true, units: [{cmd:waitingProcess()},{cmd:waitingProcess(10),master:true}]}],options
  snap promise: done

