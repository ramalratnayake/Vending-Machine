/*
======================================================================
COMP2121                                                        
Project - Vending Machine
Admin Screeen


Prints relevant data needed by the admin mode, to the LCD and updates
everytime theres an allowed input
=====================================================================
*/


adminScreen:
  push temp                                 ; start prologue        
  in temp, SREG
  push temp
  push temp1


  ser temp1
  cp keyPress, temp1                        ; check is any key has been pressed
  

  breq notDefault             

  defaultItem:                              ; if not, print details of the default item (ID = 1)
  ldi temp, 1
  mov currItem, temp

  notDefault:                               ; else, a key has been pressed so assume item has been changed if needed

  do_lcd_command 0b00000001                 ; clear display
  do_lcd_command 0b00000110                 ; increment, no display shift
  do_lcd_command 0b00001110                 ; Cursor on, bar, no blink

  do_lcd_data_i 'A' 
  do_lcd_data_i 'd' 
  do_lcd_data_i 'm' 
  do_lcd_data_i 'i' 
  do_lcd_data_i 'n' 
  do_lcd_data_i ' ' 
  do_lcd_data_i 'm' 
  do_lcd_data_i 'o' 
  do_lcd_data_i 'd' 
  do_lcd_data_i 'e' 
  do_lcd_data_i ' '

  mov r16, currItem
  rcall print_digits                      ; print the item ID 

  do_lcd_command 0b11000000               ; break to the next line 

  mov temp1, currItem
  get_element temp1, Inventory, r16       ; get value from inventory array
  rcall print_digits                      ; print inventory

  rcall addSpaces                         ; print spaces to move cost to the end of line

  mov temp1, currItem
  get_element temp1, Cost , r16           ; get value from cost array
  rcall print_digits                      ; print cost of item

  rcall AdminUpdateLEDs                   ; update the LEDs depending on inventory
  clr keyPress                            ; clear flag to acknowledge the key press

  pop temp1                               ; epilogue
  pop temp
  out SREG, temp
  pop temp

  ret 

             /* Trivial function to add required number of spaces to format LCD */
             /* =============================================================== */

  addSpaces:
  push temp
  in temp, SREG
  push temp

  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' ' 
  do_lcd_data_i ' '  
  do_lcd_data_i '$'                       ; add preceding "$" for cost printing

    pop temp
  out SREG, temp
    pop temp 

    ret

             /* Function (invoked by keypad) to change the current item */
             /* ======================================================= */

updateAdminItem:            
  push temp
  in temp, SREG
  push temp

  ldi temp, inAdmin         
  cp oldFlag, temp                        ; check if system is currently in Admin mode
  brne noUpdate

  mov currItem, keyID                     ; if so, update the item ID thats currently open

  noUpdate:                               ; otherwise don't update anything
    pop temp
  out SREG, temp
    pop temp

    ret

               /* Function (invoked by "#" press) to exit Admin mode */
               /* ================================================== */

exitAdmin:
  push temp
  in temp, SREG
  push temp 

  ldi temp, inAdmin                     ; check if system is currently in Admin mode
  cp oldFlag, temp

  brne noAdminExit

  set_reg currFlag, inSelect            ; if so, revert screen flag to select so that main will update

  clr temp1
  out PORTC, temp1
  out PORTE, temp1                      ; turn off any remaining LEDs

  noAdminExit:                          ; if not in Admin, then ignore
    pop temp
  out SREG, temp
    pop temp 

    ret

          /* Function (invoked by left push button) to decrease stock number */
            /* =============================================================== */

adminRemoveItem:
  push temp
  in temp, SREG
  push temp 
    push r16
    push r17

  ldi temp, inAdmin                     ; check if system is currently in Admin mode
  cp oldFlag, temp
  brne endRemove                        ; if not in Admin, then ignore

    set_reg keyPress, 0xFF              ; set flag to tell main to update the screen

    mov r17, currItem
    get_element r17, Inventory, r16     ; get the current stock number from inventory array

    cpi r16, 0                          ; check if already zero
    breq endRemove                      ; if zero, then don't decrement

    dec r16
    set_element r17, Inventory, r16     ; otherwise, decrement and store new value in array

    endRemove: 
    pop r17
    pop r16
    pop temp
  out SREG, temp
    pop temp 
ret

          /* Function (invoked by right push button) to increase stock number */
            /* ================================================================ */

adminAddItem:
  push temp
  in temp, SREG
  push temp 
    push r16
    push r17

  ldi temp, inAdmin                     ; check if system is currently in Admin mode
  cp oldFlag, temp
  brne endAdd                           ; if not in Admin, then ignore

    set_reg keyPress, 0xFF              ; set flag to tell main to update the screen

    mov r17, currItem
    get_element r17, Inventory, r16     ; get the current stock number from inventory array

    cpi r16, 255                        ; check if already 255 (changed from orginal limit of 10 to satisfy extention task)
    breq endAdd                         ; if 255, then don't increment

    inc r16
    set_element r17, Inventory, r16     ; otherwise, increment and store new value in array

    endAdd:
    pop r17
    pop r16
    pop temp
  out SREG, temp
    pop temp 
ret

              /* Function (invoked by "A" button) to increase cost */
                /* ================================================= */

adminIncCost:
  push temp
  in temp, SREG
  push temp 
    push r16
    push r17

  ldi temp, inAdmin                     ; check if system is currently in Admin mode
  cp oldFlag, temp
  brne endIncCost                       ; if not in Admin, then ignore

    set_reg keyPress, 0xFF              ; set flag to tell main to update the screen

    mov r17, currItem
    get_element r17, Cost, r16          ; get current cost of selected item

    cpi r16, 3                          ; check if already 3 (max value assigned by spec)
    breq endIncCost                     ; if 3, then dont increment

    inc r16
    set_element r17, Cost, r16          ; else, increment and store value in cost array

    endIncCost:
    pop r17
    pop r16
    pop temp
  out SREG, temp
    pop temp 
ret


              /* Function (invoked by "B" button) to decrease cost */
                /* ================================================= */

adminDecCost:
  push temp
  in temp, SREG
  push temp 
    push r16
    push r17

  ldi temp, inAdmin                   ; check if system is currently in Admin mode
  cp oldFlag, temp
  brne endDecCost                     ; if not in Admin, then ignore

    set_reg keyPress, 0xFF            ; set flag to tell main to update the screen

    mov r17, currItem
    get_element r17, Cost, r16        ; get current cost of selected item

    cpi r16, 1                        ; check if already 1 (min value assigned by spec)
    breq endDecCost                   ; if 1, then dont decrement

    dec r16
    set_element r17, Cost, r16        ; else, decrement and store value in cost array

    endDecCost:
    pop r17
    pop r16
    pop temp
  out SREG, temp
    pop temp 
ret

              /* Function (invoked by "C" button) to clear the stock */
                /* =================================================== */

resetNumItems:
  push temp
  in temp, SREG
  push temp 
    push r16
    push r17

  ldi temp, inAdmin                   ; check if system is currently in Admin mode
  cp oldFlag, temp
  brne endReset                       ; if not in Admin, then ignore

    set_reg keyPress, 0xFF            ; set flag to tell main to update the screen

    mov r17, currItem
    clr r16
    set_element r17, Inventory, r16   ; load a zero in Inventory array to denote empty stock

    endReset:
    pop r17
    pop r16
    pop temp
  out SREG, temp
    pop temp 
ret

            /* Function to update LEDs to reflect the number of items in stock */
            /* =============================================================== */

AdminUpdateLEDs:
  push temp
  in temp, SREG
  push temp
  push r17
  push temp1

  clr r1
  ldi temp, 0

  mov r17, currItem
  get_element r17, Inventory, temp1   ; get the current number of items in stock from Inventory array
  push temp1

  AdminLEDloop:                       ; setting the appropriate binary value to appropriately toggle the first 8 LEDs
  cp r1, temp1                        ; if zero, then loop is done
  breq LEDFinish

    lsl temp                          ; left shift 
    inc temp                          ; and add 1 to binary value, such that number of LEDs turned on equals inventory
    dec temp1                         ; decrement copied inventory value to control loop
    rjmp AdminLEDloop

  LEDFinish:                          ; finish counting first 9, so output to PORTC
    out PORTC, temp
  
  pop temp1                           ; reset the copied inventory value
  
  cpi temp1, 9                        ; compare to 9 to determine if the two LEDs above (on a different port) need to be turned on

  brlo noOtherLights                  ; if lower than, then no other lights needed
  breq oneLight                       ; if equal to 9, then one more light is needed
  rjmp twoLights                      ; if anything greater, then other two LEDs needed (intended saturation for inventory > 10)

  oneLight:
  ldi temp1, 0b00001000               ; load specific value to only turn on one LED (and not the other LED or motor)
  jmp printLights

  twoLights:
  ldi temp1, 0b00101000               ; load specific value to only turn the LEDs (and not the motor)
  jmp printLights

  noOtherLights:
  clr temp1                           ; clear the value to not turn off the entra lights

  printLights:
  out PORTE, temp1                    ; write loaded value into PORTE

  endLEDUpdate:
  pop temp1
  pop r17
  pop temp
  out SREG, temp
  pop temp

  ret