	SEG.U	tunnel_variables
	ORG 	#$80

tunx	ds 1
tunfc	ds 2			; 16 bits frames counter
tuntm	ds 2			; Storing next variant start time

;;; Tunnel variant
tunvar	ds 1			; Tunnel variant
tuntbl	ds 2			; Tunnel table to use
tuntxt	ds 2			; Tunnel texture to use

; sprite
tuntmp  ds 2
tunptr  ds 12
