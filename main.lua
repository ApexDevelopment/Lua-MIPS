-- main.lua
-- Only purpose rn is to start the emulator
-- By ApexDev

function string.split(str,sep)
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

-- work in progress function for parsing elf files, not used ATM
function parseELFMIPS(stream)
    assert(stream:nextByte() == 0x7F and stream:nextChars() == "ELF", "Magic number is incorrect.")
    assert(stream:nextByte() == 1, "File is not 32-bit.")
    assert(stream:nextByte() == 1, "File is not little-endian.")

    local e = {
        FileHeader = {
            OriginalELF = stream:nextByte() == 1,
            TargetABI = stream:nextByte(),
            ABIVersion = stream:nextByte(),
            Pad = stream:nextChars(7),
            FileType = stream:nextInt16(),
            TargetArchitecture = stream:nextInt16(),
            Version = stream:nextByte(),
            Entry = stream:nextInt32(),
            PHOff = stream:nextInt32(),
            SHOff = stream:nextInt32(),
            Flags = stream:nextInt32(),
            EHSize = stream:nextInt16(),
            PHEntSize = stream:nextInt16(),
            PHNum = stream:nextInt16(),
            SHEntSize = stream:nextInt16(),
            SHNum = stream:nextInt16(),
            SHStrNdx = stream:nextInt16()
        },
        ProgramHeader = {},
        SectionHeader = {}
    }

    stream.Input:seek("set", e.FileHeader.PHOff)

    for i = 1, e.FileHeader.PHNum do
        table.insert(e.ProgramHeader, {
            Type = stream:nextInt32(),
            Offset = stream:nextInt32(),
            VAddr = stream:nextInt32(),
            FileSz = stream:nextInt32(),
            MemSz = stream:nextInt32(),
            Flags = stream:nextInt32(),
            Align = stream:nextInt32()
        })

        local entry = e.ProgramHeader[#e.ProgramHeader]

        assert(entry.Align == 0 or entry.Align == 1 or entry.VAddr == entry.Offset % entry.Align, "Program header segment alignment error.")
    end

    stream.Input:seek("set", e.FileHeader.SHOff)

    for i = 1, e.FileHeader.SHNum do
        table.insert(e.SectionHeader, {
            Name = stream:nextInt32(),
            Type = stream:nextInt32(),
            Flags = stream:nextInt32(),
            Addr = stream:nextInt32(),
            Offset = stream:nextInt32(),
            Size = stream:nextInt32(),
            Link = stream:nextInt32(),
            Info = stream:nextInt32(),
            AddrAlign = stream:nextInt32(),
            EntSize = stream:nextInt32()
        })

        local entry = e.SectionHeader[#e.SectionHeader]

        assert(entry.AddrAlign % 2 == 0, "Section header segment alignment error.")
    end

    assert(e.FileHeader.TargetArchitecture == 0x08, "File was not compiled for MIPS.")

    stream:close()
    return e
end

Object = require "lib/classic"
require "lib/filestream"
require "lib/bitops"
require "lib/math32"
require "registers"
require "memory"
require "datasegment"
require "textsegment"
require "stacksegment"
require "cpu"

--local ELF = parseELFMIPS(FileStream(io.open("test.elf")))

cpu = CPU()