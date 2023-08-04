--[[
$ a = string
$ a = name:string | age:number

$ a = (string,number) -> (string)

$ a = ( (string, number) -> (number) , bool) -> (string)

--         |          |
//$ a = { name:string, age:number }
//$ a = (name:string, age:number -> able:bool)

--$ error = string number


--$ a = { name:string, age:number }
--$ a = { name:@sref,  age:@nref }
--$ a = ( name:a, age:n -> id:n }
--$ a = "hi" | 10
--$ a = ( name:string -> id:n ) | { id: n }
--$ a = @sref | @nref
--$ a = ( fn:(a ->a), n:a )




-- KIND FILE
mod.ex = 's'
mod.ax = 'n'
mod.person = { 't', name = 's', age = 'n' }
mod.set    = { '(s,a)(a)' }
mod.apply  = { '(s,(s)(s))(s)' }


function(a) return function(b,c) end
--]]
