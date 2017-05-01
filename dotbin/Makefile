#CC ?= clang

srcasm = $(wildcard common/asm/*.s bank*/asm/*.s bank7/asm/forward/*.s bank7/asm/salami/*.s bank7/asm/koniec/*.s)
srcinc = $(wildcard asminc/*.inc common/asm/*.inc)
srcc   = $(wildcard common/c/*.c   bank*/c/*.c)
srch   = $(wildcard include/*.h)
srck1  = $(wildcard *.k65 bank*/k65/*.k65)
srck2  = $(wildcard bank*/k65/*.k65)

genasm = $(patsubst %.c, %.s, $(srcc))
obj    = $(patsubst %.s, %.o, $(srcasm) $(genasm))
lst    = $(patsubst %.s, %.lst, $(srcasm) $(genasm))

# k65 F4 bank order (see system_a2600.nut): 45230167
MIX := AB2DEFGH

.SUFFIXES:

demo.bin: program.bin main.bin
	tools/mixbin.lua $(MIX)
	cat main.sym program.sym > demo.sym

main.bin: $(obj)
	ld65 -C atari2600.cfg -m $(patsubst %.bin, %.sym, $@) -vm -o $@ $(obj) atari2600.lib

program.bin: $(srck1) $(srck2) #tools/vcsconv
	#$(foreach f,$(srck2),tools/vcsconv update $(f))
	k65 @k65files.lst

tools/vcsconv: tools/vcsconv.c
	$(CC) -std=c99 -fno-strict-aliasing $< -lm -o $@

%.s: %.c $(srch)
	cc65 -I include/ -T -t atari2600 $<

%.o %.lst: %.s $(srcinc)
	ca65 -I asminc/ -g -l $(patsubst %.s, %.lst, $<) $<

clean:
	rm -f $(obj) $(genasm) $(lst) demo.bin demo.sym main.bin main.sym program.bin program.sym program.lst
	find . -name "*~" -exec rm {} \;

run: demo.bin
	stella demo.bin

rund: demo.bin
	stella -debug demo.bin

runm: main.bin
	stella main.bin

runk: program.bin
	stella program.bin

runkd: program.bin
	stella -debug program.bin

vidrec: demo.bin
	mame64 a2600p -nofilter -aviwrite demo.avi -cart demo.bin

vidstretch:
	ffmpeg -i snap/demo.avi -c:a copy -c:v rawvideo -vf scale=iw*2:ih:flags=neighbor snap/demo_stretched.avi
