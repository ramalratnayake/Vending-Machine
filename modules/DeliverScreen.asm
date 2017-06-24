/*
===================================================================
COMP2121                                                        
Project - Vending Machine
Deliver Screen


Delivers the item requested by user and updates inventory
===================================================================
*/


deliverScreen:
  push temp 
  in temp, SREG 
  push temp 

  do_lcd_command 0b00000001           ; clear display
  do_lcd_command 0b00000110           ; increment, no display shift
  do_lcd_command 0b00001110           ; Cursor on, bar, no blink

  do_lcd_data_i 'D' 
  do_lcd_data_i 'e' 
  do_lcd_data_i 'l' 
  do_lcd_data_i 'i' 
  do_lcd_data_i 'v' 
  do_lcd_data_i 'e' 
  do_lcd_data_i 'r' 
  do_lcd_data_i 'i' 
  do_lcd_data_i 'n' 
  do_lcd_data_i 'g' 
  do_lcd_data_i ' ' 
  do_lcd_data_i 'I' 
  do_lcd_data_i 't'   
  do_lcd_data_i 'e' 
  do_lcd_data_i 'm' 
 
  ldi temp, 0xFF                     
  out PORTC, temp
  out PORTE, temp                     ; turn on LEDS (need to set the top 2 LEDS as well)           
 
  clear displayCounter                ; start timer to change screen
  clear LEDCounter                    ; start timer to turn off LEDS
 
EndDeliver: 
  pop temp 
  out SREG, temp 
  pop temp 

ret


