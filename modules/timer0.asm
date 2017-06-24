/*
===================================================================
COMP2121                                                        
Project - Vending Machine
timer0


Interrupt subroutine for the sole timer for the whole system. 
Timing used for:
    - Screen transistions
    - Turning off LEDs
    - Turning off Motor
    - Returning coins
===================================================================
*/

.equ INTS_PER_MS = 8                                    ; time per interrupt = (1/(16E6)) * (2^8 - 1) * 8 <- pre scaler = 127.5 us
                                                        ; number of interrupts per second = (1E-3) / (127.5)E-6 = 7.843 ~ 8

Timer0OVF: ; interrupt subroutine to Timer0
    push temp
    in temp, SREG
    push temp                               ; Prologue starts.
    push temp1
    push YH                                 ; Save all conflict registers in the prologue.
    push YL
    push r24
    push r25
    push r26
    push r27



                    /* Just increases a counter (every ms) when a "*" is pressed */
                    /* ========================================================= */
    clr r1
    cp asterixPressed, r1                           ; poll 'asterix pressed' flag 
    breq noAsterix                                  ; asterix is not currently pressed so dont count

    lds r26, AsterixCounter                         ; else start counting 
    lds r27, AsterixCounter+1
    adiw r27:r26, 1

    sts AsterixCounter, r26
    sts AsterixCounter +1, r27


    noAsterix:

                            /* Enables the ADC Reader every millisecond */ 
                            /* ======================================== */      
    mov temp1, currFlag
    cpi temp1, ADCCoin
    brne skipADC                                    ; dont enable ADC if not in coin screen

    lds r26, ADCCounter
    lds r27, ADCCounter+1
    adiw r27:r26, 1

    cpi r26, low(1*INTS_PER_MS)                     ; 1ms second check
    ldi temp, high(1*INTS_PER_MS) 
    cpc r27, temp
    brne finishADC

    lds temp, ADCSRA
    ori temp, (1 << ADSC)               
    sts ADCSRA, temp                                ; enabling the ADC reader which will interrupt when conversion done
   
    clear ADCCounter                                ; clear counter for next ADC request
    rjmp skipADC

    finishADC:
    sts ADCCounter, r26
    sts ADCCounter +1, r27

    skipADC:

                        /* Times 3 seconds for screen transition and motor off */ 
                        /* =================================================== */

    lds r26, DisplayCounter
    lds r27, DisplayCounter+1
    adiw r27:r26, 1


    cpi r26, low(3000*INTS_PER_MS)                  ; 3 second check
    ldi temp, high(3000*INTS_PER_MS) 
    cpc r27, temp
    brne skipDisplay

    rcall start_to_select                           ; if the start screen needs to be changed
    rcall empty_to_select                           ; if the empty screen needs to be changed
    rcall deliver_to_select                         ; if the deliver screen needs to be changed (and trigger motor off))

    clear DisplayCounter 
    rjmp EndIF

    skipDisplay:

    sts DisplayCounter, r26
    sts DisplayCounter +1, r27

                            /* Times 0.5 seconds to alternate LEDs off and on */ 
                            /* ============================================== */

    lds r26, LEDCounter
    lds r27, LEDCounter+1
    adiw r27:r26, 1
    
    ldi temp, inEmpty                               
    cp currFlag, temp                               ; if currently in Empty screen
    breq turnOff 

    ldi temp, inDeliver
    cp currFlag, temp                               ; else if in deliver screen
    brne skipLED                                    ; if not in any of these then skip all 

    turnOff:                                        ; turn off LEDs at 0.5 seconds
    cpi r26, low(500*INTS_PER_MS) 
    ldi temp, high(500*INTS_PER_MS) 
    cpc r27, temp
    brne turnOn
    
    clr temp                           
    out PORTC, temp                                     
    out PORTE, temp                                 ; write LOW to both LED ports to turn off (which also turns off motor)

    ldi temp, inEmpty                               ; if in empty screen
    cp currFlag, temp                               
    breq turnOn                                     ; check if its 1 second

    ldi temp, turnLEDOff                            ; otherwise in deliver so write individual bits to keep only motor on for longer
    out PORTE, temp

    turnOn:                                         ; to turn on LEDs at 1 second
    cpi r26, low(1000*INTS_PER_MS)                  
    ldi temp, high(1000*INTS_PER_MS) 
    cpc r27, temp
    brne skipLED
    
    ser temp                           
    out PORTC, temp                                 ; write HIGH to LED only port to turn on                        
                                
    
    ldi temp, inDeliver                             ; check if in deliver screen 
    cp currFlag, temp
    breq deliverOn                                  ; we need to turn on the motor as well as the LEDs

    ldi temp, turnLEDOn                             ; else we should only turn on the LEDs and not the motor
    out PORTE, temp
    rjmp finishLED

    deliverOn:
    ldi temp, turnLEDMotOn                          ; write individual bits to turn on motor and LED
    out PORTE, temp

    finishLED:
    clear LEDCounter                                ; clear counter for next check

    rjmp EndIF

    skipLED:

    sts LEDCounter, r26
    sts LEDCounter +1, r27

                            /* Times 0.25 seconds to turn motor on for coin return */ 
                            /* =================================================== */

 lds r26, ReturnCounter
    lds r27, ReturnCounter+1
    adiw r27:r26, 1

    cpi r26, low(250*INTS_PER_MS)                   ; 0.25 second check to turn off motor
    ldi temp, high(250*INTS_PER_MS) 
    cpc r27, temp
    brne skipOff                                    ; not enough time yet

    check_coins_zero                                ; macro that checks whether any coins are still stored in the system
    breq EndIF                                      ; if not, then don't need to do anything here

    clr temp1
    out PORTE, temp1                                ; otherwise, turn motor off
    
    dec coinsToReturn                               ; a coin has been returned so decrement amount in system


skipOff:
    cpi r26, low(500*INTS_PER_MS)                   ; 0.5 second check to turn on motor
    ldi temp, high(500*INTS_PER_MS) 
    cpc r27, temp
    brne skipOn
    
    check_coins_zero                                ; macro that checks whether any coins are still stored in the system
    breq EndIf                                      ; if not, then don't need to do anything here
    
    ldi temp1, turnMotOn 
    out PORTE, temp1                                ; otherwise, turn motor off

    clear ReturnCounter                             ; clear counter for next coin return request
    jmp EndIF

    skipOn:
    sts ReturnCounter, r26
    sts ReturnCounter +1, r27

                                             /* Epilogue */ 
                                             /* ======== */
    EndIF:
    pop r27
    pop r26
    pop r25                                 
    pop r24                                         ; Restore all conflict registers from the stack.
    pop YL
    pop YH
    pop temp1
    pop temp
    out SREG, temp
    pop temp
    reti                                            ; Return from the interrupt.