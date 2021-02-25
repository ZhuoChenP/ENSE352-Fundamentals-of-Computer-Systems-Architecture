;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Project: Solution to Q2 and Q3 of assign3
;;; File: crypto.s
;;; Class: ense352
;;; Programmer: K. Naqvi

;;; Directives
	thumb

;;; Equates
RAM_START	equ	0x20000000
string_buffer	equ	RAM_START + 0

;;; Includes
	;; empty

;;; Vector definitions

	area vector_table, data, readonly
__Vectors
	dcd	0x20002000	; initial stack value
	dcd	Reset_Handler	; program entry point
	export __Vectors

	align

;;; Our mainline code begins here
	area	mainline, code
	entry
	export	Reset_Handler

;;; Procedure definitions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This mainline code sets up a RAM buffer with text to be encrypted.
;;; Then it calls the encrypt subroutine to encrypt the text in place.
Reset_Handler proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; First test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Copy the plaintext1 from flash to RAM buffer so it 
	;; can be modified.
	ldr	r1,=plaintext1
	ldr	r2,=string_buffer
	ldr	r3,=size1
	ldr	r3,[r3]
	bl	byte_copy
	
	;; Encrypt the plaintext1 buffer
	ldr	r4,=string_buffer
	ldr	r3,=size1
	ldr	r3,[r3]
	orr	r3,r3,#(13 :SHL: 15)  ;; rotate by 13
	bl	encrypt

	;; Verify the results of test 1 are correct
        mov     r1,r4
        ldr     r2,=ciphertext1
        ldr     r3,=size1
        ldr     r3,[r3]
        bl      strncmp
        cbz     r0,test2
error1  b       error1
        
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Second test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Copy the plaintext2 from flash to RAM buffer so it 
	;; can be modified.
test2	ldr	r1,=plaintext2
	ldr	r2,=string_buffer
	ldr	r3,=size2
	ldr	r3,[r3]
	bl	byte_copy
	
	;; Encrypt the plaintext2 buffer
	ldr	r4,=string_buffer
	ldr	r3,=size2
	ldr	r3,[r3]
	orr	r3,r3,#(13 :SHL: 15)  ;; rotate by 13
	bl	encrypt

	;; Verify the results of test 2 are correct
        mov     r1,r4
        ldr     r2,=ciphertext2_rot13
        ldr     r3,=size2
        ldr     r3,[r3]
        bl      strncmp
        cbz     r0,test3
error2  b       error2
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Third test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Copy the plaintext2 from flash to RAM buffer so it 
	;; can be modified.
test3	ldr	r1,=plaintext2
	ldr	r2,=string_buffer
	ldr	r3,=size2
	ldr	r3,[r3]
	bl	byte_copy
	
	;; Encrypt the plaintext2 buffer
	ldr	r4,=string_buffer
	ldr	r3,=size2
	ldr	r3,[r3]
	orr	r3,r3,#(1 :SHL: 15) ;; rotate by 1
	bl	encrypt
	
	;; Verify the results of test 3 are correct
        mov     r1,r4
        ldr     r2,=ciphertext2_rot1
        ldr     r3,=size2
        ldr     r3,[r3]
        bl      strncmp
        cbz     r0,test4
error3  b       error3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Fourth test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Now to test the decrypt routine, use the current string_buffer
	;; which has been encrypted with a rotation of 1, and apply decrypt
test4	ldr	r4,=string_buffer
	ldr	r3,=size2
	ldr	r3,[r3]
	orr	r3,r3,#(1 :SHL: 15) ;; unrotate by 1
	bl	decrypt

	;; Verify the results of rot1 decryption are correct
        mov     r1,r4
        ldr     r2,=plaintext2
        ldr     r3,=size2
        ldr     r3,[r3]
        bl      strncmp
        cbz     r0,good
error4  b       error4


	;; we are finished
good	b	good		; finished mainline code.
	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plaintext1
	dcb	"This is some plaintext.  Very good."
plaintext1size	equ . - plaintext1
;;; expected cipher text for rot13:
ciphertext1
        dcb	"Guvf vf fbzr cynvagrkg.  Irel tbbq."

	align
size1
	dcd	plaintext1size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plaintext2
	dcb	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
plaintext2size	equ . - plaintext2
	
;;; expected cipher text for rot13:
ciphertext2_rot13
	dcb	"NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm"

;;; expected cipher text for rot1
ciphertext2_rot1
	dcb	"BCDEFGHIJKLMNOPQRSTUVWXYZAbcdefghijklmnopqrstuvwxyza"
	
	align
size2
	dcd	plaintext2size
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; encrypte the input string for n value.
;;; from A=1, Z=26. R4 is string_buffer, 14:0 of r3 is length of array 19:15 of r3 is the n(number) of rotate..
;;;	r5,r6,r7,r8,r9,r10,r11 check if the element in the r4 is char value. r1 is temp value of array length. r2 is temp value of number of rotate,r12 is fetchd value from ram
;;; Require:
;;;   The destination buffer is located in RAM.
;;;   Source and dest arrays must not overlap.
;;;
;;; Promise: only the caracters changes in the array.
		ALIGN
encrypt	PROC
	push	{r4,r3,r0,r1,r2}
	mov		r0,0x7fff;temp mask value
	mov		r2,r3, lsr #15; get n value
	and		r2,r2,0x1f;;get value from 19:15, 5 bits
	and		r3,r3,r0
	mov 	r1,r3;get length
	
	cmp		r2,#25
	bgt		loopx
	
	b	loop
	
loopx
	mov		r12,0x58
	strb	r12,[r4]
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	cmp		r1,#0
	bgt		loopx
	
	b 	finish
	
	
loop	
	mov		r5,0
	mov		r6,0
	mov		r7,0
	mov		r8,0
	mov		r9,0
	mov		r10,0
	mov		r11,0
	mov		r12,0
	
	cmp		r1,#0
	beq 	finish
	
	ldrb	r12,[r4]
	cmp 	r12,0x41;;;;;;;;;chart>=A
	addge	r5,r5,#1
	cmp		r12,0x5A;;;;;;;;;chart<=Z
	addle	r6,r6,#1
	cmp 	r12,0x61;;;;;;;;;chart>=a
	addge	r7,r7,#1
	cmp		r12,0x7A;;;;;;;;;chart<=z
	addle	r8,r8,#1
	
	add		r11,r5,r6
	add		r11,r11,r7
	add		r11,r11,r8
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	cmp		r11,#3;;;find if the element is char value
	blt		loop
	
	sub 	r4,r4,#1;;;get to orignial address of element
	add		r1,r1,#1;;;get to original length
	
	adds	r12,r12,r2
	cmp		r12,0x5a;;;if the char is overflow	chart<Z
	addgt	r9,#1
	cmp		r12,0x7a;;;if the char is overflow	chart<z
	addgt	r10,#1
	
	add		r11,r6,r9
	cmp		r11,#2;;;;;;;The original value between A-Z and there is overflow
	beq		A_overflow
	
	add		r11,r7,r10
	cmp		r11,#2;;;;;;;The original value between a-z and there is overflow
	beq		A_overflow	
	
	strb	r12,[r4];;;;no over flow
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	b loop
	
A_overflow
	add		r12,r12,#6
	sub		r12,r12,0x20
	strb	r12,[r4]
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	b loop
	
finish
	pop{r4,r3,r0,r1,r2}
	bx lr
	
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; decrypt the input string, only characters for n value.
;;; from A=1, Z=26. R4 is string_buffer, 14:0 of r3 is length of array 19:15 of r3 is the n(number) of rotate..
;;;	r5,r6,r7,r,8,r9,r10, check if the element in the r4 is char value. r1 is temp value of array length. r2 is temp value of number of rotate,r12 fetchd value
;;; Require:
;;;   The destination buffer is located in RAM.
;;;   Source and dest arrays must not overlap.
;;;
;;; Promise: only the caracters changes in the array.	
	ALIGN
decrypt PROC
	push	{r4,r3,r0,r1,r2}
	mov		r0,0x7fff;temp mask value
	mov		r2,r3, lsr #15; get n value
	and		r2,r2,0x1f;;get value from 19:15, 5 bits
	and		r3,r3,r0
	mov 	r1,r3;get length
	mov		r5,#26
	sub		r2,r5,r2
	mov		r5,#0
	
	
	cmp		r2,#25
	bgt		loopx1
	
	b	loop1
	
loopx1
	mov		r12,0x58
	strb	r12,[r4]
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	cmp		r1,#0
	bgt		loopx1
	
	b 	finish1
	
	
loop1	
	mov		r5,0
	mov		r6,0
	mov		r7,0
	mov		r8,0
	mov		r9,0
	mov		r10,0
	mov		r11,0
	mov		r12,0
	
	cmp		r1,#0
	beq 	finish1
	
	ldrb	r12,[r4]
	cmp 	r12,0x41;;;;;;;;;chart>=A
	addge	r5,r5,#1
	cmp		r12,0x5A;;;;;;;;;chart<=Z
	addle	r6,r6,#1
	cmp 	r12,0x61;;;;;;;;;chart>=a
	addge	r7,r7,#1
	cmp		r12,0x7A;;;;;;;;;chart<=z
	addle	r8,r8,#1
	
	add		r11,r5,r6
	add		r11,r11,r7
	add		r11,r11,r8
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	cmp		r11,#3;;;find if the element is char value
	blt		loop1
	
	sub 	r4,r4,#1;;;get to orignial address of element
	add		r1,r1,#1;;;get to original length
	
	adds	r12,r12,r2
	cmp		r12,0x5a;;;if the char is overflow	chart<Z
	addgt	r9,#1
	cmp		r12,0x7a;;;if the char is overflow	chart<z
	addgt	r10,#1
	
	add		r11,r6,r9
	cmp		r11,#2;;;;;;;The original value between A-Z and there is overflow
	beq		A_overflow1
	
	add		r11,r7,r10
	cmp		r11,#2;;;;;;;The original value between a-z and there is overflow
	beq		A_overflow1
	
	strb	r12,[r4];;;;no over flow
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	b loop1
	
A_overflow1
	add		r12,r12,#6
	sub		r12,r12,0x20
	strb	r12,[r4]
	
	adds 	r4,r4,#1;;;move to next value
	subs	r1,r1,#1;;;length reduced by 1
	b loop1
	
finish1
	pop{r4,r3,r0,r1,r2}
	bx lr
	
	ENDP
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; copy an array of bytes from source ptr R1 to dest ptr R2.  R3
;;; contains the number of bytes to copy.
;;; Require:
;;;   The destination buffer is located in RAM.
;;;   Source and dest arrays must not overlap.
;;;
;;; Promise: No registers are modified.  Flags are modified. The
;;;     	destination buffer is modified.
byte_copy
	push	{r1,r2,r3,r4}
0
	cbz	r3,done_byte_copy
	sub	r3,r3,#1
	ldrb	r4,[r1],#1
	strb	r4,[r2],#1
	b	%b0
done_byte_copy
	pop	{r1,r2,r3,r4}
	bx	lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Compare a pair of byte arrays, of size n
;;; Require:
;;;   R1: ptr to first byte array
;;;   R2: ptr to second byte array
;;;   R3: size, n
;;; Promise:
;;;   returns a value in R0: (<0,0,>0) if first array is lexically (less than,
;;;   equal to, greater than) second array.  Similar to strncmp().
;;;   Modifies no registers.  Modifies flags.
strncmp
	push	{r1-r5}

loop_strncmp
	cbz	r3,done_strncmp	; done?
	sub	r3,r3,#1

	;; load a char into r4 and r5, then compare them
	ldrb	r4,[r1],#1
	ldrb	r5,[r2],#1
	subs	r0,r4,r5
	bne	done_strncmp	; return as promised
	b	loop_strncmp

done_strncmp
	pop	{r1-r5}
	bx	lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;  paste your encrypt and decrypt implementations to test them here
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; End of assembly file
	align
	end
