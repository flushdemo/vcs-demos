.macro mBankCall fn
	ldy 	#0
	lda 	#>fn
	dec 	sp
	sta 	(sp),Y
	lda 	#<fn
	dec 	sp
	sta 	(sp),Y
	jsr 	_bankCall
.endmacro

.macro mBankJump fn
	ldy 	#0
	lda 	#>fn
	dec 	sp
	sta 	(sp),Y
	lda 	#<fn
	dec 	sp
	sta 	(sp),Y
	jmp 	_bankCall
.endmacro

.macro mDirectBankCall addr
    lda #<@return
    sec
    sbc #1
    tax
    lda #>@return
    sbc #0
    pha
    txa
    pha
    lda #>addr
    pha
    lda #<addr
    pha
    jmp _bankReturn
@return:
.endmacro

.macro mDirectBankCallPtr ptr
    lda #<@return
    sec
    sbc #1
    tax
    lda #>@return
    sbc #0
    pha
    txa
    pha
    lda ptr+1
    sec
    sbc #1
    tax
    lda ptr
    sbc #0
    pha
    txa
    pha
    jmp _bankReturn
@return:
.endmacro

.macro mDirectBankCallPtrNoRet ptr
    lda ptr+1
    sec
    sbc #1
    tax
    lda ptr
    sbc #0
    pha
    txa
    pha
    jmp _bankReturn
.endmacro

.macro mDirectBankCallPtrNoRetPrepare ptr
    lda ptr+1
    sec
    sbc #1
    tax
    lda ptr
    sbc #0
    pha
    txa
    pha
.endmacro
