
; 16-bit boot program code ==========================================
 [bits 16]

; code/data position in physical memory space
 [org 0x7C00]

bootsector:
 ; disable interrupts (we modify the segment registers)
 cli

 ; set the code segment (CS) address to the start of physical memory
 jmp 0x0000:.repair_cs

.repair_cs:
 ; set the data (DS), extra (ES) and stack (SS) segment addresses to the start of physical memory
 xor ax, ax
 mov ds, ax ; data segment
 mov ss, ax ; stack segment

 ; point the stack top at guaranteed free memory
 mov sp, bootsector

 ; enable interrupts
 sti

 ; load the main boot program code
 mov ah, 0x42
 mov si, bootsector_table_disk_address_packet
 int 0x13

 ; if the main boot program code loaded correctly, run it
 jnc 0x1000

 ; stop further execution of the boot program code
 jmp $

; table-formatted data block used by function AH=0x42, interrupt 0x13
; http://www.ctyme.com/intr/rb-0708.htm
; we keep all tables at a full address
 align 0x04
bootsector_table_disk_address_packet:
 db 0x10 ; table size
 db 0x00 ; reserved value
 dw ZERO_FILE_SIZE_bytes / 0x0200 ; compute the size of the file appended to the boot sector
 dw 0x1000 ; offset
 dw 0x0000 ; segment
 dq 0x0000000000000001 ; LBA address of the first sector of the appended file

; boot sector signature
 times 510 - ($ - $$) db 0x00
 dw 0xAA55 ; pure magic ;></
