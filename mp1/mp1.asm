; MP1 - Terrence Janas - September 7, 2001
;
;
; Josh Potts, Fall 2001
; Guest Author: George Lu
; University of Illinois, Urbana-Champaign
; Dept. of Electrical and Computer Engineering
;
; Version 1.0

	BITS	16

;====== SECTION 1: Define constants =======================================

        CR          EQU 0Dh
        LF          EQU 0Ah
        BEL         EQU 07h
        MAX_ENTRIES EQU 10

;====== SECTION 2: Declare external procedures ============================

; These are functions from lib291
EXTERN  kbdine, dspout, dspmsg, dosxit,ascbin,binasc

; You will be writing your own versions of these functions
EXTERN _libDisplayEntry, _libDisplayAllEntries, _libDisplayAcademicEntries
EXTERN _libInterpretAmount, _libInterpretTag, _libAddDeposit
EXTERN _libAddWithdraw, _libDisplayTotal, mp1xit

; The _lib functions need these to work properly
GLOBAL MainHeader, MainMenu, AmountMenu, TagMenu, msg_Total, msg_NoEntries
GLOBAL msg_Invalid, msg_Deposit, msg_Withdraw, msg_Books, msg_Supply
GLOBAL msg_Academic, msg_Rent, msg_Food, msg_Entertain, msg_Other
GLOBAL msg_CRLF, msg_Cookie, msg_BigDebt, msg_SmallDebt, msg_SmallPlus
GLOBAL msg_BigPlus
GLOBAL _DisplayMainMenu, _DisplayAmountMenu, _DisplayTagMenu
GLOBAL EntryArray, NumEntries, Buffer
GLOBAL _DisplayEntry, _InterpretAmount, _InterpretTag

;====== SECTION 3: Define stack segment ===================================

SEGMENT stkseg STACK
        resb      64*8
stacktop:

;====== SECTION 4: Define code segment ====================================

SEGMENT code

;====== SECTION 5: Declare variables for main procedure ===================

EntryArray      resb (3*MAX_ENTRIES)
NumEntries      db 0
Buffer          resb 7

MainHeader      db CR, LF, CR, LF, 'Blah.  Witty Menu Title Here.'
                db CR, LF, '  Current Number of Entries: $'
MainMenu        db CR, LF, '------------------------------------'
                db CR, LF, ' a) Make a deposit'
                db CR, LF, ' b) Make a withdrawal'
                db CR, LF, ' c) Display all entries'
                db CR, LF, ' d) Display academic-related entries'
                db CR, LF, ' e) Exit'
                db CR, LF, CR, LF, 'Selection: $'

AmountMenu      db CR, LF
                db CR, LF, 'Select Amount of Transaction:'
                db CR, LF, '-----------------------------'
                db CR, LF, ' a) 1         b) 4'
                db CR, LF, ' c) 16        d) 64'
                db CR, LF, ' e) 256       f) 1024'
                db CR, LF, ' g) 4096'
                db CR, LF, CR, LF, 'Selection: $'

TagMenu         db CR, LF
                db CR, LF, 'Select Transaction Memo:'
                db CR, LF, '------------------------'
                db CR, LF, ' a) Books'
                db CR, LF, ' b) School Supplies'
                db CR, LF, ' c) Other Academic'
                db CR, LF, ' d) Rent'
                db CR, LF, ' e) Food'
                db CR, LF, ' f) Entertainment'
                db CR, LF, ' g) Other'
                db CR, LF, CR, LF, 'Selection: $'

msg_Total       db CR, LF, CR, LF, '     Account Balance: $'
msg_NoEntries   db CR, LF, 'There are no entries!$'
msg_Invalid     db CR, LF, '*** Invalid Selection!  Operation aborted! ***$'
msg_Deposit     db CR, LF, 'Deposit    $'
msg_Withdraw    db CR, LF, 'Withdraw   $'
msg_Books       db '   Books$'
msg_Supply      db '   School Supplies$'
msg_Academic    db '   Other Academic$'
msg_Rent        db '   Rent$'
msg_Food        db '   Food$'
msg_Entertain   db '   Entertainment$'
msg_Other       db '   Other$'
msg_CRLF        db CR, LF, '$'
msg_Cookie      db CR, LF, CR, LF
                db 'Leaving the bank, you stop by a Chinese restaurant', CR, LF
                db 'for food.  While waiting for your order, you are', CR, LF
                db 'presented with a fortune cookie.  You break it open', CR, LF
                db 'and the message inside reads...', CR, LF, CR, LF, '$'
msg_BigDebt     db 'A fortuitious fortune may fix your financial flaws.'
                db CR, LF, '  Lucky numbers: 1, 2, 8, 9, 23, 43, 45'
                db CR, LF, '$'
msg_SmallDebt   db 'You are in debt.  You are in ECE291.  Get used to both.'
                db CR, LF, '$'
msg_SmallPlus   db 'You have survived the horrors of IUB.  Enjoy your rest...'
                db CR, LF, '  Until next semester.', CR, LF, '$'
msg_BigPlus     db 'You have too much money for a college student.  The'
                db CR, LF, '  IRS and FBI have been contacted.', CR, LF, '$'

;====== SECTION 6: Program initialization =================================

..start:
        mov     ax, cs                  ; Initialize Default Segment register
        mov     ds, ax  
        mov     ax, stkseg              ; Initialize Stack Segment register
        mov     ss, ax
        mov     sp, stacktop            ; Initialize Stack Pointer register

;====== SECTION 7: Main procedure =========================================

MAIN:

.MainLoop
  cmp byte [NumEntries], MAX_ENTRIES
  jae .End

  call _DisplayMainMenu
  cmp al, 'a'
  je .AddDeposit
  cmp al, 'b'
  je .AddWithdraw
  cmp al, 'c'
  je .DisplayAll
  cmp al, 'd'
  je .DisplayAcad
  cmp al, 'e'
  je .End

  mov dx, msg_Invalid
  call dspmsg
  jmp .MainLoop

.AddDeposit
  call _AddDeposit
  jmp .MainLoop

.AddWithdraw
  call _AddWithdraw
  jmp .MainLoop

.DisplayAll
  call _DisplayAllEntries
  jmp .MainLoop

.DisplayAcad
  call _DisplayAcademicEntries
  jmp .MainLoop

.End
  call _DisplayAllEntries
  call _DisplayTotal
  call mp1xit


;--------------------------------------------------------------------------
; DisplayMainMenu
;   Inputs: none
;   Outputs: al = selection from keyboard
;   Calls: dspmsg, binasc, kbdine
;--------------------------------------------------------------------------
_DisplayMainMenu
  push bx               ; All used registers except ax are pushed because
  push cx               ;   only ax returns information.  (Notice: You can't
  push dx               ;   push or pop an 8-bit register.)

  mov dx, MainHeader
  call dspmsg           ; Display menu header
  xor ax, ax
  mov al, [NumEntries]
  mov bx, Buffer
  call binasc           ; Call binasc to convert a binary number into ASCII
  mov dx, bx
  call dspmsg           ; Display the converted number
  mov dx, MainMenu
  call dspmsg           ; Display the rest of the menu
  call kbdine           ; Wait for keyboard input

  pop dx                ; Pop all pushed registers -- notice the order
  pop cx
  pop bx
  ret

;--------------------------------------------------------------------------
; DisplayAmountMenu
;   Inputs: none
;   Outputs: al = selection from keyboard
;   Calls: dspmsg, kbdine
;--------------------------------------------------------------------------
_DisplayAmountMenu
  push dx
  mov dx, AmountMenu
  call dspmsg
  call kbdine
  pop dx
  ret

;--------------------------------------------------------------------------
; DisplayTagMenu
;   Inputs: none
;   Outputs: al = selection from keyboard
;   Calls: dspmsg, kbdine
;--------------------------------------------------------------------------
_DisplayTagMenu
  push dx
  mov dx, TagMenu
  call dspmsg
  call kbdine
  pop dx
  ret

;-------------------------------------------------------------------------
; DisplayEntry
;   Inputs: bx = offset to entry
;   Outputs: displays to screen
;   Calls: dspmsg, dspout, binasc
;-------------------------------------------------------------------------
_DisplayEntry

  push ax
  push cx
  push dx
  push bx

  mov cl, byte [bx]     ; gets the tag byte to check if
  and cl, 01h           ; it is a withdrawl
  cmp cl, 01h           ; if bit 0 = 1 it is a withdrawl
  je .TypeWithdraw

   mov dx, msg_Deposit
   call dspmsg
   jmp .DollarSignPrint

  .TypeWithdraw:
   mov dx, msg_Withdraw
   call dspmsg

  .DollarSignPrint:
   mov dl, '$'
   call dspout


   inc bx                ; bx points to the beginning of transaction amount
   mov ax, [bx]
                         ; binasc requires that ax = 16-bit signed integer to be converted
   mov bx, Buffer        ; binasc requires that bx is starting offset address for 7-byte buffer
                         ;  to hold the byte string generated
   call binasc
   mov dx, Buffer
   call dspmsg
   pop bx
  
   mov al, byte [bx]      ; gets the tag byte to see type of transaction
   and al, 11111110b      ; i.e. Rent, Food

  cmp al, 2              ; a switch case to display proper transaction message
  jne .NotBooks
  mov dx, msg_Books
  jmp .Display

  .NotBooks:
  cmp al, 4            ; check to see if Supply tag
  jne .NotSupply
  mov dx, msg_Supply
  jmp .Display

  .NotSupply:
  cmp al, 8            ; check to see if Academic tag
  jne .NotAcademic
  mov dx, msg_Academic
  jmp .Display

  .NotAcademic:
  cmp al, 16           ; check to see if Rent tag
  jne .NotRent
  mov dx, msg_Rent
  jmp .Display

  .NotRent:
  cmp al, 32           ; check to see if Food tag
  jne .NotFood
  mov dx, msg_Food
  jmp .Display

  .NotFood:
  cmp al, 64           ; check to see if Entertainment tag
  jne .NotEntertain
  mov dx, msg_Entertain
  jmp .Display

  .NotEntertain:
  mov dx, msg_Other  

 .Display:
  call dspmsg
  pop dx
  pop cx
  pop ax
  ret

;-------------------------------------------------------------------------
; DisplayAllEntries
;   Inputs: [NumEntries], [EntryArray]
;   Outputs: displays to screen
;   Calls: DisplayEntry, dspmsg
;-------------------------------------------------------------------------
_DisplayAllEntries
  
  push ax              ; Save data in registers
  push bx              ; on the stack
  push cx
  push dx

  mov cl, 0                    ; Start the counter at 0
  mov bx, EntryArray           ; bx points to beginning of EntryArray
  cmp byte [NumEntries], 0     ; Check to see if there is at least 1 entry
  jne .AtLeastOneEntry         ;
  mov dx, msg_NoEntries        ; If not, display NoEntries message
  call dspmsg
  jmp .End

 .AtLeastOneEntry:
  call _DisplayEntry           ; Display entry currently pointed to by bx
  inc cl                       ; Increment the counter

  cmp cl, [NumEntries]         ; If the counter = NumEntries, 
  je .End                      ; goto end of procedure
  add bx, 3                    ; Next entry is 3 bytes higher in array
  jmp .AtLeastOneEntry         ; repeat until completed all entries


 .End:
  pop dx                       ; Restore original register data
  pop cx                       ; before leaving the routine
  pop bx
  pop ax
  ret


;-------------------------------------------------------------------------
; DisplayAcademicEntries
;   Inputs: [NumEntries], [EntryArray]
;   Outputs: displays to screen
;   Calls: DisplayEntry, dspmsg
;-------------------------------------------------------------------------
_DisplayAcademicEntries

  push ax              ; Save data in registers
  push bx              ; on the stack
  push cx
  push dx

  mov cx, 0
  mov al, 0
  mov bx, EntryArray
  cmp byte [NumEntries], 0   ; check if there are any entries
  jne .AtLeastOneEntry
    jmp .NoEntries

 .AtLeastOneEntry:
  mov cl, byte [bx]          ; move tag byte of current entry to cl
  mov dl, 11111110b
  and cl, dl
  cmp cl, 8                  ; if tag is 2, 4, or 8 it is for academics
  ja .NotAcademic            ; else must not be academic, 
    call _DisplayEntry
    inc al                   ; Increment the academic entry counter


 .NotAcademic:
  inc ch                     ; Increment the counter
  cmp ch, [NumEntries]       ; If the counter = NumEntries,
  je .EndLoop                ; we have printed all the entries
  add bx, 3                  ; else, next entry is 3 bytes higher in the array
  
  jmp .AtLeastOneEntry       ; repeat until completed all entries


 .EndLoop:
  cmp al, 0                  ; check if there are any academic entries
  je .NoEntries              ; if not, display NoEntries message

 .End:
  pop dx                       ; Restore original register data
  pop cx                       ; before leaving the routine
  pop bx
  pop ax
  ret

 .NoEntries:
  mov dx, msg_NoEntries     ; prints NoEntries message to screen
  call dspmsg
  jmp .End
  

;-------------------------------------------------------------------------
; InterpretAmount
;   Inputs: al = ASCII code of key pressed from AmountMenu
;   Outputs: dx = binary representation of corresponding amount,
;                 or -1 on error
;   Calls: dspmsg
;-------------------------------------------------------------------------
_InterpretAmount
  cmp al, 'a'          ; Check input from keyboard to see if valid choice
  je .Amount_is_a      ; goes to correct case
  cmp al, 'b'
  je .Amount_is_b
  cmp al, 'c'
  je .Amount_is_c
  cmp al, 'd'
  je .Amount_is_d
  cmp al, 'e'
  je .Amount_is_e
  cmp al, 'f'
  je .Amount_is_f
  cmp al, 'g'
  je .Amount_is_g

  mov dx, msg_Invalid  ; Invalid choice, print error message
  call dspmsg
  mov dx, -1 
  ret

  .Amount_is_a:
    mov dx, 0001h      ;Choice is $1
    ret
  .Amount_is_b:
    mov dx, 0004h      ;Choice is $4
    ret
  .Amount_is_c:
    mov dx, 0010h      ;Choice is $16
    ret
  .Amount_is_d:
    mov dx, 0040h      ;Choice is $64
    ret
  .Amount_is_e:
    mov dx, 0100h      ;Choice is $256
    ret
  .Amount_is_f:
    mov dx, 0400h      ;Choice is $1024
    ret
  .Amount_is_g:
    mov dx, 1000h      ;Choice is $4096
    ret

;-------------------------------------------------------------------------
; InterpretTag
;   Inputs: al = ASCII code of key pressed from TagMenu
;   Outputs: cl = tag with only one 1 corresponding to entered type,
;                 or all 1s on error
;   Calls: dspmsg
;-------------------------------------------------------------------------
_InterpretTag
  push dx
  xor cl, cl           ; Clear the tag byte

  cmp al, 'a'          ; Check input from keyboard to see if valid choice
  je .Choice_is_a      ; goes to correct case
  cmp al, 'b'
  je .Choice_is_b
  cmp al, 'c'
  je .Choice_is_c
  cmp al, 'd'
  je .Choice_is_d
  cmp al, 'e'
  je .Choice_is_e
  cmp al, 'f'
  je .Choice_is_f
  cmp al, 'g'
  je .Choice_is_g

  mov dx, msg_Invalid  ; Invalid choice,
  call dspmsg          ;  prints error message
  mov cl, -1           ; cl = 11111111b indicates an error
  jmp .End

  .Choice_is_a:        ; Bit 1 is the books tag
    xor cl, 00000010b
    jmp .End
  .Choice_is_b:        ; Bit 2 is the school supplies tag
    xor cl, 00000100b
    jmp .End
  .Choice_is_c:        ; Bit 3 is the other academic tag
    xor cl, 00001000b
    jmp .End
  .Choice_is_d:        ; Bit 4 is the rent tag
    xor cl, 00010000b
    jmp .End
  .Choice_is_e:        ; Bit 5 is the food tag
    xor cl, 00100000b
    jmp .End
  .Choice_is_f:        ; Bit 6 is the entertainment tag
    xor cl, 01000000b
    jmp .End
  .Choice_is_g:        ; Bit 7 is the other tag
    xor cl, 10000000b
    jmp .End

  .End
    pop dx
    ret

;-------------------------------------------------------------------------
; AddDeposit
;   Inputs: [NumEntries]
;   Outputs: [NumEntries], [EntryArray]
;   Calls: DisplayAmountMenu, InterpretAmount, DisplayTagMenu,
;           InterpretTag
;-------------------------------------------------------------------------
_AddDeposit
  call _DisplayAmountMenu
  call _InterpretAmount
  cmp dx, -1               ; Check if there was an error with amount
  je .End              ; If so, return w/o incrementing [NumEntries]

  call _DisplayTagMenu
  call _InterpretTag
  cmp cl, -1               ; Check if there was an error with tag
  je .End              ; If so, return w/o incrementing [NumEntries]

  and cl, 11111110b        ; set bit 0 = 0 for deposit

  push bx
  push ax
  mov bx, EntryArray
  mov al, 3
  mul byte [NumEntries]    ; next entry is found after 3 bytes in the array
  add bx, ax               ; move the pointer to the next cell in the array
  mov [bx], cl             ; store tag info in first byte of array cell
  add bx, 1                ; go to the next byte
  mov [bx], dx             ; and store the amount
  

  inc byte [NumEntries]    ; Increment the number of entries
  pop ax
  pop bx

  .End:
  ret

;-------------------------------------------------------------------------
; AddWithdraw
;   Inputs: [NumEntries]
;   Outputs: [NumEntries], [EntryArray]
;   Calls: DisplayAmountMenu, InterpretAmount, DisplayTagMenu,
;           InterpretTag
;-------------------------------------------------------------------------
_AddWithdraw

  call _DisplayAmountMenu
  call _InterpretAmount
  cmp dx, -1               ; Check if there was an error
  je .End                  ; If so, return without inc [NumEntries]

  call _DisplayTagMenu
  call _InterpretTag
  cmp cl, -1               ; Check if there was an error
  je .End                  ; If so, return without inc [NumEntries]

  or cl, 00000001b         ; set bit 0 = 1 for withdrawl

  push bx
  push ax
  mov bx, EntryArray       ; bx is pointing to the EntryArray
  mov al, 3
  mul byte [NumEntries]    ; ax = 3*NumEntries
  add bx, ax               ; move the pointer to the next cell in the array
  mov [bx], cl             ; store tag info in first byte of array cell
  add bx, 1                ; go to the next byte
  mov [bx], dx             ; and store the amount
  

  inc byte [NumEntries]    ; Add 1 to the number of entries
  pop ax
  pop bx

  .End:
  ret


;-------------------------------------------------------------------------
; DisplayTotal
;   Inputs: [NumEntries], [EntryArray]
;   Outputs: displays to screen
;   Calls: dspmsg, dspout, binasc
;-------------------------------------------------------------------------
_DisplayTotal
                ;call _libDisplayTotal
                ;ret

  push ax       ; save data in registers
  push bx
  push cx
  push dx

  mov dx, msg_Total   ; print out msg_Total
  call dspmsg         ; as well as the dollar sign
  mov dl, '$'
  call dspout

  mov dx, 0           ; clear registers
  mov ax, 0
  mov cx, 0
  mov bx, 0
  mov bx, EntryArray         ; bx points to the EntryArray
  cmp byte [NumEntries], 0   ; check if there are any entries
  je .PrintTotal


 .AmountLoop:
  mov cl, byte [bx]          ; store tag in cl
  inc bx                     ; point to amount in current array cell
  and cl, 00000001b          ; only keep the deposit/withdrawl bit
  cmp cl, 1                  ; check if it is withdrawl
  je .NegativeAmount

  add ax, [bx]               ; assume its a deposit, so add instead of subtract
  jmp .EndOfLoop             ; from the running total


 .NegativeAmount:            ; subtract amount from the total since it
  sub ax, [bx]               ; is a withdrawl


 .EndOfLoop:
  inc ch                     ; Increment counter
  cmp ch, [NumEntries]       ; check if all entries have been added
  je .PrintTotal
  add bx, 2                  ; if not, point ot next array cell to be added
  jmp .AmountLoop

 .PrintTotal:
  mov bx, Buffer             ; convert ax to ASCII to display
  call binasc                ; readable number
  mov dx, Buffer             ; print the total to the screen
  call dspmsg

  mov dx, msg_Cookie         ; display the fortune cookie message
  call dspmsg

  cmp ax, -1000              ; check if total is less than -1000
  jl .BigDebt
  
  cmp ax, 0                  ; check if total between -1000 and 0
  jl .SmallDebt

  cmp ax, 1000
  jl .SmallPlus              ; check if total between 0 and 1000

  cmp ax, 999                ; check if total greater/equal 1000
  jg .BigPlus


 .BigDebt:
  mov dx, msg_BigDebt        ; print BigDebt message to screen
  jmp .End
 .SmallDebt:
  mov dx, msg_SmallDebt      ; print SmallDebt message to screen
  jmp .End
 .SmallPlus:
  mov dx, msg_SmallPlus      ; print SmallPlus message to screen
  jmp .End
 .BigPlus                    ; print BigPlus message to screen
  mov dx, msg_BigPlus


 .End:
  call dspmsg                ; restore original register data
  pop dx
  pop cx
  pop bx
  pop ax
  ret