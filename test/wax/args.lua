-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--[[
Parsing command line arguments
==============================

Suppose you are writing a time tracking app, where you can add tasks you did
with some facilities like task start time and end time. You could call it
from command line as:


```
track.lua --done --start 11:00 --end 14:30 what I did
```

When you call the script, Lua populate te ``arg`` table, setting the index 0
with the name the script and subsequent index with each argument informed to
the script.

You can access each argument accessing the ``arg`` table, but the arguments
can be in different order or you may want to check if has received specific
options with specific values. Also trying to stick with the most common styles
used by command line programs will lead for increased complexity.

To avoid this work and ease further code maintenance, ``wax.waxarg`` brings a
simple and readable way to handle most of the features of the most used
argument parsers for Lua or other parsers.

For the command line above, you could do make it simple as below:
--]]

local wax = require 'wax'
do
  local arg = { '--done','--start','11:00','--end','14:30' }
--{
  local spec = {
    { 'done',  nil, '-' },
    { 'start' },
    { 'end' },
  }

  local options = wax.arg.parse(spec, arg)

  assert(options.done == true)
  assert(options.start == '11:00')
  assert(options['end'] == '14:30')
--}
end

--[[
$ wax.arg.parse(spec:table, arg:table [, argidx:number]) : table | nil, string

The ``spec`` is a table containing a list of rules for options. Each rule also
cconsists in a table with both, a list and an associative part.

```
spec = {
  { longopt:string, shortopt:string, flag:string }, -- this is a rule
  ...
}
```

The first three list items of rule table are the name of the long option,
the name of the short option and a option mode indicator:


The ``longopt`` refers to the name part of an option captured from the
arguments list. If you inform in this field the word ``done``, it will
represent the argument ``--done`` to be captured from cli.

The ``shortopt`` refers to a single character from a-z, A-Z or 0-9. If you
inform in this field the letter ``d``, it will represent the argument ``-d``
to be captured from cli.

The ``flag`` can be:

- ``-`` for switches (captured as boolean).
- ``+`` for options allowed to appear more then once per call.
- ``!`` for mandatory options.

As the ``-`` means the inverse of the default value, it cannot be combined
with ``!`` pr ``+`` as doesn't make sense to have always the opposite to the
default value.

The ``arg``, also a table, is a list with each command line argument, it is
similar to the Lua global variable ``arg``.

The ``argidx`` is optional, being its value equal to 1. You can use this
argument do indicate to the parser the specific index of the ``arg`` from
,which it should starts, for example:

```
track.lua addtask --done --start 11:00 --end 14:30 what I did
```

... could be parsed with:
--]]
do
  local arg = { 'addtask', '--done','--start','11:00','--end','14:30' }
--{
  local spec = {
    { 'done',  nil, '-' },
    { 'start' },
    { 'end' },
  }

  local options = wax.arg.parse(spec, arg, 2)

  assert(options.done == true)
  assert(options.start == '11:00')
  assert(options['end'] == '14:30')
--}
end

do
--[[
The function returns a table populated with its associative part containing
pairs of option/value and its list part containing all remaining non-options.

Short option is a ``-`` followed by a short option character, while long
option is a ``--`` followed by a character from a-z, A-Z or 0-9 followed by
any characters from a-z, A-Z, 0-9 and ``_`` or ``-``. Simple options may be
written directly after the option character or as its next argument. Several
short options can be grouped if none of them or only the last exepects a
value.

Non-options are all arguments that come after the first ``--`` alone, after
an option that do not expects a value (switches) or after the first argument
that comes after an option value.
--]]
--{
  local spec = {
    { 'other',  'o', '+' },
    { 'moon',   'm', '-' },
    { 'mars',   'M', '-' },
    { 'venus',  'v', '-' }
  }
  --all these are parsed the same:
  local cli_calls = {
    { '-mMvosaturn', '-ojupiter', '-o','uranus' },
    { '-Mmv', '-osaturn', '-ojupiter', '-o','uranus' },
    { '-v', '-m', '-M', '--other','saturn', '-o','jupiter', '-ouranus' },
  }
  for _, arg in pairs(cli_calls) do
    local x = wax.arg.parse(spec, arg)
    assert(x.moon == x.mars == x.venus == true)
    assert(x.other[1] == 'saturn')
    assert(x.other[2] == 'jupiter')
    assert(x.other[3] == 'uranus')
  end
--}
end

do
--[[
The spec can also have some more goodies to help on argument parsing.
Until now we only used the first three items of the list part of spec table.
We can also add some more specific details to the spec argument:
--]]
--{
  local spec = {
    { 'equipment', 'e', '!',
      desc = 'Kind of equipment for observation',
    },
    { 'type', 't',
      default = {'refractor', 'reflector'},
      desc = 'light handling scheme',
    },
    { 'mount', 'm',
      default = {'equatorial', 'altazimuthal', 'dobsonian', 'none'},
      desc = 'kind of mounting used for sky navigation',
    },
    { 'zoom', 'z',
      default = function(_, t) return t and tonumber(t) or 100 end,
      desc = 'zoom level at the observation',
    },
    { 'aperture', 'a',
      default = {'50', '60', '120'},
    },
    { 'with-finder', 'f', '-',
      default = false,
      desc = 'used when the telescope model comes with a finder'
    }
  }
--}

--[[
The ``default`` spec field says which value should be used when the option is
ommited:

* If a boolean false (or nil) is used in a rule with the switch flag ``-``
  the use of the option will lead to true. For any other value on a switch,
  resulting value will be false.

* If a string is used, it will be used as is when the option is not given
  at argument list.

* If a function is used, it will receive the option table parsed until then as
  the first argument and its return will be used as default value.

* If a list (table) is used, the option only will accept one of the items
  in this list and, in the absence of option between arguments will lead
  to the last list item be used as default.

Considering the last ``spec`` above, we have as example:
--]]
  do
  --{
    local args = { '-e','Telescope','-t','reflector', '-f' }
    local opt = wax.arg.parse(spec,args)

    assert(opt.equipment == 'Telescope')
    assert(opt.type == 'reflector')
    assert(opt.mount == 'none')
    assert(opt.zoom == 100)
    assert(opt.aperture == '120')
    assert(opt['with-finder'] == true)
  --}
  end
--| The following lead to an error because we give a value that is not in the
--| set:
  do
  --{
    local args = { '-e','Telescope','-t','ccd' }
    local opt, err = wax.arg.parse(spec, args)
    assert(not opt and err)
  --}
  end
--[[
The ``desc`` spec field is used to give a short description about the purpose of
the option. See `wax.arg.help` for more.

$ wax.arg.help(spec:table, [out:file]) : nil

--]]
wax.arg.help(spec)

end
