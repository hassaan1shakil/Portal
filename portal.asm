; Made By: 22L-6904 & 22L-6544

[org 0x0100]

jmp start

isGameRunning: dw 0

tickCountInc: dw 0
tickcount: dw 0

rows: dw 200
cols: dw 320
astSize: dw 10
starLocX: dw 10, 25, 50, 230, 83, 78, 124, 140, 150, 200, 5, 260, 300, 315, 230
starLocY: dw 10, 30, 20, 50, 5, 25, 28, 49, 12, 39, 52, 32, 30, 12, 22, 27
starSize: dw 4, 3, 2, 4, 1, 4, 3, 1, 2, 3, 1, 4 ,2, 2, 1

isStartScrn: dw 1
startScrnMsg: db "Press Space to Start$"

isNameScrn: dw 0
enterNameMsg:	db 'Enter Your Name:$'

isInstScrn: dw 0

isEscape: dw 0
isYes:  dw 0
isNo: dw 0
escapeMsg: db "Would You Like to Exit the Game$"
yesMsg: db "Yes (Y)$"
noMsg: db "No (N)$"
isPausePrint: dw 0

instMsg1: db ", Welcome to Portal$"
instMsg2: db "ABOUT GAME$"
instMsg3: db "1. There are 2 Levels$"
instMsg4: db "a. 1st Level Time Limit: 30 Seconds$"
instMsg5: db "b. 2nd Level Time Limit: 30 Seconds$"
instMsg6: db "2. Kill the Zombies to Gain XP$"
instMsg7: db "GAME MECHANICS$"
instMsg8: db "Q: shoot left$"
instMsg9: db "E: shoot right$"
instMsg10: db "Space: Move Left$"
instMsg11: db "RShift: Move Right$"
instMsg12: db "Press Any Key to Start$"

;following is input buffer in format required by service
nameBuffer:		db 80 								; Byte # 0: Max length of buffer
db 0 											; Byte # 1: number of characters on return
times 80 db 0 									; 80 Bytes for actual buffer space


buffer: times 7680 db 0

char_x: dw 80
char_y: dw 165

char_file: incbin "zombie.bin"

bullet_x: dw 0
bullet_y: dw 0
bullet_impact: dw 0
bullet_erased: dw 0

zombies_x: dw 0, 0, 0, 0, 0, 0
zombies_y: dw 0, 0, 0, 0, 0, 0
current_zombie: dw 0

score: dw 0
message_score: db  "XP:"
message_time: db "Time:"

level_flag: dw 0
level2_flag: dw 0

oldisr: dd 0
leftkeypressed: dw 0
rightkeypressed: dw 0
leftbulletpressed: dw 0
rightbulletpressed: dw 0

GameOver: db "GAME OVER"
message_win: db "YOU WON!"
message_level: db "Level:"
level_num: dw 1

%include "bin.asm"



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
	
	
clrScrn: 
			push es
			push ax
			push cx
			push di
			
			mov ax, 0A000h
			mov es, ax ; point es to video base
			xor di, di ; point di to top left column
			mov ax, 0x00; space char in normal attribute
			mov cx, 64000 ; number of screen locations
			cld ; auto increment mode
			rep stosb ; clear the whole screen
			pop di

			pop cx
			pop ax
			pop es
			ret
			
printstr:
		push bp
		mov bp, sp
		push ax
		push bx
		push cx
		
		mov dx, word [bp + 4]  ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, byte [bp + 6]
		
		mov dx, [bp + 8]	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		pop cx
		pop bx
		pop ax
		pop bp
		ret 6
printRect:
		mov bp, sp
		mov ax, 0A000h;
		mov es, ax;
		mov bp, sp;
		mov cx, [bp + 2];		; starting col
		mov dx, [bp + 4];		; starting row
		
		mov bh, [bp + 10]		; height
		
;--------------------------------------------------------------------
; Printing through interrupt method
;--------------------------------------------------------------------
		mov ah, 0x0C;
		mov al, [bp + 6]		; color
			
	printh:
			mov bl, [bp + 8]		; width
	printrow:
			int 10h;
			add cx, 1;
			dec bl;
			jnz printrow;
		
		mov cx, [bp + 2]
		add dx, 1;
		dec bh;
		jnz printh;
		ret 10;
		
StoreBuffer:	
				push bp
				mov bp, sp
				push es
				push ds
				push ax
				push cx
				push di
				push si

				mov ax, [cols]
				mul word [bp + 4] 		; starting row
				add ax, [bp + 6] 		; starting column
				mov si, ax
				
				push es
				pop ds
				mov di, 0
				
				mov dx, 32
		bufferLoopOuter:
				mov cx, 240
				
		bufferLoop:
				lodsb
				mov byte [buffer + di], al
				inc di
				dec CX
				jnz bufferLoop
				
				sub si, [240]
				add si, [cols]
				
				dec dx
				jnz bufferLoopOuter


				pop si
				pop di
				pop cx
				pop ax
				pop ds
				pop es
				pop bp
				ret 4

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
RestoreBuffer:	
				push bp
				mov bp, sp
				push es
				push ds
				push ax
				push cx
				push di
				push si

				mov si , buffer
				push cs
				pop ds
				mov ax , 0A000h
				mov es , ax
				
				mov ax, [cols]
				mul word [bp + 4] 		; starting row
				add ax, [bp + 6] 		; starting column
				mov di, ax
				
				mov dx, 32
				
		restoreBufferOuterLoop:
				cld
				mov cx , 240
			restoreBufferLoop:
				rep movsb
				
				sub di, [240]
				add di, [cols]
				dec dx
				jnz restoreBufferOuterLoop
			
				pop si
				pop di
				pop cx
				pop ax
				pop ds
				pop es
				pop bp
				ret 4
	
printPauseScrnBorder:
		; push bp
		; mov bp, sp
		; push ax
		; push bx
		; push cx
		; push dx
		; push es
		
		push 32			; height.....[bp + 10]
		push 240			; width......[bp + 8]
		push 14			; color = yellow.....[bp + 6]
		push 88			; starting col.....[bp + 4]
		push 80			; starting row.....[bp + 2]
		call printRect;
		
		
		; pop es
		; pop dx
		; pop cx
		; pop bx
		; pop ax
		; pop bp
		ret
		
printPauseScrn:
			push ax
			push bx
			push cx
			push dx
			push bp
			push es

			; push 80
			; push 88
			;call StoreBuffer
			;call printPauseScrnBorder
			push 32			; height.....[bp + 10]
			push 255			; width......[bp + 8]
			push 14			; color = yellow.....[bp + 6]
			push 87			; starting row.....[bp + 4]
			push 37			; starting column.....[bp + 2]
			call printRect;
		
			
			mov ax, escapeMsg
			push ax					; String addres
			push 15					; 15 = bright white color
			push 5865h				; POS
			call printstr
			
			mov ax, yesMsg
			push ax					; String addres
			push 15					; 15 = bright white color
			push 5A68h				; POS
			call printstr
			
			mov ax, noMsg
			push ax					; String addres
			push 15					; 15 = bright white color
			push 5A02h				; POS
			call printstr
				
			pop es
			pop bp
			pop dx
			pop cx
			pop bx
			pop ax
			
;pauseLoop:	jmp pauseLoop
			ret
			
;--------------------------------------------------------------------
; Prints an octagon shaped head at any given locatoin
; Parameters: starting y [bp + 6], starting x [bp + 4]
; Clobbers:   AX, BX, CX, DX, ES, BP, DI
; Returns:    <CX> (ending column), <DX> (ending row)
;--------------------------------------------------------------------
printPortal:
		push bp
		mov bp, sp
		push ax
		push es
		push cx
		push dx
		push bx
		push di
		
		mov ax, 0A000h
		mov es, ax
		mov cx, [bp + 4]		; starting column
		mov dx, [bp + 6]		; starting row
		
; printing each row independently starting for from 6 columns and increasing it by 2 every time

		mov ah, 0x0C;
		mov al, byte [bp + 8]				; color
		mov di, [bp + 10]				; width
		mov bl, 10
		add cl, bl
		inc cx
		
	pInitRows:
			sub cl, bl
			dec cx
			add bl, 2
			mov bh, bl
		
		
	pCurrInitCol:
			int 10h
			inc cx
			dec bh
			jnz pCurrInitCol
		
		inc dx
		dec di;
		jnz pInitRows

		mov di, 50
		
	pCenterRows:
			sub cl, bl
			mov bh, bl

	pCurrCenterCol:
			int 10h
			inc cx
			dec bh
			jnz pCurrCenterCol
		
		inc dx
		dec di;
		jnz pCenterRows

		mov di, [bp + 10]
	pEndRows:
			sub cl, bl
			inc cx
			sub bl, 2
			mov bh, bl
		
		
	pCurrEndCol:
			int 10h
			inc cx
			dec bh
			jnz pCurrEndCol
		
		inc dx
		dec di;
		jnz pEndRows
	
	pop di
	pop bx
	pop dx
	pop cx
	pop es
	pop ax
	pop bp
	
	ret	8
		
;--------------------------------------------------------------------
; Prints a Tilted Rectange at any given locatoin - The Coordinates are used as the first axes 
; Parameters: height [bp + 10], width [bp + 8], color [bp + 6], starting Y [bp + 4], starting X [bp + 2]
; Clobbers:   AX, BX, CX, DX, ES, BP,
; Returns:    <none>
; NOTE: Try not to use odd Width and Heights as they cause printing errors
;--------------------------------------------------------------------
printTiltRect:
		push bp
		mov bp, sp;
		push es
		push ax
		push bx
		push cx
		push dx
		mov ax, 0A000h;
		mov es, ax;
		mov cx, [bp + 4];		; starting col
		mov dx, [bp + 6];		; starting row
		
		mov bh, [bp + 12]		; height

;--------------------------------------------------------------------
; Printing through interrupt method
;--------------------------------------------------------------------
		mov ah, 0x0C;
		mov al, [bp + 8]		; color
		mov bh, [bp + 10]		; width
		mov bl, -1
		add cl, bl
		inc cx
			
	printTiltInitH: 			; printing the initial rows to the size of width in a tilted fashion
		sub cl, bl
		dec cx					; pushing the column one step back since the previous column satrting point
		dec bh					
		add bl, 2
		push bx					; preserving the bx register (Short on registers 😢)
		
	printTiltInitRow:
			int 10h;
			add cx, 1;
			dec bl
			jnz printTiltInitRow;
		
		add dx, 1;
		pop bx
		dec bh;
		jnz printTiltInitH;
		
		
	printTiltCenter:
		mov bh, [bp + 12]
		sub bh, [bp + 10]		; bh = [height - width]
		
		printTiltCenterH:
				sub cl, bl
				add cx, 1
				dec bh
				push bx
			printTiltCenterRow:
					int 10h;
					inc cx
					dec bl
					jnz printTiltCenterRow
					
			inc dx
			pop bx
			dec bh
			jnz printTiltCenterH
	
	
	mov bh, [bp + 10]		; width
	add bl, 2
	add cx, 2
	printTiltEndH: 			; printing the ending rows to the size of width in a tilted fashion
		sub cl, bl
		inc cx					; pushing the column one step back since the previous column satrting point
		dec bh					
		sub bl, 2
		push bx					; preserving the bx register (Short on registers 😢)
		
	printTiltEndRow:
			int 10h
			add cx, 1;
			dec bl
			jnz printTiltEndRow;
		
		add dx, 1;
		pop bx
		dec bh;
		jnz printTiltEndH;
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret	10
	
;--------------------------------------------------------------------
; Prints a Reverse Tilted Rectange at any given locatoin - The Coordinates are used as the first axes 
; Parameters: height [bp + 10], width [bp + 8], color [bp + 6], starting Y [bp + 4], starting X [bp + 2]
; Clobbers:   AX, BX, CX, DX, ES, BP,
; Returns:    <none>
;--------------------------------------------------------------------
printReverseTiltRect:
		push bp;
		mov bp, sp;
		push es
		push ax
		push bx
		push cx
		push dx
		mov ax, 0A000h;
		mov es, ax;
		mov cx, [bp + 4];		; starting col
		mov dx, [bp + 6];		; starting row
		
		mov bh, [bp + 12]		; height

;--------------------------------------------------------------------
; Printing through interrupt method
;--------------------------------------------------------------------
		mov ah, 0x0C;
		mov al, [bp + 8]		; color
		mov bh, [bp + 10]		; width
		mov bl, -1
		add cl, bl
		inc cx
			
	printReverseTiltInitH: 			; printing the initial rows to the size of width in a tilted fashion
		sub cl, bl
		dec cx					; pushing the column one step back since the previous column satrting point
		dec bh					
		add bl, 2
		push bx					; preserving the bx register (Short on registers 😢)
		
	printReverseTiltInitRow:
			int 10h;
			add cx, 1;
			dec bl
			jnz printReverseTiltInitRow;
		
		add dx, 1;
		pop bx
		dec bh;
		jnz printReverseTiltInitH;
		
		
	printReverseTiltCenter:
		mov bh, [bp + 12]
		sub bh, [bp + 10]		; bh = [height - width]
		
		printReverseTiltCenterH:
				sub cl, bl
				sub cx, 1
				dec bh
				push bx
			printReverseTiltCenterRow:
					int 10h;
					inc cx
					dec bl
					jnz printReverseTiltCenterRow
					
			inc dx
			pop bx
			dec bh
			jnz printReverseTiltCenterH
	
	
	mov bh, [bp + 10]		; width
	add bl, 2
	
	printReverseTiltEndH: 			; printing the ending rows to the size of width in a tilted fashion
		sub cl, bl
		inc cx					; pushing the column one step back since the previous column satrting point
		dec bh					
		sub bl, 2
		push bx					; preserving the bx register (Short on registers 😢)
		
	printReverseTiltEndRow:
			int 10h
			add cx, 1;
			dec bl
			jnz printReverseTiltEndRow;
		
		add dx, 1;
		pop bx
		dec bh;
		jnz printReverseTiltEndH;
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret 10
	
	
printMainBord:

		push ax
		push bx
		push cx
		push dx
		push es
		
		mov ax, 0A000h;
		mov es, ax;
		
		
		mov dx, 10
		mov bx, [rows]
		sub bx, dx
		mov ah, 0x0c
		mov al, 53
		
	leftBlueBordRow:
			mov cx, 4
			
		leftBlueBordCol:
			int 10h
			dec cx
			jnz leftBlueBordCol
			
		inc dx
		cmp dx, bx
		jne leftBlueBordRow
		
		mov dx, 10
		mov al, 40
		rightRedBordRow:
			mov cx, [cols]
			sub cx, 4
		rightRedBordCol:
			int 10h
			inc cx
			cmp cx, [cols]
			jne rightRedBordCol
			
		inc dx
		cmp dx, bx
		jne rightRedBordRow
		
		
	; ; interrupt for key press
		; mov ah, 00h;
		; int 16h;
		
		pop es
		pop dx
		pop cx
		pop bx
		pop ax
		ret
		
;--------------------------------------------------------------------
; Prints an octagon shaped head at any given locatoin
; Parameters: center y [bp + 6], center x [bp + 4]
; Clobbers:   AX, BX, CX, DX, ES, BP, DI
; Returns:    <CX> (ending column), <DX> (ending row)
;--------------------------------------------------------------------
printHead:
		push bp
		mov bp, sp
		push ax
		push es
		push cx
		push dx
		push bx
		push di
		
		mov ax, 0A000h
		mov es, ax
		mov cx, [bp + 4]		; starting column
		mov dx, [bp + 6]		; starting row
		
; printing each row independently starting for from 6 columns and increasing it by 2 every time

		mov ah, 0x0C;
		mov al, 15				; bright white
		mov di, 6
		mov bl, 10
		add cl, bl
		inc cx
		
	hInitRows:
			sub cl, bl
			dec cx
			add bl, 2
			mov bh, bl
		
		
	hCurrInitCol:
			int 10h
			inc cx
			dec bh
			jnz hCurrInitCol
		
		inc dx
		dec di;
		jnz hInitRows

		mov di, 10
		
	hCenterRows:
			sub cl, bl
			mov bh, bl

	hCurrCenterCol:
			int 10h
			inc cx
			dec bh
			jnz hCurrCenterCol
		
		inc dx
		dec di;
		jnz hCenterRows

		mov di, 6
	hEndRows:
			sub cl, bl
			inc cx
			sub bl, 2
			mov bh, bl
		
		
	hCurrEndCol:
			int 10h
			inc cx
			dec bh
			jnz hCurrEndCol
		
		inc dx
		dec di;
		jnz hEndRows
	
	mov [bp + 8], cx
	mov [bp + 10], dx
	
	
	pop di
	pop bx
	pop dx
	pop cx
	pop es
	pop ax
	pop bp
	
	ret	4

printStickman:
		
	stickUpperBody:
			push 0xCCCC			; ending row of head
			push 0xCCCC			; ending column of head
			push 25				; starting Y 
			push 100				; starting X
			call printHead
			
			pop cx
			add cx, 22			; Middle Body Starting X
			pop dx
			sub dx, 11			; Middle Body Starting Y
			push dx
			push cx				; Preserving both X & Y in stack (Later Use)
			
	stickRightElbow:			; Right as in the right of the screen
			sub dx, 15
			add cx, 33
			push 48				; height of right elbow
			push 20				; width of righr elbow
			push 15				; color of right elbow
			push dx				; starting Y
			push cx			; starting X
			call printReverseTiltRect
		
	stickRightArm:
			push 48				; height of right arm
			push 20				; width of righr arm
			push 15				; color of right arm
			push dx				; starting Y
			push cx			; starting X
			call printTiltRect
			
	stickLeftElbow:			; Left as in the left of the screen
			add dx, 42
			sub cx, 42
			push 48				; height of left elbow
			push 20				; width of left elbow
			push 27				; color of left elbow
			push dx				; starting Y
			push cx			; starting X
			call printReverseTiltRect
		
	stickLeftArm:
			sub cx, 42
			;sub dx, 22
			push 48				; height of left arm
			push 20				; width of left arm
			push 27				; color of left arm
			push dx				; starting Y
			push cx			; starting X
			call printTiltRect
			
	stickLeftKnee:			; Left as in the left of the screen
			add dx, 42
			add cx, 82
			push 48				; height of left elbow
			push 20				; width of left elbow
			push 15				; color of left elbow
			push dx				; starting Y
			push cx			; starting X
			call printReverseTiltRect
		
	stickLeftLeg:
			sub cx, 12
			add dx, 22
			push 48				; height of left arm
			push 20				; width of left arm
			push 15				; color of left arm
			push dx				; starting Y
			push cx			; starting X
			call printTiltRect
			
	stickRightKnee:			; Right as in the right of the screen
			sub dx, 35
			add cx, 33
			push 48				; height of right elbow
			push 20				; width of righr elbow
			push 27				; color of right elbow
			push dx				; starting Y
			push cx			; starting X
			call printTiltRect
		
	stickRightLeg:
			add dx, 7
			add cx, 37
			push 48				; height of right arm
			push 20				; width of righr arm
			push 27				; color of right arm
			push dx				; starting Y
			push cx			; starting X
			call printReverseTiltRect
		
	stickMiddleBody:
		pop cx
		pop dx
		push 120			; height of body
		push 56				; width of body
		push 15				; color of body
		push dx				; starting Y
		push cx				; starting X
		call printTiltRect	
		
		
		ret
		
printStartScreen:

	call printMainBord
	
	call printStickman
	
	mov dx, 1909h  ; Row=20 (in DH), Column=10 (in DL)
	mov bh, 0      ; Page=0
	mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
	int 10h
	
	mov dx, startScrnMsg	 						; ds:dx points to '$' terminated string
	sub dx, 1
	mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
	int 0x21
	
	
	ret
	
printAllPortals:

	yellowPortal:
		mov cx, 10
		mov dx, 15
		push 6				; width
		push 14				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal
		
		add dx, 2
		push 4				; width
		push 116				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal
		
		add dx, 2
		push 2				; width
		push 115				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal
		
	bluePortal:
		mov cx, 220
		mov dx, 15
		push 10				; width
		push 53				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal
		
		add dx, 3
		push 7
		push 54				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal
		
		add dx, 3
		push 4
		push 55				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal

		add dx, 2
		push 2
		push 127				; color
		push dx				; starting Y 
		push cx				; starting X
		call printPortal

ret

printNameScrn:		
		mov dx, 1002h  ; Row=20 (in DH), Column=10 (in DL)
		mov bh, 0      ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov dx, enterNameMsg	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
			
		mov dx, nameBuffer 							; input buffer (ds:dx pointing to input buffer)
		mov ah, 0x0A 							; DOS' service A – buffered input
		int 0x21 								; dos services call

		mov bh, 0
		mov bl, [nameBuffer+1] 						; read actual size in bx i.e. no of characters user entered
		mov byte [nameBuffer+2+bx], '$' 			; append $ at the end of user input
		

		ret
printInstructionScrn:
			
		push ax
		push es
		push bp
		push cx
		push dx
		push bx
		push di	

		xor ax, ax
		xor bx, bx
			
		mov dx, 0007h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov dx, nameBuffer+2 						; user input buffer
		mov ah, 9 								; service 9 – write string
		int 0x21 								; dos services
		
		
		mov ax, instMsg1
		push ax					; String addres
		push 15					; 15 = bright white color
		push 000Ch				; POS
		call printstr
		
		mov ax, instMsg2
		push ax					; String addres
		push 53					; 53 = blue color
		push 0300h				; POS
		call printstr
		
		mov ax, instMsg3
		push ax					; String addres
		push 15					; 15 = bright white color
		push 0500h				; POS
		call printstr
		
		mov ax, instMsg4
		push ax					; String addres
		push 15					; 15 = bright white color
		push 0600h				; POS
		call printstr
		
		mov ax, instMsg5
		push ax					; String addres
		push 15					; 15 = bright white color
		push 0700h				; POS
		call printstr
		
		mov ax, instMsg6
		push ax					; String addres
		push 15					; 15 = bright white color
		push 0800h				; POS
		call printstr
		
		;----------Instructions not properly printing after 10th row using the subroutine
		
		mov dx, 0A00h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 40
		
		mov dx, instMsg7	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		mov dx, 0C00h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 15
		
		mov dx, instMsg8	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		mov dx, 0D00h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 15
		
		mov dx, instMsg9	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		mov dx, 0E00h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 15
		
		mov dx, instMsg10	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		mov dx, 0F00h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 15
		
		mov dx, instMsg11	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		
		mov dx, 1309h ; Row (in DH), Column(in DL)
		mov bh, 0     ; Page=0
		mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
		int 10h
		
		mov bl, 15
		
		mov dx, instMsg12	 						; ds:dx points to '$' terminated string
		mov ah, 9 								; service 9 –  WRITE STRING TO STANDARD OUTPUT
		int 0x21
		
		call EmptyKeyboardBuffer

		pop di
		pop bx
		pop dx
		pop cx
		pop bp
		pop es
		pop ax

		ret

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

	push 0x0041		            	; height.....[bp + 10]
	push 0x0C00			            ; color = dark grey.....[bp + 8]
	push 0			                ; starting col.....[bp + 6]
	push 0			            	; starting row.....[bp + 4]

    call ClearScreen

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
	push bp
	mov bp, sp
    push ax
    push cx
    push dx
    
    mov ax, 0A000h;
    mov es, ax;
    mov cx, [bp + 6]		            ; starting col
    mov dx, [bp + 4]		            ; starting row
    
	mov ax, [bp + 10]
	add ax, [bp + 4]
	mov [bp + 10], ax					; finding the correct row

    mov ax, [bp + 8]					; color
			
	clear_columns:
		mov cx, 0		                ; width

        clear_rows:
            int 10h;
            add cx, 1;
            cmp cx, [cols]
            jnz clear_rows;
    
        add dx, 1

		cmp dx, 74				; height
		je change_ceiling_color

        cmp dx, [bp + 10]                ; limited to 2nd section only             
        jnz clear_columns;
	
    pop dx
    pop cx
    pop ax
	pop bp
	
	ret 8

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
	
	ret 10

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
	
	ret 10 

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

	; ;interrupt for key press ;; is this needed here???
	; mov ah, 00h;
	; int 16h;

	ret

	change_gap:
		add dx, 8
		cmp cx, 0
		jnz loop_hooks


PrintMiddle:

	push 0x0045		            	; height.....[bp + 10]
	push 0x0C18			            ; color = dark grey.....[bp + 8]
	push 0			                ; starting col.....[bp + 6]
	push 0x0042		            	; starting row.....[bp + 4]

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


PrintCharacter:

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
    
    mov bl, [bp + 18]               ; width (picking in half register???)
    mov bh, [bp + 20]               ; height

	push bx
	mov bl, bh
	mov bh, 0
	mov ax, dx
	add ax, bx
	mov [bp + 20], ax				; finding the true height

	pop bx

	mov ax, [bp + 16]		   		; color
    
			
	character_rows:
		mov cx, word [bp + 14]

        character_columns:
            int 10h;
            add cx, 1;
            dec bl
            jnz character_columns;

		mov bl, [bp + 18]
        add dx, 1
        cmp dx, [bp + 20]           ; height
        jnz character_rows

	pop dx
	pop cx
	pop bx
	pop ax
	pop bp

	ret 10

PrintForeground:

	push ax
	push bx
	push cx
	push dx
	push es
	push si

	push 0x0040		            	; height.....[bp + 10]
	push 0x0C1C			            ; color = light brown.....[bp + 8]
	push 0			                ; starting col.....[bp + 6]
	push 136			            	; starting row.....[bp + 4]

    call ClearScreen

    push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0CF5			            ; color = navy .....[bp + 16]
	push 80			                ; starting col.....[bp + 14]
	push 165			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist


	mov ax, 235						; Starting Row of Zombies
	mov bx, 165						; Starting Column of Zombies
	mov cx, 3						; No. of zombies
	mov si, 0						; index of Zombie_x

Zombie_loop:

    ; push 0x0015			            ; height.....[bp + 20]
	; push 0x000F			            ; width......[bp + 18]
	; push 0x0C06			            ; color = navy .....[bp + 16]
	; push ax			           		; starting col.....[bp + 14]
	; push bx			            	; starting row.....[bp + 12]

	; call PrintCharacter				; Enemy

	print_pic bx, ax, char_file, ds, 0, 0xA000, 0, 200

	mov [zombies_x + si], ax
	mov [zombies_y + si], bx

	add ax, 30
	add si, 2
	dec cx
	jnz Zombie_loop


Score_Printing:

	mov ah , 0x13
	mov al , 1
	mov bh , 0x5
	mov bl , 0x2C					; Color = Yellow
	mov cx , 3						; Number of Characters
	mov dh , 17						; Row No
	mov dl , 0						; Column No
	mov bp , message_score
	push ds
	pop es
	int 0x10

Level_Num_Printing:

	mov cx , 6						; Number of Characters
	mov dh , 17						; Row No
	mov dl , 16						; Column No
	mov bp , message_level
	push ds
	pop es
	int 0x10

	push 1116h
	push word [level_num]

	call printnum

Time_Printing:

	mov cx , 5						; Number of Characters
	mov dh , 17						; Row No
	mov dl , 33						; Column No
	mov bp , message_time
	push ds
	pop es
	int 0x10

	push 1103h
	push word [score]

	call printnum
	
	pop si
	pop es
	pop dx
	pop cx
	pop bx
	pop dx

    ret
	
PrintMainScreen:        ; this will only call 3 funcs for now for printing sections
	
	call printBackground
	call PrintMiddle
	call PrintForeground
    
    ret


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;                 Animation                 ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shiftScreenRight:
		push bp
		mov bp, sp
		push dx
		push ax
		push es
		push ds
		push cx
		sub sp, 2
		
		mov dx, [bp + 8]			;number of rows
		
		mov ax,0xA000
		mov es,ax
		mov ds,ax	
		
	
		mov si,  [bp + 6]			;starting pixels
		mov di, [bp + 4]
	
	loopShiftRight:	
		
		mov al, [es:di]
		mov [bp - 2], al
		mov cx, 319
		
		nextShiftRight:
			movsb
			sub si, 2
			sub di, 2
			loop nextShiftRight
			
		mov al, [bp - 2]
		mov [es:di], al
		add si, 319
		add di, 319
		add si, 320
		add di, 320
		sub dx, 1
		jnz loopShiftRight
		
		add sp,2
		pop cx
		pop ds
		pop es
		pop ax
		pop dx
		pop bp
		ret 6
		
shiftScreenLeft:
		push bp
		mov bp, sp
		push dx
		push ax
		push es
		push ds
		push cx
		sub sp, 2
		
		mov dx, [bp + 8]			;number of rows
		mov ax, 0xA000
		mov es, ax
		mov ds, ax	
		
		mov si, [bp + 6]			;starting pixels
		mov di, [bp + 4]
	
	loopShiftLeft:	
		
		mov al, [es:di]
		mov [bp-2], al
		mov cx, 319
		
		rep movsb
		mov al, [bp - 2]
		mov [es:di], al
		sub si, 319
		sub di, 319
		add si, 320	
		add di, 320
		sub dx, 1
		jnz loopShiftLeft
		
		
		add sp,2
		pop cx
		pop ds
		pop es
		pop ax
		pop dx
		pop bp
		ret 6

PrintAnimation:

	push cx
	
	xor cx, cx

	mov cx, 1						; background Animation (keep this 1)

	
	shiftL:
		push 66						; number of rows
		push 1						; starting pixel for si
		push 0						; starting pixel for di
		call shiftScreenLeft
		loop shiftL

	mov cx, 2						; Conveyor Hooks Animation
	
	shiftL2:
		push 14						; number of rows
		push 21121					; starting pixel for si
		push 21120					; starting pixel for di
		call shiftScreenLeft
		loop shiftL2
	
	mov cx, 1						; Conveyor Belt Animation
	
	shiftR:
		push 40						; number of rows
		push 25918					; starting pixel for si
		push 25919					; starting pixel for di
		call shiftScreenRight
		loop shiftR
	

	pop cx
	ret


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
PrintStartScrnAnimation:
	push cx
	
	xor cx, cx

	mov cx, 1						; background Animation (keep this 1)

	
	startScrnShiftL:
		push 182						; number of rows
		push 1						; starting pixel for si
		push 0						; starting pixel for di
		call shiftScreenLeft
		loop startScrnShiftL	

	pop cx
	ret

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


moveright:							; (make generic by taking the coordinate for whatever is to be moved)
									; a flag would also need to be set to move the Character or the Zombie
	push cx

	mov cx, [char_x]
	cmp cx, 280
	ja noright

	push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0C1C			            ; color = navy .....[bp + 16]
	push word [char_x]			                ; starting col.....[bp + 14]
	push word [char_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist

	add cx, 5
	mov [char_x], cx

	push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0CF5			            ; color = navy .....[bp + 16]
	push word [char_x]			                ; starting col.....[bp + 14]
	push word [char_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist

	call check_right_zombie

	pop cx
	ret

	noright:
		pop cx
		ret


check_right_zombie:

		; traverse zombies_x array in a loop and check for collision

		push ax
		push bx
		push cx
		push si

		mov cx, 6						; max number of zombies
		mov si, 0

right_zombie_loop:

		mov ax, [char_x]
		add ax, 15
		
		mov bx, [zombies_x + si]
		cmp ax, bx
		je exit							; edit this to show Game Over Screen

		add si, 2
		dec cx
		jnz right_zombie_loop

exit97:
	
		pop si
		pop cx
		pop bx
		pop ax
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;move left
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

moveleft:							; (make generic by taking the coordinate for whatever is to be moved)
									; a flag would also need to be set to move the Character or the Zombie
	push cx

	mov cx, [char_x]
	cmp cx, 20
	jl noleft

	push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0C1C ;??			            ; color = navy .....[bp + 16]
	push word [char_x]			                ; starting col.....[bp + 14]
	push word [char_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist

	sub cx, 5
	mov [char_x], cx

	push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0CF5			            ; color = navy .....[bp + 16]
	push word [char_x]			                ; starting col.....[bp + 14]
	push word [char_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist

	pop cx
	ret

	noleft:

	pop cx
	ret


shootleft:							; (make generic by taking the coordinate for whatever is to be moved)
									; a flag would also need to be set to move the Character or the Zombie
	push ax
	push cx

	mov ax, [char_x]		; initialize coordinates at the character's left side
	sub ax, 5				; 5px will need to be removed for left bullet
	mov [bullet_x], ax

	mov ax, [char_y]
	mov [bullet_y], ax

shootleft_loop:

	mov cx, [bullet_x]
	cmp cx, 20
	jl no_bulletleft

	push 0x0003			            ; height.....[bp + 20]
	push 0x0005			            ; width......[bp + 18]
	push 0x0C1C ;??			        ; color = navy .....[bp + 16]
	push word [bullet_x]			; starting col.....[bp + 14]
	push word [bullet_y]			; starting row.....[bp + 12]

	call PrintCharacter				; Bullet

	sub cx, 5
	mov [bullet_x], cx

	push 0x0003			            ; height.....[bp + 20]
	push 0x0005			            ; width......[bp + 18]
	push 0x0CF9			            ; color = navy .....[bp + 16]
	push word [bullet_x]			; starting col.....[bp + 14]
	push word [bullet_y]			; starting row.....[bp + 12]

	call PrintCharacter				; Bullet

	call delay

	call check_left_bullet			; check for collision with each zombie

	cmp word [bullet_impact], 1
	je loophole4

loophole3:

	jmp shootleft_loop

	; pop cx
	; pop ax
	; ret

	no_bulletleft:

		;cmp word [bullet_impact], 0
		call erase_bullet

		pop cx
		pop ax
		ret

loophole4:

	call erase_bullet
	jmp loophole3


check_left_bullet:

		; traverse zombies_x array in a loop and check for collision

		push ax
		push cx
		push si

		mov cx, 6						; max number of zombies
		mov si, 0

left_bullet_loop:

		mov ax, [zombies_x + si]
		add ax, 5
		
		cmp ax, [bullet_x]
		je erase_left_bullet

		add si, 2
		dec cx
		jnz left_bullet_loop

exit99:
	
		pop si
		pop cx
		pop ax
		ret
		
erase_left_bullet:

		mov word [bullet_impact], 1			; turn the flag on
		jmp exit99



shootright:							; make generic by taking the coordinate for whatever is to be moved
									; a flag would also need to be set to move the Character or the Zombie
									; x_coordinates of all zombies can be placed in an array and checked continuously for collision
	push ax
	push cx

	mov ax, [char_x]		; initialize coordinates at the character's left side
	add ax, 20				; 10px will need to be added for right bullet
	mov [bullet_x], ax

	mov ax, [char_y]
	mov [bullet_y], ax

shootright_loop:

	mov cx, [bullet_x]
	cmp cx, 300
	ja no_bulletright

	cmp word [bullet_erased], 1
	je no_bulletright

	push 0x0003			            ; height.....[bp + 20]
	push 0x0005			            ; width......[bp + 18]
	push 0x0C1C ;??			            ; color = navy .....[bp + 16]
	push word [bullet_x]			                ; starting col.....[bp + 14]
	push word [bullet_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Bullet

	add cx, 5
	mov [bullet_x], cx

	push 0x0003			            ; height.....[bp + 20]
	push 0x0005			            ; width......[bp + 18]
	push 0x0CF9			            ; color = navy .....[bp + 16]
	push word [bullet_x]			                ; starting col.....[bp + 14]
	push word [bullet_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Bullet

	call delay

	call check_right_bullet			; check for collision with each zombie

	cmp word [bullet_impact], 1
	je loophole2
	
loophole1:

	jmp shootright_loop

	; pop cx
	; pop ax
	; ret

	no_bulletright:

		;cmp word [bullet_impact], 0
		call erase_bullet

		mov word [bullet_erased], 0
		pop cx
		pop ax
		ret

loophole2:

	call erase_bullet
	jmp loophole1


check_right_bullet:

		; traverse zombies_x array in a loop and check for collision

		push ax
		push bx
		push cx
		push si

		mov cx, 6						; max number of zombies
		mov si, 0

right_bullet_loop:

		mov ax, [bullet_x]
		add ax, 5
		
		mov bx, [zombies_x + si]
		cmp ax, bx
		je erase_right_bullet

		add si, 2
		dec cx
		jnz right_bullet_loop

exit98:
	
		pop si
		pop cx
		pop bx
		pop ax
		ret
		
erase_right_bullet:

		mov word [bullet_impact], 1			; turn the flag on
		jmp exit98


erase_bullet:

	push 0x0003			            ; height.....[bp + 20]
	push 0x0005			            ; width......[bp + 18]
	push 0x0C1C				        ; color = navy .....[bp + 16]
	push word [bullet_x]            ; starting col.....[bp + 14]
	push word [bullet_y]	        ; starting row.....[bp + 12]

	call PrintCharacter				; Bullet

	mov word [bullet_x], 0
	mov word [bullet_y], 0

	mov word [bullet_erased], 1

	cmp word [bullet_impact], 1
	je loophole6

loophole5:

	mov word [bullet_impact], 0

	ret

loophole6:

	call erase_zombie
	jmp loophole5	


erase_zombie:

	push ax
	push si

	mov si, [current_zombie]

    push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0C1C				        ; color = navy .....[bp + 16]
	push word [zombies_x + si]      ; starting col.....[bp + 14]
	push word [zombies_y + si]	    ; starting row.....[bp + 12]

	call PrintCharacter				; Zombie

	mov word [zombies_x + si], 0
	mov word [zombies_y + si], 0

	add si, 2
	mov [current_zombie], si		; Update Zombie Index

Update_Score:

	mov ax, word [score]			; updating score
	inc ax
	mov word [score], ax

	push 1103h
	push word [score] ; send in time or any other loop

	call printnum

; Check for Starting Level 2

compare_score:

	cmp word [score], 3
	jne .lev2
	mov word [level_flag], 1
	mov word [level_num], 2

.lev2:
	cmp word [score], 6
	jne .lev3
	mov word [level_flag], 1
	mov word [level2_flag], 1

.lev3:
	cmp word [score], 9
	je exit	; preferably set [isgamerunning to 0 here]	

.ret:

	pop si
	pop ax
	ret

Print_Level:

	; erase character from current location

	push 0x0015			            ; height.....[bp + 20]
	push 0x000F			            ; width......[bp + 18]
	push 0x0C1C			            ; color = navy .....[bp + 16]
	push word [char_x]			                ; starting col.....[bp + 14]
	push word [char_y]			            ; starting row.....[bp + 12]

	call PrintCharacter				; Protagonist

	; update character's coordinates

	mov word [char_x], 80
	mov word [char_y], 165

	; update current zombie

	mov word [current_zombie], 0

	cmp word [level2_flag], 0
	je reset_timer	

loophole7:

	call PrintForeground
	
	mov word [level_flag], 0

	ret

reset_timer:

	mov word [tickcount], 0
	mov word [tickCountInc], 0
	jmp loophole7

;;;;;;;;;;;;;;;;;;;;;;


;------------------------------------------------------
; subroutine to print a number at top left of screen
; takes the number to be printed as its parameter
;------------------------------------------------------
printnum: 	

			push bp
			mov bp, sp
			push es
			push ax
			push bx
			push cx
			push dx
			push di
			
			mov ax, 0A000h
			mov es, ax ; point es to video base
			
			mov ax, [bp+4] ; load number in ax
			mov bx, 10 ; use base 10 for division
			mov cx, 0 ; initialize count of digits
			nextdigit:
				mov dx, 0 ; zero upper half of dividend
				div bx ; divide by 10
				add dl, 0x30 ; convert digit into ascii value
				push dx ; save ascii value on stack
				inc cx ; increment count of values
				cmp ax, 0 ; is the quotient zero
				jnz nextdigit ; if no divide it again
				
			mov di, 140 ; point di to 70th column
			

			mov dx, [bp + 6]  ; Row=12 (in DH), Column=20 (in DL)
			nextpos:
				;pop dx ; remove a digit from the stack
				;mov dh, 0x07 ; use normal attribute
				;mov [es:di], dx ; print char on screen
				
				
				mov bh, 0      ; Page=0
				mov ah, 02h    ; BIOS.SetCursorPosition - Point to the location of dx and page no. of bh
				int 10h
				
				pop ax
				mov bx, 002Ch  ; Page=0 (in BH), Color=15 (in BL)             15 is BrightWhite
				mov ah, 0Eh  ; BIOS.Teletype (in AH), Character=33 (in AL)  33 is ASCII of "!"
				int 10h
				
				inc dx;
				;add di, 2 ; move to next screen location
				loop nextpos ; repeat for all digits on stack

			pop di
			pop dx
			pop cx
			pop bx
			pop ax 
			pop es
			pop bp
			ret 4

Print_GameOver:

	push ax		            
	push bx			           
	push cx			       
	push dx			            
	push bp
	push ds
	push es

	call clrScrn

	cmp word [score], 9
	je Print_Win

	mov ah , 0x13
	mov al , 1
	mov bh , 0x5
	mov bl , 0x2C ; [GameOverAttribute]	; 0x0A
	mov cx , 9		; Number of Characters
	mov dh , 12						; Row No
	mov dl , 15						; Column No
	mov bp , GameOver
	push ds
	pop es
	int 0x10

Score_Printing2:

	mov cx , 3						; Number of Characters
	mov dh , 14						; Row No
	mov dl , 17						; Column No
	mov bp , message_score
	push ds
	pop es
	int 0x10

	push 0E14h
	push word [score] ; send in time or any other loop

	call printnum

	pop ax		            
	pop bx			           
	pop cx			       
	pop dx			            
	pop bp
	pop ds
	pop es

	; interrupt for key press
    mov ah, 00h;
    int 16h;

	ret

Print_Win:

	mov ah , 0x13
	mov al , 1
	mov bh , 0x5
	mov bl , 0x2C ; [GameOverAttribute]	; 0x0A
	mov cx , 8		; Number of Characters
	mov dh , 12						; Row No
	mov dl , 15						; Column No
	mov bp , message_win
	push ds
	pop es
	int 0x10
	
	jmp Score_Printing2

EmptyKeyboardBuffer:
  push ax
.more:
  mov  ah, 01h        ; BIOS.ReadKeyboardStatus
  int  16h            ; -> AX ZF
  jz   .done          ; No key waiting aka buffer is empty
  mov  ah, 00h        ; BIOS.ReadKeyboardCharacter
  int  16h            ; -> AX
  jmp  .more          ; Go see if more keys are waiting
.done:
  pop  ax
  ret

;------------------------------------------------------
; timer interrupt service routine
;------------------------------------------------------
timer:		push ax
			cmp word [cs:isGameRunning], 0;
			je exitTimer
			
			cmp word [cs:isEscape], 1
			je exitTimer
			
			inc word [cs:tickCountInc];
			cmp word [cs:tickCountInc], 20
			jne exitTimer;
			mov word [cs:tickCountInc],0
			
			inc word [cs:tickcount]			; increment tick count

			push 1126h					 	; Row=12 (in DH), Column=20 (in DL)
			push word [cs:tickcount]

			call printnum ; print tick count
			
			cmp word[cs:tickcount], 30		; add exit game after 30 seconds
			jne exitTimer

			mov word [cs:isGameRunning], 0

exitTimer:
			mov al, 0x20
			out 0x20, al ; end of interrupt
			;jmp far [cs:oldtimerisr] ; call the original ISR
			pop ax
			iret ; return from interrupt

kbisr:
		
	push ax
	push es
	push ds

	push cs
	pop ds							; DS is being changed somewhere, so we need to preserve it
	
	in al, 0x60

	
	cmp word [cs:isEscape], 1
	je chkEscapeYes
	
	chkEscape:
		cmp al , 0x01				; SCAN CODE Enter "ESC"
		jne chkStartScrn
		mov word [cs:isEscape] , 1
		;call printPauseScrn
		jmp exit_kbisr
		
	chkEscapeYes:
		cmp word [cs:isEscape], 0
		je chkStartScrn
		cmp al, 0x15				; SCAN CODE Enter "Y"
		jne chkEscapeNo
		mov word [cs:isYes], 1
		jmp exit_kbisr
		
	chkEscapeNo:
		cmp word [cs:isEscape], 0
		je chkStartScrn
		cmp al, 0x31				; SCAN CODE Enter "N"
		jne exit_kbisr
		mov word [cs:isNo], 1
		;mov word [cs:isEscape], 0
		;mov word [cs:isYes], 0
		; push 80
		; push 88
		; call RestoreBuffer
		jmp exit_kbisr		
		
	chkStartScrn:
		cmp word [isStartScrn], 0
		je cmp_left
		cmp al, 0x39				; SCAN CODE Enter "1c"
		jne exit_kbisr
		mov word [isStartScrn], 0
		jmp exit_kbisr
	cmp_left:
		cmp al,0x39               ; SCAN CODE Space Bar
		jne cmp_left_bullet
		mov word [leftkeypressed] , 1
		jmp exit_kbisr


	cmp_left_bullet:
		cmp al,0x10               ; SCAN CODE "Q"
		jne cmp_right_bullet
		mov word [leftbulletpressed] , 1
		jmp exit_kbisr

	cmp_right_bullet:
		cmp al,0x12               ; SCAN CODE "E"
		jne cmp_right
		mov word [rightbulletpressed] , 1
		jmp exit_kbisr


	cmp_right:
		cmp al,0x36               ; SCAN CODE Right Shift
		jne exit_kbisr
		mov word [rightkeypressed] , 1


	exit_kbisr:
		
		; mov al,0x20
		; out 0x20,al                ; send EOI to PIC

		pop ds
		pop es
		pop ax
		
		jmp far [cs:oldisr] 		; call the original ISR
		;iret                       ; return from interrupt


call_level_change:

	call Print_Level
	mov word [level_flag], 0
	jmp levelflagreturn
	


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	xor ax, ax
	mov es, ax
	mov ax, [es:9*4]
	mov [oldisr], ax
	mov ax, [es:9*4+2]
	mov [oldisr+2], ax


	cli
	mov word [es:8*4], timer
	mov [es:8*4+2], cs
	
	mov word [es:9*4], kbisr
	mov [es:9*4+2], cs
	sti

	
	call printStartScreen
	
loopStartScreen:
	call PrintStartScrnAnimation
	
	cmp word [isStartScrn], 0
	jne loopStartScreen
	
	call clrScrn

	call printNameScrn
	
	call clrScrn
	call printInstructionScrn
	
	; interrupt for key press

    mov ah, 00h;
    int 16h;
	
	call clrScrn
	
	call PrintMainScreen

	mov word [isGameRunning],1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


loop99:

		cmp word [isGameRunning], 0
		je exit
		
		cmp word [isEscape], 1
		jne checklevelflag
		cmp word [isPausePrint], 1
		je inputCompare
		call printPauseScrn
		mov word [isPausePrint], 1

inputCompare:
		cmp word [isYes], 1
		je exit
		cmp word [isNo], 1
		jne skipPause
		
callRestoreBuffer:

		call PrintMiddle
		mov word [isPausePrint], 0
		mov word [isNo], 0
		mov word [isEscape], 0
		
skipPause:		jmp animation_loop

checklevelflag:

		cmp word [level_flag], 1
		je call_level_change

levelflagreturn:

		call PrintAnimation

checkleft:	cmp word [leftkeypressed] , 1
			jne checkright

			call moveleft
			mov word [leftkeypressed], 0
			jmp animation_loop

checkright:	cmp word [rightkeypressed] , 1
			jne checkleft_bullet

			call moveright
			mov word [rightkeypressed], 0
			jmp animation_loop

checkleft_bullet:

			cmp word [leftbulletpressed] , 1
			jne checkright_bullet

			call shootleft
			mov word [leftbulletpressed], 0
			jmp animation_loop

checkright_bullet:

			cmp word [rightbulletpressed] , 1
			jne animation_loop

			call shootright
			mov word [rightbulletpressed], 0


animation_loop:	jmp loop99


exit:
	mov word [isYes], 0
	mov word [isGameRunning], 0

	call EmptyKeyboardBuffer
	call Print_GameOver

; setting the mode back to text
	mov ah, 00h;
	mov al, 03h;
	int 10h;

	call clrScrn

	
; terminate
	mov ah, 4ch;
	int 21h;