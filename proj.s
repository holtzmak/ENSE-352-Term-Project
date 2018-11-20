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

;The onboard LEDS are on port C bits 8 and 9
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

; Times for delay routines
DELAYTIME	EQU		1600000		; (200 ms/24MHz PLL)

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
	BL GPIO_ClockInit
	BL GPIO_init

;; Cycling LEDS until button is pressed (no touch r2, r3!!!)
reload_leds	
	ldr r0, =GPIOA_ODR
	mov r1, #0x0200
	mvn r1, r1
	str r1, [r0]
	
	ldr r2, =DELAYTIME
	ldr r3, =4
waiting_for_player
;; Check if user has pressed a button 
	ldr r0, =GPIOB_IDR ; PB8 and PB9
	ldr r1, [r0] 
	and r1, #0x0300 ; Bit pattern (source) 0000 0300 (0100 PB8 and 0200 PB9)
	ldr r0, =GPIOC_IDR ; PC12
	ldr r4, [r0]
	and r4, #0x1000 ; Bit pattern (source) 0000 1000 (1000 PC12)
	ldr r0, =GPIOA_IDR ; PA5
	ldr r5, [r0]
	and r5, #0x0020 ; Bit pattern (source) 0000 0020 (0020 PA5)
	
	;; Splice together bit patterns for buttons
	orr r4, r4, r5
	orr r1, r1, r4
	cmp r1, #0x1320 ; Bit pattern when no button is pressed is 0000 1320
	bne normal_gameplay
	
	;; If DELAYTIME has not expried, keep the LED on
	subs r2, #1
	bne waiting_for_player
	
	ldr r0, =GPIOA_ODR
	ldr r1, [r0]
	lsl r1, #1 ; Shift pattern to turn on next LED
	str r1, [r0]
	
	;; If the 4th LED was just on, turn on the 1st LED
	subs r3, #1
	beq reload_leds
	
	ldr r2, =DELAYTIME
	b waiting_for_player
	
normal_gameplay
	ldr r0, =GPIOA_ODR
	mov r1, #0x0
	mvn r1, r1
	str r1, [r0]
	b normal_gameplay
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutines

	ALIGN

;This routine will enable the clock for the Ports that you need	
	ALIGN
GPIO_ClockInit PROC

	; Registers   .. RCC_APB2ENR
	; ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12 *****NEW for 2015**** SW5(Green): PA5
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
	ldr r0, =RCC_APB2ENR ; LEDS & SW
	mov r1, #0x001C ; Bit pattern 0000 001C -> IOPA at bit 2, IOPB at bit 3, IOPC at bit 4
	str r1, [r0]
	
	BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ALIGN

;This routine enables the GPIO for the LED's.  By default the I/O lines are input so we only need to configure for ouptut.
	ALIGN
GPIO_init  PROC
	
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
	ldr r0, =GPIOA_CRH ; LEDS
	ldr r1, =0x00033330 ; Bit pattern 0003 3330 -> CRH ports 9-12 with below pattern
						; Output mode, GP output push-pull (00) & max speed 50MHz (11) [0011=3]
	str r1, [r0]

    BX LR
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	ALIGN


	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;