--| # wax.template - Simple Lua embedded strings

--| ## Basic usage
do
--{ Suppose you have the following code:

local template = require "wax.template"

local revolutions = {
  {name = 'Mars',    days=687},
  {name = 'Jupiter', days=4333},
  {name = 'Saturn',  days=10759}
}
--}

--| The most basic usage consists in replacing the template fields by its
--| variable names, i.e, replacing the contents between `{{` and `}}` by its
--| Lua value:
--{
local str = {}
for _,v in ipairs(revolutions) do
  str[#str+1] = template.format('{{data.name}} year lasts {{data.days}} Earth days.',v)
end

assert(table.concat(str,'\n') == [[
Mars year lasts 687 Earth days.
Jupiter year lasts 4333 Earth days.
Saturn year lasts 10759 Earth days.]])
--}

--| You can use all Lua values inside the template fields, even the return of
--| function calls. A subset of Lua standard library can be used to process the
--| field values as seen below:
--{
local str = {}
for _,v in ipairs(revolutions) do
  str[#str+1] = template.format(
    '{{data.name:upper()}} year = {{string.format("%.1f",(data.days / 365))}} Earth year.'
    ,v
  )
end

assert(table.concat(str,'\n') == [[
MARS year = 1.9 Earth year.
JUPITER year = 11.9 Earth year.
SATURN year = 29.5 Earth year.]])
--}
--| Most of time may be better choose a simple `string.format` call.
--| The basic usage of `wax.template` shines when you need transformations
--| on data like math, table handling or string transformations or a great
--| set of values that could make a `string.format` seems complex or difficult
--| to understand.
end


--| ## Lua as template
do
--| Sometimes you may prefer to think in terms of "text processing" instead of
--| string concatenation. This template module allows you to use the Lua
--| simple block comments as template and replace it according the Lua logic.
--{
local template = require "wax.template"

local revolutions = {
  {name = 'Mars',    days=687},
  {name = 'Jupiter', days=4333},
  {name = 'Saturn',  days=10759}
}

local res, err = template.format([=[
]] for i,v in ipairs(data) do --[[
  {{ i }}. {{ v.name }} revolves around the Sun in {{ v.days }} Earth days,
  (near {{ ('%.2f'):format(v.days/365.26) }} years).
]]
end]=], revolutions)

assert(res == [[
  1. Mars revolves around the Sun in 687 Earth days,
  (near 1.88 years).
  2. Jupiter revolves around the Sun in 4333 Earth days,
  (near 11.86 years).
  3. Saturn revolves around the Sun in 10759 Earth days,
  (near 29.46 years).
]])

--}
--| It is a simple way to do the things quickly, but as your template complexity
--| grows you should prefer to use a template file when possible.
end


--| ## Backfilters
do
--| When using templates is easy to be trapped into distortions due to some kind
--| of identation, or incur ugly strategies to make text correct aligned.
--| To cope with this, use template backfilters `**`, `*`, `++` and `+`
--{
local template = require "wax.template"

-- Default behavior without backfilter: preserve and breaklines and spaces
local res_default = template.format([[
XX
  {{data}}]], 'hi')

assert(res_default == [[
XX
  hi]])

--| Using `**` strips previous white spaces or line breaks
local greedy = template.format([[
XX
  {{**data}}]],'hi')
assert(greedy == 'XXhi')

--| Using `*` replaces previous white spaces and line breaks
--| by a single white space
local elegantgreedy = template.format([[
XX
  {{*data}}]],'hi')
assert(elegantgreedy == 'XX hi')

--| Using `++` strips any previous white spaces
local leftist1 = template.format([[
XX
  {{++data}}]],'hi')
assert(leftist1 == [[XX
hi]])

leftist2 = template.format([[
XX                 {{++data}}]],'hi')
assert(leftist2 == [[XXhi]])

--| * `+` strips all previous spaces on the line if there is no other
--| word before. If there is a word, replace all spaces by a single one.
normalizer1 = template.format([[
XX                 {{+data}}]],'hi')
assert(normalizer1 == [[XX hi]])

normalizer2 = template.format([[
                 {{+data}}]],'hi')
assert(normalizer2 == [[hi]])

--}
end

--| ## Using files as templates
--| There are many benefits, as your project grows, of having your templates
--| in separated files.
--|
--| You can take full benefit of this using plain Lua files as templates. To do
--| this you use the `template.loadfile` function instead `template.load`
--| or `template.format`.
--|
--| There is a single difference between when you directly use a string from
--| when you use a template file.
--|
--| Template strings as in `template.format` or `template.load` expects the
--| template starts directly _inside_ a Lua comment:
--|
--| Example 1:
--| ```
--| {{data.title}}: ]] for i, v in ipairs (data.list) do --[[ {{v}},]] end
--| ```
--| Example 2:
--| ```
--| ]] for key, val in pairs(data) do --[[
--|  {{key}} = {{value}}
--| ]] end
--| ```
--|
--| But template files, as used in `template.loadfile`, expects the template
--| starts directly in a Lua expression:
--|
--| Example 1:
--| ```lua
--| --[[{{data.title}}: ]] for i,v in ipairs(data.list) do --[[ {{v}},]] end
--| ```
--| Example 2:
--| ```lua
--| for key, val in pairs(data) do
--|   --[[ {{key}} = {{value}} ]]
--| end
--| ```
--|
--| The main reasons for this implementation choice is:
--| * most of time when `template.format` or `template.load` are used, you will
--|   be using the code mixed with the application logic, and you will be doing
--|   smaller replacements without too much Lua code on templates.
--| * when using a file for templates, you will need no other syntax than Lua,
--|   and starting a file this way allows you to have syntax checkers, editors,
--|   etc. working out of the box.
--|

--| ## Advanced usage
do

--| There is specific scenarios where you want to reuse the same template with
--| different data, or having more control about the environment used by
--| template as custom functions etc.
--|
--| This control is achieved separating the moment of template parsing, from the
--| environment assignment and finally the assembly with data through the
--| `:format` function.
--{

local template = require "wax.template"

local bookChapters = {
  { name = 'Tripping to Proxima Centauri' },
  { name = 'Has Great Attractor a Black Hole?' },
  { name = 'To the Shapley Cluster and Beyond' }
}

-- Create a template instance from a string
tpl = template.load[=[
Index
=====
]] for n, chapter in ipairs(data) do --[[
  * [{{chapter.name}}]({{slugify(chapter.name)}}.md)
]] end ]=]

-- Inject on template environment the 'slugify' as a function
tpl:assign('slugify',function(s) return string.lower(s):gsub('%W','-') end)

local res = tpl(bookChapters)
assert(res == [[
Index
=====
  * [Tripping to Proxima Centauri](tripping-to-proxima-centauri.md)
  * [Has Great Attractor a Black Hole?](has-great-attractor-a-black-hole-.md)
  * [To the Shapley Cluster and Beyond](to-the-shapley-cluster-and-beyond.md)
]])

--}
end
--| ### Observations
--| * Once you load a template, you can have multiple calls with it.
--| * You can write your own transformation functions inside the template,
--|   according to your needs.
--| * Your template is always a valid Lua code
--| * A valid Lua code is not always a valid template as only a subset of
--|   Lua standard library is enabled by default under template environment:
--|   - all table library functions
--|   - all string library functions
--|   - all math library functions
--|   - also the global functions `pairs``,``ipairs`,`next`,`tonumber`,
--|   `tostring`,`type and `error`.

local template = require "wax.template"
local luaver = tonumber(({_VERSION:gmatch('(%d+%.%d+)$')()})[1])

--| ## Scoping
do
--| Template is sandboxed. It can't see the outer environment neither change it
--| as confirmed by tests below:

--| 1. There is no `_G` (table representing global values) inside the template
--| environment. For Lua 5.2+, the `_ENV` contains only the assigned data.

  if luaver >= 5.2 then
    local res = template.format[=[{{type(_G)}}/{{type(_ENV)}}/{{type(_ENV.data)}}]=]
    assert(res == 'nil/table/table')
  end

  if luaver == 5.1 then
    local res = template.format'{{ type(_G) }}/{{ type(_ENV) }}'
    assert(res == 'nil/nil')
  end


--| 2. Variables declared inside template without the `local` keyword do not
--| affect the outer template scope.
  local scopex = (template.format']] somevar="x" --[[{{somevar}}')
  assert(scopex == "x")
  assert(somevar == nil)
--}
end

--| ## Functions

--$ wax.template.format(t: string, data: any) : string
--| Uses the string `t` as  template to apply the values contained in `data`.
--| Only the default `wax.template` subset of Lua functions are allowed.
do
--{
assert(template.format([[{{data}}]],'hello') == 'hello')
assert(template.format([[{{data.value}}]],{value="hello"}) == 'hello')

local value='hello'
assert(template.format([[{{data()}}]],function() return value end) == 'hello')
--}
end


--$ wax.template.load(tplstr: string) : WaxTemplate
--| Create a `WaxTemplate` instance from the `tplstr` string argument.
do
--{

--}
end


--$ wax.template.loadfile(filename: string): WaxTemplate
--| Create a `WaxTemplate` instance from the string contents of `filename`.
do
--| See the section "Template files" above to know the differences from
--| template strings.
templatefile = require 'wax.fs'.getcwd()..'/etc/example/template.lua'
--{
local tpl = template.loadfile(templatefile)
assert( tpl({'Tupã'}) == 'hello!\nTupã is a star on Crux' )
assert( tpl({'Antares'}) == 'hello!\nAntares was not found in data' )
--}
end


--| ## Class `WaxTemplate`

--$ WaxTemplate:assign(module: table)
--| Takes the keys of the table parameter and adds to the environment.
--| These values can be used accross template calls under the same instance.
do
--{
local tpl = template.load[[The {{what}} {{thing}} in {{data[1]}} is {{top}} {{data[2]}}]]
tpl:assign({ what='brightest', thing = 'star', top = 'alpha'})
assert(tpl({'Virgo','Virginis'})
  == 'The brightest star in Virgo is alpha Virginis')
assert(tpl({'Crux','Crucis'})
  == 'The brightest star in Crux is alpha Crucis')
--}
end


--$ WaxTemplate:assign(name: string, value:)
--| Assigns a `value` to the template environment `name` accross calls.
do
--{
local tpl = template.load[[This is {{what}} {{data}}]]
tpl:assign('what', 'alpha')
assert(tpl('Virginis') == 'This is alpha Virginis')
assert(tpl('Crucis') == 'This is alpha Crucis')
--}
end


--$ WaxTemplate(data: string) : string
--| Apply the data values on template represented by the WaxTemplate instance,
--| and fetches the resulting string. See above examples for `template.load`
--| and `template.loadfile`
