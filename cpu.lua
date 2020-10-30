-- cpu.lua

CPU = Object:extend()

function CPU.getUserInput(message)
    io.write(message)
    io.flush()
    local ret = io.read() -- TODO: pcall

    return ret
end

function CPU.presentableNegative(n)
    res = (bit.bnot(n) + 1) * -1
    --print(string.format("%08x to %08x", n, res))
    return res
end

function CPU.presentableSigned(n)
    if bit.isnegative(n) then
        return CPU.presentableNegative(n)
    else
        return n
    end
end

function CPU.loadHex(s)
    local n = tonumber(s, 16)
    return n
end

function CPU:new(s)
    if not s then s = "" end

    self.reg = Registers()
    self.data = DataSegment()
    self.instr = TextSegment()
    self.stack = StackSegment()

    self:clrscr()

    local w, e = pcall(function()
        if s == "" then
            s = self.getUserInput("Name of your file: ")
        end

        self:loadFile(s)
    end)

    if not w then
        error("Failed loading file: " .. e)
        return
    end

    print("Init program counter")
    self.reg.pc = self.instr:getStart()
    print("Init stack pointer")
    self.reg:set(29, 0x7FFFEFFC) -- initialize $sp to 0x7FFFEFFC
    print("Init ra")
    self.reg:set(31, 0xFFFFFFFF) -- $ra so as to know when to end the program (on jr 0xFFFFFFFF)
    print("Init gp")
    self.reg:set(28, self.data.start + self.data.size * 2) -- set $gp to 0x10011000
    -- FIXME
    self.reg:set(30, 0x7FFFEFFC) -- set $fp to same as $sp

    local opt = self.getUserInput("Single step (s) or run to completion (c): ")

    print("Handing over control. \n")

    if opt:lower():sub(1, 1) == "s" then
        self:singleStep()
    else
        --[[local w, e = pcall(self.runToCompletion, self)
        if not w then
            print(e)
            self.reg:printAll()
        end]]
        self:runToCompletion()
    end
end

function CPU:clrscr()
    for i = 1, 100 do
        print("\n")
    end
end

function CPU:runToCompletion()
    local callOut = 0
    -- -1 means done
    while callOut ~= -1 do
        callOut = self.instr:run(self, false)
    end
end

function CPU:pInstruction(instr)
    if #instr < 3 then return false end
    local spec = instr:sub(3)
    local loc = 0
    local isInt = true

    local w = pcall(function()
        loc = tonumber(spec)
    end)

    if not w then
        isInt = false
    end

    spec = spec:lower()

    if spec == "all" then
        self.reg:printAll()
    elseif spec == "hi" or spec == "lo" or spec == "pc" then
        self.reg:printReg(spec)
    elseif isInt then
        self.reg:printReg(loc)
    else
        return false
    end

    return true
end

function CPU:dInstruction(instr)
    if #instr < 3 then return false end
    local parts = string.split(instr, " ")
    if #parts < 2 then return false end
    local loc = 0
    local address = parts[#parts]
    local inputHex = false
    local output = 0; -- 0 is decimal 1 is binary 2 is hex

    for i = 2, #parts - 1 do
        if parts[i] == "-h" then
            inputHex = true
        elseif parts[i] == "-oh" then
            output = 2
        elseif parts[i] == "-ob" then
            output = 1
        end
    end

    if address == "stack" then
        self.stack:printAll()
        return true
    elseif address == "data" then
        self.data:printAll()
        return true
    elseif inputHex then
        local w = pcall(function()
            if address:sub(1, 2) == "0x" then
                address = address:sub(3)
            end

            loc = self.loadHex(address)
            address = "0x" .. address
        end)

        if not w then return false end
    else
        local w = pcall(function()
            loc = tonumber(address)
        end)

        if not w then return false end
    end

    local out = ""

    if output == 0 then
        out = self:getFromMemory(loc, 0) .. ""
    elseif output == 1 then
        out = "Binary printing unavailable at the moment." -- FIXME
    elseif output == 2 then
        out = "0x" .. string.format("%08x", self:getFromMemory(loc, 0)):upper()
    end

    print("MEM[" .. address .. "] = " .. out)
    return true
end

function CPU:outputHelp()
    print("p [#/HI/LO/PC/all] - print registers either specific #, hi, lo, pc, or all registers")
    print("d [#/data/stack] - print memory at specific location, default takes a decimal int\n\t-h : take in hex\n\t-oh : output hex\n\t-ob : output binary")
    print("s # - execute next # instructions (# is decimal)")
    print("q - quit")
end

function CPU:singleStep()
    local callOut, isDone, isValid, moveForward, cmd

    while not isDone do
        callOut = 0
        isDone = false
        isValid = false
        moveForward = 0

        local instr = self.getUserInput("Single step instruction: ")
        if #instr == 0 then
            print("Invalid command.")
        else
            cmd = instr:sub(1, 1)

            if cmd == "p" then
                isValid = self:pInstruction(instr)
            elseif cmd == "d" then
                isValid = self:dInstruction(instr)
            elseif cmd == "q" then
                isDone = true
                isValid = true
            elseif cmd == "h" or cmd == "?" then
                self:outputHelp()
                isValid = true
            elseif cmd == "s" then
                if #instr < 3 then
                    moveForward = 0
                    isValid = false
                else
                    local instrNum = instr:sub(3)

                    local w = pcall(function()
                        moveForward = tonumber(instrNum)
                        isValid = true
                    end)

                    if not w then
                        moveForward = 0
                        isValid = false
                    end
                end
            end

            if not isValid then
                print("Invalid command.")
            end

            local i = 0

            while i < moveForward and not isDone do
                i = i + 1
                callOut = self.instr:run(self, true)
                if callOut == -1 then
                    isDone = true
                end
            end
        end
    end
end

function CPU:loadFile(filename)
    print("Loading file " .. filename)
    local i = 1
    local staticData = false

    for line in io.lines(filename) do
        if line == "DATA SEGMENT" then
            staticData = true
        elseif line:sub(1, 2) ~= "0x" then
            error("ERROR on line " .. i .. ": " .. line)
        else
            if staticData then
                local nums = string.split(line, " ")
                local loc = self.loadHex(nums[1]:sub(3))
                local val = self.loadHex(nums[2]:sub(3))

                self:setMemory(loc, 0, val)
            else
                line = line:sub(3)
                local val = self.loadHex(line)
                self.instr:add(val)
            end
        end

        i = i + 1
    end
end

-- get a value from memory
-- chooses which block of memory to read based on memory address
function CPU:getFromMemory(start, offset)
    if start >= self.data.start and start <= self.data.start + self.data.size * 4 then
        return self.data:get(start + offset)
    elseif start >= self.stack.start and start <= self.stack.start + self.stack.size * 4 then
        return self.stack:get(start + offset)
    elseif start >= self.instr.start and start <= self.instr.start + self.instr.size * 4 then
        return self.instr:get(start + offset)
    end

    return 0
end

-- set one word (4 bytes) in memory
function CPU:setMemory(start, offset, rt)
    if start >= self.data.start and start <= self.data.start + self.data.size * 4 then
        --print("set data 0x" .. string.format("%08x", start + offset) .. " -- " .. rt)
        self.data:set(start + offset, rt)
    elseif start >= self.stack.start and start <= self.stack.start + self.stack.size * 4 then
        --print("set stack 0x" .. string.format("%08x", start + offset) .. " -- " .. rt)
        self.stack:set(start + offset, rt)
    elseif start >= self.instr.start and start <= self.instr.start + self.instr.size * 4 then
        --print("set instr 0x" .. string.format("%08x", start + offset) .. " -- " .. rt)
        self.instr:set(start + offset, rt)
    end
end

-- set a byte of memory to a given value
function CPU:setMemoryByte(start, offset, val)
    val = bit.bits(val, 0, 7, false)
    local word = self:getFromMemory(start + offset, 0)
    local byteOffset = (start + offset) % 4
    word = bit.bor(bit.lshift(bit.bits(word, 31 - 8 * byteOffset, 31, false), 31 - 8 * byteOffset), bit.bits(word, 0, 7 * (3 - byteOffset), false))
    local newVal = bit.bor(word, bit.lshift(val, 8 * (3 - byteOffset)))
    self:setMemory(start + offset, 0, newVal)
end

-- read 8 bits from memory
function CPU:getMemoryByte(start, offset, signed)
    local word = self:getFromMemory(start, offset)
    local byteOffset = (start + offset) % 4
    local val = bit.bits(word, 24 - 8 * byteOffset, 31 - 8 * byteOffset, signed)
    return val
end