;===============================================================================

;===============================================================================
kernel_sleep:
	; wywłaszcz process, przekazująć pozosały czas
	int	KERNEL_APIC_IRQ_number

	; powrót z procedury
	ret

	macro_debug	"kernel_sleep"
