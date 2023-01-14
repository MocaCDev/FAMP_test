#ifndef protocol_boot_header
#define protocol_boot_header

#ifndef protocol_types
#include "types.h"
#endif

/* The C code has to be 16-bit for second-stage bootloader. */
/* The boot sector program loads the second-stage bootloader
 * which, to the user, is the initial boot of the OS. The second-stage
 * bootloader is where the user can load in the memory map, setup a video mode,
 * and other bare minimum ideals that a OS bootloader needs. */
asm(".code16gcc\n");

/* Beginning address of second-stage bootloader(`main.c`). */
extern uint8 begin_symbol[];
extern uint8 end_symbol[];

extern void init_bootloader(int8 setting);
extern void print_str();

/* Other ideals for the protocol*/
#ifndef protocol_util
#include "util.h"
#endif

#ifndef protocol_print
#include "tools/print.h"
#endif

#ifndef protocol_disk
#include "disk/disk.h"
#endif

#ifndef protocol_gdt_api
#include "gdt.h"    
#endif

uint8 inp(uint16 port)
{
        uint8 rv;
        __asm__ __volatile__ ("in %0, %1" : "=a"(rv) : "dN"(port));
        return rv;
}
void outp(uint16 port, uint8 data)
{
        __asm__ __volatile__ ("outb %0, %1" : : "dN"(port), "a"(data));
}

/* For user-convenience. */
#define starting_point          __attribute__((section("__start")))

#endif