 %include "config.asm"
 %include "kernel/config.asm"

[BITS 64]

[DEFAULT REL]

[ORG SOFTWARE_base_address]

wello:

 mov ax, KERNEL_SERVICE_VIDEO_string
 mov ecx, wello_string_end - wello_string
 mov rsi, wello_string
 int KERNEL_SERVICE

 xor ax, ax
 int KERNEL_SERVICE

wello_string db "Test Wello Cik from software"
wello_string_end:

