--[[
    Helper functions for formulaparser

    Author: Martin Zwicknagl
]]

math.e = math.exp(1)
local angle_convert = 1 -- use 1 for RAD, pi/180 for Deg, pi/200 for Gon

local ParserHelp = {}

ParserHelp.help_text = [[Help:

random generator is seeded by os.time()

Variables names may start with [_A-Za-z] but not with [0-9]

1.) Variables stored with ":=":
    If you define "b=2,x:=4+b" and then set "b=5", "x" evaluates to 9.
    So you can use the variable like a function.
2.) Variables stored with "=":
    If you define "b=2,x=4+b" and then set "b=5", "x" evaluates to 6

Predefined constants:
    "e"        Euler's number
    "pi", "π"  Two pi :)

Predefined var:
    "ans"   42

The following operators are supported with increasing priority:
    ","  sequential
    ":=" store tree
    "+=" increase evaluated value by
    "-=" decrease evaluated value by
    "*=" multiply evaluated value by
    "/=" divide evaluated value by
    "="  store evaluated value,
    "?:" ternary like in C
    "&&" logical and
    "||" logical or
    "!&" logical nand
    "<="
    "=="
    ">="
    "!="
    ">"
    "<"
    "+"  sing, add
    "-"  sign, subtract
    "*"  multiply
    "/"  divide
    "%"  modulo
    "^"  power
    "!"  factorial

The following functions are supported:
the angular functions can operate on degree, radiant and gon.

    "(", braces for identity function
    "abs("
    "acos("
    "asin("
    "atan("
    "bug("      show hints for a bug
    "cos("
    "exp("
    "floor("    round down
    "getAngleMode(" Info: degree, radiant, gon; not for calculations
    "kill("     delete a variable
    "ld("       logarithmus dualis
    "ln("       logarithmus naturalis
    "log("      logarithmus decadis
    "rnd("      random
    "rndseed("  randomseed
    "round("    round

    "setdeg(",  set angle mode to degree
    "setgon(",  set angle mode to gon
    "setrad(",  set angle mode to radiant
    "showvars(",  show defined variables
    "sin("
    "sqrt("
    "tan("
    "√("

Examples:
    3+4*5    -> 23
    ld(1024) -> 10
    3>4      -> true
    4!=4     -> false
    x=3>4?1:-1 -> -1, set x=-1
    x=2,y=4  -> 4, set x=2 and y=4
]]

ParserHelp.bug_text = [[You have triggered a BUG.
Please report an issue on
https://github.com/zwim/formula-parser
Please note the offending formula and the output of 'showvars()'.
]]

function ParserHelp.abs(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return math.abs(l)
end

function ParserHelp.acos(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.acos(l) / angle_convert
end
function ParserHelp.asin(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.asin(l) / angle_convert
end
function ParserHelp.atan(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.atan(l) / angle_convert
end

function ParserHelp.cos(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.cos(l * angle_convert)
end
function ParserHelp.sin(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.sin(l * angle_convert)
end
function ParserHelp.tan(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmethics on boolean?"
    end
    return math.tan(l * angle_convert)
end

function ParserHelp.identity(l) return l end

function ParserHelp.factorial(l, r)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif r then
        return nil, "no value expected"
    end
    local x = 1
    for i = 2, l do x = x * i end
    return x
end

function ParserHelp.exp(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return math.exp(l)
end

function ParserHelp.ln(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l <= 0 then
        return nil, "Domain error"
    end
    return math.log(l)
end

function ParserHelp.log2(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l <= 0 then
        return nil, "Domain error"
    end
    return math.log(l) / math.log(2)
end

function ParserHelp.log(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l <= 0 then
        return nil, "Domain error"
    end
    return math.log10(l) / math.log(math.e)
end

function ParserHelp.add(l, r)
    if r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l == nil then
        return r
    else
        return l + r
    end
end

function ParserHelp.sub(l, r)
    if r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l == nil then
        return -r
    else
        return l - r
    end
end

function ParserHelp.mul(l, r)
    if l == nil or r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return l * r
end

function ParserHelp.div(l, r)
    if l == nil or r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return l / r
end

function ParserHelp.mod(l, r)
    if l == nil or r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return l % r
end

function ParserHelp.pot(l, r)
    if l == nil or r == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return l ^ r
end

function ParserHelp.floor(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return math.floor(l)
end
function ParserHelp.round(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    return math.floor(l + 0.5)
end

function ParserHelp.randomseed(l)
    if l == nil then
        return nil
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    if l > 0 then
        return math.randomseed(l)
    else
        return math.randomseed(os.clock())
    end
end
function ParserHelp.rnd(l)
    if l == nil then
        return nil
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    end
    if l > 0 then
        return math.random(0, l)
    else
        return math.random()
    end
end

function ParserHelp.sqrt(l)
    if l == nil then
        return nil, "Value expected"
    elseif type(l) == "boolean" then
        return nil, "Arithmetics on boolean?"
    elseif l < 0 then
        return nil, "Domain error"
    end
    return math.sqrt(l)
end

function ParserHelp.setAngleDeg()
    angle_convert = math.pi / 180
    return angle_convert
end
function ParserHelp.setAngleRad()
    angle_convert = 1
    return angle_convert
end
function ParserHelp.setAngleGon()
    angle_convert = math.pi / 200
    return angle_convert
end
function ParserHelp.getAngleMode()
    if angle_convert == 1 then
        return "radiant"
    elseif angle_convert == math.pi / 180 then
        return "degree"
    else
        return "gon"
    end
end

function ParserHelp.seq(l, r)
    if l == nil or r == nil then return nil, "Value expected ','" end
    return r
end

function ParserHelp.ternary(l, m, r)
    if l == nil or m == nil or r == nil then return nil, "Value expected" end
    if l then
        return m
    else
        return r
    end
end

function ParserHelp.logOr(l, r)
    if l == nil or r == nil then return nil, "Value missing" end
    return l or r
end
function ParserHelp.logAnd(l, r)
    if l == nil or r == nil then return nil, "Value missing" end
    return l and r
end
function ParserHelp.logNand(l, r)
    if l == nil or r == nil then return nil, "Value missing" end
    return not (l and r)
end

function ParserHelp.lt(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Comparison on boolean?"
    end
    return (l < r)
end
function ParserHelp.le(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Comparison on boolean?"
    end
    return (l <= r)
end
function ParserHelp.ge(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Comparison on boolean?"
    end
    return (l >= r)
end
function ParserHelp.gt(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) == "boolean" or type(r) == "boolean" then
        return nil, "Comparison on boolean?"
    end
    return (l > r)
end
function ParserHelp.ne(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) ~= type(r) then
        return nil, "Mixed comparison?"
    end
    return (l ~= r)
end
function ParserHelp.eq(l, r)
    if l == nil or r == nil then
        return nil
    elseif type(l) ~= type(r) then
        return nil, "Mixed comparison?"
    end
    return (l == r)
end

ParserHelp.greek = {
    {"α", "alpha"},
    {"β", "beta"},
    {"γ", "gamma"},
    {"δ", "delta"},
    {"ε", "epsilon"},
    {"ζ", "zeta"},
    {"η", "eta"},
    {"ϑ", "thita"},
    {"ι", "iota"},
    {"ϰ", "kappa"},
    {"λ", "lambda"},
    {"μ", "my"},
    {"ν", "ny"},
    {"ξ", "xi"},
    {"π", "pi"},
    {"ρ", "rho"},
    {"σ", "sigma"},
    {"τ", "tau"},
    {"φ", "phi"},
    {"χ", "chi"},
    {"ψ", "psi"},
    {"ω", "omega"},
}

return ParserHelp
