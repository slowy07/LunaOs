
; entry:
;	bx - block pattern
tetris_collision:
 ; save the original registers
 push rax
 push rbx
 push rcx
 push rdx
 push r9

 ; local variable
 push TETRIS_BRICK_STRUCTURE_height

.loop:
 ; fetch the first line of the block structure
 mov al, bl
 and al, STATIC_BYTE_LOW_mask

 ; move the line of the block structure into the place
 mov cl, r8b
 shl ax, cl

 ; fetch the board space line matching the line position of the block structure
 mov rdx, tetris_brick_platform
 mov dx, word [rdx + r9 * STATIC_WORD_SIZE_byte]

 ; did a collision occur?
 test ax, dx
 jz .no_collision ; no

 ; etc.
 nop

.no_collision:
 ; next line of the block pattern structure
 shr bx, STATIC_MOVE_AL_HALF_TO_LOW_shift

 ; next line of the board space
 inc r9

 ; has the whole block pattern been processed?
 dec qword [rsp]
 jnz .loop ; no

.end:
 ; free the local variable
 pop rax

 ; restore the original registers
 pop r9
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret
