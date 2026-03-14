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

kernel_init_video_string_welcome db "welcome cik", STATIC_ASCII_NEW_LINE
kernel_init_video_string_welcome_end:

kernel_init_memory_string_error db "Error: memory map error"
kernel_init_memory_string_error_end:

kernel_init_string_error_acpi db "Error: ACPI table not found"
kernel_init_string_error_acpi_end:

kernel_init_string_error_acpi_2 db "Error: no support for acpi v2 version"
kernel_init_string_error_acpi_2_end:

kernel_init_string_error_acpi_corrupted db "Error: APIC table not found"
kernel_init_string_error_acpi_corrupted_end:

kernel_init_string_error_apic db "Error: APIC table not found"
kernel_init_string_error_apic_end:

kernel_init_string_error_ioapic db "Error: I / O APIC table not found"
kernel_init_string_error_ioapic_end:

kernel_init_apic_semaphore db STATIC_FALSE
kernel_init_ioapic_semaphore db STATIC_FALSE
kernel_init_smp_semaphore db STATIC_FALSE
kernel_init_ap_count db STATIC_EMPTY

kernel_init_apic_id_highest db STATIC_EMPTY
