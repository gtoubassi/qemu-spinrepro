SECTIONS
{
    . = 0x7c00;
    .text :
    {
        FILL(0)
        obj/boot.s.o(*)
        . = 0x1FE;
        SHORT(0xAA55)
        *(.*)

        . = 10 * 512;
    }
}
