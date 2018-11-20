;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Name: Kelly Holtzman
;;; Student Number: 200366225
;;; Lab: ENSE 352-093
;;; Assignment Number: Lab5 | Phases 1 & 2
;;; Program Completion Date: Nov 6, 2018

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Directives
	PRESERVE8
	THUMB
		      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    		 
;;; Equates

INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value

GPIOA_CRH	EQU		0x40010804	; (0x00) Port Configuration Register for Px15 -> Px8
GPIOA_ODR   EQU     0x4001080C  ; (0x00) Port Output Data Register for Px15 -> Px8
RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register

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
;;; This is just mainline code, will call the subroutines for Phases 1 & 2

Reset_Handler		PROC
	BL GPIO_ClockInit
	BL GPIO_init
	
	mov r3, #3 ; initialize
start_loop
	ldr r2, =DELAYTIME
	;mov r2, #2
loop
	subs r2, r2, #1
	bne loop
	ldr r0, =GPIOA_ODR
	cmp r3, #3
	moveq r1, #0x1000
	cmp r3, #2
	moveq r1, #0x0800
	cmp r3, #1
	moveq r1, #0x0400
	cmp r3, #0
	moveq r1, #0x0200
	moveq r3, #3
	subne r3, #1
	mvn r1, r1
	str r1, [r0]
	
	b start_loop

	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutines

	ALIGN

;This routine will enable the clock for the Ports that you need	
GPIO_ClockInit PROC
	ldr r0, =RCC_APB2ENR
	mov r1, #0x0004	
	str r1, [r0]

	BX LR

	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ALIGN

;This routine enables the GPIO for the LEDs 
GPIO_init  PROC
	ldr r0, =GPIOA_CRH
	ldr r1, =0x00033330
	str r1, [r0]

	BX LR

	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	ALIGN


	END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;