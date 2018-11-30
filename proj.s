;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Author: Kelly Holtzman
;;; Student Number: 200366225
;;; Course: ENSE 352-001
;;; Project: Term Project (Whack-A-Mole)
;;; Program Completion Date: Nov 29, 2018

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Directives
	PRESERVE8
	THUMB
		      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    		 
;;; Equates
INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value

;; PORT A GPIO - Base Addr: 0x40010800
;GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register

;; PORT B GPIO - Base Addr: 0x40010C00
;GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0
;GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register

;; PORT C GPIO - Base Addr: 0x40011000
;GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
;GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register

;; RCC Registers - Base Addr: 0x40021000
RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register

;; Constants for Linear Congruential Generator (LCG/RNG) routine
;; These constants are parameters specific to the LCG defined in
;; "Numerical Recipes" by William H. Press, Saul A. Teukolsky, William T. Vetterling and Brian P. Flannery.
A			EQU 	0x19660D	; 'A' - The multiplier
C			EQU     0x3C6EF35F	; 'C' - The increment

;; Wait Times
DELAY_TIME  	EQU     0x27100		; Delay Time specific to cycling LEDs at approx 1Hz
PRELIM_WAIT		EQU		0x186A00	; Preliminary Wait specific to each game round
REACT_TIME		EQU		0x3FC00		; Reaction Time for the user to respond within
NUM_CYCLES		EQU		0x10		; Number of Cycles for each game
WINNING_SIGNAL_TIME	EQU 0x20		; Winning Signal time
LOSING_SIGNAL_TIME	EQU 0x20		; Losing Signal time

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Vector Table Mapped to Address 0 at Reset
            AREA    RESET, Data, READONLY
            EXPORT  __Vectors

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__Vectors	DCD		INITIAL_MSP			; Stack pointer value when stack is empty
        	DCD		Reset_Handler		; Reset vector

            AREA    MYCODE, CODE, READONLY
			EXPORT	Reset_Handler

			ENTRY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Handler for game, will initialize I/O of board and repeats game procedures

Reset_Handler		PROC
	;; Initialize I/O lines
	bl GPIO_ClockInit
	bl GPIO_init

gameplay
	bl Waiting_for_Player ; Cycling LEDS until a button is pressed (UC2)
	bl Normal_Gameplay    ; Begin normal gameplay (UC3)
	b gameplay
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Enable the clock for Ports A, B, and C (LEDs and Buttons)
;;; Requires:
;;;		RCC_APB2ENR: Address in memory for Reset and Clock Control APB2 Peripheral 
;;; Promise:
;;; 	Will set bits at RCC_APB2ENR such that the clock is enabled for the above.
;;; Modifies:
;;;		Subroutine does not modify any registers.
;;;
;;; NOTES:
;;;	1) 	ENEL 384 Pushbuttons: Button 1(Red): PB8, Button 2(Black): PB9, Button 3(Blue): PC12, Button 4(Green): PA5
;;;	2) 	ENEL 384 Board LEDs: LED 1 - PA9, LED 2 - PA10, LED 3 - PA11, LED 4 - PA12

	ALIGN
GPIO_ClockInit		PROC
	push {r0, r1}

	ldr r0, =RCC_APB2ENR
	mov r1, #0x001C ; Bit pattern 0000 001C for PA, PB, PC enable
	str r1, [r0]

	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;	Configure output lines for Port A (LEDs)
;;; Requires:
;;;		GPIOA_CRH: Address in memory for Port A Register Configuration (High)
;;; Promise:
;;; 	Will set bits at GPIOA_CRH such that output is configured for the above 'high' pins.
;;; Modifies:
;;;		Subroutine does not modify any registers.
;;;
;;; NOTES:
;;; 1)	By default the I/O lines are configured for input.
;;; 2)	ENEL 384 Board LEDs: LED 1 - PA9, LED 2 - PA10, LED 3 - PA11, LED 4 - PA12

	ALIGN
GPIO_init			PROC
	push {r0, r1}

	ldr r0, =GPIOA_CRH
	ldr r1, =0x00033330 ; Bit pattern 0003 3330, configures pins 9-12 with
						; Output mode, GP output push-pull & max speed 50MHz (3)
	str r1, [r0]

	pop {r0, r1}
    BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Wait for the player to Start the Game
;;; Requires:
;;; 	DELAY_TIME: Predefined time to hold an LED. Any value, works best if approx. 0x27100.
;;; Promise: 
;;; 	Will cycle LEDs at approx. 1Hz (when 0x27100) without stopping until a button is pressed.
;;;		Once a button is pressed, the system enters normal game play (UC3).
;;; Modifies:
;;;		Returns the stopped DELAY_TIME in R2 and modifies flags.
;;;		Subroutine does not modify any other registers.

	ALIGN
Waiting_for_Player 	PROC
	push {lr, r0, r1, r3}
	
	;; The following loops cycle the LEDs back and forth by shifting the bits in the GPIOA_ODR left or right by one bit.
	;; The direction depends on the last LED that was on. It starts with the leftmost LED on the 384 Board.
cycling_prep_forwards
	mov r1, #0x0200 	; Bit Pattern for LED 1
	bl Set_LED_Output 	; Requires pattern for LEDs in r1
	ldr r2, =DELAY_TIME
	ldr r3, =3 			; LED count per cycle
	
cycle_forwards
	;; Check if user has pressed a button, if a button is pressed start gameplay
	bl Get_Button_Input	; Button pattern returned in r0
	cmp r0, #0x1320 	; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	;; If DELAY_TIME has not expried, keep the current LED on
	subs r2, #1
	bne cycle_forwards
	
	;; When DELAY_TIME is up, shift bit pattern at GPIOA_ODR left to turn on next forward LED
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsl r1, #1
	str r1, [r0]
	
	;; If the 4th LED was just on, cycle backwards
	;; Else, reset DELAY_TIME and continue cycling forwards
	subs r3, #1
	beq cycling_prep_backwards
	ldr r2, =DELAY_TIME
	b cycle_forwards
	
cycling_prep_backwards
	ldr r2, =DELAY_TIME
	ldr r3, =3 		; LED count per cycle

cycle_backwards
	;; Check if user has pressed a button, if a button is pressed start gameplay
	bl Get_Button_Input
	cmp r0, #0x1320 	 ; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	;; If DELAY_TIME has not expried, keep the current LED on
	subs r2, #1
	bne cycle_backwards
	
	;; When DELAY_TIME is up, shift bit pattern at GPIOA_ODR right to turn on previous LED
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsr r1, #1
	str r1, [r0]
	
	;; If the 1st LED was just on, cycle forwards
	;; Else, reset DELAY_TIME and continue cycling backwards
	subs r3, #1
	beq cycling_prep_forwards
	ldr r2, =DELAY_TIME
	b cycle_backwards
	
start_gameplay
	;; Turn off LEDs to signal the end of Waiting for Player
	mov r1, #0x0		; Bit Pattern when no LEDs are on is 0000 0000
	bl Set_LED_Output

	pop {lr, r0, r1, r3}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Control Normal Gameplay
;;; Requires: 
;;;		R2: User-controlled RNG seed. Will be within the range [DELAY_TIME:0].
;;; 	NUM_CYCLES: The number of rounds per game. Should be at least 1.
;;;		REACT_TIME: The allowed reaction time for the user to respond. 
;;;					Works best if approx. 0x3FC00 (4*0xFFOO, or approx. 4s)
;;;		PRELIM_WAIT: The predefined wait time between rounds.
;;;					 Works best if long enough for the user to let go of the button.
;;; Promise:
;;;		Controls I/O from the ENEL 384 Board for NUM_CYCLES of rounds.
;;;		Will return the user's score [NUMCYCLES:0] in R12 after NUM_CYCLES of rounds.
;;; Modifies:
;;;		Returns the user's score in R12 and modifies flags.
;;; 	Subroutine does not modify any other registers.

	ALIGN
Normal_Gameplay PROC
	push {lr, r0, r1, r2, r3, r4, r11}

	;; Set up the current game by seeding the RNG, the number of cycles, score, and starting reaction time
	bl Seed_RNG			; Sets the seed for RNG in r10
	ldr r11, =NUM_CYCLES
	mov r12, #0 		; Score starts at 0
	ldr r3, =REACT_TIME
	
start_round
	;; The fixed wait time PRELIM_WAIT elapses
	ldr r4, =PRELIM_WAIT
	bl Wait			  ; Requires the time to wait in r4

	bl RNG 			  ; RNG the LED to turn on from r10, returns the number in r9
	bl Select_LED 	  ; Select the chosen LED and corresponding button -
					  ; returns the corresponding button pattern in r2
	bl Set_LED_Output ; Turn on the chosen LED

	;; Save the current reaction time
	push {r3}

reaction_time
	;; Wait for the player to press the corresponding button to the chosen LED
	subs r3, #1
	beq failed_reaction

	;; Check if user has pressed a button
	;; If no button is pressed, continue waiting
	bl Get_Button_Input
	cmp r0, #0x1320     ; Bit pattern when no button is pressed is 0000 1320
	beq reaction_time
	
	;; Else, the user must have pressed a button
	cmp r0, r2			; Compares button input in r0 to pattern in r2
	beq good_reaction	; If the pattern matches, the user has pressed the correct button
	bne failed_reaction ; If not, the user has pressed more than one button or the wrong button

good_reaction
	;; Turn off LEDs to signal the round is over
	mov r1, #0x0
	bl Set_LED_Output

	;; Reduce the reaction time for the next cycle
	pop {r3}
	ldr r0, =0xFF00
	lsr r3, #1	   ; Reduce time by 2^n, or approx 1/2^n each round (results in an approx. sqrt of R3)
	add r3, r3, r0 ; Add 1s so there will be at least one second per round -
				   ; one second with consumed clock cycles is approx 0xFF00

	;; The value 0xFF00, among others, was determined through testing
	;; and the understanding that each instruction (cmp, mov, ldr, lsr, etc.) 
	;; consumes anywhere from 1-N clock cycles. Since a cycle is approx. a microsecond long,
	;; they do not contribute much delay on their own, but can exponentially increase
	;; with increased code between NUM_CYCLES.
	
	;; Update the score and the number of cycles completed
	add r12, #1
	subs r11, #1
	bne start_round ; If there are still more cycles, start the next round
	bl End_Success
	
	pop {lr, r0, r1, r2, r3, r4, r11}
	BX LR

failed_reaction
	;; Turn off LEDs to signal the round is over
	mov r1, #0x0
	bl Set_LED_Output

	pop {r3} 		; Remove r3 from the stack, no longer need to reduce reaction time
	subs r11, #1 	; Update the number of cycles completed
	bl End_Failure

	pop {lr, r0, r1, r2, r3, r4, r11}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Collect the input on the 384 Board buttons 
;;; Requires:
;;;		GPIOA_IDR, GPIOB_IDR, GPIOC_IDR: Addresses in memory for Ports A, B, and C input
;;; Promise:
;;;		Collects the bits present at all the button input ports.
;;; Modifies:
;;;		Returns the current input pattern in R0.
;;;		Subroutine does not modify any other register.
;;;
;;; NOTES:
;;; 1)  ENEL 384 Pushbuttons: Button 1(Red): PB8, Button 2(Black): PB9, Button 3(Blue): PC12, Button 4(Green): PA5

	ALIGN
Get_Button_Input  PROC
	push {r1, r2, r3}

	ldr r0, =GPIOB_IDR ; PB8 and PB9
	ldr r1, [r0] 
	and r1, #0x0300 ; Bit pattern (source) 0000 0300 (0100 PB8 and 0200 PB9)

	ldr r0, =GPIOC_IDR ; PC12
	ldr r2, [r0]
	and r2, #0x1000 ; Bit pattern (source) 0000 1000 (1000 PC12)

	ldr r0, =GPIOA_IDR ; PA5
	ldr r3, [r0]
	and r3, #0x0020 ; Bit pattern (source) 0000 0020 (0020 PA5)
	
	;; Splice together bit patterns for buttons
	orr r2, r2, r3
	orr r1, r1, r2
	mov r0, r1

	pop {r1, r2, r3}
    BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set the output on the LEDs
;;; Requires:
;;;		R1: The pattern for output. Must be written as active-HIGH.
;;;		GPIOA_ODR: Address in memory for Port A output
;;; Promise:
;;; 	Will store the pattern in R1 at GPIOA_ODR.
;;; Modifies:
;;;		Subroutine does not modify any registers.

	ALIGN
Set_LED_Output PROC
	push {r0, r1}

	ldr r0, =GPIOA_ODR
	mvn r1, r1 		; As the LEDs are active-LOW, the active-HIGH pattern expected is flipped
	str r1, [r0]
	
	pop {r0, r1}
	BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Seed the RNG
;;; Requires:
;;;		R2: The value to store in dedicated register R10. Expected value [DELAY_TIME:0]
;;;			It should be noted that R10 is reset every game to ensure a new sequence.
;;; Promise: 
;;;		Returns the DELAY_TIME result in R10.
;;; Modifies:
;;; 	R10 contains the DELAY_TIME result.
;;;		Subroutine does not modify any other register.

	ALIGN
Seed_RNG PROC
	mov r10, r2

	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Linear Congruential Generator (LCG/RNG)
;;; Requires:
;;; 	R10: The seed/start value. Must be 0 < R10 <= M.
;;; 		 If R10 = 0, random value would increment by C every time (decidedly not random).
;;;		A: The multiplier. Must be 0x19660D.
;;;		C: The increment. Must be 0x3C6EF35F.
;;;		(M: The modulus. Unused as 2^32 is greater than what can be represented in 32 bits)
;;; Promise:
;;; 	Returns a quality pseudo-random number (which passes tests for randomness) in R10.
;;;		Returns the upper 2 bits of R10 in R9 (upper bits chosen for max pseudo-randomness).
;;; Modifies:
;;;		Returns the consecutive seed value in R10.
;;;		Returns the LED choice in R9.
;;;		Subroutine does not modify any other register.
;;; NOTES:
;;; 1)	The constants are parameters specific to the LCG defined in
;;; 	"Numerical Recipes" by William H. Press, Saul A. Teukolsky, William T. Vetterling and Brian P. Flannery.
;;; 2)	The modulus M is unused due to the nature of modulus and the chosen value M. 
;;;		For example, 3mod4 would result in 3 as 3 < 4. (2^32 > 2^31).

	ALIGN
RNG 	PROC
	push {r0, r1}

	;; Using the formula X = (X0*A+C)%M, and discarding %M
	ldr r0, =A
	ldr r1, =C
	mul r10, r0
	add r10, r1
	
	;; Select upper 2 bits for pseudo-random LED choice (2 bits can represent 0-3)
	ldr r0, =0xC0000000
	and r9, r10, r0
	lsr r9, #30 	; Shift so as to read the upper 2 bits as 00(0), 01(1), 10(2), or 11(3)
	
	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Wait Time
;;; Requires:
;;;		R4: The time to wait. Can be any value.
;;; Promise:
;;;		The routine will wait for the time it takes to count to the value in R4.
;;;		The value 0x1770 results in approx. 1s, using only the subs and bne instructions below.
;;; Modifies:
;;;		The subroutine does not modify any registers.

	ALIGN
Wait 	PROC
	push {r4}

wait_loop
	subs r4, #1
	bne wait_loop
	
	pop {r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Signal End Success
;;; Requires:
;;;		WINNING_SIGNAL_TIME: The time to display the winning signal. Should be greater than 0.
;;; 	REACT_TIME: Predefined time to hold the LED. Works best if approx. 0x3FC00.
;;;		PRELIM_WAIT: The predefined wait time between rounds/games.
;;; Promise:
;;; 	Will cycle a 'twinkling' LED pattern (alike arcade machines) at approx. 1Hz,
;;;		for WINNING_SIGNAL_TIME.
;;;	Modifies:
;;;		Subroutine does not modify any registers.

	ALIGN
End_Success 	PROC
	push {lr, r0, r1, r4}

	ldr r0, =WINNING_SIGNAL_TIME
signal_win
	;; Light up 2 LEDs for the twinkling pattern and hold
	mov r1, #0x0A00
	bl Set_LED_Output
	ldr r4, =REACT_TIME
	bl Wait
	
	;; Reduce the WINNING_SIGNAL_TIME
	subs r0, #1
	beq end_win
	
	;; Light up 2 LEDs for the twinkling pattern and hold
	mov r1, #0x1400
	bl Set_LED_Output
	ldr r4, =REACT_TIME
	bl Wait
	
	;; Reduce the WINNING_SIGNAL_TIME
	subs r0, #1
	beq end_win
	b signal_win

end_win
	;; Turn off LEDs to signal the end of the game
	mov r1, #0x0
	bl Set_LED_Output
	
	ldr r4, =PRELIM_WAIT
	bl Wait
	
	pop {lr, r0, r1, r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Signal End Failure
;;; Requires:
;;;		LOSING_SIGNAL_TIME: The time to display the losing signal. Should be greater than 0.
;;; 	REACT_TIME: Predefined time to hold the LED. Works best if approx. 0x3FC00.
;;;		PRELIM_WAIT: The predefined wait time between rounds/games.
;;; Promise:
;;; 	Will blink an LED pattern representing the binary value of the rounds completed before failure,
;;;		at approx. 1Hz if DELAY_TIME is 0x27100 for LOSING_SIGNAL_TIME.
;;;	Modifies:
;;;		Subroutine does not modify any registers.

	ALIGN
End_Failure PROC
	push {lr, r0, r1, r4}

	ldr r0, =LOSING_SIGNAL_TIME
signal_fail
	;; Light up binary LED pattern for the player's score and hold
	bl Select_LED_Binary
	bl Set_LED_Output
	ldr r4, =REACT_TIME
	bl Wait
	
	;; Reduce the LOSING_SIGNAL_TIME
	subs r0, #1
	beq end_fail
	
	;; Turn off LEDs and hold
	mov r1, #0x0
	bl Set_LED_Output
	ldr r4, =REACT_TIME
	bl Wait
	
	;; Reduce the LOSING_SIGNAL_TIME
	subs r0, #1
	beq end_fail
	b signal_fail
	
end_fail
	;; Turn off LEDs to signal the end of the game
	mov r1, #0x0
	bl Set_LED_Output
	
	ldr r4, =PRELIM_WAIT
	bl Wait
	
	pop {lr, r0, r1, r4}
	BX LR
	ENDP

		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Select LED and corresponding Button Pattern
;;; Requires:
;;; 	R9: The RNG value. Must be between 0-3, else default is case_0.
;;; Promise:
;;;		Turns on an LED corresponding to R9. Sets the expected correct button pattern.
;;; Modifies:
;;;		Sets the expected button pattern in R2.
;;;		Subroutine does not modify any other register.

	ALIGN
Select_LED 	PROC
	push {r0}

	cmp r9, #3 ; If the 2 bits are somehow > 3, default to LED 1
	bhi case_0

	;; Starting at the base case, jump to the X case by formula: addr = (base_addr + X*4)
	;; The cases are aligned by 4 bytes.
	ldr r0, =Branch_Table_LEDs
	ldr pc,[r0, r9, lsl #2]

	ALIGN 4
case_0 
	mov r1, #0x0200 ; Output pattern for LED 1
	mov r2, #0x1220 ; Input pattern for Button 1
	pop {r0}
	BX LR

case_1
	mov r1, #0x0400 ; Output pattern for LED 2
	mov r2, #0x1120 ; Input pattern for Button 2
	pop {r0}
	BX LR

case_2
	mov r1, #0x0800 ; Output pattern for LED 3
	mov r2, #0x0320 ; Input pattern for Button 3
	pop {r0}
	BX LR

case_3
	mov r1, #0x1000 ; Output pattern for LED 4
	mov r2, #0x1300 ; Input pattern for Button 4
	pop {r0}
	BX LR
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Select LEDs for Binary Pattern
;;; Requires:
;;; 	R12: The player's score. Expected value [NUM_CYCLES:0].
;;; Promise:
;;;		Set LEDs for binary pattern corresponding to the player's score.
;;; Modifies:
;;;		Sets the pattern in R1.
;;;		Subroutine does not modify any other register.

	ALIGN
Select_LED_Binary 	PROC
	push {r0}

	cmp r12, #15 ; If the score is > 15, default to 15
	bhi case_15_rounds

	;; Starting at the base case, jump to the X case by formula: addr = (base_addr + X*4)
	;; The cases are aligned by 4 bytes.
	ldr r0, =Branch_Table_Binary
	ldr pc,[r0, r12, lsl #2]

	ALIGN 4
case_0_rounds
	mov r1, #0x0000 ; Output pattern for 0000
	pop {r0}
	BX LR

case_1_rounds
	mov r1, #0x1000 ; Output pattern for 0001
	pop {r0}
	BX LR

case_2_rounds
	mov r1, #0x0800 ; Output pattern for 0010
	pop {r0}
	BX LR

case_3_rounds
	mov r1, #0x1800 ; Output pattern for 0011
	pop {r0}
	BX LR

case_4_rounds
	mov r1, #0x0400 ; Output pattern for 0100
	pop {r0}
	BX LR

case_5_rounds
	mov r1, #0x1400 ; Output pattern for 0101
	pop {r0}
	BX LR

case_6_rounds
	mov r1, #0x0C00 ; Output pattern for 0110
	pop {r0}
	BX LR

case_7_rounds
	mov r1, #0x1C00 ; Output pattern for 0111
	pop {r0}
	BX LR

case_8_rounds
	mov r1, #0x0200 ; Output pattern for 1000
	pop {r0}
	BX LR

case_9_rounds
	mov r1, #0x1200 ; Output pattern for 1001
	pop {r0}
	BX LR

case_10_rounds
	mov r1, #0x0A00 ; Output pattern for 1010
	pop {r0}
	BX LR

case_11_rounds
	mov r1, #0x1A00 ; Output pattern for 1011
	pop {r0}
	BX LR

case_12_rounds
	mov r1, #0x0600 ; Output pattern for 1100
	pop {r0}
	BX LR

case_13_rounds
	mov r1, #0x1600 ; Output pattern for 1101
	pop {r0}
	BX LR

case_14_rounds
	mov r1, #0x0E00 ; Output pattern for 1110
	pop {r0}
	BX LR

case_15_rounds
	mov r1, #0x1E00 ; Output pattern for 1111
	pop {r0}
	BX LR
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Branch Table for LED and Button choice

	ALIGN
Branch_Table_LEDs
	DCD case_0
	DCD case_1
	DCD case_2
	DCD case_3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Branch Table for LEDs based on completed rounds before failure

	ALIGN
Branch_Table_Binary
	DCD case_0_rounds
	DCD case_1_rounds
	DCD case_2_rounds
	DCD case_3_rounds
	DCD case_4_rounds
	DCD case_5_rounds
	DCD case_6_rounds
	DCD case_7_rounds
	DCD case_8_rounds
	DCD case_9_rounds
	DCD case_10_rounds
	DCD case_11_rounds
	DCD case_12_rounds
	DCD case_13_rounds
	DCD case_14_rounds
	DCD case_15_rounds
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ALIGN
		
		
	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;