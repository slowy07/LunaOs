all:
	nasm -f bin kernel/kernel.asm -o build/kernel
	nasm -f bin luna/luna.asm -o build/luna

test:
	@echo "test and running with qemu"
	nasm -f bin kernel/kernel.asm -o build/kernel
	nasm -f bin luna/luna.asm -o build/disk.raw
	qemu-system-x86_64 -drive file=build/disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime

clean:
	@echo "clearing"
	rm -rf build/kernel && rm -rf build/disk.raw
