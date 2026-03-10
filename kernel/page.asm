; Copyright (c) 2026 arfy slowy
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.


KERNEL_PAGE_FLAG_available equ 0x01
KERNEL_PAGE_FLAG_write equ 0x02
KERNEL_PAGE_FLAG_user equ 0x04
KERNEL_PAGE_FLAG_write_trough equ 0x08
KERNEL_PAGE_FLAG_cache_disable equ 0x10
KERNEL_PAGE_FLAG_length equ 0x80

KERNEL_PAGE_RECORDS_amount equ 512

KERNEL_PAGE_PML4_SIZE_byte equ KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML3_SIZE_byte
KERNEL_PAGE_PML3_SIZE_byte equ KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML2_SIZE_byte
KERNEL_PAGE_PML2_SIZE_byte equ KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML1_SIZE_byte
KERNEL_PAGE_PML1_SIZE_byte equ KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_SIZE_byte

kernel_page_pml4_address dq STATIC_EMPTY
kernel_page_total_count dq STATIC_EMPTY
kernel_page_free_count dq STATIC_EMPTY
kernel_page_reserved_count dq STATIC_EMPTY
kernel_page_paged_count dq STATIC_EMPTY

kernel_page_drain:
  push rcx

  mov rcx, KERNEL_PAGE_SIZE_byte

  call .proceed
  pop rcx

  ret

.proceed:
  push rax
  push rdi

  xor rax, rax
  shr rcx, STATIC_DIVIDE_BY_8_shift
  and di, KERNEL_PAGE_mask
  rep stosq

  pop rdi
  pop rax

  ret

kernel_page_drain_few:
  push rcx

  shl rcx, KERNEL_PAGE_SIZE_shift
  call kernel_page_drain.proceed
  
  pop rcx

  ret
