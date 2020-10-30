-- textsegment.lua

TextSegment = Memory:extend()

function TextSegment:new(start, size)
    if start and size then
        TextSegment.super.new(self, start, size)
    else
        -- 2 KB starting at 0x00400000
        TextSegment.super.new(self, 2*1024, 0x00400000)
    end
end

function TextSegment:throwOverflowError()
    error("Text segment memory overflow")
end

function TextSegment:getStart()
    return self.start
end

-- runs given command from text segment memory
-- increments pc by 4 when appropriate
function TextSegment:run(mips, printCmd)
    local loc = mips.reg.pc
    mips.reg.pc = loc + 4
    local cmd = ""

    --print(loc)
    -- figure out what type it is
    local opcode = self:getBits(loc, 26, 31, false)
    local rs, rt, rd, immed, shamt, func, addr, immedU, addrU
    --print("instr: " .. string.format("%08x", self:getBits(loc, 0, 31, false)), "opcode: " .. opcode)

    if opcode == 0 then -- R-type
        rs = self:getBits(loc, 21, 25, false)
        rt = self:getBits(loc, 16, 20, false)
        rd = self:getBits(loc, 11, 15, false)
        func = self:getBits(loc, 0, 5, false)
        --print("func: " .. string.format("%02x", func))

        if func == 0 then -- SLL
            shamt = self:getBits(loc, 6, 10, false)
            cmd = "SLL $" .. rd .. " = $" .. rt .. " << " .. shamt
            mips.reg:set(rd, bit.lshift(mips.reg:get(rt), shamt))
        elseif func == 2 then -- SRL
            shamt = self:getBits(loc, 6, 10, false)
            cmd = "SRL $" .. rd .. " = $" .. rt .. " >>> " .. shamt
            mips.reg:set(rd, bit.rshift(mips.reg:get(rt), shamt))
        elseif func == 3 then -- SRA
            shamt = self:getBits(loc, 6, 10, false)
            cmd = "SRA $" .. rd .. " = $" .. rt .. " >> " .. shamt
            mips.reg:set(rd, bit.srshift(mips.reg:get(rt), shamt))
        elseif func == 8 then -- JR
            cmd = "JR $" .. rs

            if mips.reg:get(rs) == 4294967295 then
                return -1
            end

            mips.reg.pc = mips.reg:get(rs)
        elseif func == 10 then -- MOVZ
            cmd = "MOVZ $" .. rt .. ", $" .. rs .. ", $" .. rt

            if mips.reg:get(rt) == 0 then
                mips.reg:set(rd, mips.reg:get(rs))
            end
        elseif func == 12 then -- SYSCALL
            local n = mips.reg:get(2)
            cmd = "syscall " .. n

            if n == 1 then -- print integer
                io.write("" .. mips.reg:get(4)) -- get corrector register
                io.flush()
            elseif n == 3 then
                io.write("" .. mips.reg:get(4))
                io.flush()
            elseif n == 4 then -- print string
                local strIncomplete = true
                local l = mips.reg:get(4)

                while strIncomplete do
                    local x = mips:getMemoryByte(l, 0, false)

                    if x == 0 then
                        strIncomplete = false
                    else
                        io.write(string.char(x))
                        l = l + 1
                    end
                end

                io.flush()
            elseif n == 5 then -- read int
                local temp = CPU.getUserInput("")
                local t = 0

                local w, e = pcall(function()
                    t = math.floor(tonumber(temp))
                    mips.reg:set(2, t)
                end)

                if not w then
                    mips.reg:set(2, 0)
                end
            elseif n == 8 then -- read string
                local temp = CPU.getUserInput("")
                local i = 1
                local sloc = mips.reg:get(4)

                while i <= #temp and i < mips.reg:get(5) do
                    local val = string.byte(temp:sub(i, i))
                    mips:setMemoryByte(sloc + (i - 1), 0, val)
                    i = i + 1
                end
            elseif n == 10 then -- exit
                return -1
            end
        elseif func == 16 then -- MFHI
            cmd = "MFHI $" .. rd .. " = $HI"
            mips.reg:set(rd, mips.reg:get("HI"))
        elseif func == 18 then -- MFLO
            cmd = "MFLO $" .. rd .. " = $LO"
            mips.reg:set(rd, mips.reg:get("LO"))
        elseif func == 24 then -- signed multiply
            cmd = "MULT ($LO, $HI) = $" .. rs .. " x $" .. rt
            local l1 = mips.reg:get(rs)
            local l2 = mips.reg:get(rt)
            local m = l1 * l2
            local lo = bit.rshift(bit.lshift(m, 32), 32)
            local hi = bit.rshift(m, 32)
            mips.reg:set("LO", lo)
            mips.reg:set("HI", hi)
        elseif func == 25 then
            -- TODO: make sure overflow/underflow works properly (multU32, addU32, subU32, etc)
            -- maybe make library for it?
            cmd = "MULTU $LO = $" .. rs .. " x $" .. rt
            mips.reg:set("LO", mips.reg:get(rs) * mips.reg:get(rt))
        elseif func == 32 then -- add with overflow
            cmd = "ADD $" .. rd .. " = $" .. rs .. " + $" .. rt
            mips.reg:set(rd, math32.add(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 33 then
            cmd = "ADDU $" .. rd .. " = $" .. rs .. " + $" .. rt
            mips.reg:set(rd, math32.add(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 34 then
            cmd = "SUB $" .. rd .. " = $" .. rs .. " - $" .. rt
            mips.reg:set(rd, math32.sub(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 35 then
            cmd = "SUBU $" .. rd .. " = $" .. rs .. " - $" .. rt
            mips.reg:set(rd, math32.sub(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 36 then
            cmd = "AND $" .. rd .. " = $" .. rs .. " & $" .. rt
            mips.reg:set(rd, bit.band(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 37 then
            cmd = "OR $" .. rd .. " = $" .. rs .. " | $" .. rt
            mips.reg:set(rd, bit.bor(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 38 then
            cmd = "XOR $" .. rd .. " = $" .. rs .. " ^ $" .. rt
            mips.reg:set(rd, bit.bxor(mips.reg:get(rs), mips.reg:get(rt)))
        elseif func == 39 then
            cmd = "NOR"
            mips.reg:set(rd, bit.bnot(bit.bor(mips.reg:get(rs), mips.reg:get(rt))))
        elseif func == 42 then
            cmd = "SLT if $" .. rs .. " < $" .. rt .. " ? $" .. rd .. " = 1 : $" .. rd .. " = 0"

            local val1 = mips.reg:get(rs)
            local val2 = mips.reg:get(rt)

            --local val1neg = val1 >= bit.neg
            --local val2neg = val2 >= bit.neg

            --if (val1neg and not val2neg) or (not val1neg and not val2neg and val1 < val2) or (val1neg and val2neg and val1 > val2) then
            if mips.presentableSigned(val1) < mips.presentableSigned(val2) then
                mips.reg:set(rd, 1)
            else
                mips.reg:set(rd, 0)
            end
        elseif func == 43 then
            cmd = "SLTU if $" .. rs .. " < $" .. rt .. " ? $" .. rd .. " = 1 : $" .. rd .. " = 0"

            -- unsigned comparison
            if mips.reg:get(rs) < mips.reg:get(rt) then
                mips.reg:set(rd, 1)
            else
                mips.reg:set(rd, 0)
            end
        else
            cmd = "OTHER R INSTRUCTION: " .. opcode .. " -- " .. func
        end
    else -- I-type and J-type have to be considered together
        rs = self:getBits(loc, 21, 25, false)
        rt = self:getBits(loc, 16, 20, false) -- I-type
        immed = self:getBits(loc, 0, 15)
        immedU = self:getBits(loc, 0, 15, false)
        addr = self:getBits(loc, 0, 25) -- J-type
        addrU = self:getBits(loc, 0, 25, false)

        if opcode == 1 then
            if rt == 1 then
                cmd = "BGEZ $" .. rs .. ", " .. mips.presentableSigned(immed)

                if mips.reg:get(rs) < bit.neg then
                    mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2))
                end
            elseif rt == 0 then
                cmd = "BLTZ $" .. rs .. ", " .. mips.presentableSigned(immed)

                if mips.reg:get(rs) >= bit.neg then
                    mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2))
                end
            end
        elseif opcode == 2 then
            cmd = "J " .. addrU
            mips.reg.pc = bit.bor(bit.band(mips.reg.pc - 4, 4026531840), bit.lshift(addrU, 2))
        elseif opcode == 3 then
            cmd = "JAL " .. addrU
            mips.reg:set(31, mips.reg.pc)
            mips.reg.pc = bit.bor(bit.band(mips.reg.pc - 4, 4026531840), bit.lshift(addrU, 2))
        elseif opcode == 4 then
            cmd = "BEQ $" .. rs .. ", $" .. rt .. ", " .. mips.presentableSigned(immed)

            if mips.reg:get(rs) == mips.reg:get(rt) then
                mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2))
            end
        elseif opcode == 5 then
            cmd = "BNE $" .. rs .. ", $" .. rt .. ", " .. mips.presentableSigned(immed)

            if mips.reg:get(rs) ~= mips.reg:get(rt) then
                mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2)) -- TODO: use this everywhere
            end
        elseif opcode == 6 then
            cmd = "BLEZ $" .. rs .. ", " .. mips.presentableSigned(immed)

            local rsval = mips.reg:get(rs)
            if rsval == 0 or rsval >= bit.neg then
                mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2))
            end
        elseif opcode == 7 then
            cmd = "BGTZ $" .. rs .. ", " .. mips.presentableSigned(immed)

            local rsval = mips.reg:get(rs)
            if rsval > 0 and rsval < bit.neg then
                mips.reg.pc = math32.add(mips.reg.pc - 4, bit.lshift(immed, 2))
            end
        elseif opcode == 8 then
            -- TODO: Add trap exception/exceptions in general?
            cmd = "ADDI $" .. rt .. " = $" .. rs .. " + " .. mips.presentableSigned(immed)
            mips.reg:set(rt, math32.add(mips.reg:get(rs), immed))
        elseif opcode == 9 then
            cmd = "ADDIU $" .. rt .. " = $" .. rs .. " + " .. mips.presentableSigned(immed)
            mips.reg:set(rt, math32.add(mips.reg:get(rs), immed))
        elseif opcode == 10 then
            cmd = "SLTI if $" .. rs .. " < " .. mips.presentableSigned(immed) .. " ? $" .. rt .. " = 1 : $" .. rt .. " = 0"

            local val = mips.reg:get(rs)
            --local neg = val >= bit.neg
            --local immneg = immed >= bit.neg

            -- todo: maybe make signed comparison function
            --if (neg and not immneg) or (not neg and not immneg and val < immed) or (neg and immneg and val > immed) then
            if mips.presentableSigned(val) < mips.presentableSigned(immed) then
                mips.reg:set(rt, 1)
            else
                mips.reg:set(rt, 0)
            end
        elseif opcode == 11 then
            cmd = "SLTIU if $" .. rs .. " < " .. mips.presentableSigned(immed) .. " ? $" .. rt .. " = 1 : $" .. rt .. " = 0"

            -- unsigned comparison
            if mips.reg:get(rs) < immed then
                mips.reg:set(rt, 1)
            else
                mips.reg:set(rt, 0)
            end
        elseif opcode == 12 then
            cmd = "ANDI"
            mips.reg:set(rt, bit.band(mips.reg:get(rs), immed))
        elseif opcode == 13 then
            cmd = "ORI $" .. rt .. " = $" .. rs .. " | " .. immedU
            mips.reg:set(rt, bit.bor(mips.reg:get(rs), immedU))
        elseif opcode == 15 then
            cmd = "LUI $" .. rt .. ", " .. immedU
            mips.reg:set(rt, bit.lshift(immedU, 16))
        elseif opcode == 32 then
            cmd = "LB $" .. rt .. " = MEM[$" .. rs .. " + " .. mips.presentableSigned(immed) .. "]"
            mips.reg:set(rt, mips:getMemoryByte(mips.reg:get(rs), immed, true))
        elseif opcode == 35 then
            cmd = "LW $" .. rt .. " = MEM[$" .. rs .. " + " .. mips.presentableSigned(immed) .. "]"
            mips.reg:set(rt, mips:getFromMemory(mips.reg:get(rs), immed))
        elseif opcode == 36 then
            cmd = "LBU $" .. rt .. " = MEM[$" .. rs .. " + " .. mips.presentableSigned(immed) .. "]"
            mips.reg:set(rt, mips:getMemoryByte(mips.reg:get(rs), immed, false))
        elseif opcode == 40 then
            cmd = "SB MEM[$" .. rs .. " + " .. mips.presentableSigned(immed) .. "] = $" .. rt
            mips:setMemoryByte(mips.reg:get(rs), immed, mips.reg:get(rt))
        elseif opcode == 43 then
            cmd = "SW MEM[$" .. rs .. " + " .. mips.presentableSigned(immed) .. "] = $" .. rt
            mips:setMemory(mips.reg:get(rs), immed, mips.reg:get(rt))
        else
            cmd = "OTHER I OR J: " .. opcode .. " -- " .. string.format("%08x", opcode)
        end
    end

    if printCmd and cmd ~= "" then
        print(cmd)
    end

    return 0
end