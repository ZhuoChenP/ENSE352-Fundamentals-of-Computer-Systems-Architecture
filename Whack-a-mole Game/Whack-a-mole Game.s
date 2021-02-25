  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Whack-a-hole-game
;;Auther: Zhuo Chen
;;Date : 2020-12-3
	PRESERVE8
	THUMB

end_of_stack	equ 0x20001000			;Allocating 4kB of memory for the stack
RAM_START		equ	0x20000000

RCC_APB2ENR		EQU	0x40021018	    ; APB2 Peripheral Clock Enable Register
GPIOB_CRH		EQU	0x40010C04    ;  Port Configuration Register for Pb15 -> Pb8
GPIOB_CRL		EQU	0x40010C00    ;  Port Configuration Register for Pb7 -> Pb0
GPIOA_CRL		EQU	0x40010800    ;  Port Configuration Register for Pa7 -> Pa0
GPIOA_ODR		EQU	0x4001080C		;change output value for PA0,PA1,PA4
GPIOB_ODR		EQU	0x40010C0C		;change output value for PB0
GPIOB_IDR		EQU	0x40010C08		;observe value for PortB
DELAYONEHZ 		EQU	10000		
Prelimwait 		EQU 100000
ReactTime		EQU 800000
NumCycles		EQU 16
LosingSignalTime EQU 8
WinningSignalTime EQU 8
one_min			EQU 10000000
Random			EQU	0xded86b77	
; Vector Table Mapped to Address 0 at Reset, Linker requires __Vectors to be exported
	AREA RESET, DATA, READONLY
	EXPORT 	__Vectors


__Vectors DCD 0x20002000 ; stack pointer value when stack is empty
	DCD Reset_Handler ; reset vector
	
	ALIGN


;My program, Linker requires Reset_Handler and it must be exported
	AREA MYCODE, CODE, READONLY
	ENTRY

	EXPORT Reset_Handler
		
	ALIGN
Reset_Handler PROC;We only have one line of actual application code
	bl UC2
	

doneMain	b	doneMain
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; Show the winning signal and player's proficiency level
 ;;; UC4
 ;;; Require:
 ;;; r0: multiply constant r0 must greater than 1
 ;;; R3: value to distinguish user performance in different level
 ;;; r4: counter for loop for UC4 r4 must greater than 0
 ;;; r5: WinningSignalTime, which must be greater than 0
 ;;; r10: delay value
 ;;; r11: actual time for palyer used to compete the game
 ;;; r12: total time for entire NumCycle cycles
 ;;; Promise:
 ;;; flashing right two LEDs and left two Leds for WinningSignalTime which must be greater than 0
 ;;; after flashing, the right most LED(blue) will turn on if user used more than half of total reacting time to complete the game
 ;;; right two LEDs will turn on(green and blue) if user used less than half of total reacting time to complete the game
 ;;; After one minute, it will go back to UC2 section
 ;;;
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	align
UC4	proc
	mov r0,#2 ; set constant value
	ldr r5,=WinningSignalTime ;initiate WinningSignalTime
	mov r4,0 ; initiate counter
	b	winning_signal
show_proficiency
	bl turn_off_green
	bl turn_off_blue
	mul r3,r11,r0 ; multiple the actual used time by 2
	cmp r3,r12 ; to check if the player used less than half of the total reacting time
	blt level_2 ; if they used less time
	b level_1 ;if they used more than half
	
level_1
	bl turn_on_blue ;turn on the blue (right most LED)
	ldr r10,=one_min ;set delay value
	bl delay ; delay function
	bl turn_off_blue ;turn off the light
	b UC2 ; go back to UC2
level_2
	bl turn_on_green ; turn on second right LED
	bl turn_on_blue 
	ldr r10,=one_min
	bl delay
	bl turn_off_blue
	bl turn_off_green
	b UC2
winning_signal
; check the counter, in order to operate loop for WinningSignalTime times
;	it loops for WinningSignalTime times, go the section to determin player's performance
;	else operate the loop, flashing the LEDs in certain parttern
	cmp r4,r5 
	beq	show_proficiency  
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_green
	bl turn_off_blue
	bl turn_on_black
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_red
	bl turn_on_blue
	bl turn_on_green
	add r4,#1 ;increase the counter
	b winning_signal ;back to loop
	endp
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; Playing function to play the game, pressing correct button in react time will make the game to be continuous
 ;;; UC3
 ;;; Require:
 ;;; r3: a value for recoding how many cycles the player completed successfully.
 ;;; r7: fetch random number
 ;;; r8 reactTime
 ;;; R9 random number seed. must be greater than 0
 ;;; r10: delay value, which must be greater than 0
 ;;; r11: total actual time for played used
 ;;; r12: total time for entire NumCycle cycles
 ;;; Promise:
 ;;; LEDs will turn on randomly from random seed
 ;;; each LED will turn on during period of reactTime, after each cycle, reactTime will be reduced by 0x8000
 ;;; if player presses correct button, the LED will turn off and go the PreliWait section to enter next playing cycle
 ;;; if player presses incorrect button or did not presses any button within reactTime they will be redirected to UC5
 ;;; if play successfuly completed all Numcycle cycles, they will be redirected to UC4 
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
UC3	proc
	push{lr}
	mov r11,0 ;initiate actual time
	ldr r4,=NumCycles ;initiate actual number of cycles
	mov r12,0 ;initiate total time
	mov r3,0 ;initiate loop value
	ldr r9,=Random ;load random number seed to r9
	ldr r8,=ReactTime ;load reacttime to r8 
	b PrelimWait
	
PrelimWait
	ldr r10,=Prelimwait ;certain duration for pre wait
	bl delay
	b game_start; redirect to game_start branch
finish_game
	pop {lr}
	b UC4 ;redirecte to UC4
reduce_reactTime
	subs r8,r8,0x8000 ;reduce reacting time by 0x8000 after each cycle
	b PrelimWait ;redirected to PrelimWait branch

Led_black
	bl turn_on_black
	mov r10,r8 ;certain duration for pre wait
	bl waiting_reactTime_black ;go to delay function, it also can check if the player presses correct button with the delay duration, if not correct button or expire duration. redirect to UC5
	bl turn_off_black
	lsr r9,0x1 ; logical shift the random number seed to the right by 1, in order to fetch lower two bits
	add r3,#1 ;increase loop counter
	b reduce_reactTime

Led_red
	bl turn_on_red
	mov r10,r8 ;certain duration for pre wait
	bl waiting_reactTime_red
	bl turn_off_red
	lsr r9,0x1
	add r3,#1
	b reduce_reactTime
Led_green
	bl turn_on_green
	mov r10,r8 ;certain duration for pre wait
	bl waiting_reactTime_green
	bl turn_off_green
	lsr r9,0x1
	add r3,#1
	b reduce_reactTime
Led_blue
	bl turn_on_blue
	mov r10,r8 ;certain duration for pre wait
	bl waiting_reactTime_blue
	bl turn_off_blue
	lsr r9,0x1
	add r3,#1
	b reduce_reactTime
game_start
	add r12,r8 ;accumulate the total reacting time
	cmp r3,r4 ;check if the loop meets Numcycle required number
	beq finish_game ; complete the game and redirect to finish_game section
	and r7, r9,0x3 ;only extract lowest 2 bits from seed, range is 0-3
	cmp r7,#0 ; if the random number is 0, turn on black LED
	beq Led_black
	cmp r7,#1
	beq Led_red
	cmp r7,#2
	beq Led_green
	cmp r7,#3
	beq Led_blue
	b game_start
	endp 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; Showing the losing signal which is a flashing signal of how many cycles, in binary form, the player have completed in the game.
 ;;; UC5
 ;;; Require:
 ;;; r3: a value for recoding how many cycles the player completed successfully.
 ;;; r4: counter for the loop of flashing
 ;;; r5: LosingSignalTime, which musr be greater than 0
 ;;; r10: delay value
 ;;; Promise:
 ;;; LEDs will flash in the binary form, the binary number is corresponding number that player completed cycle in UC3
 ;;; The MSL and LSB LEDs will toggle to indecate the R3(number of completed cycles) is not in range of 1-15
 ;;; After falshing for LosingSignalTime, it will redirect to UC2
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)

	align
UC5 proc
	mov r4,#0 ; initiate loop counter
	ldr r5,=LosingSignalTime ; initiate LosingSignalTime
	b	losing_signal
cycle_accident
;; display signal if the cycles the player completed is out of the range less than 1 or greater than 16.
;; most right and left LEDs toggles between each other.
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_blue
	bl turn_on_black
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_on_blue
	add r4,#1 ;increase loop counter each time
	b losing_signal
cycle_1
; show binary number 1 by flashing LED
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_blue
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_blue
	add r4,#1
	b losing_signal
cycle_2
; show binary number 2 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_3
; show binary number 3 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_blue
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_blue
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_4
; show binary number 4 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_red
	add r4,#1
	b losing_signal
cycle_5
; show binary number 5 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_blue
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_blue
	bl turn_off_red
	add r4,#1
	b losing_signal
cycle_6
; show binary number 6 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_green
	bl turn_off_red
	add r4,#1
	b losing_signal
cycle_7
; show binary number 7 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_blue
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_red
	bl turn_off_blue
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_8
; show binary number 8 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_black
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	add r4,#1
	b losing_signal
cycle_9
; show binary number 9 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_blue
	bl turn_on_black
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_blue
	add r4,#1
	b losing_signal
cycle_10
; show binary number 10 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_black
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_11
; show binary number 11 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_blue
	bl turn_on_black
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_blue
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_12
; show binary number 12 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_black
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_red
	add r4,#1
	b losing_signal
cycle_13
; show binary number 13 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_blue
	bl turn_on_black
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_red
	bl turn_off_blue
	add r4,#1
	b losing_signal
cycle_14
; show binary number 14 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_black
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_red
	bl turn_off_green
	add r4,#1
	b losing_signal
cycle_15
; show binary number 15 by flashing LEDs
	ldr r10,=Prelimwait
	bl delay
	bl turn_on_green
	bl turn_on_blue
	bl turn_on_black
	bl turn_on_red
	ldr r10,=Prelimwait
	bl delay
	bl turn_off_black
	bl turn_off_red
	bl turn_off_blue
	bl turn_off_green
	add r4,#1
	b losing_signal
losing_signal
	cmp r4,r5 ;check if the loop meets LosingSignalTime
	beq UC2 ; if it meets that number, redirect to UC2, else go forward to check how many cycles the player completed
; check the number of cycles, the player have completed and redirect to the corresponding branch
	cmp r3,#1 
	beq cycle_1
	cmp r3,#2
	beq cycle_2
	cmp r3,#3
	beq cycle_3
	cmp r3,#4
	beq cycle_4
	cmp r3,#5
	beq cycle_5
	cmp r3,#6
	beq cycle_6
	cmp r3,#7
	beq cycle_7
	cmp r3,#8
	beq cycle_8
	cmp r3,#9
	beq cycle_9
	cmp r3,#10
	beq cycle_10
	cmp r3,#11
	beq cycle_11
	cmp r3,#12
	beq cycle_12
	cmp r3,#13
	beq cycle_13
	cmp r3,#14
	beq cycle_14
	cmp r3,#15
	beq cycle_15

	b cycle_accident ;if the cycles completed is not withint range 1-15, it will be redirected to cycle_accident branch. 
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; Set up PA0,PA1,PA4,PB0 as output and PB10,PB4,PB5,PB6 as input. Set RCC_APB2ENR values to enable Port A and Port B
 ;;; UC2
 ;;; Require:
 ;;; r0: enable value
 ;;; r2: value to check if the player presses any button
 ;;; r6: RCC_APB2ENR value adress.
 ;;; r10: delay value
 ;;; Promise:
 ;;; set up PA0,PA1,PA4,PB0 as output and PB10,PB4,PB5,PB6 as input. Set RCC_APB2ENR values to enable Port A and Port B
 ;;; If player presses any of four buttons, they will be redirected to UC3 to play the game
 ;;; in the waiting-play section the LEDs will turn on one by one and from left to right like a cycle.
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)

	ALIGN
UC2	PROC
	push{lr}
	LDR	R6, = RCC_APB2ENR	; R6 will contain the address of the register
	LDR	R0,[R6]
	orr	r0,R0, 0xC	; enable value of port A and B
	STR	R0, [R6] ; store is back to enable port A and B

	LDR	R6, = GPIOA_CRL	    ; CRl determines gpio_A pins 0-7 input
	LDR	R0,[R6]
	ldr r0,=0x30033
	str r0,[r6]
	
	LDR	R6, = GPIOB_CRL	    ; CRl determines gpio_A pins 0-7 input and output
	LDR	R0,[R6]
	ldr r0,=0x4440003
	str r0,[r6]
	
	
	LDR	R6, = GPIOB_CRH	    ; CRH determines gpio_B pins 8-15 output
	LDR	R0,[R6]
	mov r0,0x400
	str r0,[r6]

	b wait_for_play ; to waiting play loop
finish
	pop{lr}
	b UC3 ;redirect to UC3 to play the game
	endp

wait_for_play
; check if the player presses the any of four buttons
	mov r2,0 ; initiate r2 
	bl check_black_button 
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	cmp r2,0
	bne	finish ; if so, go to finish section
	bl turn_on_black ; else turn on the left most LED;
	ldr r10,=DELAYONEHZ ; assign delay value
	bl delay ; delay function
	bl turn_off_black; turn of the left most LED
	ldr r10,=DELAYONEHZ
	bl delay
	mov r2,0
	bl check_black_button
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	cmp r2,0
	bne	finish 
	bl turn_on_red ;turn on the second left LED
	ldr r10,=DELAYONEHZ
	bl delay
	bl turn_off_red;turn off the second left LED
	ldr r10,=DELAYONEHZ
	bl delay
	mov r2,0
	bl check_black_button
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	cmp r2,0
	bne	finish 
	bl turn_on_green ;turn on the second right LED
	ldr r10,=DELAYONEHZ
	bl delay
	bl turn_off_green;turn off the second right LED
	ldr r10,=DELAYONEHZ
	bl delay
	mov r2,0
	bl check_black_button
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	cmp r2,0
	bne	finish 
	bl turn_on_blue ; turn on the right most LED
	ldr r10,=DELAYONEHZ
	bl delay
	bl turn_off_blue; turn off the right most LED
	ldr r10,=DELAYONEHZ
	bl delay
	b wait_for_play ;go back to the wait-for-play loop 
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; a delay function with a counter, to count the actual react time that player used to press correct blue button, and a function 
 ;;; to check if the player presses correct button in given react time, if not they will be redirected to fail function(UC5)
 ;;; waiting_reactTime_blue
 ;;; Require:
 ;;; r2: value to check if the player presses buttons
 ;;; r10: delay value which must be greater than 0
 ;;; r11: total actual time used to complete cycles 
 ;;; Promise:
 ;;; if player presses blue button it will stop delay and redirect back to original function(UC3)
 ;;; If player presses wrong button or did not presses button during the reactTime, it will redirect to UC5
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
waiting_reactTime_blue proc
	push{lr}
	b loopping_blue
fail_push_blue
	bl turn_off_blue
	b UC5
success_push_blue
	add r9,r11; increase the rondom seed by actual react time to generate new random number
	pop{lr}
	bx lr ; redirect to original function
loopping_blue
	add r11,#1 ; increase total actual time used to complete cycles 
	mov r2,0 ; initiate checking value
	cmp r10,0 ;compare delay value
	bne check_correct_blue ; if delay value not equal 0 go to check_correct_blue section
	b fail_push_blue ; if delay value if 0, go to fail_push_blue section
check_correct_blue
	subs r10, #1 ;reduce delay value by 1 each looping time
	bl check_blue_button ; check if the blue button is pressed
	cmp r2,#1 ; check if the blue button is pressed
	beq success_push_blue ; if the blue button is pressed go to success_push_blue section
	mov r2,0
	bl check_red_button
	bl check_green_button
	bl check_black_button
	cmp r2,0 ; else checking if other three buttons are pressed
	bgt fail_push_blue ; if otehr buttons are pressed, go to fail_push_blue section
	b loopping_blue ; go to looping_blue section again
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; a delay function with a counter, to count the actual react time that player used to press correct black button, and a function 
 ;;; to check if the player presses correct button in given react time, if not they will be redirected to fail function(UC5)
 ;;; waiting_reactTime_black
 ;;; Require:
 ;;; r2: value to check if the player presses buttons
 ;;; r10: delay value which must be greater than 0
 ;;; r11: total actual time used to complete cycles 
 ;;; Promise:
 ;;; if player presses black button it will stop delay and redirect back to original function(UC3)
 ;;; If player presses wrong button or did not presses button during the reactTime, it will redirect to UC5
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
waiting_reactTime_black proc
	push{lr}
	b loopping_black
fail_push_black
	bl turn_off_black
	b UC5
success_push_black
	pop{lr}
	add r9,r11; increase the rondom seed by actual react time to generate new random number
	bx lr
loopping_black
	add r11,#1
	mov r2,0
	cmp r10,0
	bne check_correct_black
	b fail_push_black
check_correct_black
;;check if the black button is pressed, if so redirect to success_push_black, else check if any of other three button is pressed, if so redirect to fail function (UC5)
;; if the timmer counter r10 is 0, redirect to UC5 as well.
	subs r10, #1
	bl check_black_button
	cmp r2,#1
	beq success_push_black
	mov r2,0
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	cmp r2,0
	bgt fail_push_black
	b loopping_black
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; a delay function with a counter, to count the actual react time that player used to press correct red button, and a function 
 ;;; to check if the player presses correct button in given react time, if not they will be redirected to fail function(UC5)
 ;;; waiting_reactTime_red
 ;;; Require:
 ;;; r2: value to check if the player presses buttons
 ;;; r10: delay value which must be greater than 0
 ;;; r11: total actual time used to complete cycles 
 ;;; Promise:
 ;;; if player presses red button it will stop delay and redirect back to original function(UC3)
 ;;; If player presses wrong button or did not presses button during the reactTime, it will redirect to UC5
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN		
	ALIGN
waiting_reactTime_red proc
	push{lr}
	b loopping_red
fail_push_red
	bl turn_off_red
	b UC5
success_push_red
	add r9,r11; increase the rondom seed by actual react time to generate new random number
	pop{lr}
	bx lr
loopping_red
	add r11,#1
	mov r2,0
	cmp r10,0
	bne check_correct_red
	b fail_push_red
check_correct_red
;;check if the black button is pressed, if so redirect to success_push_red, else check if any of other three button is pressed, if so redirect to fail function (UC5)
;; if the timmer counter r10 is 0, redirect to UC5 as well.
	subs r10, #1
	bl check_red_button
	cmp r2,#1
	beq success_push_red
	mov r2,0
	bl check_blue_button
	bl check_green_button
	bl check_black_button
	cmp r2,0
	bgt fail_push_red
	b loopping_red
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; a delay function with a counter, to count the actual react time that player used to press correct  button, and a function 
 ;;; to check if the player presses correct button in given react time, if not they will be redirected to fail function(UC5)
 ;;; waiting_reactTime_green
 ;;; Require:
 ;;; r2: value to check if the player presses buttons
 ;;; r10: delay value which must be greater than 0
 ;;; r11: total actual time used to complete cycles 
 ;;; Promise:
 ;;; if player presses green button it will stop delay and redirect back to original function(UC3)
 ;;; If player presses wrong button or did not presses button during the reactTime, it will redirect to UC5
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN		
	ALIGN
waiting_reactTime_green proc
	push{lr}
	b loopping_green
fail_push_green
	bl turn_off_green
	b UC5
success_push_green
	add r9,r11 ; increase the rondom seed by actual react time to generate new random number
	pop{lr}
	bx lr
loopping_green
	add r11,#1
	mov r2,0
	cmp r10,0
	bne check_correct_green
	b fail_push_green
check_correct_green
;;check if the black button is pressed, if so redirect to success_push_green, else check if any of other three button is pressed, if so redirect to fail function (UC5)
;; if the timmer counter r10 is 0, redirect to UC5 as well.
	subs r10, #1
	bl check_green_button
	cmp r2,#1
	beq success_push_green
	mov r2,0
	bl check_red_button
	bl check_blue_button
	bl check_black_button
	cmp r2,0
	bgt fail_push_green
	b loopping_green
	endp
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; check if the black button is pressed
 ;;; check_black_button
 ;;; Require:
 ;;; r0: value in GPIOB_IDR
 ;;; r1: temp value mask
 ;;; r2: boolean value
 ;;; r6: GPIOB_IDR value adress.
 ;;; Promise:
 ;;; if player presses black button r2 will be added 1
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
align
check_black_button PROC
	LDR	R6, = GPIOB_IDR
	LDR	R0,[R6]
	and r1,r0,0x40	;check the button for D10/PB6
	cmp r1,0 ; check if the black button is pressed
	addeq r2,#1 ; if black button is pressed, r2=r2+1
	bx LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; check if the red button is pressed
 ;;; check_red_button
 ;;; Require:
 ;;; r0: value in GPIOB_IDR
 ;;; r1: temp value mask
 ;;; r2: boolean value
 ;;; r6: GPIOB_IDR value adress.
 ;;; Promise:
 ;;; if player presses red button r2 will be added 1
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	align
check_red_button PROC
	LDR	R6, = GPIOB_IDR
	LDR	R0,[R6]
	and r1,r0,0x20	;check the button for D4/PB5
	cmp r1,0
	addeq r2,#1
	bx LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; check if the green button is pressed
 ;;; check_green_button
 ;;; Require:
 ;;; r0: value in GPIOB_IDR
 ;;; r1: temp value mask
 ;;; r2: boolean value
 ;;; r6: GPIOB_IDR value adress.
 ;;; Promise:
 ;;; if player presses green button r2 will be added 1
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	align
check_green_button PROC
	LDR	R6, = GPIOB_IDR
	LDR	R0,[R6]
	and r1,r0,0x10	;check the button for D5/PB4
	cmp r1,0
	addeq r2,#1
	bx LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; check if the blue button is pressed
 ;;; check_blue_button
 ;;; Require:
 ;;; r0: value in GPIOB_IDR
 ;;; r1: temp value mask
 ;;; r2: boolean value
 ;;; r6: GPIOB_IDR value adress.
 ;;; Promise:
 ;;; if player presses blue button r2 will be added 1
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)	
	align
check_blue_button PROC
	LDR	R6, = GPIOB_IDR
	LDR	R0,[R6]
	and r1,r0,0x400	;check the button for D6/PB10
	cmp r1,0
	addeq r2,#1
	bx LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; the delay of operating next line code with certain time length input, r10,
 ;;; delay
 ;;; Require:
 ;;; r10: delay value
 ;;; Promise:
 ;;; if the delay the BX LR operation for corresponding delay value(the larger delay value, the longer time it takes to go back to orginal function)
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)		
		
	align
delay PROC
	push{lr}
	b wait
wait
	bl check_black_button ;nothing to do with checking any button, just because add four checking function will make the delay function takes even more time.
	bl check_red_button
	bl check_green_button
	bl check_blue_button
	subs r10, #1 ; reduce the delay value
	bne wait ; if delay value is not zero, go back to wait section, else go back to orignal function
	pop{lr}
	BX LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn on the most left LED
 ;;; turn_on_black
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn black LED (left most LED) on
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)	
	ALIGN
turn_on_black PROC
	
	LDR	R6, = GPIOA_ODR ; get GPIOA_ODR address
	LDR	r0,[R6] ; fetch the value in GPIOA_ODR address
	orr r0,0x1 ;change the value to turn on the black LED with mask without changing other value
	str r0,[r6]	;stor the value back to memory
	bx	lr	
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn off the most left LED
 ;;; turn_off_black
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn black LED (left most LED) off
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)	
	align
turn_off_black	proc
	LDR	R6, = GPIOA_ODR
	LDR	r0,[R6]
	mvn	r1,0x1 ;make turn off mask
	and r0,r0,r1 ;change the value with mask to turn off the black LED
	str r0,[r6] ; store the value back
	bx	lr
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn on the most second left LED
 ;;; turn_on_red
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn red LED (left most LED) on
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
turn_on_red PROC
	LDR	R6, = GPIOA_ODR
	LDR	r0,[R6]
	orr r0,0x2
	str r0,[r6]	
	bx	lr
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn off the most second left LED
 ;;; turn_off_red
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn red LED (left most LED) off
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	align
turn_off_red	proc
	LDR	R6, = GPIOA_ODR
	LDR	r0,[R6]
	mvn	r1,0x2
	and r0,r0,r1
	str r0,[r6]
	bx	lr
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn on the most second right LED
 ;;; turn_on_green
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn green LED (left most LED) on
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)		
		
	ALIGN
turn_on_green PROC
	
	LDR	R6, = GPIOA_ODR
	LDR	r0,[R6]
	orr r0,0x10
	str r0,[r6]	
	bx	lr	
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn off the most second right LED
 ;;; turn_off_green
 ;;; Require:
 ;;; r0: value in GPIOA_ODR
 ;;; r6: GPIOA_ODR value adress.
 ;;; Promise:
 ;;; turn green LED (left most LED) off
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)	
	align
turn_off_green	proc
	LDR	R6, = GPIOA_ODR
	LDR	r0,[R6]
	mvn	r1,0x10
	and r0,r0,r1
	str r0,[r6]
	bx	lr
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn on the most left LED
 ;;; turn_on_blue
 ;;; Require:
 ;;; r0: value in GPIOB_ODR
 ;;; r6: GPIOB_ODR value adress.
 ;;; Promise:
 ;;; turn blue LED (left most LED) on
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	ALIGN
turn_on_blue PROC
	
	LDR	R6, = GPIOB_ODR
	LDR	r0,[R6]
	orr r0,0x1
	str r0,[r6]	
	bx	lr	
	endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;; turn off the most left LED
 ;;; turn_off_blue
 ;;; Require:
 ;;; r0: value in GPIOB_ODR
 ;;; r6: GPIOB_ODR value adress.
 ;;; Promise:
 ;;; turn blue LED (left most LED) off;
 ;;; NOTES:
 ;;; 1) order from left to right (black, red,green,blue)
	align
turn_off_blue	proc
	LDR	R6, = GPIOB_ODR
	LDR	r0,[R6]
	mvn	r1,0x1
	and r0,r0,r1
	str r0,[r6]
	bx	lr
	endp
	