; ECE 291 Fall 2001 MP4    
; -- Paint291 --
;
; Completed By:
;  Terrence Bradley Janas
;  http://www.uiuc.edu/~tjanas
;  tjanas@uiuc.edu
;  November 08, 2001
;
; Josh Potts
; Guest Author - Ryan Chmiel
; University of Illinois at Urbana-Champaign
; Dept. of Electrical & Computer Engineering
;
; Ver 1.0


%include "lib291.inc"
%include "libmp4.inc"

	BITS 32

	GLOBAL _main

; EXTERN	_LoadPNG

; Define Contstants

	DOWNARROW	EQU	80
	RIGHTARROW	EQU	77
	LEFTARROW	EQU	75
	UPARROW		EQU	72

	CANVAS_X	EQU	20
	CANVAS_Y	EQU	20

	NUM_MENU_ITEMS	EQU	11

	BKSP		EQU	8
	ESC		EQU	1
	ENTERKEY	EQU	13
	SPACE		EQU	57
	LSHIFT		EQU	42
	RSHIFT		EQU	54


	SECTION .bss

_GraphicsMode	resw	1	; Graphics mode #

_kbINT		resb	1	; Keyboard interrupt #
_kbIRQ		resb	1	; Keyboard IRQ
_kbPort		resw	1	; Keyboard port

_MouseSeg	resw	1       ; real mode segment for MouseCallback
_MouseOff	resw	1	; real mode offset for MouseCallback
_MouseX		resw	1       ; X coordinate position of mouse on screen
_MouseY		resw	1       ; Y coordinate position of mouse on screen
					
_ScreenOff	resd	1	; Screen image offset
_CanvasOff	resd	1	; Canvas image offset
_OverlayOff	resd	1	; Overlay image offset
_FontOff	resd	1	; Font image offset
_MenuOff	resd	1	; Menu image offset
_TitleOff	resd	1	; Title Bar image offset

_MPFlags	resb	1	; program flags
				; Bit 0 - Exit program
				; Bit 1 - Left mouse button (LMB) status: set if down, cleared if up
				; Bit 2 - Change in LMB status: set if button status
				;         moves from pressed->released or vice-versa
				; Bit 3 - Right shift key status: set if down, cleared if up
				; Bit 4 - Left shift key status: set if down, cleared if up
				; Bit 5 - Key other than shift was pressed
				; Bit 6 - Not Used Anymore
				; Bit 7 - Status of chosen color: set if obtained with user input,
                                ;         cleared if obtained with eyedrop (you do not have to deal
				;         with this - the library code uses it)
				
_MenuItem	resb	1	; selected menu item

; line algorithm variables				
_x		resw	1
_y		resw	1
_dx		resw	1
_dy		resw	1
_lineerror	resw	1
_xhorizinc	resw	1
_xdiaginc	resw	1
_yvertinc	resw	1
_ydiaginc	resw	1
_errordiaginc	resw	1
_errornodiaginc	resw	1
 
; circle algorithm variables
_radius		resw	1
_circleerror	resw	1
_xdist		resw	1
_ydist		resw	1

; flood fill variables
_PointQueue	resd	1
_QueueHead	resd	1
_QueueTail	resd	1

_key		resb	1


	SECTION .data

	
; Required image files
_FontFN		db	'font.png',0   
_MenuFN		db	'menu.png',0
_TitleFN	db	'title.png',0

; Defined color values
_CurrentColor	dd	0ffff0000h	; current color
_ColorBlue	dd	0ff0033ffh
_ColorWhite	dd	0ffffffffh
_ColorBlack	dd	0ff000000h
_ColorHalfBlack dd	0cc000000h

_buffer		db	'       ','$'

_ColorString1	db	'Enter numerical values for','$'
_ColorString2	db	'each channel (ARGB), and','$'
_ColorString3	db	'separate each number by a','$'
_ColorString4	db	'space (ex. 127 255 255 0).','$'
 
_QwertyNames
	db	0	; filler
	db	0,'1','2','3','4','5','6','7','8','9','0','-','=',BKSP
	db	0, 'q','w','e','r','t','y','u','i','o','p','[',']',ENTERKEY
	db	0,'a','s','d','f','g','h','j','k','l',';',"'","`"
	db	0,'\','z','x','c','v','b','n','m',",",'.','/',0,'*'
	db	0, ' ', 0, 0,0,0,0,0,0,0,0,0,0 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	0, 0, 0, '-'
	db	0, 0, 0, '+'
	db	0, 0, 0, 0
	db	0, 0; sysrq
_QwertyNames_end resb 0

_QwertyShift
	db	0	; filler
	db	0,'!','@','#','$','%','^','&','*','(',')','_','+',BKSP
	db	0, 'Q','W','E','R','T','Y','U','I','O','P','{','}',ENTERKEY
	db	0,'A','S','D','F','G','H','J','K','L',':','"','~'
	db	0,'|','Z','X','C','V','B','N','M',"<",'>','?',0,'*'
	db	0, ' ', 0, 0,0,0,0,0,0,0,0,0,0 ; F1-F10
	db	0,0	; numlock, scroll lock
	db	0, 0, 0, '-'
	db	0, 0, 0, '+'
	db	0, 0, 0, 0
	db	0, 0; sysrq
_QwertyShift_end resb 0

_TextInputString	times 80 db 0,'$'
_ColorInputString	times 15 db 0,'$'

_RoundingFactor	dd	000800080h, 00000080h


	SECTION .text


_main
	call	_LibInit

	; Allocate Screen Image buffer
	invoke	_AllocMem, dword 640*480*4
	cmp	eax, -1
	je	near .memerror
	mov	[_ScreenOff], eax

	; Allocate Canvas Image buffer
	invoke	_AllocMem, dword 480*400*4
	cmp	eax, -1
	je	near .memerror
	mov	[_CanvasOff], eax

	; Allocate Overlay Image buffer
	invoke	_AllocMem, dword 480*400*4
	cmp	eax, -1
	je	near .memerror
	mov	[_OverlayOff], eax

	; Allocate Font Image buffer
	invoke	_AllocMem, dword 2048*16*4
	cmp	eax, -1
	je	near .memerror
	mov	[_FontOff], eax  

	; Allocate Menu Image buffer
	invoke	_AllocMem, dword 400*100*4
	cmp	eax, -1
	je	near .memerror
	mov	[_MenuOff], eax 

	; Allocate Title Bar Image buffer
	invoke	_AllocMem, dword 640*20*4
	cmp	eax, -1
	je	near .memerror
	mov	[_TitleOff], eax 

	; Allocate Point Queue
	invoke	_AllocMem, dword 480*400*4*40
	cmp	eax, -1
	je	near .memerror
	mov	[_PointQueue], eax

	; Load image files
	invoke	_LoadPNG, dword _FontFN, dword [_FontOff], dword 0, dword 0 
	invoke	_LoadPNG, dword _MenuFN, dword [_MenuOff], dword 0, dword 0 
	invoke	_LoadPNG, dword _TitleFN, dword [_TitleOff], dword 0, dword 0 
 
	; Graphics init
	invoke	_InitGraphics, dword _kbINT, dword _kbIRQ, dword _kbPort
	test	eax, eax
	jnz	near .graphicserror

	; Find graphics mode: 640x480x32, allow driver-emulated modes
	invoke	_FindGraphicsMode, word 640, word 480, word 32, dword 1
	mov	[_GraphicsMode], ax

	; Keyboard/Mouse init
	call	_InstallKeyboard
	test	eax, eax
	jnz	near .keyboarderror
	invoke	_SetGraphicsMode, word [_GraphicsMode]
	test	eax, eax
	jnz	.setgraphicserror
	call	_InstallMouse
	test	eax, eax
	jnz	.mouseerror

	; Show mouse cursor	
	mov	dword [DPMI_EAX], 01h
	mov	bx, 33h
	call	DPMI_Int

	call	_MP4Main	

	; Shutdown and cleanup	      

.mouseerror
	call	_RemoveMouse

.setgraphicserror
	call	_UnsetGraphicsMode

.keyboarderror
	call	_RemoveKeyboard

.graphicserror
	call	_ExitGraphics

.memerror
	call	_MP4LibExit
	call	_LibExit
	ret





;-------------------------------------------------------------------------;
; PointInBox()								  ;
;									  ;
;   dword _PointInBox(word PointX, word PointY, word BoxULCornerX,	  ;
;		 word BoxULCornerY, word BoxLRCornerX, word BoxLRCornerY) ;
;									  ;
;   Inputs: X = x coordinate of point in question			  ;
;	    Y = y coordinate of point in question			  ;
;	    BoxULCornerX = x coordinate of upper-left hand corner of box  ;
;	    BoxULCornerY = y coordinate of upper-left hand corner of box  ;
;	    BoxLRCornerX = x coordinate of lower-right hand corner of box ;
;	    BoxLRCornerY = y coordinate of lower-right hand corner of box ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: eax = 1 if BoxULCornerX <= X <= BoxLRCornerX and		  ;
;		        BoxULCornerY <= Y <= BoxLRCornerY		  ;
;	         = 0 otherwise						  ;
;									  ;
;   Purpose: Determines if the point (X,Y) is located in the box formed	  ;
;	     by the points (BoxULCornerX,BoxULCornerY)			  ;
;	     and (BoxLRCornerX,BoxLRCornerY)				  ;
;									  ;
;-------------------------------------------------------------------------;
proc _PointInBox
.X		arg	2
.Y		arg	2
.BoxULCornerX	arg	2
.BoxULCornerY	arg	2
.BoxLRCornerX	arg	2
.BoxLRCornerY	arg	2
;invoke	_libPointInBox, word [ebp+.X], word [ebp+.Y], word [ebp+.BoxULCornerX], word [ebp+.BoxULCornerY], word [ebp+.BoxLRCornerX], word [ebp+.BoxLRCornerY]
;ret



 mov ax, word [ebp+.X]			; Check if the X coord is within box
 cmp ax, word [ebp+.BoxULCornerX]	; by checking UR corner and LR corner
 jb near .NotInBox

 cmp ax, word [ebp+.BoxLRCornerX]
 ja near .NotInBox


 mov ax, word [ebp+.Y]			; Check if the Y coord is within box
 cmp ax, word [ebp+.BoxULCornerY]	; by checking UR corner and LR corner
 jb near .NotInBox

 cmp ax, word [ebp+.BoxLRCornerY]
 ja near .NotInBox

 mov eax, 1				; If point is in box, return 1
 ret


 .NotInBox:
 xor eax, eax				; If point isn't in box, return 0
 ret



endproc
_PointInBox_arglen	EQU	12








;-------------------------------------------------------------------------;
; GetPixel()								  ;
;									  ;
;   dword _GetPixel(dword DestOff, word DestWidth, word DestHeight,	  ;
;                 word X, word Y)					  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X = x coordinate of point					  ;
;	    Y = y coordinate of point					  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: _PointInBox							  ;
;									  ;
;   Returns: eax = color of the pixel located at (X,Y) in the buffer	  ;
;	         = 0 if point is not within boundary of buffer		  ;
;									  ;
;   Purpose: Gets the color of the pixel located at the point (X,Y) in	  ;
;	     the buffer pointed to by DestOff				  ;
;									  ;
;-------------------------------------------------------------------------;
proc _GetPixel
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
;invoke	_libGetPixel, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]
;ret


 ; First check if pixel is a point in the box
 invoke _PointInBox, word [ebp + .X], word [ebp + .Y], word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
 test eax, eax
 jz near .InvalidPixel			; If point not in box, then return 0

 
 push ebx				; Save registers
 push ecx
 push edx

 
 movzx eax, word [ebp + .DestWidth]	; The pixel is at [DestOff + 4*(DestWidth*Y + X)]
 movzx ecx, word [ebp + .Y]		; So we set eax = DestWidth*Y
 mul ecx


 movzx ecx, word [ebp + .X]		; ecx = X


 add ecx, eax				; ecx = DestWidth*Y + X
 shl ecx, 2				; ecx = 4*(DestWidth*Y + X)
					; We multiply by 4 because each pixel is 4 bytes

 mov ebx, dword [ebp + .DestOff]
 add ebx, ecx				; ebx = DestOff + 4*(DestWidth*Y + X)
 mov eax, dword [ebx]			; Move pixel into eax


 pop edx				; Restore registers
 pop ecx
 pop ebx

 .InvalidPixel:
 ret



endproc
_GetPixel_arglen	EQU	12







;-------------------------------------------------------------------------;
; DrawPixel()								  ;
;									  ;
;   void _DrawPixel(dword DestOff, word DestWidth, word DestHeight,	  ;
;                 word X, word Y, dword Color)				  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X = x coordinate of point					  ;
;	    Y = y coordinate of point					  ;
;	    Color = color of pixel to draw				  ;
;									  ;
;   Outputs: Pixel drawn to buffer					  ;
;									  ;
;   Calls: _PointInBox							  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Draws a pixel with color Color at point (X,Y) in		  ;
;	     the buffer pointed to by DestOff				  ;
;									  ;
;-------------------------------------------------------------------------;
proc _DrawPixel
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4
;invoke	_libDrawPixel, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color]
;ret


 push eax

 invoke _PointInBox, word [ebp + .X], word [ebp + .Y], word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
 test eax, eax
 jz near .InvalidPixel			; If point not in box, then return


 push ebx
 push ecx
 push edx


 movzx eax, word [ebp + .DestWidth]	; The pixel is at [DestOff + 4*(DestWidth*Y + X)]
 movzx ecx, word [ebp + .Y]		; So we set eax = DestWidth*Y
 mul ecx



 movzx ecx, word [ebp + .X]		; ecx = X


 add ecx, eax				; ecx = DestWidth*Y + X
 shl ecx, 2				; ecx = 4*(DestWidth*Y + X)
					; We multiply by 4 because each pixel is 4 bytes


 mov ebx, dword [ebp + .DestOff]
 add ebx, ecx				; ebx = DestOff + 4*(DestWidth*Y + X)
 mov ecx, dword [ebp + .Color]
 mov dword [ebx], ecx			; Draw pixel with color at point (X,Y)
 

 pop edx				; Restore registers
 pop ecx
 pop ebx


 .InvalidPixel:

 pop eax

 ret


endproc
_DrawPixel_arglen	EQU	16










;-------------------------------------------------------------------------;
; DrawLine()								  ;
;									  ;
;   void _DrawLine(dword DestOff, word DestWidth, word DestHeight,	  ;
;                  word X1, word Y1, word X2, word Y2, dword Color)	  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X1 = x coordinate of start point				  ;
;	    Y1 = y coordinate of start point				  ;
;	    X2 = x coordinate of end point				  ;
;	    Y2 = y coordinate of end point				  ;
;	    Color = color of line to draw				  ;
;									  ;
;   Outputs: Line drawn to buffer					  ;
;									  ;
;   Calls: _DrawPixel							  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Draws a line with color Color from point (X1,Y1) to (X2,Y2)  ;
;	     in the buffer pointed to by DestOff			  ;
;									  ;
;-------------------------------------------------------------------------;
proc _DrawLine
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X1		arg	2
.Y1		arg	2
.X2		arg	2
.Y2		arg	2
.Color		arg	4
;invoke	_libDrawLine, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X1], word [ebp+.Y1], word [ebp+.X2], word [ebp+.Y2], dword [ebp+.Color]
;ret


 push ax				; Save registers
 push cx


					; Begin Bresenham's Line Algorithm:
 mov ax, word [ebp + .X2]		; dx = abs(x2 - x1)
 sub ax, word [ebp + .X1]
 cmp ax, 0
 jl near .AbsValueX
 jmp near .StoreDX



 .AbsValueX:				; if x2 - x1 is negative,
 neg ax					; then make value positive

 .StoreDX:
 mov word [_dx], ax			; _dx = abs(x2 - x1)


 ;Calculate (y2 - y1)
 mov ax, word [ebp + .Y2]		; dy = abs(y2 - y1)
 sub ax, word [ebp + .Y1]
 cmp ax, 0
 jl near .AbsValueY
 jmp near .StoreDY


 .AbsValueY:				; if y2 - y1 is negative,
 neg ax					; then make value positive


 .StoreDY:
 mov word [_dy], ax			; _dy = abs(y2 - y1)


 mov word [_xdiaginc], 1		; xdiaginc = 1  always
 mov word [_ydiaginc], 1		; ydiaginc = 1  always



 cmp ax, word [_dx]			; ax is currently holding _dy
 jg near .DYisBigger


 ;--- If dx >= dy then -----------------------------------------------

 shl ax, 1				; ax = 2 * dy
 mov word [_errornodiaginc], ax		; errornodiaginc = 2 * dy

 sub ax, [_dx]
 mov word [_lineerror], ax		; lineerror = (2 * dy) - dx

 mov ax, word [_dy]
 sub ax, word [_dx]
 shl ax, 1
 mov word [_errordiaginc], ax		; errordiaginc = 2 * (dy - dx)

 mov ax, word [_dx]
 inc ax
 mov cx, ax				; numpixels = cx = dx + 1

 mov word [_xhorizinc], 1		; xhorizinc = 1
 mov word [_yvertinc], 0		; yvertinc = 0
 jmp near .CheckXinc

 ;--------------------------------------------------------------------
 ;
 ;
 ;--- Else (dy > dx) -------------------------------------------------

 .DYisBigger:
 mov word [_xhorizinc], 0		; xhorizinc = 0
 mov word [_yvertinc], 1		; yvertinc = 1

 mov cx, ax				; ax is currently holding _dy
 inc cx					; numpixels = cx = dy + 1

 mov ax, word [_dx]
 shl ax, 1
 mov word [_errornodiaginc], ax		; errornodiaginc = 2 * dx

 sub ax, word [_dy]
 mov word [_lineerror], ax		; lineerror = (2 * dx) - dy

 mov ax, word [_dx]
 sub ax, word [_dy]
 shl ax, 1				; errordiaginc = 2 * (dx - dy)
 mov word [_errordiaginc], ax

;---------------------------------------------------------------------


 ;----------
 .CheckXinc:
 ;----------
    mov ax, word [ebp + .X1]
    cmp ax, word [ebp + .X2]		; Check if x1 > x2
    jng .CheckYinc

    neg word [_xhorizinc]		; If so, then xhorizinc = -xhorizinc
    neg word [_xdiaginc]		;         and xdiaginc  = -xdiaginc


 ;----------
 .CheckYinc:
 ;----------
    mov ax, word [ebp + .Y1]
    cmp ax, word [ebp + .Y2]		; Check if y1 > y2
    jng .SetXandY

    neg word [_yvertinc]		; If so, then yvertinc = -yvertinc
    neg word [_ydiaginc]		;         and ydiaginc = -ydiaginc


 ;---------
 .SetXandY:
 ;---------
    mov ax, word [ebp + .X1]
    mov word [_x], ax			; x = x1
    mov ax, word [ebp + .Y1]
    mov word [_y], ax			; y = y1




 ;----------
 .PixelLoop:
 ;----------
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y], dword [ebp + .Color]
    mov ax, word [_lineerror]
    cmp ax, 0
    jge .NotNegativeError

    add ax, word [_errornodiaginc]
    mov word [_lineerror], ax		; lineerror = lineerror + errornodiaginc

    mov ax, word [_x]
    add ax, word [_xhorizinc]
    mov word [_x], ax			; x = x + xhorizinc

    mov ax, word [_y]
    add ax, word [_yvertinc]
    mov word [_y], ax			; y = y + yvertinc
    jmp near .CheckCounter


  ;-----------------
  .NotNegativeError:
  ;-----------------
     add ax, word [_errordiaginc]
     mov word [_lineerror], ax		; lineerror = lineerror + errordiaginc

     mov ax, word [_x]
     add ax, word [_xdiaginc]
     mov word [_x], ax			; x = x + xdiaginc

     mov ax, word [_y]
     add ax, word [_ydiaginc]
     mov word [_y], ax			; y = y + ydiaginc


  ;-------------
  .CheckCounter:
  ;-------------
     dec cx				; loop PixelLoop as many times
     jnz near .PixelLoop		; as there are pixels


    pop cx				; Restore registers
    pop ax
    ret

endproc
_DrawLine_arglen	EQU	20









;-------------------------------------------------------------------------;
; DrawRect()								  ;
;									  ;
;   void _DrawRect(dword DestOff, word DestWidth, word DestHeight,	  ;
;                  word X1, word Y1, word X2, word Y2,			  ;
;		   dword Color, dword FillRectFlag)			  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X1 = x coordinate of start point				  ;
;	    Y1 = y coordinate of start point				  ;
;	    X2 = x coordinate of end point				  ;
;	    Y2 = y coordinate of end point				  ;
;	    Color = color of rectangle to draw				  ;
;	    FillRectFlag = flag to determine whether or not to fill	  ;
;			   the rectangle				  ;
;									  ;
;   Outputs: Rectangle drawn to buffer, filled if necessary		  ;
;									  ;
;   Calls: _DrawLine, _FloodFill					  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Draws a rectangle with color Color from point (X1,Y1)	  ;
;	     to (X2,Y2) in the buffer pointed to by DestOff		  ;
;									  ;
;-------------------------------------------------------------------------;
proc _DrawRect
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X1		arg	2
.Y1		arg	2
.X2		arg	2
.Y2		arg	2
.Color		arg	4
.FillRectFlag	arg	4
;invoke	_libDrawRect, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X1], word [ebp+.Y1], word [ebp+.X2], word [ebp+.Y2], dword [ebp+.Color], dword [ebp+.FillRectFlag]
;ret




 ; Draw the 4 lines of the rectangle
 invoke	_DrawLine, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X1], word [ebp + .Y1], word [ebp + .X2], word [ebp + .Y1], dword [ebp + .Color]
 invoke	_DrawLine, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X1], word [ebp + .Y1], word [ebp + .X1], word [ebp + .Y2], dword [ebp + .Color]
 invoke	_DrawLine, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X1], word [ebp + .Y2], word [ebp + .X2], word [ebp + .Y2], dword [ebp + .Color]
 invoke	_DrawLine, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X2], word [ebp + .Y1], word [ebp + .X2], word [ebp + .Y2], dword [ebp + .Color]


 cmp dword [ebp + .FillRectFlag], 0	; Check whether to fill the rectangle
 jz near .End


 push ax
 push cx

 mov ax, word [ebp + .X1]		; X coordinate of point in center of
 add ax, word [ebp + .X2]		; box is (X1 + X2)/2
 shr ax, 1

 mov cx, word [ebp + .Y1]		; Y coordinate of point in center of
 add cx, word [ebp + .Y2]		; box is (Y1 + Y2)/2
 shr cx, 1

 invoke	_FloodFill, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word ax, word cx, dword [ebp + .Color], dword 0
 
 pop cx
 pop ax


 .End:
 ret


endproc
_DrawRect_arglen	EQU	24








;-------------------------------------------------------------------------;
; DrawCircle()								  ;
;									  ;
;   void _DrawCircle(dword DestOff, word DestWidth, word DestHeight,	  ;
;                  word X, word Y, word Radius, dword Color,		  ;
;		   dword FillCircleFlag)				  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X = x coordinate of center					  ;
;	    Y = y coordinate of center					  ;
;	    Color = color of circle to draw				  ;
;	    FillCircleFlag = flag to determine whether or not to fill	  ;
;			     the circle					  ;
;									  ;
;   Outputs: Circle drawn to buffer, filled if necessary		  ;
;									  ;
;   Calls: _DrawPixel, _FloodFill					  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Draws a circle with center (X1,Y1), color Color, and	  ;
;	     radius Radius in the buffer pointed to by DestOff		  ;
;									  ;
;-------------------------------------------------------------------------;
proc _DrawCircle
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Radius		arg	2
.Color		arg	4
.FillCircleFlag	arg	4
;invoke	_libDrawCircle, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], word [ebp+.Radius], dword [ebp+.Color], dword [ebp+.FillCircleFlag]
;ret




 push ax				; Save registers
 push bx
 push cx
 push dx


					; Begin Bresenham's Circle Algorithm:
 mov word [_xdist], 0			; xdist = 0
 mov ax, word [ebp + .Radius]
 mov word [_ydist], ax			; ydist = r
 mov word [_circleerror], 1 
 sub word [_circleerror], ax		; circleerror = 1 - r



 ;----------
 .PixelLoop:
 ;----------
					; DrawPixel(x + xdist, y + ydist)
					; DrawPixel(x - xdist, y + ydist)
					; DrawPixel(x + xdist, y - ydist)
					; DrawPixel(x - xdist, y - ydist)

    mov ax, word [ebp + .X]
    mov cx, ax
    add ax, word [_xdist]		; ax = x + xdist
    mov bx, word [ebp + .Y]
    mov dx, bx
    add bx, word [_ydist]		; bx = y + ydist

    sub cx, word [_xdist]		; cx = x - xdist
    sub dx, word [_ydist]		; dx = y - ydist
 
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word ax, word bx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word cx, word bx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word ax, word dx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word cx, word dx, dword [ebp + .Color]




					; DrawPixel(x + ydist, y + xdist)
					; DrawPixel(x - ydist, y + xdist)
					; DrawPixel(x + ydist, y - xdist)
					; DrawPixel(x - ydist, y - xdist)

    mov ax, word [ebp + .X]
    mov cx, ax
    add ax, word [_ydist]		; ax = x + ydist
    mov bx, word [ebp + .Y]
    mov dx, bx
    add bx, word [_xdist]		; bx = y + xdist

    sub cx, word [_ydist]		; cx = x - ydist
    sub dx, word [_xdist]		; dx = y - xdist

    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word ax, word bx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word cx, word bx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word ax, word dx, dword [ebp + .Color]
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word cx, word dx, dword [ebp + .Color]




    inc word [_xdist]


    cmp word [_circleerror], 0
    jge near .NonnegError


    ;--- If (circleerror < 0) then -----------------------------------
    ;								     ;
    mov ax, word [_xdist]					     ;
    shl ax, 1							     ;
    inc ax							     ;
    add ax, word [_circleerror]					     ;
    mov word [_circleerror], ax					     ;
    jmp near .LoopCheck						     ;
    ;								     ;
    ;-----------------------------------------------------------------

    ;--- Else (circleerror >= 0) -------------------------------------
    ;								     ;
    .NonnegError:						     ;
    dec word [_ydist]						     ;
    mov ax, word [_xdist]					     ;
    sub ax, word [_ydist]					     ;
    shl ax, 1							     ;
    inc ax							     ;
    add ax, word [_circleerror]					     ;
    mov word [_circleerror], ax					     ;
    ;								     ;
    ;-----------------------------------------------------------------


 ;----------
 .LoopCheck:
 ;----------

    mov ax, word [_xdist]		; Repeat PixelLoop as long as
    cmp ax, word [_ydist]		; (xdist <= ydist) is true
    jle near .PixelLoop




 cmp dword [ebp + .FillCircleFlag], 0	; Check whether or not to fill circle
 jz near .End

 invoke	_FloodFill, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X], word [ebp + .Y], dword [ebp + .Color], dword 0



 ;----
 .End:
 ;----
    pop dx				; Restore registers
    pop cx
    pop bx
    pop ax
    ret

endproc
_DrawCircle_arglen	EQU	22







;-------------------------------------------------------------------------;
; DrawText()								  ;
;									  ;
;   void _DrawText(dword StringOff, dword DestOff, word DestWidth,	  ;
;		   word DestHeight, word X, word Y, dword Color)	  ;
;									  ;
;   Inputs: StringOff = offset of string to draw			  ;
;	    DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    X = x coordinate of start point				  ;
;	    Y = y coordinate of start point				  ;
;	    Color = color of the string to draw				  ;
;	    [_FontOff] = offset of font image data			  ;
;									  ;
;   Outputs: String drawn to buffer					  ;
;									  ;
;   Calls: _PointInBox							  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Draws a text string pointed to by StringOff with color	  ;
;	     Color at point (X,Y) in the buffer pointed to by DestOff 	  ;
;									  ;
;-------------------------------------------------------------------------;
proc _DrawText
.StringOff	arg	4
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4

;invoke	_libDrawText, dword [ebp+.StringOff], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color]
;ret



 pushad						; Save registers


 mov ax, word [ebp+.X]
 mov word [_x], ax				; Use _x = X coord

 mov ax, word [ebp+.Y]
 mov word [_y], ax				; Use _y = Y coord

 mov word [_dx], 0				; String offset




 ;--------------
 .PositionCheck:
 ;--------------
    mov eax, dword [ebp+.StringOff]
    movzx ebx, word [_dx]
    add eax, ebx

    mov bl, byte [eax]				; bl = character in string
    cmp bl, '$'
    je near .End				; we are at the end of the string

    test bl, bl
    jz near .End


    movzx ecx, bl
    shl ecx, 6
    mov esi, dword [_FontOff]
    add esi, ecx

    xor dx, dx
    xor cx, cx



 ;----------
 .NextPoint:
 ;----------
    invoke _PointInBox, word [_x], word [_y], word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
    test eax, eax
    jz near .OutsideBorder
	
    test cx, cx
    jnz near .ColorText
	
    cmp dx, 16
    je near .Done



 ;----------
 .ColorText:
 ;----------
    push edx					; Save registers
    push ecx					; Use temporarily

    movzx ecx, word [_y]
    movzx eax, word [ebp+.DestWidth]

    mul ecx
    mov edx, eax
    movzx eax, word [_x]
    add edx, eax
    shl edx, 2
    mov dword edi, dword [ebp+.DestOff]
    add edi, edx


    mov	eax, dword [ebp+.Color]
    mov dword [edi], eax
    and dword [edi], 00FFFFFFh			; Clear ALPHA byte
    mov eax, dword [esi]
    and eax, 0FF000000h				; Keep only ALPHA byte
    or dword [edi], eax				; Combine color and alpha
	
    pop ecx					; Restore registers
    pop edx




 ;--------------
 .OutsideBorder:
 ;--------------
   add esi, 4

   inc word [_x]
   inc cx

   cmp cx, 16				; If we are at end of the row of the char image, then wraparound
   je near .Wraparound

   cmp dx, 16
   je near .Done
	
   jmp near .NextPoint




 ;-----------
 .Wraparound:
 ;-----------
    add esi, dword 8128			; 8128 = length of the whole font image
    sub word [_x], 16
    inc word [_y]
    inc dx
    xor cx, cx
    jmp near .NextPoint



 ;-----
 .Done:
 ;-----
    inc word [_dx]
    mov ax, word [ebp+.Y]
    mov word [_y], ax
    mov ax, word [ebp+.X]
    mov word [_x], ax
    mov ax, word [_dx]
    shl ax, 4
    add word [_x], ax
    jmp near .PositionCheck



 ;----
 .End:
 ;----
    popad				; Restore registers
    ret


endproc
_DrawText_arglen	EQU	20







;-------------------------------------------------------------------------;
; ClearBuffer()								  ;
;									  ;
;   void _ClearBuffer(dword DestOff, word DestWidth, word DestHeight,	  ;
;		      dword Color)					  ;
;									  ;
;   Inputs: DestOff = offset of an image buffer in memory		  ;
;	    DestWidth = width of the buffer				  ;
;	    DestHeight = height of the buffer				  ;
;	    Color = color to make buffer				  ;
;									  ;
;   Outputs: Color copyied to buffer					  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Clears a buffer pointed to by DestOff by filling it	  ;
;	     with color Color						  ;
;									  ;
;-------------------------------------------------------------------------;
proc _ClearBuffer
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.Color		arg	4
;invoke	_libClearBuffer, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], dword [ebp+.Color]
;ret


 push eax				; Save registers
 push ecx
 push edx
 push edi


 mov edi, dword [ebp + .DestOff]
 movzx eax, word [ebp + .DestWidth]
 movzx ecx, word [ebp + .DestHeight]
 mul ecx
 mov ecx, eax				; ecx = DestWidth*DestHeight
 mov eax, dword [ebp + .Color]		; Write Color ecx times

 CLD					; Auto-increment edi by 4

 REP STOSD				; Loop until ecx=0


 pop edi				; Restore registers
 pop edx
 pop ecx
 pop eax

 ret


endproc
_ClearBuffer_arglen	EQU	12







;-------------------------------------------------------------------------;
; CopyBuffer()								  ;
;									  ;
;   void _CopyBuffer(dword SrcOff, word SrcWidth, word SrcHeight,	  ;
;		     dword DestOff, word DestWidth, word DestHeight,	  ;
;		     word X, word Y)					  ;
;									  ;
;   Inputs: SrcOff = offset of source buffer				  ;
;	    SrcWidth = width of source buffer 				  ;
;	    SrcHeight = height of source buffer 			  ;
;	    DestOff = offset of destination buffer 			  ;
;           DestWidth = width of destination buffer			  ;
;	    DestHeight = height of destination buffer			  ;
;	    X = x coordinate of start point in destination buffer	  ;
;	    Y = y coordinate of start point in destination buffer	  ;
;									  ;
;   Outputs: Source buffer copied onto destination buffer		  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Copies a source buffer pointed to by SrcOff to a		  ;
;	     location (X,Y) in a destination buffer pointed to by DestOff ;
;									  ;
;-------------------------------------------------------------------------;
proc _CopyBuffer
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
;invoke	_libCopyBuffer, dword [ebp+.SrcOff], word [ebp+.SrcWidth], word [ebp+.SrcHeight], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]
;ret


 push eax				; Save registers
 push ecx
 push edi
 push esi
 push edx


 mov esi, dword [ebp + .SrcOff]		; esi = SrcOff
 mov edi, dword [ebp + .DestOff]	; edi = DestOff


 movzx eax, word [ebp + .DestWidth]
 movzx ecx, word [ebp + .Y]
 mul ecx				; eax = DestWidth*Y
 movzx ecx, word [ebp + .X]
 add eax, ecx				; eax = DestWidth*Y + .X
 shl eax, 2				; each pixel is 4 bytes

 add edi, eax				; edi = DestOff + 4*(DestWidth*Y + X)



 mov dx, word [ebp + .SrcHeight]	; dx = # of rows of the
					; source buffer to copy
 CLD					; Auto-increment di, si for MOVSD


 ;--------
 .RowLoop:
 ;--------
    movzx ecx, word [ebp + .SrcWidth]	; ecx = # of pixels in row of Src


    REP MOVSD				; Copy pixels ecx many times

    movzx eax, word [ebp + .DestWidth]	; To get to the beginning of the next
    shl eax, 2				; line, add the DestWidth to di and
    add edi, eax			; then subtract the SrcWidth from di
    movzx eax, word [ebp + .SrcWidth]
    shl eax, 2
    sub edi, eax
    dec dx
					; Repeat until all rows from Src
    jnz near .RowLoop			; are copied to Dest buffer


 pop edx				; Restore registers
 pop esi
 pop edi
 pop ecx
 pop eax

 ret


endproc
_CopyBuffer_arglen	EQU	20







;-------------------------------------------------------------------------;
; CopyBuffer()								  ;
;									  ;
;   void _CopyBuffer(dword SrcOff, word SrcWidth, word SrcHeight,	  ;
;		     dword DestOff, word DestWidth, word DestHeight,	  ;
;		     word X, word Y)					  ;
;									  ;
;   Inputs: SrcOff = offset of source buffer				  ;
;	    SrcWidth = width of source buffer 				  ;
;	    SrcHeight = height of source buffer 			  ;
;	    DestOff = offset of destination buffer 			  ;
;           DestWidth = width of destination buffer			  ;
;	    DestHeight = height of destination buffer			  ;
;	    X = x coordinate of start point in destination buffer	  ;
;	    Y = y coordinate of start point in destination buffer	  ;
;									  ;
;   Outputs: Source buffer alpha composed onto destination buffer	  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Alpha composes a source buffer pointed to by SrcOff onto a	  ;
;	     destination buffer pointed to by DestOff at location (X,Y)	  ;
;									  ;
;-------------------------------------------------------------------------;
proc _ComposeBuffers
.SrcOff		arg	4
.SrcWidth	arg	2
.SrcHeight	arg	2
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X	        arg	2
.Y		arg	2

;invoke	_libComposeBuffers, dword [ebp+.SrcOff], word [ebp+.SrcWidth], word [ebp+.SrcHeight], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y]
;ret


 pushad

 mov esi, dword [ebp + .SrcOff]
 mov edi, dword [ebp + .DestOff]

 movzx eax, word [ebp + .DestWidth]
 movzx ecx, word [ebp + .Y]
 mul ecx
 movzx ecx, word [ebp + .X]
 add eax, ecx
 shl eax, 2

 add edi, eax

 mov bx, word [ebp + .SrcHeight]



 ;-----------
 .HeightLoop:
 ;-----------
    test bx, bx
    jz near .End

    movzx ecx, word [ebp + .SrcWidth]
    shr ecx, 1					; We are doing 2 pixels at once



 ;--------
 .RowLoop:
 ;--------
    test cx, cx
    jz near .LoopCheck


    movq mm0, qword [esi]
    movq mm1, mm0


    pxor mm7, mm7				; mm7 = [00][00][00][00]
    PUNPCKLBW mm0, mm7				; mm0 = unpacked source#1
    PUNPCKHBW mm1, mm7				; mm1 = unpacked source#2



    movq mm2, qword [edi]
    movq mm3, mm2
    PUNPCKLBW mm2, mm7				; mm2 = unpacked destination#1
    PUNPCKHBW mm3, mm7				; mm3 = unpacked destination#2



    movq mm5, mm0				; mm5 = [0A][0R][0G][0B]
    PUNPCKHWD mm5, mm5				; mm5 = [0A][0A][0R][0R]
    PUNPCKHDQ mm5, mm5				; mm5 = Source#1 ALPHA



    movq mm6, mm1				; mm6 = [0A][0R][0G][0B]
    PUNPCKHWD mm6, mm6				; mm6 = [0A][0A][0R][0R]
    PUNPCKHDQ mm6, mm6				; mm6 = Source#2 ALPHA



    pmullw mm0, mm5				; mm0 = Source#1 * ALPHA1
    pmullw mm1, mm6				; mm1 = Source#2 * ALPHA2

    paddw mm0, qword [_RoundingFactor]		; Step#4
    paddw mm1, qword [_RoundingFactor]		;


    psrlw mm0, 8				; Step#5
    psrlw mm1, 8				;


    paddw mm0, mm2				; Step#7
    paddw mm1, mm3


    pmullw mm2, mm5				; mm2 = Destination#1 * ALPHA1
    pmullw mm3, mm6				; mm3 = Destination#2 * ALPHA2


    paddw mm2, qword [_RoundingFactor]		; Step#9
    paddw mm3, qword [_RoundingFactor]


    psrlw mm2, 8				; Step#10
    psrlw mm3, 8


    psubw mm0, mm2				; Step#11
    psubw mm1, mm3


    packuswb mm0, mm1				; Pack both pixels and write to DestBuffer
    movq qword [edi], mm0


    add edi, 8					; Next 2 pixels are 8 bytes away
    add esi, 8

    dec cx					; Check if we are done with row
    jmp near .RowLoop



 ;----------
 .LoopCheck:
 ;----------
    movzx eax, word [ebp + .DestWidth]
    sub ax, word [ebp + .SrcWidth]
    shl eax, 2
    add edi, eax

    dec bx
    jmp near .HeightLoop


 ;----
 .End:
 ;----
    popad
    emms
    ret


endproc
_ComposeBuffers_arglen	EQU	20












;-------------------------------------------------------------------------;
; BlurBuffer()								  ;
;									  ;
;   void _CopyBuffer(dword SrcOff, dword DestOff, word DestWidth,	  ;
;		     word DestHeight)					  ;
;									  ;
;   Inputs: SrcOff = offset of source buffer				  ;
;	    DestOff = offset of destination buffer 			  ;
;           DestWidth = width of destination buffer			  ;
;	    DestHeight = height of destination buffer			  ;
;									  ;
;   Outputs: Source buffer blurred and written to destination buffer	  ;
;									  ;
;   Calls: _PointInBox							  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Blurs the buffer pointed to by SrcOff and writes the	  ;
;	     blurred buffer to the buffer pointed to by DestOff		  ;
;									  ;
;-------------------------------------------------------------------------;
proc _BlurBuffer
.SrcOff		arg	4
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2

;invoke	_libBlurBuffer, dword [ebp+.SrcOff], dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight]
;ret


 pushad

 mov word [_x], 0			; Use [_x] as our X coordinate
 mov word [_y], 0			; Use [_y] as our Y coordinate

 
 mov esi, dword [ebp + .SrcOff]
 mov edi, dword [ebp + .DestOff]
	
 movzx eax, word [ebp + .DestWidth]
 movzx ecx, word [ebp + .DestHeight]
 mul ecx
 mov ecx, eax				; ecx = total number of pixels




 ;--------
 .RowLoop:
 ;--------
 invoke _PointInBox, word [_x], word [_y], word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
 cmp eax, 0
 je near .InvalidPoint


 emms

 movd mm0, dword [esi]			; mm0 = [00][00][AR][GB] of center pixel
 pxor mm1, mm1				; mm1 = [00][00][00][00]
 punpcklbw mm0, mm1			; mm0 = [0A][0R][0G][0B]
 psllw mm0, 2				; Each component of center pixel multiplied by 4






 dec word [_x]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]

 movd mm1, eax				; mm1 = [00][00][AR][GB] of left pixel
 pxor mm2, mm2				; mm2 = [00][00][00][00]
 punpcklbw mm1, mm2			; mm1 = [0A][0R][0G][0B]
 psllw mm1, 1				; Each component of left pixel multiplied by 2
 paddusw mm0, mm1			; mm0 = center + left
 inc word [_x]






 inc word [_x]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]

 movd mm1, eax
 punpcklbw mm1, mm2
 psllw mm1, 1
 paddusw mm0, mm1			; mm0 = center + left + right
 dec word [_x]





 
 
 dec word [_x]
 dec word [_y]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]

 movd mm1, eax
 punpcklbw mm1, mm2
 paddusw mm0, mm1			; mm0 = center + left + right + UL
 inc word [_x]







 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]

 movd mm1, eax
 punpcklbw mm1, mm2
 psllw mm1, 1
 paddusw mm0, mm1			; mm0 = center + left + right + UL + top

 





 inc word [_x]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]

 movd mm1, eax
 punpcklbw mm1, mm2
 paddusw mm0, mm1			; mm0 = center + left + right + UL + top + UR
 dec word [_x]
 inc word [_y]








 dec word [_x]
 inc word [_y]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]
 mov	bx, word [ebp+.DestHeight]
 cmp	word [_y], bx
 jne	.LLPixel
 xor	eax, eax			; If we are at bottom row, ignore LL pixel

 .LLPixel:
 movd mm1, eax
 punpcklbw mm1, mm2
 paddusw mm0, mm1			; mm0 = center + left + right + UL + top + UR + LL
 inc word [_x]








 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]
 mov bx, word [ebp+.DestHeight]
 cmp word [_y], bx
 jne .BotPixel
 xor eax, eax				; If we are at bottom row, ignore bottom pixel

 .BotPixel:
 movd mm1, eax
 punpcklbw mm1, mm2
 psllw mm1, 1
 paddusw mm0, mm1			; mm0 = center + left + right + UL + top + UR + LL + bottom








 inc word [_x]
 invoke _GetPixel, dword [ebp + .SrcOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [_x], word [_y]
 mov bx, word [ebp+.DestHeight]
 cmp word [_y], bx
 jne .LRPixel
 xor eax, eax				; If we are at bottom row, ignore LR pixel

 .LRPixel:
 movd mm1, eax
 punpcklbw mm1, mm2
 paddusw mm0, mm1			; mm0 = (center + left + right) + (UL + top + UR) + (LL + bottom + LR)
 dec word [_y]




 psrlw mm0, 4				; mm0 = ((center + left + right) + (UL + top + UR) + (LL + bottom + LR))/16
 packuswb mm0, mm2			; mm0 = blurred pixel [00][00][AR][GB]
 movd dword [edi], mm0			; write pixel to memory



 ;-------------
 .InvalidPoint:
 ;-------------
    add edi, 4				; point to next pixel
    add esi, 4

    mov	ax, word [ebp + .DestWidth]
    cmp	word [_x], ax
    jne	.NotEndofRow
    mov	word [_x], 0
    inc	word [_y]



 ;------------
 .NotEndofRow:
 ;------------
    dec ecx
    jnz near .RowLoop


    popad
    emms
    ret


endproc
_BlurBuffer_arglen	EQU	12








;-------------------------------------------------------------------------;
; FloodFill()								  ;
;									  ;
;   void _CopyBuffer(dword DestOff, word DestWidth, word DestHeight,	  ;
;                     word X, word Y, dword .Color, dword ComposeFlag)	  ;
;									  ;
;   Inputs: DestOff= offset of an image buffer in memory		  ;
;           DestWidth = width of destination buffer			  ;
;	    DestHeight = height of destination buffer			  ;
;	    X = x coordinate of point in the region			  ;
;	    Y = y coordinate of point in the region			  ;
;	    Color = new color for region				  ;
;	    ComposeFlag = flag to determine whether or not to alpha	  ;
;	               compose the current color of the region with Color ;
;									  ;
;   Outputs: Region filled with color Color in buffer			  ;
;									  ;
;   Calls: _PointInBox, _GetPixel, _DrawPixel				  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Performs a flood fill operation on a region in the buffer	  ;
;	     pointed to by DestOff					  ;
;									  ;
;-------------------------------------------------------------------------;
proc _FloodFill
.DestOff	arg	4
.DestWidth	arg	2
.DestHeight	arg	2
.X		arg	2
.Y		arg	2
.Color		arg	4
.ComposeFlag	arg	4

;invoke	_libFloodFill, dword [ebp+.DestOff], word [ebp+.DestWidth], word [ebp+.DestHeight], word [ebp+.X], word [ebp+.Y], dword [ebp+.Color], dword [ebp+.ComposeFlag]
;ret



 pushad


 mov eax, dword[_PointQueue]
 mov dword [_QueueHead], eax			; Initialize _QueueHead to front of Queue
 mov dword [_QueueTail], eax			; Initialize _QueueTail to front of Queue






 dec word [ebp + .DestHeight]			; Temporarily change DestWidth, DestHeight for PointInBox
 dec word [ebp + .DestWidth]
 invoke _PointInBox, word [ebp + .X], word [ebp + .Y], word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
 inc word [ebp + .DestWidth]
 inc word [ebp + .DestHeight]



 test ax, ax
 jz near .End



 mov ebx, dword [_QueueTail]		; Enqueue(x,y)
 mov dx, word [ebp + .X]		; Place (x,y) at location of [_QueueTail],
 mov word [ebx], dx			; then add 4 to [_QueueTail]
 mov dx, word[ebp + .Y]
 mov word [ebx + 2], dx
 add dword [_QueueTail], 4




 invoke _GetPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], word [ebp + .X], word [ebp + .Y]
 mov edx, eax				; edx = OldColor

 cmp dword [ebp + .ComposeFlag], 0	; If ComposeFlag is set, update the value of the new color
 je near .PixelLoop			; by alpha composing onto the current color





 ;--------- Begin Alpha Compose the Two Colors ---------;

 movd mm0, dword [ebp + .Color]
 movd mm1, edx

 pxor mm3, mm3

 punpcklbw mm0, mm3			; Unpack (bytes to words) the source pixel into an MMX register
 movq mm2, mm0				; Copy out the source alpha byte into the four words of another MMX register
 punpckhwd mm2, mm2			; mm2 = [0A][0A][0R][0R] 
 punpckhdq mm2, mm2			; mm2 = [0A][0A][0A][0A]
 pmullw mm0, mm2			; Multiply the two previously mentioned MMX registers together
	
 paddw mm0, qword [_RoundingFactor]	; Add the rounding factor to the previous result to round the upcoming division
 psrlw mm0, 8				; Shift each word right to divide by 256, thus fitting into a byte per channel (this calculates a * A)
	
 punpcklbw mm1, mm3			; Unpack (bytes to words) the destination pixel into an MMX register
 paddw mm0, mm1				; Add the results of the previous two steps (this calculates a * A + B)
 pmullw mm1, mm2			; Multiply the destination pixel by the source alpha
 paddw mm1, qword [_RoundingFactor]	; Add the rounding factor to the previous result to round the upcoming division
 psrlw mm1, 8				; Shift each word right to divide by 256, thus fitting into a byte per channel (this calculates a * B)
 psubw mm0, mm1				; Subtract the value of step 10 from the value of step 7, giving you (a * A) + B - (a * B)

 packuswb mm0, mm3			; Pack (words to bytes) the two alpha-composed pixels back together with proper saturation in the correct order
 movd eax, mm0
 emms
 mov dword [ebp + .Color], eax		; Write the composed pixels back to memory

 ;--------- End Alpha Compose the Two Colors  ---------;






 ;----------
 .PixelLoop:				; while (QueueHead < QueueTail)
 ;----------
    mov ecx, [_QueueHead]
    cmp ecx, [_QueueTail]
    jnb near .End
	
    mov ebx, dword [_QueueHead]		; Point = Dequeue()
    mov si, word [ebx]			; si = Point.X
    mov di, word [ebx + 2]		; di = Point.Y
    add dword [_QueueHead], 4		; To dequeue, read point at [_QueueHead], then add 4 to [_QueueHead]

    dec word [ebp + .DestWidth]
    dec word [ebp + .DestHeight]
    invoke _PointInBox, si, di, word 0, word 0, word [ebp + .DestWidth], word[ebp + .DestHeight]
    inc word [ebp + .DestWidth]
    inc word [ebp + .DestHeight]

    test eax, eax			; Check if invalid point
    jz near .PixelLoop




    invoke _GetPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], si, di
    cmp edx, eax
    jne near .PixelLoop

    cmp edx, dword [ebp+.Color]
    je near .PixelLoop
	


    ;--- Do below if GetPixel(Point.x,Point.y) = OldColor  AND  GetPixel(Point.x,Point.y) != Color then ---;

    ; DrawPixel(Point.x,Point.y,Color)
    invoke _DrawPixel, dword [ebp + .DestOff], word [ebp + .DestWidth], word [ebp + .DestHeight], si, di, dword [ebp + .Color]
	
    mov	ebx, dword [_QueueTail]
    inc	si
    dec	word [ebp + .DestWidth]
    dec	word [ebp + .DestHeight]
    invoke _PointInBox, si, di, word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
    inc	word [ebp + .DestWidth]
    inc	word [ebp + .DestHeight]
    test eax, eax
    jz near .EnqueueLeft		; If invalid point, don't enqueue it
	
    ;Enqueue(Point.x+1,Point.y)		; Right Point
    mov word [ebx], si
    mov word [ebx + 2], di
    add dword [_QueueTail], 4





    ;------------
    .EnqueueLeft:
    ;------------
    dec si
    dec si
    mov ebx, dword [_QueueTail]
    dec word [ebp+.DestWidth]
    dec word [ebp+.DestHeight]
    invoke _PointInBox, si, di, word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
    inc word [ebp + .DestWidth]
    inc word [ebp + .DestHeight]
    test eax, eax
    jz near .EnqueueBottom		; If invalid point, don't enqueue it

    ; Enqueue(Point.x-1,Point.y)	; Left Point
    mov word [ebx], si
    mov word [ebx + 2], di
    add dword [_QueueTail], 4






    ;--------------
    .EnqueueBottom:
    ;--------------
    inc si
    inc di
    mov ebx, dword [_QueueTail]
    dec word [ebp + .DestWidth]
    dec word [ebp + .DestHeight]
    invoke _PointInBox, si, di, word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
    inc word [ebp+.DestWidth]
    inc word [ebp+.DestHeight]
    test eax, eax
    jz near .EnqueueTop			; If invalid point, don't enqueue it

    ; Enqueue(Point.x,Point.y+1)	; Bottom Point
    mov word [ebx], si
    mov word [ebx + 2], di
    add dword [_QueueTail], 4




    ;-----------
    .EnqueueTop:
    ;-----------
    sub di, 2
    mov ebx, dword [_QueueTail]
    dec word [ebp+.DestWidth]
    dec word [ebp+.DestHeight]
    invoke _PointInBox, si, di, word 0, word 0, word [ebp + .DestWidth], word [ebp + .DestHeight]
    inc word [ebp+.DestWidth]
    inc word [ebp+.DestHeight]
    test eax, eax
    jz near .NextPoint			; If invalid point, don't enqueue it

    ; Enqueue(Point.x,Point.y-1)	; Top Point
    mov word [ebx], si
    mov word [ebx + 2], di
    add dword [_QueueTail], 4


    ;----------
    .NextPoint:
    ;----------
       inc di
       jmp .PixelLoop


    ;----
    .End:
    ;----
       popad
       ret


endproc
_FloodFill_arglen	EQU	20






;-------------------------------------------------------------------------;
; InstallKeyboard()							  ;
;									  ;
;   dword _InstallKeyboard(void)					  ;
;									  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: _LockArea							  ;
;									  ;
;   Returns: 1 on error, 0 otherwise					  ;
;									  ;
;   Purpose: Installs the keyboard ISR					  ;
;									  ;
;-------------------------------------------------------------------------;
_InstallKeyboard



 ; int Install_Int(int num, unsigned int Handler_Address)
 movzx eax, byte [_kbINT]
 invoke _Install_Int, dword eax, dword _KeyboardISR
 test eax, eax					; Library function in pmodelib
 jnz .Error					; Returns -1 on error



 ; Lock variables the interrupt with access (_KeyboardISR function)
 ; bool LockArea(short Selector, unsigned int Offset, unsigned int Length)
 invoke _LockArea, cs, dword _KeyboardISR, dword _KeyboardISR_end-_KeyboardISR
 test eax, eax
 jnz .Error


 ; Lock variables the interrupt with access (_MPFlags)
 ; bool LockArea(short Selector, unsigned int Offset, unsigned int Length)
 invoke _LockArea, ds, dword _MPFlags, dword 1
 test eax, eax
 jnz .Error


 ; Lock variables the interrupt with access (_key)
 ; bool LockArea(short Selector, unsigned int Offset, unsigned int Length)
 invoke _LockArea, ds, dword _key, dword 1
 test eax, eax
 jnz .Error
 ret



 ;------
 .Error:
 ;------
    mov eax, 1
    ret







;-------------------------------------------------------------------------;
; RemoveKeyboard()							  ;
;									  ;
;   void _RemoveKeyboard(void)						  ;
;									  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: _Remove_Int							  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Uninstalls the keyboard ISR				  ;
;									  ;
;-------------------------------------------------------------------------;
_RemoveKeyboard

 push edx
 movzx edx, byte [_kbINT]
 invoke _Remove_Int, edx        ; Library function in pmodelib
 pop edx			; Keyboard uses Interrupt [_kbINT]
 ret






;-------------------------------------------------------------------------;
; KeyboardISR()								  ;
;									  ;
;   void _RemoveKeyboard(void)						  ;
;									  ;
;   Inputs: Keypress waiting at port [_kbPort], [_kbIRQ]		  ;
;									  ;
;   Outputs: [_key], [_MPFlags]						  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Handles keyboard input from the user			  ;
;									  ;
;-------------------------------------------------------------------------;
_KeyboardISR
;call	_libKeyboardISR	
;ret


 push ax
 push ebx
 push cx
 push dx



 mov dx, word [_kbPort]
 in al, dx					; al = scancode

 cmp al, ESC					; Check for ESC scancode
 jne near .NoQuit
 or byte [_MPFlags], 01h			; Set bit0 to exit program
 jmp near .Quit



 ;-------
 .NoQuit:
 ;-------
    and byte [_MPFlags], 11111110b		; Clear bit0 cause we ain't quittin
    cmp al, 80h					; Check for key press or release
    jnb near .KeyRelease


 ;-------
 ;LSHIFT:
 ;-------
    cmp al, LSHIFT
    jne .Rshift
    or byte [_MPFlags], 00010000b		; Left shift key status set
    jmp near .End


 ;-------
 .Rshift:
 ;-------
    cmp al, RSHIFT
    jne .OtherChar
    or byte [_MPFlags], 00001000b		; Right shift key status set
    jmp near .End


 ;----------
 .OtherChar:
 ;----------
    mov dl, byte [_MPFlags]
    and dl, 00011000b				; Clear all status bits but shift status bits
    test dl, dl					; If shift status set, then shift is pressed down
    jnz near .Uppercase


    movzx ebx, al				; Otherwise, just get normal lowercase character
    mov cl, byte [_QwertyNames + ebx]
    mov byte [_key], cl
    or byte [_MPFlags], 00100000b		; Set "Key other than shift was pressed" status bit
    jmp near .End


 ;----------
 .Uppercase:
 ;----------
    movzx ebx, al				; Since shift is pressed, get uppercase character
    mov cl, byte [_QwertyShift + ebx]
    mov byte [_key], cl
    or byte [_MPFlags], 00100000b		; Set "Key other than shift was pressed" status bit
    jmp near .End



 ;-----------
 .KeyRelease:
 ;-----------
    cmp al, 170
    jne .KeyRelease2
    and byte [_MPFlags], 11101111b		; Released LSHIFT
    jmp near .End



 ;------------
 .KeyRelease2:
 ;------------
    cmp al, 182
    jne near .End
    and byte [_MPFlags], 11110111b		; Released RSHIFT



 ;----
 .End:
 ;----
    mov al, 20h
    out 20h, al				; Send an end-of-interrupt signal
    cmp byte [_kbIRQ], 8
    jl near .Quit
    out 0A0h, al			; ACK with the slave PIC if IRQ > 7


 ;-----
 .Quit:
 ;-----
    pop dx
    pop cx
    pop ebx
    pop ax
    ret

_KeyboardISR_end







;-------------------------------------------------------------------------;
; InstallMouse()							  ;
;									  ;
;   dword _InstallMouse(void)						  ;
;									  ;
;   Inputs: none							  ;
;									  ;
;   Outputs: [_MouseSeg], [_MouseOff]					  ;
;									  ;
;   Calls: _LockArea, _Get_RMCB, DPMI_Int				  ;
;									  ;
;   Returns: 1 on error, 0 otherwise					  ;
;									  ;
;   Purpose: Installs the mouse callback				  ;
;									  ;
;-------------------------------------------------------------------------;
_InstallMouse
;call	_libInstallMouse
;ret
	



 push ebx
 push cx
 push dx

 ; Lock variables the callback will access (MouseCallback routine, MouseX, MouseY, MPFlags)
 invoke _LockArea, word cs, dword _MouseCallback, dword _MouseCallback_end-_MouseCallback
 test eax, eax
 jnz near .Error

 invoke _LockArea, word ds, dword _MouseX, dword 2
 test eax, eax
 jnz near .Error


 invoke _LockArea, word ds, dword _MouseY, dword 2
 test eax, eax
 jnz near .Error


 invoke _LockArea, word ds, dword _MPFlags, dword 1
 test eax, eax
 jnz near .Error
	



 invoke _Get_RMCB, dword _MouseSeg, dword _MouseOff, dword _MouseCallback, dword 1
 test eax, eax
 jnz near .Error



 mov word [DPMI_EAX], 0Ch
 mov word [DPMI_ECX], 07h


 mov ax, word [_MouseSeg]
 mov word [DPMI_ES], ax
 mov ax, word [_MouseOff]
 mov word [DPMI_EDX], ax

 mov bx, 33h
 call DPMI_Int			; DPMI_Int sets carryflag if error occured
 jc .Error


 pop dx
 pop cx
 pop ebx
 xor eax, eax
 ret


 ;------
 .Error:
 ;------
    pop dx
    pop cx
    pop ebx
    mov eax, 1
    ret






;-------------------------------------------------------------------------;
; RemoveMouse()								  ;
;									  ;
;   void _RemoveMouse(void)						  ;
;									  ;
;   Inputs: [_MouseSeg], [_MouseOff]					  ;
;									  ;
;   Outputs: none							  ;
;									  ;
;   Calls: _Free_RMCB, DPMI_Int						  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Removes the mouse callback					  ;
;									  ;
;-------------------------------------------------------------------------;
_RemoveMouse
        ;call	_libRemoveMouse
        ;ret



 push ax
 push bx
 push cx
 push dx

 mov dword [DPMI_EAX], 0Ch
 mov dword [DPMI_ECX], 0
 mov dword [DPMI_ES], 0
 mov dword [DPMI_EDX], 0

 mov bx, 33h
 call DPMI_Int

 invoke _Free_RMCB, word 0, word 0

 pop dx
 pop cx
 pop bx
 pop ax
 ret




;-------------------------------------------------------------------------;
; MouseCallback()							  ;
;									  ;
;   void _MouseCallback(dword DPMIRegsPtr)				  ;
;									  ;
;   Inputs: DPMIRegsPtr = pointer to DPMI register structure		  ;
;	    [_MouseX], [_MouseY], [_MPFlags]				  ;
;									  ;
;   Outputs: [_MouseX], [_MouseY], [_MPFlags]				  ;
;									  ;
;   Calls: none								  ;
;									  ;
;   Returns: none							  ;
;									  ;
;   Purpose: Handles mouse input from the user				  ;
;									  ;
;-------------------------------------------------------------------------;
proc _MouseCallback
.DPMIRegsPtr   arg     4
;invoke	_libMouseCallback, dword [ebp+.DPMIRegsPtr]
;ret

 pushad

 mov esi, dword [ebp + .DPMIRegsPtr]
 mov ebx, dword [es:esi+DPMI_EBX_off]
 mov ecx, dword [es:esi+DPMI_ECX_off]
 mov edx, dword [es:esi+DPMI_EDX_off]


 and bl, 00000001b
 cmp bl, 1
 je near .LeftPressed


 mov al, byte [_MPFlags]
 and al, 00000010b
 and byte [_MPFlags], 11111101b		; Clear Bit 2 in [_MPFlags]		
 jmp near .CheckStatusChange



 ;------------
 .LeftPressed:
 ;------------
    mov al, byte [_MPFlags]
    and al, 00000010b
    or byte [_MPFlags], 00000010b	; Set Bit 2 in [_MPFlags]


 ;------------------
 .CheckStatusChange:
 ;------------------
    shr al, 1
    cmp al, bl
    jne .StatusChange
    and byte [_MPFlags], 11111011b
    jmp near .UpdateXY


 ;-------------
 .StatusChange:
 ;-------------
    or byte [_MPFlags], 00000100b	; Change in LMB status


 ;---------
 .UpdateXY:
 ;---------
    mov word [_MouseX], cx		; Update values of [_MouseX] and [_MouseY]
    mov word [_MouseY], dx		; when mouse is moved

    popad
    ret


endproc
_MouseCallback_end
_MouseCallback_arglen	EQU	4
