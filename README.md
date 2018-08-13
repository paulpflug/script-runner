## Script runner

Invoke multiple commands, running in parallel / sequential, matching npm scripts

### Install

```bash
npm install --save-dev script-runner
```

### Usage

```
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
```

### Examples

```bash
run "echo 1" "echo 2"
run-para "echo 1" "echo 2"
run-npm build:*
run mocha
run-npm -p serve --master "run-npm 'sleep 1' test:e2e"
```

```json
// package.json
"scripts": {
    ...
    "build": "run-npm build:*",
    "build:step1": "do something",
    "build:step2": "do another thing"
    ...
}
```


## License
Copyright (c) 2016 Paul Pflugradt
Licensed under the MIT license.
