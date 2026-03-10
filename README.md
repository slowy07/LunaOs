# LunaOs
multitasking operating system written in assembly x86_64 (formely aidenOS)

## Requirements

- nasm
- qemu

## Running:

```
nasm -f bin kernel/kernel.asm -o build/kernel
nasm -f bin luna/luna.asm -o build/luna.raw
```

**Playing with qemu**
```
qemu-system-x86_64 -drive file=build/luna.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime
```
