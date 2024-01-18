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
#include <glob.h>
#include <sys/stat.h>
// gcc -lm -O1 -fPIE gorg64_spktone.c  -o gorg64_spktonec

void spkon()
{
outb(inb(0x61) | 3, 0x61);
}
void spkoff()
{
outb(inb(0x61) & 0xFC, 0x61);
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
void (*gspkon)() = NULL;
void (*gspkoff)() = NULL;
void (*gspk)(short t) = NULL;

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
gspkoff();
_Exit(0);
}
void SIGINTHandler(int signal) {
puts("SIGINT");
gspkoff();
_Exit(0);
}
void SIGTERMHandler(int signal) {
puts("SIGTERM");
gspkoff();
_Exit(0);
}
void InstallSignalHandlers() {
  struct sigaction action, nu;
  memset(&action, 0, sizeof(action));
  memset(&nu, 0, sizeof(nu));
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
long int pid = getpid();
glob_t globlist;
int64_t i;
char cm[1024];
struct stat sp;
i = 0;               
glob("/proc/[0-9]*", GLOB_ONLYDIR, NULL, &globlist);
      while (globlist.gl_pathv[i])
        {
char *name = strrchr(globlist.gl_pathv[i], '/') + 1;
if (pid != atoi(name)) {
FILE *fp = fopen(strcat(globlist.gl_pathv[i], "/comm"), "r");
fgets(cm, 1023, fp);
cm[strcspn(cm, "\n" )] = '\0';
fclose(fp);
if ((strcmp("gorg64_spkplay", cm) == 0) | (strcmp("gorg64_spktone", cm) == 0)) {
puts("Already running. Exit.");
_Exit(0);
}
}
          i++;
        }
globfree(&globlist);

if (argc<3) {puts("Use: gorg64_spktone [f|t|d] [freq (in Hz)|tone (in speaker unit)]|delay in diapason in ms"); return 0;}

InstallSignalHandlers();

if (syscall(1003) == 123)
{gspkon = kspkon; gspkoff = kspkoff; gspk = kspk; puts("Use kernel patch");} else { 
if ( ioperm(0x42, 2, 1) != 0 ) {puts("ERR 42-43 ports"); _Exit(1);};
if ( ioperm(0x61, 1, 1) != 0 ) {puts("ERR 61 port"); _Exit(1);};
gspkon = spkon; gspkoff = spkoff; gspk = spk; puts("Use I/O ports");}

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
gspk(f);
usleep(i);
}
gspkoff();
};

}
