	SEG.U	rotozoom_variables
	ORG 	#$80

;;; Address of picture to display
cur_pic		ds 2
;;; Address of tables to use
cur_sin		ds 2
cur_cos		ds 2
;;; FX variant
roto_fxvar	ds 2

;;; Position of the rectangle to project
rec_x		ds 1
rec_y		ds 1
;;; Direction of the rectangle to project
vec_x		ds 1
vec_y		ds 1
;;; Position of the line to project
line_x		ds 1
line_y		ds 1
;;; Position of the pixel to project
pix_x		ds 1
pix_y		ds 1

;;; Framebuffer and positions
frame_buffer	ds 72		; 24 lines * 3 bytes/line
angle		ds 1
angle_counter	ds 1		; Incrementing angle when counter is 0
angle_delay	ds 1		; The delay to initialize to counter to
trans_counter	ds 1		; Incrementing position when counter is 0
trans_delay	ds 1		; The delay to initialize to counter to
fb_pt		ds 1
fb_byte		ds 1		; Next byte type to process 0, 1 or 2

;;; Bits of bytes to compute
bits_tmp	ds 7
rz_tmp		ds 1		; Temporary storage used for bits manipulations

;;; Global variables
fx_counter	ds 2

;;; Display variables
line_pt 	ds 2
pf_hue		ds 1
pf_lum		ds 1
pf_dir		ds 1
