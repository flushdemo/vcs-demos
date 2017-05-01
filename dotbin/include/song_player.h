#define PATTERN_NOTES_ZIK1 64
#define PATTERN_TIME_ZIK1 (64*2)
#define PATTERN_TIME_ZIK2 (64*3)

// Available music tracks (Init and Player methods)

// Set background color according to the beat
void bgcolor_beat(void);
// Get beat volume
unsigned char beat_vol(void);

void forward_tt_init(void);
void forward_tt_player(void);

void salami_tt_init(void);
void salami_tt_player(void);

void koniec_tt_init(void);
void koniec_tt_player(void);

extern unsigned char tt_envelope_index_c0;
extern unsigned char tt_envelope_index_c1;
extern unsigned char tt_cur_ins_c0;
extern unsigned char tt_cur_ins_c1;
extern unsigned char tt_cur_vol_c0;
extern unsigned char tt_cur_vol_c1;

extern unsigned char tt_timer;
extern unsigned char tt_cur_pat_index_c0;
extern unsigned char tt_cur_pat_index_c1;
extern unsigned char tt_cur_note_index_c0;
extern unsigned char tt_cur_note_index_c1;

#pragma zpsym ("tt_envelope_index_c0");
#pragma zpsym ("tt_envelope_index_c1");
#pragma zpsym ("tt_cur_ins_c0");
#pragma zpsym ("tt_cur_ins_c1");
#pragma zpsym ("tt_cur_vol_c0");
#pragma zpsym ("tt_cur_vol_c1");

#pragma zpsym ("tt_timer");
#pragma zpsym ("tt_cur_pat_index_c0");
#pragma zpsym ("tt_cur_pat_index_c1");
#pragma zpsym ("tt_cur_note_index_c0");
#pragma zpsym ("tt_cur_note_index_c1");
