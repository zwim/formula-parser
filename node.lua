--[[
    The parser datastructure
]]

local Node = {
    left = nil,
    mid = nil,
    right = nil,
    op = nil,
    val = nil,
    name = nil,
    assoz = nil,
}

function Node:new(o)
    if not o then o = {} end
    return o
end

return Node
