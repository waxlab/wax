# Development Guidelines

## Development flow

Any development should follow this flow:

1. Plan and represent Usage (return and parameters)
2. Lua code documenting with tests
3. Development with C or Lua
4. Test
5. Bug reporting


### 1. Plan and Represent Usage

Wax focus in the most common boilerplate code in Lua and the most needed
resources for Lua use as a system programming language and multipurpose one.
So we should be aware that modules should contain only the resources that makes
more sense to the scope of module.

Wax library functions should have some characteristics described below.

**Impure functions should have descriptive error**

When the function is impure, i.e., depends of a external program state, it
it should return `nil` and a `string` containing the error description.

Ex.1: (Impure) `writeString(file,content)`, a function that behaves differently
even if you pass the same values for the name of the file and the file content:
 - disk can be full
 - disk can be corrupted
 - file can be locked
 - current user can have no write permission etc.

Ex.2: (Impure) `canWrite()`, a function to check write permission to a file.
You expect it return `true` for yes or `false` for no. But this function
depends of the external environment state: 
 - file or its path doesn't exist
 - filesystem is corrupted
 - any other problem with OS, disk, memory, weather, hour of day, sky color etc.

Ex.3: (Impure) `getLastInfo()` get some data from a network or database.
 - network is off
 - remote file or database doesn't exist
 - malformed url
 - timeout
 - in case of a database, corrupted data

Ex.4: (Pure) `squareArea(x,y)` the result will always be the same when the same
arguments be passed as the same parameters.


Examples 1 and 2 can return a boolean. But a false can not be clear **why** and
how it could be made true. A better aproach is have beside the main return a
second return giving the reason:

    local res, err = writeString(file,content)
    if not res and err then
        -- handle the exception
    end
    -- Do what you want with data


Example 3 expects a string as its result. But if something wrong happens, how
to know it? how to handle the error?

    local res, err = getLastInfo(somearg)
    if not res and err then
        -- handle the exception
    end
    -- Do what you want with data

Example 4 shows that the value always be a number, so we only expect a number.
Also the result will **always** be 200:

    local res = squareArea(10,20)

So, for every impure function, via Lua or Lua C Api, the function must always
return a default type in success (ex. `string`, `number`, `boolean`) and `nil`
on error. Also, a second value should returned with a descriptive string.

**When possible, use tail calls**

Lua allows tail call optimization, i,e., a function call returns a function
call to the same or other function. Instead of the sucessive calls, when
running the code the interpreter. See the book
[Programming in Lua](https://www.lua.org/pil/6.3.html) and the more
[tail call examples](https://stackoverflow.com/questions/13303347/tail-call-optimization-in-lua).


# Developing / Documenting / Testing

This project pairs tests and documentation, creating an interesting flow
where nothing is undocumented, nothing is untested.

1. each function developed in C needs to has its tests developed
   beforehand.

2. tests should cover the intended behavior, ie.:
 - how it should behave?
 - which should be the return if exact?
 - which should be the return range if inexact?
 - when it should fail?
 - how it should fail?
 - how the fail can be handled?

3. These tests should be executed in a clear scope of variables and
   documented with self explanatory comments and comment blocks.

4. These comment blocks should be parseable to generate documentation
   directly from tests.


### Lua Code Documenting With Tests

Once you know what you want, develop a test inside the project `tests/` folder.
- Each module should have its own test file.
- Each function should have its own `do ... end` block
- Tests are focused in the expected behavior not its exceptions.
- An exception can be tested to check the C test branch and to make explicit
  in documentation the way the exception should be handled.

Observe that the test code in Lua is commented in some different way. All the
text to be converted in markdown should start with `--|` or `--{` or `--}`.
The `--{` and `--}` are used to delimitate that code between them should be
shown on documentation. The test/document lua file follows this structure:

 1. Header of file, describing with module is being tested/documented.
    --| ## wax.fs
    --| Module for filesystem operations.

 2. Block of the test, useful to make local variables scoped.
    do
      -- Inside it goes the item 3
    end

 3. Function signature as markdown header level 3 followed with descriptin
    --| ### wax.fs.stat(path:string) : string | nil, string
    --{ Get the stat information for the `path`
        -- Inside it goest the item 4
    --}

 4. Tests use Lua `assert()` function to make tests break and trace to the
 line.
        -- As this area is of the test, use simple comments
        -- Use local variables for clarity. They are and scoped in do/end block
        local filename = "somefile"
        local res, err = wax.fs.stat(filename)
        assert(type(res.uid) == "number" and res.uid > 0)
        -- etc...

When written all together:

    --| ## wax.fs
    --| Module for filesystem operations.

    do
    --| ### wax.fs.stat(path:string) : string | nil, string
    --{ Get the stat information for the `path`
        -- As this area is of the test, use simple comments
        -- Use local variables for clarity. They are and scoped in do/end block
        local filename = "somefile"
        local res, err = wax.fs.stat(filename)
        assert(type(res.uid) == "number" and res.uid > 0)
        -- etc...
    --}
    end


All the module development should be guide by the tests in these Lua files.
The same files should be use to generate documentation. The premise is:
 - tests define what is expected
 - tests define what the code should do
 - tests are the documentation
 - if it is documented then it works


### 3. Development with C or Lua

Modules written in Lua as well as C and C headers should be placed under `./src`
folder. The rockspec file should be updated and tests should be done using
the `make test` on current machine and `sudo make dtest` with docker.

Any function used along with Lua C api should be placed under `./src`. If you
need to write a bigger set of C functions you can place them under `./src/lib`
and call them from the module written inside `./src` folder.

Use the rockspec as example. Read the **C Code Design** for more info.


### 4. Test

To test you need basically...

- GNU Make
- Luarocks
- GCC compiler
- Lua headers, library and interpreters for versions 5.1 - 5.4
- Docker

With all of them installed you can test locally with `make test`.

It is a must to test administrative permissions along with the code. In that
case we need a Docker instance to avoid some chaos from testing with the
machine root.

To build the Docker instance:

    sudo make dbuild

To test with Docker instance
    sudo make dtest

Observe that all the code is tested under Docker with `root` permission.
Docker is also good as guarantee you are testing in an "clean" environment.

After tests, if something goes wrong, you always can issue `make clean` to
remove the local modules and compiled code. If the code was generated inside
the Docker instance, you may need to run `sudo make clean`.



### 5. Bug Reporting

Bugs should be reported containing in the function crumb (ex: `wax.fs.stat()`)
and should be descriptive in how to reproduce errors. Not reproducible errors
will be closed.

Also, before opening a new bug please take a look if not other is opened yet
for the same matter.


# C Code Design

Wax intends to improve Lua capabilities with libraries. So its C code should
also be familiar for Lua coders that know C or newbies on C that are comming
from Lua.

If you want to contribute with Wax development, when style doesn't affect
performance, the style designs represented below should be used.

## Alignment and Indentation

1. Indented code should be 2 spaces wide. On early days of programming, in
70s and 80s, programming screens had 80 columns. Today wider screens can
have more, but you can have more files side by side... open a documentation
etc. Not every one have three or four screens. Also code in such way, allows
people to contribute, edit, review from different screens, even from a
termux on mobile or a netbook.

2. Limit lines to 80 characters. Most of time it sufficient because:
 - Internal functions, custom types and variables doesn't need long names
 - Functions exported trough `luaopen_*` receives a single argument, the
   `lua_State *L`
 - Deep nesting is a clear sign that the function should be refactored.
 - If you have poor eyesight you will need larger letters.
 - If you have good eyesight you can enjoy three side by side files opened.

3. Align codes on multiple assigns. If alignment weren't good no one would
use tables, spreadsheets etc. anymore.

Don't do this:
```
uinfo.name = pw->pw_name;
uinfo.dir = pw->pw_dir;
uinfo.uid = pw->pw_uid;
uinfo.shell = pw->pw_shell;
uinfo.gnum = gnum;
uinfo.gids = gids;
```

Do this instead:
```
uinfo.dir   = pw->pw_dir;
uinfo.gids  = gids;
uinfo.gnum  = gnum;
uinfo.name  = pw->pw_name;
uinfo.shell = pw->pw_shell;
uinfo.uid   = pw->pw_uid;
```

4. Observe in the above example that beyond the alignment, code was reordered
in alphabetical order. Well, it helps too.

5. Braces should be used with previous statement/instruction:

Don't do this:
```
static int something()
{
  /* Function body */
}
```

Do this instead:
```
static int something() {
  /* Function body */
}
```

6. Use blank lines wisely:
 - 1 line when separating blocks inside function.
 - 2 lines between two functions
 - 3 lines between blocks of functions separated by section comment
 - 0 lines can be used for one line functions or macros when they are grouped
 by same characteristics (one liner, purpose, parameter and type etc.)



## Comments

1. Use comments in format `/* */`. For multiple lines prefer the design:

```
/* first line of comment...
** and second line here
*/
```

2. Comment **what** the block of code does, not **how**. If the functions are
well named most of times **what** function does is already clear, and no
further comment is necessary.



## Functions

1. Functions not to be exported should be defined with `static` keyword. I.e.
for a Lua module C code only the `luaopen_*` should not have the `static`
keyword and have an entry in header. The functions that will be exposed through
the `luaopen_*` should have the `static` keyword.

2. Static functions (and variables/constants) exposed to Lua module through
`luaopen_*` function should have the module name/path prefix. Examples: 
  * the C function `wax_fs_stat()` should be found as `wax.fs.stat()` by Lua;
  * the C function `wax_user_name()` as  `wax.user.name()` on Lua module;

3. For private functions (i.e. not to be exposed with the Lua module) the names
should be in camelCase (always initiated by lowercase).

4. The functions should return early as possible. Many of times this approach
will avoid variables to follow the state of function and will make use further
debuging.

* Always use `static` for function declarations.

* Use curly braces in the same line of previous statement/test/declaration,
even for functions. C can be programmed with resemblances with other languages.
C has its differences from other languages. Why to add more peculiarities
where they are not needed?


## Function macros

* Macros for simplifying Lua C Api usage should be put under `src/lib/axa.h`
and be prefixed with `axa_`. If some macro should be used specifically for
the module in development, it should be put under the specific module C header.


## "Scoped" pre processor code

Use preprocessor not only to avoid larger blocks of boiler plate code for the
consumer of your code. Use them to make explicit the intention of your code.

If you deal with larger structs and need to repeat the same code many times in
a way you can abstract it... abstract it!

When you abstract things that repeats many times, you allows your code to be
prone of say something is wrong early and avoids typing errors for parts of code
that can pass untested or with errors difficult to reproduce. A good example
is the `wax.fs.stat()` that uses `axa_field_si()` macro to simplify multiple
assignments to a Lua table.

**Never** create a macro using return. It can break things and difficult to
spot errors.


## Readability / Maintainability

1. **Curlyless tests** : Don't write if/else conditions without curly braces.
Curly braces make explicit the intention.

Instead of this:
    if (true)
      callsomething();
    callotherthing();

Always write this way:
    if (true) {
      callsomething();
    }
    callotherthing();

Keep your identation correct. But even with good identation you can't rely
just in it as correctness or your code. C relies only on semicolons and
curly braces. Why should you rely on indentation?


2. **Ternaries** : While "style" is more about spaces, indenting, aligning
things, readability and even more maintainability goes further.

While ternaries are cute, a line that do three things are not better that one
thing in one line. A ternary does basically three!

Instead of:

    int a = somevar > b ? x : y;

Prefer always

    int a;
    if (somevar) {
      a = x;
    } else {
      a = y;
    }

Remember: shorter code is better, shorter and explicit code is even better.

## Globals

Avoid them. OK? Unless strictly necessary.

## Memory allocation

Sometimes you may need to manually manage the memory allocation.

As much as possible, prefer:
 - allocate the memory inside the called function;
 - free on the caller;

Always:
 - suffix the called function that returns a malloc with `_ma`
 - if a function doesn't frees the return of a internally called `_ma` it
 should be also has name containing the `_ma`.
 - call `free()` as soon as possible.

