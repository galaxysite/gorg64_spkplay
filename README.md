# gorg64_spkplay
Program for playing melodys on PC-Speaker. For GNU/Linux 32 and 64 bit version. Root priveleges needed.

Project have new place: https://gitflic.ru/project/alexander2023/gorg64_spkplay

GALAXY ORGANIZER PC-speaker player.

Can play musics from *.speaker files via standard PC-Speaker.

Run gorg64_spkplay only for test beep or
gorg64_spkpaly file1.speaker file2.speaker ... for music playing.

For compile player need installed Free Pascal Compiler (FPC),
then run: "fpc gorg64_spkplay.pas" for ports version
or: "fpc gorg64_spkplay_syscalls.pas" for playing on patched Linux Kernel.

For patch kernel need copy 3 files:
kernelrwpatch.txt
kerneltblpatch.txt
spkpatch.sh
to root of kernel source tree and one time run spkpatch.sh
