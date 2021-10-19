#ifndef GCC_BINARY_X86_H
#define GCC_BINARY_X86_H

unsigned char x86_inb(unsigned short port);
void x86_outb(unsigned short port, unsigned char data);

void x86_loadCr3(void *rootTable);
void x86_jumpToUserMode(void *rsp);

#endif //GCC_BINARY_X86_H
