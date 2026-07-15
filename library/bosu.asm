 %include "library/bosu/config.asm"
 %include "library/bosu/font.asm"

library_bosu:
 push rax
 push rbx
 push rcx
 push rdi
 push rsi

 pop rsi
 pop rdi
 pop rcx
 pop rbx
 pop rax

 ret
