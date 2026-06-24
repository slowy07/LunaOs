kernel_init_string db STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GREEN_LIGHT, " Made By - Arfy Slowy", STATIC_ASCII_NEW_LINE
 db STATIC_COLOR_ASCII_GRAY, " ---------- ", STATIC_ASCII_NEW_LINE, STATIC_ASCII_NEW_LINE
kernel_init_string_end:

init_program_shell db "/bin/shell"
init_program_shell_end:

