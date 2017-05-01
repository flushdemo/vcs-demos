#!/usr/bin/env lua

if #arg ~= 1 then
    print('mixbin - mix VCS binaries')
    print('usage: mixbin <8 chars>')
    print('  Banks marked with a digit are taken from program.bin,')
    print('  those marked with a letter are taken from main.bin.')
    print('example: mixbin A5BCD1H3')
    print('  main.bin:0, program.bin:5, ...')
    os.exit(true)
end

local mix = arg[1]
assert(#mix == 8)

local bin0f, bin1f = assert(io.open('program.bin', 'rb')), assert(io.open('main.bin', 'rb'))
local bin0, bin1 = {}, {}
for i=1,8 do
    bin0[i] = assert(bin0f:read(4096))
    bin1[i] = assert(bin1f:read(4096))
end
bin0f:close()
bin1f:close()

local out = assert(io.open('demo.bin', 'wb'))
for i=1,8 do
    local c,d = mix:sub(i,i)
    if c >= 'A' then d=bin1[c:byte()-string.byte('A')+1]
    else d=bin0[c:byte()-string.byte('0')+1] end
    out:write(d)
end
out:close()
