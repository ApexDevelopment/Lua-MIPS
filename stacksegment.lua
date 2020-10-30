-- stacksegment.lua

StackSegment = Memory:extend()

function StackSegment:new(size, start)
    if size and start then
        StackSegment.super.new(self, size, start)
    else
        -- 2 KB ending at 0x7FFFEFFF
        StackSegment.super.new(self, 2*1024, 2147479551 - 2*1024)
    end
end

function StackSegment:throwOverflowError()
    error("Stack segment memory overflow")
end