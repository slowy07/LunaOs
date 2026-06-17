all:
	nasm -f bin kernel/init/boot.asm -o build/boot
	nasm -f bin kernel/kernel.asm -o build/kernel -dMULTIBOOT_VIDEO_WIDTH_pixel=640 -dMULTIBOOT_VIDEO_HEIGHT_pixel=480
	nasm -f bin luna/luna.asm -o build/luna_disk.raw -dMULTIBOOT_VIDEO_WIDTH_pixel=640 -dMULTIBOOT_VIDEO_HEIGHT_pixel=480

run-qemu:
	@echo "running qemu"
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime

qemu-smp-2:
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 2 -rtc base=localtime

debug:
	@echo "building and debugging with qemu + gdb"
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime -s -S &
	gdb -x debug.gdb

clean:
	@echo "clearing"
	rm -rf build/kernel && rm -rf build/luna_disk.raw
