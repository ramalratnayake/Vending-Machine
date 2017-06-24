/*
===================================================================
COMP2121                                                        
Project - Vending Machine
LCD


Collection of funtions and macros that provide LCD functionality
===================================================================
*/

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

lcd_command:
    out PORTF, r16              ; write out a control command to LCD
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    lcd_clr LCD_E
    rcall sleep_1ms
    ret

lcd_data:
    out PORTF, r16              ; write out data to LCD
    lcd_set LCD_RS
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    lcd_clr LCD_E
    rcall sleep_1ms
    lcd_clr LCD_RS
    ret

lcd_wait:
    push r16
    clr r16
    out DDRF, r16               ; set port F as input
    out PORTF, r16
    lcd_set LCD_RW
        
lcd_wait_loop:
    rcall sleep_1ms
    lcd_set LCD_E
    rcall sleep_1ms
    in r16, PINF
    lcd_clr LCD_E
    sbrc r16, 7                 ; check if busy flag has been cleared
    rjmp lcd_wait_loop          ; if its still busy then it waits longer
    lcd_clr LCD_RW
    ser r16
    out DDRF, r16               // Port F to output
    pop r16
    ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4

; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:                      ; function to delay 1ms
    push r24
    push r25
    ldi r25, high(DELAY_1MS)
    ldi r24, low(DELAY_1MS)

delayloop_1ms:
    sbiw r25:r24, 1
    brne delayloop_1ms
    pop r25
    pop r24
    ret

sleep_5ms:                      ; function that delays for 5ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    ret

/*
    Given a binary value in r16, it will convert digit by digit and print
    to LCD
*/
print_digits:
    push temp
    in temp, SREG
    push temp
    push temp1
    push r16
    clr temp1

    hundreds:                   ; counts the number of hundreds
    ldi temp, 100              
    cpi  r16, 100
    brlo hundred_print
    sub  r16, temp
    inc temp1
    jmp hundreds

    hundred_print:
    rcall print                 ; prints the hundredth digit

    tens:                       ; likewise for tens and ones....
    ldi temp, 10
    cpi  r16, 10
    brlo tens_print
    sub  r16, temp
    inc temp1
    jmp tens

    tens_print:
    rcall print

    ones:
    ldi temp, 1
    cp  r16, temp
    brlo ones_print
    sub  r16, temp
    inc temp1
    jmp ones

    ones_print:
    rcall print

    pop r16
    pop temp1
    pop temp
    out SREG, temp
    pop temp
    ret

print:
    do_lcd_data temp1          ;prints number in temp1
    clr temp1
    ret