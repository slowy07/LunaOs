;===============================================================================

;===============================================================================
; entry:
;	ax - key code
moko_key:
	; was the Enter key pressed?
	cmp	ax,	STATIC_SCANCODE_RETURN
	je	.key_enter	; yes

	; was the HOME key pressed?
	cmp	ax,	STATIC_SCANCODE_HOME
	je	.key_home	; yes

	; was the END key pressed?
	cmp	ax,	STATIC_SCANCODE_END
	je	.key_end	; yes

	; was the left arrow key pressed?
	cmp	ax,	STATIC_SCANCODE_LEFT
	je	.key_arrow_left	; yes

	; was the right arrow key pressed?
	cmp	ax,	STATIC_SCANCODE_RIGHT
	je	.key_arrow_right	; yes

	; was the up arrow key pressed?
	cmp	ax,	STATIC_SCANCODE_UP
	je	.key_arrow_up	; yes

	; was the down arrow key pressed?
	cmp	ax,	STATIC_SCANCODE_DOWN
	je	.key_arrow_down	; yes

	; was the PageUp key pressed?
	cmp	ax,	STATIC_SCANCODE_PAGE_UP
	je	.key_page_up	; yes

	; was the PageDown key pressed?
	cmp	ax,	STATIC_SCANCODE_PAGE_DOWN
	je	.key_page_down	; yes

	; was the Backspace key pressed?
	cmp	ax,	STATIC_SCANCODE_BACKSPACE
	je	.key_backspace	; yes

	; was the Delete key pressed?
	cmp	ax,	STATIC_SCANCODE_DELETE
	je	.key_delete	; yes

	; was the INSERT key pressed?
	cmp	ax,	STATIC_SCANCODE_INSERT
	je	.insert	; yes

	; was the CTRL key pressed?
	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT
 	je	.ctrl	; yes

 	; was the CTRL key released?
 	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT + STATIC_SCANCODE_RELEASE_mask
 	je	.ctrl_release	; yes

.no_key:
	; no key handling
	stc

	; end of the procedure
	ret

.changed:
	; save the last known inner line position pointer
	mov	qword [moko_document_line_index_last],	r11

	; save the last known beginning of the displayed line
	mov	qword [moko_document_line_begin_last],	r12

.refresh:
	; display the line contents again
	call	moko_line

.done:
	; function key, handled
	clc

.end:
	; return from the procedure
	ret

;-------------------------------------------------------------------------------
.key_page_up:
	; is the inner document pointer in the first line?
	mov	rax,	r10
	sub	rax,	r11
	cmp	rax,	qword [moko_document_start_address]
	je	.done	; yes, ignore

	; is the current line displayed from its first character?
	test	r12,	r12
	jz	.key_page_up_first_char	; yes

	; display the line again, starting at the first character
	xor	r12,	r12
	call	moko_line

.key_page_up_first_char:
	; is the document displayed from its first line?
	cmp	qword [moko_document_show_from_line],	STATIC_EMPTY
	ja	.key_page_up_from_other_line	; no

	; set the cursor in the first line of the screen space
	xor	r15,	r15

	; fetch the information about the first line of the document
	xor	rcx,	rcx
	call	moko_line_this

	; set the new properties of the current line
	call	moko_line_update

	; key handled
	jmp	.refresh

.key_page_up_from_other_line:
	; is the document displayed beyond the full height of the document space?
	cmp	qword [moko_document_show_from_line],	r9
	ja	.key_page_up_more_than_page	; yes

	; display the document contents from the first line
	mov	qword [moko_document_show_from_line],	STATIC_EMPTY

	; fetch the information about the line based on the cursor position (row)
	mov	rcx,	r15
	call	moko_line_this

.key_page_up_from_other_page:
	; refresh the document space on the screen
	call	moko_document_reload

	; set the new properties of the current line
	call	moko_line_update

	; key released
	jmp	.refresh

.key_page_up_more_than_page:
	; display the document from the previous N lines
	mov	rcx,	r9
	inc	rcx
	sub	qword [moko_document_show_from_line],	rcx

	; fetch the information about the line N rows back
	mov	rcx,	qword [moko_document_show_from_line]
	add	rcx,	r15
	call	moko_line_this

	; continue
	jmp	.key_page_up_from_other_page

;-------------------------------------------------------------------------------
.key_page_down:
	; is the inner document pointer in the last line?
	mov	rax,	r10
	sub	rax,	r11
	add	rax,	r13
	cmp	rax,	qword [moko_document_end_address]
	je	.done	; yes, ignore

	; is the current line displayed from its first character?
	test	r12,	r12
	jz	.key_page_down_first_char	; yes

	; display the line again, starting at the first character
	xor	r12,	r12
	call	moko_line

.key_page_down_first_char:
	; have the contents of the last document lines been displayed in the screen space?
	mov	rax,	qword [moko_document_line_count]
	sub	rax,	qword [moko_document_show_from_line]
	cmp	rax,	r9
	ja	.key_page_down_from_other_line	; no

	; set the cursor in the last line of the screen space
	mov	r15,	rax

	; fetch the information about the last line of the document
	mov	rcx,	qword [moko_document_line_count]
	call	moko_line_this

	; set the new properties of the current line
	call	moko_line_update

	; key handled
	jmp	.refresh

.key_page_down_from_other_line:
	; display the next N lines of the document
	mov	rcx,	r9
	inc	rcx
	add	qword [moko_document_show_from_line],	rcx

	; does the document line exist based on the current cursor position in the row?
	mov	rcx,	qword [moko_document_show_from_line]
	add	rcx,	r15
	cmp	rcx,	qword [moko_document_line_count]
	jbe	.key_page_down_row_exist	; yes

	; choose the last visible line of the document
	mov	rcx,	qword [moko_document_line_count]

	; set the cursor in the row of the last visible line
	mov	r15,	qword [moko_document_line_count]
	sub	r15,	qword [moko_document_show_from_line]

.key_page_down_row_exist:
	; refresh the document space on the screen
	call	moko_document_reload

	; fetch the information about this line
	call	moko_line_this

	; set the new properties of the current line
	call	moko_line_update

	; key released
	jmp	.refresh

;-------------------------------------------------------------------------------
.key_backspace:
	; is the cursor pointer inside the document at the beginning of the document?
	cmp	r10,	qword [moko_document_start_address]
	je	.done	; yes, ignore

	; is the cursor in the first column?
	test	r14,	r14
	jz	.key_backspace_first_column	; yes

	; move the cursor back to the previous column
	dec	r14

.key_backspace_middle_of_line:
	; move the cursor pointer inside the document to the previous character
	dec	r10

	; remove the given character from the document
	call	moko_document_remove

	; move the inner line pointer to the previous character
	dec	r11

	; decrease the number of characters in the line
	dec	r13

	; key handled
	jmp	.changed

.key_backspace_first_column:
	; is the line displayed from its first character?
	test	r12,	r12
	jz	.key_backspace_first_char	; yes

	; display the line contents from the previous character
	dec	r12

	; continue as in the previous query (skipping the cursor)
	jmp	.key_backspace_middle_of_line

.key_backspace_first_char:
	; is the cursor in the first row of the screen?
	test	r15,	r15
	jz	.key_backspace_first_row	; yes

	; is the cursor in the last line of the document visible on the screen?
	cmp	r9,	r15
	je	.key_backspace_last_line	; yes

	; move all the rows below the current cursor position up by one row
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	r15w
	inc	word [moko_string_scroll_up.y]	; start at the next row
	mov	word [moko_string_scroll_up.c],	r9w	; together with all the others
	sub	word [moko_string_scroll_up.c],	r15w
	int	KERNEL_SERVICE

	; clear the last line of the document
	call	moko_line_clear_last

.key_backspace_last_line:
	; display the document line matching the last row of the screen space (if there is one) or clear the row
	mov	rbx,	r9	; last row of the screen space
	mov	rcx,	r9
	add	rcx,	qword [moko_document_show_from_line]
	inc	rcx	; + removed line
	call	moko_line_number

	; move the cursor one row up
	dec	r15

.key_backspace_first_row:
	; fetch the properties of the previous line of the document
	call	moko_line_previous

	; move the cursor pointer inside the document back to the newline character
	dec	r10

	; remove the newline character from the document (join both lines into one)
	call	moko_document_remove

	; number of lines in the document
	dec	qword [moko_document_line_count]

	; beginning of the document?
	cmp	qword [moko_document_show_from_line],	STATIC_EMPTY
	je	.key_backspace_end	; yes

	; display the document from the previous line
	dec	qword [moko_document_show_from_line]

.key_backspace_end:
	; update the information about the current line

	; cursor position inside the document
	mov	r10,	rsi
	add	r10,	rcx

	; cursor position inside the line
	mov	r11,	rcx

	; display the line from its first character
	xor	r12,	r12

	; size of the line
	add	r13,	rcx

	; set the cursor in the column matching the size of the previous row
	mov	r14,	rcx

	; is the size of the current line greater than the width of the screen space?
	cmp	rcx,	r8
	jbe	.changed	; no

	; display the last N characters of the line
	mov	r12,	rcx
	sub	r12,	r8

	; set the cursor to the last row of the screen space
	mov	r14,	r8

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_delete:
	; end of the document
	cmp	r10,	qword [moko_document_end_address]
	je	.done	; yes, ignore

	; is the inner line pointer at the end of the line?
	cmp	r11,	r13
	je	.key_delete_end_of_line	; yes

	; remove the next character from the document
	call	moko_document_remove

	; decrease the line size by one character
	dec	r13

	; key handled
	jmp	.changed

.key_delete_end_of_line:
	; move all the rows below the current cursor position up by one row
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	r15w
	inc	word [moko_string_scroll_up.y]	; start at the next row
	mov	word [moko_string_scroll_up.c],	r9w	; together with all the others
	sub	word [moko_string_scroll_up.c],	r15w
	int	KERNEL_SERVICE

	; clear the last line of the document
	call	moko_line_clear_last

	; display the document line matching the last row of the screen space (if there is one)
	mov	rbx,	r9	; last row of the screen space
	mov	rcx,	r9
	add	rcx,	qword [moko_document_show_from_line]
	inc	rcx	; + removed line
	call	moko_line_number

	; fetch the information about the next line of the document
	call	moko_line_next

	; remove the newline character from the document
	call	moko_document_remove

	; extend the size of the current line by the size of the next one
	add	r13,	rcx

	; number of lines in the document
	dec	qword [moko_document_line_count]

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_arrow_up:
	; is the cursor pointer inside the document in the first line?
	mov	rax,	r10
	sub	rax,	r11
	cmp	rax,	qword [moko_document_start_address]
	je	.done	; yes, ignore the key

	; is the current line displayed from its first character?
	test	r12,	r12
	jz	.key_arrow_up_first_char	; yes

	; display the line again, starting at the first character
	xor	r12,	r12
	call	moko_line

.key_arrow_up_first_char:
	; the cursor is in the first row
	test	r15,	r15
	jnz	.key_arrow_up_other_row	; no

	; move all the document rows down
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_down_end - moko_string_scroll_down
	mov	rsi,	moko_string_scroll_down
	mov	word [moko_string_scroll_down.y],	STATIC_EMPTY	; start at the first row
	mov	word [moko_string_scroll_down.c],	r9w	; together with all the others
	int	KERNEL_SERVICE

	; display the document in the screen space from the previous line
	dec	qword [moko_document_show_from_line]

	; continue
	jmp	.key_arrow_up_first_row

.key_arrow_up_other_row:
	; move the cursor one row up
	dec	r15

.key_arrow_up_first_row:
	; fetch the information about the previous line of the document
	call	moko_line_previous

	; set the new properties of the current line
	call	moko_line_update

	; key handled
	jmp	.refresh

;-------------------------------------------------------------------------------
.key_arrow_down:
	; is the cursor pointer inside the document in the last line?
	mov	rax,	r10
	sub	rax,	r11
	add	rax,	r13
	cmp	rax,	qword [moko_document_end_address]
	je	.done	; yes, ignore

	; is the current line displayed from its first character?
	test	r12,	r12
	jz	.key_arrow_down_first_char	; yes

	; display the line again, starting at the first character
	xor	r12,	r12
	call	moko_line

.key_arrow_down_first_char:
	; is the cursor in the last row of the document space?
	cmp	r15,	r9
	jne	.key_arrow_down_other_row	; no

	; move rows 1..N up by one line
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	1	; start at the first row
	mov	word [moko_string_scroll_up.c],	r9w	; together with all the others
	int	KERNEL_SERVICE

	; display the document in the screen space from the next line
	inc	qword [moko_document_show_from_line]

	; continue
	jmp	.key_arrow_down_first_row

.key_arrow_down_other_row:
	; move the cursor one row down
	inc	r15

.key_arrow_down_first_row:
	; fetch the information about the next line of the document
	call	moko_line_next

	; set the new properties of the current line
	call	moko_line_update

	; key handled
	jmp	.refresh

;-------------------------------------------------------------------------------
.key_arrow_left:
	; is the cursor position pointer inside the document at the beginning of the document?
	cmp	r10,	qword [moko_document_start_address]
	je	.done	; yes, ignore

	; is the cursor in the first column?
	test	r14,	r14
	jnz	.key_arrow_left_other_column	; no

	; is the line displayed from its beginning?
	test	r12,	r12
	jnz	.key_arrow_left_start_of_line	; no

	; is the cursor in the first row?
	test	r15,	r15
	jnz	.key_arrow_left_other_row	; no

	; move all the document rows down
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_down_end - moko_string_scroll_down
	mov	rsi,	moko_string_scroll_down
	mov	word [moko_string_scroll_down.y],	STATIC_EMPTY	; start at the first row
	mov	word [moko_string_scroll_down.c],	r9w	; together with all the others
	int	KERNEL_SERVICE

	; display the document from the previous line
	dec	qword [moko_document_show_from_line]

	; continue as if moving one row up on the screen
	jmp	.key_arrow_left_other_row_omit_cursor

.key_arrow_left_other_row:
	; move the cursor one row up
	dec	r15

.key_arrow_left_other_row_omit_cursor:
	; fetch the information about the previous line
	call	moko_line_previous

	; update the properties of the current line and the cursor

	; pointer to the cursor position in the document space
	dec	r10

	; inner line offset
	mov	r11,	rcx

	; display the line from its first character
	xor	r12,	r12

	; line size in characters
	mov	r13,	rcx

	; set the cursor behind the last character in the line
	mov	r14,	rcx

	; is the line size greater than the width of the document space on the screen?
	cmp	rcx,	r8
	jbe	.changed	; no

	; display the last N characters of the line
	mov	r12,	rcx
	sub	r12,	r8

	; set the cursor in the last column
	mov	r14,	r8

	; key handled
	jmp	.changed

.key_arrow_left_other_column:
	; move the cursor position pointer in the document space one position left
	dec	r10

	; inner line offset by one position to the left
	dec	r11

	; move the cursor position back to the left
	dec	r14

	; key handled
	jmp	.changed

.key_arrow_left_start_of_line:
	; move the cursor position pointer in the document space one position left
	dec	r10

	; inner line offset by one position to the left
	dec	r11

	; display the line from the previous character
	dec	r12

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_arrow_right:
	; is the cursor position pointer inside the document at the end of the document?
	cmp	r10,	qword [moko_document_end_address]
	je	.done	; yes, ignore

	; is the inner line offset at the end of the line?
	cmp	r11,	r13
	je	.key_arrow_right_last_char	; yes

	; move the cursor position pointer in the document space to the next character
	inc	r10

	; inner line offset by one position to the right
	inc	r11

	; is the cursor in the last column?
	cmp	r14,	r8
	je	.key_arrow_right_last_column	; yes

	; move the cursor to the next column
	inc	r14

	; key handled
	jmp	.changed

.key_arrow_right_last_column:
	; display the line from the next character
	inc	r12

	; key handled
	jmp	.changed

.key_arrow_right_last_char:
	; is the whole current line visible?
	test	r12,	r12
	jz	.key_arrow_right_line_visible	; yes

	; display the line from the beginning
	xor	r12,	r12
	call	moko_line

.key_arrow_right_line_visible:
	; is the cursor in the last row?
	cmp	r15,	r9
	jb	.key_arrow_right_not_last_row	; no

	; move rows 1..N up by one line
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	1	; start at the first row
	mov	word [moko_string_scroll_up.c],	r9w	; together with all the others
	int	KERNEL_SERVICE

	; display the document from the next line
	inc	qword [moko_document_show_from_line]

	; leave the cursor in the current row
	jmp	.key_arrow_right_last_row

.key_arrow_right_not_last_row:
	; move the cursor to the next row
	inc	r15

.key_arrow_right_last_row:
	; fetch the properties of the next line of the document
	call	moko_line_next

	; pointer to the cursor position in the document space
	mov	r10,	rsi

	; inner line offset
	xor	r11,	r11

	; display the line contents from its first character
	xor	r12,	r12

	; size of the newline
	mov	r13,	rcx

	; set the cursor in the first column
	xor	r14,	r14

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_home:
	; set the cursor position pointer in the document space to the beginning of the current line
	sub	r10,	r11

	; set the inner line offset to the beginning of the line
	xor	r11,	r11

	; display the line from the beginning
	xor	r12,	r12

	; set the cursor on the X axis in the first column
	xor	r14,	r14

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_end:
	; set the cursor position pointer in the document space to the end of the current line
	sub	r10,	r11	; move back by the inner line offset
	add	r10,	r13	; move forward by the line size in characters

	; set the inner line offset by the line size in characters
	mov	r11,	r13

	; set the cursor in the column matching the end of the line
	mov	r14,	r13

	; will the displayed end of the line be off screen?
	cmp	r14,	r8
	jbe	.changed	; no

	; start displaying the line from the last r8 characters
	mov	r12,	r13	; from the line size
	sub	r12,	r8	; subtract the screen width in characters
	inc	r12

	; set the cursor in the last column of the current line
	mov	r14,	r8
	dec	r14

	; key handled
	jmp	.changed

;-------------------------------------------------------------------------------
.key_enter:
	; insert a newline character into the document at the current pointer position
	mov	ax,	STATIC_SCANCODE_NEW_LINE
	mov	bl,	STATIC_FALSE	; do not modify the properties of the current line
	call	moko_document_insert

	; the number of lines in the document is increasing
	inc	qword [moko_document_line_count]

	; save the information about the remaining line size, if it was cut
	mov	rdx,	r13
	sub	rdx,	r11

	; display the current line again, from its first character
	xor	r12,	r12	; from the first character
	sub	r13,	rdx	; to the first character of the new line
	call	moko_line

	; is the cursor in the last row of the screen space?
	cmp	r15,	r9
	jb	.key_enter_not_last	; no

	; move rows 1..N up by one line
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	1	; start at the second row
	mov	word [moko_string_scroll_up.c],	r9w	; together with all the others
	int	KERNEL_SERVICE

	; display the document from the next line
	inc	qword [moko_document_show_from_line]

	; continue
	jmp	.key_enter_continue

.key_enter_not_last:
	; set the cursor in the new row
	inc	r15

	; move the virtual cursor to the next line
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_to_row_next_end - moko_string_cursor_to_row_next
	mov	rsi,	moko_string_cursor_to_row_next
	int	KERNEL_SERVICE

	; is the virtual cursor on the last line of the document on the screen?
	cmp	r9,	r15
	je	.key_enter_continue	; yes

	; move the remaining rows of the document down
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_down_end - moko_string_scroll_down
	mov	rsi,	moko_string_scroll_down
	mov	word [moko_string_scroll_down.y],	r15w	; start at the second row
	mov	word [moko_string_scroll_down.c],	r9w	; together with all the others
	sub	word [moko_string_scroll_down.c],	r15w
	int	KERNEL_SERVICE

.key_enter_continue:
	; update the information about the new line of the document

	; move the inner document pointer past the inserted newline character
	inc	r10

	; set the inner line offset to the beginning
	xor	r11,	r11

	; display the new line from the beginning
	xor	r12,	r12

	; new line size
	mov	r13,	rdx

	; set the cursor to the beginning of the row
	xor	r14,	r14

	; the Enter key has been handled
	jmp	.changed


;-------------------------------------------------------------------------------
.ctrl:
	; raise the flag
	mov	byte [moko_key_ctrl_semaphore],	STATIC_TRUE
	jmp	.end	; key handled

;-------------------------------------------------------------------------------
.ctrl_release:
	; clear the flag
	mov	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
	jmp	.end	; key handled

;-------------------------------------------------------------------------------
.insert:
	; change the flag state

	; flag raised?
	cmp	byte [moko_key_insert_semaphore],	STATIC_FALSE
	je	.insert_no	; no

	; clear the flag
	mov	byte [moko_key_insert_semaphore],	STATIC_FALSE

	; end of the key handling
	jmp	moko_key.done

.insert_no:
	; raise the flag
	mov	byte [moko_key_insert_semaphore],	STATIC_TRUE

	; end of the key handling
	jmp	moko_key.done
