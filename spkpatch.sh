#!/bin/bash

cat kernelrwpatch.txt >> fs/read_write.c
cat kerneltblpatch.txt >> tools/perf/arch/x86/entry/syscalls/syscall_64.tbl
cat kerneltblpatch.txt >> arch/x86/entry/syscalls/syscall_64.tbl
