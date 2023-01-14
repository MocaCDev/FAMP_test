use16

;
; =======================
;       16-bit code
; =======================
;

%include "protocol/extra/tests.s"
%include "protocol/mouse/mouse.s"
%include "protocol/tools/print.s"
%include "protocol/disk/disk.s"

; TODO: Make these into "magic numbers"
; For now, this works well
%define clean_gdt           0x1
%define bit32_bit16_gdt     0x10
%define bit32_only_gdt      0x2
%define b8000_vid_mode      0x20
%define vesa_vid_mode       0x3

%define DEFAULT_ALL                 clean_gdt | b8000_vid_mode
%define CLEAN_GDT_DEF_VID_MODE      clean_gdt | b8000_vid_mode
%define CLEAN_GDT_VESA_VID_MODE     clean_gdt | vesa_vid_mode
%define BIT32_BIT16_DEF_VID_MODE    bit32_bit16_gdt | b8000_vid_mode
%define BIT32_BIT16_VESA_VID_MODE   bit32_bit16_gdt | vesa_vid_mode
%define BIT32_ONLY_DEF_VID_MODE     bit32_only_gdt | b8000_vid_mode
%define BIT32_ONLY_VESA_VID_MODE    bit32_only_gdt | vesa_vid_mode

setting         db 0x0


global init_bootloader
use16
init_bootloader:
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Init the mouse
    call config_mouse

    push ebp
    mov ebp, esp

    mov ah, [ebp + 8]
    mov [setting], ah

    pop ebp

    mov ah, [setting]

    ; Check
    cmp ah, DEFAULT_ALL
    je .defall

    cmp ah, CLEAN_GDT_DEF_VID_MODE
    je .defall

    cmp ah, CLEAN_GDT_VESA_VID_MODE
    je .clean_gdt_vesa_vid_mode

    cmp ah, BIT32_BIT16_DEF_VID_MODE
    je .bit32_bit16_def_vid_mode

    cmp ah, BIT32_BIT16_VESA_VID_MODE
    je .bit32_bit16_vesa_vid_mode

    cmp ah, BIT32_ONLY_DEF_VID_MODE
    je .bit32_only_def_vid_mode

    cmp ah, BIT32_ONLY_VESA_VID_MODE
    je .bit32_only_vesa_vid_mode

    jmp .error
.defall:
    mov eax, [g_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [g_GDT32_16]
    mov [g_GDT_address], eax

    mov eax, 0                        ; 0 meaning: there isn't an already-working GDT loaded into  memory
    mov [g_GDT_status], eax

    ret
.clean_gdt_vesa_vid_mode:
    mov eax, [g_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [g_GDT32_16]
    mov [g_GDT_address], eax

    mov eax, 0                        ; 0 meaning: there isn't an already-working bit32/bit16 GDT loaded into  memory
    mov [g_GDT_status], eax

    ; Call to setup vesa video mode.
    ; TODO: Figure out what we want to do

    ret
.bit32_bit16_def_vid_mode:
    mov eax, [working_bit32_bit16_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [working_bit32_bit16_GDT]
    mov [g_GDT_address], eax

    mov eax, 1                        ; 1 meaning: there is an already-working bit32/bit16GDT loaded into  memory
    mov [g_GDT_status], eax

    ; Call to setup vesa video mode.
    ; TODO: Figure out what we want to do

    ret
.bit32_bit16_vesa_vid_mode:

    mov eax, [working_bit32_bit16_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [working_bit32_bit16_GDT]
    mov [g_GDT_address], eax

    mov eax, 1                        ; 1 meaning: there is an already-working bit32/bit16 GDT loaded into  memory
    mov [g_GDT_status], eax

    ; Call to setup vesa video mode.
    ; TODO: Figure out what we want to do

    ret
.bit32_only_def_vid_mode:
    mov eax, [working_bit32_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [working_bit32_GDT]
    mov [g_GDT_address], eax

    mov eax, 2                      ; 2 meaning: there is an already-working bit32 GDT loaded into memory
    mov [g_GDT_status], eax

    ret
.bit32_only_vesa_vid_mode:
    
    mov eax, [working_bit32_GDTDesc]
    mov [g_GDT_desc_addr], eax

    mov eax, [working_bit32_GDT]
    mov [g_GDT_address], eax

    mov eax, 2                      ; 2 meaning: there is an already-working bit32 GDT loaded into memory
    mov [g_GDT_status], eax

    ; Call to setup vesa video mode.
    ; TODO: Figure out what we want to do

    ret
.error:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10

    cli
    hlt
    
%include "protocol/gdt/gdt_ideals.s"