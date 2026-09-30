
 ; create the window
 mov rsi, calculator_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu
 jc calculator.close ; not enough memory space

 ; display the window
 mov al, KERNEL_WM_WINDOW_update
 or qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags], LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
 int KERNEL_WM_IRQ

 ; initialize the coprocessor mode
 finit
 fstcw word [calculator_fpu_control] ; store the coprocessor flags in the variable
 or word [calculator_fpu_control], 110000000000b ; do not store the value after the comma
 fldcw word [calculator_fpu_control] ; load the new coprocessor flags from the variable
