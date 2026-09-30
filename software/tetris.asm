
 %include "software/tetris/config.asm"

tetris:
 ; create the window
 mov rsi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu
 jc tetris.close ; not enough memory space

 ; randomly pick a block and its pattern
 call tetris_random_block

 ; starting position of the block
 mov r8, TETRIS_BRICK_START_POSITION_x
 mov r9, TETRIS_BRICK_START_POSITION_y

.loop:
 ; check whether the new block collides with the currently existing ones
 call tetris_collision

 ; check the incoming events
 mov rsi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_event

 ; etc.
 jmp $

.close:
 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 macro_debug "software: tetris"

 %include "software/tetris/data.asm"
 %include "software/tetris/random.asm"
 %include "software/tetris/collision.asm"
