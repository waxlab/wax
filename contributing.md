# CONTRIBUTING

You can contribute with Wax and WaxLab:
* [Donating](https://liberapay.com/WaxLab/donate).
* Reporting well detailed bugs.
* Suggesting features with use examples.
* Testing in different POSIX compliant OSes.


To enter in the Wax projects, a module has to prove that is simple to be used,
usable to build common patterns and of the kind that avoids boilerplate.

Contributions are accepted once discussed as an issue. Also, the most valuable
contribution at the moment is testing and proving that what is already done
is on the right way, i.e. using it and giving feedback you are really doing
a great contribution.

Please note we have a code of conduct, please follow it in all your
interactions with the project.



## Documenting

Instead of a polluted source code with cryptical comments and strange decorations,
Wax opts to keep on the source code only the comments needed to understand what
the code IS DOING.

To understand HOW TO USE code, the documentation should be with the tests. So
while developer see the documentation it also understand explicitly what to
expect and also has examples.

Also this approach makes the documentation works not as a product result, but
also as the basis to development and its rails.

The documentation is, by now, under the `./test` folder as plain Lua files.
The only difference is that the documentation are on a specific Lua comment
format:

- All documentation lines are started with the `--`
- The comment sign `--` is immediately followed by a marker. Actually there is
only 4 types of mark that work as a mixing interface between Markdown and Lua
code. This shouldn't be extended in future to keep the maximum of simplicity
and flexibility.

The markers used are one of the following: `$`, `|`, `{` or `}`. So if line of
the Lua code starts with:

- `--$ XXX` so XXX will be considered as function or code signature
- `--| XXX` will be considered as plain Markdown
- `--{` then the subsequent lines of code (LOC) until a line started by `--}`
will be included on the documentation.

Messy code used for hard tests and that are less instructional for the user of
the module can be kept outside the blocks delimited by lines started
with `--{` and `--}`

Use `./test/wax/json.lua` as reference.

For C code, basically documenting for extraction purposes are only needed on
the files under `src/w` folder. In this case, every comment is under multiline
comment in this way:

```
/*
//## This is a H2
//| This is the content
//$ void funsignature(lua_State *L)
*/
```




## Testing code

* **Use sparse** Sparse has proven to be a simple way to avoid common mistakes
that can lead to obscure bugs. Run `./run sparse` always, specially before
pull requests.

* **Always test under multiple Lua versions**. Check the main project documentation
to know which Lua versions should be supported.


## Configure your text editor

For C and Lua files our coding style uses:


* `80` column wide

* Tab for indentation - You should be smart enough to know how to use tabs
as indentation and how to align things around with spaces instead of tabs.
If not, it's always a good time to get smarter.

* C curly braces opening `{` should be kept in the line where expression or
function name is declared.

* Function body should never have more than one empty line.

* Between functions (function with bodies, not declaration only) should
always to have at least two empty lines.

These very simple rules make C more accessible and simple to read by who is
accostumed with other languages while also keeping code short for use in
different screens, from mobile to desktop and easy to open side by side in
different editors leaving to reader to choose how many spaces a indentation
level should be presented.
  
