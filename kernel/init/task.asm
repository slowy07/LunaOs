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

kernel_init_task:
  movzx ecx, byte [kernel_init_apic_id_highest]
  inc cx

  shl ecx, STATIC_MULTIPLE_BY_8_shift

  call library_page_from_size

  call kernel_memory_alloc
  jc kernel_init_panic_low_memory

  mov qword [kernel_task_active_list], rdi

  mov rsi, rdi

  call kernel_memory_alloc_page
  jc kernel_init_panic_low_memory

  call kernel_page_drain

  mov qword [kernel_task_address], rdi

  mov qword [rdi + STATIC_STRUCTURE_BLOCK.link], rdi

  call kernel_apic_id_get

  shl rax, STATIC_MULTIPLE_BY_8_shift
  mov qword [rsi + rax], rdi

  mov ebx, KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_daemon | KERNEL_TASK_FLAG_secured | KERNEL_TASK_FLAG_processing
  mov r11, qword [kernel_page_pml4_address]
  call kernel_task_add

  mov rax, KERNEL_APIC_IRQ_number
  mov bx, KERNEL_IDT_TYPE_irq
  mov rdi, kernel_task
  call kernel_idt_mount
