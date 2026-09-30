
; input:
;	rbx - pointer to the drawing procedure
;	r8 - x1
;	r9 - y1
;	r10 - x2
;	r11 - y2
library_bresenham:
	; preserve the original registers
	push rax
	push rdx
	push rsi
	push rdi
	push r8
	push r9
	push r12
	push r13
	push r14
	push r15

	; check the X axis
	; x1 > x2
	cmp r8, r10
	ja .reverse_x

	; X axis direction increasing
	mov r12, 1 ; xi =  1
	mov r14, r10 ; dx =  x2
	sub r14, r8 ; dx -= x1

	; check the Y axis
	jmp .check_y

.reverse_x:
	; X axis direction decreasing
	mov r12, -1 ; xi =  -1
	mov r14, r8 ; dx =  x1
	sub r14, r10 ; dx -= x2

.check_y:
	; check the Y axis
	; y1 > y2
	cmp r9, r11
	ja .reverse_y

	; Y axis direction increasing
	mov r13, 1 ; yi =  1
	mov r15, r11 ; dy =  y2
	sub r15, r9 ; dy -= y1

	; continue
	jmp .done

.reverse_y:
	; Y axis direction decreasing
	mov r13, -1 ; yi =  -1
	mov r15, r9 ; dy =  y1
	sub r15, r11 ; dy -= y2

.done:
	; relative to which axis is the line drawn?
	; dy > dx
	cmp r15, r14
	ja .osY

	; draw the line relative to the X axis
	mov rsi, r15 ; ai =  dy
	sub rsi, r14 ; ai -= dx
	shl rsi, STATIC_MULTIPLE_BY_2_shift
	mov rdx, r15 ; d =   dy
	shl rdx, STATIC_MULTIPLE_BY_2_shift
	mov rdi, rdx ; bi =  d
	sub rdx, r14 ; d -=  dx

.loop_x:
	; display the pixel with the given color
	call rbx

	; if the displayed pixel sits at the line end point, done
	; x1 == x2
	cmp r8, r10
	je .end

	; negative coefficient?
	; d
	bt rdx, STATIC_QWORD_BIT_sign
	jc .loop_x_minus

	; compute the position of the next pixel on the line
	add r8, r12 ; x +=  xi
	add r9, r13 ; y +=  yi
	add rdx, rsi ; d +=  ai

	; draw the line
	jmp .loop_x

.loop_x_minus:
	; compute the position of the next pixel on the line
	add rdx, rdi ; d +=  bi
	add r8, r12 ; x +=  xi

	; draw the line
	jmp .loop_x

.osY:
	; draw the line relative to the Y axis
	mov rsi, r14 ; ai =  dx
	sub rsi, r15 ; ai -= dy
	shl rsi, STATIC_MULTIPLE_BY_2_shift
	mov rdx, r14 ; d =   dx
	shl rdx, STATIC_MULTIPLE_BY_2_shift
	mov rdi, rdx ; bi =  d
	sub rdx, r15 ; d -=  dy

.loop_y:
	; display the pixel with the given color
	call rbx

	; if the displayed pixel sits at the line end point, done
	; y1 == y2
	cmp r9, r11
	je .end

	; negative coefficient?
	; d
	bt rdx, STATIC_QWORD_BIT_sign
	jc .loop_y_minus

	; compute the position of the next pixel on the line
	add r8, r12 ; x +=  xi
	add r9, r13 ; y +=  yi
	add rdx, rsi ; d +=  ai

	; draw the line
	jmp .loop_y

.loop_y_minus:
	; compute the position of the next pixel on the line
	add rdx, rdi ; d +=  bi
	add r9, r13 ; y +=  yi

	; draw the line
	jmp .loop_y

.end:
	; restore the original registers
	pop r15
	pop r14
	pop r13
	pop r12
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rdx
	pop rax

	; return from the procedure
	ret
