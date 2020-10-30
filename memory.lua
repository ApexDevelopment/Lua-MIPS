-- memory.lua

Memory = Object:extend()

function Memory:new(size, start)
    self.mem = {}

    for i = 1, size / 4 do
        self.mem[i] = "empty"
    end

    self.size = size / 4
    self.start = start
    self.current = start
end

function Memory:throwOverflowError()
    error("Memory overflow error")
end

-- gets index value based on memory location
function Memory:getRealLoc(loc)
    return math.floor((loc - self.start) / 4) + 1
end

-- gets 4 bytes at given location (number or hex string)
-- assumes word aligned
function Memory:get(loc)
    local realLoc = 0

    if type(loc) == "number" then
        realLoc = self:getRealLoc(loc)
    elseif type(loc) == "string" then
        if loc:sub(1, 2) == "0x" then loc = loc:sub(3) end
        realLoc = self:getRealLoc(tonumber(loc, 16))
    else
        error("ACCESS VIOLATION: Unknown memory location get: " .. tostring(loc))
        return -1
    end

    if not self.mem[realLoc] or self.mem[realLoc] == "empty" then
        --error("ACCESS VIOLATION: Attempted to read unallocated memory at 0x" .. string.format("%08x", loc) .. " (index " .. realLoc .. ")")
        return 0
    end

    return self.mem[realLoc]
end

-- set word at given location
function Memory:set(loc, o)
    local realLoc = 0

    if type(loc) == "number" then
        realLoc = self:getRealLoc(loc)
    elseif type(loc) == "string" then
        if loc:sub(1, 2) == "0x" then loc = loc:sub(3) end
        realLoc = self:getRealLoc(tonumber(loc, 16))
    else
        error("ACCESS VIOLATION: Unknown memory location set: " .. tostring(loc))
        return -1
    end

    self.mem[realLoc] = o
end

-- add a value to the next available spot in memory
function Memory:add(o)
    for i = 1, self.size do
        if self.mem[i] == "empty" then
            self.mem[i] = o
            return
        end
    end

    self:throwOverflowError()
end

function Memory:getBits(loc, startBit, endBit, signed)
    if startBit > endBit then
        local temp = endBit
        endBit = startBit
        startBit = temp
    end

    local value = self.mem[self:getRealLoc(loc)]

    if value == "empty" then
        error("ACCESS VIOLATION: Attempted to index unallocated memory.")
        return -1
    end

    return bit.bits(value, startBit, endBit, signed)
end

-- print all memory locations that are not 0 or nil
function Memory:printAll()
    for i = 1, self.size do
        if self.mem[i] and self.mem[i] ~= "empty" then
            local loc = (i - 1) * 4 + self.start
            print("0x" .. string.format("%08x", loc):upper() .. ": 0x" .. string.format("%08x", self.mem[i]):upper())
        end
    end
end