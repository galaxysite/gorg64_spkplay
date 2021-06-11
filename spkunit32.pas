unit spkunit32;

{$MODE OBJFPC}
{$ASMMODE INTEL}
{$CODEPAGE UTF8}
{$LONGSTRINGS ON}
{$RANGECHECKS ON}
{$SMARTLINK ON}
{$INLINE ON}

{
    Unit for playing melodys on PC-Speaker.
    For GNU/Linux 64 bit version. Root priveleges needed.
    Version: 3.
    Written on FreePascal (https://freepascal.org/).
    Copyright (C) 2000-2021  Artyomov Alexander
    http://self-made-free.ru/ (Ex http://aralni.narod.ru/)
    aralni@mail.ru

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
}

interface

uses X86;

procedure spk(b : word); procedure spkon; procedure spkoff;
function spkf(tone : Word) : Word; inline;

implementation

procedure spkon; assembler;
asm
        push    eax
        in      al, 61h
        or      al, 03h
        out     61h, al
        pop     eax
end;
procedure spkoff; assembler;
asm
        push    eax
        in      al, 61h
        or      al, 03h
        xor     al, 03h
        out     61h, al
        pop     eax
end;
procedure spk(b : word);
var hb, lb : byte;
begin
hb := hi(b); lb := lo(b);
 asm
        push    eax
        mov     al, 0B6h
        out     43h, al
        mov     al, lb
        out     42h, al
        mov     al, hb
        out     42h, al
        pop     eax
 end;
end;

// Установить частоту воспроизведения. Частота 1193280 div tone.
function spkf(tone : Word) : Word;
var
  tmp : LongInt;
begin
if tone < 1 then Exit(0);
tmp := 1193280 div tone;
if tmp > $FFFF then tmp := $FFFF;
Exit(tmp);
end;

initialization

fpioperm($42, 2, 1);
fpioperm($61, 1, 1);

end.
