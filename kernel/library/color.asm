
; input:
;	rsi - weighted color
;	rdi - base color
; output:
;	eax - color combined through the alpha channel
library_color_alpha:
 ; preserve the original registers
 push rbx
 push rcx
 push rdx

 ; local variable
 push STATIC_EMPTY

 ; weight (alpha channel)
 movzx rbx, byte [rsi + 0x03]

 ; invert the alpha channel, I use the reversed notation 0..visible, 255..invisible
 not bl
 inc bl

 ; red ------------------------------------------------------------------
 movzx rax, byte [rsi + 0x02]

 ; weighting
 mul bl
 mov cl, STATIC_BYTE_mask
 xor dl, dl
 div cl

 ; partial result
 mov byte [rsp + 0x02], al

 ; green ----------------------------------------------------------------
 mov al, byte [rsi + 0x01]

 ; weighting
 mul bl
 xor dl, dl
 div cl

 ; partial result
 mov byte [rsp + 0x01], al

 ; blue -----------------------------------------------------------------
 mov al, byte [rsi]

 ; weighting
 mul bl
 xor dl, dl
 div cl

 ; partial result
 mov byte [rsp], al

 ; invert the alpha channel
 sub bl, STATIC_BYTE_mask
 not bl
 inc bl

 ; base red -------------------------------------------------------------
 mov al, byte [rdi + 0x02]

 ; weighting
 mul bl
 xor dl, dl
 div cl

 ; partial result
 add byte [rsp + 0x02], al

 ; base green -----------------------------------------------------------
 mov al, byte [rdi + 0x01]

 ; weighting
 mul bl
 xor dl, dl
 div cl

 ; partial result
 add byte [rsp + 0x01], al

 ; base blue ------------------------------------------------------------
 mov al, byte [rdi]

 ; weighting
 mul bl
 xor dl, dl
 div cl

 ; partial result
 add byte [rsp], al

 ; return the result
 pop rax

 ; restore the original registers
 pop rdx
 pop rcx
 pop rbx

 ; return from the procedure
 ret

 ; information for Bochs
 macro_debug "library_color_alpha"

; input:
;	rcx - amount of image data in bytes
;	rsi - pointer to the image data
library_color_alpha_invert:
 ; preserve the original registers
 push rax
 push rcx
 push rsi

 ; convert the size into a pixel count
 shr rcx, KERNEL_VIDEO_DEPTH_shift

.loop:
 ; fetch the alpha channel value
 mov al, byte [rsi + 0x03]

 ; value completely invisible?
 test al, al
 jz .invisible ; yes

 ; fix up the value
 dec al

.invisible:
 ; invert the value
 not al

 ; put it back in place
 mov byte [rsi + 0x03], al

 ; move the pointer to the next alpha channel value
 add rsi, KERNEL_VIDEO_DEPTH_byte

 ; process further pixels?
 dec rcx
 jnz .loop ; yes

 ; restore the original registers
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

 ; information for Bochs
 macro_debug "library_color_alpha_invert"
