#include <xc.inc>

global	PWM_Setup, PWM_Start

   
psect   udata_acs
   
max_PWM_dc:	     ds 1	; reserve 1 byte for the maximum PWM duty cycle
half_PWM_dc:	     ds 1	; reserve 1 byte for the reduced PWM duty cycle
upper_lim_temp:	     ds 1	; reserve 1 byte for the upper temp threshold
target_low_temp:     ds 1	; reserve 1 byte for the lower temp threshold
current_temp:	     ds 1	; reserve 1 byte for the current temp value
heating:	     ds 1	; reserve 1 byte for the heating mode value
constant1:	     ds 1	; reserve 1 byte for a constant to check heating mode
    
    
psect pwm_code, class=CODE

PWM_Setup:
   
    movlw   0x02		;set value of 0x02 for constant
    movwf   constant1
    movlw   0x02		;set heating mode on initially (on when value = 0x02)
    movwf   heating	
    movlw   0xFF		;set maximum PWM duty cycle to 0xFF
    movwf   max_PWM_dc
    movlw   0x80		;set reduced PWM duty cycle to 0x80
    movwf   half_PWM_dc
    movlw   0x30		;set upper temp threshold to 30C
    movwf   upper_lim_temp
    movlw   0x24		;set lower temp threshold to 25C
    movwf   target_low_temp
    
   
    movlw   0xFF		;set PWM period to 0xFF
    movwf   PR2
   
    clrf    CCPTMRS1		;use timer2 for ccp4
    movlw   0x3C		;load the 2 LSBs set to pwm mode
    movwf   CCP4CON		;write to CCP4CON<5:4>
 
    bcf    TRISG, 3		;setting pin 3 as output pin (RG3 is output pin for PWM)
    return
    
PWM_Start:
     
    movf    ADRESH, W		;move the temperature value to current_temp
    movwf   current_temp
    
    call    Update_PWM
 
    bsf    T2CON, 2		;turning the timer 2 on - initiates the PWM
    return

Update_PWM:
   
    movf    upper_lim_temp, W	  ;check if the current temp is below the upper temp limit
    subwf   current_temp, W
    btfsc   STATUS, 0		  ;if temp > limit go to PWM_calc to reduce PWM duty cycle
    call    PWM_calc
    movf    upper_lim_temp, W
    subwf   current_temp, W	  ;if temp < limit go to Low_Temp_Check to check the heating mode
    btfsc   STATUS, 0
    return
    call    Low_Temp_Check
    return
   
 PWM_calc:
 
    clrf    heating		   ;set heating mode to off
    movf   half_PWM_dc, W		   ;set PWM duty cycle to reduced value
    ;movlw   0x05  
    ;mulwf   current_temp
   ; movf    PRODL, W
    ;subwf   max_PWM_dc, W
    
    movwf   CCPR4L
    
    return
   
Low_Temp_Check:
   
    movf    current_temp, W	    ;check if temp < lower temp value
    subwf   target_low_temp, W
    btfsc   STATUS, 0		    ;if temp < lower temp value go to PWM_max to set PWM duty cycle to max
    call    PWM_max
    movf    current_temp, W	    
    subwf   target_low_temp, W
    btfsc   STATUS, 0		    ;if temp > lower temp check to see if heating mode is on or off
    return
    call    Check_Mode
    return
    
Check_Mode:
   
    movf    constant1, W	    ;check if heating mode is on or off
    
    subwf   heating, W
    btfsc   STATUS, 0
    call    PWM_max		    ;if heating mode is on then set PWM duty cycle to max
    movf    constant1, W
    subwf   heating, W		    ;if heating mode is off set PWM to reduced duty cycle
    btfsc   STATUS, 0
    return
    call    PWM_calc
    return
    
   
PWM_max:
    
    movlw   0x02		    ;turn heating mode on
    movwf   heating
  
    movf    max_PWM_dc, W	    ;set PWM duty cycle to maximum
    movwf   CCPR4L
   
   
    return
 