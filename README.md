# webserver.sh

A simple web server written in bash

BECAUSE WHY NOT.

## What is this

This is a a series of examples of bash scripting to make a web server using little more than bash, the GNU tools, and`*Hobbit*`'s `nc` (`netcat-traditional`)... and Bash Builder for the advanced example.

There are three executable versions:

* Quick and dirty implementation in `examples/webserver-dirty.sh`
* Cleaner version in `examples/webserver-functional.sh` which uses functions and local variables
* Fully functional one one in `bin/webserver.sh` which is a "compiled" version of the sources in `examples/src`
	* it is a demonstration of the use of [Bash Builder](https://github.com/taikedz/bash-builder)

The fuller version has simple additional implemented features compared to the `dirty` and `funcitonal` variants including

* Plain text directory listing capabilities
* MIME support (from `file`)
* tree climbing protection (`http://localhost:8080/../../../..`-style requests)
* Custom port selection
* Output and logging

## How to use this

Copy the `bin/webserver.sh` file to a location on your path

Then run `webserver.sh` from any folder to serve its contents.

`webserver.sh` supports GET for listing directories, and catting files.

## When to use this

In an educational setting ?

## When not to use this

To serve files for real.
