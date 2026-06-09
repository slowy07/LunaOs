KERNEL_VIDEO_BASE_address equ 0x000B8000
KERNEL_VIDEO_BASE_limit equ KERNEL_VIDEO_BASE_address + KERNEL_VIDEO_SIZE_byte
KERNEL_VIDEO_WIDTH_char equ 80
KERNEL_VIDEO_HEIGHT_char equ 25
KERNEL_VIDEO_CHAR_SIZE_byte equ 0x02
KERNEL_VIDEO_LINE_SIZE_byte equ KERNEL_VIDEO_WIDTH_char * KERNEL_VIDEO_CHAR_SIZE_byte
KERNEL_VIDEO_SIZE_byte equ KERNEL_VIDEO_LINE_SIZE_byte * KERNEL_VIDEO_HEIGHT_char

kernel_video_width dq KERNEL_VIDEO_WIDTH_char
kernel_video_height dq KERNEL_VIDEO_HEIGHT_char
kernel_video_char_size_byte dq KERNEL_VIDEO_CHAR_SIZE_byte
kernel_video_line_size_byte dq KERNEL_VIDEO_LINE_SIZE_byte
kernel_video_size_byte dq KERNEL_VIDEO_LINE_SIZE_byte * KERNEL_VIDEO_HEIGHT_char

kernel_video_pointer dq KERNEL_VIDEO_BASE_address
kernel_video_cursor:
 .x: dd STATIC_EMPTY
 .y: dd STATIC_EMPTY

kernel_video_char_color_and_background db STATIC_COLOR_gray_light

kernel_video_color_sequence_default db STATIC_COLOR_ASCII_DEFAULT
kernel_video_color_sequence_black db STATIC_COLOR_ASCII_BLACK
kernel_video_color_sequence_blue db STATIC_COLOR_ASCII_BLUE
kernel_video_color_sequence_green db STATIC_COLOR_ASCII_GREEN
kernel_video_color_sequence_cyan db STATIC_COLOR_ASCII_CYAN
kernel_video_color_sequence_red db STATIC_COLOR_ASCII_RED
kernel_video_color_sequence_magenta db STATIC_COLOR_ASCII_MAGENTA
kernel_video_color_sequence_brown db STATIC_COLOR_ASCII_BROWN
kernel_video_color_sequence_gray_light db STATIC_COLOR_ASCII_GRAY_LIGHT
kernel_video_color_sequence_gray db STATIC_COLOR_ASCII_GRAY
kernel_video_color_sequence_blue_light db STATIC_COLOR_ASCII_BLUE_LIGHT
kernel_video_color_sequence_green_light db STATIC_COLOR_ASCII_GREEN_LIGHT
kernel_video_color_sequence_cyan_light db STATIC_COLOR_ASCII_CYAN_LIGHT
kernel_video_color_sequence_red_light db STATIC_COLOR_ASCII_RED_LIGHT
kernel_video_color_sequence_magenta_light db STATIC_COLOR_ASCII_MAGENTA_LIGHT
kernel_video_color_sequence_yellow db STATIC_COLOR_ASCII_YELLOW
kernel_video_color_sequence_white db STATIC_COLOR_ASCII_WHITE

kernel_video_dump:
 push rax
 push rcx
 push rdi

 mov ax, 0x0720
 mov ecx, KERNEL_VIDEO_WIDTH_char * KERNEL_VIDEO_HEIGHT_char
 mov rdi, KERNEL_VIDEO_BASE_address
 rep stosw

 mov qword [kernel_video_pointer], KERNEL_VIDEO_BASE_address

 mov qword [kernel_video_cursor], STATIC_EMPTY

 call kernel_video_cursor_set

 pop rdi
 pop rcx
 pop rax

 ret

kernel_video_cursor_set:
 push rax
 push rcx
 push rdx

 mov eax, KERNEL_VIDEO_WIDTH_char
 mul dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte]
 add eax, dword [kernel_video_cursor]

 push rax

 mov cx, ax

 mov al, 0x0F
 mov dx, 0x03D4
 out dx, al

 inc dx
 mov al, cl
 out dx, al

 mov al, 0x0E
 dec dx
 out dx, al

 inc dx
 mov al, ch
 out dx, al

 pop rax

 shl rax, STATIC_MULTIPLE_BY_2_shift
 add rax, KERNEL_VIDEO_BASE_address
 mov qword [kernel_video_pointer], rax

 pop rdx
 pop rcx
 pop rax

 ret

kernel_video_string:
 push rax
 push rbx
 push rcx
 push rdx
 push rsi

 test rcx, rcx
 jz .end

 mov ah, byte [kernel_video_char_color_and_background]

.loop:
 lodsb

 test al, al
 jz .end

 cmp al, STATIC_ASCII_BACKSLASH
 jne .no

 cmp rcx, STATIC_ASCII_SEQUENCE_length
 jb .fail

 push rdi
 push rsi
 push rcx

 dec rsi

 mov ecx, STATIC_ASCII_SEQUENCE_length

.default:
 mov rdi, kernel_video_color_sequence_default
 call library_string_compare
 jc .black

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_default

 jmp .done

.black:
 mov rdi, kernel_video_color_sequence_black
 call library_string_compare
 jc .blue

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_black

 jmp .done

.blue:
 mov rdi, kernel_video_color_sequence_blue
 call library_string_compare
 jc .green

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_blue

 jmp .done

.green:
 mov rdi, kernel_video_color_sequence_green
 call library_string_compare
 jc .cyan

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_green

 jmp .done

.cyan:
 mov rdi, kernel_video_color_sequence_cyan
 call library_string_compare
 jc .red

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_cyan

 jmp .done

.red:
 mov rdi, kernel_video_color_sequence_red
 call library_string_compare
 jc .magenta

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_red

 jmp .done

.magenta:
 mov rdi, kernel_video_color_sequence_magenta
 call library_string_compare
 jc .brown

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_magenta

 jmp .done

.brown:
 mov rdi, kernel_video_color_sequence_brown
 call library_string_compare
 jc .gray_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_brown

 jmp .done

.gray_light:
 mov rdi, kernel_video_color_sequence_gray_light
 call library_string_compare
 jc .gray

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_gray_light

 jmp .done

.gray:
 mov rdi, kernel_video_color_sequence_gray
 call library_string_compare
 jc .blue_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_gray

 jmp .done

.blue_light:
 mov rdi, kernel_video_color_sequence_blue_light
 call library_string_compare
 jc .green_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_blue_light

 jmp .done

.green_light:
 mov rdi, kernel_video_color_sequence_green_light
 call library_string_compare
 jc .cyan_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_green_light

 jmp .done

.cyan_light:
 mov rdi, kernel_video_color_sequence_cyan_light
 call library_string_compare
 jc .red_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_cyan_light

 jmp .done

.red_light:
 mov rdi, kernel_video_color_sequence_red_light
 call library_string_compare
 jc .magenta_light

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_red_light

 jmp .done

.magenta_light:
 mov rdi, kernel_video_color_sequence_magenta_light
 call library_string_compare
 jc .yellow

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_magenta_light

 jmp .done

.yellow:
 mov rdi, kernel_video_color_sequence_yellow
 call library_string_compare
 jc .white

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_yellow

 jmp .done

.white:
 mov rdi, kernel_video_color_sequence_white
 call library_string_compare
 jc .fail

 mov byte [kernel_video_char_color_and_background], STATIC_COLOR_white

.done:
 sub qword [rsp], STATIC_ASCII_SEQUENCE_length - 0x01
 add qword [rsp + STATIC_QWORD_SIZE_byte], STATIC_ASCII_SEQUENCE_length - 0x01

.fail:
 pop rcx
 pop rsi
 pop rdi

 jnc .continue

.no:
 push rcx

 mov ecx, 1
 call kernel_video_char

 pop rcx

.continue:
 dec rcx
 jnz .loop

.end:
 pop rsi
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ret

kernel_video_char:
 push rax
 push rbx
 push rcx
 push rdx
 push rdi

 mov ah, byte [kernel_video_char_color_and_background]

 mov ebx, dword [kernel_video_cursor]
 mov edx, dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte]

 mov rdi, qword [kernel_video_pointer]

.loop:
 cmp al, STATIC_ASCII_NEW_LINE
 je .new_line

 cmp al, STATIC_ASCII_BACKSPACE
 je .backspace

 stosw

 inc ebx

 cmp ebx, KERNEL_VIDEO_WIDTH_char
 jb .continue

 sub ebx, KERNEL_VIDEO_WIDTH_char
 inc edx

.row:
 cmp edx, KERNEL_VIDEO_HEIGHT_char
 jb .continue

 dec edx

 sub rdi, KERNEL_VIDEO_LINE_SIZE_byte

 call kernel_video_scroll

.continue:
 dec rcx
 jnz .loop

 mov dword [kernel_video_cursor], ebx
 mov dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte], edx

 mov qword [kernel_video_pointer], rdi

 call kernel_video_cursor_set

 pop rdi
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ret

.new_line:
 push rax

 mov eax, ebx
 shl eax, STATIC_MULTIPLE_BY_2_shift
 sub rdi, rax
 xor ebx, ebx

 inc edx
 add rdi, KERNEL_VIDEO_LINE_SIZE_byte

 pop rax

 jmp .row

.backspace:
 test ebx, ebx
 jz .begin

 dec ebx

 jmp .clear

.begin:
 test edx, edx
 jz .clear

 dec edx

 mov ebx, KERNEL_VIDEO_WIDTH_char - 0x01

.clear:
 sub rdi, KERNEL_VIDEO_CHAR_SIZE_byte

 mov word [rdi], 0x0720

 jmp .continue

kernel_video_number:
 push rax
 push rdx
 push rbp
 push r8
 push r9

 cmp bl, 2
 jb .error
 cmp bl, 36
 ja .error

 mov r8, rdx
 sub r8, 0x30

 xor rdx, rdx

 mov rbp, rsp

.loop:
 div rbx

 push rdx
 dec rcx

 xor rdx, rdx

 test rax, rax
 jnz .loop

 cmp rcx, STATIC_EMPTY
 jle .print

.prefix:
 push r8

 dec rcx
 jnz .prefix

.print:
 mov ecx, 0x01

 cmp rsp, rbp
 je .end

 pop rax

 add rax, 0x30

 cmp al, 0x3A
 jb .no

 add al, 0x07

.no:
 call kernel_video_char

 jmp .print

.error:
 stc

.end:
 pop r9
 pop r8
 pop rbp
 pop rdx
 pop rax

 ret

kernel_video_scroll:
 push rcx
 push rsi
 push rdi

 mov ecx, (KERNEL_VIDEO_SIZE_byte - KERNEL_VIDEO_LINE_SIZE_byte) >> STATIC_DIVIDE_BY_2_shift
 mov rdi, KERNEL_VIDEO_BASE_address
 mov rsi, KERNEL_VIDEO_BASE_address + KERNEL_VIDEO_LINE_SIZE_byte
 rep movsw

 mov al, STATIC_ASCII_SPACE
 mov ah, STATIC_COLOR_default
 mov ecx, KERNEL_VIDEO_LINE_SIZE_byte >> STATIC_DIVIDE_BY_2_shift
 rep stosw

 pop rdi
 pop rsi
 pop rcx

 ret
