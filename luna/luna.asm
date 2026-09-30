
; 16-bit main boot program code
 [bits 16]

; code position within the CS segment space
 [org 0x1000]

zero:
 ; prepare the memory map
 %include "luna/memory.asm"

 ; enable graphics mode
 %include "luna/graphics.asm"

 ; switch the processor to 32-bit mode
 %include "luna/protected_mode.asm"

 ; switch the processor to 64-bit mode
 %include "luna/long_mode.asm"

 ; configure exception and hardware interrupt handling
 %include "luna/idt.asm"

 ; enable the hardware interrupts on the PIC controller
 %include "luna/pic.asm"

 ; load the kernel file
 %include "luna/storage.asm"

 ; disable the interrupt on the PIT controller
 %include "luna/pit.asm"

 ; pass all required information to the kernel
 %include "luna/kernel.asm"

 ; IDE disk controller driver
 %include "luna/driver/storage/ide.asm"

 ; routine that rounds an address up to a full page
 %include "luna/page.asm"

 ; boot program variables
 %include "luna/data.asm"

zero_end:
