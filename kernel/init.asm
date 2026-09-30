
 ; logical processor?
 cmp byte [rel kernel_init_smp_semaphore], STATIC_FALSE
 je kernel_init ; no


 ; ; AP - logical processor initialisation
 %include "kernel/init/ap.asm"

 ; variables - used while initialising the kernel environment
 %include "kernel/init/data.asm"

 ; procedure initialising the APIC controller
 %include "kernel/init/apic.asm"

kernel_init:
 ; initialise the COM1 port (stdlog)
 %include "kernel/init/serial.asm"

 ; initialisation of the text mode area
 %include "kernel/init/video.asm"

 ; creation of the binary memory map and marking the kernel in it
 %include "kernel/init/memory.asm"

 ; create the stream table
 %include "kernel/init/stream.asm"

 ; processing of the ACPI tables
 %include "kernel/init/acpi.asm"

 ; create the final paging of the kernel
 %include "kernel/init/page.asm"

 ; share the libraries with all processes
 %include "kernel/init/library.asm"

 ; create the Global Descriptor Table
 %include "kernel/init/gdt.asm"

 ; create the Interrupt Descriptor Table
 %include "kernel/init/idt.asm"

 ; configure the real time clock - system uptime
 %include "kernel/init/rtc.asm"

 ; configure the handling of the pointing devices
 %include "kernel/init/ps2.asm"

 ; prepare the interprocess communication
 %include "kernel/init/ipc.asm"

 ; create the virtual file system
 %include "kernel/init/vfs.asm"

 ; initialise the available data drives
 %include "kernel/init/storage.asm"

 ; initialise one of the available network interfaces
 %include "kernel/init/network.asm"

 ; create the task queue
 %include "kernel/init/task.asm"

 ; insert into the task queue a set of services managing the kernel environment
 %include "kernel/init/services.asm"

 ; configure the internal interrupt of the local APIC controller (task switching in the queue)
 call kernel_init_apic

 ; set the default time between the interrupt calls (units)
 mov dword [rsi + KERNEL_APIC_TICR_register], DRIVER_RTC_Hz

 ; inform the APIC that the current local hardware interrupt has been handled
 mov dword [rsi + KERNEL_APIC_EOI_register], STATIC_EMPTY

 ; the task queue procedure will be called shortly!

 ; SMP - start the remaining logical processors
 %include "kernel/init/smp.asm"

.wait:
 ; fetch the number of running logical processors
 mov al, byte [rel kernel_init_ap_count]
 inc al ; the BSP processor is not counted as logical

 ; have all logical processors been initialised?
 cmp al, byte [rel kernel_apic_count]
 jne .wait ; no, wait


 ; INITIALISATION COMPLETE

 ; signal the end of the initialisation
 mov byte [rel kernel_init_semaphore], STATIC_FALSE

; bring the code position to a full page
 align STATIC_PAGE_SIZE_byte, db STATIC_NOTHING

.clean:
 ; release the area occupied by the initialisation procedures
 mov ecx, .clean - $$
 mov rdi, KERNEL_BASE_address
 call library_page_from_size ; convert the area size into pages
 call kernel_memory_release
