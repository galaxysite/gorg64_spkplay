//    Program for playing melodyes on PC-Speaker.
//    For GNU/Linux 64 bit version.
//    Version: 4.
//    Written on FreePascal (https://freepascal.org/).
//    Copyright (C) 2021-2024  Artyomov Alexander
//    http://self-made-free.ru/
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
#include <sys/io.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <glob.h>
#include <linux/input.h>
#include <stdint.h>

#include <sys/time.h>
#include <sys/resource.h>

// gcc -O4 -fPIE -pie gorg64_spktone.c  -o gorg64_spktonec -lm

int efd;

typedef struct {
	unsigned short tone;
	unsigned short duration;
} ttw;

short spkf(float tone)
{
int64_t tmp;
if ( tone < 1 ) { return 0; };
tmp = round(1193182 / tone);
if (tmp > 0xFFFF) { tmp = 0xFFFF; };
return tmp;
}

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

int open_evdev(const char *const device_name)
{
    struct stat sb;

    if (-1 == stat(device_name, &sb)) {
        return -1;
    }

    if (!S_ISCHR(sb.st_mode)) {
        return -1;
    }

    const int fd = open(device_name, O_WRONLY);
    if (fd == -1) {
        return -1;
    }

    if (-1 == fstat(fd, &sb)) {
        return -1;
    }

    if (!S_ISCHR(sb.st_mode)) {
        return -1;
    }

    return fd;
}

static
void espk(const uint16_t freq)
{
    struct input_event e;

    memset(&e, 0, sizeof(e));
    e.type = EV_SND;
    e.code = SND_TONE;
    e.value = spkf(freq);

    if (sizeof(e) != write(efd, &e, sizeof(e))) {
        puts("Cannot use the sound API");
        _Exit(1);
    }
}

static
void espkoff()
{
    struct input_event e;

    memset(&e, 0, sizeof(e));
    e.type = EV_SND;
    e.code = SND_TONE;
    e.value = 0;

    if (sizeof(e) != write(efd, &e, sizeof(e))) {
        _Exit(1);
    }
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
int evdev = 0;

int f_uid;
int f_euid;
f_uid = getuid();
f_euid = geteuid();
printf("UID=%d EUID=%d\n",f_uid,f_euid);

if (f_euid == 0) {
    if (setuid(0))
    {
        perror("setuid");
        return 1;
    }

//    if (seteuid(0))
//    {
//        perror("seteuid");
//        return 1;
//    }
}

f_uid = getuid();
f_euid = geteuid();
printf("Now UID=%d EUID=%d\n",f_uid,f_euid);

if ((argc > 1) && (strcmp(argv[1],"--stop") == 0)) {
system("killall gorg64_spkplay");
_Exit(0);
}

long int pid = getpid();
glob_t globlist;
int i;
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

InstallSignalHandlers();

if ((ioperm(0x42, 2, 1) == 0) && (ioperm(0x61, 1, 1) == 0))
{gspkon = spkon; gspkoff = spkoff; gspk = spk; puts("Use I/O ports");}
else {
 if (syscall(1003) == 123)
 {gspkon = kspkon; gspkoff = kspkoff; gspk = kspk; puts("Use kernel patch");} else {
  efd = open_evdev("/dev/input/by-path/platform-pcspkr-event-spkr");
  if (efd < 0) {puts("Error open evdev"); _Exit(1);} else {evdev = 1; puts("Use evdev");}
 };
};

setpriority(PRIO_PROCESS,0,-20);

if (argc == 1) {puts("Use: gorg64_spkplay file1.speaker file2.speaker ... ");
gspkon(); gspk(1000); usleep(1000000); gspkoff(); _Exit(0);}

void *a;
ttw *p;
struct stat sb;
int fd;
int64_t ff;
int64_t f;
for (ff = 1;  ff < argc; ff++){
puts(argv[ff]);
fd = open(argv[ff], O_RDONLY);
fstat(fd, &sb);
a = mmap(NULL,  sb.st_size, PROT_READ, MAP_PRIVATE, fd,  0);
close(fd);
if (a == MAP_FAILED) {puts("map failed"); continue;}
if (sb.st_size % 4 != 0) {puts("size / 4 <> 0"); continue;}
p = a;

if (evdev == 1) {
for (f = 0; f < sb.st_size; f++){
 if (p->duration < 1) continue;
 if (p->tone < 1) {
   espkoff();
   usleep(p->duration*1000);
 } else {
   espk(p->tone);
   usleep(p->duration*1000);
 }
p++;
}
espkoff();
} else {
gspkon();
for (f = 0; f < sb.st_size; f++){
 if (p->duration < 1) continue;
 if (p->tone < 1) {
   gspkoff();
   usleep(p->duration*1000);
   gspkon();
 } else {
   gspk(p->tone);
   usleep(p->duration*1000);
 }
p++;
}
gspkoff();
}

munmap(a, sb.st_size);
}
_Exit(0);
}