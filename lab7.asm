IDEAL			
MODEL small		
STACK 256		
				
			 
MACRO M_Init ; init macros
    mov ax, @data
    mov ds, ax
    mov es, ax
ENDM M_Init

DATASEG
    
    string db 254
	
    display_message1 db "press a for count", 10, 13, "$"	
	display_message2 db "press S for beep", 10, 13, "$"
	display_message3 db "press d for exit", 10, 13, "$"
	display_message4 db "Input command and press enter: ", 10, 13, "$"

    ;------Константи для функції звуку
    NUMBER_CYCLES EQU 2000
    FREQUENCY EQU 600
    PORT_B EQU 61H
    COMMAND_REG EQU 43H ; Адреса командного регістру 
    CHANNEL_2 EQU 42H ; Адреса каналу 2

	

	exCode db 0
	
				
CODESEG

Start:
    M_Init
	
	Menu:
        call displayMenu
        
        mov ah, 0ah 
        mov dx, offset string
        int 21h 
        xor ax, ax
        mov bx, offset string 
        mov ax, [bx+1]
        shr ax, 8 ; зсув в регістрі ах для виконання cmp

        cmp ax, 61h ; a ascii == 61h
        je expr_count
        
        cmp ax, 053h ; S ascii == 53h
        je func_beep
        
        cmp ax, 064h ; d ascii == 64h
        je Exit
        
        jmp Menu ; повернення до почактку програми

	expr_count:
		call count ; виклик функції розрахунку
		jmp Menu ; повернення до почактку програми

	func_beep:
		call beep ; виклик  функції виведення звуку
		jmp Menu ; повернення до почактку програми

	Exit:
		mov ah,4ch 		;Завантаження числа 4ch до регістру ah(Функція DOS 4ch - завершення програми)
		mov al,[exCode]	;отримання коду виходу 
		int 21h			;виклик функції DOS 4ch



	PROC displayMenu
		mov dx, offset display_message1 ; вивід повідомлення меню
		mov ah,09h
		int 21h
        mov dx, offset display_message2 ; вивід повідомлення меню
		mov ah,09h
		int 21h	
        mov dx, offset display_message3 ; вивід повідомлення меню
		mov ah,09h
		int 21h
        mov dx, offset display_message4 ; вивід повідомлення меню
		mov ah,09h
		int 21h			
		ret
	endp displayMenu

	PROC count
        ; Вираз ((a1-a2)*a3*a4+a5)	a1=-1, a2=2, a3=1,	a4=2,	a5=3
		mov al, -1 
		mov bl, 2 
		sub al, bl 
		mov bl, 1 
		imul bl 
		mov bl, 2 
		imul bl 
		mov bl, 3 
		add al, bl
		add al, 38h  
		mov [ES:0201h], al 
		mov [ES:0202h], 10
		mov [ES:0203h], 13
		mov [ES:0204h], '$'
		mov dx, (201h) 
		mov ah, 09h 
		int 21h ; вивід числа
		ret
	endp count

	PROC beep
		;Встановлення частоти 440 гц
        ;--- дозвіл каналу 2 встановлення порту В мікросхеми 8255
        IN AL,PORT_B ;Читання
        OR AL,3 ;Встановлення двох молодших бітів
        OUT PORT_B,AL ;пересилка байта в порт B мікросхеми 8255
        ;--- встановлення регістрів порту вводу-виводу
        MOV AL,10110110B ;біти для каналу 2
        OUT COMMAND_REG,AL ;байт в порт командний регістр
        ;--- встановлення лічильника 
        MOV AX,2945 ;лічильник = 1190000/440
        OUT CHANNEL_2,AL ;відправка AL
        MOV AL,AH ;відправка старшого байту в AL
        OUT CHANNEL_2,AL ;відправка старшого байту 
        
        mov cx, 200 
        L1:
            mov bx, cx
            mov  ah,86h
            xor cx, cx
            mov  dx,25000
            int  15h
            mov cx, bx 
        loop L1

        ;--- виключення звуку 
        IN AL,PORT_B ;отримуємо байт з порту В
        AND AL,11111100B ;скидання двох молодших бітів
        OUT PORT_B,AL ;пересилка байтів в зворотному напрямку
        ret
	endp beep
END Start