## Script runner

Because dependencies of build or other processes are difficult to handle, a tool is needed to make package management easy again.
Script runner has four handy cli tools to manage processes and run npm scripts.

### Install

```bash
npm install script-runner
```

### Usage

```
usage: run [<options> [cmd..]..]

options:
-h, --help         output usage information
-v, --verbose      verbose logging (not implemented yet)

    --silent       suppress output of children
-t, --test         no runing only show process structure
-s, --sequential   following cmds will be run in sequenz
-p, --parallel     following cmds will be run in parallel
-i, --ignore       the following cmd will be ignored for --first, --wait and errors
-f, --first        only in parallel block: close all sibling processes after first exits (succes/error)
-w, --wait         only in parallel block: will not close sibling processes on error
-m, --master       only in parallel block: close all sibling processes when the following cmd exits. exitCode will only depend on master
-f, --first        close all sibling processes after first exits (succes/error)

run also looks in node_modules/.bin for cmds
run-para is a shorthand for run --parallel
run-seq is a longhand for run
run-npm will match cmd with npm script and replace them, usage of globs is allowed
```

### Examples

```bash
run "echo 1" "echo 2"
run-para "echo 1" "echo 2"
run-npm build:*
```


## License
Copyright (c) 2016 Paul Pflugradt
Licensed under the MIT license.
