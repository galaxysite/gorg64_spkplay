//    Program for playing tones on PC-Speaker output. Adjust speaker tone.
//    For GNU/Linux 64 bit version. Root priveleges or kernel patch needed.
//    Version: 3.
//    Written on FreePascal (https://freepascal.org/).
//    Copyright (C) 2021-2023  Artyomov Alexander
//    http://self-made-free.ru/ (Ex http://aralni.narod.ru/)
//    aralni@mail.ru

//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Affero General Public License as
//    published by the Free Software Foundation, either version 3 of the
//    License, or (at your option) any later version.

//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU Affero General Public License for more details.

//    You should have received a copy of the GNU Affero General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.

#define _GNU_SOURCE
//#define extern -O1
#include <sys/io.h>
#include <unistd.h>
#include <sys/syscall.h>
//#include <sys/types.h>
#include <signal.h>
//#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
// gcc -lm -O1 -fPIE gorg64_spktone.c  -o gorg64_spktonec

int b_r = 0;
int e;

void spkon()
{
outb(inb(0x61) | 3, 0x61);
}
void spkoff()
{
outb(inb(0x61) & 0xFC, 0x61);
}
void spkpatchexists()
{
if (syscall(1003) == 123) {e = 1; } else {e = 0;}
}
void spk(short t)
{
outb(0xB6, 0x43);
outb(t & 0xff, 0x42);
outb((t >> 8) & 0xff, 0x42);
}
void kspk(short t)
{
syscall(1002,t);
}
void kspkon()
{
syscall(1000);
}
void kspkoff()
{
syscall(1001);
}
void gspk(short t)
{
if (e == 1) {kspk(t);} else {spk(t);}
}
void gspkon()
{
if (e == 1) {kspkon();} else {spkon();}
}
void gspkoff()
{
if (e == 1) {kspkoff();} else {spkoff();}
}

short spkf(float tone)
{
int64_t tmp;
if ( tone < 1 ) { return 0; };
tmp = round(1193280 / tone);
if (tmp > 0xFFFF) { tmp = 0xFFFF; };
return tmp;
}

void SIGHUPHandler(int signal) {
puts("SIGHUP");
b_r = 1;
gspkoff();
}
void SIGINTHandler(int signal) {
puts("SIGINT");
b_r = 1;
gspkoff();
}
void SIGTERMHandler(int signal) {
puts("SIGTERM");
b_r = 1;
gspkoff();
}
void InstallSignalHandlers() {
  struct sigaction action, nu;
  memset(&action, 0, sizeof(action));
  memset(&action, 0, sizeof(nu));
  action.sa_handler = SIGTERMHandler;
  action.sa_flags = SA_RESTART;
  sigaction(SIGTERM, &action, &nu);
  action.sa_handler = SIGINTHandler;
  sigaction(SIGINT, &action, &nu);
  action.sa_handler = SIGHUPHandler;
  sigaction(SIGHUP, &action, &nu);
}


int
main(int argc, char *argv[])
{
if (argc<2) {puts("Use: gorg64_spktone [f|t|d] [freq (in Hz)|tone (in speaker unit)]|delay in diapason in ms"); return 0;}

InstallSignalHandlers();

spkpatchexists();
if (e == 0) {
if ( ioperm(0x42, 2, 1) != 0 ) {puts("ERR 42-43 ports"); return 1;};
if ( ioperm(0x61, 1, 1) != 0 ) {puts("ERR 61 port"); return 1;};
}

int64_t i;
if (strcmp(argv[1], "t") == 0) {
i = atoi(argv[2]);
if (i != 0) { gspk(i); }
};
if (strcmp(argv[1], "f") == 0) {
float fl;
fl = atof(argv[2]);
i = spkf(fl);
if (i != 0) { gspk(i); }
};

if (strcmp(argv[1], "d") == 0) {
i = atoi(argv[2])*1000;
gspkon();
int f;
for (f =  0;  f <= 8000; f++) 
{
if (b_r) break;
gspk(f);
usleep(i);
}
gspkoff();
};

}
