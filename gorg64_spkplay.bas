''	Program for playing melodys on PC-Speaker.
''	For GNU/Linux 64 bit version. Root priveleges needed.
''	Version: 1.
''	Written on FreeBasic (https://www.freebasic.net/).
''	Copyright (C) 2024 Artyomov Alexander
''	http://self-made-free.ru/
''	aralni@mail.ru

''	This program is free software: you can redistribute it and/or modify
''	it under the terms of the GNU Affero General Public License as
''	published by the Free Software Foundation, either version 3 of the
''	License, or (at your option) any later version.

''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU Affero General Public License for more details.

''	You should have received a copy of the GNU Affero General Public License
''	along with this program.  If not, see <https://www.gnu.org/licenses/>.

#define	SIGINT		2	'' Interactive attention
#define	SIGILL		4	'' Illegal instruction
#define	SIGFPE		8	'' Floating point error
#define	SIGSEGV		11	'' Segmentation violation
#define	SIGTERM		15	'' Termination request
#define SIGBREAK	21	'' Control-break
#define	SIGABRT		22	'' Abnormal termination (abort)

extern "C"
	type __p_sig_fn_t as sub(byval as integer)
	declare function signal(byval as integer, byval as __p_sig_fn_t) as __p_sig_fn_t
end extern

Type TTW
	tone As Unsigned Short
	duration As Unsigned Short
End Type

Sub SpkOn
	Out &h61,Inp(&h61) Or 3
End Sub

Sub SpkOff
	Out &h61,Inp(&h61) And &hfc
End Sub

Sub Spk(ByVal t As Unsigned Short)
	Out &h43,&hb6
	Out &h42,LoByte(t)
	Out &h42,HiByte(t)
End Sub

function SpkF(ByVal f As UInteger) as Unsigned Short
	return 1193181 \ f
end function

private sub handler cdecl(byval sig as integer)
Print("Signal:")
Print(sig)
SpkOff
End
end sub

signal(SIGABRT, @handler)
signal(SIGSEGV, @handler)
signal(SIGFPE, @handler)
signal(SIGILL, @handler)
signal(SIGTERM, @handler)
signal(SIGINT, @handler)

Print("GALAXY ORGANIZER SPEAKER PLAYER (BASIC) Version 1")
Print("Artyomov Alexander 2024  License: GNU AGPLv3 and above")
Print("Use: gorg64_spkplay or gorg64_spkplay somemusic.speaker somemusic2.speaker ...")

Dim r as TTW
Dim i as Integer
Dim l as Integer
Dim f as Integer
i = 1
while( command(i) > "" )
Print("Playing: " + command(i))
Open command(i) For Binary As #1
l = LOF(1)/4
SpkOn
for f = 1 to l
  Get #1, , r
 if (r.duration < 1) then
  Continue For
 endif
 if r.tone < 1 then
   spkoff
   sleep(r.duration)
   spkon
 else
   spk(r.tone)
   sleep(r.duration)
 endif
Next
SpkOff
Close #1
i += 1
wend
if i = 1 then
Print("No files given")
Spk(300)
SpkOn
Sleep(1000)
SpkOff
endif