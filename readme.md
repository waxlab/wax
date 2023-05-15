![Wax](https://repository-images.githubusercontent.com/527150563/25981ea3-4df3-4c7e-b496-6c66ee7a5574)

# Wax

Wax is a Lua package, that aims to provide increasing support to the most
common scripting tasks. Its name comes from the astronomical term used to
describe a planetary body that looks to be "waxing" or "crescent" as its
surface is revealed by its main star light.

Wax contains a set of subpackages or modules to extend the Lua standard
library for multipurpose programming. Also, its source code, provide a simple
C header libraries to help when developing Lua C modules.


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


## Systems Support

By now, it is fully supported under Linux.
BSD's support was dropped, so some adjusts may be needed on building process.
Windows support is not on plans due to the expensiveness development cost on
OS register, and also by WSL offering ways to use it natively as it would
a Linux system.



* Documentation:
[GitHub](https://github.com/waxlab/wax/wiki)
[GitLab](https://gitlab.com/waxlab/wax/wiki)
[Codeberg](https://codeberg.org/waxlab/wax/wiki)

* Roadmap:
[GitHub](https://github.com/waxlab/wax/tree/meta/roadmap/)
[GitLab](https://gitlab.com/waxlab/wax/tree/meta/roadmap/)
[Codeberg](https://codeberg.org/waxlab/wax/src/branch/meta/roadmap/)

* Issues:
[GitHub](https://github.com/waxlab/wax/tree/meta/issues/)
[GitLab](https://gitlab.com/waxlab/wax/tree/meta/issues/)
[Codeberg](https://codeberg.org/waxlab/wax/src/branch/meta/issues/)

* Contributors:
[GitHub](https://github.com/waxlab/wax/tree/meta/contributors/)
[GitLab](https://gitlab.com/waxlab/wax/tree/meta/contributors/)
[Codeberg](https://codeberg.org/waxlab/wax/src/branch/meta/contributors/)

* Donate:
[Liberapay](https://liberapay.com/WaxLab/donate)



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

There are two main branches: `latest` and `dev`.

* `latest` contains the latest public release.
* `dev` is the recipient of the development on other branches.

When developing a feature, ex. `wax.os.pipeline()`, use a separate branch like
`dev-os.pipeline` that should be merged with `dev` **only** after developed,
just for tests before to be released as a version.

Each version has its own tag, and Luarocks rockspec points to that.


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

