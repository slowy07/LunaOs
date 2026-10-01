# LunaOs build. Stage order is load order: the kernel incbin's the library,
# stage 2 incbin's the kernel, and the boot sector incbin's stage 2.
WIDTH  = 1280
HEIGHT = 720

APPS = free init wello cat console hello ls lulu glaze redia shell calculator tetris tm

.PHONY: all run-qemu debug clean

all: build/luna_disk.raw

build:
	mkdir -p build

# User applications. The pattern rule only matches names that exist under
# software/, so it cannot shadow the explicit rules below.
build/%: software/%.asm | build
	nasm -f bin $< -o $@

# Application support library, incbin'd by the kernel.
build/library: kernel/library.asm | build
	nasm -f bin $< -o $@

# Application-support module, incbin'd by the kernel alongside the VFS files.
build/boot: kernel/init/boot.asm | build
	nasm -f bin $< -o $@

# The kernel embeds all eleven upstream applications, boot, library and the two
# files under fs/ as its initial VFS image, so every one of them is a real
# prerequisite. Upstream's shell script built them in a fixed order and never
# had to declare this; the dependency has to be stated here.
KERNEL_VFS_APPS = shell hello tm console ls cat lulu glaze redia calculator tetris
KERNEL_VFS_DEPS = $(addprefix build/,$(KERNEL_VFS_APPS)) build/boot build/library \
                  fs/etc/hostname fs/var/welcome.txt

# 64-bit kernel, incbin'd by stage 2.
build/kernel: kernel.asm $(KERNEL_VFS_DEPS) | build
	nasm -f bin $< -o $@

# Recursive assignment, so the size is read when the recipe runs and the
# dependency has already been built. A := assignment would be expanded at
# parse time, before build/kernel exists, and would embed a stale size.
KERNEL_SIZE = $(shell wc -c < build/kernel)

# Stage 2: graphics, protected mode, long mode, IDT, disk load.
build/luna_stage2: luna/luna.asm build/kernel | build
	nasm -f bin $< -o $@ \
	  -dKERNEL_FILE_SIZE_bytes=$(KERNEL_SIZE) \
	  -dSELECTED_VIDEO_WIDTH_pixel=$(WIDTH) \
	  -dSELECTED_VIDEO_HEIGHT_pixel=$(HEIGHT)

STAGE2_SIZE = $(shell wc -c < build/luna_stage2)

# Stage 1: master boot record, 512 bytes.
build/bootsector: luna/bootsector.asm build/luna_stage2 | build
	nasm -f bin $< -o $@ -dZERO_FILE_SIZE_bytes=$(STAGE2_SIZE)

# Disk image, 1 MiB.
build/luna_disk.raw: disk.asm build/bootsector build/luna_stage2 build/kernel | build
	nasm -f bin $< -o $@

run-qemu: build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw \
	  -m 16 -smp 2 -rtc base=localtime -display gtk,zoom-to-fit=on

debug: build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw \
	  -m 16 -smp 2 -rtc base=localtime -s -S &
	gdb -x debug.gdb

clean:
	rm -rf build
