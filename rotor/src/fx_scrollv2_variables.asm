	SEG.U	scrollv2_variables
	ORG 	#$80

;;; Framebuffer to prepare scrolling text
fb0	ds 8
fb1	ds 8
fb2	ds 8
fb3	ds 8
fb4	ds 8
fb5	ds 8

;;; Indexes into our data
scr_line_pt	ds 2	      ; 16 bits pointer to current character line
scr_text_pt	ds 2	      ; Index of last text character displayed
line_cnt	ds 1

;;; Background
bg_idx_hi	ds 1
bg_idx_lo	ds 1
bg_vec_hi	ds 1
bg_vec_lo	ds 1
bg_sta_hi	ds 1
bg_sta_lo	ds 1

;;; Temporary storage to consume line bits
cur_line	ds 1
frame_cnt	ds 1

;;; Colors
col_start	ds 1

;;; Temporary
cur_offset	ds 1
tmp_var		ds 1
