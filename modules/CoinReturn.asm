/*
===================================================================
COMP2121                                                        
Project - Vending Machine
CoinReturn


Sets up system to return the coins entered
===================================================================
*/

returnScreen:
  push temp
  in temp, SREG
  push temp

  mov coinsToReturn, coinsEntered           ; store the coins entered as coins that have to be returned

  clear ReturnCounter
  
  ldi temp1, turnMotOn
  out PORTE, temp1                          ; turn the motor on to begin returning

  set_reg currFlag, inSelect                ; systems changes back to select mode

  clr temp
  out PORTC, temp                           ; turns off any previously lit LEDs

  pop temp
  out SREG, temp
  pop temp
  
  ret

