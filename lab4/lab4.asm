.586
.model flat, stdcall, c
option casemap :none
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\windows.inc
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\user32.lib
.const
.data

.data
Caption1 db "A+B 1",0
Caption3 db "A+B 2",0
Caption2 db "A-B",0

TextBuf1 db 640 dup(?)
TextBuf3 db 640 dup(?)
TextBuf2 db 480 dup(?)

ValueA1 db 640 dup(?) 
ValueB1 db 640 dup(?) 
ValueA3 db 640 dup(?) 
ValueB3 db 640 dup(?)
ValueA2 db 480 dup(?) 
ValueB2 db 480 dup(?) 

Result1 db 640 dup(0)
Result3 db 640 dup(0)
Result2 db 480 dup(0)

.code
StrHex_MY proc
	push ebp
	mov ebp,esp
	mov ecx, [ebp+8] ;к≥льк≥сть б≥т≥в числа
	cmp ecx, 0
	jle @exitp
	shr ecx, 3 ;к≥льк≥сть байт≥в числа
	mov esi, [ebp+12] ;адреса числа
	mov ebx, [ebp+16] ;адреса буфера результату
@cycle:
	mov dl, byte ptr[esi+ecx-1] ;байт числа - це дв≥ hex-цифри
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
	and eax, 3 ;пром≥жок розд≥люЇ групи по в≥с≥м цифр
	cmp al, 0
	jne @next
	mov byte ptr[ebx+2], 32 ;код символа пром≥жку
	inc ebx
@next:
	add ebx, 2
	dec ecx
	jnz @cycle
	mov byte ptr[ebx], 0 ;р€док зак≥нчуЇтьс€ нулем
@exitp:
	pop ebp
	ret 12

StrHex_MY endp

;ц€ процедура обчислюЇ код hex-цифри
;параметр - значенн€ AL
;результат -> AL
HexSymbol_MY proc
	and al, 0Fh
	add al, 48 ;так можна т≥льки дл€ цифр 0-9
	cmp al, 58
	jl @exitp
	add al, 7 ;дл€ цифр A,B,C,D,E,F
@exitp:
	ret
HexSymbol_MY endp


;ц€ процедура записуЇ 8 символ≥в HEX коду числа
;перший параметр - 32-б≥тове число
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
and al,0Fh ;вид≥л€Їмо одну ш≥стнадц€ткову цифру
add ax,48 ;так можна т≥льки дл€ цифр 0-9
cmp ax,58
jl @store
add ax,7 ;дл€ цифр A,B,C,D,E,F
@store:
mov [ebx+edi],al
shr edx,4
dec edi
cmp edi,0
jge @next
pop ebp
ret 8
DwordToStrHex endp

Add_512_LONGOP proc
    push ebp
	mov ebp,esp

	mov esi, [ebp+16] ; ESI = адреса A
	mov ebx, [ebp+12] ; EBX = адреса B
	mov edi, [ebp+8] ; EDI = адреса результату

	mov ecx, 16 ; ECX = потр≥бна к≥льк≥сть повторень
	mov edx, 0
	clc ; обнулюЇ б≥т CF рег≥стру EFLAGS
	cycle:
	mov eax, dword ptr[esi+4*edx]
	adc eax, dword ptr[ebx+4*edx] ; додаванн€ групи з 32 б≥т≥в
	mov dword ptr[edi+4*edx], eax

	inc edx
	dec ecx ; л≥чильник зменшуЇмо на 1
	jnz cycle
	pop ebp
	ret 12
Add_512_LONGOP endp

Sub_608_LONGOP proc
    push ebp
	mov ebp,esp

	mov esi, [ebp+16] ; ESI = адреса A
	mov ebx, [ebp+12] ; EBX = адреса B
	mov edi, [ebp+8] ; EDI = адреса результату

	mov ecx, 19 ; ECX = потр≥бна к≥льк≥сть повторень
	mov edx, 0
	clc ; обнул€Ї б≥т CF рег≥стру EFLAGS
	cycle:
	mov eax, dword ptr[esi+4*edx]
	sbb eax, dword ptr[ebx+4*edx] ; в≥дн≥манн€ групи з 32 б≥т≥в
	mov dword ptr[edi+4*edx], eax

	inc edx
	dec ecx ; л≥чильник зменшуЇмо на 1
	jnz cycle
	pop ebp
	ret 12
Sub_608_LONGOP endp
 

main:

;A+B 1
mov eax, 80010001h
mov ecx, 16   ; ECX = потр≥бна к≥льк≥сть повторень
mov edx, 0
cycleAB1:	
mov DWord ptr[ValueA1+4*edx], eax
mov DWord ptr[ValueB1+4*edx], 80000001h
add eax, 10000h
inc edx
dec ecx        ; зменшуЇмо л≥чильник на 1 
jnz cycleAB1

push offset ValueA1
push offset ValueB1
push offset Result1
call Add_512_LONGOP
push offset TextBuf1 
push offset Result1
push 512
call StrHex_MY 
invoke MessageBoxA, 0, ADDR TextBuf1, ADDR Caption1,0

;A+B 2
mov eax, 14h
mov ecx, 16   ; ECX = потр≥бна к≥льк≥сть повторень
mov edx,0
cycleAB3:	
mov DWord ptr[ValueA3+4*edx], eax
mov DWord ptr[ValueB3+4*edx], 00000001h
add eax, 1h
inc edx
dec ecx        ; зменшуЇмо л≥чильник на 1 
jnz cycleAB3

push offset ValueA3
push offset ValueB3
push offset Result3
call Add_512_LONGOP
push offset TextBuf3
push offset Result3
push 512
call StrHex_MY 
invoke MessageBoxA, 0, ADDR TextBuf3, ADDR Caption3,0

;A-B 
mov eax, 14h  
mov ecx, 19   ; ECX = потр≥бна к≥льк≥сть повторень
mov edx,0
cycleAB2:	
mov DWord ptr[ValueA2+4*edx], 0
mov DWord ptr[ValueB2+4*edx], eax
add eax, 1h
inc edx
dec ecx        ; зменшуЇмо л≥чильник на 1  
jnz cycleAB2

push offset ValueA2
push offset ValueB2
push offset Result2
call Sub_608_LONGOP
push offset TextBuf2 
push offset Result2
push 608
call StrHex_MY 
invoke MessageBoxA, 0, ADDR TextBuf2, ADDR Caption2,0


invoke ExitProcess, 0
end main
