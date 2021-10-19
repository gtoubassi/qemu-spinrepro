	.text
	.code64

	.globl	x86_inb
	.p2align	4, 0x90
x86_inb:
    movw     %di, %dx
	inb      %dx, %al
	retq

	.globl	x86_outb
	.p2align	4, 0x90
x86_outb:
    movw    %di, %dx
    movb    %sil, %al
	outb    %al, %dx
	retq

	.globl	x86_loadCr3
	.p2align	4, 0x90
x86_loadCr3:
    movq    %rdi, %cr3
	retq

	.globl	x86_jumpToUserMode
	.p2align	4, 0x90
x86_jumpToUserMode:
    movq %rdi, %rsp
	iretq
