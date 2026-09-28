;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"software/header.asm"
	;-----------------------------------------------------------------------
	%include	"software/console/header.asm"
	;-----------------------------------------------------------------------

%define	PROGRAM_NAME		"shell"
%define	PROGRAM_VERSION		"0.63"

SHELL_CACHE_SIZE_byte	equ	128
