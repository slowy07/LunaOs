
; entry:
;	rcx - number of characters of the string
;	rsi - pointer to the string
;	r8 - pointer to the terminal properties
console_sequence:
	; save the original registers
	push rax
	push rbx
	push rdi

	; can the string size contain sequences?
	cmp rcx, STATIC_SEQUENCE_length_min
	jb .error ; no

	; does the first character belong to the sequence?
	cmp byte [rsi], STATIC_SCANCODE_CARET
	jne .error ; no

	; command to execute?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte], "["
	jne .error ; no

	; color change?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x02], "c"
	je .color ; yes

	; modification of the console space?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x02], "t"
	je .terminal ; yes

	; console window header change?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x02], "h"
	je .header ; yes

.error:
	; no sequence handling
	stc

.end:
	; restore the original registers
	pop rdi
	pop rbx
	pop rax

	; return from the procedure
	ret

.header:
	; save the original registers
	push rax
	push rdi
	push rsi
	push rcx

	; move the pointer to the new window header name and limit the size of the remaining string
	sub rcx, 0x03
	add rsi, 0x03

	; recognize the header name (number of characters it consists of)
	mov al, "]"
	macro_library LIBRARY_STRUCTURE_ENTRY.string_cut
	jc .header_end ; end of the sequence not found

	; create a new header
	mov rdi, console_window
	macro_library LIBRARY_STRUCTURE_ENTRY.bosu_header_set

	; beginning and end of the sequence
	add rcx, 0x04

	; sequence processed
	sub qword [rsp], rcx
	; return the information about the remaining string to process
	add qword [rsp + STATIC_QWORD_SIZE_byte], rcx

.header_end:
	; restore the original registers
	pop rcx
	pop rsi
	pop rdi
	pop rax

	; return from the subprocedure
	jmp console_sequence.end

.color:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_COLOR_DEFAULT

	; save the original registers
	push rax
	push rdi

	; color table
	mov rdi, console_table_color

	; fetch the color code
	movzx eax, byte [rsi + STATIC_BYTE_SIZE_byte * 0x04]

	; no character color?
	cmp al, "*"
	je .color_background_only ; yes

	; set the character color
	call .color_translate
	mov eax, dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color], eax

.color_background_only:
	; fetch the color code
	movzx eax, byte [rsi + STATIC_BYTE_SIZE_byte * 0x03]

	; no background color?
	cmp al, "*"
	je .color_ready ; yes

	; set the background color
	call .color_translate
	mov eax, dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color], eax

.color_ready:
	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; restore the original registers
	pop rdi
	pop rax

	; return from the subprocedure
	jmp console_sequence.end

.color_translate:
	; decimal value?
	cmp al, STATIC_SCANCODE_DIGIT_9
	ja .color_translate_hex

	; convert into a 0-9 digit
	sub al, STATIC_SCANCODE_DIGIT_0

	; return from the subprocedure
	ret

.color_translate_hex:
	; convert into an A-F letter
	sub al, (STATIC_SCANCODE_HIGH_CASE - (STATIC_SCANCODE_DIGIT_9 - STATIC_SCANCODE_DIGIT_0)) - 0x01

	; return from the subprocedure
	ret

.terminal:
	; clear the character space?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "0"
	je .terminal_clear ; yes

	; set the cursor to a new position in the character space?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "1"
	je .terminal_cursor_position ; yes

	; toggle the cursor visibility?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "2"
	je .terminal_cursor_visibility ; yes

	; clear the line at the cursor position?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "3"
	je .terminal_line_clear ; yes

	; move the terminal contents up?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "4"
	je .terminal_scroll_up ; yes

	; move the terminal contents down?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "5"
	je .terminal_scroll_down ; yes

	; display the value?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x03], "6"
	je .terminal_number ; yes

	; sequence not recognized or corrupted
	jmp console_sequence.error

.terminal_number:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_NUMBER

	; has the sequence been completed correctly?
	cmp byte [rsi + THIS_SEQUENCE_LENGTH - STATIC_BYTE_SIZE_byte], "]"
	jne console_sequence.error

	; save the string size
	push rcx

	; display the value on the terminal
	mov rax, qword [rsi + 0x08] ; value
	mov bl, byte [rsi + 0x05] ; base
	movzx ecx, byte [rsi + 0x06] ; prefix size
	mov dl, byte [rsi + 0x07] ; prefix padding
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_number

	; restore the string size
	pop rcx

	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; return from the subprocedure
	jmp console_sequence.end

.terminal_scroll_up:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_SCROOL_UP

	; save the string size
	push rcx

	; fetch the number of lines to move
	movzx ebx, word [rsi + 0x05]

	; fetch the line number the shift starts from
	movzx rcx, word [rsi + 0x05 + STATIC_WORD_SIZE_byte]

	; execute
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_scroll_up

	; restore the string size
	pop rcx

	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; return from the subprocedure
	jmp console_sequence.end

.terminal_scroll_down:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_SCROOL_DOWN

	; save the string size
	push rcx

	; fetch the number of lines to move
	movzx ebx, word [rsi + 0x05]

	; fetch the line number the shift starts from
	movzx rcx, word [rsi + 0x05 + STATIC_WORD_SIZE_byte]

	; execute
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_scroll_down

	; restore the string size
	pop rcx

	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; return from the subprocedure
	jmp console_sequence.end

.terminal_line_clear:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CLEAR

	; line number to clear
	mov ebx, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_empty_line

	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; return from the subprocedure
	jmp console_sequence.end

.terminal_clear:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CLEAR

	; clear the console character space
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_clear

	; sequence processed
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; return from the subprocedure
	jmp console_sequence.end

.terminal_cursor_position:
	%strlen THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CURSOR

	; is the sequence size correct?
	cmp rcx, THIS_SEQUENCE_LENGTH
	jb console_sequence.error ; no

	; has the sequence been completed correctly?
	cmp byte [rsi + THIS_SEQUENCE_LENGTH - STATIC_BYTE_SIZE_byte], "]"
	jne console_sequence.error ; no

	; fetch the position on the X axis
	movzx eax, word [rsi + 0x05]
	cmp eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char] ; outside the area?
	jb .terminal_cursor_poistion_x_ok ; no

	; correct the position to the last column of the terminal
	mov eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	dec eax

.terminal_cursor_poistion_x_ok:
	; save the cursor position on the X axis
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x], eax

	; fetch the position on the Y axis
	movzx eax, word [rsi + 0x05 + STATIC_WORD_SIZE_byte]
	cmp eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char] ; outside the area?
	jb .terminal_cursor_poistion_y_ok ; no

	; correct the position to the last row of the terminal
	mov eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]
	dec eax

.terminal_cursor_poistion_y_ok:
	; save the cursor position on the X axis
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y], eax

	; close the sequence handling
	sub rcx, THIS_SEQUENCE_LENGTH
	add rsi, THIS_SEQUENCE_LENGTH

	; update the text cursor position in the console
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_set

	; return from the subprocedure
	jmp console_sequence.end

.terminal_cursor_visibility:
	; enable the cursor?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "0"
	je .terminal_cursor_visibility_show ; yes

	; disable the cursor?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "1"
	je .terminal_cursor_visibility_hide ; yes

	; remember the position?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "2"
	je .terminal_cursor_visibility_remember ; yes

	; restore the position?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "3"
	je .terminal_cursor_visibility_restore ; yes

	; unlock the cursor? (force it on)
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "4"
	je .terminal_cursor_visibility_reset ; yes

	; move the cursor one position up?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "C"
	je .terminal_cursor_visibility_move_up ; yes

	; move the cursor one position down?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "D"
	je .terminal_cursor_visibility_move_down ; yes

	; move the cursor one position to the left?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "E"
	je .terminal_cursor_visibility_move_left ; yes

	; move the cursor one position to the right?
	cmp byte [rsi + STATIC_BYTE_SIZE_byte * 0x05], "F"
	je .terminal_cursor_visibility_move_right ; yes

	; sequence not recognized or corrupted
	jmp console_sequence.error

.terminal_cursor_visibility_end:
	; sequence processed
	sub rcx, 0x07
	add rsi, 0x07

	; return from the subprocedure
	jmp console_sequence.end

.terminal_cursor_visibility_reset:
	; reset the lock counter
	mov qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock], STATIC_EMPTY

	; enable the cursor
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_hide:
	; hide the text cursor
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_disable

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_show:
	; show the text cursor
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_remember:
	; fetch the current cursor position in the terminal space
	mov rax, qword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor]

	; save
	mov qword [console_terminal_cursor_position_save], rax

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_restore:
	; hide the text cursor
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_disable

	; fetch the remembered cursor position
	mov rax, qword [console_terminal_cursor_position_save]

	; inform the terminal
	mov qword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor], rax
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_set

	; show the text cursor
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_move_up:
	; fetch the current cursor position on the Y axis
	mov eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]

	; move one position up
	dec eax
	jns .terminal_cursor_visibility_move_up_ok ; no overflow

	; lock the cursor in the first row
	xor eax, eax

.terminal_cursor_visibility_move_up_ok:
	; save the new cursor position on the Y axis
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y], eax

	; return from the subprocedure
	jmp .terminal_cursor_visibility_moved

.terminal_cursor_visibility_move_down:
	; fetch the current cursor position on the Y axis
	mov eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]

	; move one position down
	inc eax

	; has the cursor gone outside the terminal space?
	cmp eax, dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height]
	jb .terminal_cursor_visibility_move_down_ok ; no

	; no cursor movement in the terminal space

	; scroll the terminal contents up by one line
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_scroll

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_move_down_ok:
	; save the new cursor position on the Y axis
	mov dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y], eax

	; return from the subprocedure
	jmp .terminal_cursor_visibility_moved

.terminal_cursor_visibility_move_left:

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end
.terminal_cursor_visibility_move_right:

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end

.terminal_cursor_visibility_moved:
	; set the cursor at the position
	macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_set

	; return from the subprocedure
	jmp .terminal_cursor_visibility_end
