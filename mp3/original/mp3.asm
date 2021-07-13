; MP3 - Your Name - Today's Date
;
;
; MP3 - Chat 291 - SOLUTION
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

	ATTR_BORDER	EQU	6	;Feel free to change this.
	TOP_OFF		EQU	0	;libcode isn't currently robust enough
	BOTTOM_OFF	EQU	13*160	;to handle changes in these

	COM1BASE	EQU	03F8h
	COM2BASE	EQU	02F8h
	BAUDRATE	EQU	12
	PARAMS		EQU	03h

	RECV_BUF_LEN	EQU	8	
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

	

; MP3Main
; No inputs or outputs
; Normal Main loop for MP3
MP3Main:
	call 	libMP3Main
	ret

; DrawBorder  
; No inputs or outputs
;
DrawBorder  
	call	libDrawBorder
	ret



; InstallPort
; Installs new vector to PortISR, saving old vector
; No inputs/Outputs
InstallPort
	call	libInstallPort
	ret
	

; RemovePort
; No Input/Outputs
; Restores old handler for the appropriate serial port IRQ
RemovePort       
	call	libRemovePort
	ret


; PortISR
; services serial port interrupts
; No inputs/Outputs
PortISR
	jmp	libPortISR


	
; InstallKeyboard
; Installs new vector to KeyboardISR, saving old vector
; No inputs/Outputs
InstallKeyboard
	call	libInstallKeyboard
	ret


; RemoveKeyboard
; restores original keyboard vector
; No inputs/Outputs
RemoveKeyboard
	call	libRemoveKeyboard
	ret


; KeyboardISR
; handles esc=>[quit], shift keys=>call DrawKeyNames, regular key => [nextKey]
; No inputs/Outputs
KeyboardISR
	jmp	libKeyboardISR


; GetNextKey
; output: al = next key, unless esc was pressed
;	  dx = TOP_OFF if user typed, else = BOTTOM_OFF
GetNextKey 
	call	libGetNextKey
	ret



;TransmitKey
;Transmits the byte in al to the appropriate serial port
;Inputs		al=byte to transmit
;Outputs	none
TransmitKey
	call	libTransmitKey
	ret
	

;DrawNewLine
;Inputs:	
;		di=location of char below which to draw new line
;		dx=offset of the correct box(top or bottom)
;Outputs:	al=row#, ah=col#, di=offset of next char

DrawNewLine
	call	libDrawNewLine
	ret


;Inputs:	
;		di=location of char from which to bksp
;		dx=offset of the correct box(top or bottom)
;Outputs:	di=offset of next char
;		cursor to the right spot
DrawBackspace
	call	libDrawBackspace
	ret


;	
; inputs:	al = asciikey that the user just typed
;		di = current location on top box
;		si = current location on bottom box
;		dx = upper left corner of the current box
; output:	di = next char's location
;		si = next char's location

TypeKey
	call	libTypeKey
	ret


	


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


