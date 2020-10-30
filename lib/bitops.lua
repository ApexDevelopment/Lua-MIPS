-- bitops.lua
-- 32-bitwise operations
local MAX = 0xFFFFFFFF
local MOD = MAX + 1
local NEG = 0x80000000

function isnegative(num)
    return num >= NEG
end

function bnot(num)
    --print(MAX, num, MAX - num)
    return MAX - num
end

function bxor(a, b)
    local p, c = 1, 0

    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then c = c + p end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end

    if a < b then a = b end

    while a > 0 do
        local ra = a % 2
        if ra > 0 then c = c + p end

        a, p = (a - ra) / 2, p * 2
    end

    return c
end

function band(a, b)
    local p, c = 1, 0

    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra + rb > 1 then c = c + p end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end

    return c
end

function bor(a, b)
    local p, res = 1, 0

    while a + b > 0 do
        local ra, rb = a % 2, b % 2

        if ra + rb > 0 then
            res = res + p
        end

        a = (a - ra) / 2
        b = (b - rb) / 2
        p = p * 2
	end
	
    return res
end

-- left bitshift (<<)
function lshift(num, amt)
    return num * 2 ^ amt
end

-- normal right bitshift (>>>)
function rshift(num, amt)
    return math.floor(num / 2 ^ amt)
end

-- right bitshift but pad with sign bit (>>)
function srshift(num, amt)
    local z = rshift(num, amt)
    if num >= NEG then z = z + lshift(2^amt-1, 32 - amt) end
    return z
end

function bits(val, bStart, bEnd, signed)
    if type(signed) == "nil" then signed = true end

    local max = MAX
    local mask = band(rshift(max, 31 - bEnd), lshift(max, bStart))
    --print(val, mask)
    val = band(val, mask)

    if signed then
        val = lshift(val, 31 - bEnd)
        return srshift(val, bStart + (31 - bEnd))
    end

    return rshift(val, bStart)
end

function numtotable(num)
    local t = {}

    while num > 0 and #t < 32 do
        local r = num % 2
        t[#t + 1] = r
        num = (num - r) / 2
    end

    while #t < 32 do
        t[#t + 1] = 0
    end

    return t
end

function tabletonum(tab)
    local num = 0

    for i = 1, #tab do
        num = num + tab[i] * 2 ^ (i - 1)
    end

    return num
end

bit = {
    max = MAX,
    neg = NEG,
    isnegative = isnegative,
    bnot = bnot,
    bxor = bxor,
    band = band,
    bor = bor,
    lshift = lshift,
    rshift = rshift,
    srshift = srshift,
    bits = bits,
    numtotable = numtotable,
    tabletonum = tabletonum
}