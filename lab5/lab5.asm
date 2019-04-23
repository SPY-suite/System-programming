.586
.model flat, stdcall, c

option casemap :none


include C:\masm32\include\windows.inc

include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc


includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\user32.lib

.data 
    counter dd 0
    myLength dd 0
    ValueAi dd 0


	Caption1 db "n!",0
	Caption2 db "n! * n!",0
	Caption3 db "Test #1: N*N  111...1*111...1",0
	Caption4 db "Test #2: N*32 111...1*111...1",0
	Caption5 db "Test #3: N*N  111...1*110...0",0
	
	factMultiplier dd 1  ; start of factorial
	factCounter dd 40    ; counter of factorial

	valueA dd 1, 0, 0, 0, 0,0

	val11 dd 6 dup(0FFFFFFFFh)
	val11x32 dd 0FFFFFFFFh, 0FFFFFFFFh, 0FFFFFFFFh, 0FFFFFFFFh, 0FFFFFFFFh, 0FFFFFFFFh,0FFFFFFFFh, 0FFFFFFFFh, 0, 0, 0, 0, 0, 0, 0
	val110 dd 0, 0, 0, 0, 0, 0C0000000h, 0C0000000h
	
	faxtXfact dd 12 dup(0)
	test1Res dd 12 dup(0)
	test2Res dd 12 dup(0)

	TextBuf db 64 dup(?)
.code 
StrHex_MY proc
	push ebp
	mov ebp,esp
	mov ecx, [ebp+8] ;кількість бітів числа
	cmp ecx, 0
	jle @exitp
	shr ecx, 3 ;кількість байтів числа
	mov esi, [ebp+12] ;адреса числа
	mov ebx, [ebp+16] ;адреса буфера результату
@cycle:
	mov dl, byte ptr[esi+ecx-1] ;байт числа - це дві hex-цифри
	mov al, dl
	shr al, 4 ;старша цифра
	call HexSymbol_MY
	mov byte ptr[ebx], al
	mov al, dl ;молодша цифра
	call HexSymbol_MY
	mov byte ptr[ebx+1], al
	mov eax, ecx
	cmp eax, 4
	jle @next
	dec eax
	and eax, 3 ;проміжок розділює групи по вісім цифр
	cmp al, 0
	jne @next
	mov byte ptr[ebx+2], 32 ;код символа проміжку
	inc ebx
@next:
	add ebx, 2
	dec ecx
	jnz @cycle
	mov byte ptr[ebx], 0 ;рядок закінчується нулем
@exitp:
	pop ebp
	ret 12

StrHex_MY endp

;ця процедура обчислює код hex-цифри
;параметр - значення AL
;результат -> AL
HexSymbol_MY proc
	and al, 0Fh
	add al, 48 ;так можна тільки для цифр 0-9
	cmp al, 58
	jl @exitp
	add al, 7 ;для цифр A,B,C,D,E,F
@exitp:
	ret
HexSymbol_MY endp


;ця процедура записує 8 символів HEX коду числа
;перший параметр - 32-бітове число
;другий параметр - адреса буфера тексту
DwordToStrHex proc
push ebp
mov ebp,esp
mov ebx,[ebp+8] ;другий параметр
mov edx,[ebp+12] ;перший параметр
xor eax,eax
mov edi,7
@next:
mov al,dl
and al,0Fh ;виділяємо одну шістнадцяткову цифру
add ax,48 ;так можна тільки для цифр 0-9
cmp ax,58
jl @store
add ax,7 ;для цифр A,B,C,D,E,F
@store:
mov [ebx+edi],al
shr edx,4
dec edi
cmp edi,0
jge @next
pop ebp
ret 8
DwordToStrHex endp


Mul_Nx32_LONGOP proc
	push ebp
	mov ebp,esp
	mov ecx,[ebp+8] ; встановлення лічильника
	mov esi,[ebp+16] ;ESI = адреса B
	mov ebp,[ebp+12] ;EBP = A

	xor ebx,ebx		; обнуляємо ebx
	xor edi, edi	; обнуляємо edi. Зсув
	cycle:
		mov eax,ebp			;EAX = A
		mul dword ptr[esi+4*edi]
		clc					; встановлення переносу в нуль
		adc eax,ebx
		adc edx,0
		mov dword ptr[esi+4*edi],eax
		mov ebx,edx

		inc edi				; збільшення зсуву на 1
		dec ecx				; зменшуємо лічильник на 1
		jnz cycle	; якщо лічильник не 0, то перехід на мітку cycle_Mul_Nx32
	pop ebp
	ret 12
Mul_Nx32_LONGOP endp

Mul_NxN_LONGOP proc
	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	mov myLength,eax
	mov esi,[ebp+12]
	mov edi,[ebp+16]
	mov ebp,[ebp+20]
	
	mov counter,0
	cycle_out:			; початок зовнішнього циклу1
		mov eax,counter			
		inc eax					; збільшуємо лічильник на одиницю
		cmp eax,myLength
		jg exit					; вихід з циклу
		mov counter,eax

		mov ecx,myLength			; встановлення лічильника внутрішнього циклу

		mov ebx,dword ptr[esi+4*eax-4]	; записуємо в пам'ять множник Аix32
		mov ValueAi,ebx

		xor ebx,ebx				; обнуляємо ebx		
		cycle_in:
			mov eax,ValueAi
			mul dword ptr[edi+4*ebx]
			
			; встановлення переносу в нуль
			add dword ptr[ebp+4*ebx],eax
			adc dword ptr[ebp+4*ebx+4],edx
			
			jnc not_res_cor
				mov eax,1
				add eax,ebx
				stc ; встановлення переносу в одиницю
				res_cor2:
					inc eax
					adc dword ptr[ebp+4*eax],0
					jl res_cor2
			not_res_cor:

			inc ebx					; збільшення зсуву на 1
			dec ecx					; зменшуємо лічильник на 1
			jnz cycle_in	; якщо лічильник не 0, то перехід на мітку cycle_Mul_NxN
		
		add ebp,4					; збільшення запису результату зсуву на 1
		jmp cycle_out

		exit:
	pop ebp
	ret 16
Mul_NxN_LONGOP endp
Add_224_LONGOP proc

   push ebp 
   mov ebp,esp 
   
   mov esi, [ebp+16]           ;ESI = адреса A 
   mov ebx, [ebp+12]           ;EBX = адреса B 
   mov edi, [ebp+8]            ;EDI = адреса результату  

   mov ecx, 7   ; ECX = потрібна кількість повторень 
   mov edx,0

   clc            ; обнулює біт CF регістру EFLAGS 

   cycle: 
   mov eax, dword ptr[esi+4*edx]  
   adc eax, dword ptr[ebx+4*edx]     ; додавання групи з 32 бітів 
   mov dword ptr[edi+4*edx], eax   

   inc edx
   dec ecx        ; лічильник зменшуємо на 1 
   jnz cycle 
   pop ebp
   ret 12
Add_224_LONGOP endp
Sub_896_LONGOP proc
   push ebp 
   mov ebp,esp 
 
   mov esi, [ebp+16]           ;ESI = адреса A 
   mov ebx, [ebp+12]           ;EBX = адреса B 
   mov edi, [ebp+8]            ;EDI = адреса результату  
   mov ecx, 7   ; ECX = потрібна кількість повторень 
   mov edx,0
   clc            ; обнулює біт CF регістру EFLAGS 
   cycle: 
   mov eax, dword ptr[esi+4*edx]  
   sbb eax, dword ptr[ebx+4*edx]     ; віднімання групи з 32 бітів 
   mov dword ptr[edi+4*edx], eax   
   inc edx
   dec ecx        ; лічильник зменшуємо на 1 
   jnz cycle 
   pop ebp
   ret 12
Sub_896_LONGOP endp



main:
	; ====================   N! 
	cycleFact:
		push offset valueA		; передача в стек адреси першого операнду
		push factMultiplier	    ; передача другого операнду
		push 6					; запис в стек кількості 32-бітних чисел в числі
		call Mul_Nx32_LONGOP	; виклик функції множення Nx32
		inc factMultiplier		; збільшення зсуву на 1 
		dec factCounter		    ; зменшуємо лічильник на 1
	jnz cycleFact

	push offset TextBuf			; передача в стек адреси результату
	push offset valueA			; передача в стек адреси операнду
	push 192				; запис в стек кількості біт в числі
	call StrHex_MY				; виклик функції формування 16-го числа
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption1, 0

	
	
	; ====================   N! * N!
	push offset faxtXfact		; передача в стек адреси результату
	push offset valueA			; передача в стек адреси першого операнду
	push offset valueA			; передача в стек адреси другого операнду
	push 6				     	; запис в стек кількості 32-бітних чисел в числі
	call Mul_NxN_LONGOP

	push offset TextBuf			; передача в стек адреси результату
	push offset faxtXfact		; передача в стек адреси операнду
	push 384					; запис в стек кількості біт в числі
	call StrHex_MY				; виклик функції формування 16-го числа
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption2, 0

;**************************************************************************************



	; ====================   N * N  111..1*111..1
	push offset test1Res		; передача в стек адреси результату
	push offset val11		    ; передача в стек адреси першого операнду
	push offset val11		    ; передача в стек адреси другого операнду
	push 6						; запис в стек кількості 32-бітних чисел в числі
	call Mul_NxN_LONGOP

	push offset TextBuf			; передача в стек адреси результату
	push offset test1Res		; передача в стек адреси операнду
	push 384					; запис в стек кількості біт в числі
	call StrHex_MY				; виклик функції формування 16-го числа
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption3, 0

	
	; ====================   N * 32  111..1*111..1
	push offset val11x32	    ; передача в стек адреси першого операнду
	push 0FFFFFFFFh				; передача другого операнду
	push 12						; запис в стек кількості 32-бітних чисел в числі
	call Mul_Nx32_LONGOP		; виклик функції множення Nx32

	push offset TextBuf			; передача в стек адреси результату
	push offset val11x32	    ; передача в стек адреси операнду
	push 384					; запис в стек кількості біт в числі
	call StrHex_MY				; виклик функції формування 16-го числа
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption4, 0
	
	; ====================   N * N  111..1*110..0
	push offset test2Res		; передача в стек адреси результату
	push offset val11	    	; передача в стек адреси першого операнду
	push offset val110	    	; передача в стек адреси другого операнду
	push 6						; запис в стек кількості 32-бітних чисел в числі
	call Mul_NxN_LONGOP

	push offset TextBuf			; передача в стек адреси результату
	push offset test2Res		; передача в стек адреси операнду
	push 384					; запис в стек кількості біт в числі
	call StrHex_MY				; виклик функції формування 16-го числа
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption5, 0
	invoke ExitProcess, 0
end main
