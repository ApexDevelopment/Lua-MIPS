-- datasegment.lua

DataSegment = Memory:extend()

function DataSegment:new(size, start)
    if size and start then
        DataSegment.super.new(self, size, start)
    else
        -- 4 KB starting at 0x10010000
        DataSegment.super.new(self, 4*1024, 0x10010000)
    end
end

function DataSegment:throwOverflowError()
    error("Data segment memory overflow")
end