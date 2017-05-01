.mac m_reset
	sta	vect + 7	; Switch to bank7
	jmp	_start
.endmac

.mac m_vectors
.byte $f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb
.word reset ; Reset
.word reset ; IRQ
.endmac
