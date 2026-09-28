BITS 64
section .data
sem: db 0
section .text
%macro ml 2
	xchg	byte [%1 + %2],	al
%endmacro
ml sem, 0
