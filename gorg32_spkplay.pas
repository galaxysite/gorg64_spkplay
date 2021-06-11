program gorg32_spkplay;

{$MODE OBJFPC}
{$RANGECHECKS ON}
{$LONGSTRINGS ON}
{$SMARTLINK ON}
//{$CODEPAGE UTF8}

{
    Program for playing melodys on PC-Speaker.
    For GNU/Linux 32 bit version. Root priveleges needed.
    Version: 3.
    Written on FreePascal (https://freepascal.org/).
    Copyright (C) 2021  Artyomov Alexander
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

uses sysutils, spkunit32,unix,baseunix,linux;

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
  fs : Int64;
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

const
   lockfilename = '/tmp/speaker.lock';

var
    f, ff : LongInt;
    oa,na : PSigActionRec;
    lockfile : File of Byte;

Procedure DoSig(sig : cint);cdecl;
begin
   writeln('Receiving signal: ',sig);
   spkoff;
   DeleteFile(lockfilename);
   halt(0);
end;

begin
WriteLn('GALAXY ORGANIZER SPEAKER PLAYER Version 2');
WriteLn('Artyomov Alexander 2021  License: GNU AGPLv3 and above');
WriteLn('Use: gorg32_spkplay or gorg32_spkplay somemusic.speaker somemusic2.speaker ...');

if FileExists(lockfilename) then begin WriteLn('Already running. Or just locked by (in that case delete it): ' + lockfilename); exit; end;
Assign(lockfile, lockfilename);
ReWrite(lockfile);
Close(lockfile);

   new(na);
   new(oa);
   na^.sa_Handler:=SigActionHandler(@DoSig);
   fillchar(na^.Sa_Mask,sizeof(na^.sa_mask),#0);
   na^.Sa_Flags:=0;
   na^.Sa_Restorer:=Nil;
   if fpSigAction(SigTerm,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     DeleteFile(lockfilename);
     halt(1);
     end;
   if fpSigAction(SigHup,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     DeleteFile(lockfilename);
     halt(1);
     end;
   if fpSigAction(SigInt,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     DeleteFile(lockfilename);
     halt(1);
     end;
   if fpSigAction(SigQuit,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     DeleteFile(lockfilename);
     halt(1);
     end;
   if fpSigAction(SigTStp,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     DeleteFile(lockfilename);
     halt(1);
     end;

fpSystem('renice -n -19 -p ' + inttostr(fpgetpid));

if ParamCount = 0 then begin
 spkon; spk(1000); sleep(2000); spk(300); sleep(2000); spkoff;
 DeleteFile(lockfilename);
 Halt;
end;

for ff := 1 to ParamCount do
with TSpkFile.Create do begin
if LoadFromFile(ParamStr(ff)) then begin
 WriteLn('Err');  spkon; spk(1000); sleep(1000); spk(300); sleep(1000); spkoff;
 DeleteFile(lockfilename); Halt(2);
end;
WriteLn(WideChar($1F) + '♪ ♫  Playing file: ' + fFileName);
spkon;
for f := 0 to High(a) do begin
if a[f].duration < 1 then continue;
if a[f].tone < 1 then begin
  spkoff;
  sleep(a[f].duration);
  spkon;
end else begin
  spk(a[f].tone);
  sleep(a[f].duration);
end;
end;
spkoff;
Free;
end;

DeleteFile(lockfilename);

end.