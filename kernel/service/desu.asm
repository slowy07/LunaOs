 %include "kernel/service/desu/config.asm"

service_desu:
 %include "kernel/service/desu/init.asm"

.loop:
 call service_desu_object
 call service_desu_cursor
 call service_desu_fill

 jmp .loop

 %include "kernel/service/desu/data.asm"
 %include "kernel/service/desu/zone.asm"
 %include "kernel/service/desu/cursor.asm"
 %include "kernel/service/desu/object.asm"
 %include "kernel/service/desu/fill.asm"

service_desu_end:
