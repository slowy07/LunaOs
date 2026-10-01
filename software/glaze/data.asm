align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
glaze_window dw STATIC_EMPTY ; position on the X axis
 dw STATIC_EMPTY ; position on the Y axis
 dw GLAZE_WINDOW_WIDTH_pixel ; window width
 dw GLAZE_WINDOW_HEIGHT_pixel ; window height
 dq STATIC_EMPTY ; pointer to the window data space (filled in by Bosu)
.extra: dd STATIC_EMPTY ; size of the window data space in bytes (filled in by Bosu)
 dw LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_border
 dq STATIC_EMPTY ; window identifier (filled in by Bosu)
 db 5
 db "Glaze                          " ; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
 dq STATIC_EMPTY ; window data space width in bytes (filled in by Bosu)
.elements: ; end of the window elements
 db STATIC_EMPTY
glaze_window_end: