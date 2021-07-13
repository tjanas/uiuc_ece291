; MP3 - Terrence Bradley Janas - October 15, 2001
;
;
; MP3 - Chat 291
;
; Josh Potts, Fall 2001
; Author: Ajay Ladsaria
; University of Illinois, Urbana-Champaign
; Dept. of Electrical and Computer Engineering
;
; Version 1.0

	BITS	16


;====== SECTION 1: Define constants =======================================

        CR      	EQU     0Dh
        LF      	EQU     0Ah

	ATTR_BORDER	EQU	10	; Light green is my favorite color,
	TOP_OFF		EQU	0	; so I chose this as the border color
	BOTTOM_OFF	EQU	13*160	;
	VIDEO_SEG	EQU	0B800h	; Our textmode video segment

	COM1BASE	EQU	03F8h	; COM1 is IRQ4
	COM2BASE	EQU	02F8h	; COM2 is IRQ3
	BAUDRATE	EQU	12	; Communicates at 9600 baud
	PARAMS		EQU	03h	; and transfer size of 8 bits

	RECV_BUF_LEN	EQU	8	; Length of recvBuf
;====== SECTION 2: Declare external procedures ============================

EXTERN  kbdine, dspout, dspmsg, mp1xit,ascbin,binasc
EXTERN  kbdin, dosxit

EXTERN	mp3xit
EXTERN	libMP3Main, libDrawBorder, libInstallPort, libRemovePort, libPortISR
EXTERN	libInstallKeyboard, libRemoveKeyboard, libKeyboardISR, libGetNextKey
EXTERN	libTransmitKey, libDrawNewLine, libDrawBackspace, libTypeKey

GLOBAL	shift, quit, nextKey, KeyboardV, PortV, recvPort, recvBuf
GLOBAL	bufhead, bufsize, colorLookup, myColorLookup, colorTable
GLOBAL	QwertyNames, QwertyShift

;You will have to write these functions
GLOBAL	MP3Main, DrawBorder, InstallPort, RemovePort, PortISR
GLOBAL	InstallKeyboard, RemoveKeyboard, KeyboardISR, GetNextKey
GLOBAL	TransmitKey, DrawNewLine, DrawBackspace, TypeKey


;GLOBAL DisplayCard

;EXTERN Jumptable, Suittable
;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK                    ; *** STACK SEGMENT ***
        resb      64*8
stacktop:
        resb      0                     ; work around NASM bug

;====== SECTION 4: Define code segment ====================================

SEGMENT code                            ; *** CODE SEGMENT ***

;====== SECTION 5: Declare variables for main procedure ===================
shift		db 	0	;bit 1=LSHIFT pressed, bit 0=RSHIFT pressed
quit		db 	0	;quit on nonzero
nextKey		db	0	;most recent input
KeyboardV	resd 	1	;holds address of orig keyboardISR
PortV		resd 	1	;holds address of orig PortISR
recvPort	dw	0
recvBuf		times   RECV_BUF_LEN db	0	;receive buffer(FIFO)
bufhead		dw	0	;current first element of FIFO
bufsize		dw	0	;num elements in FIFO

colorLookup	dw	0	;other user's color lookup value for colorTAble
myColorLookup	dw	0	;my window's color lookup
colorTable	db	07h, 01h, 02h, 04h, 03h, 06h, 41h, 82h, 83h, 87h 

PortMsg	db CR, LF, "Select which port to receive in", CR, LF
	db "(1) COM1", CR, LF
	db "(2) COM2", CR, LF, '$'

	
;====== SECTION 6: Program initialization =================================

..start:
        mov     ax, cs                  ; Initialize Default Segment register
        mov     ds, ax  
        mov     ax, stkseg              ; Initialize Stack Segment register
        mov     ss, ax
        mov     sp, stacktop            ; Initialize Stack Pointer register

;====== SECTION 7: Main procedure =========================================

MAIN:
	mov	dx, PortMsg		;prompt user for COMM1 or 2
	call	dspmsg
	call	kbdin
	cmp	al, '1'
	jne	.checkCom2
	mov	word [recvPort], COM1BASE
	jmp	.portFixed

.checkCom2
	cmp	al, '2'
	jne	MAIN   
	mov	word [recvPort], COM2BASE

.portFixed
	mov	ax, 3			;int for textmode video
	int	10h

	call 	MP3Main			;you get to write main this time
					;but did that last time too because
					;DoCommand was Main in disguise!

;	call	dosxit
;.FinalExit:
        call    mp3xit                  ; Exit to DOS





;-------------------------------------------------------------------------;
; MP3Main								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: InstallKeyboard, InstallPort, DrawBorder, GetNextKey,	  ;
;	   TypeKey, RemovePort, RemoveKeyboard,				  ;
;	   Interrupt 10h , AH = 02h					  ;
;									  ;
;   Purpose: Setup the ISRs and handle each key press			  ;
;-------------------------------------------------------------------------;
MP3Main:
				;call 	libMP3Main
				;ret

 
 push ax			; Preserve registers
 push bx
 push cx
 push dx
 push di
 push si

 call InstallKeyboard		; Install the keyboard ISR
 call InstallPort		; Install the serial port ISR

 mov cx, TOP_OFF		; Draw the text boxes starting at
 call DrawBorder		; the upper left corner of the screen




 mov ah, 02h			; Interrupt 10h : Set Cursor Position
 xor bh, bh			; AH = 02h , BH = Display page
 mov dx, 0101h			; DH:DL = Row:Column

 int 10h			; We want cursor at row 1, col 1


 mov si, 2242			; si points to beginning of bottom text box
 mov di, 162			; di points to beginning of top text box



 ;--------------
 .CheckKeypress:
 ;--------------
    call GetNextKey

    cmp byte [quit], 1			; Quit if ESC was pressed
    je .Exit

    cmp al, 200				; Check if F1 -> F10 was pressed
    jb .NotFunctionKey
    cmp al, 209
    ja .NotFunctionKey


    mov bl, al				; bl = 200 -> 209 (F1 -> F10)
    sub bl, 200				; Translate to colorTable index

    cmp dx, BOTTOM_OFF
    je .BottomColorKey

    mov byte [myColorLookup], bl	; Local user typed F1 -> F10, so set
    jmp .CheckKeypress			; text color for the top text box



 ;---------------
 .BottomColorKey:
 ;---------------
    mov byte [colorLookup], bl		; Other user typed F1 -> F10, so set
    jmp .CheckKeypress			; text color for the bottom text box



 ;---------------
 .NotFunctionKey:
 ;---------------
    call TypeKey			; If the key wasn't a function key,
    jmp .CheckKeypress			; then type the key to the screen



 ;-----
 .Exit:
 ;-----
    call RemovePort			; Uninstall interrupt service routines
    call RemoveKeyboard

    pop si				; Restore registers
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret





;-------------------------------------------------------------------------;
; DrawBorder								  ;
;   Inputs: cx = offset of upper left corner of location		  ;
;		 to start displaying the text box			  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Purpose: Draw the rectangular box that represents			  ;
;	     the two text windows.					  ;
;-------------------------------------------------------------------------;
DrawBorder  
					;call	libDrawBorder
					;ret



 push bx				; Preserve registers
 push cx
 push dx
 push es

 mov bx, cx
 mov cx, VIDEO_SEG			; ES points to video segment
 mov es, cx

 mov dh, ATTR_BORDER			; DH = attribute of border,
					; DL = contains ASCII value of char
 
 
 ;-------------
 ; DrawULCorner
 ;-------------
	mov dl, 0C9h			; Draw upper-left character
	mov [es:bx], dx			; for the top & bottom boxes
	mov [es:bx + BOTTOM_OFF], dx
	add bx, 2




	mov cl, 78			; CL = counter
	mov dl, 0CDh			; DL = top border character

 ;--------
 .DrawTop:
 ;--------
	mov [es:bx], dx			; Draw top border character,
	mov [es:bx + BOTTOM_OFF], dx	; repeat 78 times
	add bx, 2
	dec cl
	jnz .DrawTop



 ;-------------
 ; DrawURCorner
 ;-------------
	mov dl, 0BBh			; Draw upper-right character
	mov [es:bx], dx			; for the top & bottom boxes
	mov [es:bx + BOTTOM_OFF], dx
	add bx, 2



	mov cl, 10			; CL = counter
	mov dl, 0BAh			; DL = side border character

 ;----------
 .DrawSides:
 ;----------
	mov [es:bx], dx			; Draw left-side border character,
	mov [es:bx + BOTTOM_OFF], dx	; then add 158 to draw right-side
	add bx, 158			; character, and then repeat for
	mov [es:bx], dx			; all 10 rows
	mov [es:bx + BOTTOM_OFF], dx
	add bx, 2
	dec cl
	jnz .DrawSides 



 ;-------------
 ; DrawLLCorner
 ;-------------
	mov dl, 0C8h			; Draw lower-left character
	mov [es:bx], dx			; for the top & bottom boxes
	mov [es:bx + BOTTOM_OFF], dx
	add bx, 2



	mov cl, 78			; CL = counter
	mov dl, 0CDh			; DL = bottom border character

 ;-----------
 .DrawBottom:
 ;-----------
	mov [es:bx], dx			; Draw bottom border character,
	mov [es:bx + BOTTOM_OFF], dx	; repeat 78 times
	add bx, 2
	dec cl
	jnz .DrawBottom



 ;-------------
 ; DrawLRCorner
 ;-------------
	mov dl, 0BCh			; Draw lower-right character
	mov [es:bx], dx			; for the top & bottom boxes
	mov [es:bx + BOTTOM_OFF], dx

	pop es				; Restore registers
	pop dx
	pop cx
	pop bx

	ret







;-------------------------------------------------------------------------;
; InstallPort								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: Interrupt 21h , AH = 25h					  ;
;	   Interrupt 21h , AH = 35h					  ;
;									  ;
;   Purpose: Sets yp the baud rate, data size, saves old ISR address,	  ;
;	     installs new ISR, unmasks all IRQ's, and sets up the	  ;
;	     trigger for the interrupt					  ;
;-------------------------------------------------------------------------;
InstallPort
				;call	libInstallPort
				;ret

 push ax			; Preserve registers
 push bx
 push cx
 push dx
 push es

 mov ax, 350Bh			; To get & save original int vector, AH=35h
 cmp word [recvPort], COM2BASE	; and AL=interrupt number. 0Bh is our base
 je .PreserveIRQ		; interrupt number for the COM port
 
 inc al				; If COM1, then it is interrupt 12
 


 ;------------
 .PreserveIRQ:
 ;------------
    int 21h			; ES:BX -> original interrupt handler
    mov cl, al			; Save interrupt number
 
    mov word [PortV], bx	; Save original vector in PortV
    mov word [PortV + 2], es




 mov dx, [recvPort]
 add dx, 3			; DX = COMxBASE+3
 mov al, 10000000b		; Set DLAB=1 by writing to COMxBASE+3
 out dx, al

 sub dx, 3			; Since DLAB=1, we can now write divisor
 mov al, BAUDRATE		; latch low byte at COMxBASE+0
 out dx, al			; Latch high byte defaults to 00h for us

 add dx, 3			; Set data transfer size to 8 bits
 mov al, PARAMS
 out dx, al


 mov al, cl			; Restore interrupt number for the COM port
 mov ah, 25h			; Int 21h , AH=25h : Sets interrupt vector
 mov dx, PortISR		; DS:DX -> new interrupt handler
 int 21h			; Install new ISR

 xor al, al			; Unmask all IRQ's
 out 21h, al

 mov dx, word [recvPort]	; Set least significant bit of Interrupt
 mov al, 1			; Enable Register so ISR to be jumped to
 inc dx				; only when Receiver Buffer is full
 out dx, al


 pop es				; Restore registers
 pop dx
 pop cx
 pop bx
 pop ax

 ret	
 
 


;-------------------------------------------------------------------------;
; RemovePort								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: Interrupt 21h , AH = 25h					  ;
;									  ;
;   Purpose: To restore old handler for the serial port being used	  ;
;-------------------------------------------------------------------------;
RemovePort       
				;call	libRemovePort
				;ret



 
 push ax			; Save registers
 push dx
 push ds


 cmp word [recvPort], COM2BASE	; Let's find out what COM port
 je .CheckCom2			; we're using

 

 ;---------
 ;CheckCom1
 ;---------
    mov al, 12			; IRQ4 = COM1
    jmp .RestoreInt



 ;----------
 .CheckCom2:
 ;----------
    mov al, 11			; IRQ 3 = COM2



 ;-----------
 .RestoreInt:
 ;-----------
    mov dx, word [PortV]	; [PortV] contains original interrupt handler
    mov ds, word [PortV + 2]
    mov ah, 25h			; Int 21h , AH=25h : Sets interrupt vector
				;    AL = interrupt number
    int 21h			;    DS:DX --> new interrupt handler to use


    mov al, 18h			; Mask IRQs by writing 18h to port 21h
    out 21h, al			; as stated in the MP3 prompt

    pop ds
    pop dx			; Restore registers
    pop ax

    ret







;-------------------------------------------------------------------------;
; PortISR								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Purpose: To add to the FIFO any data received over the serial port	  ;
;-------------------------------------------------------------------------;
PortISR
				;jmp	libPortISR



 push ax				; Preserve registers
 push bx
 push dx
 push ds

 mov ax, cs				; Make sure DS = CS
 mov ds, ax



 mov dx, word [recvPort]		; Make sure DLAB is cleared
 add dx, 3				; and set transfer size to 8 bits
 mov al, PARAMS
 out dx, al
 sub dx, 3


 in al, dx				; Get ASCII char from serial port

 cmp word [bufsize], RECV_BUF_LEN	; Check if buffer is full
 jae .Exit				; If so, ignore any serial input


 mov bx, word [bufsize]			; If not, determine the proper spot 
 add bx, word [bufhead]			; to add the next entry to buffer
 cmp bx, RECV_BUF_LEN
 jae .Adjust



 ;--------------
 .WriteToBuffer:
 ;--------------			
					; Enque the character at
    mov byte [recvBuf + bx], al		; [recvBuf + [bufsize]]
    inc word [bufsize]			; And update the size of buffer




 ;-----
 .Exit:
 ;-----
    mov al, 20h				; Send a generic end of interrupt
    out 20h, al

    pop ds				; Restore registers
    pop dx
    pop bx
    pop ax


    iret				; Use IRET for end of ISR




 ;-------
 .Adjust:
 ;-------
    sub bx, RECV_BUF_LEN		; Queue is circular
    jmp .WriteToBuffer






;-------------------------------------------------------------------------;
; InstallKeyboard							  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: Interrupt 21h , AH = 25h					  ;
;	   Interrupt 21h , AH = 35h					  ;
;									  ;
;   Purpose: To preserve original keyboard vector			  ;
;	     and install new vector to KeyboardISR			  ;
;-------------------------------------------------------------------------;
InstallKeyboard
				;call	libInstallKeyboard
				;ret


 push ax			; Save registers
 push bx
 push dx
 push es

 mov ax, 3509h			; Int 21h , 35h : Get original int vector
				; Keyboard is interrupt 9
 int 21h			; ES:BX -> current interrupt handler

 mov word [KeyboardV], bx	; Save original interrupt handler
 mov word [KeyboardV + 2], es	; in KeyboardV

 mov ah, 25h			; Int 21h, 25h : Set Interrupt Vector
 mov dx, KeyboardISR		; DS:DX -> new interrupt handler
 int 21h

 pop es
 pop dx
 pop bx				; Restore registers
 pop ax

 ret




;-------------------------------------------------------------------------;
; RemoveKeyboard							  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: Interrupt 21h , AH = 25h					  ;
;									  ;
;   Purpose: To restore original keyboard vector			  ;
;-------------------------------------------------------------------------;
RemoveKeyboard
				;call	libRemoveKeyboard
				;ret

 push ax			; Save registers
 push dx
 push ds

 mov al, 9			; Keyboard is INT 9
 mov dx, word [KeyboardV]	; DS:DX --> original interrupt handler
 mov ds, word [KeyboardV + 2]
 mov ah, 25h			; Int 21h , AH=25h : Sets interrupt vector

 int 21h

 pop ds
 pop dx				; Restore registers
 pop ax

 ret






;-------------------------------------------------------------------------;
; KeyboardISR								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Purpose: Set [nextKey] to be proper ASCII representation		  ;
;	     of the character typed. Access the QwertyNames or		  ;
;	     QwertyShift look-up table to determine the correct		  ;
;	     ASCII representation of the input.				  ;
;-------------------------------------------------------------------------;
KeyboardISR
				;jmp	libKeyboardISR



 push ds			; Save registers
 push ax
 push bx



 mov ax, cs			; Make sure DS = CS
 mov ds, ax


 in al, 60h			; Get scan code
	

 cmp al, 1			; Check if ESC was pressed
 je .ESCpressed


 cmp al, 10000000b		; Check if key press or release
 jnb .KeyRelease		; highest bit of scancode set = release




 ;---------------
 ;LeftShiftPress:
 ;---------------
    cmp al, 42			; Check if LSHIFT pressed
    jne .RightShiftPress
    or byte [shift], 00000010b	; If so, set second least significant
    jmp .Exit			; bit of [shift]




 ;----------------
 .RightShiftPress:
 ;----------------
    cmp al, 54			; Check if RSHIFT pressed
    jne .OtherKey
    or byte[shift], 00000001b	; If so, set least significant
    jmp .Exit			; bit of [shift]




 ;------------------
 .RightShiftRelease:
 ;------------------
    cmp al, 182			; Check if RSHIFT released
    jne .Exit
    and byte [shift], 00000010b
    jmp .Exit




 ;-----------
 .KeyRelease:
 ;-----------
    cmp al, 170			; Check if LSHIFT released
    jne .RightShiftRelease
    and byte[shift], 00000001b	
    jmp .Exit




 ;----------
 .Uppercase:
 ;----------
    mov bl, al			; Here we have an upper-case
    xor bh, bh			; keypress, so consult scancode table
    mov ah, [QwertyShift + bx]	; table and determine proper
    mov [nextKey], ah		; upper-case character to write
    jmp .Exit			; to [nextKey]




 ;---------
 .OtherKey:
 ;---------
    cmp byte[shift], 0		; Check if normal key and shift pressed
    jne .Uppercase			
    mov bl, al			; If not, consult the scancode table
    xor bh, bh			; and determine proper lower-case character
    mov ah, [QwertyNames + bx]	; to write to [nextKey]
    mov [nextKey], ah
    jmp .Exit




 ;-----------
 .ESCpressed:
 ;-----------
    mov byte [quit], 1		; Set [quit] to 1 if escape is pressed



 ;-----
 .Exit:
 ;-----
    in al, 61h			; Send acknowledgement without
    or al, 10000000b		; modifying the other bits
    out 61h, al
    and al, 01111111b
    out 61h, al
    mov al, 20h			; Send End-of-Interrupt signal
    out 20h, al


    pop bx			; Restore registers
    pop ax
    pop ds

    iret			; End of handler







;-------------------------------------------------------------------------;
; GetNextKey								  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: al = ASCII of next key					  ;
;	     dx = TOP_OFF if user typed, else BOTTOM_OFF		  ;
;									  ;
;   Calls: TransmitKey							  ;
;									  ;
;   Purpose: Polls two buffers to get the next key to be		  ;
;	     displayed onto the screen.					  ;
;									  ;
;	     Exits if [quit] is nonzero; otherwise it loops until	  ;
;	     [nextKey] is nonzero, or the [recvBuf] FIFO is non-empty.	  ;
;									  ;
;	     If [nextKey] is nonzero, then it transmits it to the other	  ;
;	     user and clears [nextKey].					  ;
;-------------------------------------------------------------------------;
GetNextKey 
   					;call	libGetNextKey
					;ret


 push si



 ;------------
 .PollBuffers:
 ;------------
    cmp byte [quit], 0			; Check if ESC was pressed
    jnz .Exit

    cmp byte [nextKey], 0		; Check if there is a char to transmit
    jnz .Transmit

    cmp word [bufsize], 0		; Check if FIFO buffer is empty
    jz .PollBuffers


    mov si, word [bufhead]		; AL = char at the head of the buffer
    mov al, byte [recvBuf + si]
    inc word [bufhead]			; Increment the head of the buffer

    cmp word [bufhead], RECV_BUF_LEN	; If bufhead is pointing to end of
    jae .AdjustBufHead			; buffer, adjust its position




 ;-------------
 .ShrinkBuffer:
 ;-------------
    mov dx, BOTTOM_OFF			; Buffer holds chars to be displayed
					; in bottom text box.
    dec word [bufsize]			; After writing character to buffer,
    jmp .Exit				; we can shrink size of buffer.




 ;--------------
 .AdjustBufHead:
 ;--------------
    mov word [bufhead], 0		; Bufhead now points to the beginning
    jmp .ShrinkBuffer			; of the FIFO buffer




 ;---------
 .Transmit:
 ;---------
    mov al, [nextKey]			; Transmit the character in al onto
    call TransmitKey			; the serial port to other user
    mov dx, TOP_OFF			; Since we typed char, display on top
    mov byte [nextKey], 0		; Key is sent, so clear [nextKey]




 ;-----
 .Exit:
 ;-----
    pop si

    ret





;-------------------------------------------------------------------------;
; TransmitKey								  ;
;   Inputs: al = ASCII character to transmit				  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Purpose: Transmits the data in al onto the serial port		  ;
;-------------------------------------------------------------------------;
TransmitKey
			;call	libTransmitKey
			;ret
 
 push dx

 mov dx, word [recvPort]	; send character to [recvPort]
 out dx, al

 pop dx

 ret


;-------------------------------------------------------------------------;
; DrawNewLine								  ;
;   Inputs: di = offset of a location in the line directly above	  ;
;		 where the new line will go				  ;
;	    dx = offset of upper left corner of text box		  ;
;									  ;
;   Outputs: al = row#							  ;
;	     ah = col#							  ;
;	     di = offset of next character				  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Purpose: Clears a line of text on the screen			  ;
;-------------------------------------------------------------------------;
DrawNewLine
				;call	libDrawNewLine
				;ret


 push bx			; Save registers
 push cx
 push dx
 push es

 mov ax, di			; Divide offset by 80*2 and
 mov dl, 160			; AL = row , AH = cols*2
 div dl
 inc al				; AL = next row


 cmp al, 11			; There are only 10 rows in each chat box
 je .AtBottom			; If we are at the bottom of either one
 cmp al, 24			; the next row is 10 rows above
 je .AtBottom
 jmp .GetOffset

 ;---------
 .AtBottom:
 ;---------
	sub al, 10		; adjust AL if we are already at the bottom


 ;---------------
 .GetOffset:
 ;---------------
	mov dx, VIDEO_SEG	; Set up ES to point to video segment
	mov es, dx

	mov cl, al		; Save the the row number
	mov dl, 160
	mul dl			; ax = offset of col 0 and the next row

	add ax, 2
	mov bx, ax
	mov di, bx		; di = offset of next character


	mov dl, 78

 ;----------
 .ClearChar:
 ;----------
	mov word [es:bx], 0700h	; Clear all 78 characters in the next row
	add bx, 2
	dec dl
	jnz .ClearChar

	mov al, cl		; al = row#
	mov ah, 1		; ah = col#

	pop es			; Restore registers
	pop dx
	pop cx
	pop bx

	ret



;-------------------------------------------------------------------------;
; DrawBackspace								  ;
;   Inputs: di = offset of character from which to backspace		  ;
;	    dx = offset of upper left corner of text box		  ;
;									  ;
;   Outputs: di = offset of next character				  ;
;									  ;
;   Calls: Interrupt 10h , AH = 02h					  ;
;									  ;
;   Purpose: Backspaces and moves the cursor back			  ;
;-------------------------------------------------------------------------;
DrawBackspace
				;call	libDrawBackspace
				;ret
 
 push ax			; Save registers
 push bx
 push dx
 push es
 
 mov ax, di			; Divide offset by 80*2 and
 mov dl, 160			; AL = row , AH = col*2
 div dl

 cmp ah, 2			; Cannot backspace if we are at the
 je .Exit			; beginning of the row


 mov cx, VIDEO_SEG		; Set up ES to point to video segment
 mov es, cx			; and erase the character to be backspaced to
 mov word [es:di - 2], 0
 sub di, 2			; offset of next character

 shr ah, 1			; AH = cols
 mov dl, ah
 dec dl				; we want cursor one column to the left
 mov dh, al
 xor bh, bh			; Interrupt 10h : Set Cursor Position
				;  AH = 02h
 mov ah, 02h			;  BH = Display page
 int 10h			;  DH = Row
 				;  DL = Column

 ;-----
 .Exit:
 ;-----

	pop es			; Restore registers
	pop dx
	pop bx
	pop ax

	ret





;-------------------------------------------------------------------------;
; TypeKey								  ;
;   Inputs: al = input ASCII value					  ;
;	    di = offset of current location in top text box		  ;
;	    si = offset of current location in bottom text box		  ;
;	    dx = offset of upper left corner of the correct text box	  ;
;									  ;
;   Outputs: di = offset of next character in the top text box		  ;
;	     si = offset of next character in the bottom text box	  ;
;									  ;
;   Calls: DrawBackspace						  ;
;	   DrawNewLine							  ;
;	   Interrupt 10h , AH = 02h					  ;
;									  ;
;   Purpose: To display at the proper location the input ASCII value	  ;
;	     and to update the location of the cursor			  ;
;-------------------------------------------------------------------------;
TypeKey
			;call	libTypeKey
			;ret


 

 push ax		; Save Registers
 push bx
 push dx
 push es



 cmp al, BKSP		; Check to see if input key is either
 je .BackspaceKey	; a backspace, enter, or other key
 cmp al, ENTR		; to be displayed
 je .EnterKey
 jmp .OtherKey



 ;-------------
 .BackspaceKey:
 ;-------------
    cmp dx, TOP_OFF	; Check to see if backspace is to be displayed
    je .TopBackspace	; in the top or bottom text box


    ;---------------
    ;BottomBackspace
    ;---------------
       push di			; Preserve original di
       mov di, si		; DrawBackspace uses di as its offset
       call DrawBackspace
       mov si, di		; Store new offset
       pop di			; and restore di
       jmp .Exit
 

    ;-------------
    .TopBackspace:
    ;-------------
       call DrawBackspace	; DrawBackspace automatically stores new
       jmp .Exit		; offset in di. We are done.





 ;---------
 .EnterKey:
 ;---------
    xor bh, bh			; display page = 0 for displaying cursor
    cmp dx, TOP_OFF		; Check to see which text box to use
    je .TopEnter


    ;-----------
    ;BottomEnter
    ;-----------
       push di			; Copy si to di because
       mov di, si		; DrawNewLine uses di as offset
       call DrawNewLine		; New offset generated is stored in si
       mov si, di
       pop di
       mov dl, ah		; DrawNewLine already gives us
       mov dh, al		; al=row# , ah=col#, di=new offset
       mov ah, 02h		; To display cursor at new offset:
       int 10h			; ah=02h, dh=row#, dl=col#
       jmp .Exit


    ;---------
    .TopEnter:
    ;---------
       call DrawNewLine		; di, dx already set for DrawNewLine
       mov dl, ah		; Set the inputs of Int 10h to display cursor
       mov dh, al		; with the row and col numbers that
       mov ah, 02h		; DrawNewLine gives us
       int 10h
       jmp .Exit




 ;-----
 .Exit:
 ;-----
    pop es			; Restore registers
    pop dx
    pop bx
    pop ax
    ret




 ;---------
 .OtherKey:
 ;---------
    mov bx, VIDEO_SEG		; Set up ES to point to video segment
    mov es, bx
    cmp dx, BOTTOM_OFF		; Check if key belongs in top or bottom box
    je .BottomOther
 

    ;-----------
    ;TopOtherKey		; Here we write the char & cursor in top box
    ;-----------
       mov bx, word [myColorLookup]	; Move attribute byte into high byte
       mov ah, byte [colorTable + bx]	; at the current offset.
       mov word [es:di], ax		; AL already holds character byte

       mov ax, di		; Divide offset by 80*2 and
       mov bl, 160		; AL = row, AH = cols*2
       div bl

       xor bh, bh		; Set BH=0 to display page 0 for cursor
       cmp ah, 156		; Check to see if we are currently at
       jne .NotEndofTopRow	; the end of a row.

       call DrawNewLine
       mov dl, ah
       mov dh, al		; If so, then draw a new line
       mov ah, 02h		; and move cursor to the new location
       int 10h
       jmp .Exit

       
       ;---------------
       .NotEndofTopRow:
       ;---------------
          add di, 2		; If we are here, we are not at the end of
          shr ah, 1		; the row. New offset is one character
          inc ah		; to the right. AH=cols*2, so divide by 2
          mov dl, ah		; and increment to point to new column
          mov dh, al
          mov ah, 02h
          int 10h
          jmp .Exit



    ;------------
    .BottomOther:	     ; Here we write the char & cursor in bottom box
    ;------------
       mov bx, word [colorLookup]	; Move attribute byte into high byte
       mov ah, byte [colorTable + bx]	; at the current offset.
       mov word [es:si], ax		; AL already holds character byte

       mov ax, si		; Divide offset by 80*2 and
       mov bl, 160		; AL = row, AH = cols*2
       div bl
 
       xor bh, bh		; Set BH=0 to display page 0 for cursor
       cmp ah, 156		; Check to see if we are currently at
       jne .NotEndofBotRow	; the end of a row.

       push di
       mov di, si		; DrawNewLine uses di as its offset
       call DrawNewLine
       mov si, di
       pop di
       mov dl, ah		; Set the row and column numbers
       mov dh, al		; using the values that DrawNewLine
       mov ah, 02h		; gives us.
       int 10h
       jmp .Exit


       ;---------------
       .NotEndofBotRow:
       ;---------------
          add si, 2		; If we are here, we are not at the end of
          shr ah, 1		; the row. New offset is one character
          inc ah		; to the right. AH=cols*2, so divide by 2
          mov dl, ah		; and increment to point to new column
          mov dh, al
          mov ah, 02h
          int 10h
          jmp .Exit






;====== SECTION 8: Stuff we would have preferred to use %include for ======


LSHIFT	equ	6
RSHIFT	equ	7
BKSP	equ	8
ENTR	equ	13
ESC	equ	27
DEL	equ	10
HOME	equ	11
UP	equ	24
PGUP	equ	12
LEFT	equ	27
RIGHT	equ	26
END	equ	14
DOWN	equ	25
PGDN	equ	15
INS	equ	16
SPACE	equ	17

QwertyNames
	db	0	; filler
	db	ESC,'1','2','3','4','5','6','7','8','9','0','-','=',BKSP
	db	0, 'q','w','e','r','t','y','u','i','o','p','[',']',ENTR
	db	0,'a','s','d','f','g','h','j','k','l',';',"'","`"
	db	LSHIFT,'\','z','x','c','v','b','n','m',",",'.','/',RSHIFT,'*'
	db	0, ' ', 0, 200,201,202,203,204,205,206,207,208,209 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	HOME, UP, PGUP, '-'
	db	LEFT, 0, RIGHT, '+'
	db	END, DOWN, PGDN, INS
	db	DEL, 0; sysrq

QwertyShift
	db	0	; filler
	db	ESC,'!','@','#','$','%','^','&','*','(',')','_','+',BKSP
	db	0, 'Q','W','E','R','T','Y','U','I','O','P','{','}',ENTR
	db	0,'A','S','D','F','G','H','J','K','L',':','"','~'
	db	LSHIFT,'|','Z','X','C','V','B','N','M',"<",'>','?',RSHIFT,'*'
	db	0, ' ', 0, 200, 201,202,203,204,205,206,207,208,209 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	HOME, UP, PGUP, '-'
	db	LEFT, 0, RIGHT, '+'
	db	END, DOWN, PGDN, INS
	db	DEL, 0; sysrq