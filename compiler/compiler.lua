-- compiler.lua

--[[
	This tool is completely useless for anything other than "compiling" my
	"MIPS assembly"-esque language into the format that my intepreter can read. 
]]

function split(str,sep)
    local ret={}
    local n=1
    for w in str:gmatch("([^"..sep.."]*)") do
        ret[n] = ret[n] or w
        if w=="" then
            n = n + 1
        end
    end
    return ret
end

-- trim12
local function trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

local function band(a, b)
    local p, c = 1, 0

    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra + rb > 1 then c = c + p end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end

    return c
end

local function lshift(n, amt)
    return n * 2 ^ amt
end

local function rshift(n, amt)
    return math.floor(n / 2 ^ amt)
end

local function autonumber(n)
    if n:sub(1, 2) == "0x" then
        return tonumber(n:sub(3), 16)
    end

    local endChar = n:sub(#n, #n)

    if endChar == "h" then
        return tonumber(n:sub(1, #n - 1), 16)
    elseif endChar == "b" then
        return tonumber(n:sub(1, #n - 1), 2)
    else
        local n = tonumber(n)
        if n < 0 then n = 4294967295 + n + 1 end
        return tonumber(n)
    end
end

local function parseArgs(args)
    local parsed = {}

    for _, arg in next, args do
        local endChar = arg:sub(#arg, #arg)

        if endChar == "," then
            arg = arg:sub(1, #arg - 1)
        elseif endChar == ")" then
            local s = split(arg:sub(1, #arg - 1), "(")

            table.insert(parsed, autonumber(s[1]))
            arg = s[2]
        end

        if arg:sub(1, 1) == "$" then
            -- register
            local reg = arg:sub(2)
            local fl = reg:sub(1, 1)

            if reg == "ra" then
                reg = 31
            elseif reg == "s8" or reg == "fp" then
                reg = 30
            elseif reg == "sp" then
                reg = 29
            elseif reg == "gp" then
                reg = 28
            elseif reg == "at" then
                reg = 1
            elseif reg == "zero" then
                reg = 0
            elseif fl == "k" then
                reg = tonumber(reg:sub(2)) + 26
            elseif fl == "t" then
                reg = tonumber(reg:sub(2)) + 24
            elseif fl == "s" then
                reg = tonumber(reg:sub(2)) + 16
            elseif fl == "t" then
                reg = tonumber(reg:sub(2)) + 8
            elseif fl == "a" then
                reg = tonumber(reg:sub(2)) + 4
            elseif fl == "v" then
                reg =  tonumber(reg:sub(2)) + 2
            else
                reg = tonumber(reg)
            end

            table.insert(parsed, reg)
        else
            -- immediate
            local num = autonumber(arg)
            table.insert(parsed, num)
        end
    end

    return unpack(parsed)
end

local function ASMtoHex(asm)
    local parts = split(asm, " ")
    local cmd = parts[1]:lower()
    table.remove(parts, 1)
    local final = 0

    if cmd == "sll" then
        local rd, rt, sa = parseArgs(parts)
        final = lshift(sa, 6) + lshift(rt, 11) + lshift(rt, 16)
    elseif cmd == "srl" then
        local rd, rt, sa = parseArgs(parts)
        final = 2 + lshift(sa, 6) + lshift(rt, 11) + lshift(rt, 16)
    elseif cmd == "sra" then
        local rd, rt, sa = parseArgs(parts)
        final = 3 + lshift(sa, 6) + lshift(rt, 11) + lshift(rt, 16)
    elseif cmd == "jr" then
        local rs = parseArgs(parts)
        final = 8 + lshift(rs, 21)
    elseif cmd == "movz" then
        local rd, rs, rt = parseArgs(parts)
        final = 10 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "syscall" then
        final = 12
    elseif cmd == "mfhi" then
        local rd = parseArgs(parts)
        final = 16 + lshift(rd, 11)
    elseif cmd == "mflo" then
        local rd = parseArgs(parts)
        final = 18 + lshift(rd, 11)
    elseif cmd == "mult" then
        local rs, rt = parseArgs(parts)
        final = 24 + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "multu" then
        local rs, rt = parseArgs(parts)
        final = 25 + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "add" then
        local rd, rs, rt = parseArgs(parts)
        final = 32 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "addu" then
        local rd, rs, rt = parseArgs(parts)
        final = 33 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "sub" then
        local rd, rs, rt = parseArgs(parts)
        final = 34 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "subu" then
        local rd, rs, rt = parseArgs(parts)
        final = 35 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "and" then
        local rd, rs, rt = parseArgs(parts)
        final = 36 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "or" then
        local rd, rs, rt = parseArgs(parts)
        final = 37 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "xor" then
        local rd, rs, rt = parseArgs(parts)
        final = 38 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "nor" then
        local rd, rs, rt = parseArgs(parts)
        final = 39 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "slt" then
        local rd, rs, rt = parseArgs(parts)
        final = 42 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "sltu" then
        local rd, rs, rt = parseArgs(parts)
        final = 43 + lshift(rd, 11) + lshift(rt, 16) + lshift(rs, 21)
    elseif cmd == "bgez" then
        local rs, offset = parseArgs(parts)
        final = offset + lshift(1, 16) + lshift(rs, 21) + lshift(1, 26)
    elseif cmd == "bltz" then
        local rs, offset = parseArgs(parts)
        final = offset + lshift(rs, 21) + lshift(1, 26)
    elseif cmd == "j" then
        local target = parseArgs(parts)
        final = target + lshift(2, 26)
    elseif cmd == "jal" then
        local target = parseArgs(parts)
        final = target + lshift(3, 26)
    elseif cmd == "beq" then
        local rs, rt, offset = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(rs, 21) + lshift(4, 26)
    elseif cmd == "bne" then
        local rs, rt, offset = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(rs, 21) + lshift(5, 26)
    elseif cmd == "blez" then
        local rs, offset = parseArgs(parts)
        final = offset + lshift(rs, 21) + lshift(6, 26)
    elseif cmd == "bgtz" then
        local rs, offset = parseArgs(parts)
        final = offset + lshift(rs, 21) + lshift(7, 26)
    elseif cmd == "addi" then
        local rt, rs, immed = parseArgs(parts)
        final = band(immed, 0xFFFF) + lshift(rt, 16) + lshift(rs, 21) + lshift(8, 26)
    elseif cmd == "addiu" then
        local rt, rs, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(rs, 21) + lshift(9, 26)
    elseif cmd == "slti" then
        local rt, rs, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(rs, 21) + lshift(10, 26)
    elseif cmd == "sltiu" then
        local rt, rs, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(rs, 21) + lshift(11, 26)
    elseif cmd == "andi" then
        local rt, rs, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(rs, 21) + lshift(12, 26)
    elseif cmd == "ori" then
        local rt, rs, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(rs, 21) + lshift(13, 26)
    elseif cmd == "lui" then
        local rt, immed = parseArgs(parts)
        final = immed + lshift(rt, 16) + lshift(15, 26)
    elseif cmd == "lb" then
        local rt, offset, base = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(base, 21) + lshift(32, 26)
    elseif cmd == "lw" then
        local rt, offset, base = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(base, 21) + lshift(35, 26)
    elseif cmd == "lbu" then
        local rt, offset, base = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(base, 21) + lshift(36, 26)
    elseif cmd == "sb" then
        local rt, offset, base = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(base, 21) + lshift(40, 26)
    elseif cmd == "sw" then
        local rt, offset, base = parseArgs(parts)
        final = offset + lshift(rt, 16) + lshift(base, 21) + lshift(43, 26)
    else
        return "Unrecognized command \"" .. cmd:upper() .. "\""
    end

    return "0x" .. string.format("%08x", final):upper()
end

local function convertInstr(asm, labels)
    local parts = split(asm, " ")
    local cmd = parts[1]:lower()
    table.remove(parts, 1)
    local finalInstructions = {}

    -- pseudoinstrucions
    if cmd == "move" then
        local rd, rs = parseArgs(parts)
        table.insert(finalInstructions, ASMtoHex("add $" .. rd .. ", $" .. rs .. ", $zero"))
    elseif cmd == "blt" then
        local rs, rt, offset = parseArgs(parts)
        table.insert(finalInstructions, ASMtoHex("slt $at, $" .. rs .. ", $" .. rt))
        table.insert(finalInstructions, ASMtoHex("bne $at, $zero, " .. offset))
    elseif cmd == "li" then
        local rd, immed = parseArgs(parts)
        table.insert(finalInstructions, ASMtoHex("lui $at, " .. rshift(band(immed, 0xFFFF0000), 16)))
        table.insert(finalInstructions, ASMtoHex("ori $" .. rd .. ", $at, " .. band(immed, 0xFFFF)))
    elseif cmd == "la" then
        local rd = parseArgs({parts[1]})
        local loc = labels[parts[2]]
        table.insert(finalInstructions, ASMtoHex("lui $at, 4097"))
        table.insert(finalInstructions, ASMtoHex("ori $" .. rd .. ", $at, " .. (loc - 0x10010000))) -- TODO: ADD VARIABLES!
    else
        table.insert(finalInstructions, ASMtoHex(asm))
    end

    return finalInstructions
end


local function compile(path)
    local dtype = 0 -- 0 = instructions, 1 = data
    local instr = {}
    local data = {}
    local labels = {}
    local dlabels = {}

    for line in io.lines(path) do
        line = trim(line)

        if line:sub(1, 1) ~= "#" then
            if line:lower() == ".text" then
                dtype = 0
            elseif line:lower() == ".data" then
                dtype = 1
            elseif dtype == 0 then
                if line ~= "" then
                    if line:sub(#line, #line) == ":" then -- for labels
                        labels[line:sub(1, #line-1)] = 0x00400000 + #instr * 4
                    else
                        line = trim(line)

                        for lbl, loc in pairs(labels) do
                            local s, e = line:find(lbl)

                            if s then
                                local last = ""

                                if e < #line then
                                    last = line:sub(e + 1)
                                end

                                line = line:sub(1, s - 1) .. loc .. last
                            end
                        end

                        local instrs = convertInstr(line, dlabels)

                        for _, i in next, instrs do
                            table.insert(instr, i)
                        end
                    end
                end
            elseif dtype == 1 then
                line = trim(line)
                parts = split(line, " ")
                local first = parts[1]

                if first:sub(#first, #first) == ":" then
                    dlabels[first:sub(1, #first - 1)] = 0x10010000 + #data * 4

                    parts = split(trim(line:sub(#first + 1)), " ")
                    first = parts[1]
                end

                if first == ".asciiz" then
                    local s = split(line:sub(8), "\"")[2]:gsub("\\n", "\n")
                    local bytes = {s:byte(1, #s)}
                    local bytestr = "0x"

                    for i, b in ipairs(bytes) do
                        bytestr = bytestr .. string.format("%02x", b)

                        if i % 4 == 0 and bytestr then
                            data[#data + 1] = bytestr
                            bytestr = "0x"
                        end
                    end

                    if #bytestr > 2 and #bytestr < 10 then
                        while #bytestr < 10 do
                            bytestr = bytestr .. "0"
                        end

                        data[#data + 1] = bytestr
                    else
                        data[#data + 1] = "0x00000000"
                    end
                elseif first == ".ascii" then
                    local s = split(line:sub(8), "\"")[2]
                    local bytes = {s:byte(1, #s)}
                    local bytestr = "0x"

                    for i, b in ipairs(bytes) do
                        bytestr = bytestr .. string.format("%02x", b)

                        if i % 4 == 0 and bytestr then
                            data[#data + 1] = bytestr
                            bytestr = "0x"
                        end
                    end

                    if #bytestr > 2 and #bytestr < 10 then
                        while #bytestr < 10 do
                            bytestr = bytestr .. "0"
                        end

                        data[#data + 1] = bytestr
                    end
                end
            end
        end
    end

    local s = split(path, "%.")
    local newName = s[1] .. ".in"
    local newFile = io.open(newName, "w+")

    for _, i in next, instr do
        newFile:write(i .. "\n")
    end

    newFile:write("DATA SEGMENT")

    for i, d in ipairs(data) do
        newFile:write("\n0x" .. string.format("%08x", 0x10010000 + (i - 1) * 4) .. " " .. d)
    end

    newFile:close()

    return "Compilation succeeded."
end

local input = ""
local mode = 0
print("\n(c) 2018 ApexDev (Micah Havens)")
print("Type \"q\" to quit.")

while input ~= "q" do
    io.write(">")
    io.flush()
    input = io.read()

    if input == "i" then
        print("Interactive mode.")
        mode = 0
    elseif input == "c" then
        print("Compiler mode.")
        mode = 1
    elseif input ~= "q" then
        if mode == 0 then
            local res = convertInstr(input)
            for _, instr in next, res do
                print(instr)
            end
        elseif mode == 1 then
            print(compile(input))
        end
    end
end