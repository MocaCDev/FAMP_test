#define bit32_bit16_GDT
//#define default_gdt

#include "boot_protocol/protocol/boot_header.h"

void starting_point main()
{
    init_bootloader(BIT32_BIT16_DEF_VID_MODE);//init_bootloader(CLEAN_GDT_DEF_VID_MODE);
    set_gdt_status(NO_GDT);

    load_kernel();
}