/*
===================================================================
COMP2121                                                        
Project - Vending Machine
Main


This is where the main logic for the whole system takes place, the
screen changes are managed here as well
===================================================================
*/
								/* ========= */
								/* Constants */
								/* ========= */
.equ inStart =  1
.equ inSelect = 2
.equ inCoin = 3
.equ inEmpty = 4
.equ ADCCoin = 6
.equ inReturn = 5
.equ inDeliver = 7
.equ inAdmin = 8							; flags to denote the current screen

.equ aKey = 20
.equ bKey = 21
.equ cKey = 22
.equ dKey = 23
.equ asterix = 24
.equ hash = 25
.equ zeroButton = 26 						; constants for non-numerical key presses

.equ turnLEDOff = 0b11010000
.equ turnLEDOn =  0b00101000
.equ turnLEDMotOn =  0b11111111
.equ turnMotOn = 0b11010000 				; binary values to provide independant control os components on the same port

							/* ================ */
							/* Useful Registers */
							/* ================ */

.def currFlag = r4 							; stores constant denoting the current screen
.def oldFlag = r5 							; stores constant denoting previous screen (used to avoid reprinting same screen)
.def keyPress = r6 							; if a key has been pressed
.def keyID = r7 							; what that key was
.def potPos = r8 							; the position of the Potentiometer
.def coinsToReturn = r9  					; number of coins left to return
.def coinsEntered = r10	 					; number of coins entered by user
.def coinsRequired = r11 					; number of coins required for item (cost)
.def currItem = r13 						; the current item being modified in Admin screen
.def asterixPressed = r14 					; whether the "*" key is pressed 

.def row = r16 								; current row in keypad thats being scanned
.def col = r17 								; current column in keypad thats being scanned
.def rmask = r18                			; mask for row
.def cmask = r19                			; mask for column
.def temp = r20								; first temporary register
.def temp1 = r21 							; second temporary register
.def ADCLow = r22 							; store low byte of ADC input
.def ADCHigh = r23							; store high byte of ADC input

.dseg 
						/* ====================== */
						/* Counters used by timer */
						/* ====================== */

	LEDCounter:									; to turn off LEDs
	    .byte 2             					
	DisplayCounter:								; to switch displays
	    .byte 2             					
	ReturnCounter:								; to control coin return
		.byte 2
	AsterixCounter: 							; to watch for 5 second "*" press
		.byte 2
	ADCCounter: 								; to enable the ADC reader
		.byte 2

							/* =============== */
							/* Data Structures */
							/* =============== */

	Inventory: 									; 9 byte array to store stock number (item ID = index + 1)
		.byte 9
	Cost: 										; 9 byte array to store cost (item ID = index + 1)
		.byte 9	

						/* ====================== */
						/* Interrupt Vector Table */
						/* ====================== */
.cseg
	.org 0x0000
	   jmp RESET
	.org INT0addr 								; handling the push button 1 interrupt
		jmp EXT_INT0		
	.org INT1addr 								; handling the push buttong 0 interrupt
	   jmp EXT_INT1
	.org OVF0addr 								; handling interrupt for timer 0
	   jmp Timer0OVF        
	.org ADCCaddr 								; handling ADC reader interrupt
		jmp EXT_POT


	jmp DEFAULT          						; default service for all other interrupts.
	DEFAULT:  reti          					; no service

					/* ============================ */
					/* Including all helper modules */
					/* ============================ */

.include "m2560def.inc"
.include "modules/macros.asm"
.include "modules/lcd.asm"
.include "modules/timer0.asm"
.include "modules/keypad.asm"

							/* =============== */
							/* RESET interrupt */
							/* =============== */

RESET: 
	ldi temp1, high(RAMEND) 					; Initialize stack pointer
	out SPH, temp1
	ldi temp1, low(RAMEND)
	out SPL, temp1
	ldi temp1, PORTLDIR
	sts DDRL, temp1								; sets lower bits as input and upper as output for key pad

	rcall InitArrays							; initializes the Cost & Inventory arrays with appropriate values

	ser temp1 									
	out DDRC, temp1 
	out DDRE, temp1
	out DDRG, temp1								; set Port C,E &  as output - reset all bits to 0 (ser = set all bits in register)
	
	clr temp
	out DDRD, temp								; set PORTD (external interrupts) as input

	ldi temp, (1 << INT0) | (1 << INT1)
	out EIMSK, temp  							; unmasking two external button interrupts

    ser r16
    out DDRF, r16
    out DDRA, r16
    clr r16
    out PORTF, r16
    out PORTA, r16              				; setting PORTA & PORTF as output


    do_lcd_command 0b00111000 					; 2x5x7 (2 lines, 5x7 is the font)
    rcall sleep_5ms
    do_lcd_command 0b00111000 					; 2x5x7
    rcall sleep_1ms
    do_lcd_command 0b00111000 					; 2x5x7
    do_lcd_command 0b00111000 					; 2x5x7
    do_lcd_command 0b00001000 					; display off?
    do_lcd_command 0b00000001 					; clear display
    do_lcd_command 0b00000110 					; increment, no display shift
    do_lcd_command 0b00001110 					; Cursor on, bar, no blink

	set_reg currFlag, inStart 					; set flag to start screen
	clr oldFlag 								; clear old flag to tell main to update screen
	clear DisplayCounter 						; start timer to change display
	clr asterixPressed 							; "*" not currently pressed

    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        					; Prescaling value=8
    ldi temp, 1<<TOIE0      					; = 128 microseconds
    sts TIMSK0, temp        					; T/C0 interrupt enable

	clr coinsToReturn

	// REFS0: sets up voltage reference, 0b01 provides the reference with the best range
	// setting ADLAR to 1 left aligns the 10 output bits within the 16 bit output register
	// MUX0 to MUX5 choose the input pin/mode/gain. 0b10000 chooses PK8 on the board
	// ADIE enables the ADC interrupt, which interrupts when a conversion is finished
	// ADPS0 chooses the ADC clock divider. 0b111 uses a 128 divider to get a 125 kHz ADC
	//      clock which is within the recommended range of 50 - 200 kHz
	ldi temp, (0b01 << REFS0) | (0 << ADLAR) | (0 << MUX0)
	sts ADMUX, temp

	ldi temp, (1 << MUX5)
	sts ADCSRB, temp

	ldi temp, (1 << ADEN) | (1 << ADIE) | (0b111 << ADPS0) 
	sts ADCSRA, temp

	sei



main:
	cp currFlag, oldFlag						; check if one of the functions have changed the flag
	brne update									; screen update needed 
	
	ldi temp, 0xFF
	cp keyPress, temp
	brne end									; if key not pressed no update needed 
												; else if is pressed then one of the screens might need updating
	update:
	mov oldFlag, currFlag						; update flags

	mov temp, currFlag
	

				/* check the flag to see which screen function needs to be called */
				/* ============================================================== */
checkStart:
	cpi temp, inStart		
	brne checkAdmin
	rcall startScreen
checkAdmin:
	cpi temp, inAdmin		
	brne checkSelect
	rcall adminScreen
checkSelect:
	cpi temp, inSelect
	brne checkEmpty
	rcall selectScreen		
checkEmpty:
	cpi temp, inEmpty
	brne checkCoin
	rcall emptyScreen
checkCoin:
	cpi temp, inCoin
	brne checkReturn
	rcall coinScreen
checkReturn:
	cpi temp, inReturn
	brne checkDeliver
	rcall returnScreen
checkDeliver:
	cpi temp, inDeliver
	brne end
	rcall deliverScreen
	
end:
	rjmp init_loop

				/* helper functions that check update flags if required */
				/* ==================================================== */


checkCoins:										; during abort ("#"), check coins entered to go back to select or coin return
    push temp
    in temp, SREG
    push temp

	ldi temp, ADCCoin 							; if not in coin input skip the whole thind
	cp currFlag, temp
	brne endFunction

	clr temp
	cp coinsEntered, temp 						; checking coins entered
	brne retCoin 								

	set_reg currFlag, inSelect					; no coins have been entered so go back to select
	rjmp endF

	retCoin:									; coins have been entered so move onto coin return
	set_reg currFlag, inReturn

	endFunction:
	rjmp endF	

start_to_select: 								; moving from start screen to select screen
    push temp
    in temp, SREG
    push temp

    mov temp, currFlag
    cpi temp, inStart              				; checking whether the start screen is open
    brne endFunction
                                				; not in start screen, so keep going
    
    set_reg currFlag, inSelect
	clr_reg keyPress							; ignore this key press
	rjmp endF

empty_to_select:								; going from empty screen to select screen
    push temp
    in temp, SREG
    push temp

    mov temp, currFlag
    cpi temp, inEmpty              				; checking whether the empty screen is open
    brne endF 
												; not in empty screen, so keep going
	clr temp
	out PORTC, temp                     
	out PORTE, temp
    
    set_reg currFlag, inSelect
	clr_reg keyPress							; ignore this key press
	rjmp endF

select_to_admin:								; going from select screen to admin screen
    push temp
    in temp, SREG
    push temp
	push r26
	push r27

    mov temp, oldFlag
    cpi temp, inSelect              			; checking whether the select screen is open
    brne endF 

	lds r26, AsterixCounter
    lds r27, AsterixCounter+1

	cpi r26, low(5000*INTS_PER_MS)        		; check whether "*" held down for 5 seconds
    ldi temp, high(5000*INTS_PER_MS) 
    cpc r27, temp

	pop r27
	pop r26

	brne endF									; button not held down for 5 seconds yet
 
    set_reg currFlag, inAdmin
	clr_reg keyPress							; ignore this key press
	rjmp endF

deliver_to_select: 								; going from deliver screen back to select screen
	push temp
    in temp, SREG
	push temp

	mov temp, currFlag
    cpi temp, inDeliver              			; checking whether the deliver screen is open
    brne endF 

    set_reg currFlag, inSelect
	ldi temp, 0
	out PORTE, temp     						; turn off motor 

    endF:										; common epilogue for all helper functions
    pop temp
    out SREG, temp
    pop temp
    ret 

    						/* include different screen files */
							/* ============================== */

.include "modules/AdminScreen.asm"
.include "modules/CoinReturn.asm"
.include "modules/CoinScreen.asm"
.include "modules/DeliverScreen.asm"
.include "modules/EmptyScreen.asm"
.include "modules/SelectScreen.asm"
.include "modules/StartScreen.asm"

					/* initialize data structures to default values */
					/* ============================================ */

initArrays:
	push temp
	in temp, SREG
	push temp
	push temp1
	
	ldi temp1, 1

	loop:
	cpi temp1, 10 								; loop through all items
	breq endLoop

	mov r16, temp1
	set_element temp1 ,Inventory, r16 			; set stock = item ID

	rcall odd_or_even 							; depending on whether the ID is odd or even, appropriate cost written to r16
	set_element temp1 ,Cost, r16 				; save cost in data structure

	inc temp1
	rjmp loop

	endLoop:
	pop temp1
	pop temp
	out SREG, temp
	pop temp
	ret

							/* getting cost for odd/even */
							/* ========================= */
odd_or_even: 									
    push temp1
	push temp
    in temp, SREG
	push temp

    /*
    	Algo to test odd/even:

        9 ->       1 0 0 1
        1 ->     & 0 0 0 1
                   -------
                   0 0 0 1

        14 ->      1 1 1 0
        1 ->     & 0 0 0 1
                   -------
                   0 0 0 0          
    */
                
    andi temp1, 1                   
    cpi temp1, 0

    breq even
    cpi temp1, 1
    breq odd

    even:
        ldi r16, 2 								; write 2 if even
        rjmp endOop
    odd: 
        ldi r16, 1 								; write 1 if odd

	endOop:
	pop temp
    out SREG, temp
	pop temp
    pop temp1
	ret

							/* External Interrupt handler for ADC */
							/* ================================== */
EXT_POT:
	push temp
	in temp, SREG
	push temp

	lds ADCLow, ADCL 	 							
    lds ADCHigh, ADCH 							; save low and high ADC readings in designated registers

	pop temp
	out SREG, temp
	pop temp

	reti

						/* External Interrupt handler for Push Button 1 */
						/* ============================================ */
EXT_INT0:
	push temp
	in temp, SREG
	push temp

	rcall empty_to_select						; to abort the empty screen if needed
	rcall adminAddItem							; to add an item if in Admin mode
	rcall debounce_sleep 						; debounce the button

	pop temp
	out SREG, temp
	pop temp
	reti

						/* External Interrupt handler for Push Button 0 */
						/* ============================================ */	

EXT_INT1:
	push temp
	in temp, SREG
	push temp

	rcall empty_to_select					; to abort the empty screen if needed
	rcall adminRemoveItem					; to remove an item if in Admin mode
	rcall debounce_sleep  					; debounce the button

	pop temp
	out SREG, temp
	pop temp
	reti
