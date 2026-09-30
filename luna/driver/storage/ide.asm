
DRIVER_IDE_CHANNEL_PRIMARY equ 0x01F0
DRIVER_IDE_CHANNEL_SECONDARY equ 0x0170

DRIVER_IDE_REGISTER_data equ 0x0000
DRIVER_IDE_REGISTER_error equ 0x0001
DRIVER_IDE_REGISTER_sector_count_0 equ 0x0002
DRIVER_IDE_REGISTER_lba0 equ 0x0003
DRIVER_IDE_REGISTER_lba1 equ 0x0004
DRIVER_IDE_REGISTER_lba2 equ 0x0005
DRIVER_IDE_REGISTER_drive_OR_head equ 0x0006
DRIVER_IDE_REGISTER_command_OR_status equ 0x0007
DRIVER_IDE_REGISTER_channel_control_OR_altstatus equ 0x0206

DRIVER_IDE_DRIVE_master equ 11100000b
DRIVER_IDE_DRIVE_slave equ 11110000b

DRIVER_IDE_CONTROL_nIEN equ 00000010b
DRIVER_IDE_CONTROL_SRST equ 00000100b

DRIVER_IDE_COMMAND_ATAPI_eject equ 0x1B
DRIVER_IDE_COMMAND_read_pio equ 0x20
DRIVER_IDE_COMMAND_read_pio_extended equ 0x24
DRIVER_IDE_COMMAND_read_dma_extended equ 0x25
DRIVER_IDE_COMMAND_write_pio equ 0x30
DRIVER_IDE_COMMAND_write_pio_extended equ 0x34
DRIVER_IDE_COMMAND_write_dma_extended equ 0x35
DRIVER_IDE_COMMAND_packet equ 0xA0
DRIVER_IDE_COMMAND_identify_packet equ 0xA1
DRIVER_IDE_COMMAND_ATAPI_read equ 0xA8
DRIVER_IDE_COMMAND_read_dma equ 0xC8
DRIVER_IDE_COMMAND_write_dma equ 0xCA
DRIVER_IDE_COMMAND_cache_flush equ 0xE7
DRIVER_IDE_COMMAND_cache_flush_extended equ 0xEA
DRIVER_IDE_COMMAND_identify equ 0xEC

DRIVER_IDE_IDENTIFY_device_type equ 0x00
DRIVER_IDE_IDENTIFY_cylinders equ 0x02
DRIVER_IDE_IDENTIFY_heads equ 0x06
DRIVER_IDE_IDENTIFY_sectors equ 0x0C
DRIVER_IDE_IDENTIFY_serial equ 0x14
DRIVER_IDE_IDENTIFY_model equ 0x36
DRIVER_IDE_IDENTIFY_capabilities equ 0x62
DRIVER_IDE_IDENTIFY_field_valid equ 0x6A
DRIVER_IDE_IDENTIFY_max_lba equ 0x78
DRIVER_IDE_IDENTIFY_command_sets equ 0xA4
DRIVER_IDE_IDENTIFY_max_lba_extended equ 0xC8

DRIVER_IDE_IDENTIFY_COMMAND_SETS_lba_extended equ 1 << 26

DRIVER_IDE_STATUS_error equ 00000001b ; ERR
DRIVER_IDE_STATUS_index equ 00000010b
DRIVER_IDE_STATUS_corrected_data equ 00000100b
DRIVER_IDE_STATUS_data_ready equ 00001000b ; DRQ
DRIVER_IDE_STATUS_seek_complete equ 00010000b ; SRV
DRIVER_IDE_STATUS_write_fault equ 00100000b ; DF
DRIVER_IDE_STATUS_ready equ 01000000b ; RDY
DRIVER_IDE_STATUS_busy equ 10000000b ; BSY

DRIVER_IDE_ERROR_no_address_mark equ 00000001b
DRIVER_IDE_ERROR_track_0_not_found equ 00000010b
DRIVER_IDE_ERROR_command_aborted equ 00000100b
DRIVER_IDE_ERROR_media_change_request equ 00001000b
DRIVER_IDE_ERROR_id_mark_not_found equ 00010000b
DRIVER_IDE_ERROR_media_changed equ 00100000b
DRIVER_IDE_ERROR_uncorrectble_data equ 01000000b
DRIVER_IDE_ERROR_bad_block equ 10000000b

struc DRIVER_IDE_STRUCTURE_DEVICE
      .size_sectors resb 8
      .channel resb 2
      .drive resb 1
      .reserved resb 5
      .SIZE:
endstruc

driver_ide_devices_count db 0x00

; bring the table position to a full address
align 0x10, db 0x90
driver_ide_devices:
      times DRIVER_IDE_STRUCTURE_DEVICE.SIZE * 0x04 db 0x00

; in:
;	rax - number of the first sector to read (LBA)
;	rbx - drive identifier
;	rcx - total number of sectors
;	rdi - destination pointer for the read data
; out:
;	; the CF flag is set on a read error or a missing drive
driver_ide_read:
      ; preserve the original registers
      push rax
      push rbx
      push rcx
      push rdx
      push rdi
      push rax

      ; by default: set the flag, error
      stc

      ; identifier valid?
      cmp rbx, 0x04 ; maximum number of drives
      jnb .end ; no

      ; convert the identifier into a pointer
      shl bl, 4
      add rbx, driver_ide_devices

      ; select the drive and switch it to LBA mode
      mov al, byte [rbx + DRIVER_IDE_STRUCTURE_DEVICE.drive]
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_drive_OR_head
      out dx, al

      ; wait for the drive to become ready
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      call driver_ide_pool
      jc .end ; error

      ; restore the first sector number
      pop rax

      ; send the sector count and the first sector to read
      call driver_ide_lba

      ; wait for the drive to become ready
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      call driver_ide_pool
      jc .end ; error

      ; issue the extended PIO read command
      mov al, DRIVER_IDE_COMMAND_read_pio_extended
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_command_OR_status
      out dx, al

      ; wait for the drive to become ready
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      call driver_ide_pool
      jc .end ; error

.read:
      ; read the first sector
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_data

      ; preserve the remaining number of sectors to read
      push rcx

      ; fetch 256 words from the drive
      mov rcx, 256
      rep insw

      ; restore the remaining number of sectors to read
      pop rcx

      ; all sectors read?
      dec rcx
      jnz .read ; no

.end:
      ; restore the original registers
      pop rdi
      pop rdx
      pop rcx
      pop rbx
      pop rax

      ; return from the routine
      ret

; in:
;	rax - numer pierwszego sektora do odczytu w postaci LBA
;	rbx - pointer to the drive identifier
;	cl - number of consecutive sectors to read
driver_ide_lba:
      ; preserve the original registers
      push rbx
      push rdx
      push rax

      ; high part of the sector count to read
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_sector_count_0
      mov al, 0x00
      out dx, al

      ; send the top 24 bits of the sector number

      ; al = 31..24
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba0
      mov rax, qword [rsp]
      shr rax, 24
      out dx, al

      ; al = 39..32
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba1
      mov rax, qword [rsp]
      shr rax, 32
      out dx, al

      ; al = 47..40
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba2
      mov rax, qword [rsp]
      shr rax, 40
      out dx, al

      ; low part of the sector count to read
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_sector_count_0
      mov al, cl
      out dx, al

      ; al = 7..0
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba0
      mov al, byte [rsp]
      out dx, al

      ; al = 15..8
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba1
      mov ax, word [rsp]
      shr ax, 8
      out dx, al

      ; al = 23..16
      mov dx, word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
      add dx, DRIVER_IDE_REGISTER_lba2
      mov eax, dword [rsp]
      shr eax, 16
      out dx, al

      ; restore the original registers
      pop rax
      pop rdx
      pop rbx

      ; return from the routine
      ret

driver_ide_init:
      ; preserve the original registers
      push rax
      push rdx
      push rdi

      ; point at the work area
      mov rdi, 0x8000

      ; disable the interrupts on the PRIMARY channel
      mov al, DRIVER_IDE_CONTROL_nIEN
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY + DRIVER_IDE_REGISTER_channel_control_OR_altstatus
      out dx, al

      ; czekaj na wykonanie polecenia
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY
      call driver_ide_pool
      jc .next ; no devices on the channel

      ; put the devices on the channel into RESET mode
      mov al, DRIVER_IDE_CONTROL_SRST
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY + DRIVER_IDE_REGISTER_channel_control_OR_altstatus
      out dx, al

      ; leave RESET mode
      xor al, al
      out dx, al

      ; czekaj na wykonanie polecenia
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY
      call driver_ide_pool

      ; initialise the MASTER device on the PRIMARY channel
      mov al, DRIVER_IDE_DRIVE_master
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY
      call driver_ide_init_drive

      ; initialise the SLAVE device on the PRIMARY channel
      mov al, DRIVER_IDE_DRIVE_slave
      mov dx, DRIVER_IDE_CHANNEL_PRIMARY
      call driver_ide_init_drive

.next:
      ; disable the interrupts on the SECONDARY channel
      mov al, DRIVER_IDE_CONTROL_nIEN
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY + DRIVER_IDE_REGISTER_channel_control_OR_altstatus
      out dx, al

      ; czekaj na wykonanie polecenia
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY
      call driver_ide_pool
      jc .end ; no devices on the channel

      ; put the devices on the channel into RESET mode
      mov al, DRIVER_IDE_CONTROL_SRST
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY + DRIVER_IDE_REGISTER_channel_control_OR_altstatus
      out dx, al

      ; leave RESET mode
      xor al, al
      out dx, al

      ; czekaj na wykonanie polecenia
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY
      call driver_ide_pool

      ; initialise the MASTER device on the SECONDARY channel
      mov al, DRIVER_IDE_DRIVE_master
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY
      call driver_ide_init_drive

      ; initialise the SLAVE device on the SECONDARY channel
      mov al, DRIVER_IDE_DRIVE_slave
      mov dx, DRIVER_IDE_CHANNEL_SECONDARY
      call driver_ide_init_drive

.end:
      ; restore the original registers
      pop rdi
      pop rdx
      pop rax

      ; return from the routine
      ret

; in:
;	al - MASTER or SLAVE device
;	dx - PRIMARY or SECONDARY channel
driver_ide_init_drive:
      ; preserve the original registers
      push rcx
      push rax
      push rdi
      push rdx

      ; select device X on channel Y
      add dx, DRIVER_IDE_REGISTER_drive_OR_head
      out dx, al

      ; odczekaj na wykonanie polecenia
      mov dx, word [rsp]
      call driver_ide_pool
      jc .end ; no device

      ; send the IDENTIFY command	; channel
      mov al, DRIVER_IDE_COMMAND_identify
      mov dx, word [rsp]
      add dx, DRIVER_IDE_REGISTER_command_OR_status
      out dx, al

      ; odczekaj na wykonanie polecenia
      mov dx, word [rsp]
      call driver_ide_pool
      jc .end ; the IDENTIFY command is unsupported

      ; receive the data pending from the IDENTIFY command
      mov ecx, 256 ; 512 bytes
      mov dx, word [rsp]
      add dx, DRIVER_IDE_REGISTER_data
      rep insw

      ; restore the pointer to the start of the work area
      mov rdi, qword [rsp + 0x08]

      ; does the device support LBA Extended mode?
      mov eax, dword [rdi + DRIVER_IDE_IDENTIFY_command_sets]
      test eax, DRIVER_IDE_IDENTIFY_COMMAND_SETS_lba_extended
      jz .end ; no

      ; drive initialised, register it
      mov rcx, driver_ide_devices

      ; channel
      mov dx, word [rsp]
      cmp dx, DRIVER_IDE_CHANNEL_PRIMARY
      je .primary ; yes

      ; no, advance to the SECONDARY entry
      add rcx, DRIVER_IDE_STRUCTURE_DEVICE.SIZE << 1

.primary:
      ; MASTER drive?
      mov al, byte [rsp + 0x08 * 0x02]
      cmp al, DRIVER_IDE_DRIVE_master
      je .master ; yes

      ; no, advance to the SLAVE entry
      add rcx, DRIVER_IDE_STRUCTURE_DEVICE.SIZE

.master:
      ; store the drive channel
      mov word [rcx + DRIVER_IDE_STRUCTURE_DEVICE.channel], dx

      ; store the drive device
      mov byte [rcx + DRIVER_IDE_STRUCTURE_DEVICE.drive], al

      ; store the drive size in sectors
      mov eax, dword [rdi + DRIVER_IDE_IDENTIFY_max_lba_extended]
      mov qword [rcx + DRIVER_IDE_STRUCTURE_DEVICE.size_sectors], rax

      ; data drive registered
      inc byte [rel driver_ide_devices_count]

.end:
      ; restore the original registers
      pop rdx
      pop rdi
      pop rax
      pop rcx

      ; return from the routine
      ret

; in:
;	dx - drive identifier
driver_ide_pool:
      ; preserve the original registers
      push rax
      push rdx

      ; defer the channel status check
      add dx, DRIVER_IDE_REGISTER_channel_control_OR_altstatus
      in al, dx
      in al, dx
      in al, dx
      in al, dx

      ; no devices?
      test al, al
      jz .error ; yes

      ; no devices?
      cmp al, 0xFF
      jne .wait ; yes

.error:
      ; set the flag, error
      stc

      ; end of routine processing
      jmp .end

.wait:
      ; fetch the state of the devices on the channel
      in al, dx
      and al, DRIVER_IDE_STATUS_busy | DRIVER_IDE_STATUS_ready
      cmp al, DRIVER_IDE_STATUS_ready
      jne .wait ; devices still not ready, wait

      ; flaga, sukces
      clc

.end:
      ; restore the original registers
      pop rdx
      pop rax

      ; return from the routine
      ret
