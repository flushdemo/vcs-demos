	.include "atari2600.inc"
	.include "zeropage.inc"
	.include "popax.inc"
	.include "mBankCall.inc"
	.include "song_player.inc"

	;; Macro definitions
	.include "bankswitch.inc"
	.include "reset.inc"
	.include "sync.inc"

	.export	_bankCall, _bankReturn, _cBankCall
	.export _wait_overscan, _wait_vblank

	.import _start


;;; Setting a couple of symbols in bank0
.segment "COMMON"
_bankCall:
	m_bankCall
_bankReturn:
	m_bankReturn
_cBankCall:
	lda #>_bankReturn
	pha
	lda #(<_bankReturn - 1)
	pha
	jmp _bankCall
_wait_overscan:
	m_wait_overscan
_wait_vblank:
	m_wait_vblank
reset:
	m_reset
.segment "VECTORS0"
vect:
	m_vectors

.segment "VECTORS1"
	m_vectors
.segment "VECTORS2"
	m_vectors
.segment "VECTORS3"
	m_vectors
.segment "VECTORS4"
	m_vectors
.segment "VECTORS5"
	m_vectors
.segment "VECTORS6"
	m_vectors
.segment "VECTORS7"
	m_vectors
