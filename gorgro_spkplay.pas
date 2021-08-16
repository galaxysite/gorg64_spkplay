program gorgro_spkplay;

{$MODE OBJFPC}
{$RANGECHECKS ON}
{$LONGSTRINGS ON}
{$SMARTLINK ON}
{$ASMMODE INTEL}
//{$CODEPAGE UTF8}

{
    Program for playing melodys on PC-Speaker.
    For ReactOS.
    Version: 2.
    Written on FreePascal (https://freepascal.org/).
    Copyright (C) 2021  Artyomov Alexander
    http://self-made-free.ru/
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

uses sysutils,  windows;

type
      TTW = packed record
       tone, duration : Word;
      end;
      TAoW = array of Word;
      TAoTW = array of TTW;
      TSpkFile = class(TObject)
       a : TAoTW;
       fFileName : utf8string;
      public
      function LoadFromFile(fn : utf8string) : boolean;
      end;

function TSpkFile.LoadFromFile(fn : utf8string) : boolean;
var
  fp : File of TTW;
  fs : LongInt;
begin
Assign(fp, fn);
FileMode := 0;
{$I-}
ReSet(fp);
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
fs := FileSize(fp);
{$I+} if IOResult <> 0 then Exit(true);
SetLength(a, fs);
{$I-}
BlockRead(fp, a[0], fs);
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
Close(fp);
{$I+} if IOResult <> 0 then Exit(true);
fFileName := fn;
Exit(false);
end;

var
    f, ff, tmp : LongInt;

begin
WriteLn('GALAXY ORGANIZER SPEAKER PLAYER Version 3');
WriteLn('Artyomov Alexander 2021  License: GNU AGPLv3 and above');
WriteLn('Use: gorg64_spkplay or gorg64_spkplay somemusic.speaker somemusic2.speaker ...');

if ParamCount = 0 then begin
windows.Beep(2000, 1000);
Halt(0);
end;

for ff := 1 to ParamCount do
with TSpkFile.Create do begin
if LoadFromFile(ParamStr(ff)) then begin
 WriteLn('Err');
 Halt(2);
end;
WriteLn('Playing file: ' + fFileName);
for f := 0 to High(a) do begin
if a[f].duration < 1 then continue;
if a[f].tone < 1 then begin
sleep(a[f].duration);
end else begin
tmp := a[f].tone;
tmp :=1193280 div tmp;
if tmp > $FFFF then tmp := $FFFF;
if tmp < 1 then begin  sleep(a[f].duration); end else
windows.Beep(tmp, a[f].duration)
end;
end;
Free;
end;

end.