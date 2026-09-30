local Luau = require("@std/luau")
local Parser = require("@std/syntax/parser")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local RemoveTypes = require("@src/transformers/remove_types")

local cases: { { name: string, source: string, unchanged: boolean? } } = {
	{ name = "untyped source", source = "-- keep this comment\nlocal x = ':: <T>'\nreturn x", unchanged = true },
	{ name = "empty source", source = "", unchanged = true },
	{ name = "comments only", source = "--!strict\n-- comment\n", unchanged = true },
	{ name = "local annotations", source = "local x: number, y: string = 1, 'a' return x, y" },
	{ name = "uninitialized local", source = "local x: number? return x" },
	{ name = "simple assertion", source = "return 1 :: number" },
	{ name = "nested assertions", source = "return ((1 :: number) :: any) :: unknown" },
	{ name = "number next to concatenation", source = "return 1::number..'x'" },
	{ name = "adjacent statements", source = "local x=1::number local y=2::number return x+y" },
	{ name = "asserted function", source = "return (function(x: number): number return x :: number end :: any)(3)" },
	{ name = "asserted generic function", source = "return (function<T>(x: T): T return x end :: any)(3)" },
	{ name = "asserted table", source = "return ({x = 1 :: number} :: {x: number}).x" },
	{ name = "assertion inside interpolation", source = "return `value {1 :: number}`" },
	{ name = "asserted interpolation", source = "return `value {1 :: number}` :: string" },
	{ name = "assertion before line comment", source = "return 1 :: number -- trailing comment\n" },
	{ name = "assertion after line comment", source = "return 1 -- operand comment\n:: number" },
	{ name = "leading comment", source = "return -- operand comment\n1 :: number" },
	{ name = "call assertion returns one value", source = "local function f() return 1, 2 end return f() :: number" },
	{ name = "vararg assertion returns one value", source = "local function f(...) return ... :: number end return f(1, 2)" },
	{ name = "call assertion in argument", source = "local function f() return 1, 2 end return select('#', f() :: number)" },
	{ name = "call assertion in table", source = "local function f() return 1, 2 end return #{f() :: number}" },
	{ name = "fixed return pack", source = "local function f(): (number, string) return 1, 'a' end return f()" },
	{ name = "empty return pack", source = "local function f(): () end return f()" },
	{ name = "variadic return pack", source = "local function f(): ...number return 1, 2 end return f()" },
	{ name = "variadic annotation", source = "local function f(...: number): number return select('#', ...) end return f(1, 2)" },
	{ name = "generic parameter", source = "local function f<T>(x: T): T return x end return f(3)" },
	{ name = "multiple generic parameters", source = "local function f<T, U>(x: T, y: U): (T, U) return x, y end return f(1, 'a')" },
	{ name = "generic pack", source = "local function f<T...>(...: T...): T... return ... end return f(1, 'a')" },
	{ name = "mixed generic return pack", source = "local function f<T, U...>(x: T, ...: U...): (T, U...) return x, ... end return f(1, 'a')" },
	{ name = "multiple generic packs", source = "local function f<T..., U...>(...: T...): T... return ... end return f(1, 2)" },
	{ name = "anonymous generic function", source = "local f = function<T...>(...: T...): T... return ... end return f(1, 2)" },
	{ name = "method annotations", source = "local t = {} function t:f<T>(x: T): T return x end return t:f(1)" },
	{ name = "numeric for annotation", source = "local n=0 for i: number = 1, 3 do n+=i end return n" },
	{ name = "for-in annotations", source = "local n=0 for k: number, v: number in {1, 2} do n+=k*v end return n" },
	{ name = "type alias", source = "type T = number local x: T = 1 return x" },
	{ name = "exported generic type alias", source = "export type T<U, V...> = (U, V...) -> U return 1" },
	{ name = "type function", source = "type function identity(t) return t end return 1" },
	{ name = "exported type function", source = "export type function identity(t) return t end return 1" },
	{ name = "type function with nested annotations", source = "type function identity(t) local x: any = t :: any return x end return 1" },
	{ name = "only type declarations", source = "type T = number; type function identity(t) return t end;" },
	{ name = "typeof with nested edits", source = "local x: typeof(function<T>(x: T): T return x :: T end) = 1 return x" },
	{ name = "explicit instantiation", source = "local function f<T>(x: T): T return x end return f<<number>>(1)" },
	{ name = "instantiation inside assertion", source = "local function f<T>(x: T): T return x end return (f<<number>> :: any)(1)" },
	{ name = "assertion inside instantiation", source = "local function f<T>(x: T): T return x end return f<<typeof(1 :: number)>>(1)" },
	{ name = "instantiation preserves multiple returns", source = "local function f<T...>(...: T...): T... return ... end return f<<number, string>>(1, 'a')" },
	{ name = "declaration between calls", source = "local f=function()return function()end end local x=f() type T=number (f)() return type(x)" },
	{ name = "assertion between calls", source = "local f=function()return function()end end local x=f()::any (f)() return type(x)" },
	{ name = "separator after number", source = "local n=0 local function f() n+=1 end local x=1::number (f)() return x,n" },
	{ name = "existing separator", source = "local n=0 local function f() n+=1 end local x=1; type T=number; (f)() return x,n" },
	{ name = "deleted declarations at block start", source = "local n=0 local function f() n+=1 end do type T=number (f)() end return n" },
	{ name = "nested block separator", source = "local n=0 local function f() n+=1 end do local x=1 type T=number type U=string (f)() end return n" },
	{ name = "separator before comment", source = "local n=0 local function f() n+=1 end local x=1 -- keep\ntype T=number\n(f)() return x,n" },
	{ name = "unicode and CRLF", source = "-- 한글\r\nlocal s='한글';local x:number=1::number\r\nreturn s,x\r\n" },
	{ name = "multiline types", source = "local x:\n{\nvalue: number\n} = {value=1}\nreturn x.value ::\nnumber\n" },
	{ name = "multiline generic pack", source = "local function f<\nT,\nU...\n>(x: T, ...: U...): (\nT,\nU...\n) return x, ... end\nreturn f(1,2)" },
}

local function transform(source: string): string
	return RemoveTypes.transform({
		path = "test.luau",
		source = source,
		parseresult = Parser.parse(source),
		options = {},
	}) :: string
end

local function newlineSequence(source: string): string
	return (string.gsub(source, "[^\r\n]", ""))
end

local failures = 0
for _, case in cases do
	local ok, message = pcall(function()
		local original = Luau.load(Luau.compile(case.source), case.name .. " input")
		local output = transform(case.source)
		local parsed = Parser.parse(output)
		local transformed = Luau.load(Luau.compile(output), case.name .. " output")
		assert(transform(output) == output, "transformation is not idempotent")
		assert(newlineSequence(output) == newlineSequence(case.source), "line endings changed")
		if case.unchanged then
			assert(output == case.source, "untyped source changed")
		end

		Query.findAllFromRoot(parsed, function(node)
			assert(not Utils.isType(node) and not Utils.isTypePack(node), "type annotation remains")
			assert(not Utils.isStatTypeAlias(node) and not Utils.isStatTypeFunction(node), "type declaration remains")
			assert(not Utils.isExprTypeAssertion(node) and not Utils.isExprInstantiate(node), "type expression remains")
			local func = Utils.isExprFunction(node)
			if func then
				assert(not func.openGenerics and not func.closeGenerics, "generic parameters remain")
			end
			return nil
		end)

		local expected = table.pack(original())
		local actual = table.pack(transformed())
		assert(actual.n == expected.n, `return count changed: {expected.n} -> {actual.n}`)
		for i = 1, expected.n do
			assert(actual[i] == expected[i], `return value {i} changed`)
		end
	end)
	if not ok then
		failures += 1
		print(`FAIL: {case.name}\n{message}`)
	end
end

assert(failures == 0, `{failures}/{#cases} remove_types tests failed`)
print(`Passed {#cases} remove_types tests`)
