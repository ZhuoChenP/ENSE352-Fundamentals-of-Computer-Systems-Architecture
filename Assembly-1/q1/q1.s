;ARM1.s Source code for my first program on the ARM Cortex M3
;Function Modify some registers so we can observe the results in the debugger
;Author - Dave Duguid
;Modified August 2012 Trevor Douglas
; Directives
	thumb

;;; Equates
end_of_stack	equ 0x20001000			;Allocating 4kB of memory for the stack
RAM_START		equ	0x20000000


;;; Includes
	;; empty

;;; Vector definitions

	area vector_table, data, readonly
__Vectors
	DCD	0x20002000		; initial stack pointer value
	DCD	Reset_Handler	; program entry point
	export __Vectors

	align


;My program, Linker requires Reset_Handler and it must be exported
	AREA MYCODE, CODE, READONLY
	ENTRY

	EXPORT Reset_Handler
		
		
Reset_Handler ;We only have one line of actual application code

	mov		r9,#34;input
	LDR		r10,=0x20000030
	bl int_to_ascii



	B Reset_Handler; back to beginning of Reset_Handler
		
	ENDP
		
	ALIGN		
int_to_ascii PROC
	push	{lr}
	mov		r11,r9,lsr #31
	mov		r6,0x20;initiate sign bit to positive
	cmp		r11,#1
	bleq	complement		
	
	mov		r8,#0;find leading one
loop
	mov		r1,#0;msb
	mov		r2,#0;sub_lsb
	mov		r3,#0;lsb
	mov		r5,#10;assign divider
	mov		r7,0x00;null byte
	mov		r4,#0; temp
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp		r9,#0
    BEQ   	finish
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOV		r0, r9, lsr #24;r0=r9>>24 get each byte
    mov		r9,r9,lsl #8;r9<<8, reduce each byte,Shift one byte for next time
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp		r0,#0	;;check if this byte is zero
	beq		loop	;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	cmp		r8,#0
	bleq	find_one
	
	mov		r4,r0
	UDIV	r0,r0,r5
	
	
	cmp		r0,#9
	blhi	divid
	
	mls		r3,r5,r0,r4;get lsb
	
	
	CMP		r1,#0
	BEQ		insert_two
	
	ADDS   	r1, r1, #48;
	ADDS   	r2, r2, #48;
	ADDS   	r3, r3, #48;
	
	STRB	r1,[r10]
	ADD		r10,r10,#1
	STRB	r2,[r10]
	ADD		r10,r10,#1	
	STRB	r3,[r10]
	ADD		r10,r10,#1

	
	cmp		r9,#0
    BNE   	loop
	strb	r7,[r10]
	pop	{lr}
	bx lr
	ENDP
insert_two
	ADDS   	r0, r0, #48; For each nibble (now in r0) convert to ASCII and print  
	STRB	r0,[r10]
	ADD		r10,r10,#1
	ADDS   	r3, r3, #48; For each nibble (now in r0) convert to ASCII and print  
	strb	r3,[r10]	
	ADD		r10,r10,#1
	b 	loop

finish
	strb	r7,[r10]
	pop	{lr}
	bx lr
	ENDP	
	
	ALIGN
complement PROC
	mvn		r9,r9
	add		r9,#1
	mov		r6,0x2d
	bx lr
	ENDP


	ALIGN		
divid PROC
	UDIV	r1,r0,r5;find decimal express
	mls		r2,r1,r5,r0;r2=(r0-r5*r1) find the sub-lsb story is in r2

	bx lr
	ENDP


	ALIGN		
find_one PROC
	mov		r8,#1;
	strb	r6,[r10]
	ADD		r10,r10,#1
	bx lr
	ENDP



	align
	end