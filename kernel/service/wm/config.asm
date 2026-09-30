
KERNEL_WM_OBJECT_NAME_length equ 31

KERNEL_WM_OBJECT_FLAG_flush equ 1 << 0 ; the object has been updated
 ; the flags below are reserved for the GUI
KERNEL_WM_OBJECT_FLAG_visible equ 1 << 1 ; the object is visible
KERNEL_WM_OBJECT_FLAG_fixed_xy equ 1 << 2 ; the object is fixed on the X,Y axis
KERNEL_WM_OBJECT_FLAG_fixed_z equ 1 << 3 ; the object is fixed on the Z axis
KERNEL_WM_OBJECT_FLAG_fragile equ 1 << 4 ; the object is hidden on the occurrence of an LMB or RMB action
KERNEL_WM_OBJECT_FLAG_pointer equ 1 << 5 ; the object of the "cursor" type
KERNEL_WM_OBJECT_FLAG_arbiter equ 1 << 6 ; superobject
KERNEL_WM_OBJECT_FLAG_undraw equ 1 << 7 ; redraw the space under the object

; the last element of the list is always empty
KERNEL_WM_OBJECT_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE) - 0x01
KERNEL_WM_FILL_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_FILL.SIZE) - 0x01
KERNEL_WM_ZONE_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_ZONE.SIZE) - 0x01

KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift equ STATIC_MULTIPLE_BY_8_shift

 struc KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY
.object_address resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_FIELD
.x resb 2
.y resb 2
.width resb 2
.height resb 2
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_OBJECT
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.address resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_OBJECT_EXTRA
.size resb 4
.flags resb 2
.id resb 8
.length resb 1
.name resb KERNEL_WM_OBJECT_NAME_length
 ;--- data specific to the WM
.pid resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_FILL
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.object resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_ZONE
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.object resb 8
.SIZE:
 endstruc
