; Program for playing on PC-Speaker.
; For GNU/Linux 64 bit version. Root priveleges or kernel patch needed.
; Version: 4.
; Written on FreePascal (https://freepascal.org/).
; Copyright (C) 2021-2023  Artyomov Alexander
; http://self-made-free.ru/ (Ex http://aralni.narod.ru/)
; aralni@mail.ru

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU Affero General Public License as
; published by the Free Software Foundation, either version 3 of the
; License, or (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU Affero General Public License for more details.

; You should have received a copy of the GNU Affero General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

; for 64-bit systems, Linux syscalls
; nasm -fELF64 spkplay.asm 
; &&
; ld spkplay.o  -o spkplay

sys_write	equ	1		; the linux WRITE syscall
sys_lseek equ 8
SEEK_END equ 2
sys_exit	equ	60		; the linux EXIT syscall
sys_stdout	equ	1		; the file descriptor for standard output (to print/write to)
section .data
	linebreak	db	0x0A	; ASCII character 10, a line break

fp dq 0 ; file handler
filesize dq 0 ; file size

section .text
global _start
_start:
call writehelp
call startspk
call startsignal

	pop	r8			; pop the number of arguments from the stack
	cmp r8, 1
	jne arg
	call gspkon
	mov bx,1000
	call gspk
	mov ax, 1000
	call sle
	call gspkoff
	jmp exit
	arg:
	pop	rsi			; discard the program name, since we only want the commandline arguments
	dec r8

loop:
					; loop condition
	cmp	r8,	0		; check if we have to print more arguments
	jz	exit			; if not, jump to the 'end' label

					; print the argument
	mov	rax,	sys_write	; set the rax register to the syscall number we want to execute (WRITE)
	mov	rdi,	sys_stdout	; specify the file we want to write to (standard output in this case)
	pop	rsi			; pop a pointer to the string we want to print from the stack
	call getlength
	syscall				; execute the system call

push rax
push rdi
push r8
push rsi
push rdx
	call gspkon;
call playfile
	call gspkoff;
mov ax, 500
call sle
pop rdx
pop rsi
pop r8
pop rdi
pop rax
					; print a newline
	mov	rax,	sys_write	; rax is overwritten by the kernel with the syscall return code, so we set it again
	mov	rdi,	sys_stdout
	mov	rsi,	linebreak	; this time we want to print a line break
	mov	rdx,	1		; which is one byte long
	syscall
	
	dec	r8			; count down every time we print an argument until there are none left
	jmp	loop			; jump back to the top of the loop

					; the program is finished, now exit cleanly by calling the EXIT syscall


jmp exit
%include "spklib.inc"

getlength:
xor rdx,rdx
 glloop:
cmp byte [rsi+rdx],0
je glexit
inc rdx
jmp glloop
glexit:
ret

playfile:
	mov rdi, rsi ; patchname
	; открыть файл
	mov rsi,0; открываем для чтения
	mov rax,2; номер системного вызова
	syscall; вызов функции "открыть файл"
	cmp rax, 0; нет ли ошибки при открытии
	jl  open_error; перейти к концу программы.
	mov rbx, rax; запомнить дескриптор файла
	; получить длину файла
	mov rdi,rax; дескриптор файла
	mov rsi,0; от начала файла
	mov rdx,2; SEEK_END
	mov rax,8; номер системной функции
	syscall; вызов функции получить длину
	cmp rax,0; нет ли ошибки при открытии
	jl  len_error          ; перейти к концу программы.
	mov r15,rax; запомнить длину файла
	call check
	; отобразить файл 
	mov rdi,0; с начала
	mov rsi,rax; длина файла
		;PROT_READ	1	Read access is allowed.
		;PROT_WRITE	2	Write access is allowed. Note that this value assumes PROT_READ also.
		;PROT_NONE	8	No data access is allowed.
		;PROT_EXEC	4	This value is allowed, but is equivalent to PROT_READ.
		;MAP_SHARED	4	Changes are shared.
		;MAP_PRIVATE	2	Changes are private.
		;MAP_FIXED	1	Parameter addr has exact address
	mov rdx,1; PROT_
	mov r10,1; MAP_
	mov r8,rbx; дескриптор файла
	mov r9,0; с начала файла
	mov rax,9; номер системного вызова
	syscall; вызов функции отобразить файл
	cmp rax,0; нет ли ошибки 
	jl  map_error          ; перейти к концу программы.
	mov r13,rax; запомнить адрес начала отображенного файла
	; закрыть файл
	mov rdi,rbx; дескриптор файла
	mov rax,3; номер системного вызова
	syscall         ; вызов функции "закрыть файл"
	cmp rax,0; нет ли ошибки при открытии
	jl  map_error          ; перейти к концу программы.
	; воспроизвести отображаемый файл
	mov rbx,r13; адрес начала области
	mov rdx,r15; обрабатываемая длина
 fileloop:
	push rdx
	mov dword eax,[rbx]
	push rbx
	mov bx, ax
	call play
	pop rbx
	pop rdx
	add rbx, 4;	к следующему двойному слову
	sub rdx, 4;	уменьшим счетчик
	jnz  fileloop;	если не 0 - продолжим 
	; закрыть отображение
	mov rdi,r13; адрес отображенного файла
	mov rsi,r15; длина отображенной части файла
	mov rax, 11; номер системного вызова
	syscall
	cmp rax,0; нет ли ошибки 
	jl  error          ; перейти к концу программы.
ret

play:
	cmp bx, 0
	jz noon
	call gspk
	jmp sl
 noon:
	call gspkoff
	call sl
	call gspkon
	ret
 sl:
	shr eax, 16
	and rax, 1111111111111111b
	cmp ax, 0
	jz playret
 sle:

; Signed divide RDX:RAX by r/m64, with result stored in RAX ← Quotient, RDX ← Remainder.

	mov rdx, 0;  RDX:RAX делимое в rax
	mov rcx, 1000; делитель
	div rcx; целое в RAX, остаток в RDX
	mov r11, rax

	mov rax, rdx
	mov rbx, 1000000
	mov cl, 0
	mul rbx
	; put a time structure on the stack
	push rax ; nanoseconds
	push r11; seconds

	mov rax, 35 ; sys_nanosleep
	mov rdi, rsp ;point to our time structure (requested)
	mov rsi, rsp ;  (remaining)
	syscall
	add rsp, 16 ; "free" our time structure
 playret:
ret

check:
push rax
push rdx
push rcx
xor rdx, rdx
mov rcx, 4
div rcx
cmp rdx,0
jne consistent_error
pop rcx
pop rdx
pop rax
ret