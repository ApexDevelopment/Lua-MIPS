-- registers.lua

Registers = Object:extend()

function Registers:new()
    print("Initializing registers.")

    self.r = {}
    self.HI = 0
    self.LO = 0
    self.pc = 0

    for i = 1, 32 do
        self.r[i] = 0
    end

    print("Done.")
end

function Registers:get(name)
    if type(name) == "string" then
        if name:lower() == "hi" then
            return self.HI
        elseif name:lower() == "lo" then
            return self.LO
        elseif name:lower() == "oc" then
            return self.pc
        else
            error("Unknown register get: " .. name)
            return -1
        end
    elseif type(name) == "number" then
        return self.r[name + 1]
    else
        error("Invalid register get.")
    end
end

function Registers:set(name, value)
    if type(name) == "string" then
        if name:lower() == "hi" then
            self.HI = value
        elseif name:lower() == "lo" then
            self.LO = value
        elseif name:lower() == "oc" then
            self.pc = value
        else
            error("Unknown register set: " .. name .. " <- " .. tostring(value))
            return -1
        end
    elseif type(name) == "number" then
        if name == 0 then return end
        self.r[name + 1] = value
    else
        error("Invalid register set: " .. tostring(name))
    end
end

function Registers:printReg(i)
    if type(i) == "number" then
        print("$" .. tostring(i) .. " = 0x" .. string.format("%08x", self.r[i + 1]):upper())
    elseif type(i) == "string" then
        if i:lower() == "lo" then
            print("$LO = 0x" .. string.format("%08x", self.LO):upper())
        elseif i:lower() == "hi" then
            print("$HI = 0x" .. string.format("%08x", self.HI):upper())
        elseif i:lower() == "pc" then
            print("$PC = 0x" .. string.format("%08x", self.pc):upper())
        end
    end
end

function Registers:printAll()
    for i = 0, 31 do
        self:printReg(i)
    end

    self:printReg("hi")
    self:printReg("lo")
    self:printReg("pc")
end