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

%include "config.asm"
%include "kernel/config.asm"

[BITS 32]

[ORG KERNEL_BASE_address]

init:
  %include "kernel/init.asm"

clean:

kernel:
  jmp $

  %include "kernel/macro/close.asm"
  %include "kernel/macro/apic.asm"
  
  ; kernel root
  %include "kernel/panic.asm"
  %include "kernel/page.asm"
  %include "kernel/memory.asm"
  %include "kernel/video.asm"
  %include "kernel/apic.asm"
  %include "kernel/io_apic.asm"
  %include "kernel/data.asm"
  %include "kernel/idt.asm"
  %include "kernel/task.asm"
  
  ; driver
  %include "kernel/driver/rtc.asm"
  %include "kernel/driver/ps2.asm"

  ; library
  %include "library/page_align_up.asm"
  %include "library/page_from_size.asm"

kernel_end:
