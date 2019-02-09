# webserver.sh

A simple web server written in bash

BECAUSE WHY NOT.

## What is this

This is a a series of examples of bash scripting to make a web server using little more than bash, the GNU tools, and`*Hobbit*`'s `nc` (`netcat-traditional`)... and [Bash Builder][bbuild] for the advanced example.

There are four executable versions:

* Quick and dirty implementation in `examples/webserver-dirty.sh`
* Cleaner version in `examples/webserver-functional.sh` which uses functions and local variables
* Fully functional one one in `bin/webserver.sh` which is a "compiled" version of the sources in `examples/src`
	* it is a demonstration of the use of [Bash Builder][bbuild]
* A bash-builder example using the syntax extensions

The fuller version has simple additional implemented features compared to the `dirty` and `funcitonal` variants including

* Plain text directory listing capabilities
* MIME support (from `file`)
* tree climbing protection (`http://localhost:8080/../../../..`-style requests)
* Custom port selection
* Output and logging
* Server-side commands definitions

## How to use this

Copy the `bin/webserver.sh` file to a location on your path

Then run `webserver.sh` from any folder to serve its contents.

`webserver.sh` supports GET for listing directories, and catting files.

### `functions.txt`

If a file `functions.txt` exists in the working directory, one-line commands defined within it can be run. These take no user input from the client side, and just dump all otuput to the response stream.

For a functions file containing

    df          df -h
    listnums    for x in {1..5}; do echo "- $x -"; done

each can be called using the following syntax

    http://localhost:8080/~df
    http://localhost:8080/~listnums

## When to use this

In an education setting, probably when teaching bash scripting.

## When not to use this

To serve files for real.

At worst, use `python -m SimpleHTTPServer` instead. For pity's sake.

## License

This software is provided under the terms of the GNU Affero Public License. This means that if you use this software to serve files, you must also provide anybody who asks for its corresponding source code.

Because users of such a service should be allowed to know what a heinous person you are.






  [bbuild]: https://github.com/taikedz/bash-builder "Bash Builder"
