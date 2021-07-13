; MP2 - Your Name - Today's Date
;
;
; Josh Potts, Fall 2001
; Guest Authors: Michael Urman, Justin Quek
; University of Illinois, Urbana-Champaign
; Dept. of Electrical and Computer Engineering
;
; Version 1.0

	BITS	16

;====== SECTION 1: Define constants =======================================

	BS	    EQU 8
        CR          EQU 0Dh
        LF          EQU 0Ah
        BEL         EQU 07h
	TBUF_SIZE   EQU 79

;====== SECTION 2: Declare external procedures ============================

; These are functions from lib291
EXTERN kbdin, dspout, dspmsg, ascbin, binasc, mp2xit

; You will be writing your own versions of these functions
EXTERN _libDoCommand, _libReadLine, _libGetLetter, _libGetNumber
EXTERN _libCalculateInterest, _libConvertCurrency
EXTERN _libFDRead, _libFDWrite, _libFDAdd, _libFDMul, _libFDPow

; The _lib functions need these to work properly
GLOBAL _DoCommand, _ReadLine, _GetLetter, _GetNumber
GLOBAL _CalculateInterest, _ConvertCurrency
GLOBAL _FDRead, _FDWrite, _FDAdd, _FDMul, _FDPow
GLOBAL tbuf, pbuf, binascbuf
GLOBAL principle, interest, periods, result
GLOBAL numbuf1, numbuf2
GLOBAL msg_help, msg_error, msg_result, msg_crlf
GLOBAL tab_from, tab_to

;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK                    ; *** STACK SEGMENT ***
        resb      64*8
stacktop:
	resb 0

;====== SECTION 4: Define code segment ====================================

SEGMENT code                            ; *** CODE SEGMENT ***

;====== SECTION 5: Declare variables for main procedure ===================
tbuf		resb TBUF_SIZE
pbuf            resb 10
binascbuf	resb 7
principle	resd 1
interest	resd 1
periods		resd 1
result		resd 1
numbuf1		resd 1
numbuf2		resd 1

msg_help	db CR, LF, 'Perform an Interest calculation by entering'
		db CR, LF, '  i <principle> <interest rate> <periods>'
		db CR, LF
		db CR, LF, 'Perform a currency conversion by entering'
		db CR, LF, '  c <from> <to> <principle>'
		db CR, LF, ' where <from> and <to> are one of the letters:'
		db CR, LF, '  c d e f g k l* m p q r s w* y z'
		db CR, LF, ' Letters with a star can only be <to>.'
		db CR, LF, '$'

msg_error	db CR, LF, ' ** ERROR **', CR, LF, '$'
msg_result	db CR, LF, ' The result is: ', '$'
msg_crlf	db CR, LF, '$'

; c = canada dollar
; d = us dollar
; e = euros
; f = france francs
; g = germany deutchmarks
; k = czech republic koruny
; l = italy lira
; m = mexico peso
; p = great britain pounds
; r = russia rubles
; s = israel new shekel
; w = south korea won
; y = japan yen

tab_from	dw 0, 0			; a, b
		dw from_canadian	; c
		dw from_dollar		; d
		dw from_euros		; e
		dw from_francs		; f
		dw from_deutsche	; g
		dw 0, 0, 0		; h, i, j
		dw from_koruny		; k
		dw 0			; l
		dw from_peso		; m 
		dw 0, 0			; n, o
		dw from_pound		; p
		dw 0			; q
		dw from_ruble		; r
		dw from_shekel		; s
		dw 0, 0, 0, 0, 0	; t, u, v, w, x
		dw from_yen		; y
		dw 0			; z
		
tab_to		dw 0, 0			; a, b
		dw to_canadian		; c
		dw to_dollar		; d
		dw to_euros		; e
		dw to_francs		; f
		dw to_deutsche		; g
		dw 0, 0, 0		; h, i, j
		dw to_koruny		; k
		dw to_lira		; l
		dw to_peso		; m 
		dw 0, 0			; n, o
		dw to_pound		; p
		dw 0			; q
		dw to_ruble		; r
		dw to_shekel		; s
		dw 0, 0, 0		; t, u, v
		dw to_won		; w
		dw 0			; x
		dw to_yen		; y
		dw 0			; z

from_canadian	dw	0, 64
from_dollar	dw	1, 0
from_euros	dw	0, 91
from_francs	dw	0, 14
from_deutsche	dw	0, 46
from_koruny	dw	0, 03
from_peso	dw	0, 11
from_pound	dw	1, 46
from_ruble	dw	0, 03
from_shekel	dw	0, 23
from_yen	dw	0, 01

to_canadian	dw	1, 56
to_dollar	dw	1, 0
to_euros	dw	1, 10
to_francs	dw	7, 23
to_deutsche	dw	2, 16
to_koruny	dw	37, 61
to_lira		dw	2133, 87
to_peso		dw	9, 29
to_pound	dw	0, 68
to_ruble	dw	29, 2
to_shekel	dw	4, 29
to_won		dw	1281, 0
to_yen		dw	120, 0


;====== SECTION 6: Program initialization =================================

..start:
        mov     ax, cs                  ; Initialize Default Segment register
        mov     ds, ax  
        mov     ax, stkseg              ; Initialize Stack Segment register
        mov     ss, ax
        mov     sp, stacktop            ; Initialize Stack Pointer register

;====== SECTION 7: Main procedure =========================================

MAIN:
	call	_DoCommand
	test	ax, ax
	jnz	MAIN
	
	call	mp2xit

;--------------------------------------------------------------------------
; DoCommand
;--------------------------------------------------------------------------
_DoCommand
	call	_libDoCommand
	ret

;--------------------------------------------------------------------------
; ReadLine
;--------------------------------------------------------------------------
_ReadLine
	call	_libReadLine
	ret

;--------------------------------------------------------------------------
; GetLetter
;--------------------------------------------------------------------------
_GetLetter
	call	_libGetLetter
	ret

;--------------------------------------------------------------------------
; GetNumber
;--------------------------------------------------------------------------
_GetNumber
	call	_libGetNumber
	ret

;--------------------------------------------------------------------------
; CalculateInterest
;--------------------------------------------------------------------------
_CalculateInterest
	call	_libCalculateInterest
	ret

;--------------------------------------------------------------------------
; ConvertCurrency
;--------------------------------------------------------------------------
_ConvertCurrency
	call	_libConvertCurrency
	ret

;--------------------------------------------------------------------------
; FDRead
;--------------------------------------------------------------------------
_FDRead
	call	_libFDRead
	ret

;--------------------------------------------------------------------------
; FDWrite
;--------------------------------------------------------------------------
_FDWrite
	call	_libFDWrite
	ret

;--------------------------------------------------------------------------
; FDAdd
;--------------------------------------------------------------------------
_FDAdd
	call	_libFDAdd
	ret

;--------------------------------------------------------------------------
; FDMul
;--------------------------------------------------------------------------
_FDMul
	call	_libFDMul
	ret

;--------------------------------------------------------------------------
; FDPow
;--------------------------------------------------------------------------
_FDPow
	call	_libFDPow
	ret
