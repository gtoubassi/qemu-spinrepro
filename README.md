# Spin Loop Repro

This repo reproduces a case of a spin loop in kernel (ring 0) mode being emulated 100x slower than the same loop run in
user mode (ring 3) in qemu-system-x86_64 on a Mac (uname -a: Darwin xyz-mbp.lan 20.5.0 Darwin Kernel Version 20.5.0: Sat May  8 05:10:33 PDT 2021; root:xnu-7195.121.3~9/RELEASE_X86_64 x86_64
).

## How to Run

You can run directly against the `kernel.img` provided in the repro (to build your own see below)

    $ qemu-system-x86_64 kernel.img

## How to Build

To build you will need an x86_64 GNU toolchain on the Mac.  You should be able to install with brew install gcc, but I
built my own so this has not been verified.  The Makefile is set up to 
run x86_64-elf-gcc, x86_64-elf-as and x86_64-elf-ld, so adjust the constants accordingly:

    $ make
    $ qemu-system-x86_64 obj/kernel.img

## What it does

Execution starts with boot.s, which bootstraps into 64 bit long mode, loads "the rest" of the kernel
from disk (couldn't quite fit it all into the boot block), and then jumps over to start64C in start.c.

Start.c initializes the interrupt controller, then runs the spinloop in kernel mode.  The spinloop iterates to 10000000, and every 200k iterations
appends a '.' on line 20 for a progress bar.  It takes ~10 seconds to print the first line of dots.  Then 
we use a fabricated interrupt stack frame to jump to the spinloop in userland, and redo the spinloop, except
this time we print the progress bar on line 21.  The dots all render instantaneously.

## Investigations to date

I have run with `-trace exec_tb -trace translate_block -d out_asm,guest_errors,nochain` and could not find any obvious
explanations.



