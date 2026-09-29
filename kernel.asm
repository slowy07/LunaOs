;===============================================================================

	;-----------------------------------------------------------------------
	; constants, variables, globals, structures, objects, macros, headers
	;-----------------------------------------------------------------------
	%include	"kernel/header.asm"
	;-----------------------------------------------------------------------

; 64 bit initialization code of the system kernel
[bits 64]

; location of the system kernel code in the physical memory
[org KERNEL_BASE_address]

init:
	;-----------------------------------------------------------------------
	; Init - initialization of the system kernel working environment
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

kernel:
	; fetch the pointer to the current task (the kernel) in the queue
	call	kernel_task_active

	; remove the process from the rotation
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_active

	; wait for the preemption
	jmp	$

	;-----------------------------------------------------------------------
	; procedures, data, libraries, services - everything needed
	; for the correct operation of the kernel/system services
	;-----------------------------------------------------------------------
	%include	"kernel/apic.asm"
	%include	"kernel/data.asm"
	%include	"kernel/exec.asm"
	%include	"kernel/idt.asm"
	%include	"kernel/io_apic.asm"
	%include	"kernel/ipc.asm"
	%include	"kernel/memory.asm"
	%include	"kernel/page.asm"
	%include	"kernel/panic.asm"
	%include	"kernel/task.asm"
	%include	"kernel/vfs.asm"
	%include	"kernel/service.asm"
	%include	"kernel/sleep.asm"
	%include	"kernel/stream.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/driver/network/i82540em.asm"
	%include	"kernel/driver/pci.asm"
	%include	"kernel/driver/ps2.asm"
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/serial.asm"
	%include	"kernel/driver/storage/ide.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/service/gc.asm"
	%include	"kernel/service/gui.asm"
	%include	"kernel/service/http.asm"
	%include	"kernel/service/network.asm"
	%include	"kernel/service/tx.asm"
	%include	"kernel/service/wm.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/library/page_align_up.asm"
	%include	"kernel/library/page_from_size.asm"
	;-----------------------------------------------------------------------

; move the system kernel code up to a full page boundary
align	STATIC_PAGE_SIZE_byte

kernel_end:
