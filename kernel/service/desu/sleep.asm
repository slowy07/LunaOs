service_desu_sleep:
 cmp qword [service_desu_object_list_record], STATIC_EMPTY
 je .end

 jmp service_desu_sleep

.end:
 ret

 macro_debug "service DESU sleep"
