[org 0x0100]

	jmp start

PrintTrain:
		push bp
		mov bp, sp

		mov ch, [bp + 4]			; store number of rows
		
		cabin_rows:		; add loop for train ~3 times
			mov cl, 20
			mov dl, 3
			add di, 16					; to have 10 pixels of free space


			cabin_columns:
				mov ah, 0x44			; move attribute (white color)
				mov al, 0x20			; move data
				mov word[es:di], ax
				add di, 2
				dec cl
				jnz cabin_columns
			
			add di, 2					; place holder for the link bw bogies
			mov cl, 20
			dec dl
			jnz cabin_columns

			add di, 18					; to leave 10 pixels of free space
			dec ch
			jnz cabin_rows

		add di, 20
		mov ch, 6

		wheels_rows:
			
			mov cl, 4						; width of each wheel / columns

			wheels_columns:
				mov ah, 0x00			; move attribute (black color)
				mov al, 0x20			; move data
				mov word[es:di], ax
				add di, 2
				dec cl
				jnz wheels_columns

			test ch, 1					; checks if counter is odd
			jz skip
			add di, 10
			jmp cont

	skip:
			add di, 16					; 8px space bw wheels of same cabin
	cont:
			dec ch
			jnz wheels_rows

		add di, 14
		
		pop bp
		ret 4


PrintTrack:
		push bp
		mov bp, sp
		
		;mov ax, [bp + 8]
		;add di, ax

		mov ch, [bp + 6]				; store number of rows as counter
		dec ch

		rows:
			mov cl, [bp + 4]				; store number of columns as counter

			columns:
				mov ah, 0x60			; move attribute (brown color)
				mov al, 0x20			; move data
				mov word[es:di], ax
				add di, 2
				dec cl
				jnz columns

			;add di, 140
			dec ch
			jnz rows

		mov ch, 0x03			; rows

		TrackSupports:
			
			mov cl, 0x02		; columns
			add di, 36

			l2:
				mov ah, 0x60			; move attribute (brown color)
				mov al, 0x20			; move data
				mov word[es:di], ax
				add di, 2
				dec cl
				jnz l2

			dec ch
			jnz TrackSupports

		add di, 40
		pop bp
		ret 6
	
start:	
        mov ax, 0xb800 				; load video base in ax
        mov es, ax 					; point es to video base
        mov di, 0 					; point di to top left column
                                    ; es:di pointint to --> 0xB800:0000 (B8000)

ClrScreen: 	
		mov ah, 0x30			; move attribute (cyan color)
		mov al, 0x20			; move data
		mov word[es:di], ax
		add di, 2 						; move to next screen location
		cmp di, 4000 						; has the whole screen cleared
		jne ClrScreen 						; if no clear next position

Background: 	
		mov ah, 0x30			; move attribute (cyan color)
		mov al, 0x20			; move data
		mov word[es:di], ax
		add di, 2 						; move to next screen location
		cmp di, 1440 					; has the whole screen cleared
		jne Background 					; if no clear next position

Middle: 	
		add di, 160						; to skip 1 row
		push 0x0004						; push rows of train
		call PrintTrain
		

		; add di, 160						; to skip 1 row
		push 0x0002						; push rows of square
		push 0x0050						; push columns of square
		call PrintTrack

Foreground: 	
		mov ah, 0x20			; move attribute (green color)
		mov al, 0x20			; move data
		mov word[es:di], ax
		add di, 2 						; move to next screen location
		cmp di, 4000 						; has the whole screen cleared
		jne Foreground 						; if no clear next position

mov ax, 0x4c00 ; terminate program
int 0x21 