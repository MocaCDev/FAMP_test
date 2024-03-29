org 0x7C00
use16

struc mbr_partition_table_entry
	; Is this MBR partition table entry bootable?(is it describing the rest of the bootloader?)
	; 0x80 = bootable, 0x0 = not bootable
	.is_bootable:									resb 0x01
	; From what sector does the program begin(lower 8-bits)
	; With this, the sector where the program begins has to be the sector where the last program ended off
	; So, for a program after the MBR, `first_sector` would be 2
	; From what cylinder does the sector reside on?(upper 8-bits)
	.starting_sector_and_cylinder:					resw 0x01
	; 0x05/0x0F for extended partition table
	; Any other value has yet to be determined
	.entry_type:									resb 0x01
	; If this is `1`, the MBR partition table C program will automatically read in
	; the needed amount of memory. If `0`, the MBR partition table C program will not load
	; anything into memory.
	; This is going to be more helpful later on. With this, we can primarily mark certain
	; partitions in the extended partition table as "critical", thus, the protocol MUST
	; read the programs residing in each partition into memory AND run them
	.auto_read_program:								resb 0x01
	; From what sector does the program end?(lower 8-bits)
	; From what cylinder does the last sector reside on?(upper 8-bits)
	.last_sector_and_cylinder:						resw 0x01
	; Just set this to zero lol
	.relative_sector:								resd 0x01
	; How many sectors does the program obtain?
	; This amount * 512 will be added to `bprogram_address` to calculate the ending address
	; of the program
	.sector_amnt:									resb 0x01
	; Pad 1 byte
	.pad:											resd 0x01
endstruc

%macro CreateEntry	7
mbr_partition_entry%+%1:	istruc mbr_partition_table_entry
	at mbr_partition_table_entry.is_bootable,					db %2
	at mbr_partition_table_entry.starting_sector_and_cylinder,	dw %3
	at mbr_partition_table_entry.entry_type,					db %4
	at mbr_partition_table_entry.auto_read_program,				db %5
	at mbr_partition_table_entry.last_sector_and_cylinder,		dw %6
	at mbr_partition_table_entry.relative_sector,				dd 0x0
	at mbr_partition_table_entry.sector_amnt,					db %7
	at mbr_partition_table_entry.pad,							dd 0x0
iend
%endmacro

jmp 0x0:start

start:
	xor ax, ax
	mov es, ax
	mov ds, ax

	cli
	mov bp, 0x7C00
	mov sp, bp
	mov ss, ax
	sti

	; Read in program that works with the MBR partition table(located at 0x0500)
	xor ax, ax
	mov es, ax
	mov bx, 0x0500

	mov ah, 0x02
	mov al, 0x1
	mov ch, 0x00
	mov cl, 0x02
	mov dh, 0x00
	mov dl, 0x80
	int 0x13
	jc failed

	; Jump to program that works with the MBR partition table
	jmp 0x0500

	; Uh oh, something went wrong
	jmp failed

	; We shouldn't reach here, but if we do, hlt
	cli
	hlt

sector_addr equ 0x5000

times 0x100 - $ + $$ db 0x0

OS_info:
	; With this, the protocol will put some sort of data structure describing the type of FS
	; the user is using at a specific location.
	; The data at the specified memory address will be referred to by the protocol so it knows
	; what functionality/structures to use when working with files/directories.
	; If the user formats a disk image and mounts a FS other than what they specify they are using,
	; the protocol will catch it by seeing the FS header in the disk image. If the protocol finds that
	; the user specified a FS that the FS header at the beginning of the disk image does not describe,
	; it will prompt to the user to change the preferred FS in `boot.yaml`, and halt.
	.fs_type:			db 0x1 ; 0x1 - custom FS, 0x2 - FAT32, 0x3 - ext2
	.os_name:			db "FAMP_test"
	.os_version:		db "1.0.1"
	.os_type:			db 0x2 ; 0x2 - 32 bit OS, 0x3 - 64 bit OS

failed:
	mov ah, 0x0E
	mov al, 'F'
	int 0x10
.f_halt:
	jmp .f_halt

TIMES 0x01BE - $ + $$ db 0

; Second stage bootloader(0x0E = second-stage bootloader)
CreateEntry 1, 0x80, 0x3, 0x0E, 1, 0xB, 0x8

; Kernel(0x0D = kernel)
CreateEntry	2, 0x00, 0xB, 0x0D, 1, 0x15, 0xA

; FS(0x0C = FileSystem)
CreateEntry	3, 0x00, 0x15, 0x0C, 1, 0x15, 0x15  
CreateEntry	4, 0, 0, 0, 0, 0, 0

dw 0xAA55

mbr_partition_table_program: incbin "bin/mbr_partition_table.bin"
mbr_partition_table_program_end:

second_stage: incbin "bin/second_stage.bin"
second_stageE:

higher_half_kernel_program: incbin "bin/higher_half_kernel.bin"
higher_half_kernel_programE:

kernel: incbin "../bin/kernel.bin"
kernelE: