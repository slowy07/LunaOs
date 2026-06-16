set pagination off
set confirm off
set disassembly-flavor intel

target remote localhost:1234

echo Debug Mode \n
echo Kernel physical at 0x100000, virtual at 0xFFFF800000100000\n
echo Type 'continue' to start execution\n

hbreak *0x100000
