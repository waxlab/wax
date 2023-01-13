![Wax](https://repository-images.githubusercontent.com/527150563/25981ea3-4df3-4c7e-b496-6c66ee7a5574)

# Wax

Wax is a Lua package containing a set of modules to extend the Lua standard
library for multipurpose programming. It intends to inforce good practices
and less boilerplate code, while not building up to a dependency or abstraction
hell.

By now, it is fully supported under Linux and the major BSD representants
(FreeBSD, OpenBSD, Dragonfly BSD and NetBSD).

By now you can read a short list of available functions in the
[Wiki](https://codeberg.org/waxlab/wax/wiki)
or dive in the full examples within the Lua files inside ./test folder.

In future these tests will be used to generate the full wiki documentation.


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


## Contribute

You can [donate](https://liberapay.com/WaxLab/donate) or help us
reviewing, reporting, testing or coding.
See contribution [guidelines](contributing.md) for more information.

The main code home is https://codeberg.org/waxlab/wax repository.
Head there to read about lastest commits, bug reporting or discussions.


## Join Community

Join our [Matrix channel]([https://matrix.to/#/#wax-lua:matrix.org])
created basically for announcements and discussions about the future of project.


## Development

* The latest tested version is under the `latest` branch
* Releases can be downloaded with `luarocks`


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
