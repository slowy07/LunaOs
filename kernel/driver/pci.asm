
DRIVER_PCI_PORT_command equ 0x0CF8
DRIVER_PCI_PORT_data equ 0x0CFC

DRIVER_PCI_REGISTER_vendor_and_device equ 0x00
DRIVER_PCI_REGISTER_status_and_command equ 0x04
DRIVER_PCI_REGISTER_class_and_subclass equ 0x08
DRIVER_PCI_REGISTER_bar0 equ 0x10
DRIVER_PCI_REGISTER_bar1 equ 0x14
DRIVER_PCI_REGISTER_bar2 equ 0x18
DRIVER_PCI_REGISTER_bar3 equ 0x1C
DRIVER_PCI_REGISTER_bar4 equ 0x20
DRIVER_PCI_REGISTER_bar5 equ 0x24
DRIVER_PCI_REGISTER_irq equ 0x3C
DRIVER_PCI_REGISTER_FLAG_64_bit equ 00000010b

DRIVER_PCI_CLASS_SUBCLASS_ide equ 0x0101
DRIVER_PCI_CLASS_SUBCLASS_ahci equ 0x0106
DRIVER_PCI_CLASS_SUBCLASS_scsi equ 0x0107
DRIVER_PCI_CLASS_SUBCLASS_network equ 0x0200

; input:
;	eax - value to look for
;		high - device
;		low - vendor
; output:
;	CF flag, set if not found
;	ebx - szyna
;	ecx - device
;	edx - function
driver_pci_find_vendor_and_device:
 ; zachowaj oryginalne rejestry
 push rbx
 push rcx
 push rdx
 push rax

 ; bus 0
 xor ebx, ebx
 ; device 0
 xor ecx, ecx
 ; function 0
 xor edx, edx

.next:
 ; read the Vendor & Device register
 mov eax, DRIVER_PCI_REGISTER_vendor_and_device
 call driver_pci_read

 ; looking for Vendor and Device?
 cmp eax, dword [rsp]
 je .found ; yes

 ; next function
 inc edx

 ; end of the functions scanned?
 cmp edx, 0x0008
 jb .next ; no

 ; next device on the bus
 inc ecx

 ; first function of the device
 xor edx, edx

 ; end of the devices on this bus?
 cmp ecx, 0x0020
 jb .next ; no

 ; next bus
 inc ebx

 ; first device on the bus
 xor ecx, ecx

 ; end of the available buses?
 cmp ebx, 0x0100
 jb .next ; no

.error:
 ; flag, error
 stc

 ; end
 jmp .end

.found:
 ; read the Vendor & Device register
 mov eax, DRIVER_PCI_REGISTER_bar0
 call driver_pci_read

 ; return the device location information
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rdx
 mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x02], rcx
 mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x03], rbx

 ; flag, success
 clc

.end:
 ; restore the original registers
 pop rax
 pop rdx
 pop rcx
 pop rbx

 ; return from the procedure
 ret

; input:
;	ax - Class & Subclass value to look for
; output:
;	CF flag, set if not found
;	ebx - szyna
;	ecx - device
;	edx - function
driver_pci_find_class_and_subclass:
 ; zachowaj oryginalne rejestry
 push rbx
 push rcx
 push rdx
 push rax

 ; bus 0
 xor ebx, ebx
 ; device 0
 xor ecx, ecx
 ; function 0
 xor edx, edx

.next:
 ; read the Class & Subclass register
 mov eax, DRIVER_PCI_REGISTER_class_and_subclass
 call driver_pci_read

 ; shift the value into AX
 shr eax, STATIC_MOVE_HIGH_TO_AX_shift

 ; IDE controller?
 cmp ax, word [rsp]
 je .found ; yes

 ; next function
 inc edx

 ; end of the functions scanned?
 cmp edx, 0x0008
 jb .next ; no

 ; next device on the bus
 inc ecx

 ; first function of the device
 xor edx, edx

 ; end of the devices on this bus?
 cmp ecx, 0x0020
 jb .next ; no

 ; next bus
 inc ebx

 ; first device on the bus
 xor ecx, ecx

 ; end of the available buses?
 cmp ebx, 0x0100
 jb .next ; no

.error:
 ; flag, error
 stc

 ; end
 jmp .end

.found:
 ; return the device location information
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rdx
 mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x02], rcx
 mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x03], rbx

 ; flag, success
 clc

.end:
 ; restore the original registers
 pop rax
 pop rdx
 pop rcx
 pop rbx

 ; return from the procedure
 ret

; input:
;	eax - address of the register to read
;	bl - szyna
;	cl - device
;	dl - funkcja
; output:
;	eax - response
driver_pci_read:
 ; zachowaj oryginalne rejestry
 push rbx
 push rcx
 push rdx

 ; set bit 31
 or eax, 0x80000000

 ; load the function number into bits 10..8
 ror eax, 8
 or al, dl

 ; load the device number into bits 15..11
 ror eax, 3
 or al, cl

 ; load the bus number into bits 23..16
 ror eax, 5
 or al, bl

 ; register number in bits 7..2
 rol eax, 16

 ; ask for the information in the given register
 mov dx, DRIVER_PCI_PORT_command
 out dx, eax ; send the command

 ; receive the response
 mov dx, DRIVER_PCI_PORT_data
 in eax, dx

 ; restore the original registers
 pop rdx
 pop rcx
 pop rbx

 ; return from the procedure
 ret

; input:
;	eax - value
;
;	bl - szyna
;	cl - device
;	dl - funkcja
driver_pci_write:
 ; zachowaj oryginalne rejestry
 push rbx
 push rcx
 push rdx
 push rax

 ; set bit 31
 or eax, 0x80000000

 ; load the function number into bits 10..8
 ror eax, 8
 or al, dl

 ; load the device number into bits 15..11
 ror eax, 3
 or al, cl

 ; load the bus number into bits 23..16
 ror eax, 5
 or al, bl

 ; register number in bits 7..2
 rol eax, 16

 ; ask for the data from the register
 mov dx, DRIVER_PCI_PORT_command
 out dx, eax

 ; restore the value to be sent
 pop rax

 ; send
 mov dx, DRIVER_PCI_PORT_data
 out dx, eax

 ; restore the original registers
 pop rdx
 pop rcx
 pop rbx

 ; return from the procedure
 ret
