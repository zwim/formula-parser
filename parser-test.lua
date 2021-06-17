--[[
    Testsuite for parser.lua

    Author: Martin Zwicknagl
    Version: 0.9.0
]]

-- number of passes
local passes = 32 -- set this for benchmark
local repetitions = 32 -- how thorogh the test is
math.randomseed(os.clock())

local Parser = require("formulaparser")
local ParserHelp = require("parserhelp")

print("This is a test for formulaparser.lua")

local test_counter = 0
local function Assert(a, b)
    test_counter = test_counter + 1
    assert(a, b, " " .. tostring(a) .. "    " .. tostring(b))
end


print("Help")
print(tostring(Parser:eval("help()")))

local greek_alphabet = "α β γ δ ε ζ η ϑ ι ϰ λ μ ν ξ π ρ σ τ φ χ ψ ω Σ"
local greek_alphabet_in_text = "alpha beta gamma delta epsilon zeta eta thita iota kappa lambda my ny xi pi rho sigma tau phi chi psi omega Sigma"

print("THE ANSWER: " .. Parser:eval("ans") .. "\n")
Assert(Parser:eval("ans") == 42)

Assert(greek_alphabet_in_text == Parser:greek2text(greek_alphabet))
Assert(greek_alphabet == Parser:text2greek(greek_alphabet_in_text))

------------------------------
local NAN = 0.0 / 0.0
local NINF = -math.huge
local PINF = math.huge
function math.finite(value)
    if type(value) == "string" then
        value = tonumber(value)
        if value == nil then return nil end
    elseif type(value) ~= "number" then
        return nil
    end
    return value > NINF and value < PINF
end

local function rnd(range)
    if not range then range = 1e7 end
    return math.random(range)
end

local function genVal(numer)
    if not numer then
        local l = rnd(10) >= 5
        return tostring(l), tostring(l) -- return boolean
    end
    local nachkomma = 7
    local r = rnd(100)
    local vorz = rnd(1)
    local val = rnd() % 10000000
    if rnd(1) == 0 then
        val = val + rnd(10 ^ nachkomma) / 10 ^ nachkomma
    end
    if r < 80 then
        return "" .. val, val
    elseif r < 70 then
        if vorz == 0 then
            val = -val
        end
        return string.format("%e", val), string.format("%e", val)
    elseif r < 80 then
        if vorz == 0 then
            return "e", "math.exp(1)"
        else
            return "-e", "-math.exp(1)"
        end
    elseif r < 90 then
        if vorz == 0 then
            return "pi", "math.pi"
        else
            return "-pi", "-math.pi"
        end
    elseif r < 95 then
        if vorz == 0 then
            return "π", "math.pi"
        else
            return "-π", "-math.pi"
        end
    else
        return "", ""
    end
    return "0", "0"
end

local function my_Assert(a, b)
    local expected, result, err
    local lua_fun = loadstring("function() return " .. b .. " end")
    --      print(a)
    expected = lua_fun and pcall(lua_fun())
    result, err = Parser:eval(a)
    if math.finite(expected) and math.finite(result) then
        if type(result) == "number" and type(expected) == "number" then
            Assert(math.abs(result - expected) /
                       ((expected == 0) and 1 or expected) < 1e-15,
                   string.format("%s  err:%s   %.20f==%.20f diff=%E\n", a,
                                 tostring(err), result, expected,
                                 result - expected))
        elseif result == nil and expected == nil then
            Assert(result == expected,
                   string.format("%s  err:%s   %s==%s\n", a, tostring(err),
                                 tostring(result), tostring(expected)))
        else
            print("????")
        end
    end
end

local function optest(values, op1, op2)
    local a, b, x, y

    -- a is for parser, b is for loadstring

    if values == 1 then -- numbers
        a, b = genVal(10)
        x, y = genVal(10)
    elseif values == 0 then -- boolean
        a, b = genVal()
        x, y = genVal()
    else
        if rnd(2) == 1 then -- mixed
            a, b = genVal()
            x, y = genVal(10)
        else
            a, b = genVal(10)
            x, y = genVal(0)
        end
    end
    a = a .. op1 .. x
    if op1 == "!=" then op1 = "~=" end
    b = "" .. b .. op1 .. y

    if rnd(2) == 1 then
        a = "(" .. a .. ")"
        b = "(" .. b .. ")"
    end

    if op2 then
        x, y = genVal(10)
        a = a .. op2 .. x
        if op2 == "!=" then op2 = "~=" end
        b = "" .. b .. op2 .. y
    end

    if rnd(5) == 1 then
        a = "(" .. a .. ")"
        b = "(" .. b .. ")"
    end

   my_Assert(a, b)
end

local function rep_optest(a, b, c, d)
    for _ = 1, d or 100 do optest(a, b, c) end
end

local function functest1(values, op, func)
    local a, b, x, y
    -- a is for parser, b is for loadstring
    if values == 1 then -- numbers
        a, b = genVal(10)
        x, y = genVal(10)
    elseif values == 0 then -- boolean
        a, b = genVal()
        x, y = genVal()
    else
        if rnd(2) == 1 then -- mixed
            a, b = genVal()
            x, y = genVal(10)
        else
            a, b = genVal(10)
            x, y = genVal(0)
        end
    end

    local aa, bb
    -- e.g. 3*sin(5)
    aa=        a .. op .. func .. x .. ")"
    bb = "" .. b .. op .. func .. y .. ")"
    my_Assert(aa, bb)

    -- e.g. 3*sin(5)
    aa =       func .. a .. op .. x .. ")"
    bb = "" .. func .. b .. op .. y .. ")"
    my_Assert(aa, bb)
end
---------------------------------

for number = 0, passes do

    if number % 10 == 0 then print("Test run: " .. number) end

    --  print("numbers")
    Assert(Parser:eval("0") == 0)
    Assert(Parser:eval("pi") == math.pi)
    Assert(Parser:eval("exp(1)") == math.exp(1))

    Assert(Parser:eval("123") == 123)
    Assert(Parser:eval("-123") == -123)
    Assert(Parser:eval("1E12") == 1e12)
    Assert(Parser:eval("-12E34") == -12e34)
    Assert(Parser:eval("1E-12") == 1e-12)
    Assert(Parser:eval("-1E-12") == -1e-12)

    --  print("operators")
    Assert(Parser:eval("1+2") == 1 + 2)
    Assert(Parser:eval("1-2") == 1 - 2)
    Assert(Parser:eval("3*2") == 3 * 2)
    Assert(Parser:eval("3/2") == 3 / 2)
    Assert(Parser:eval("7%2") == 7 % 2)
    Assert(Parser:eval("3^2") == 3 ^ 2)
    Assert(Parser:eval("5!") == 120)
    Assert(Parser:eval("e^5") == math.exp(1) ^ 5)
    Assert(Parser:eval("3*pi") == 3 * math.pi)
    Assert(Parser:eval("3pi") == 3 * math.pi)
    Assert(Parser:eval("-4pi") == -4 * math.pi)
    Assert(Parser:eval("false || false") == false)
    Assert(Parser:eval("true  || false") == true)
    Assert(Parser:eval("false || true") == true)
    Assert(Parser:eval("true  || true") == true)
    Assert(Parser:eval("3 || false") == 3)
    Assert(Parser:eval("3 || 7") == 3)
    Assert(Parser:eval("false || 7") == 7)
    Assert(Parser:eval("false && false") == false)
    Assert(Parser:eval("true  && false") == false)
    Assert(Parser:eval("false && true") == false)
    Assert(Parser:eval("true  && true") == true)
    Assert(Parser:eval("2  && true") == true)
    Assert(Parser:eval("2  && 7") == 7)
    Assert(Parser:eval("false  && 7") == false)
    Assert(Parser:eval("false ## false") == true)
    Assert(Parser:eval("true  ## false") == true)
    Assert(Parser:eval("false ## true") == true)
    Assert(Parser:eval("true  ## true") == false)
    Assert(Parser:eval("true  ## true") == false)
    Assert(Parser:eval("##true") == false)
    Assert(Parser:eval("##false") == true)
    Assert(Parser:eval("##8") == false)
    Assert(Parser:eval("##0") == false)
    Assert(Parser:eval("2>0") == true)
    Assert(Parser:eval("5>5") == false)
    Assert(Parser:eval("5>=5") == true)
    Assert(Parser:eval("5==5") == true)
    Assert(Parser:eval("true==true") == true)
    Assert(Parser:eval("true==false") == false)
    Assert(Parser:eval("false==true") == false)
    Assert(Parser:eval("false==false") == true)
    Assert(Parser:eval("4<10") == true)
    Assert(Parser:eval("4<=10") == true)
    Assert(Parser:eval("4<=1") == false)
    Assert(Parser:eval("5!=5") == false)
    Assert(Parser:eval("true!=true") == false)
    Assert(Parser:eval("true!=false") == true)
    Assert(Parser:eval("false!=true") == true)
    Assert(Parser:eval("false!=false") == false)
    Assert(Parser:eval("7 | 8") == 15)
    Assert(Parser:eval("7 & 8") == 0)
    Assert(Parser:eval("7 # 8") == -1)
    Assert(Parser:eval("3 ~ 5") == 6)
    Assert(Parser:eval("#8") == -9)

    Assert(Parser:eval("265/5/8") == 265 / 5 / 8)

    Assert(Parser:eval("2^1^3") == (2 ^ 1) ^ 3)
    Assert(Parser:eval("2/3*5") == 2 / 3 * 5)

    Assert(Parser:eval("123+4*6") == 123 + 4 * 6)
    Assert(Parser:eval("4*6+123") == 4 * 6 + 123)

    Assert(Parser:eval("(3*8)-7") == (3 * 8) - 7)
    Assert(Parser:eval("3*(8-7)") == 3 * (8 - 7))
    Assert(Parser:eval("(8-7)*3") == (8 - 7) * 3)
    Assert(Parser:eval("-(-8-7)*3") == -(-8 - 7) * 3)
    Assert(Parser:eval("-(-8-7)*(3)") == -(-8 - 7) * (3))
    Assert(Parser:eval("(8-7)*pi") == (8 - 7) * math.pi)

    Assert(Parser:eval("(8e5-7)*3e-4") == (8e5 - 7) * 3e-4)
    Assert(Parser:eval("(8+e-7)*3") == (8 + math.exp(1) - 7) * 3)
    Assert(Parser:eval("(-8e5-7)%3e-4") == (-8e5 - 7) % 3e-4)

    Assert(Parser:eval("3!+4") == 10)
    Assert(Parser:eval("-e*2") == -math.exp(1) * 2)

    Assert(Parser:eval("4 || false || 5") == 4)
    Assert(Parser:eval("4 && 1 && 5") == 5)

    Assert(Parser:eval("(-pi)&&(+pi)") == math.pi)
    Assert(Parser:eval("-pi<=e") == true)

    Assert(Parser:eval("4<4 || 4==4") == true)
    Assert(Parser:eval("4<4 && 4==4") == false)
    Assert(Parser:eval("4<4 && 4>=4") == false)
    Assert(Parser:eval("4<4 ## 4>=4") == true)

    --  print("functions")
    Assert(Parser:eval("abs(-4.5)") == 4.5)
    Assert(Parser:eval("floor(5.9)") == 5)
    Assert(Parser:eval("round(5.9)") == 6)
    Assert(Parser:eval("sqrt(100)") == 10)
    Assert(Parser:eval("√(100)") == 10)
    Assert(Parser:eval("ld(1024)") == 10)
    Assert(Parser:eval("ln(e)") == 1)
    Assert(Parser:eval("log(0.001)") == -3)

    --  print("angle func")
    Parser:eval("setrad()")

    Assert(Parser:eval("sin(3*pi)") == 0)
    my_Assert("asin(0.3)", "math.asin(0.3)")
    Assert(Parser:eval("cos(0.3)") == math.cos(0.3))
    Assert(Parser:eval("acos(0.3)") == math.acos(0.3))
    my_Assert("tan(0.3)", "math.tan(0.3)")
    Assert(Parser:eval("tan(3*pi)") == 0)
    my_Assert("atan(0.3)", "math.atan(0.3)")

    Assert(Parser:eval("asin(sin(3*pi))") == 0)
    Assert(Parser:eval("acos(cos(3*pi))") == math.pi)
    Assert(Parser:eval("atan(tan(3*pi))") == 0)
    Assert(Parser:eval("asin(sin(pi/2))") == math.pi/2)

    Parser:eval("setdeg()")
    Assert(Parser:eval("sin(0)") == 0)
    Assert(Parser:eval("sin(90)") == 1)
    Assert(Parser:eval("sin(180)") == 0)
    Assert(Parser:eval("sin(270)") == -1)
    Assert(Parser:eval("sin(90)") == math.sin(90 * math.pi / 180))
    Assert(Parser:eval("asin(1)") == 90)
    Assert(Parser:eval("cos(0)") == 1)
    Assert(Parser:eval("cos(90)") == 0)
    Assert(Parser:eval("cos(180)") == -1)
    Assert(Parser:eval("cos(270)") == 0)
    Assert(Parser:eval("acos(0)") == 90)
    Assert(Parser:eval("acos(-1)") == 180)
    assert(Parser:eval("tan(0)") == 0)
    assert(Parser:eval("tan(90)") ~= 0/0)
    assert(Parser:eval("tan(180)") == 0)
    assert(Parser:eval("tan(270)") ~= 0/0)
    assert(Parser:eval("tan(360)") == 0)
    assert(Parser:eval("tan(-45)") == -1)
    assert(Parser:eval("tan(45)") == 1)

    my_Assert("tan(45)", "math.tan(math.pi / 4)")
    Assert(Parser:eval("atan(1)") == 45)
    Assert(Parser:eval("atan(0.3)") == math.atan(0.3) / math.pi * 180)

    my_Assert("asin(sin(45))", "math.asin(math.sin(math.pi / 4)) * 180 / math.pi")
    Assert(Parser:eval("acos(cos(0))") == math.acos(math.cos(0)))
    my_Assert("atan(tan(0.1))", "math.atan(math.tan(0.1))")

    --  print("other random test")
    Assert(Parser:eval("abs(-5)*abs(6)+77") == math.abs(-5) * math.abs(6) + 77)

    Assert(Parser:eval("floor(23.3*4.7)-2") == math.floor(23.3 * 4.7) - 2)
    Assert(Parser:eval("round(23.3*4.7)") == math.floor(23.3 * 4.7 + 0.5))

    Parser:eval("randseed(1)")
    Assert(Parser:eval("rnd(12)") <= 12)

    Assert(Parser:eval("log(1e-4)") == -4)

    --  print("store tests")

    Assert(Parser:eval("x=1+2") == 3)
    Assert(Parser:eval("x") == 3)

    Parser:eval("x=1+2")
    Assert(Parser:eval("x=20+x") == 23)
    Assert(Parser:eval("x") == 23)

    Parser:eval("test=" .. number)
    Assert(Parser:eval("20+test") == 20 + number)

    Parser:eval("x=y=12")
    Assert(Parser:eval("x") == 12)
    Assert(Parser:eval("y") == 12)

    Parser:eval("x=3+(y=-3)")
    Assert(Parser:eval("y") == -3)
    Assert(Parser:eval("x") == 3 - 3)

    Assert(Parser:eval("kill(x)") == true)
    Assert(Parser:eval("kill()") == true)
    Assert(Parser:eval("kill(y)") == false)

    Parser:eval("kill(x)")
    Parser:eval("x:=1+2")
    Assert(Parser:eval("y:=20+x") == 23)

    Assert(Parser:eval("x+=5+5") == 13)
    Assert(Parser:eval("x-=20") == 13 - 20)
    Parser:eval("x:=10")
    Assert(Parser:eval("x*=5") == 50)
    Assert(Parser:eval("x/=10") == 5)
    Assert(Parser:eval("x%=4") == 1)

    --  print("sequential")
    Assert(Parser:eval("3,4") == 4)
    Assert(Parser:eval("1*2,3*5") == 15)
    Assert(Parser:eval("(1+2),(3*5)") == 15)
    Assert(Parser:eval("x=3,y=-12") == -12)
    Assert(Parser:eval("x") == 3)
    Assert(Parser:eval("y") == -12)

    --  print("ternary op")
    Assert(Parser:eval("true?5:-5") == 5, Parser:eval("true?5:-5"))
    Assert(Parser:eval("false?5:-5") == -5)

    Assert(Parser:eval("3<3?5:-5") == -5)

    Assert(Parser:eval("x=3") == 3)
    Assert(Parser:eval("x?pi:e") == math.pi)
    Assert(Parser:eval("x-=3") == 0)
    Assert(Parser:eval("x!=0?pi:e") == math.exp(1))

    Assert(Parser:eval("2>0?2:-2") == 2)
    Assert(Parser:eval("2<0?2:-2") == -2)

    Assert(Parser:eval("x=3") == 3)
    Assert(Parser:eval("x>0?x:-x") == 3)
    Assert(Parser:eval("x<=0?x:-x") == -3)

    Assert(Parser:eval("2>4?3:4") == 4)

    Parser:eval("x=10")
    Assert(Parser:eval("x=x==0?pi:e") == math.exp(1))
    Assert(Parser:eval("x") == math.exp(1))

    Assert(Parser:eval("2ld(1024)") == 20)
    Assert(Parser:eval("2pi") == 2 * math.pi)
    Assert(Parser:eval("2(pi)") == 2 * math.pi)

    Assert(Parser:eval("kill()") == true)

    --  print("check for wrong input")
    local val, err

    val, err = Parser:eval("")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("z")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3-")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("*4)")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("2*)")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("2+3)")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("(3*2")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("*pi")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("sin(x")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3!*+4")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4-)")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4))")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4+(8)))")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("1*sin(4+(8)")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("3**4)")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("()")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("true==3")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("true>true")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("true>false")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("false>true")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("false>false")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("true<3")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("true>=3")
    Assert(val == nil or err ~= nil)
    val, err = Parser:eval("-4>false")
    Assert(val == nil or err ~= nil)

    Assert(Parser:eval("x=-1E+3") == -1000)
    val, err = Parser:eval("x=")
    Assert(val == nil or err ~= nil)
    Assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x+=")
    Assert(val == nil or err ~= nil)
    Assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x-=")
    Assert(val == nil or err ~= nil)
    Assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x*=")
    Assert(val == nil or err ~= nil)
    Assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x/=")
    Assert(val == nil or err ~= nil)
    Assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("pi=4")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("e+=4")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("1-=4")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("e*=4")
    Assert(val == nil or err ~= nil)

    val, err = Parser:eval("(1+2)/=4")
    Assert(val == nil or err ~= nil)

    local operators = {"+", "-", "*", "/", "%", "^", "<", ">", "<=", ">=", "==", "!="}
    local operators_math = {"+", "-", "*", "/", "%", "^"}
    local operators_logic = {"||", "&&", "##"}
    local operators_comparison = {"<", ">", "<=", ">=", "==", "!="}

   for _, op1 in pairs(operators_math) do
        for _, op2 in pairs(operators_math) do
            rep_optest(1, op1, op2, repetitions)
        end
    end

    for _, op1 in pairs(operators_logic) do
        for _, op2 in pairs(operators_comparison) do
            rep_optest(1, op1, op2, repetitions)
        end
    end

    for _, op1 in pairs(operators_logic) do
        for _, op2 in pairs(operators_logic) do
            rep_optest(0, op1, op2, repetitions)
        end
    end

    for _, op1 in pairs(operators) do
        for _, op2 in pairs(operators) do
            rep_optest(2, op1, op2, repetitions)
        end
    end

    -- todo bitwise operator tests

    local functions = {
        "abs(", "acos(", "asin(", "atan(", "cos(", "exp(", "floor(", "kill(",
        "ld(", "ln(", "log(", "rndseed(", "round(", "setdeg(", "setgon(",
        "setrad(", "sin(", "sqrt(", "tan(", "√("
    } -- rnd can not be tested so

    for _, func in pairs(functions) do
        for _, op in pairs(operators) do
            functest1(1, op, func)
            functest1(0, op, func)
            functest1(2, op, func)
        end
    end

end

print("\nAll parser tests passed\n" .. test_counter .. " individual tests done\n")

local max_error
local error_angle
test_counter = 0

print("Trigonometry test ...")
ParserHelp.setAngleDeg()

Assert(ParserHelp.sin(3) ~= math.sin(3))

max_error = 0
error_angle = 0
for i = -4*360,4*360,1 do
	local err = math.abs(ParserHelp.sin(i) - math.sin(math.rad(i)))
    Assert(max_error < 1e-15)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 1e-15)

max_error = 0
error_angle = 0
for i = -4*360,4*360,1 do
	local err = math.abs(ParserHelp.cos(i) - math.cos(math.rad(i)))
    Assert(max_error < 1e-14, max_error)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 1e-14, max_error)

max_error = 0
error_angle = 0
for i = -4*360,4*360,1 do
	local err = math.abs(ParserHelp.cos(i) - math.cos(math.rad(i)))
Assert(max_error < 1e-14, max_error)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 1e-14, max_error)

max_error = 0
error_angle = 0
for i = -360,360,5 do
	local err = math.abs(ParserHelp.tan(i) - math.tan(math.rad(i)))/math.tan(math.rad(i))
    Assert(max_error < 1e-14, tostring(max_error) .. " " .. error_angle)
	if i%90 ~= 0 then
		if err > max_error then
			max_error = err
			error_angle = i
		end
	end
end
Assert(max_error < 1e-14, tostring(max_error) .. " " .. error_angle)


ParserHelp.setAngleRad()

max_error = 0
error_angle = 0
for i = -4*math.pi,4*math.pi,0.01 do
	local err = math.abs(ParserHelp.sin(i) - math.sin(i))
    Assert(max_error < 1e-14, max_error)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 1e-14, max_error)

max_error = 0
error_angle = 0
for i = -4*math.pi,4*math.pi,0.01 do
	local err = math.abs(ParserHelp.cos(i) - math.cos(i))
    Assert(max_error < 1e-14, max_error)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 1e-14, max_error)

max_error = 0
error_angle = 0
for i = -2*math.pi,2*math.pi,0.01 do
	local err = math.abs(ParserHelp.tan(i) - math.tan(i))
    Assert(max_error < 5e-10, tostring(max_error) .. " angle: " .. error_angle)
	if err > max_error then
		max_error = err
		error_angle = i
	end
end
Assert(max_error < 5e-10, tostring(max_error) .. " angle: " .. error_angle)

print("\nAll trigonometry tests passed\n" .. test_counter .. " individual tests done\n")
