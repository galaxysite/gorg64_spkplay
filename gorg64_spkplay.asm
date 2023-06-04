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
	call spkon
	mov bx,1000
	call spk
	mov ax, 1000
	call sle
	call spkoff
	jmp exit
	arg:
	pop	rsi			; discard the program name, since we only want the commandline arguments
	dec r8

loop:
					; loop condition
	cmp	r8,	0		; check if we have more arguments
	jz	exit			; if not, exit

					; display the argument
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
call playfile
	call spkoff;
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


exit:
mov	rax,	60	; load the EXIT syscall number into rax
xor	rdi,	rdi		; the program return code
;mov di, 10
syscall				; execute the system call

%define SIGINT          2 ;Interrupt (ANSI)
%define SIGTERM         15; Default kill signal
%define SA_RESTORER     0x04000000 ;Required for x86_64 sigaction
%define SYS_RT_SIGACTION    13 ;int sig,const struct sigaction __user * act,

writehelp:
	mov	rax,	sys_write	; rax is overwritten by the kernel with the syscall return code, so we set it again
	mov	rdi,	sys_stdout
	mov	rsi,	helpmsg	; this time we want to print a line break
	mov	rdx,	helpmsg_len		; which is one byte long
	syscall
ret

error:
	mov	rax,	1	; WRITE
	mov	rdi,	1	; standard output
	mov	rsi, errmsg			; pointer to the string
	mov	rdx,	errmsg_len		; specify the length of the string
	syscall				; execute the system call
jmp exit;

open_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, openerrmsg			
	mov	rdx,	openerrmsg_len		
	syscall
jmp exit;

len_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, lenerrmsg
	mov	rdx,	lenerrmsg_len
	syscall
jmp exit;

map_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, maperrmsg
	mov	rdx,	maperrmsg_len
	syscall
jmp exit;

ports_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, portsmsg
	mov	rdx,	portsmsg_len
	syscall
jmp exit;

consistent_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, consistenterrmsg
	mov	rdx,	consistenterrmsg_len
	syscall
	call spkoff
jmp exit;

section .data

sigaction:
    sa_handler  dq handler
    sa_flags    dq SA_RESTORER
    sa_restorer dq 0;
    sa_mask     dq 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

errmsg: db 10,'>>> Error',10,0
errmsg_len equ $ - errmsg
lenerrmsg: db 10,'>>> [><] GET FILE LENGTH Error',10,0
lenerrmsg_len equ $ - lenerrmsg
openerrmsg: db 10,'>>> [*] FILE OPEN Error',10,0
openerrmsg_len equ $ - openerrmsg
maperrmsg: db 10,'>>> [*] FILE MAP Error',10,0
maperrmsg_len equ $ - maperrmsg
consistenterrmsg: db 10,'>>> [*] FILE Consistent Error',10,0
consistenterrmsg_len equ $ - consistenterrmsg
signalmsg: db 10,'--==[[   Breaked by SIGNAL  ]]==--',10,0
signalmsg_len equ $ - signalmsg
portsmsg: db 10,'Error get ports access. h42-43, h61. Need root access.',10,0
portsmsg_len equ $ - portsmsg
helpmsg: db 'GALAXY ORGANIZER SPEAKER PLAYER Version 4',10,'Artyomov Alexander 2022-2023  License: GNU AGPLv3 and above',10,'Use: gorg64_spkplay or gorg64_spkplay somemusic.speaker somemusic2.speaker ...',10,0
helpmsg_len equ $ - helpmsg

section .text

startspk:
  mov  rax, 173
  mov  rdi, $42
  mov  rsi, 2
  mov  rdx, 1
  syscall
	cmp rax,0
	jne ports_error
  mov  rax, 173
  mov  rdi, $61
  mov  rsi, 1
  mov  rdx, 1
  syscall
	cmp rax,0
	jne ports_error
ret

spkon:
push rax
        in      al, 61h
        or      al, 03h
        out     61h, al
pop rax
ret
spkoff:
push rax
        in      al, 61h
        or      al, 03h
        xor     al, 03h
        out     61h, al
pop rax
ret
spk:
push rax
;push rbx
        mov     al, 0B6h
        out     43h, al
        mov     al, bl
        out     42h, al
	shr rbx, 8
        mov     al, bl
        out     42h, al
;pop rbx
pop rax
ret

startsignal:
    mov r10, 8 ; sizeof(sigset_t)
    xor rdx, rdx
    mov rsi, sigaction
    mov rdi, SIGINT
    mov rax, SYS_RT_SIGACTION
    syscall
    mov rdi, SIGTERM
    mov rax, SYS_RT_SIGACTION
    syscall
ret

handler:
call spkoff;
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, signalmsg
	mov	rdx, signalmsg_len
	syscall
jmp exit


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

mov rbx,[r13]
call spk

	; воспроизвести отображаемый файл
	mov rbx,r13; адрес начала области
	mov rdx,r15; обрабатываемая длина
	call spkon;
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
	call spk
	jmp sl
 noon:
	call spkoff
	call sl
	call spkon
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