program gorg64_spkplay_evdev;

{$MODE OBJFPC}
{$RANGECHECKS ON}
{$LONGSTRINGS ON}
{$SMARTLINK ON}
{$ASMMODE INTEL}

{
    Program for playing melodys on PC-Speaker.
    For GNU/Linux 64 bit version.
    Version: 4.
    Written on FreePascal (https://freepascal.org/).
    Copyright (C) 2021,2022,2024  Artyomov Alexander
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

uses sysutils,unix,baseunix,linux,urun;

var
  efd : Integer;

const
EV_SND = 18;
SND_TONE = 2;

type
      TTW = packed record
       tone, duration : Word;
      end;
      PTW=^TTW;

var
    f, ff : Int64;
    oa,na : PSigActionRec;
    fs : Int64 = 0;
    a :  PTW = nil;
    fFileName : utf8string = '';

function spkf(tone : Word) : Word;
var
  tmp : Int64;
begin
if tone < 1 then Exit(0);
tmp := 1193182 div tone;
if tmp > $FFFF then tmp := $FFFF;
Exit(tmp);
end;
function spkf(tone : extended) : Word;
var
  tmp : Int64;
begin
if tone < 1 then Exit(0);
tmp := round(1193280 / tone);
if tmp > $FFFF then tmp := $FFFF;
Exit(tmp);
end;

function open_evdev(fn : string) : Integer;
var
 info : stat;
 fd : cint;
begin
if fpstat (fn,info)<>0 then
begin
	writeln('Fstat failed. Errno : ',fpgeterrno);
	halt (1);
end;
if not fpS_ISCHR(info.st_mode) then begin
	writeln('fpS_ISCHR failed.');
	halt (1);
end;
FD:=fpOpen(fn,O_WrOnly);
if not(FD>0) then
begin
	writeln('fpOpen failed.');
	halt (1);
end;
if fpfstat (fd,info)<>0 then
begin
	writeln('Fstat 2 failed. Errno : ',fpgeterrno);
	halt (1);
end;
if not fpS_ISCHR(info.st_mode) then begin
	writeln('fpS_ISCHR failed.');
	halt (1);
end;
Exit(fd);
end;

type
input_event = record
	time : timeval;
	_type : Word;
	code : Word;
	value : LongInt;
end;

procedure espk(freq : Word);
var
    e : input_event;
begin
//    memset(&e, 0, sizeof(e));
    e._type := EV_SND;
    e.code := SND_TONE;
    e.value := spkf(freq);

    if (sizeof(e) <> fpwrite(efd, e, sizeof(e))) then begin
//        /* If we cannot use the sound API, we cannot silence the sound either */
        Halt(1);
    end;
end;

procedure espkoff;
var
    e : input_event;
begin
//    memset(&e, 0, sizeof(e));
    e._type := EV_SND;
    e.code := SND_TONE;
    e.value := 0;

    if (sizeof(e) <> fpwrite(efd, e, sizeof(e))) then begin
        Halt(1);
    end;
end;

function LoadFromFile(fn : utf8string) : boolean;
var
  fp : File of TTW;
begin
Assign(fp, fn);
FileMode := 0;
{$I-}
ReSet(fp);
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
fs := FileSize(fp);
{$I+} if IOResult <> 0 then Exit(true);
GetMem(a, fs*SizeOf(TTW));
{$I-}
BlockRead(fp, a[0], fs);
{$I+} if IOResult <> 0 then Exit(true);
{$I-}
Close(fp);
{$I+} if IOResult <> 0 then Exit(true);
fFileName := fn;
Exit(false);
end;

Procedure DoSig(sig : cint);cdecl;
begin
   writeln('Receiving signal: ',sig);
   espkoff;
   halt(0);
end;

begin
WriteLn('GALAXY ORGANIZER SPEAKER PLAYER Version 3');
WriteLn('Artyomov Alexander 2022-2024  License: GNU AGPLv3 and above');
WriteLn('Use: gorg64_spkplay_syscalls or gorg64_spkplay_syscalls somemusic.speaker somemusic2.speaker ...');

efd := open_evdev('/dev/input/by-path/platform-pcspkr-event-spkr');
//WriteLn('EFD = ',efd);

   new(na);
   new(oa);
   na^.sa_Handler:=SigActionHandler(@DoSig);
   fillchar(na^.Sa_Mask,sizeof(na^.sa_mask),#0);
   na^.Sa_Flags:= SA_RESTART;
   na^.Sa_Restorer:=Nil;
   if fpSigAction(SigTerm,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     halt(1);
     end;
   if fpSigAction(SigHup,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     halt(1);
     end;
   if fpSigAction(SigInt,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     halt(1);
     end;
   if fpSigAction(SigQuit,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     halt(1);
     end;
   if fpSigAction(SigTStp,na,oa)<>0 then
     begin
     writeln('Error: ',fpgeterrno,'.');
     halt(1);
     end;

if ParamCount = 0 then begin
 espk(1000); sleep(1000); espkoff;
 Halt;
end;

for ff := 1 to ParamCount do begin
if LoadFromFile(ParamStr(ff)) then begin
 WriteLn('Err');  espk(300); sleep(1000); espkoff;
Halt(2);
end;
WriteLn('* Playing file: ' + fFileName);

for f := 0 to fs-1 do begin
 if a[f].duration < 1 then continue;
 if a[f].tone < 1 then begin
   espkoff;
   sleep(a[f].duration);
 end else begin
   espk(a[f].tone);
   sleep(a[f].duration);
 end;
end;
espkoff;
FreeMem(a);
end;

end.