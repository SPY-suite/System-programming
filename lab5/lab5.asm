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
	mov ecx, [ebp+8] ;������� ��� �����
	cmp ecx, 0
	jle @exitp
	shr ecx, 3 ;������� ����� �����
	mov esi, [ebp+12] ;������ �����
	mov ebx, [ebp+16] ;������ ������ ����������
@cycle:
	mov dl, byte ptr[esi+ecx-1] ;���� ����� - �� �� hex-�����
	mov al, dl
	shr al, 4 ;������ �����
	call HexSymbol_MY
	mov byte ptr[ebx], al
	mov al, dl ;������� �����
	call HexSymbol_MY
	mov byte ptr[ebx+1], al
	mov eax, ecx
	cmp eax, 4
	jle @next
	dec eax
	and eax, 3 ;������� ������� ����� �� ��� ����
	cmp al, 0
	jne @next
	mov byte ptr[ebx+2], 32 ;��� ������� �������
	inc ebx
@next:
	add ebx, 2
	dec ecx
	jnz @cycle
	mov byte ptr[ebx], 0 ;����� ���������� �����
@exitp:
	pop ebp
	ret 12

StrHex_MY endp

;�� ��������� �������� ��� hex-�����
;�������� - �������� AL
;��������� -> AL
HexSymbol_MY proc
	and al, 0Fh
	add al, 48 ;��� ����� ����� ��� ���� 0-9
	cmp al, 58
	jl @exitp
	add al, 7 ;��� ���� A,B,C,D,E,F
@exitp:
	ret
HexSymbol_MY endp


;�� ��������� ������ 8 ������� HEX ���� �����
;������ �������� - 32-����� �����
;������ �������� - ������ ������ ������
DwordToStrHex proc
push ebp
mov ebp,esp
mov ebx,[ebp+8] ;������ ��������
mov edx,[ebp+12] ;������ ��������
xor eax,eax
mov edi,7
@next:
mov al,dl
and al,0Fh ;�������� ���� �������������� �����
add ax,48 ;��� ����� ����� ��� ���� 0-9
cmp ax,58
jl @store
add ax,7 ;��� ���� A,B,C,D,E,F
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
	mov ecx,[ebp+8] ; ������������ ���������
	mov esi,[ebp+16] ;ESI = ������ B
	mov ebp,[ebp+12] ;EBP = A

	xor ebx,ebx		; ��������� ebx
	xor edi, edi	; ��������� edi. ����
	cycle:
		mov eax,ebp			;EAX = A
		mul dword ptr[esi+4*edi]
		clc					; ������������ �������� � ����
		adc eax,ebx
		adc edx,0
		mov dword ptr[esi+4*edi],eax
		mov ebx,edx

		inc edi				; ��������� ����� �� 1
		dec ecx				; �������� �������� �� 1
		jnz cycle	; ���� �������� �� 0, �� ������� �� ���� cycle_Mul_Nx32
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
	cycle_out:			; ������� ���������� �����1
		mov eax,counter			
		inc eax					; �������� �������� �� �������
		cmp eax,myLength
		jg exit					; ����� � �����
		mov counter,eax

		mov ecx,myLength			; ������������ ��������� ����������� �����

		mov ebx,dword ptr[esi+4*eax-4]	; �������� � ���'��� ������� �ix32
		mov ValueAi,ebx

		xor ebx,ebx				; ��������� ebx		
		cycle_in:
			mov eax,ValueAi
			mul dword ptr[edi+4*ebx]
			
			; ������������ �������� � ����
			add dword ptr[ebp+4*ebx],eax
			adc dword ptr[ebp+4*ebx+4],edx
			
			jnc not_res_cor
				mov eax,1
				add eax,ebx
				stc ; ������������ �������� � �������
				res_cor2:
					inc eax
					adc dword ptr[ebp+4*eax],0
					jl res_cor2
			not_res_cor:

			inc ebx					; ��������� ����� �� 1
			dec ecx					; �������� �������� �� 1
			jnz cycle_in	; ���� �������� �� 0, �� ������� �� ���� cycle_Mul_NxN
		
		add ebp,4					; ��������� ������ ���������� ����� �� 1
		jmp cycle_out

		exit:
	pop ebp
	ret 16
Mul_NxN_LONGOP endp
Add_224_LONGOP proc

   push ebp 
   mov ebp,esp 
   
   mov esi, [ebp+16]           ;ESI = ������ A 
   mov ebx, [ebp+12]           ;EBX = ������ B 
   mov edi, [ebp+8]            ;EDI = ������ ����������  

   mov ecx, 7   ; ECX = ������� ������� ��������� 
   mov edx,0

   clc            ; ������� �� CF ������� EFLAGS 

   cycle: 
   mov eax, dword ptr[esi+4*edx]  
   adc eax, dword ptr[ebx+4*edx]     ; ��������� ����� � 32 ��� 
   mov dword ptr[edi+4*edx], eax   

   inc edx
   dec ecx        ; �������� �������� �� 1 
   jnz cycle 
   pop ebp
   ret 12
Add_224_LONGOP endp
Sub_896_LONGOP proc
   push ebp 
   mov ebp,esp 
 
   mov esi, [ebp+16]           ;ESI = ������ A 
   mov ebx, [ebp+12]           ;EBX = ������ B 
   mov edi, [ebp+8]            ;EDI = ������ ����������  
   mov ecx, 7   ; ECX = ������� ������� ��������� 
   mov edx,0
   clc            ; ������� �� CF ������� EFLAGS 
   cycle: 
   mov eax, dword ptr[esi+4*edx]  
   sbb eax, dword ptr[ebx+4*edx]     ; �������� ����� � 32 ��� 
   mov dword ptr[edi+4*edx], eax   
   inc edx
   dec ecx        ; �������� �������� �� 1 
   jnz cycle 
   pop ebp
   ret 12
Sub_896_LONGOP endp



main:
	; ====================   N! 
	cycleFact:
		push offset valueA		; �������� � ���� ������ ������� ��������
		push factMultiplier	    ; �������� ������� ��������
		push 6					; ����� � ���� ������� 32-����� ����� � ����
		call Mul_Nx32_LONGOP	; ������ ������� �������� Nx32
		inc factMultiplier		; ��������� ����� �� 1 
		dec factCounter		    ; �������� �������� �� 1
	jnz cycleFact

	push offset TextBuf			; �������� � ���� ������ ����������
	push offset valueA			; �������� � ���� ������ ��������
	push 192				; ����� � ���� ������� �� � ����
	call StrHex_MY				; ������ ������� ���������� 16-�� �����
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption1, 0

	
	
	; ====================   N! * N!
	push offset faxtXfact		; �������� � ���� ������ ����������
	push offset valueA			; �������� � ���� ������ ������� ��������
	push offset valueA			; �������� � ���� ������ ������� ��������
	push 6				     	; ����� � ���� ������� 32-����� ����� � ����
	call Mul_NxN_LONGOP

	push offset TextBuf			; �������� � ���� ������ ����������
	push offset faxtXfact		; �������� � ���� ������ ��������
	push 384					; ����� � ���� ������� �� � ����
	call StrHex_MY				; ������ ������� ���������� 16-�� �����
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption2, 0

;**************************************************************************************



	; ====================   N * N  111..1*111..1
	push offset test1Res		; �������� � ���� ������ ����������
	push offset val11		    ; �������� � ���� ������ ������� ��������
	push offset val11		    ; �������� � ���� ������ ������� ��������
	push 6						; ����� � ���� ������� 32-����� ����� � ����
	call Mul_NxN_LONGOP

	push offset TextBuf			; �������� � ���� ������ ����������
	push offset test1Res		; �������� � ���� ������ ��������
	push 384					; ����� � ���� ������� �� � ����
	call StrHex_MY				; ������ ������� ���������� 16-�� �����
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption3, 0

	
	; ====================   N * 32  111..1*111..1
	push offset val11x32	    ; �������� � ���� ������ ������� ��������
	push 0FFFFFFFFh				; �������� ������� ��������
	push 12						; ����� � ���� ������� 32-����� ����� � ����
	call Mul_Nx32_LONGOP		; ������ ������� �������� Nx32

	push offset TextBuf			; �������� � ���� ������ ����������
	push offset val11x32	    ; �������� � ���� ������ ��������
	push 384					; ����� � ���� ������� �� � ����
	call StrHex_MY				; ������ ������� ���������� 16-�� �����
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption4, 0
	
	; ====================   N * N  111..1*110..0
	push offset test2Res		; �������� � ���� ������ ����������
	push offset val11	    	; �������� � ���� ������ ������� ��������
	push offset val110	    	; �������� � ���� ������ ������� ��������
	push 6						; ����� � ���� ������� 32-����� ����� � ����
	call Mul_NxN_LONGOP

	push offset TextBuf			; �������� � ���� ������ ����������
	push offset test2Res		; �������� � ���� ������ ��������
	push 384					; ����� � ���� ������� �� � ����
	call StrHex_MY				; ������ ������� ���������� 16-�� �����
	invoke MessageBoxA, 0, ADDR TextBuf, ADDR Caption5, 0
	invoke ExitProcess, 0
end main
