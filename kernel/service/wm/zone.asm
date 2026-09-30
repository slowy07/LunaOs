

; input:
;	rax - pointer to the object table record
kernel_wm_zone_insert_by_object:
 ; preserve the original registers
 push rdx
 push rdi
 push rsi
 push rax

 ; lock access to modifying the zone list
 macro_lock kernel_wm_zone_semaphore, 0

 ; is the zone list full?
 cmp qword [rel kernel_wm_zone_list_records], KERNEL_WM_ZONE_LIST_limit
 jb .insert ; no

 xchg bx,bx
 jmp $

.insert:
 ; indirect pointer to the end of the zone list
 mov eax, KERNEL_WM_STRUCTURE_ZONE.SIZE
 mul qword [rel kernel_wm_zone_list_records] ; position past the last zone of the list

 ; set the pointers to their places
 mov rsi, qword [rsp]
 mov rdi, qword [rel kernel_wm_zone_list_address]
 add rdi, rax

 ; insert the zone properties
 movsw ; position on the X axis
 movsw ; position on the Y axis
 movsw ; width
 movsw ; height

 ; and the information about the dependent object
 mov rax, qword [rsp]
 mov qword [rdi], rax

 ; number of zones on the list
 inc qword [rel kernel_wm_zone_list_records]

 ; unlock the zone list for modification
 mov byte [rel kernel_wm_zone_semaphore], STATIC_FALSE

 ; restore the original registers
 pop rax
 pop rsi
 pop rdi
 pop rdx

 ; return from the procedure
 ret

 macro_debug "kernel_wm_zone_insert_by_object"

; input:
;	rdi - pointer to the object table record
;	r8 - position on the X axis
;	r9 - position on the Y axis
;	r10 - width of the zone
;	r11 - height of the zone
kernel_wm_zone_insert_by_register:
 ; preserve the original registers
 push rax
 push rdx
 push rsi

 ; lock access to modifying the zone list
 macro_lock kernel_wm_zone_semaphore, 0

 ; is the zone list full?
 cmp qword [rel kernel_wm_zone_list_records], KERNEL_WM_ZONE_LIST_limit
 jb .insert ; no

 xchg bx,bx
 jmp $

.insert:
 ; indirect pointer to the end of the zone list
 mov eax, KERNEL_WM_STRUCTURE_ZONE.SIZE
 mul qword [rel kernel_wm_zone_list_records] ; position past the last zone of the list

 ; direct pointer to the end of the zone list
 mov rsi, qword [rel kernel_wm_zone_list_address]
 add rsi, rax

 ; put a new zone on the list
 mov word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.x], r8w
 mov word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.y], r9w
 mov word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.width], r10w
 mov word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.height], r11w

 ; and its dependent object
 mov qword [rsi + KERNEL_WM_STRUCTURE_ZONE.object], rdi

 ; number of zones on the list
 inc qword [rel kernel_wm_zone_list_records]

 ; unlock the zone list for modification
 mov byte [rel kernel_wm_zone_semaphore], STATIC_FALSE

 ; restore the original registers
 pop rsi
 pop rdx
 pop rax

 ; return from the procedure
 ret

 macro_debug "kernel_wm_zone_insert_by_register"

kernel_wm_zone:
 ; preserve the original registers
 push rax
 push rsi
 push rdi
 push r8
 push r9
 push r10
 push r11
 push r12
 push r13
 push r14
 push r15

 ; no zones on the list?
 cmp qword [rel kernel_wm_zone_list_records], STATIC_EMPTY
 je .end ; yes

 ; set the pointer to the first described zone on the list
 mov rdi, qword [rel kernel_wm_zone_list_address]

 ; start processing
 jmp .entry

.loop:
 ; release the zone from the list
 mov qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object], STATIC_EMPTY

 ; move the pointer to the first/next zone to process
 add rdi, KERNEL_WM_STRUCTURE_ZONE.SIZE

.entry:
 ; no zone to process?
 cmp qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object], STATIC_EMPTY
 je .end ; yes

 ; fetch the zone properties

 ; left edge on the X axis
 mov r8w, word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.x]
 ; top edge on the Y axis
 mov r9w, word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.y]
 ; right edge on the X axis
 mov r10w, word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.width]
 add r10w, r8w
 ; bottom edge on the Y axis
 mov r11w, word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.height]
 add r11w, r9w

 ; is the described zone inside the "screen" space?

 ; beyond the right edge of the screen?
 cmp r8w, word [rel kernel_video_width_pixel]
 jge .loop ; yes
 ; beyond the bottom edge of the screen?
 cmp r9w, word [rel kernel_video_height_pixel]
 jge .loop ; yes
 ; beyond the left edge of the screen?
 cmp r10w, STATIC_EMPTY
 jle .loop ; yes
 ; beyond the top edge of the screen?
 cmp r11w, STATIC_EMPTY
 jle .loop ; no

 ; interference

 ; indirect pointer to the end of the object list
 mov rsi, qword [rel kernel_wm_object_list_length]
 shl rsi, KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift ; position past the last object of the list
 add rsi, qword [rel kernel_wm_object_list_address]

.object:
 ; set the pointer to the considered object
 sub rsi, KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

 ; fetch the pointer to the object table record
 mov rax, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

 ; is the considered object first on the list?
 cmp rsi, qword [rel kernel_wm_object_list_address]
 je .fill ; yes

 ; is the object visible?
 test word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_visible
 jz .object ; no

 ; has the interference with the processed object occurred? (with itself)
 cmp rax, qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object]
 je .fill ; yes

 ; fetch the object coordinates

 ; left edge on the X axis
 mov r12w, word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
 ; top edge on the Y axis
 mov r13w, word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
 ; right edge on the X axis
 mov r14w, word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
 add r14w, r12w
 ; bottom edge on the Y axis
 mov r15w, word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
 add r15w, r13w

 ;      r9	       r13	X
 ;    -------	     -------
 ; r8 |  S  | r10 r12 |  O  | r14
 ;    -------	     -------
 ;      r11	       r15
 ; Y

 ; is the object outside the processed zone?
 cmp r12w, r10w ; left edge of the object past the right edge of the zone?
 jge .object ; yes
 cmp r13w, r11w ; top edge of the object past the bottom edge of the zone?
 jge .object ; yes
 cmp r14w, r8w ; right edge of the object before the left edge of the zone?
 jle .object ; yes
 cmp r15w, r9w ; bottom edge of the object before the top edge of the zone?
 jle .object ; yes

 ; trimming

.left: ;)
 ; is the left edge of the zone before the left edge of the object?
 cmp r8w, r12w
 jge .up ; no

 ; cut out the protruding fragment of the zone

 ; preserve the original position of the right edge of the zone
 push r10

 ; width of the cut off zone
 mov r10w, r12w
 sub r10w, r8w

 ; height of the cut off zone
 sub r11w, r9w

 ; put on the zone list
 call kernel_wm_zone_insert_by_register

 ; restore the original position of the right edge of the zone
 pop r10

 ; restore the original position of the bottom edge of the zone
 add r11w, r9w

 ; new position of the left edge of the zone
 mov r8w, r12w

.up:
 ; is the top edge of the zone before the top edge of the object?
 cmp r9w, r13w
 jge .right ; no

 ; cut out the protruding fragment of the zone

 ; width of the cut off zone
 sub r10w, r8w

 ; preserve the original position of the bottom edge of the zone
 push r11

 ; height of the cut off zone
 mov r11w, r13w
 sub r11w, r9w

 ; put on the zone list
 call kernel_wm_zone_insert_by_register

 ; restore the original position of the right edge of the zone
 pop r11

 ; restore the original position of the bottom edge of the zone
 add r10w, r8w

 ; new position of the top edge of the zone
 mov r9w, r13w

.right:
 ; is the right edge of the zone past the right edge of the object?
 cmp r10w, r14w
 jle .down ; no

 ; cut out the protruding fragment of the zone

 ; width of the cut off zone
 push r10
 sub r10w, r14w

 ; height of the cut off zone
 sub r11w, r9w

 ; preserve the original position of the left edge of the zone
 push r8

 ; position of the left edge of the cut off zone
 mov r8w, r14w

 ; put on the zone list
 call kernel_wm_zone_insert_by_register

 ; restore the original position of the left edge of the zone
 pop r8

 ; new position of the right edge of the zone
 sub word [rsp], r10w
 pop r10

 ; restore the position of the bottom edge
 add r11w, r9w

.down:
 ; is the bottom edge of the zone past the bottom edge of the object?
 cmp r11w, r15w
 jle .fill ; no

 ; cut out the protruding fragment of the zone

 ; height of the cut off zone
 sub r11w, r15w

 ; preserve the original position of the top edge of the zone
 push r9

 ; position of the top edge of the cut off zone
 mov r9w, r15w

 ; put on the zone list
 call kernel_wm_zone_insert_by_register

 ; restore the original position of the left edge of the zone
 pop r9

 ; new position of the bottom edge of the zone
 sub word [rsp], r11w
 mov r11w, r15w

.fill:
 ; fill the remaining fragment with the given object
 sub r10w, r8w ; return the width of the zone
 sub r11w, r9w ; return the height of the zone
 cmp r10w, STATIC_EMPTY
 jle .loop

 ; register for filling
 call kernel_wm_fill_insert_by_register

 ; continue
 jmp .loop

.end:
 ; all zones on the list have been processed
 mov qword [rel kernel_wm_zone_list_records], STATIC_EMPTY

 ; restore the original registers
 pop r15
 pop r14
 pop r13
 pop r12
 pop r11
 pop r10
 pop r9
 pop r8
 pop rdi
 pop rsi
 pop rax

 ; return from the procedure
 ret

 macro_debug "kernel_wm_zone"
