TYPE := F4
SOURCES := src
INCLUDES := src

#EMULATORFLAGS := -type $(TYPE) -format pal
EMULATORFLAGS := -type $(TYPE) -format ntsc

# k65 F4 bank order (see system_a2600.nut): 45230167
MIX := 0BCDE567

################################################################################

EMULATOR      := stella
DASM          := dasm
K65			  := k65
# Change the K65 command to compile on Linux boxes using wine
# K65          := wine <path.to.k65.exe>

################################################################################

asmfiles := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.asm))
hfiles := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.h))
k65files := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.k65))

################################################################################

.SUFFIXES:
.PHONY: all run rundebug

all: demo.bin

demo.bin: program.bin main.bin
	tools/mixbin.lua $(MIX)
	cat main.sym program.sym > demo.sym

main.bin: $(SOURCES)/main.asm sincos_tables_0.5.asm sincos_tables_0.99.asm pic_invader.asm pic_atari.asm tunnel_tables.asm $(asmfiles) $(hfiles)
	$(DASM) $< -f3 -I$(INCLUDES) -o$@ -lmain.lst -smain.sym

program.bin: $(k65files) $(SOURCES)/files.lst
	$(K65) @${SOURCES}/files.lst

run: demo.bin
	$(EMULATOR) $(EMULATORFLAGS) demo.bin

rund: demo.bin
	$(EMULATOR) -debug $(EMULATORFLAGS) demo.bin

runm : main.bin
	$(EMULATOR) $(EMULATORFLAGS) main.bin

runmd: main.bin
	$(EMULATOR) -debug $(EMULATORFLAGS) main.bin

runk : program.bin
	$(EMULATOR) $(EMULATORFLAGS) program.bin

runkd: program.bin
	$(EMULATOR) -debug $(EMULATORFLAGS) program.bin

clean:
	rm -f demo.bin demo.sym program.bin program.lst program.sym main.bin main.lst main.sym
