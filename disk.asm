
	; first part of the boot program
	incbin	"build/bootsector"

	; main boot program file
	incbin	"build/luna_stage2"

	; kernel file
	incbin	"build/kernel"

	; VirtualBox requires an image of at least 1 MiB

; pad the disk image size to a full 1 MiB
align	1048576
