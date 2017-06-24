/*
===================================================================
COMP2121                                                        
Project - Vending Machine
Empty Screen


Lets the user know that there is more of this item in inventory
===================================================================
*/

emptyScreen:
	push temp1
	in temp1, SREG
	push temp1

	do_lcd_command 0b00000001 			; clear display
	do_lcd_command 0b00000110 			; increment, no display shift
	do_lcd_command 0b00001110 			; Cursor on, bar, no blink

  	do_lcd_data_i 'O' 
  	do_lcd_data_i 'u' 
	do_lcd_data_i 't' 
	do_lcd_data_i ' ' 
	do_lcd_data_i ' ' 
	do_lcd_data_i 'O' 
	do_lcd_data_i 'f' 
	do_lcd_data_i ' ' 
	do_lcd_data_i 'S' 
	do_lcd_data_i 't' 
	do_lcd_data_i 'o' 
	do_lcd_data_i 'c' 
	do_lcd_data_i 'k'   
	do_lcd_data_i ' ' 

  	do_lcd_command 0b11000000  			; break to the next line   
  	mov r16, keyID						; store the ID of requested item
  	rcall 	print_digits 				; function to print r16 

  	ldi temp1, 0xFF
  	out PORTC, temp1					; turn on all LEDs in PORTC
  	ldi temp1, turnLEDOn				
  	out PORTE, temp1					; set bits to turn on other LEDs

  	clear displayCounter				; start timer to change display
  	clear LEDCounter 					; start timer to turn off LEDs

  	pop temp1
  	out SREG, temp1
  	pop temp1
	ret