;===============================================================================

;===============================================================================
zero_pic:
	; switch both chips to initialisation mode
	mov	al,	0x11
	out	0x20,	al
	out	0xA0,	al

	; rebase pic0 (master) to interrupts 0x20 through 0x27
	mov	al,	0x20
	out	0x21,	al

	; rebase pic1 (slave) to interrupts 0x28 through 0x2F
	mov	al,	0x28
	out	0xA1,	al

	; tell pic0 it is the master and that pic1 exists
	mov	al,	4
	out	0x21,	al

	; tell pic1 it is the secondary (slave)
	mov	al,	2
	out	0xA1,	al

	; both controllers in 8086 mode
	mov	al,	1
	out	0x21,	al
	out	0xA1,	al

	; disable all hardware interrupts for now
	; they should not have been enabled, so act on a cold assumption
	mov	al,	11111111b	; irq15, irq14, irq13, irq12, irq11, irq10, irq9, irq8
	out	0xA1,	al	; pic1 (slave)

	mov	al,	11011110b	; irq7, irq6, sound, irq4, irq3, irq2, keyboard, sheduler/clock
	out	0x21,	al	; pic0 (master)

	; continue
	jmp	zero_pic_end

;===============================================================================
zero_pic_disable:
	; disable the interrupts on the PIC controller
	mov	al,	0xFF
	out	0x00A1,	al	; Slave
	out	0x0021,	al	; Master

	; return from the routine
	ret

;===============================================================================
zero_pic_end:
