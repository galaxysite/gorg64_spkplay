; Program for playing tones on PC-Speaker output.
; For GNU/Linux 64 bit version. Root priveleges or kernel patch needed.
; Version: 3.
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

section .text

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

consistent_error:
	mov	rax,	1
	mov	rdi,	1
	mov	rsi, consistenterrmsg
	mov	rdx,	consistenterrmsg_len
	syscall
	call gspkoff
jmp exit;

section .data

spkpatch: dq 0
retval1: dq 0
retval2: dq 0

file_descriptor: dq 0
file_size: dq 0
file_address : dq 0

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
helpmsg: db 'GALAXY ORGANIZER SPEAKER PLAYER Version 4',10,'Artyomov Alexander 2022-2023  License: GNU AGPLv3 and above',10,'Use: gorg64_spkplay or gorg64_spkplay somemusic.speaker somemusic2.speaker ...',10,0
helpmsg_len equ $ - helpmsg

section .text

ioperm:
  push rax
  push rdi
  push rsi
  push  rdx
  mov  rax, 173
  mov  rdi, $42
  mov  rsi, 2
  mov  rdx, 1
  syscall
  mov [retval1], rax
  mov  rax, 173
  mov  rdi, $61
  mov  rsi, 1
  mov  rdx, 1
  syscall
  mov [retval2], rax
  pop rdx
  pop rsi
  pop rdi
  pop rax
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
kspkon:
;push rax
	mov rax, 1000
	syscall
;pop rax
ret
kspkoff:
;push rax
	mov rax, 1001
	syscall
;pop rax
ret
kspk:
push rax
;push rdi
;push rbx
	mov rax, 1002
	mov rdi, rbx
	syscall
;pop rbx
;pop rdi
pop rax
ret
kspkpatchexists:
	mov rax, 1003
	syscall
	cmp qword rax, 123
	jne kspkpatchexistsexit
	mov qword [spkpatch], 1
 kspkpatchexistsexit:
ret
gspkon:
	cmp qword [spkpatch], 1
	je gspkonex
	call spkon
 ret
 gspkonex:
	call kspkon
ret
gspkoff:
	cmp qword [spkpatch], 1
	je gspkoffex
	call spkoff
 ret
 gspkoffex:
	call kspkoff
ret
gspk:
	cmp qword [spkpatch], 1
	je gspkex
	call spk
 ret
 gspkex:
	call kspk
ret
startspk:
	call ioperm
	cmp qword [retval1],0
	jne patch_ex
	cmp qword [retval2],0
	jne patch_ex
 ret
 patch_ex:
	call kspkpatchexists
	cmp qword  [spkpatch], 1
	jne exit
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
call gspkoff;
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, signalmsg
	mov	rdx, signalmsg_len
	syscall
jmp exit
