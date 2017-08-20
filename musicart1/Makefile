CC ?= clang

songs = $(wildcard *_trackdata.k65)
song_players = $(wildcard song_player?.k65)

program.bin: k65files.lst vcsconv main.k65 banks.k65 common.k65 print.k65 songs.k65 gfx_bg.k65 gfx_blaster_a.k65 gfx_blaster_b.k65 gfx_intro.k65 gfx_intro_data.k65 $(song_players) $(songs)
	./vcsconv update songs.k65
	./vcsconv update gfx_blaster_a.k65
	./vcsconv update gfx_blaster_b.k65
	./vcsconv update gfx_intro_data.k65
	k65 @k65files.lst

vcsconv: vcsconv.c
	$(CC) -std=c99 -fno-strict-aliasing $< -lm -o $@

clean:
	rm -f program.bin program.lst program.sym vcsconv.exe vcsconv

run: program.bin
	stella program.bin

rund: program.bin
	stella -debug program.bin

vidrec: program.bin
	mame64 a2600p -nofilter -aviwrite demo.avi -cart program.bin

vidstretch:
	ffmpeg -y -i snap/demo.avi -strict -2 scale=iw*2:ih:flags=neighbor -crf 23 -preset veryslow -pix_fmt yuv420p demo.mp4
