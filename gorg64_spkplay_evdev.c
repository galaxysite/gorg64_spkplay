//    Program for playing melodyes on PC-Speaker.
//    For GNU/Linux 64 bit version. Evdev version.
//    Version: 3.
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
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <glob.h>
#include <stdint.h>
#include <linux/input.h>

// gcc -O4 -fPIE -pie -msse4a -ffast-math gorg64_spkplay_evdev.c  -o gorg64_spkplay -lm

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
        /* If we cannot use the sound API, we cannot silence the sound either */
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
espkoff();
_Exit(0);
}
void SIGINTHandler(int signal) {
puts("SIGINT");
espkoff();
_Exit(0);
}
void SIGTERMHandler(int signal) {
puts("SIGTERM");
espkoff();
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

efd = open_evdev("/dev/input/by-path/platform-pcspkr-event-spkr");
if (efd < 0) {puts("Error open evdev"); _Exit(1);} else {puts("Use evdev");}

if (argc == 1) {puts("Use: gorg64_spkplay file1.speaker file2.speaker ... ");
espk(1000); usleep(1000000); espkoff(); _Exit(0);}

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

munmap(a, sb.st_size);
}
_Exit(0);
}