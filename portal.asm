[org 0x0100]

	; set the video mode to 13h
	; resolution of 320x200 with 256 color options
	; 1 Byte for 1 Pixel
	mov ah, 00h;
	mov al, 13h;        how to change resolution???
	int 10h;

    jmp start

    Rows: dw 200
    Columns: dw 320
    
ClearScreen:
        push ax
        push cx
        push dx
        
        mov ax, 0A000h;
		mov es, ax;
		mov cx, 0;		; starting col
		mov dx, 0;		; starting row
		
		mov ah, 0x0C;
		mov al, 4		; color

        mov cx, 0
        mov dx, 0
			
	printh:
			mov cx, 0		; width
	printrow:
			int 10h;
			add cx, 1;
			cmp cx, [Columns]
			jnz printrow;
    
		add dx, 1;
		cmp dx, [Rows]
		jnz printh;
	
    pop dx
    pop cx
    pop ax
	
; interrupt for key press ;; is this needed here???
	; mov ah, 00h;
	; int 16h;
	
	ret
	
	
; interrupt for key press
	mov ah, 00h;
	int 16h;
	
	ret 10;
	
PrintMainScreen:

    call ClearScreen


	push 50			; height.....[bp + 10]
	push 40			; width......[bp + 8]
	push 14			; color = yellow.....[bp + 6]
	push 10			; starting col.....[bp + 4]
	push 20			; starting row.....[bp + 2]
	;call printRect;



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;               Main Function               ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
start:
    call PrintMainScreen
	
; setting the mode back to text
	mov ah, 00h;
	mov al, 03h;
	int 10h;
	
; terminate
	mov ah, 4ch;
	int 21h;
	

