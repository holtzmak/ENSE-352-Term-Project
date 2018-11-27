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
GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register
GPIOA_BSRR	EQU		0x40010810	; (0x10) Port Bit Set/Reset Register
GPIOA_BRR	EQU		0x40010814	; (0x14) Port Bit Reset Register
GPIOA_LCKR	EQU		0x40010818	; (0x18) Port Configuration Lock Register

;PORT B GPIO - Base Addr: 0x40010C00
GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register
GPIOB_BSRR	EQU		0x40010C10	; (0x10) Port Bit Set/Reset Register
GPIOB_BRR	EQU		0x40010C14	; (0x14) Port Bit Reset Register
GPIOB_LCKR	EQU		0x40010C18	; (0x18) Port Configuration Lock Register

;PORT C GPIO - Base Addr: 0x40011000
GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register
GPIOC_BSRR	EQU		0x40011010	; (0x10) Port Bit Set/Reset Register
GPIOC_BRR	EQU		0x40011014	; (0x14) Port Bit Reset Register
GPIOC_LCKR	EQU		0x40011018	; (0x18) Port Configuration Lock Register

;Registers for configuring and enabling the clocks
;RCC Registers - Base Addr: 0x40021000
RCC_CR		EQU		0x40021000	; Clock Control Register
RCC_CFGR	EQU		0x40021004	; Clock Configuration Register
RCC_CIR		EQU		0x40021008	; Clock Interrupt Register
RCC_APB2RSTR	EQU	0x4002100C	; APB2 Peripheral Reset Register
RCC_APB1RSTR	EQU	0x40021010	; APB1 Peripheral Reset Register
RCC_AHBENR	EQU		0x40021014	; AHB Peripheral Clock Enable Register

RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register  -- Used

RCC_APB1ENR	EQU		0x4002101C	; APB1 Peripheral Clock Enable Register
RCC_BDCR	EQU		0x40021020	; Backup Domain Control Register
RCC_CSR		EQU		0x40021024	; Control/Status Register
RCC_CFGR2	EQU		0x4002102C	; Clock Configuration Register 2

; RTC Registers - Base Addr: 0x40002800
RTC_CNTL	EQU		0x4000281C	; RTC Counter Low

; Times for delay routines
DELAY_TIME  	EQU     160000
PRELIM_WAIT		EQU		1600000
REACT_TIME		EQU		1600000000
NUM_CYCLES		EQU		16
WINNING_SIGNAL_TIME	EQU 16000000
LOSING_SIGNAL_TIME	EQU 16000000
	
; Constants for RNG routine
A			EQU 	0x19660D
C			EQU     0x3C6EF35F
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Vector Table Mapped to Address 0 at Reset
            AREA    RESET, Data, READONLY
            EXPORT  __Vectors

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__Vectors	DCD		INITIAL_MSP			; stack pointer value when stack is empty
        	DCD		Reset_Handler		; reset vector

            AREA    MYCODE, CODE, READONLY
			EXPORT	Reset_Handler

			ENTRY

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Author: Kelly Holtzman

Reset_Handler		PROC
;; Initialize I/O lines
	bl GPIO_ClockInit
	bl GPIO_init

gameplay
;; Cycling LEDS until button is pressed (UC1)
	bl waiting_for_player
;; Enter normal gameplay (UC2)
	bl normal_gameplay
	
	b gameplay
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutines

;This routine will enable the clock for the Ports that you need	
	ALIGN
GPIO_ClockInit PROC
	push {r0, r1}
	; Registers   .. RCC_APB2ENR
	; ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12 SW5(Green): PA5
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
	ldr r0, =RCC_APB2ENR ; LEDS & SW
	mov r1, #0x001C ; Bit pattern 0000 001C -> IOPA at bit 2, IOPB at bit 3, IOPC at bit 4
	str r1, [r0]
	
	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine enables the GPIO for the LED's.  By default the I/O lines are input so we only need to configure for ouptut.
	ALIGN
GPIO_init  PROC
	push {r0, r1}
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
	ldr r0, =GPIOA_CRH ; LEDS
	ldr r1, =0x00033330 ; Bit pattern 0003 3330 -> CRH ports 9-12 with below pattern
						; Output mode, GP output push-pull (00) & max speed 50MHz (11) [0011=3]
	str r1, [r0]

	pop {r0, r1}
    BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine waits for the player
	ALIGN
waiting_for_player PROC
	push {lr, r0, r1, r3}
	
cycling_prep_forwards
	mov r1, #0x0200 ; Pattern for LED 1
	bl turn_on_led
	ldr r2, =DELAY_TIME
	ldr r3, =3 ; LED count
	
cycle_forwards
	bl get_btn_bits
	cmp r0, #0x1320 ; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	;; If DELAYTIME has not expried, keep the LED on
	subs r2, #1
	bne cycle_forwards
	
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsl r1, #1 ; Shift pattern to turn on next forward LED
	str r1, [r0]
	
	;; If the 4th LED was just on, cycle backwards
	subs r3, #1
	beq cycling_prep_backwards
	
	ldr r2, =DELAY_TIME
	b cycle_forwards
	
cycling_prep_backwards
	ldr r2, =DELAY_TIME
	ldr r3, =3 ; LED count

cycle_backwards
	bl get_btn_bits
	cmp r0, #0x1320 ; Bit pattern when no button is pressed is 0000 1320
	bne start_gameplay
	
	;; If DELAYTIME has not expried, keep the LED on
	subs r2, #1
	bne cycle_backwards
	
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsr r1, #1 ; Shift pattern to turn on next backwards LED
	str r1, [r0]
	
	;; If the 1st LED was just on, cycle forwards
	subs r3, #1
	beq cycling_prep_forwards
	
	ldr r2, =DELAY_TIME
	b cycle_backwards
	
start_gameplay
	mov r1, #0x0
	bl turn_on_led
	pop {lr, r0, r1, r3}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ALIGN
normal_gameplay PROC
	push {lr, r0, r1, r2, r3}
	bl seed_rng
	ldr r11, =NUM_CYCLES
start_round
	ldr r4, =PRELIM_WAIT
	bl wait
	bl rng ; R9 now has led num
	
	; turn on led
	; get btn pattern
	cmp r9, #0
	moveq r1, #0x0200
	moveq r2, #0x1220
	cmp r9, #1
	moveq r1, #0x0400
	moveq r2, #0x1120
	cmp r9, #2
	moveq r1, #0x0800
	moveq r2, #0x0320
	cmp r9, #3
	moveq r1, #0x1000
	moveq r2, #0x1300
	
	bl turn_on_led
	ldr r3, =REACT_TIME
	
reaction_time
	cmp r3, #0
	beq kill
	bl get_btn_bits
	cmp r0, #0x1320 ; Bit pattern when no button is pressed is 0000 1320
	subeq r3, #1000
	beq reaction_time
	cmp r0, r2 ; Bit pattern when red button pressed is 0000 1220
	beq good
	bne kill

good
	mov r1, #0x0
	bl turn_on_led
	add r12, #1
	subs r11, #1
	bne start_round
	bl end_success
	
	pop {lr, r0, r1, r2, r3}
	BX LR

kill
	mov r1, #0x0
	bl turn_on_led
	subs r11, #1
	bl end_failure

	pop {lr, r0, r1, r2, r3}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine grabs the button bits
	ALIGN
get_btn_bits  PROC
;; ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12 SW5(Green): PA5
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
	; "return" value in r0

    BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will turn on an led, pattern passed in r1
	ALIGN
turn_on_led PROC
	push {r0, r1}
	ldr r0, =GPIOA_ODR
	mvn r1, r1
	str r1, [r0]
	
	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will RNG
	ALIGN
rng PROC
	push {r0, r1}
	ldr r0, =A
	ldr r1, =C
	mul r10, r0
	add r10, r1
	
	; Grab upper 2 bits for random LED
	ldr r0, =0xC0000000
	and r9, r10, r0
	lsr r9, #30
	
	pop {r0, r1}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will grab counter bits
	ALIGN
seed_rng PROC
	push {r0}
	mov r10, r2
	
	pop {r0}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will wait
	ALIGN
wait PROC
	push {r4}
wait_loop
	subs r4, #1
	bne wait_loop
	
	pop {r4}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will end succ
	ALIGN
end_success PROC
	push {lr}
	mov r1, #0x1E00 ; all led on
	bl turn_on_led
	ldr r4, =WINNING_SIGNAL_TIME
	bl wait
	mov r1, #0x0 ; all led off
	bl turn_on_led
	pop {lr}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This routine will end fail
	ALIGN
end_failure PROC
	push {lr}
	mov r1, #0x0 ; all led off
	bl turn_on_led
	ldr r4, =LOSING_SIGNAL_TIME
	bl wait
	pop {lr}
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	ALIGN


	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;