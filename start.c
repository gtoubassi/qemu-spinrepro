#include "x86.h"

#define kNumSpinIterations 10000000

void spin(int line) {
    unsigned short *kscreen = (unsigned short *)0xb8000UL;
    int pos = line * 80;
    for (int i = 0; i < kNumSpinIterations; i++) {
        if (i % (kNumSpinIterations/50) == 0) {
            kscreen[pos++] = 0x0700 | '.';
        }
    }
}

void spinwrapper(void) {
    spin(21);
    while (1) {} // spin forever
}

typedef struct {
    unsigned long rip;
    unsigned long cs;
    unsigned long rflags;
    unsigned long rsp;
    unsigned long ss;
} InterruptStackFrame;

#define kPIC1CommandPort    0x20
#define kPIC2CommandPort    0xa0
#define kPIC1DataPort       0x21
#define kPIC2DataPort       0xa1

static void picInit() {
    // See https://wiki.osdev.org/PIC#Programming_the_PIC_chips
    unsigned char a1, a2;

    a1 = x86_inb(kPIC1DataPort);                        // save masks
    a2 = x86_inb(kPIC2DataPort);

    x86_outb(kPIC1CommandPort, 0x11);   // starts the initialization sequence (in cascade mode)
    x86_outb(kPIC2CommandPort, 0x11);
    x86_outb(kPIC1DataPort, 0x20);      // ICW2: Master PIC vector offset
    x86_outb(kPIC2DataPort, 0x28);      // ICW2: Slave PIC vector offset
    x86_outb(kPIC1DataPort, 4);         // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    x86_outb(kPIC2DataPort, 2);         // ICW3: tell Slave PIC its cascade identity (0000 0010)

    x86_outb(kPIC1DataPort, 1);         // 8086/88 (MCS-80/85) mode
    x86_outb(kPIC2DataPort, 1);         // 8086/88 (MCS-80/85) mode

    x86_outb(kPIC1DataPort, a1);        // restore saved masks.
    x86_outb(kPIC2DataPort, a2);

    x86_outb(kPIC1DataPort, ~0);
    x86_outb(kPIC2DataPort,~0);
}

void start64C(void) {

    picInit();

    spin(20);
    InterruptStackFrame frame;
    frame.ss = 32 | 3;
    frame.cs = 24 | 3;
    frame.rip = (unsigned long)spinwrapper;
    frame.rsp = (unsigned long)(0x00100000 + 4096);
    frame.rflags = 0x202;
    x86_jumpToUserMode(&frame);
}
