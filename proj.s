;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Name: Kelly Holtzman
;;; Student Number: 200366225

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Directives
	PRESERVE8
	THUMB
		      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    		 
;;; Equates
INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value

;PORT A GPIO - Base Addr: 0x40010800
;GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register

;PORT B GPIO - Base Addr: 0x40010C00
;GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0
;GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register

;PORT C GPIO - Base Addr: 0x40011000
;GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
;GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register

;RCC Registers - Base Addr: 0x40021000
RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register

;Constants for RNG routine
A			EQU 	0x19660D	;
C			EQU     0x3C6EF35F	;

;Times for delays in routine
DELAY_TIME  	EQU     0x27100		; Delay Time specific to cycling LEDs at approx 1Hz
PRELIM_WAIT		EQU		0x186A00	;
REACT_TIME		EQU		0x3FC00		;
NUM_CYCLES		EQU		0x10		;
WINNING_SIGNAL_TIME	EQU 0x20		;
LOSING_SIGNAL_TIME	EQU 0x20		;

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
;;; Author: Kelly Holtzman
;;; Mainline code

Reset_Handler		PROC
;; Initialize I/O lines
	bl GPIO_ClockInit
	bl GPIO_init

gameplay
;; Cycling LEDS until button is pressed (UC1)
	bl Waiting_for_Player
;; Enter normal gameplay (UC2)
	bl Normal_Gameplay
	b gameplay
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutines

;;; This routine will enable the clock for Ports A, B, and C
	ALIGN
GPIO_ClockInit PROC
	; ENEL 384 Pushbuttons: Button 1(Red): PB8, Button 2(Black): PB9, Button 3(Blue): PC12, Button 4(Green): PA5
	; ENEL 384 board LEDs: LED 1 - PA9, LED 2 - PA10, LED 3 - PA11, LED 4 - PA12
	push {r0, r1}
	ldr r0, =RCC_APB2ENR
	mov r1, #0x001C ; Bit pattern 0000 001C for PA, PB, PC enable
	str r1, [r0]
	pop {r0, r1}

	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine enables the GPIO for the LEDs.  
;;; By default the I/O lines are input. Only Port A is configured for ouptut.
	ALIGN
GPIO_init  PROC
	; ENEL 384 board LEDs: LED 1 - PA9, LED 2 - PA10, LED 3 - PA11, LED 4 - PA12
	push {r0, r1}
	ldr r0, =GPIOA_CRH
	ldr r1, =0x00033330 ; Bit pattern 0003 3330, CRH pins 9-12 with below pattern
						; Output mode, GP output push-pull (00) & max speed 50MHz (11)
	str r1, [r0]
	pop {r0, r1}

    BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine waits for the player to start the game
	ALIGN
Waiting_for_Player PROC
	push {lr, r0, r1, r3}
	
;; The following loops cycle the leds back and forth
;; by shifting the bits in the GPIOA_ODR left or right by one bit.
;; This depends on the last LED that was on.

cycling_prep_forwards
	mov r1, #0x0200 ; Pattern for LED 1
	bl Set_LED_Output
	ldr r2, =DELAY_TIME
	ldr r3, =3 ; LED count per cycle
	
cycle_forwards
	; Check if user has pressed a button, if a button is pressed start gameplay
	bl Get_Button_Input ; Returns the button pattern in r0
	cmp r0, #0x1320 	; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	; If DELAYTIME has not expried, keep the LED on
	subs r2, #1
	bne cycle_forwards
	
	; When DELAYTIME is up, shift pattern left to turn on next forward LED
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsl r1, #1
	str r1, [r0]
	
	; If the 4th LED was just on, cycle backwards
	subs r3, #1
	beq cycling_prep_backwards
	; Else, continue cycling forwards
	ldr r2, =DELAY_TIME
	b cycle_forwards
	
cycling_prep_backwards
	ldr r2, =DELAY_TIME
	ldr r3, =3 ; LED count per cycle

cycle_backwards
	; Check if user has pressed a button, if a button is pressed start gameplay
	bl Get_Button_Input  ; Returns the button pattern in r0
	cmp r0, #0x1320 	 ; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	; If DELAYTIME has not expried, keep the LED on
	subs r2, #1
	bne cycle_backwards
	
	; Shift pattern right to turn on previous/backwards LED
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsr r1, #1
	str r1, [r0]
	
	; If the 1st LED was just on, cycle forwards
	subs r3, #1
	beq cycling_prep_forwards
	; Else, continue cycling backwards
	ldr r2, =DELAY_TIME
	b cycle_backwards
	
start_gameplay
	; Turn off LEDs to signal the end of Waiting for Player
	mov r1, #0x0
	bl Set_LED_Output

	pop {lr, r0, r1, r3}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine controls normal gameplay
	ALIGN
Normal_Gameplay PROC
	push {lr, r0, r1, r2, r3, r4}

;; Set up the current game by seeding the RNG, the number of cycles, score, and starting reaction time
	bl Seed_RNG
	ldr r11, =NUM_CYCLES
	mov r12, #0 ; Score starts at 0
	ldr r3, =REACT_TIME
	
start_round
	; The fixed wait time PRELIM_WAIT elapses
	ldr r4, =PRELIM_WAIT
	bl Wait
	; RNG the LED to turn on
	bl RNG
	; Select the chosen LED and corresponding button
	bl Select_LED
	; Turn on the chosen LED
	bl Set_LED_Output
	; Save the current reaction time
	push {r3}

;; Wait for the player to press the corresponding button to the chose LED
reaction_time
	subs r3, #1
	beq failed_reaction
	; Check if user has pressed a button
	; If no button is pressed, continue waiting
	bl Get_Button_Input
	cmp r0, #0x1320 ; Bit pattern when no button is pressed is 0000 1320
	beq reaction_time
	
;; Else, the user must have pressed a button
	cmp r0, r2
	beq good_reaction	; If the pattern matches, the user has pressed the correct button
	bne failed_reaction ; If not, the user has pressed more than one button or the wrong button

good_reaction
	; Turn off LEDs to signal the round is over
	mov r1, #0x0
	bl Set_LED_Output

	; Reduce the reaction time for the next cycle
	pop {r3}
	; Reduce reaction time
	ldr r0, =0xFF00
	lsr r3, #1
	add r3, r3, r0 ; Always at least one sec to play, one sec with consumed clock cycles is approx 0xFF00
	
	; Update the score and the number of cycles completed
	add r12, #1
	subs r11, #1
	bne start_round ; If there are still more cycles, start the next round
	
	bl End_Success  ; Else, end the game in success
	
	pop {lr, r0, r1, r2, r3, r4}
	BX LR

failed_reaction
	; Turn off LEDs to signal the round is over
	mov r1, #0x0
	bl Set_LED_Output

	; Remove r3 from the stack, no longer need to reduce reaction time
	pop {r3}

	; Update the number of cycles completed
	subs r11, #1
	bl End_Failure ; End the game in failure

	pop {lr, r0, r1, r2, r3, r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine collects the present input on the buttons 
	ALIGN
Get_Button_Input  PROC
	; ENEL 384 Pushbuttons: Button 1(Red): PB8, Button 2(Black): PB9, Button 3(Blue): PC12, Button 4(Green): PA5
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
;;; This routine will turn on an LED
	ALIGN
Set_LED_Output PROC
	push {r0, r1}
	ldr r0, =GPIOA_ODR
	mvn r1, r1 ; As the LEDs are active-LOW, the active-HIGH pattern expected is flipped
	str r1, [r0]
	
	pop {r0, r1}
	BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine will use user input (pressing a button while waiting for player)
;;; to seed the RNG
	ALIGN
Seed_RNG PROC
	mov r10, r2

	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine will generate a psuedo-random number
	ALIGN
RNG PROC
;; Using the formula (X*a+c)
	push {r0, r1}
	ldr r0, =A
	ldr r1, =C
	mul r10, r0
	add r10, r1
	
	; Select upper 2 bits for pseudo-random LED
	ldr r0, =0xC0000000
	and r9, r10, r0
	lsr r9, #30 ; Shift so as to read the 2 bits as 00(0), 01(1), 10(2), or 11(3)
	
	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine will wait for a passed amount of cycles in r4
	ALIGN
Wait PROC
	push {r4}

wait_loop
	subs r4, #1
	bne wait_loop
	
	pop {r4}
	BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine will use user input (pressing a button while waiting for player)
;;; to seed the RNG
	ALIGN
Select_LED PROC
	push {r0}
	cmp r9, #3
	bhi case_0
	ldr r0, =Branch_Table
	ldr pc,[r0,r9,lsl #2]
	align 4
	; Based on the chosen LED, set the LED pattern and expected Button Input pattern
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
;;; This routine will signal a successful end
	ALIGN
End_Success PROC
	push {lr, r0, r1, r4}

	ldr r0, =WINNING_SIGNAL_TIME
signal_win
	mov r1, #0x0A00
	bl Set_LED_Output
	ldr r4, =DELAY_TIME
	bl Wait
	
	subs r0, #1
	beq end_win
	
	mov r1, #0x1400
	bl Set_LED_Output
	ldr r4, =DELAY_TIME
	bl Wait
	
	subs r0, #1
	beq end_win
	b signal_win
end_win
	mov r1, #0x0 ; all led off
	bl Set_LED_Output
	
	ldr r4, =PRELIM_WAIT
	bl Wait
	
	pop {lr, r0, r1, r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This routine will signal a failed end
	ALIGN
End_Failure PROC
	push {lr, r0, r1, r4}
	ldr r0, =LOSING_SIGNAL_TIME
signal_fail
	mov r1, #0x0A00
	bl Set_LED_Output
	ldr r4, =DELAY_TIME
	bl Wait
	
	subs r0, #1
	beq end_fail
	
	mov r1, #0x1400
	bl Set_LED_Output
	ldr r4, =DELAY_TIME
	bl Wait
	
	subs r0, #1
	beq end_fail
	b signal_fail
	
end_fail
	mov r1, #0x0 ; all led off
	bl Set_LED_Output
	
	ldr r4, =PRELIM_WAIT
	bl Wait
	
	pop {lr, r0, r1, r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; The following code is used for selecting the LED to turn on

	ALIGN
Branch_Table
	DCD case_0
	DCD case_1
	DCD case_2
	DCD case_3
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ALIGN
		
		
	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;