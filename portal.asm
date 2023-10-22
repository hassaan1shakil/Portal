; Made By: 22L-6904 & 22L-6544

[org 0x0100]

jmp start

rows: dw 200
cols: dw 320
astSize: dw 10
starLocX: dw 10, 25, 50, 230, 83, 78, 124, 140, 150, 200, 5, 260, 300, 315, 230
starLocY: dw 10, 30, 20, 50, 5, 25, 28, 49, 12, 39, 52, 32, 30, 12, 22, 27
starSize: dw 4, 3, 2, 4, 1, 4, 3, 1, 2, 3, 1, 4 ,2, 2, 1


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
; Parameters: center y [bp + 18], center x [bp + 16]
; Clobbers:   AX, BX, CX, DX, ES, BP, DI
; Returns:    <none>
;--------------------------------------------------------------------
printAsteroid:
		push ax
		push es
		push bp
		push cx
		push dx
		push bx
		push di
		
	; bh: column counter
	; cx: column
	; dx: row
	; di: row counter
		mov bp, sp
		mov ax, 0A000h
		mov es, ax
		mov cx, [bp + 16]		; starting column
		mov dx, [bp + 18]		; starting row
		
		push 6					; darkes shade of flame
		push 43					; lighter shade of flame
		push 23					; darker shade of color
		push 7					; lighter shade of color
		mov bp, sp
		
; printing first and last 4 rows with increasing/decreasing columns and the centre 7 rows with same columns each
; to give us a square with round corners

		mov ah, 0x0C;
		mov al, byte [bp + 2]				; dark colo - 78 for light bluish, 152 for dark shade
		mov di, 4
		mov bl, 6
		add cl, bl
		inc cl

	initRows:					
			sub cl, bl						; resetting cl to inital pos after traversing
			dec cx
			add bl, 2						; adding 2 more col limit
			mov bh, bl
			push bx							; we will be using bl as counter for shading so we preserve bx as a whole
			sub bl, 4
		
	currInitCol:
			cmp bh, bl
			jne carryOn1					; if 'bl' pixels are printed then switch to lighter color
			mov al, byte [bp]			; lighter color
			
		carryOn1:
			int 10h
			inc cx
			dec bh
			jnz currInitCol
		
		pop bx								; getting our bx back
		
		flameInitRows:						;printinh flames where our column ends for asteroid
			shr bh, 1
			mov al, byte [bp + 4]
			
			flameInitCols:
				int 10h
				inc cx
				dec bh
				jnz flameInitCols
			
			push bx
			mov al, byte [bp + 6]
			mov bx, 0x0202
			flameDarkInitCols:
				int 10h
				inc cx
				dec bh
				jnz flameDarkInitCols
			sub cl, bl
			pop bx
			
			mov bh, bl
			shr bh, 1
			sub cl, bh
		
		mov al, byte [bp + 2]	
		inc dx
		dec di;
		jnz initRows

		mov di, 4
		push dx
		push bx
		push cx
			
			shr bh, 1
			add cl, bh
			; shr di, 1
			mov al, byte [bp + 6]
			mov bx, 0x0505
			add cl, bl
			
			flameDarkCenterRows:
				sub cl, bl
				add	bl, 3
				mov bh, bl
			flameDarkCenterCols:
				int 10h
				inc cx
				dec bh
				jnz flameDarkCenterCols
			
			inc dx
			dec di
			jnz flameDarkCenterRows
		
		mov di, 4
			flameDarkCenterRows2:
				sub cl, bl
				sub	bl, 3
				mov bh, bl
			flameDarkCenterCols2:
				int 10h
				inc cx
				dec bh
				jnz flameDarkCenterCols2
			
			inc dx
			dec di
			jnz flameDarkCenterRows2
		pop cx
		pop bx
		pop dx
		mov di, 7
	centerRows:
			sub cl, bl
			mov bh, bl
			push bx
			sub bl, 4

	currCenterCol:
			cmp bh, bl
			jne carryOn2
			mov al, byte [bp]	
			
		carryOn2:
			int 10h
			inc cx
			dec bh
			jnz currCenterCol
		
		pop bx
		
		flameCenterRows:						;printinh flames where our column ends for asteroid
			shr bh, 1
			mov al, byte [bp + 4]
			
			flameCenterCols:
				int 10h
				inc cx
				dec bh
				jnz flameCenterCols
			
			push bx
			
			; pop di
			; push di
			; shr di, 1
			; flameDarkCenterRows2:
				; sub cl, bl
				; sub	bl, 2
				; mov bh, bl
			; flameDarkCenterCols2:
				; int 10h
				; inc cx
				; dec bh
				; jnz flameDarkCenterCols2
			
			; inc dx
			; dec di
			; jnz flameDarkCenterRows2
			
			
			; pop di
			; pop dx
			pop bx
			; mov al, byte [bp + 6]
			; int 10h
			mov bh, bl
			shr bh, 1
			sub cl, bh
			
		mov al, byte [bp + 2]	
		inc dx
		dec di;
		jnz centerRows

		mov di, 4
	endRows:
			sub cl, bl
			inc cx
			sub bl, 2
			mov bh, bl
			push bx
			sub bl, 4
		
		
	currEndCol:
			cmp bh, bl
			jne carryOn3
			mov al, byte [bp]
			
		carryOn3:
			int 10h
			inc cx
			dec bh
			jnz currEndCol
		
		pop bx
		flameEndRows:						;printinh flames where our column ends for asteroid
			shr bh, 1
			mov al, byte [bp + 4]
			
			flameEndCols:
				int 10h
				inc cx
				dec bh
				jnz flameEndCols
		
		push bx
		mov al, byte [bp + 6]
		mov bx, 0x0202
			flameDarkEndCols:
				int 10h
				inc cx
				dec bh
				jnz flameDarkEndCols
			sub cl, bl
			pop bx
			
			mov bh, bl
			shr bh, 1
			sub cl, bh
			
			; mov al, byte [bp + 6]
			; int 10h
		
		mov al, byte [bp + 2]
		inc dx
		dec di;
		jnz endRows
			
	pop ax
	pop ax
	pop ax
	pop ax
	
	astEnd:
	pop di
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
		
	mov si, 0;
	printAllStars:
		push word [starSize + si]	; radius
		push word [starLocY + si]	; Rows/X Pos
		push word [starLocX + si]	; Cols/Y Pos
		call printStar
		
		add si, 2
		cmp si, 30
		jnz printAllStars;	
		

	printAllAsteroids:
		push 30
		push 40
		call printAsteroid	
		
		push 50
		push 200
		call printAsteroid
		
		push 10
		push 150
		call printAsteroid
		
		push 17
		push 263
		call printAsteroid
		
	ret
		
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

		cmp dx, 74
		je change_ceiling_color

        cmp dx, 135                     ; limited to 2nd section only             
        jnz clear_columns;
	
    pop dx
    pop cx
    pop ax
	
	ret

	change_ceiling_color:
		mov al, 27
		jmp clear_columns

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

	conveyor_strip:
		mov cx, word [bp + 14];		    ; starting col
		mov dx, [bp + 12];		        ; starting row
		add dx, 3
		
		mov ah, 0x0C;
		mov al, 24					    ; color
		mov bx, [cols]                	; height

		strip_columns:
			mov cx, 0		            ; width

			strip_rows:
				int 10h;
				add cx, 1;
				cmp cx, bx
				jnz strip_rows;
		
			add dx, 1;
			cmp dx, 122
			jnz strip_columns;

    xor bx, bx
		mov ah, 0x0C;
		mov al, 0x12				    ; color

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
        mov bh, 5                   ; no. of boxes

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

		cmp dx, 95
		jz set_color

        cmp dx, 115                 ; hardcoded for now??? formula can be implemented tho???
        jnz box_columns

box_stars:
	mov cx, 5

	mov dx, 0D03h  					; Row=12 (in DH), Column=20 (in DL)
	mov bh, 0      					; Page=0
	mov ah, 02h    					; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
	int 10h

	mov bx, 000Eh  					; Page=0 (in BH), Color=14 (in BL)             14 is Yellow
	mov ax, 0E2Ah  					; BIOS.Teletype (in AH), Character=33 (in AL)  33 is ASCII of "!"

	loop_decor:

		mov ah, 02h    				; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h

		mov ax, 0E2Ah  				; BIOS.Teletype (in AH), Character=33 (in AL)  33 is ASCII of "!"
		int 10h						; print interrupt

		sub cx, 1
		cmp cx, 2
		jle	change_ratio

		add dl, 8;
		jnz loop_decor

	change_ratio:
		add dx, 9
		cmp cx, 0
		jnz loop_decor
            	
    pop dx
    pop cx
    pop bx
    pop ax 
    pop bp 
	
	ret 12 

set_color:
	mov al, 0x29					; brown color
	jmp box_columns


PrintCeiling:
	push bp
	mov bp, sp

    push ax
    push bx
    push cx
    push dx

	mov ax, 0A000h;
    mov es, ax;
    mov cx, 36						; starting column
    mov dx, 66		        		; starting row
    
    mov ah, 0x0C;
    mov al, 237					    ; color
    mov bl, 38              		; width (picking in half register???)
    mov bh, 4                       ; no. of hooks
    
			
	ceiling_columns:
		mov cx, 36
        mov bh, 4                   ; no. of boxes

        ceiling_rows:
            int 10h;
            add cx, 1;
            dec bl
            jnz ceiling_rows;

        add cx, 30
        mov bl, 38           		; width
        dec bh
        jnz ceiling_rows

        add dx, 1
        cmp dx, 72                	; hardcoded for now??? formula can be implemented tho???
        jnz ceiling_columns


	ceiling_hooks:					; I presum that the hook end at Row 80 (for shifting purposes)???
		mov cx, 4

		mov dx, 0906h  				; Row=12 (in DH), Column=20 (in DL)
		mov bh, 0     				; Page=0
		mov ah, 02h    				; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h

		mov bx, 0006h  				; Page=0 (in BH), Color=14 (in BL)             14 is Yellow
		mov ax, 0E7Ch  				; BIOS.Teletype (in AH), Character=7C

		loop_hooks:

			mov ah, 02h    			; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
			int 10h

			mov ax, 0E7Ch  			; BIOS.Teletype (in AH), Character=7C
			int 10h					; print interrupt

			sub cx, 1
			cmp cx, 2
			je	change_gap

			add dl, 9;
			cmp cx, 0
			jnz loop_hooks

	pop dx
    pop cx
    pop bx
    pop ax 
    pop bp 

	;interrupt for key press ;; is this needed here???
	mov ah, 00h;
	int 16h;

	ret

	change_gap:
		add dx, 8
		cmp cx, 0
		jnz loop_hooks


PrintMiddle:

    call ClearScreen

    push 0x0019			            ; height.....[bp + 20]
	push 0x0017			            ; width......[bp + 18]
	push 0x0042			            ; color = light brown.....[bp + 16]
	push 13			                ; starting col.....[bp + 14]
	push 0x005A			            ; starting row.....[bp + 12]

    call PrintBox

    push 0x000A			            ; height.....[bp + 20]
	push 0x0140			            ; width......[bp + 18]
	push 0x0012			            ; color = space grey.....[bp + 16]
	push 0			                ; starting col.....[bp + 14]
	push 0x0073			            ; starting row.....[bp + 12]

    call PrintConveyorBelt

	call PrintCeiling

    ret

	
PrintMainScreen:        ; this will only call 3 funcs for now for printing sections

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