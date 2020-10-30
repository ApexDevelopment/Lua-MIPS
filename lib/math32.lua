-- math32.lua

math32 = {}

function math32.add(...)
    local sum = 0

    for _, arg in next, {...} do
        sum = sum + arg
    end

    return sum % 4294967296
end

function math32.sub(...)
    local args = {...}
    local sum = args[1]

    for i = 2, #args do
        sum = sum - args[i]
    end

    if sum < 0 then
        sum = 4294967296 + sum
    end

    return sum
end

--[[print("2 + 2 = " .. math32.add(2, 2))
print("100 + 100 = " .. math32.add(100, 100))
print("4294967294 + 2 = " .. math32.add(4294967294, 2))
print("4194412 + 4294967283 = " .. math32.add(4194412, 4294967283))]]