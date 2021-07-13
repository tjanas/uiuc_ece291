BITS 16
CR EQU 13
LF EQU 10
EXTERN dosxit, kbdin, dspmsg, binasc


; Define stack segment
SEGMENT stkseg STACK 
	resb   512
stacktop:
	resb 0
; Define code segment 
SEGMENT code


; Variable declarations
pbuf    RESB 	7
crlf    db 	CR,LF,'$'
freq_msg  db 	' Freq = $'
count_msg db 	' Hz,  Count = $'

..start

		mov     ax, cs        ; Initialize DS register
		mov     ds, ax
		mov	ax, stkseg
		mov ss, ax
		mov sp, stacktop
MAIN:
		mov 	al,10110110b 	; Timer2, Load L+H, square wave, binary
		out 	43h,al       	; Write timer control byte        
		in 	al,61h        
		or 	al,00000011b  	; Enable Timer2 & Turn on speaker
		out 	61h,al
.mloop
		call 	kbdin
		cmp 	al,'0'   	; 0 to quit
		je 	.mdone
		sub 	al,'0'        
		mov 	ah,0

		mov 	cl,8     	; Freq * 256  (Hz)        
		shl 	ax,cl
        			
		mov 	dx, freq_msg        
		call 	dspmsg        
		mov 	bx, pbuf        
		call 	binasc        
		mov 	dx, pbuf        
		call 	dspmsg  	; Print Freq        
		mov 	bx,ax        
		mov 	ax,34DCh 	;DX:AX=1,193,180 (tics/sec)
		mov 	dx,12h   	;AX = ----------------------
		div 	bx       	;BX=Freq (1/sec)
		mov 	dx, count_msg        
		call 	dspmsg        
		mov 	bx, pbuf        
		call 	binasc        


		mov	dx, pbuf        
		call 	dspmsg  ; Print count        
		mov	dx, crlf        
		call	dspmsg 
       
		out	42h,al   ; Write Low byte to Timer Channel 2        
		mov	al,ah              
		out	42h,al   ; Write High byte to Timer Channel 2        
		jmp	.mloop

.mdone
	in	al,61h           
	and	al,11111100b 	; Turn off speaker        
	out	61h,al                
	call	dosxit      	; Exit to DOSmain