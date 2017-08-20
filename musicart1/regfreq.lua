local wavelen_map = { 1, 2, 6, 15, 31, 93, 465, 511 }
local freq_ranges = { 30, 60, 120, 240, 480, 960, 1920, 9999999 }
for i=0,255 do
    local wavelen = wavelen_map[(i>>5)+1]
    local note = (i&31)+1
    local freq = 3546894 / 114 / wavelen / note
    for x=1,9 do
        if freq <= freq_ranges[x] then
            io.write((x-1) .. " ")
            break
        end
    end
    if (i+1)%16 == 0 then io.write("\n") end
end
io.write("\n")
