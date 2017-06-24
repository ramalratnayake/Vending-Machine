/*
===================================================================
COMP2121                                                        
Project - Vending Machine
Keypad


Looping through each key and polling it's status 
===================================================================
*/

.equ PORTLDIR = 0xF0                ; 1111 0000 to set lower pins to input and upper pins to output
.equ INITCOLMASK = 0xEF             ; 1110 1111 to check the rightmost column (0 for logic low & 1 for logic high)
.equ INITROWMASK = 0x01             ; 0000 0001 to check the top row (1 to read input) 
.equ ROWMASK = 0x0F                 ; for obtaining input from port L

init_loop:
    push temp1
    in temp1, SREG
    push temp1
    push temp

    ldi temp, inDeliver
    cp currFlag, temp
    brne startLoop                  ; if in the deliver screen, all key input should be ignored

    rjmp endKeypad

    startLoop:
    ldi cmask, INITCOLMASK
    clr col 
    

colloop:
    cpi col, 4                      ; if it reached the end of the columns
    brne cont                   
    rjmp endKeypad 
    cont:
    sts PORTL, cmask                ; send logic low to certain column to read by row port

    ldi temp, 0xFF   

delay:  
    dec temp
    brne delay                      ; delays process for 255 clocks

    lds temp, PINL
    andi temp, ROWMASK              ; masking the higher bits (which will be set to output hence garbage)
    cpi temp, 0xF                   ; Check if any of the rows is low (0xF = 0000 1111)
    breq nextCol                    ; all rows are high

    set_reg keyPress, 0xFF

    rcall start_to_select           ; if any button is pressed, change (if applicable) startScreen to selectScreen

    ldi rmask, INITROWMASK          ;Initialize for row check
    clr row

rowLoop:
    cpi row, 4                      ; goes to the end of the rows
    breq nextCol                    ; the row scan is over
    mov temp1, temp                 ; copying input from pins into temp1
    and temp1, rmask                ; to only check a certain row  (if output is 00 then the Z flag is set)
    breq convert                    ; if temp1 is zero (checks zero flag) then jump to convert
    inc row
    lsl rmask                       ; to unmask the next row
    jmp rowLoop

nextCol:
    lsl cmask                       ; to unmask the next col
    inc col                         
    jmp colloop                     ; in no button pressed jump back to start

convert:   
    cpi col, 3              
    breq letters                    ; if one of the letters have been pressed
    cpi row, 3
    brne isNumber                   ; row != 3 & col != 3, then its a number
    cpi col, 0
    breq admin                      ; row == 3 & col == 0, then the * has been pressed

    clr asterixPressed
    cpi col, 1                  
    breq zero                       ; row == 3 & col == 1, then the 0 has been pressed
    cpi col, 2                  
    breq exit                       ; row == 3 & col == 2, then the # has been pressed

    isNumber:                       ; else we convert the binary to an ASCII value
    mov temp, row
    lsl temp                        ; multiply by 2
    add temp, row                   ; multiply 3
    add temp, col
    subi temp, -1                   ; temp now contains the actual number
    rcall debounce_sleep 
    mov keyID, temp

    rcall updateAdminItem           ; if in Admin mode, change the current item thats selecte

    rjmp endKeypad
    

zero:                               ; a zero has been pressed
    ldi temp1, zeroButton
    mov keyID, temp1
    rjmp endKeypad

exit:                               ; "#" pressed 
    clr keyPress
    rcall debounce_sleep            ; debounce the button
    rcall checkCoins                ; if in coin screen, then abort back to select or start returning coins
    rcall exitAdmin                 ; if in admin mode, then return to select screen
    rjmp endKeypad

letters:
    cpi row, 0                      ; if its an A
    breq aButton
    cpi row, 1                      ; if its a B
    breq bButton
    cpi row, 2                      ; if its a C
    breq cButton
    cpi row, 3                      ; if its a D
    breq dButton
    rjmp endKeypad
    
aButton:
    ldi temp1, aKey
    mov keyID, temp1
    rcall adminIncCost              ; invoke update in Admin mode (if applicable)
    rjmp endKeypad

bButton:
    ldi temp1, bKey
    mov keyID, temp1
    rcall adminDecCost              ; invoke update in Admin mode (if applicable)
    rjmp endKeypad

cButton:
    ldi temp1, cKey
    mov keyID, temp1
    rcall resetNumItems             ; invoke update in Admin mode (if applicable)
    rjmp endKeypad

dButton: 
    ldi temp1, dKey
    mov keyID, temp1
    rjmp endKeypad

admin:
    ldi temp, inAdmin
    cp currFlag, temp
    breq asterixDone                ; ignore any further input from '*' (which will be noise) in Admin mode

    clr r1
    cp asterixPressed, r1           ; if button wasn't pushed before
    brne alreadyPressed

    clear AsterixCounter            ; start the counter, else it'll keep adding onto counter

    alreadyPressed:
    set_reg asterixPressed, 0xFF    ; set flag to denote "*" pressed


    rcall select_to_admin           ; check whether its time to change screens

    ldi temp, inSelect
    cp oldFlag, temp
    breq asterixDone

    rcall debounce_sleep            ; debounce the button everywhere except in select screen 

    asterixDone:
    clr keyPress
    rjmp endKeypad


debounce_sleep:                     ; function to debounce for 250ms
    push temp1
    ldi temp1, 50               
    startDebounce:
    rcall sleep_5ms
    dec temp1
    cpi temp1, 1
    brge startDebounce
    pop temp1
    ret


endKeypad:                          ; has to return from keypad loop to appropriate function
    ldi temp, inCoin                
    cp currFlag, temp               ; if we were setting up the coin coun
    brne coinCountCheck

    pop temp
    pop temp1
    out SREG, temp1
    pop temp1

    rjmp main

    coinCountCheck:
    ldi temp, ADCCoin               ; if system was counting coins entered (reading ADC etc)
    cp currFlag, temp
    brne toMain
    rcall debounce_sleep

    pop temp
    pop temp1
    out SREG, temp1
    pop temp1

    rjmp coinCount

    toMain:
    pop temp
    pop temp1
    out SREG, temp1
    pop temp1

    rjmp main                       ; otherwise go back to main as normal

