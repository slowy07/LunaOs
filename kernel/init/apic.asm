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

kernel_init_apic:
  mov rsi, qword [kernel_apic_base_address]

  mov dword [rsi + KERNEL_APIC_TP_register], STATIC_EMPTY

  mov dword [rsi + KERNEL_APIC_DF_register], KERNEL_APIC_DF_FLAG_flat_mode

  mov dword [rsi + KERNEL_APIC_LD_register], KERNEL_APIC_LD_FLAG_target_cpu

  mov eax, dword [rsi + KERNEL_APIC_SIV_register]
  or eax, KERNEL_APIC_SIV_FLAG_enable_apic | KERNEL_APIC_SIV_FLAG_spurious_vector
  mov dword [rsi + KERNEL_APIC_SIV_register], eax

  mov eax, dword [rsi + KERNEL_APIC_LVT_TR_register]
  and eax, ~KERNEL_APIC_LVT_TR_FLAG_mask_interrupts
  mov dword [rsi + KERNEL_APIC_LVT_TR_register], eax

  mov dword [rsi + KERNEL_APIC_TDC_register], KERNEL_APIC_TDC_divide_by_16

  sti

  ret
