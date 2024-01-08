# Battery_opto
Assembly code to run a simple battery optimisation system using an LED and a temperature sensor.
The main.s file contains the primary code and calls through all the subroutines in the other files.
ACD.s converts the signal from the temp sensor from analogue to digital.
Hex_Dec.s converts the hexadecimal number to a decimal number.
LCD.s displays this temperature on the LCD.
PWM.s controls the current passing through the LED based on its temperature.
UART.s records the temperature data each time it changes up to 999 values.
