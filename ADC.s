#include <xc.inc>

global  ADC_Setup, ADC_Read
    
psect	adc_code, class=CODE
    
    
ADC_Setup:
    
	bsf	TRISA, PORTA_RA3_POSN, A  ; pin RA3==AN3 input
	movlb	0x0F
	bsf	ANSEL3	    ; set AN3 to analog
	movlb	0x00
	movlw   0x0D	    ; select AN3 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	
	return

end
