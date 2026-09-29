;===============================================================================

;===============================================================================
; entry:
;	rax - uptime
tm_uptime:
	; save the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; rax - uptime

	; convert the "uptime" value into seconds
	mov	ecx,	1024
	xor	edx,	edx
	div	rcx

	; number system: decimal
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal

	; string of characters representing the value
	mov	rdi,	tm_string_value_format

	; clear the flags
	xor	r8,	r8

	;-----------------------------------------------------------------------

	; convert the uptime into a number of days
	mov	ecx,	60*60*24	; 86400 seconds
	xor	edx,	edx
	div	rcx

	; format: _D.HHd
	mov	ecx,	0x02

	; save the remainder of the division (hours)
	push	rdx

	; default prefix
	mov	edx,	STATIC_SCANCODE_SPACE

	; no days?
	test	rax,	rax
	jz	.no_days	; yes

	; save the number of days
	push	rax

	; is the number of days smaller than 10?
	cmp	rax,	10
	jb	.day_overflow	; no

	; format: _DDDDd
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.day_overflow:
	; convert the value to a string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; display
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; restore the number of displayed days
	pop	rax

	; default format "_D.HHd"
	mov	dl,	"."

	; display the hours?
	cmp	rax,	10
	jb	.days	; yes

	; convert to the "_DDDDd" format
	mov	dl,	"d"

.days:
	; display the type
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; single character
	int	KERNEL_SERVICE

	; set the flag, the hours have been displayed
	mov	r8,	TM_UPTIME_FLAG_hour

.no_days:
	; restore the remainder of the division
	pop	rax

	; end of processing?
	cmp	dl,	"d"
	je	.end	; yes

	;-----------------------------------------------------------------------

	; convert the uptime into a number of hours
	mov	ecx,	60*60	; 3600 seconds
	xor	edx,	edx
	div	rcx

	; format: _H:MMh
	mov	ecx,	0x02

	; save the remainder of the division (minutes)
	push	rdx

	; default prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; no hours?
	test	rax,	rax
	jz	.no_hours	; yes

	; save the number of hours
	push	rax

	; have the days been displayed?
	test	r8,	TM_UPTIME_FLAG_day
	jnz	.hours_only	; yes

	; prefix for the format without days
	mov	dl,	STATIC_SCANCODE_SPACE

.hours_only:
	; is the number of hours greater than 10?
	cmp	rax,	10	; 10 hours
	jb	.hour_overflow	; no

	; format: ___HHh
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.hour_overflow:
	; convert the value to a string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; display
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; restore the number of displayed hours
	pop	rax

	; default format "_H:MMh"
	mov	dl,	":"

	; display the minutes?
	cmp	rax,	10
	jb	.hours	; yes

	; convert to the "___HHh" format
	mov	dl,	"h"

.hours:
	; display the type
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; single character
	int	KERNEL_SERVICE

	; set the flag, the hours have been displayed
	mov	r8,	TM_UPTIME_FLAG_hour

.no_hours:
	; restore the remainder of the division
	pop	rax

	; end of processing?
	cmp	dl,	"h"
	je	.end	; yes

	;-----------------------------------------------------------------------

	; convert the uptime into a number of minutes
	mov	ecx,	60	; 60 seconds
	xor	edx,	edx
	div	rcx

	; format: _M:SSm or _H:MMh
	mov	ecx,	0x02

	; save the remainder of the division (seconds)
	push	rdx

	; default prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; no minutes?
	test	rax,	rax
	jz	.no_minutes	; yes

	; save the number of minutes
	push	rax

	; have the hours been displayed?
	test	r8,	TM_UPTIME_FLAG_hour
	jnz	.minutes_only	; yes

	; prefix for the format without hours
	mov	dl,	STATIC_SCANCODE_SPACE

.minutes_only:
	; is the number of minutes smaller than 10?
	cmp	rax,	10	; 10 minutes
	jb	.minutes_overflow	; no

	; format: ___MMm
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.minutes_overflow:
	; convert the value to a string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; display
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; restore the number of displayed minutes
	pop	rax

	; default format "_M:SSm"
	mov	dl,	":"

	; display the seconds?
	cmp	rax,	10
	jb	.minutes	; yes

	; convert to the "___MMm" format
	mov	dl,	"m"

.minutes:
	; display the type
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; single character
	int	KERNEL_SERVICE

	; set the flag, the minutes have been displayed
	mov	r8,	TM_UPTIME_FLAG_minute

.no_minutes:
	; restore the remainder of the division
	pop	rax

	; end of processing?
	cmp	dl,	"m"
	je	.end	; yes

	;-----------------------------------------------------------------------

	; format: _M:SSm
	mov	ecx,	0x02

	; default prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; have the minutes been displayed?
	test	r8,	TM_UPTIME_FLAG_minute
	jnz	.second_overflow	; yes

	; format: ___SSs
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

	; prefix for the format without minutes
	mov	dl,	STATIC_SCANCODE_SPACE

.second_overflow:
	; convert the value to a string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; display
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; default format "___SSs"
	mov	dl,	"s"

	; have the minutes been displayed?
	test	r8,	TM_UPTIME_FLAG_minute
	jz	.seconds_only	; no

	; convert to the "_M:SSm" format
	mov	dl,	"m"

.seconds_only:
	; display the type
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; single character
	int	KERNEL_SERVICE

.end:
	; restore the original registers
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"software: tm_uptime"
