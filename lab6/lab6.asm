.586
.model flat, stdcall, c
option casemap :none

include C:\masm32\include\windows.inc

include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc

includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\user32.lib


.data
      cote dd ?

      N0 db 108 dup(0FFh) 
	n dd 64 
	m0 db 22 dup(000h) 
	m dd 176 

	GreetingCap db "Лаб. робота №6", 0
	GreetingText db "Побітові операції", 13, 10,
					"вик. Ололош Піу Кекович ", 13, 10,
					"гр. <None>", 0
	TextBuf0 db 256 dup(?) 
	TextBuf1 db 256 dup(?) 
	Caption0 db "Вхідний рядок", 0 
	Caption1 db "Вихідний рядок", 0


.code
StrHex_MY proc
	push ebp
	mov ebp, esp
	mov ecx, [ebp+8]
	cmp ecx, 0
	jle @exitp
	shr ecx, 3
	mov esi, [ebp+12]
	mov ebx, [ebp+16]
@cycle:
	mov dl, byte ptr[esi+ecx-1]
	
	mov al, dl
	shr al, 4
	call HexSymbol_MY
	mov byte ptr[ebx], al
	
	mov al, dl
	call HexSymbol_MY
	mov byte ptr[ebx+1], al
	
	mov eax, ecx
	cmp eax, 4
	jle @next
	dec eax
	and eax, 3
	cmp al, 0
	jne @next
	mov byte ptr[ebx+2], 32
	inc ebx
	
	@next:
		add ebx, 2
		dec ecx
		jnz @cycle
		mov byte ptr[ebx], 0
	@exitp:
		pop ebp
		ret 12
	StrHex_MY endp

	HexSymbol_MY proc
		and al, 0Fh
		add al, 48
		cmp al, 58
		jl @exitp
		add al, 7
	@exitp:
		ret
HexSymbol_MY endp



AND_LONGOP proc 
	push ebp 
	mov ebp, esp 

	mov edi, [ebp + 20]		; Адреса вихідного числа
	mov esi, [ebp + 16]		; Адреса маски 
	mov edx, [ebp + 12]		; Номер початкового біта 
	mov ecx, [ebp + 8]		; Розрядність маски 

	shr ecx, 4
	shr edx, 4 

	@loop: 
		add edx, ecx 
		mov al, byte ptr [edi + edx - 1] 
		and al, byte ptr [esi + ecx - 1] 
		mov byte ptr [edi + edx - 1], al 
		sub edx, ecx 
		dec ecx 
		jnz @loop 

	pop ebp 
	ret
AND_LONGOP endp





main: 

push offset TextBuf0
	
	invoke MessageBox, 0, ADDR GreetingText, ADDR GreetingCap, 0 

    push offset N0
    push 864
    call StrHex_MY

    invoke MessageBox, 0, ADDR TextBuf0, ADDR Caption0, 0 

	push offset N0 
	push offset m0 
	push n 
	push m 
	call AND_LONGOP 


	push offset TextBuf1
    push offset N0
    push 864
    call StrHex_MY

    invoke MessageBox, 0, ADDR TextBuf1, ADDR Caption1, 0
    invoke ExitProcess, 0

end main