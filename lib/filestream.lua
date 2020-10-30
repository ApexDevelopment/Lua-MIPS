-- filestream.lua

FileStream = Object:extend()

function FileStream:new(input)
    self.Input = input
    self.Open = true
end

function FileStream:nextByte()
    if not self.Open then error("Stream has already closed.") end
    return string.byte(self.Input:read(1))
end

function FileStream:nextInt16()
    if not self.Open then error("Stream has already closed.") end
    local byte1, byte2 = self.Input:read(2):byte(1, 2)

    return byte2 * 256 + byte1
end

function FileStream:nextInt32()
    if not self.Open then error("Stream has already closed.") end
    local byte1, byte2, byte3, byte4 = self.Input:read(4):byte(1, 4)

    return byte4 * 16777216 + byte3 * 65536 + byte2 * 256 + byte1
end

function FileStream:nextChars(n)
    return self.Input:read(n)
end

function FileStream:close()
    self.Open = false
    self.Input:close()
end