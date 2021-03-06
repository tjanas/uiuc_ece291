; MP2 - Terrence B. Janas - September 23, 2001
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
; DoCommand								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: ax = 1 to continue or 0 to quit				  ;
;									  ;
;   Calls: dspmsg, ReadLine, GetLetter, GetNumber, CalculateInterest,	  ;
;          ConvertCurrency, FDWrite					  ;
;									  ;
;   Purpose: gets and processes a command, reporting the result		  ;
;--------------------------------------------------------------------------
_DoCommand
					; call	_libDoCommand
					; ret

 push bx				; Save register values
 push cx
 push dx
 push si
 push di

 ;------
 .Start:
 ;------
	mov ax, TBUF_SIZE		; Setup typing buffer
	mov bx, tbuf
	call _ReadLine			; Keep reading line until characters
	test ax, ax			; are inputted
	jz .Start

	call _GetLetter			; Quit program if 'q' is pressed
	cmp al, 'q'			; Convert currency if 'c' is pressed
	je .End				; Calculate interest if 'i' is pressed

	cmp al, 'c'
	je .ConvertCurrency

	cmp al, 'i'
	je .CalculateInterest

	cmp al, 'a'			; Display help message if other
	jl .Error			; letters are pressed, and display
	cmp al, 'z'			; error message for non-letters
	jg .Error

	mov dx, msg_help
	call dspmsg
	mov al, 1
	jmp .Exit

 ;----
 .End:
 ;----
	xor ax, ax			; To exit the program, ax must equal 0

 ;----
 .Exit:
 ;----
	pop di				; Restore original register values
	pop si
	pop dx
	pop cx
	pop bx
	ret

 ;----------------
 .ConvertCurrency:
 ;----------------
	call _GetLetter			; Grab "convert from" type
	test ax, ax
	jz .Error
	mov dh, al

	call _GetLetter			; Grab "convert to" type
	test ax, ax
	jz .Error
	mov dl, al

	mov di, principle		; Grab amount you wish to convert
	call _GetNumber
	test ax, ax
	jz .Error

	call _ConvertCurrency		; and store the converted value
	test ax, ax			; in [result]
	jz .Error

 ;------------
 .PrintAmount:
 ;------------
	mov dx, msg_result		; Print a text string and the
	call dspmsg			; FDNumber that is stored in result
	mov bx, pbuf
	mov si, result
	call _FDWrite
	mov dx, bx
	call dspmsg
	mov dx, msg_crlf
	call dspmsg
	mov al, 1
	jmp .Exit

 ;------
 .Error:
 ;------
	mov dx, msg_error		; Print error message if ax indicated
	call dspmsg			; an error occured. Set ax to nonzero
	mov al, 1			; value to indicate not to quit
	jmp .Exit

 ;------------------
 .CalculateInterest:
 ;------------------
	mov di, principle		; Grab the principle
	call _GetNumber
	test ax, ax
	jz .Error

	mov di, interest		; Grab the interest
	call _GetNumber
	test ax, ax
	jz .Error

	mov di, periods			; Grab the periods
	call _GetNumber
	test ax, ax
	jz .Error

	call _CalculateInterest		; and store the result of compound
	test ax, ax			; interest in [result]
	jz .Error
	jmp .PrintAmount



;--------------------------------------------------------------------------
; ReadLine								  ;
;   Inputs: ax = size of the buffer					  ;
;           bx = offset of the buffer					  ;
;									  ;
;   Outputs: ax = number of characters in the buffer (excluding '$')	  ;
;            buffer at bx holds the typed characters			  ;
;									  ;
;   Calls: dspout, kbdin, dspmsg					  ;
;									  ;
;   Purpose: take keyboard entry from the user, handling backspace	  ;
;            and bounds							  ;
;--------------------------------------------------------------------------
_ReadLine
			;call	_libReadLine
			;ret
 push cx
 push dx
 push si

 xor dx, dx		; Let dx = number of characters... Initially = 0
 mov cx, ax		; Let cx = buffer size
 dec cx			; Decrement cx to allow space for '$' at the end

 push dx
 mov al, '>'
 mov dl, al		; Print a > to screen but do not display in buffer
 call dspout
 pop dx

 mov al, ' '
 dec word dx		; The Display sub-routine automatically increments dx
			; Since this ' ' should not count as a character in
 jmp .Display		; the buffer, decrement dx ahead of time

 ;------
 .Start:
 ;------
	cmp dx, cx		; Check if buffer is full (overflow)
	je .Overflow
	
	call kbdin
	cmp al, ' '
	jne .BackSpace
	mov word si, dx
	mov byte [bx + si], al	; Write a space at location of cursor
	jmp .Display

 ;------
 .Enter:
 ;------
	cmp al, 13			; If ENTER is pressed, put '$'
	jne .NumberCheck		; in the buffer and exit
	mov word si, dx
	mov byte [bx + si], '$'
	jmp .Exit

 ;----------
 .BackSpace:
 ;----------
	cmp al, 8		; To delete a character on the screen,
	jne .Enter		; display a BACKSPACE, a SPACE, and
	test dx, dx		; another BACKSPACE to move back.
	jz .Underflow		; Check if user presses BACKSPACE at beginning
				; of the buffer.
	push dx
	mov dl, al
	call dspout
	
	mov dl, ' '
	call dspout

	mov dl, al
	call dspout
	pop dx
	
	dec word dx			; Decrement buffer, since we
	mov word si, dx			; deleted a character
	mov byte [bx + si], ' '
	jmp .Start

 ;---------
 .Overflow:
 ;---------
	push dx
	mov dl, 7		; When the user presses a normal key and
	call dspout		; the buffer is full, ReadLine must BEEP
	pop dx			; and not modify the buffer's contents

	call kbdin
	cmp al, 8		; Check if user pressed BACKSPACE
	je .BackSpace

	cmp al, 13		; When the user presses ENTER, must
	jne .Overflow		; place $ at the spot where CR would go

	mov byte [bx+1], '$'	; and return with appropriate outputs
	jmp .Exit

 ;----------
 .Underflow:
 ;----------
	push dx				; If user tries to BACKSPACE at
	mov dl, 7			; beginning of buffer, then BEEP
	call dspout
	pop dx
	jmp .Start

 ;------------
 .NumberCheck:
 ;------------
	cmp al, '.'		; Check if input is a valid character
	je .Display		; to print to the screen. Valid input
	cmp al, '0'		; characters are the characters 0-9,
	jl .CharacterCheck	; a-z, and '.'
	cmp al, '9'
	jle .Display

 ;---------------
 .CharacterCheck:
 ;---------------
	cmp al, 'a'
	jl .Start
	cmp al, 'z'
	jg .Start
	
 ;--------
 .Display:
 ;--------
	mov word si, dx
	mov byte [bx + si], al		; Print to the screen
	inc dx
	push dx
	mov dl, al
	call dspout
	pop dx
	jmp .Start

 ;-----
 .Exit:
 ;-----
	mov ax, dx
	pop si
	pop dx
	pop cx
	ret



;--------------------------------------------------------------------------
; GetLetter								  ;
;   Inputs: bx = offset of the buffer from which to read		  ;
;									  ;
;   Outputs: al = ASCII value of first letter (ignoring spaces),	  ;
;                 or ax = 0 if it's not a letter			  ;
;            bx = offset of the character following the letter returned,  ;
;                 undefined on error					  ;
;									  ;
;   Purpose: retrieve a letter from the input string; error if one isn't  ;
;            available							  ;
;--------------------------------------------------------------------------
_GetLetter
				; call	_libGetLetter
				; ret

 ;----------
 .CheckChar:
 ;----------
	cmp byte [bx], ' '	; Ignore spaces when reading character
	je .SpaceChar

	cmp byte [bx], 'a'	; Check to see if ASCII value is a
	jl .Error		; valid character, between 'a' and 'z'
	cmp byte [bx], 'z'
	jg .Error
	mov al, byte [bx]
	inc bx			; Return the offset of the character
	ret			; following the letter returned
 ;------
 .Error:
 ;------
	xor ax, ax
	ret

 ;----------
 .SpaceChar:
 ;----------
	inc bx			; bx points to the next character
	jmp .CheckChar		; to check again for spaces



;--------------------------------------------------------------------------
; GetNumber								  ;
;   Inputs: bx = offset of the buffer from which to read		  ;
;           di = offset of the FDNumber in which to store the read number ;
;									  ;
;   Outputs: ax = 0 on error or non-zero on success			  ;
;            bx = offset of the character following the number returned,  ;
;                 undefined on error					  ;
;            [di] = the number read from the string			  ;
;									  ;
;   Calls: FDRead							  ;
;									  ;
;   Purpose: retrieve a FDNumber from the input string;			  ;
;            error if one isn't available				  ;
;--------------------------------------------------------------------------
_GetNumber
			; call	_libGetNumber
			; ret
 push dx
 call _FDRead		; FDRead takes care of the inputs and the
 test dl, dl		; output of bx and [di]
 jnz .Error		; DL = 0 if no conversion errors

 mov al, 1
 jmp .End

 ;------
 .Error:
 ;------
	xor ax, ax

 ;----
 .End:
 ;----
	pop dx
	ret



;--------------------------------------------------------------------------
; CalculateInterest							  ;
;   Inputs: [principle] = the principle for the calculation		  ;
;           [interest] = the interest rate per period			  ;
;           [periods] = the number of periods to compound		  ;
;									  ;
;   Outputs: ax = 0 on error or non-zero on success			  ;
;									  ;
;   Calls: FDMul, FDPow							  ;
;									  ;
;   Purpose: calculate the compound interest, storing to [result]	  ;
;--------------------------------------------------------------------------
_CalculateInterest
				;call	_libCalculateInterest
				;ret

 push si
 push di
 push dx
 
 inc word [interest]		; Calculate (1+[interest])^[periods]
 mov si, periods
 mov di, interest		; dx = integer portion of result
 call _FDPow			; ax = decimal portion of result

 dec word [interest]		; Restore [interest] to its original value
 mov word [result], dx
 mov word [result+2], ax

 mov si, principle		; [principle]*((1+[interest])^[periods])
 mov di, result
 call _FDMul			; Subroutine should always succeed, so
 mov al, 1			; ax should always be non-zero on exit

 pop dx
 pop di
 pop si
 ret



;--------------------------------------------------------------------------
; ConvertCurrency							  ;
;   Inputs: [principle] = the principle for the calculation, a FDNumber	  ;
;           dh = the letter for the currency from which to convert	  ;
;           dl = the letter for the currency to which to convert	  ;
;									  ;
;   Outputs: ax = 0 on error or non-zero on success			  ;
;            [result] = the result of the calculation (principle*from*to) ;
;									  ;
;   Calls: FDMul							  ;
;									  ;
;   Purpose: calculate a currency conversion, storing to [result]	  ;
;--------------------------------------------------------------------------
_ConvertCurrency
				;call	_libConvertCurrency
				;ret

 push dx			; Save registers
 push bx
 push si
 push di
 
 cmp dh, 'a'			; Check if the input characters are
 jl .Error			; valid characters from a through z
 cmp dh, 'z'
 jg .Error
 cmp dl, 'a'
 jl .Error
 cmp dl, 'z'
 jg .Error

 mov ax, word [principle]	; [result] holds [principle]
 mov word [result], ax
 mov ax, word [principle+2]
 mov word [result+2], ax

 mov bl, dh			; Let 0 through 25 represent the letters
 sub bl, 'a'			; a through z
 xor bh, bh
 shl bx, 1			; Index words, not bytes

 mov ax, word [tab_from + bx]	; Obtain location for FDNumber of the
 mov bx, ax			; "convert from" conversion factor
 test bx, bx			; If address is 0, then invalid letter
 jz .Error

 mov si, bx			; Else,
 mov di, result			; [result] holds [principle]*from
 call _FDMul

 mov bl, dl			; Let 0 through 25 represent the letters
 sub bl, 'a'			; a through z
 xor bh, bh
 shl bx, 1			; Index words, not bytes

 mov ax, word [tab_to + bx]	; Obtain location for FDNumber of the
 mov bx, ax			; "convert to" conversion factor
 test bx, bx			; If address is 0, then invalid letter
 jz .Error

 mov si, bx			; Else,
 mov di, result			; [result] holds [principle]*from*to
 call _FDMul

 mov al, 1			; ax = non-zero on success
 jmp .End

 ;------
 .Error:
 ;------
	xor ax, ax		; ax = 0 on error

 ;----
 .End:
 ;----
	pop di			; Restore registers
	pop si
	pop bx
	pop dx
	ret
 


;--------------------------------------------------------------------------
; FDRead								  ;
;   Inputs: bx = offset to a string representing a decimal number	  ;
;           di = offset of the buffer to which it should be stored	  ;
;									  ;
;   Outputs: bx = offset of the first non-converted character		  ;
;            dl = conversion error code, as in ascbin; use overflow if    ;
;                 the portion following the decimal is above 99		  ;
;									  ;
;   Calls: ascbin							  ;
;									  ;
;   Purpose: input a FDNumber from a user-typed string			  ;
;--------------------------------------------------------------------------
_FDRead
			;call	_libFDRead
			;ret

 push ax
 push cx

 call ascbin		; Convert integer part
 cmp dl, 1		; If no valid digits found or there are too
 je .Exit		; many digits, then exit with error indication
 cmp dl, 2
 je .Exit
 mov word [di], ax	; Store integer part in [di]
 cmp byte [bx], '.'	; If next character is not a decimal point,
 jnz .NoDecimal		; then there is no decimal portion of FDNumber
 inc bx
 mov cx, bx

 call ascbin		; Convert decimal part
 cmp dl, 1		; If there are no digits after decimal point,
 je .NoDecimal		; then there is no decimal portion of FDNumber
 cmp dl, 2
 je .Exit
 inc cx			; Make appropriate adjustment if only one digit
 cmp bx, cx		; found after decimal point
 je .OneDigit

 mov word [di+2], ax	; Store decimal part in [di+2]
 cmp word [di+2], 99	; Decimal portion can only contain 0 through 99
 jg .Overflow
 xor dl, dl
 jmp .Exit
 
 ;---------
 .OneDigit:
 ;---------
	mov cl, 10		; If number is 12.3, single digit has
	mul cl			; to be multiplied by 10, else will be
	mov word [di+2], ax	; incorrectly represented as 12.03
	xor dl, dl
	jmp .Exit

 ;----------
 .NoDecimal:
 ;----------
	mov word [di+2], 0
	xor dl, dl
	jmp .Exit

 ;---------
 .Overflow:
 ;---------
	mov dl, 3

 ;-----
 .Exit:
 ;-----
	pop cx
	pop ax
	ret



;--------------------------------------------------------------------------
; FDWrite								  ;
;   Inputs: bx = offset to a 10 byte buffer				  ;
;           si = offset of the FDNumber to be converted into ASCII	  ;
;									  ;
;   Outputs: bx = offset of the first non-blank character, with the	  ;
;                 number right-justified and with spaces to the left,	  ;
;                 two digits after the decimal point			  ;
;            cl = number of non-blank characters			  ;
;   Calls: binasc							  ;
;									  ;
;   Purpose: output a FDNumber into a user-readable string		  ;
;--------------------------------------------------------------------------
_FDWrite
			;call	_libFDWrite
			;ret

 push ax		; Save registers
 push dx
 push di
 push si

 mov ax, word [si]
 call binasc

 xor ch, ch

 mov di, cx
 mov byte [bx + di], '.'
 mov di, bx

 add bx, cx
 inc bx			; bx = location of just after decimal point

 mov ch, cl		; Save the number of characters in integer part
 push bx		; and the location immediately after decimal point

 mov ax, word [si+2]
 call binasc

 cmp cl, 1
 je .OneDigit
 cmp cl, 2
 je .TwoDigit

 mov dx, '00'		; If no decimal digits, then <integer>.00 is implied
 jmp .WriteDecimal

 ;---------
 .OneDigit:
 ;---------
	mov dl, '0'		; Save decimal part of number in dx,
	mov dh, byte [bx]	; and clear right-justified number
	mov byte [bx], 0	; that was the output of binasc
	jmp .WriteDecimal			

 ;---------
 .TwoDigit:
 ;---------
	mov dx, word [bx]	; dl = tenths place
	mov word [bx], 0	; dx = hundredths place

 ;-------------
 .WriteDecimal:
 ;-------------
	pop bx
	mov word [bx], dx

	mov bx, di
	add cl, ch		; Number of non-blank characters

 pop si				; Restore registers
 pop di
 pop dx
 pop ax
 ret



;--------------------------------------------------------------------------
; FDAdd									  ;
;   Inputs: si = offset to a source FDNumber				  ;
;	    di = offset to a source and destination FDNumber		  ;
;									  ;
;   Outputs: [di] = holds the result of the addition			  ;
;									  ;
;   Purpose: Adds the FDNumbers at offsets di, si and stores at offset di ;
;--------------------------------------------------------------------------
_FDAdd
				;call	_libFDAdd
				;ret

 push dx

 mov dx, word [si]		; Add integer portions of each FDNumber
 add dx, word [di]		; and store integer sum
 mov word [di], dx

 mov dx, word [si+2]		; Add decimal portions of each FDNumber
 add dx, word [di+2]		; and store decimal sum if less than 100
 cmp dx, 100
 jge .GreaterThan99

 mov word [di+2], dx
 jmp .End

 ;--------------
 .GreaterThan99:
 ;--------------
	sub dx, 100		; Otherwise, subtract 100 from decimal sum,
	mov word [di+2], dx	; store corrected decimal sum, and carry 1
	inc word [di]

 ;----
 .End:
 ;----
	pop dx
	ret



;--------------------------------------------------------------------------
; FDMul									  ;
;   Inputs: si = offset to a source FDNumber				  ;
;           di = offset to a source and destination FDNumber		  ;
;									  ;
;   Outputs: [di] = holds the result of the multiplication		  ;
;									  ;
;   Purpose: Multiplies the FDNumbers at offsets di, si			  ;
;            and stores at offset di					  ;
;									  ;
;   Formula: Ph = Ah*Bh + Ah*Bl/100 + Al*Bh/100				  ;
;            Pl = Ah*Bl%100 + Al*Bh%100 + Al*Bl/100,			  ;
;             where Ph, Pl are integer and decimal result		  ;
;--------------------------------------------------------------------------
_FDMul
				;call	_libFDMul
				; ret

 push ax			; Preserve original values
 push dword [numbuf2]
 push cx
 push dx

 mov dx, word [di]		; Use [numbuf2] for original value of [di]
 mov word [numbuf2], dx		; Use [numbuf2+2] for original value of [di+2]
 mov dx, word [di+2]		;   A,B = two FDNumbers , P = product
 mov word [numbuf2+2], dx	;   h,l = the integer and decimal parts


 ;---------- Calculate integer part of product ----------;
 ;							 ;
 mov ax, word [numbuf2]		; [di] = (Ah*Bh)
 mul word [si]
 mov word [di], ax

 mov ax, word [numbuf2+2]	; [di] = (Ah*Bh) + (Ah*Bl)/100
 mul word [si]
 mov cx, 100
 xor dx, dx			; Must clear dx before dividing
 div cx
 add word [di], ax

 mov ax, word [numbuf2]		; [di] = (Ah*Bh) + (Ah*Bl)/100 + (Al*Bh)/100
 mul word [si+2]
 xor dx, dx			; Must clear dx before dividing
 div cx
 add word [di], ax


 ;---------- Calculate decimal part of product ----------;
 ;							 ;
 mov ax, word [numbuf2+2]	; [di+2] = (Ah*Bl)%100
 mul word [si]
 xor dx, dx			; Must clear dx before dividing
 div cx
 mov word [di+2], dx

 mov ax, word [numbuf2]		; [di+2] = (Ah*Bl)%100 + (Al*Bh)%100
 mul word [si+2]
 xor dx, dx			; Must clear dx before dividing
 div cx
 add word [di+2], dx

 mov ax, word [numbuf2+2]	; [di+2] = (Ah*Bl)%100 + (Al*Bh)%100 + (Al*Bl)/100
 mul word [si+2]
 xor dx, dx			; Must clear dx before dividing
 div cx
 add word [di+2], ax
 

 ;---------- Perform appropriate adjustments ----------;
 ;						       ;
 cmp dx, 50			; (Al*Bl)%100 might be greater than
 jl .DecimalCheck		; or equal to 50.
 inc word [di+2]		; In such cases Pl should be incremented

 ;-------------
 .DecimalCheck:
 ;-------------
	cmp word [di+2], 100	; If decimal portion is 100 or greater,
	jl .End			; then subtract 100 and carry 1 to integer
	sub word [di+2], 100	; part of the product
	inc word [di]
	jmp .DecimalCheck

 ;----
 .End:
 ;----
	pop dx			; Restore original values
	pop cx
	pop dword [numbuf2]
	pop ax
	ret



;--------------------------------------------------------------------------
; FDPow									  ;
;   Inputs: si = offset to a source FDNumber as exponent		  ;
;           di = offset to a source FDNumber as base			  ;
;									  ;
;   Outputs: dx = integer portion of the result				  ;
;            ax = decimal portion of the result				  ;
;									  ;
;   Calls: FDMul, FDPow (recursion)					  ;
;									  ;
;   Purpose: raises [di] to the [si] power				  ;
;--------------------------------------------------------------------------
_FDPow
			;call	_libFDPow
			;ret

 push dword [di]	; Preserve the source base FDNumber

 cmp word [si], 0	; If exponent = 0, set result = 1.00 and quit
 jz .Zero
 cmp word [si], 1	; If exponent = 1, we are done recursing
 je .Finished
 shr word [si], 1	; Divide exponent by 2 (set n = n/2)
 jc .Odd		; If carry out = 1, we have an odd exponent


 ;---------         Even Exponent Recursive Calculation          ---------;
 ; When we have an even exponent, perform the following calculation:      ;
 ; b^n = b^(n/2) * b^(n/2)						  ;
 ; Here we set both si and di to the base, and then exit		  ;
									  ;
 .Even:									  ;
	call _FDPow							  ;
	mov word [si], dx						  ;
	mov word [si + 2], ax						  ;
	push dword [si]			; Copy [si] to [di]		  ;
	pop dword [di]							  ;
	call _FDMul							  ;
	jmp .Finished							  ;
									  ;
 ;------------------------------------------------------------------------;

 ;---------         Odd Exponent Recursive Calculation           ---------;
 ; When we have an odd exponent, perform the following calculation:	  ;
 ; b^n = b * b^(n/2) * b^(n/2)						  ;
 ; where b is stored in the initial push of dword [di]			  ;
									  ;
 .Odd:									  ;
	push dword [di]							  ;
	call _FDPow							  ;
	mov word [si], dx						  ;
	mov word [si + 2], ax						  ;
	push dword [si]			; Copy [si] to [di]		  ;
	pop dword [di]							  ;
	call _FDMul							  ;
	pop dword [si]			; Multiply by original base	  ;
	call _FDMul							  ;
	jmp .Finished							  ;
									  ;
 ;------------------------------------------------------------------------;


 ;---------
 .Finished:
 ;---------
	mov dx, word [di]		; Store the result in the base,
	mov ax, word [di+2]		; which is pointed to by di
	jmp .Exit

 ;-----
 .Zero:
 ;-----
	mov dx, 1			; Result = 1.00
	xor ax, ax

 ;----
 .Exit:
 ;----
	pop dword[di]
	ret