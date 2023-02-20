![Wax](https://repository-images.githubusercontent.com/527150563/25981ea3-4df3-4c7e-b496-6c66ee7a5574)

# Wax

The word Wax: increasing of size, development, prosperity and strength,
also the word used to describe the Moon phase and planets like Venus and Mercury.

Wax is a Lua package containing a set of modules to extend the Lua standard
library for multipurpose programming. It aims to enforce some good practices
and take advantage of the Lua way of doing things.

By now, it is fully supported under Linux and the major BSD representants
(FreeBSD, OpenBSD, Dragonfly BSD and NetBSD).

* [Documentation / Wiki](./wiki)
* [Roadmap](tree/meta/roadmap/)
* [Issues](tree/meta/issues/)
* [Contributors](tree/meta/contributors/)
* [Donate](https://liberapay.com/WaxLab/donate)


## Quickstart

luarocks install wax


## Requirements
The minimum requirements to run are:

* Lua 5.1, 5.2, 5,3 and 5,4 (it runs the tests through all versions)
* Luarocks >= 3.8.0

Binary modules are tested on different Unix systems:

* Debian (as common user) - Most frequent
* Debian Container (as root)
* BSDs (FreeBSD, OpenBSD, NetBSD and Dragonfly) as root and common user.


## Principles

* If developed then documented.
* If documented then tested.
* If released then tested.
* Never full or fool. More power but less bloat.
* Discretion. Simplicity matters more than the last programming fashion.
* Thoughtfull development. Avoid unnecessary features and compatibility issues.
* Consistency. Namings, conventions, syntax should be harmonic between modules.
* Intuitivity and previsibility. The siblings of the consistency.


## Versioning

The versioning uses a mix of year and features. So is really easy to understand
what is going on.

```
1.10-5
|  | '--- 5th correction of 1.10
|  '----- 10th feature implemented
'-------- 1st year of module.
```

The development version should be got directly from the repository under the
`dev` branch.

While the `latest` branch contains the latest tested code, it may be slightly
newer than the lastest rock found under Luarocks.


## Running tests under multiple Linuxes

You can run the tests under other Linux flavors using Docker. The dockerfiles
needed are found under the assets folder.

To list available dockerfiles:

	`lua ./run dbuild`

To run the tests under the docker instance:

	`lua ./run dtest`

To enter on docker and test:

	`lua ./run drun`

Observe than `./run drun` expects that the instance has bash installed.


## Help and Documentation

To see a list of functions in all modules of Wax package, you can clone this
repository and execute the script at its root directory:

	./run help

Also there is a simple navigation tool as script. To run it you need bash, fzf,
grep and sed. Like before, head to the root directory of the wax and execute:

	./view

Then you can filter while previewing the help and tests for the functions.

The `run help` and `view` scripts are just a temporary improvisation to get the
access to the documentation as a documentation extraction, conversion and a
simple viewer for console should take its way to the project some day in future.
