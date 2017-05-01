; Code to call a function in any bank
.mac m_bankCall
; Address high byte in X
; Address low byte in A
; Pushing address to jump -1 to in system stack
	popax
	sec
	sbc #1
	tay
	txa
	sbc #0
	pha			; Push high byte first
	tya
	pha			; Then low byte
.endmac

.mac m_bankReturn
	tsx
	lda $02,X		; Get return address high byte
	.repeat 5		; Getting 3 MSB
	lsr
	.endrep
	tax
	sta vect,X		; Switch to appropriate bank
	rts			; Call Function
.endmac
