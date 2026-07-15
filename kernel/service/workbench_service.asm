 %include "kernel/service/workbench_service/config.asm"

service_workbench:
 %include "kernel/service/workbench_service/init.asm"

.loop:
 jmp .loop

 %include "kernel/service/workbench_service/data.asm"
 %include "library/bosu.asm"
