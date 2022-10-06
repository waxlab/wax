# CONTRIBUTING

To enter in the Wax projects, a module has to prove that is simple to be used,
usable to build common patterns and of the kind that avoids boilerplate.

Contributions are accepted once discussed as an issue. Also, the most valuable
contribution at the moment is testing and proving that what is already done
is on the right way, i.e. using it and giving feedback you are really doing
a great contribution.

Please note we have a code of conduct, please follow it in all your
interactions with the project.


## Testing code

* **Use sparse** Sparse has proven to be a simple way to avoid common mistakes
that can lead to obscure bugs. Run `./run sparse` always, specially before
pull requests.

* **Write documentation tests** under the `./test` folder. These are simple
Markdown and Lua files. Lua files are annotated with wax.notes that can be
further converted to online documentation or markdown. Simple tests should
follow the code signatures. Deeper or complicated tests can be added outside
the intended documented tests, i.e. outer of lines between lines started by
`--{` and `--}`. Use `./test/wax/json.lua` as reference.

* **Always test under multiple Lua versions**. Check the main project documentation
to know which Lua versions should be supported.


## Configure your text editor

For C and Lua files our coding style uses:

* `2` spaces for indentation

* `80` column wide

* C curly braces opening `{` should be kept in the line where the expression is
opened, be in function declaratinos or in conditional/loops.

The main reason to adopt this approach is:

* The majority of IDEs support side-by-side edition. Some support even
multiple vertical splits. 80 columns and 2 spaces as indentation give the
reader/developer possibility to improve its work editing a source and its
testings or even reading documentation.

* It widens the device use possibilities, giving accessibility to develop and
and read the code even in mobile (ex: Termux) or older devices.

* It enforces the code simplicity. It is paradoxal, but it keep your code
vertical, at the same time that reinforce the functions to be smaller,
easy to read and simple to understand.
