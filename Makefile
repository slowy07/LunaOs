all:
	nasm -f bin kernel/init/boot.asm -o build/boot
	nasm -f bin kernel/kernel.asm -o build/kernel
	nasm -f bin luna/luna.asm -o build/luna_disk.raw

test:
	@echo "test and running with qemu"
	nasm -f bin kernel/init/boot.asm -o build/boot
	nasm -f bin kernel/kernel.asm -o build/kernel
	nasm -f bin luna/luna.asm -o build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime

qemu-smp-2:
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 2 -rtc base=localtime

debug:
	@echo "building and debugging with qemu + gdb"
	nasm -f bin kernel/init/boot.asm -o build/boot
	nasm -f bin kernel/kernel.asm -o build/kernel
	nasm -f bin luna/luna.asm -o build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime -s -S &
	gdb -x debug.gdb

clean:
	@echo "clearing"
	rm -rf build/kernel && rm -rf build/luna_disk.raw
