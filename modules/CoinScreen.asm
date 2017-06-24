/*
===================================================================
COMP2121                                                        
Project - Vending Machine
Coin Screen


Lets the user know how many coins they have to enter and takes in 
input from the potentiometer
===================================================================
*/


.equ potMax = 2									; constant to denote potentiometer being in full clockwise
.equ potMin = 9									; constant to denote potentiometer being in full anti-clockwise
.equ potMid = 34								; constant to denote potentiometer being anywhere in between 


coinScreen:
	mov  temp1, keyID 
	get_element temp1, Cost, coinsRequired		; copy the cost of the item from the Cost array
	clr coinsEntered

	rcall printCoinScreen						; print relevant information to LCD

  	set_reg potPos, potMid 						; set postition of POT to in between so that a false coin return doesn't start

  	clear ADCCounter							; start timer to trigger ADC reads
	set_reg currFlag, ADCCoin					; notify all functions that coins are being counted
  	rcall coinCount 							; start wating for coin input by user


ret



		
		 /* The timer constantly polls the 'in coin' flag so when we're in the coin screen, it'll start enabling   */
		 /*	the ADC reader, which in turn updates ADCLow and ADCHigh with the low and high bytes respectively.     */
		 /* ====================================================================================================== */ 	

		 /*	This function jumps to the keypad polling loop (to look for "#" to abort the process) which then jumps */
		 /*	back to this function when done to resume the coin input											   */
		 /* ====================================================================================================== */

coinCount:
		cpMax									; check if POT at max angle
	  	brge highSet

	  	cpMin									; check if POT at min angle	
	  	brlo lowSet
	  	
	  	rjmp init_loop							; POT somewhere in between so skip everything

	  	lowSet:
			ldi r17, potMax
			cp potPos, r17						; check if POT transition from high	

			brne noCoin							; otherwise assume no coin entered

			inc coinsEntered					; increase the number of coins entered
			rcall updateLEDs 					; update LEDs to reflect this 

 			cp coinsEntered, coinsRequired 		; check if no. of coins entered = no. of coins required
			brne notDone 						; if not then continue

			rcall removeItem 					; otherwise, remove item from inventory
			set_reg currFlag, inDeliver			; change screen flag to 'deliver' 
			rjmp main 							; jump to main to move onto deliver mode

			notDone:
	  		rcall printCoinScreen				; update LCD	

			noCoin:								; if no coin entered
			set_reg potPos, potMin				; set flag appropriately to denote POT position

	  		rjmp init_loop 						; jump to keypad polling loop to look for "#" to abort

		highSet:
			ldi r17, potMin
			cp potPos, r17						; check POT transitioned from low to high

			brne ignore 						; if not, then ignore 
			
			set_reg potPos, potMax				; otherwise register the high angle
			

			ignore:	
			rjmp init_loop 						; jump to keypad polling loop to look for "#" to abort		
ret

									/* printing information on LCD */
									/* =========================== */
printCoinScreen:								
	do_lcd_command 0b00000001 					; clear display
	do_lcd_command 0b00000110 					; increment, no display shift
	do_lcd_command 0b00001110 					; Cursor on, bar, no blink

  	do_lcd_data_i 'I' 
  	do_lcd_data_i 'n' 
	do_lcd_data_i 's' 
	do_lcd_data_i 'e' 
	do_lcd_data_i 'r' 
	do_lcd_data_i 't' 
	do_lcd_data_i ' ' 
	do_lcd_data_i 'C' 
	do_lcd_data_i 'o' 
	do_lcd_data_i 'i' 
	do_lcd_data_i 'n' 
	do_lcd_data_i 's' 

  	do_lcd_command 0b11000000  					; break to the next line 
	
  	mov r16, coinsRequired	
  	sub r16, coinsEntered						; calculate number of coins remaining

  	rcall print_digits 							; print this on LCD (stored in r16 now)

  	ret
 
 									/* remove the item from inventory */
									/* ============================== */
removeItem: 									
    push r16
    push r17

    mov r17, keyID 								
    get_element r17, Inventory, r16 			; get the number of items in stock

    dec r16 								
    set_element r17, Inventory, r16  			; decrement value and write back into Inventory array

    pop r17
    pop r16

	ret

								/* update LEDs to denote current inventory */
								/* ======================================= */
updateLEDS:
	push temp
	in temp, SREG
	push temp
	push coinsEntered
	push temp1
	clr r1

	ldi temp, 0 			

	LEDloop:
		cp r1, coinsEntered 					
		breq updateFinish						; while number of coins entered != 0

			lsl temp
			inc temp 							; left shift and add 1, such that no. of LEDs on reflects no. of coins entered

			dec coinsEntered 					; decrement no, of coins left to account for

			rjmp LEDloop

		updateFinish:
			out PORTC, temp 					; write value to PORTE

	pop temp1
	pop coinsEntered
	pop temp
	out SREG, temp
	pop temp

	ret
