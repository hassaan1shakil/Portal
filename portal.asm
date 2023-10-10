; Made By: 22L-6904 & 22L-6544

[org 0x0100]

jmp start

rows: dw 200
cols: dw 320
astSize: dw 10


;--------------------------------------------------------------------
; Example on printing through interrupts
;--------------------------------------------------------------------
	; print pixel at row 160, col 100
	; mov ah, 0x0c;
	; mov cx, 160		;cx for columns = 160th column
	; mov dx, 100		; dx for rows = 100th row
	; mov al, 4 		;color for red;
	; int 10h 		;interrupt for print
	; ref: https://www.youtube.com/watch?v=lMk6SKWCiTw
	
;--------------------------------------------------------------------
; Prints a Star at any given locatoin
; Parameters: radius [bp + 18], center y [bp + 16], center x [bp + 14]
; Clobbers:   AX, BX, CX, DX, ES, BP
; Returns:    <none>
;--------------------------------------------------------------------
printStar:
		push ax
		push es
		push bp
		push cx
		push dx
		push bx
		
		mov ax, 0A000h
		mov es, ax
		mov bp, sp
		mov cx, [bp + 14]		        ; starting column
		mov dx, [bp + 16]		        ; starting row
		
		mov ah, 0x0C
		mov al, 15				        ; 15 = bright white
		mov bh, dl
		add bh, [bp + 18]				; [row + radius] -> ending rows
		
		mov bl, cl
		add bl, [bp + 18]			    ; [cols + radius] -> ending column
		
		sub dx, [bp + 18]				; [row - radius] -> starting row
		sub cx, [bp + 18]				; [col - radius] -> starting row
		
	backslash:
			int 10h					    ; interrupt for print
			inc cx
			inc dx
			cmp cl, bl				    ; check either row or col for ending point
			jne backslash
			
		int 10h
		mov cx, [bp + 14]		        ; starting color
		mov dx, [bp + 16]		        ; starting row
		
		mov bh, dl
		add bh, [bp + 18]				; [row + radius] -> ending rows
		sub dx, [bp + 18]				; [row - radius] -> starting row

	straightLine:
			int 10h
			inc dx
			cmp dl, bh
			jne straightLine
		
		int 10h
    mov cx, [bp + 14]		            ; starting color
		mov dx, [bp + 16]		        ; starting row
		
		mov bh, dl
		sub bh, [bp + 18]				; [row - radius] -> ending rows
		
		mov bl, cl
		add bl, [bp + 18]			    ; [cols + radius] -> ending column
		
		add dx, [bp + 18]				; [row + radius] -> starting row
		sub cx, [bp + 18]				; [col - radius] -> starting row
		
	forwardslash:
			int 10h
			dec dx
			inc cx
			cmp dl, bh
			jne forwardslash
			
		int 10h
		
	pop bx
	pop dx
	pop cx
	pop bp
	pop es
	pop ax
	
	ret	6
		
;--------------------------------------------------------------------
; Prints a Asteroid at any given locatoin
; Parameters: center y [bp + 16], center x [bp + 14]
; Clobbers:   AX, BX, CX, DX, ES, BP
; Returns:    <none>
;--------------------------------------------------------------------
printAsteroid:
		push ax
		push es
		push bp
		push cx
		push dx
		push bx
		
		mov ax, 0A000h
		mov es, ax
		mov bp, sp
		mov cx, [bp + 14]		    ; centre column
		mov dx, [bp + 16]		    ; centre row
		
		mov bh, byte [astSize]
		sub bh, 4				    ; size - 4
		; shl bh, 1				    ; size / 2
		; sub dl, bh				; row - (size / 2)
		mov bl, 2;
		
		mov ah, 0x0C
		mov al, 23				    ; 23 = dull grey
		
	leftIncVert:				    ; loop to draw top left vertex of ast
		int 10h
		inc dx
		dec cx
		dec bl
		jnz leftIncVert
		
	drawBinary:
			cmp bh, 0
			je leftDecVert
			push 0xCCCC
			push 2
			call randGen
			
		pop ax;
		cmp ax, 1;
		je leftIncreaseVert
		jne leftDecreaseVert
		
	leftDecreaseVert:
			mov bl, byte [astSize]
			sub bl, 4
			shr bl, 1
			sub bh, bl
			mov ah, 0x0C
			mov al, 23		
		
		aL2:
				int 10h
				inc cx
				inc dx
				dec bl
				jnz aL2
				jmp drawBinary
		
	leftIncreaseVert:
			mov bl, byte [astSize]
			sub bl, 4
			shr bl, 1
			sub bh, bl
			mov ah, 0x0C
			mov al, 23				; 23 = dull grey
		
		aL1:
				int 10h
				dec cx
				inc dx
				dec bl
				jnz aL1
				jmp drawBinary
		
		mov bl, 2
	leftDecVert:
			int 10h
			inc dx
			inc cx
			dec bl
			jnz leftDecVert
			
		mov bl, 2
	rightIncVert:
			int 10h
			dec dx
			inc cx
			dec bl
			jnz rightIncVert
			
	rightIncreaseVert:
			mov bl, byte [astSize]
			sub bl, 4
			shr bl, 1
			mov bl, bh
			mov ah, 0x0C
			mov al, 23				; 23 = dull grey
		
		aL3:
				int 10h
				inc cx
				dec dx
				dec bl
				jnz aL3
	
	rightDecreaseVert:
			mov bl, byte [astSize]
			sub bl, 4
			shr bl, 1
			mov ah, 0x0C
			mov al, 23		
		
		aL4:
				int 10h
				dec cx
				dec dx
				dec bl
				jnz aL4
				
		mov bl, 2
	rightDecVert:
			int 10h
			dec dx
			dec cx
			dec bl
			jnz rightDecVert
			
	astEnd:
	pop bx
	pop dx
	pop cx
	pop bp
	pop es
	pop ax
	
	ret	4
			
printBackground:
		push 4			            ; radius....[bp + 18]
		push 10			            ; starting row....[bp + 16]
		push 10			            ; starting col....[bp + 14]
		call printStar
		
		mov cx, 15;
		
	printAllStars:
			push 0xCCCC	
			push 5			        ; random radius form 0 to 4
			call randGen
			push 0xCCCC		
			push 60			        ; random starting row from 0 to 59
			call randGen
			push 0xCCCC
			push 310		        ; random starting col from 0 to 309
			call randGen
			call printStar

			dec cx;
			jnz printAllStars;
		
		; push 0xCCCC
		; push 5
		; call randGen
		; push 35;
		; push 70;
		; call printStar
		
		; push 0xCCCC
		; push 5
		; call randGen
		; push 10;
		; push 80;
		; call printStar
		
	ret
		
printRect:
	
		mov ax, 0A000h;
		mov es, ax;
		mov bp, sp;
		mov cx, [bp + 2];		    ; starting col
		mov dx, [bp + 4];		    ; starting row
		
		mov bh, [bp + 10]		    ; height

;--------------------------------------------------------------------
; Printing through interrupt method
;--------------------------------------------------------------------
		; mov ah, 0x0C;
		; mov al, [bp + 6]		    ; color
			
	; printh:
			; mov bl, [bp + 8]		; width
	; printrow:
			; int 10h;
			; add cx, 1;
			; dec bl;
			; jnz printrow;
		
		; mov cx, [bp + 2]
		; add dx, 1;
		; dec bh;
		; jnz printh;
	
;--------------------------------------------------------------------
; Printing through di method
;--------------------------------------------------------------------
	calculateloc:
			mov ax, 320;
			mul word dx
			add ax, cx
			shl ax, 1;
			mov di, ax;
			
			mov ah, 0x0C;
			mov al, [bp + 6]		    ; color
		
	printh:
			mov bl, [bp + 8]		    ; width
	printrow:
			mov [es:di], ax;
			add di, 1;
			dec bl;
			jnz printrow;
		
		add di, 320;
		sub di, [bp + 8]
		dec bh;
		jnz printh;
	
; interrupt for key press
	mov ah, 00h;
	int 16h;
	
	ret 10;
	
;--------------------------------------------------------------------
; subroutine to generate a random number
; generate a rand no using the system time
; Parameters: base variable [bp + 14], ending range [bp + 12]
; Clobbers:   AX, BX, CX, DX, BP
; Returns:    random number on stack
;--------------------------------------------------------------------
; ref: https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly
;--------------------------------------------------------------------
randGen:        
		push ax
		push bx
		push dx
		push cx
		push bp
		
		mov bp, sp
		
		mov bx, 10
	randomSeed:
		mov ah, 00h                     ; interrupts to get system time        
		int 1AH                         ; CX:DX now hold number of clock ticks since midnight   
		call delay
		dec bx
		jnz randomSeed

		mov  ax, dx
		xor  dx, dx
		mov  cx, [bp + 12]    
		div  cx                         ; here dx contains the remainder of the division - from 0 to given range
		
		cmp dx, 0
		je incrementDx
		jne store
		
	incrementDx:
		inc dx;
	store:
		mov [bp + 14], dx
		
		pop bp
		pop cx
		pop dx
		pop bx
		pop ax
		
	ret 2
	
delay:      push cx
			mov cx, 0xFFFF
loop1:		loop loop1
			mov cx, 0xFFFF
loop2:		loop loop2
			pop cx
			ret


ClearScreen:
    push ax
    push cx
    push dx
    
    mov ax, 0A000h;
    mov es, ax;
    mov cx, 0;		                    ; starting col
    mov dx, 0;		                    ; starting row
    
    mov ah, 0x0C;
    mov al, 24		                    ; color

    mov cx, 0
    mov dx, 66                          ; only printing 2nd section
			
	clear_columns:
		mov cx, 0		                ; width

        clear_rows:
            int 10h;
            add cx, 1;
            cmp cx, [cols]
            jnz clear_rows;
    
        add dx, 1;
        cmp dx, 135                     ; limited to 2nd section only             
        jnz clear_columns;
	
    pop dx
    pop cx
    pop ax
	
	ret

PrintConveyorBelt:
    push bp
    push ax
    push bx
    push cx
    push dx

    mov bp, sp

    mov ax, 0A000h;
    mov es, ax;
    mov cx, word [bp + 14];		        ; starting col
    mov dx, [bp + 12];		            ; starting row
    
    mov ah, 0x0C;
    mov al, byte [bp + 16]		        ; color
    mov bx, [bp + 20]                   ; height
			
	conveyor_columns:
		mov cx, 0		                ; width

        conveyor_rows:
            int 10h;
            add cx, 1;
            cmp cx, [cols]
            jnz conveyor_rows;
    
		add dx, 1;
		dec bx
        cmp bx, 0
		jnz conveyor_columns;

        xor bx, bx

    BeltSupports:                       ; dx is already on the next row here
        
        mov cx, 35
        mov bh, 0

        BeltSupports_rows:
            int 10h
            add cx, 1
            inc bl
            cmp bl, 10
            jnz BeltSupports_rows

        inc bh
        add cx, 70
        mov bl, 0
        cmp bh, 4
        jnz BeltSupports_rows

        add dx, 1
        cmp dx, 135
        jnz BeltSupports
            	
    pop dx
    pop cx
    pop bx
    pop ax 
    pop bp 
	
	ret 12      

PrintBox:
    push bp
    push ax
    push bx
    push cx
    push dx

    mov bp, sp

    mov ax, 0A000h;
    mov es, ax;
    mov cx, word [bp + 14];		    ; starting col
    mov dx, [bp + 12];		        ; starting row
    
    mov ah, 0x0C;
    mov al, byte [bp + 16]		    ; color
    mov bl, [bp + 18]               ; width (picking in half register???)
    mov bh, 5                       ; no. of boxes
    
			
	box_columns:
		mov cx, word [bp + 14]
        mov bh, 5                   ; heigth

        box_rows:
            int 10h;
            add cx, 1;
            dec bl
            jnz box_rows;

        add cx, 45
        mov bl, [bp + 18]           ; width
        dec bh
        jnz box_rows

        add dx, 1
        cmp dx, 115                 ; hardcoded for now??? formula can be implemented tho???
        jnz box_columns
            	
    pop dx
    pop cx
    pop bx
    pop ax 
    pop bp 

    ;interrupt for key press ;; is this needed here???
	mov ah, 00h;
	int 16h;
	
	ret 12 


PrintMiddle:

    call ClearScreen

    push 0x000A			            ; height.....[bp + 20]
	push 0x0140			            ; width......[bp + 18]
	push 0x0012			            ; color = space grey.....[bp + 16]
	push 0			                ; starting col.....[bp + 14]
	push 0x0073			            ; starting row.....[bp + 12]

    call PrintConveyorBelt


    push 0x0019			            ; height.....[bp + 20]
	push 0x0017			            ; width......[bp + 18]
	push 0x0043			            ; color = light brown.....[bp + 16]
	push 13			                ; starting col.....[bp + 14]
push 0x005A			                ; starting row.....[bp + 12]

    call PrintBox

    ret

	
PrintMainScreen:        ; this will only call 3 funcs for now for printing sections

    push 10
	push 10
	call printBackground

    call PrintMiddle

    ret

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;               Main Function               ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	

start:

; set the video mode to 13h
; resolution of 320x200 with 256 color options
; 1 Byte for 1 Pixel

	mov ah, 00h;
	mov al, 13h;
	int 10h;
	
	call PrintMainScreen
	
; setting the mode back to text
	mov ah, 00h;
	mov al, 03h;
	int 10h;

; interrupt for key press
    mov ah, 00h;
    int 16h;
	
; terminate
	mov ah, 4ch;
	int 21h;