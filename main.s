#include <xc.inc>

extrn LCD_Setup, LCD_Write_Message, LCD_Write_Hex, LCD_decimalpoint, LCD_units	 ; external LCD subroutines
extrn ADC_Setup, ADC_Read	     ;external ADC subroutines
extrn Hex_Dec_Setup, Conversion	     ;external Hex to Dec subroutines
extrn PWM_Setup, PWM_Start	     ;external PWM subroutines
extrn UART_Setup, UART_Transmit_Message, UART_Write_Hex, UART_Transmit_Byte, UART_decimalpoint, UART_Space  ;external UART subroutines

psect udata_acs         ; reserve data space in access ram
counter:        ds 1    ; reserve one byte for a counter variable
delay_count:    ds 1    ; reserve one byte for counter in the delay routine
delay_second:   ds 1    ; reserve one byte for a second delay
delay_third:    ds 1    ; reserve one byte for a third delay
  
psect udata_bank4       ; reserve data anywhere in RAM (here at 0x400)
myArray:     ds 0x80    ; reserve 128 bytes for message data
psect	data
	
		;******** myTable, data in programme memory *******
	
myTable:
    db	    'T', 'e', 'm', 'p', '='
    myTable_1	EQU 6
    align	2
    
psect code, abs
rst: org 0x0
    goto setup

                ; ******* Programme FLASH read Setup Code ***********************
setup:
    bcf     CFGS	    ; point to Flash program memory 
    bsf     EEPGD           ; access Flash program memory
    call    LCD_Setup       ; setup UART
    call    ADC_Setup       ; setup ADC
    call    Hex_Dec_Setup   ; setup Hex to Decimal converter
    call    PWM_Setup	    ; setup PWM
    call    UART_Setup	    ; setup UART
    goto    Start
   
    
Start:
    lfsr    0, myArray		    ;Displaying 'Temp =' on LCD
    movlw   low highword(myTable)   ;move low byte into WREG
    movwf   TBLPTRU, A
    movlw   high(myTable)
    movwf   TBLPTRH, A
    movlw   low(myTable)
    movwf   TBLPTRL, A
    movlw   5
    movwf   counter, A
   
loop:
    tblrd*+			    ;loop to increment through letters in myTable and display on LCD
    movff   TABLAT, POSTINC0
    decfsz  counter, A
    bra	    loop
    
    movlw   myTable_1-1
    lfsr    2, myArray
    call    LCD_Write_Message
    goto    measure_loop
    
                ; ******* Main programme ****************************************
		
measure_loop:			;displaying temp value on LCD: 'Temp=XX.XXC'
  	
    call    ADC_Read		;obtain new temp value in hex
    call    Conversion		;convert hex to decimal
    
    
    movf    ADRESH, W, A	;move high two bytes decimal value into ADRESH
    call    LCD_Write_Hex	;display first two bytes of temp on LCD
    call    LCD_decimalpoint	;display decimal point
    movf    ADRESL, W, A	;move low two bytes decimal value into ADRESL
    call    LCD_Write_Hex	;display second two bytes of temp on LCD
    call    LCD_units		;display C on LCD
    movf    ADRESH, W, A	;move high two bytes decimal value into ADRESH
    call    UART_Write_Hex	;display first two bytes of temp on LCD
    call    UART_decimalpoint	;display decimal point
    movf    ADRESL, W, A	;move low two bytes decimal value into ADRESL
    call    UART_Write_Hex	;display second two bytes of temp on LCD
    call    PWM_Start		;set PWM duty cycle
   
    movlw   0x0A		;set new line in UART
    call    UART_Transmit_Byte

    call    delay_1		;delay to limit LCD refresh rate
    
    call    LCD_Setup		;Reset LCD
    goto    Start
    goto    measure_loop 
    
    ; a delay subroutine if you need one, times around loop in delay_count
delay:
    decfsz  delay_count, A ; decrement until zero
    bra     delay
    return

                 ;******* Triple Nested Delay Loop to Display Temp on LCD approximately every half second *******
delay_1:   
    movlw   0x1F
    movwf   delay_second, A

delay_loop:
    movf    delay_second, W, A
    decfsz  WREG, F, A
    goto    save_filereg
    return

save_filereg:
    movwf   delay_second, A
    goto    delay_2

delay_2:
    movlw   0xFF
    movwf   delay_third, A

delay_loop2:
    movf    delay_third, W, A
    decfsz  WREG, F, A
    goto    save_filereg_2
    goto    delay_loop

save_filereg_2:
    movwf   delay_third, A
    goto    delay_3

delay_3:
    movlw   0xFF

delay_loop3:
    decfsz  WREG, F, A
    goto    $-1
    goto    delay_loop2
  
    end     rst
