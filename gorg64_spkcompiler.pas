program gorg64_spkcompiler;

{$MODE OBJFPC}
{$RANGECHECKS ON}
{$LONGSTRINGS ON}
{$SMARTLINK ON}
{$ASMMODE INTEL}

{
    Program for converting notes to melodys for PC-Speaker.
    For GNU/Linux 64 bit version.
    Version: 1.
    Written on FreePascal (https://freepascal.org/).
    Copyright (C) 2021,2022  Artyomov Alexander
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

uses sysutils,notesarr;

{$H+}

type
      TTW = packed record
       tone, duration : Word;
      end;
      PTW=^TTW;

var
    a :  array of TTW;

function LoadFromFile(fn : utf8string) : boolean;
var fp : text;
       s : utf8string;
       d : boolean = false;
       f : Int64;
tmp : ttw;
begin
assign(fp, fn);
filemode := 0;
{$I-}
ReSet(fp);
{$I+} if IOResult <> 0 then Exit(true);
while not eof(fp) do begin
{$I-}
ReadLn(fp, s);
{$I+} if IOResult <> 0 then Exit(true);
if s[1] = '/' then continue;
IF d THEN BEGIN // duration
tmp.duration := StrToIntDef(s, $FFFF);
if tmp.duration = $FFFF then begin writeln('Error duration value: ', s); Halt(1); end;
SetLength(a, Length(a)+1);
a[High(a)] := tmp;
d := false;
continue;
END ELSE BEGIN // tone
tmp.tone := $FFFF;
for f := 0 to MAX_NOTES do begin
if notes_names[f] = s then begin
tmp.tone := notes_values[f];
d := true;
break;
end;
end;
if tmp.tone = $FFFF then begin writeln('Error note name value: ', s); Halt(1); end;
END;
end;
{$I-}
Close(fp);
{$I+} if IOResult <> 0 then Exit(true);
Exit(false);
end;

function SaveToFile(fn : utf8string) : boolean;
var
  fp : File of TTW;
begin
Assign(fp, fn);
FileMode := 1;
{$I-}
ReWrite(fp);
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
BlockWrite(fp, a[0], Length(a));
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
Close(fp);
{$I+} if IOResult <> 0 then Exit(true);
Exit(false);
end;

begin
WriteLn('GALAXY ORGANIZER SPEAKER COMPILER Version 1');
WriteLn('Artyomov Alexander 2023  License: GNU AGPLv3 and above');
writeln('Use: gorg64_spkcompiler sourcefile.txt outfile.speaker');
if ParamCount < 2 then Halt;

if LoadFromFile(ParamStr(1)) then begin
 WriteLn('Err 1'); 
Halt(2);
end;
if SaveToFile(ParamStr(2)) then begin
 WriteLn('Err 2'); 
Halt(2);
end;

end.