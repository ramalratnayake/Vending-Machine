/*
=====================================================================
COMP2121
Project - Vending Machine
Select Screeen


Displays the select screen to the LCD while also keypad input. 
Depending on inventory, calls the coin collect screen or empty screen 
=====================================================================
*/

selectScreen:
	push temp                               ; prologue starts 
	in temp, SREG
	push temp
  push temp1

  do_lcd_command 0b00000001 		          ; clear display
  do_lcd_command 0b00000110 		          ; increment, no display shift
  do_lcd_command 0b00001110 		          ; Cursor on, bar, no blink

  do_lcd_data_i 'S' 
  do_lcd_data_i 'e' 
  do_lcd_data_i 'l' 
  do_lcd_data_i 'e' 
  do_lcd_data_i 'c' 
  do_lcd_data_i 't' 
  do_lcd_data_i ' ' 
  do_lcd_data_i 'i' 
  do_lcd_data_i 't' 
  do_lcd_data_i 'e' 
  do_lcd_data_i 'm' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' '   
  do_lcd_data_i ' ' 

  mov temp1, keyPress                     ; checking if key has been pressed
  cpi temp1, 0xFF
  brne EndSelect                          ; no key, then end function

  clr keyPress                            ; clear the flag to prevent further reprints to LCD             
  mov r16, keyID

  cpi r16, 10                             ; checking that input is only from the numbers 
  brge EndSelect

  get_element r16, Inventory, r17         ; saving the number of items of nth item (in r16) into r17
  

  cpi r17, 0
  breq empty                                  

  set_reg currFlag, inCoin                ; if not zero, then item available so move onto collecting coins

  jmp EndSelect

  empty:                                  ; if zero, then empty so set flag and end function
    set_reg currFlag, inEmpty


	EndSelect:
  pop temp1                               ; epilogue starts
	pop temp
	out SREG, temp
	pop temp
	ret
