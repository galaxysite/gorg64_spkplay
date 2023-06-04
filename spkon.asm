; Program for turn on PC-Speaker output.
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

global _start
_start:
call startspk
call gspkon
exit:
mov	rax,	60	; load the EXIT syscall number into rax
syscall				; execute the system call

ioperm:
	mov  rax, 173
	mov  rdi, $42
	mov  rsi, 2
	mov  rdx, 1
	syscall
	mov r10, rax
	mov  rax, 173
	mov  rdi, $61
	mov  rsi, 1
	mov  rdx, 1
	syscall
	mov r11, rax
ret
spkon:
        in      al, 61h
        or      al, 03h
        out     61h, al
ret
kspkon:
	mov rax, 1000
	syscall
ret
gspkon:
	cmp r12, 1
	je gspkonex
	call spkon
 ret
 gspkonex:
	call kspkon
ret
kspkpatchexists:
	xor r12,r12
	mov rax, 1003
	syscall
	cmp qword rax, 123
	jne kspkpatchexistsexit
	mov r12, 1
 kspkpatchexistsexit:
ret
startspk:
	call ioperm
	cmp r10,0
	jne patch_ex
	cmp r11,0
	jne patch_ex
 ret
 patch_ex:
	call kspkpatchexists
	cmp r12, 1
	jne exit
ret