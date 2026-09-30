
kernel_sleep:
 ; yield the processor, passing on the remaining time
 int KERNEL_APIC_IRQ_number

 ; return from the procedure
 ret

 macro_debug "kernel_sleep"
