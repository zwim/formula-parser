--[[
    Testsuite for parser.lua

    Author: Martin Zwicknagl
    Version: 0.9.0
]]

-- number of passes
local passes = 20 -- set this for benchmark
local repetitions = 16 -- how thorogh the test is
math.randomseed(os.clock())

-- local Parser = require("formulaparser")
local Parser = require("formulaparser")

print("This is a test for formulaparser.lua")

print("Help")
print(tostring(Parser:eval("help()")))

local greek_alphabet = "α β γ δ ε ζ η ϑ ι ϰ λ μ ν ξ π ρ σ τ φ χ ψ ω Σ"
local greek_alphabet_in_text = "alpha beta gamma delta epsilon zeta eta thita iota kappa lambda my ny xi pi rho sigma tau phi chi psi omega Sigma"

print("THE ANSWER: " .. Parser:eval("ans") .. "\n")
assert(Parser:eval("ans") == 42)

assert(greek_alphabet_in_text == Parser:greek2text(greek_alphabet))
assert(greek_alphabet == Parser:text2greek(greek_alphabet_in_text))

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

local function my_assert(a, b)
    local expected, result, err
    local lua_fun = loadstring("function() return " .. b .. " end")
    --      print(a)
    expected = lua_fun and pcall(lua_fun())
    result, err = Parser:eval(a)
    if math.finite(expected) and math.finite(result) then
        if type(result) == "number" and type(expected) == "number" then
            assert(math.abs(result - expected) /
                       ((expected == 0) and 1 or expected) < 1e-12,
                   string.format("%s  err:%s   %.20f==%.20f diff=%E\n", a,
                                 tostring(err), result, expected,
                                 result - expected))
        elseif result == nil and expected == nil then
            assert(result == expected,
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

   my_assert(a, b)
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
    my_assert(aa, bb)

    -- e.g. 3*sin(5)
    aa =       func .. a .. op .. x .. ")"
    bb = "" .. func .. b .. op .. y .. ")"
    my_assert(aa, bb)
end
---------------------------------


for number = 0, passes do

    if number % 10 == 0 then print("Test run: " .. number) end

    --  print("numbers")
    assert(Parser:eval("0") == 0)
    assert(Parser:eval("pi") == math.pi)
    assert(Parser:eval("exp(1)") == math.exp(1))

    assert(Parser:eval("123") == 123)
    assert(Parser:eval("-123") == -123)
    assert(Parser:eval("1E12") == 1e12)
    assert(Parser:eval("-12E34") == -12e34)
    assert(Parser:eval("1E-12") == 1e-12)
    assert(Parser:eval("-1E-12") == -1e-12)

    --  print("operators")
    assert(Parser:eval("1+2") == 1 + 2)
    assert(Parser:eval("1-2") == 1 - 2)
    assert(Parser:eval("3*2") == 3 * 2)
    assert(Parser:eval("3/2") == 3 / 2)
    assert(Parser:eval("7%2") == 7 % 2)
    assert(Parser:eval("3^2") == 3 ^ 2)
    assert(Parser:eval("5!") == 120)
    assert(Parser:eval("e^5") == math.exp(1) ^ 5)
    assert(Parser:eval("3*pi") == 3 * math.pi)
    assert(Parser:eval("3pi") == 3 * math.pi)
    assert(Parser:eval("-4pi") == -4 * math.pi)
    assert(Parser:eval("false || false") == false)
    assert(Parser:eval("true  || false") == true)
    assert(Parser:eval("false || true") == true)
    assert(Parser:eval("true  || true") == true)
    assert(Parser:eval("3 || false") == 3)
    assert(Parser:eval("3 || 7") == 3)
    assert(Parser:eval("false || 7") == 7)
    assert(Parser:eval("false && false") == false)
    assert(Parser:eval("true  && false") == false)
    assert(Parser:eval("false && true") == false)
    assert(Parser:eval("true  && true") == true)
    assert(Parser:eval("2  && true") == true)
    assert(Parser:eval("2  && 7") == 7)
    assert(Parser:eval("false  && 7") == false)
    assert(Parser:eval("false ## false") == true)
    assert(Parser:eval("true  ## false") == true)
    assert(Parser:eval("false ## true") == true)
    assert(Parser:eval("true  ## true") == false)
    assert(Parser:eval("true  ## true") == false)
    assert(Parser:eval("##true") == false)
    assert(Parser:eval("##false") == true)
    assert(Parser:eval("##8") == false)
    assert(Parser:eval("##0") == false)
    assert(Parser:eval("2>0") == true)
    assert(Parser:eval("5>5") == false)
    assert(Parser:eval("5>=5") == true)
    assert(Parser:eval("5==5") == true)
    assert(Parser:eval("true==true") == true)
    assert(Parser:eval("true==false") == false)
    assert(Parser:eval("false==true") == false)
    assert(Parser:eval("false==false") == true)
    assert(Parser:eval("4<10") == true)
    assert(Parser:eval("4<=10") == true)
    assert(Parser:eval("4<=1") == false)
    assert(Parser:eval("5!=5") == false)
    assert(Parser:eval("true!=true") == false)
    assert(Parser:eval("true!=false") == true)
    assert(Parser:eval("false!=true") == true)
    assert(Parser:eval("false!=false") == false)
    assert(Parser:eval("7 | 8") == 15)
    assert(Parser:eval("7 & 8") == 0)
    assert(Parser:eval("7 # 8") == -1)
    assert(Parser:eval("3 ~ 5") == 6)
    assert(Parser:eval("#8") == -9)

    assert(Parser:eval("265/5/8") == 265 / 5 / 8)

    assert(Parser:eval("2^1^3") == (2 ^ 1) ^ 3)
    assert(Parser:eval("2/3*5") == 2 / 3 * 5)

    assert(Parser:eval("123+4*6") == 123 + 4 * 6)
    assert(Parser:eval("4*6+123") == 4 * 6 + 123)

    assert(Parser:eval("(3*8)-7") == (3 * 8) - 7)
    assert(Parser:eval("3*(8-7)") == 3 * (8 - 7))
    assert(Parser:eval("(8-7)*3") == (8 - 7) * 3)
    assert(Parser:eval("-(-8-7)*3") == -(-8 - 7) * 3)
    assert(Parser:eval("-(-8-7)*(3)") == -(-8 - 7) * (3))
    assert(Parser:eval("(8-7)*pi") == (8 - 7) * math.pi)

    assert(Parser:eval("(8e5-7)*3e-4") == (8e5 - 7) * 3e-4)
    assert(Parser:eval("(8+e-7)*3") == (8 + math.exp(1) - 7) * 3)
    assert(Parser:eval("(-8e5-7)%3e-4") == (-8e5 - 7) % 3e-4)

    assert(Parser:eval("3!+4") == 10)
    assert(Parser:eval("-e*2") == -math.exp(1) * 2)

    assert(Parser:eval("4 || false || 5") == 4)
    assert(Parser:eval("4 && 1 && 5") == 5)

    assert(Parser:eval("(-pi)&&(+pi)") == math.pi)
    assert(Parser:eval("-pi<=e") == true)

    assert(Parser:eval("4<4 || 4==4") == true)
    assert(Parser:eval("4<4 && 4==4") == false)
    assert(Parser:eval("4<4 && 4>=4") == false)
    assert(Parser:eval("4<4 ## 4>=4") == true)

    --  print("functions")
    assert(Parser:eval("abs(-4.5)") == 4.5)
    assert(Parser:eval("floor(5.9)") == 5)
    assert(Parser:eval("round(5.9)") == 6)
    assert(Parser:eval("sqrt(100)") == 10)
    assert(Parser:eval("√(100)") == 10)
    assert(Parser:eval("ld(1024)") == 10)
    assert(Parser:eval("ln(e)") == 1)
    assert(Parser:eval("log(0.001)") == -3)

    --  print("angle func")
    Parser:eval("setrad()")

    assert(Parser:eval("sin(3*pi)") == math.sin(3 * math.pi))
    my_assert("asin(0.3)","math.asin(0.3)")
    assert(Parser:eval("cos(0.3)") == math.cos(0.3))
    assert(Parser:eval("acos(0.3)") == math.acos(0.3))
    assert(Parser:eval("tan(0.3)") == math.tan(0.3))
    assert(Parser:eval("atan(0.3)") == math.atan(0.3))

    assert(Parser:eval("asin(sin(3*pi))") == math.asin(math.sin(3 * math.pi)))
    assert(Parser:eval("acos(cos(3*pi))") == math.acos(math.cos(3 * math.pi)))
    assert(Parser:eval("atan(tan(3*pi))") == math.atan(math.tan(3 * math.pi)))

    Parser:eval("setdeg()")
    assert(Parser:eval("sin(90)") == 1)
    assert(Parser:eval("sin(90)") == math.sin(90 * math.pi / 180))
    assert(Parser:eval("asin(1)") == 90)
    assert(Parser:eval("cos(180)") == -1)
    assert(Parser:eval("acos(0)") == 90)
    assert(Parser:eval("acos(-1)") == 180)
    assert(Parser:eval("tan(45)") == math.tan(math.pi / 4))
    assert(Parser:eval("atan(1)") == 45)
    assert(Parser:eval("atan(0.3)") == math.atan(0.3) / math.pi * 180)

    my_assert("asin(sin(45))", "math.asin(math.sin(math.pi / 4)) * 180 / math.pi")
    assert(Parser:eval("acos(cos(0))") == math.acos(math.cos(0)))
    assert(Parser:eval("atan(tan(0.1))") == math.atan(math.tan(0.1)))

    --  print("other random test")
    assert(Parser:eval("abs(-5)*abs(6)+77") == math.abs(-5) * math.abs(6) + 77)

    assert(Parser:eval("floor(23.3*4.7)-2") == math.floor(23.3 * 4.7) - 2)
    assert(Parser:eval("round(23.3*4.7)") == math.floor(23.3 * 4.7 + 0.5))

    Parser:eval("randseed(1)")
    assert(Parser:eval("rnd(12)") <= 12)

    assert(Parser:eval("log(1e-4)") == -4)

    --  print("store tests")

    assert(Parser:eval("x=1+2") == 3)
    assert(Parser:eval("x") == 3)

    Parser:eval("x=1+2")
    assert(Parser:eval("x=20+x") == 23)
    assert(Parser:eval("x") == 23)

    Parser:eval("test=" .. number)
    assert(Parser:eval("20+test") == 20 + number)

    Parser:eval("x=y=12")
    assert(Parser:eval("x") == 12)
    assert(Parser:eval("y") == 12)

    Parser:eval("x=3+(y=-3)")
    assert(Parser:eval("y") == -3)
    assert(Parser:eval("x") == 3 - 3)

    assert(Parser:eval("kill(x)") == true)
    assert(Parser:eval("kill()") == true)
    assert(Parser:eval("kill(y)") == false)

    Parser:eval("kill(x)")
    Parser:eval("x:=1+2")
    assert(Parser:eval("y:=20+x") == 23)

    assert(Parser:eval("x+=5+5") == 13)
    assert(Parser:eval("x-=20") == 13 - 20)
    Parser:eval("x:=10")
    assert(Parser:eval("x*=5") == 50)
    assert(Parser:eval("x/=10") == 5)
    assert(Parser:eval("x%=4") == 1)

    --  print("sequential")
    assert(Parser:eval("3,4") == 4)
    assert(Parser:eval("1*2,3*5") == 15)
    assert(Parser:eval("(1+2),(3*5)") == 15)
    assert(Parser:eval("x=3,y=-12") == -12)
    assert(Parser:eval("x") == 3)
    assert(Parser:eval("y") == -12)

    --  print("ternary op")
    assert(Parser:eval("true?5:-5") == 5, Parser:eval("true?5:-5"))
    assert(Parser:eval("false?5:-5") == -5)

    assert(Parser:eval("3<3?5:-5") == -5)

    assert(Parser:eval("x=3") == 3)
    assert(Parser:eval("x?pi:e") == math.pi)
    assert(Parser:eval("x-=3") == 0)
    assert(Parser:eval("x!=0?pi:e") == math.exp(1))

    assert(Parser:eval("2>0?2:-2") == 2)
    assert(Parser:eval("2<0?2:-2") == -2)

    assert(Parser:eval("x=3") == 3)
    assert(Parser:eval("x>0?x:-x") == 3)
    assert(Parser:eval("x<=0?x:-x") == -3)

    assert(Parser:eval("2>4?3:4") == 4)

    Parser:eval("x=10")
    assert(Parser:eval("x=x==0?pi:e") == math.exp(1))
    assert(Parser:eval("x") == math.exp(1))

    assert(Parser:eval("2ld(1024)") == 20)
    assert(Parser:eval("2pi") == 2 * math.pi)
    assert(Parser:eval("2(pi)") == 2 * math.pi)

    assert(Parser:eval("kill()") == true)

    --  print("check for wrong input")
    local val, err

    val, err = Parser:eval("")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("z")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3-")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("*4)")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("2*)")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("2+3)")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("(3*2")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("*pi")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("sin(x")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3!*+4")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4-)")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4))")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3*(4+(8)))")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("1*sin(4+(8)")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("3**4)")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("()")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("true==3")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("true>true")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("true>false")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("false>true")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("false>false")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("true<3")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("true>=3")
    assert(val == nil or err ~= nil)
    val, err = Parser:eval("-4>false")
    assert(val == nil or err ~= nil)

    assert(Parser:eval("x=-1E+3") == -1000)
    val, err = Parser:eval("x=")
    assert(val == nil or err ~= nil)
    assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x+=")
    assert(val == nil or err ~= nil)
    assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x-=")
    assert(val == nil or err ~= nil)
    assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x*=")
    assert(val == nil or err ~= nil)
    assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("x/=")
    assert(val == nil or err ~= nil)
    assert(Parser:eval("x") == -1000)

    val, err = Parser:eval("pi=4")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("e+=4")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("1-=4")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("e*=4")
    assert(val == nil or err ~= nil)

    val, err = Parser:eval("(1+2)/=4")
    assert(val == nil or err ~= nil)

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

print("\nAll tests passed\n")
