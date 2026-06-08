 %include "config.asm"
 %include "kernel/config.asm"

[BITS 32]

[ORG KERNEL_BASE_address]

init:
 %include "kernel/init.asm"

align KERNEL_PAGE_SIZE_byte, db STATIC_NOTHING
kernel:

 jmp service_http

 %include "kernel/macro/close.asm"
 %include "kernel/macro/apic.asm"
 %include "kernel/macro/debug.asm"
 %include "kernel/ipc.asm"
 %include "kernel/panic.asm"
 %include "kernel/page.asm"
 %include "kernel/memory.asm"
 %include "kernel/video.asm"
 %include "kernel/apic.asm"
 %include "kernel/io_apic.asm"
 %include "kernel/data.asm"
 %include "kernel/idt.asm"
 %include "kernel/task.asm"
 %include "kernel/network.asm"
 %include "kernel/thread.asm"
 %include "kernel/driver/rtc.asm"
 %include "kernel/driver/ps2.asm"
 %include "kernel/driver/pci.asm"
 %include "kernel/driver/network/i82540em.asm"
 %include "kernel/service/tresher.asm"
 %include "kernel/service/shell.asm"
 %include "kernel/service/http.asm"
 %include "kernel/service/tx.asm"
 %include "library/input.asm"
 %include "library/page_align_up.asm"
 %include "library/page_from_size.asm"
 %include "library/string_compare.asm"
 %include "library/string_trim.asm"
 %include "library/string_word_next.asm"

kernel_end:
