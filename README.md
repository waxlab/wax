# Wax

Wax is a multi module project that aims to bring a wider range of tools
beyond the own Lua standard library.

By now, it is fully supported under Linux and the major BSD representants
(FreeBSD, OpenBSD, Dragonfly BSD and NetBSD).


## Quickstart

luarocks install wax


## Requirements
The minimum requirements to run are:

* Lua 5.1, 5.2, 5,3 and 5,4 (it runs the tests through all versions)
* Luarocks >= 3.8.0

Binary modules are tested on different Unix systems:

* Debian (as common user)
* Debian Container (as root)
* BSDs (FreeBSD, OpenBSD, NetBSD and Dragonfly) as root and common user.


## Contribute

You have a plenty of ways to contribute to this project:

* Sponsoring the developer
* Reporting well detailed bugs and with code demonstration of that.
* Suggesting features with use examples.
* Testing in different OSes POSIX compliant
* Developing conditionals on code for use with Windows, by now not
supported (See "Using under Windows" section).


## Development

* The latest tested version is under the `latest` branch
* Releases can be downloaded with `luarocks`


## Versioning

As Lua starts from index 1, our versioning also does.
Stability is a matter of tests, so every module under this project
should have its tests well documented and passed before become release.

Examples:

* wax-1.0-0 - A version
* wax-1.0-2 - The same as above but some performance or bugs corrected.
* wax-1.1-0 - Implements new features

* wax-scm-1 - "Nightly"


## Running tests under multiple Linuxes

You can run the tests under other Linux flavors using Docker.
The dockerfiles needed are found under the assets folder.

To list available dockerfiles:

    `lua ./run dbuild`

To run the tests under the docker instance:

    `lua ./run dtest`

To enter on docker and test:

    `lua ./run drun`

Observe than `./run drun` expects that the instance have bash installed.


