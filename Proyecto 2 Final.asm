;*******************************************************************************
; Universidad del Valle de Guatemala
; Microcontroladores 
; Seccion 20
; Max de León Robles - 13012
; Ricardo Franco Rivera - 13261
; Programa: Proyecto 2
; Código utilizado para control de un brazo mecánico que posee 3 GDL, se controla
; mediante potenciometros (ADC) que luego generara PWM's para controlar los
; servomotores y mediante comunicación serial se controlará el brazo con una 
; interfaz gráfica realizada en Processing. 
;*******************************************************************************
	list      p=16F887            ; list directive to define processor
	#include <p16F887.inc>        ; processor specific variable definitions
; Configuración del PIC
	__CONFIG    _CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _HS_OSC
	__CONFIG    _CONFIG2, _WRT_OFF & _BOR21V
; DEFINICION DE VARIABLES
	UDATA
W_TEMP res 1			; variable used for context saving
STATUS_TEMP res 1		; variable used for context saving
PCLATH_TEMP res 1		; variable used for context saving
CONT res 1
 
valorPWM11 res 1
address1 res 1
address2 res 1
 
valorADC1 res 1
valorADC2 res 1

lectura res 1 
resultado res 1
dividendo res 1
tiempo res 1
tiempo1 res 1
tiempo2 res 1
tiempo3 res 1
BanderasBotones res 1
BanderasComunicacion res 1
Banderas res 1
; 0 = Bandera para conversión ADC
; 1 = Bandera para tiempo de espera para la LCD (5 mS)
; 2 = Bandera utilizada para luego de terminar de escribir en memoria EEPROM
; Bloque de variables creadas para el control de la LCD
CONT1 res 1
CONT2 res 1
rpta  res 1
VAL res 1
val1 res 1
valor res 1
unidad res 1
#DEFINE RS PORTB, 4
#DEFINE EN PORTB, 5
#DEFINE LCD_D7 PORTB, 3 
#DEFINE LCD_D6 PORTB, 2
#DEFINE LCD_D5 PORTB, 1
#DEFINE LCD_D4 PORTB, 0
;*******************************************************************************
; Macros creadas para llevar el control del programa
SAVE_DATA MACRO valorPWM, address
    BANKSEL EECON1
    BTFSC EECON1, WR
    GOTO $-1
    BANKSEL address
    MOVF address, W
    BANKSEL EEADR
    MOVWF EEADR
    
    BANKSEL valorPWM
    MOVF valorPWM, W
    BANKSEL EEDAT
    MOVWF EEDAT
    BANKSEL EECON1
    BCF EECON1, EEPGD
    BSF EECON1, WREN
    BCF INTCON, GIE
    
    MOVLW H'55'
    MOVWF EECON2
    MOVLW H'AA'
    MOVWF EECON2
    BSF EECON1, WR
   
    BSF INTCON, GIE
    BCF EECON1, WREN
    BANKSEL PIE2
    BCF PIE2, EEIF
    
    BCF STATUS, RP1
    BCF STATUS, RP0
ENDM
;*******************************************************************************
; Macro para leer la memoria EEPROM y almacenar el valor en el W register
;*******************************************************************************    
GET_DATA MACRO address
    MOVF address, W		; Cargo la dirección a leer en la memoria 
    BANKSEL EEADR		
    MOVWF EEADR
    
    BANKSEL EECON1		
    BCF EECON1, EEPGD		; Habilito opción de escritura de la memoria
    BSF EECON1, RD		; EEPROM y el puntero de la DATA memory
    BANKSEL EEDAT
    MOVF EEDAT, W		; Almaceno el valor en el registro W
    BCF STATUS, RP1
ENDM
;*******************************************************************************
ORG 0x0000
    NOP
    GOTO inicializacion 
;*******************************************************************************
ORG 0x0004
    PUSH:
	MOVWF W_TEMP
	SWAPF STATUS, W
	MOVWF STATUS_TEMP
	MOVF PCLATH, w
	MOVWF PCLATH_TEMP
;*******************************************************************************    
    ISR:
	BTFSC PIR1, ADIF			; Interrupción por ADC
	GOTO intADC
	BTFSC INTCON, T0IF			; Interrupción por timer0
	GOTO intTIMER
	BTFSC PIR1,RCIF				; Interrupción por comunicación
	GOTO intComunicacion
	GOTO POP
	
	intADC:
	BSF Banderas, 0		; Levanto bandera de ADC y deshabilito interrupción
	BCF PIR1, ADIF
	GOTO POP
	
	intTIMER:
	BCF INTCON, T0IF		; Regreso a cero la bandera
	MOVLW .225			; Se inicializa el prescaler 225
	MOVWF TMR0
	BTFSC BanderasBotones,5
	BCF PORTA,5
	
	DECFSZ tiempo, 1
	GOTO POP
	MOVLW .2
	MOVWF tiempo
	BTFSS BanderasBotones,5
	GOTO p
	BSF PORTA,5
	GOTO p1
	p:
	BCF PORTA,5
	p1:
	DECFSZ tiempo2, 1
	GOTO POP
	MOVLW .2
	MOVWF tiempo2
	BTFSS BanderasBotones,5
	BSF PORTA,5
	BSF Banderas, 1
	DECFSZ tiempo3, 1
	GOTO POP
	MOVLW .2
	MOVWF tiempo3
	
	DECFSZ tiempo1, 1
	GOTO POP
	MOVLW .50
	MOVWF tiempo1
	BSF BanderasBotones, 6		;presionado por 1 segundo
	GOTO POP
	
	intComunicacion:
	MOVF RCREG,W
	MOVWF lectura
	BSF PORTD,3
	   
	MOVLW .0	    ;si envio un 0 
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c1
	BSF PORTE,0
	BSF BanderasComunicacion,0;muestro el dato almacenado en boton 1
	GOTO POP
	c1:
	MOVLW .1    ;si envio un 1 
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c2
	BSF BanderasComunicacion,1;muestro el dato almacenado en boton 2
	GOTO POP
	c2:
	MOVLW .2	;si envio 2
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c3
	BSF BanderasComunicacion,2;muestro el dato almacenado en boton 3
	GOTO POP
	c3:
	MOVLW .3	;si envio 3
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c4
	BSF PORTE,2
	BSF BanderasComunicacion,3;muestro el dato almacenado en boton 4
	GOTO POP
	c4:
	MOVLW .4	;si envio 4
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c5
	BSF PORTE,1
	BSF BanderasComunicacion,4;muestro el dato almacenado en boton 5, abre o cierra la garra
	GOTO POP
	c5:
	MOVLW .5	;si envio 5
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c9
	BSF BanderasComunicacion,5;muestro el dato almacenado en boton 6, habilita/deshabilita ADC
	BSF PORTD,4
	GOTO POP
	c9:
	MOVLW .9	;si envio 9
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c10
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP
	c10:
	MOVLW .10	;si envio 10
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c19
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c19:
	MOVLW .19	;si envio 19
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c20
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP
	c20:
	MOVLW .20	;si envio 20
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c29
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c29:
	MOVLW .29	;si envio 29
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c30
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c30:
	MOVLW .30	;si envio 30
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c39
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c39:
	MOVLW .39	;si envio 39
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c40
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c40:
	MOVLW .40	;si envio 40
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c49
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c49:
	MOVLW .49	;si envio 49
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c50
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c50:
	MOVLW .50	;si envio 50
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c59
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c59:
	MOVLW .59	;si envio 59
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c60
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c60:
	MOVLW .60	;si envio 60
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c69
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c69:
	MOVLW .69	;si envio 69
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c70
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c70:
	MOVLW .70	;si envio 70
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c79
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c79:
	MOVLW .79	;si envio 79
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c80
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c80:
	MOVLW .80	;si envio 80
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c89
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c89:
	MOVLW .89	;si envio 89
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c90
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c90:
	MOVLW .90	;si envio 90
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c99
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
	c99:
	MOVLW .99	;si envio 99
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO c100
	BANKSEL CCPR2L
	MOVF lectura,W
	MOVWF CCPR2L
	GOTO POP

	c100:
	MOVLW .100	;si envio 100
	SUBWF lectura,W
	BTFSS STATUS,Z
	GOTO POP
	BANKSEL CCPR1L
	MOVF lectura,W
	MOVWF CCPR1L
	GOTO POP
; ******************************************************************************
    POP:
	SWAPF STATUS_TEMP, W
	MOVWF STATUS
	SWAPF W_TEMP, F
	SWAPF W_TEMP, W
    RETFIE
;*******************************************************************************
; Configuración e inicialización de herramientas a utilizar
;*******************************************************************************
inicializacion
    BANKSEL OSCCON
    BSF OSCCON, IRCF2
    BCF OSCCON, IRCF1
    BSF OSCCON, IRCF0
    
    BCF OSCCON, OSTS
    BSF OSCCON, HTS
    BSF OSCCON, SCS			; SISTEMA VA A CORRER CON EL RELOJ INTERNO
    
    BANKSEL TRISA
    CLRF TRISA
    CLRF TRISB
    CLRF TRISC
    CLRF TRISD
    CLRF TRISE
 ;Habilito interrupciones
    BSF INTCON, PEIE			; Interrupciones perifericas
    BSF INTCON, GIE			; Interrupciones globales
    BSF INTCON, T0IE			; Interrupciones TMR0
    ;BSF INTCON, RBIE			; Interrupciones Botones 
    BANKSEL PIE1
    BSF PIE1, ADIE			; Interrupciones del ADC
    BSF INTCON,RCIE			; Interrupciones de botones
; Se activan los puertos que se usaran como analógicos y los demás como digitales
    BANKSEL ANSEL
    CLRF ANSEL
    BSF ANSEL, 0
    BSF ANSEL, 1
    CLRF ANSELH
    
    BANKSEL TRISA
    BSF TRISA, 0			; Puerto RA0 como entrada
    BSF TRISA, 1			; Puerto RA1 como entrada
    BSF TRISA, 3			; Puerto RA3 como entradaBotonesPosicion4
    BSF TRISA, 4			; Puerto RA4 como entradaBotones garra
    BSF TRISC, 0			; habilita y desabilita el adc
    BSF TRISC, 3			; Puerto RC3 como entradaBotones Posicion1
    BSF TRISC, 4			; Puerto RC4 como entradaBotonesPosicion2
    BSF TRISC, 5			; Puerto RC5 como entradaBotonesPosicion3
    BSF TRISC, 6			; comunicacion
    BSF TRISC, 7			; comunicacion
; Inicializacion del temporizador
    BANKSEL OPTION_REG
    BCF OPTION_REG, T0CS	; Lo coloco como temporizador
    BCF OPTION_REG, PSA		; Asigno Prescaler al Timer0
    BSF OPTION_REG, PS2		; Seleccion Prescaler 1:256 PS2:PS0 111
    BCF OPTION_REG, PS1
    BCF OPTION_REG, PS0
    
    CALL INITADC
    CALL INITPWM
    CALL INITSERIAL
    CALL INITLCD
    
    BANKSEL ADIF
    BCF PIR1, ADIF
    
    BANKSEL PIE1
    BSF PIE1,RCIE
    
    BANKSEL PORTB
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD
    CLRF PORTE
;*******************************************************************************
; Inicialización de variables a utilizar
;*******************************************************************************
main
    MOVLW .0
    MOVWF valor
    MOVLW .0
    MOVWF address1
    MOVLW .0
    MOVWF address2
    MOVLW .0
    MOVWF CONT1
    MOVLW .0
    MOVWF CONT2
    MOVLW .0
    MOVWF VAL
    MOVLW .0
    MOVWF val1
    MOVLW .0
    MOVWF unidad
    
    MOVLW .0
    MOVWF valorPWM11
    
    MOVLW .0
    MOVWF valorADC1
    MOVLW .0
    MOVWF valorADC2
    
    MOVLW .0
    MOVWF rpta
    MOVLW .0
    MOVWF resultado
    MOVLW .0
    MOVWF dividendo
    MOVLW .255
    MOVWF CONT
    MOVLW .2
    MOVWF tiempo
    MOVLW .3
    MOVWF tiempo2
    MOVLW .2
    MOVWF tiempo3
    MOVLW .225			; Se inicializa el prescaler con el valor de 225
    MOVWF TMR0
    MOVLW .0			; Se inicializa bandera para los botones
    MOVWF BanderasBotones
    MOVLW .0			; Se inicializa bandera para los botones
    MOVWF BanderasComunicacion
    MOVLW .50
    MOVWF tiempo1		;hacer 1 segundo
    BSF BanderasBotones,0
    BSF BanderasBotones,7
    BSF PORTD,0			;indicar adc encendido
    BSF Banderas,3
    BSF Banderas,4
    BCF Banderas,5
    BCF Banderas,6
    CALL DISPLAY_LCD1
;*******************************************************************************
; Loop principal del programa 
;*******************************************************************************
loop
    BTFSS BanderasBotones,0
    GOTO loop1
    BANKSEL ADCON0
; Selección del canal ADC AN0 que se encuentra en RA0
    BCF ADCON0, CHS3
    BCF ADCON0, CHS2
    BCF ADCON0, CHS1
    BCF ADCON0, CHS0
; Se activa la conversión ADC
    CALL DELAY
    CALL DELAY
    BANKSEL ADCON0
    BSF ADCON0, GO
    BTFSS Banderas, 0		; Reviso si se completo la conversión ADC
    GOTO $-1
    BANKSEL ADRESH
    MOVF ADRESH, W		; Obtengo el valor convertido (ADC)
    CALL DIVISION
    MOVWF valorADC1
    MOVF valorADC1,W
    MOVWF CCPR1L
    BCF Banderas, 0
; Selección del canal ADC AN0 que se encuentra en RA1
    BCF ADCON0, CHS3
    BCF ADCON0, CHS2
    BCF ADCON0, CHS1
    BSF ADCON0, CHS0		; SELECCIÓN CANAL AN1
; Se activa la conversión ADC
    CALL DELAY
    CALL DELAY
    BANKSEL ADCON0 
    BSF ADCON0, GO
    BTFSS Banderas, 0		; Reviso si se completo la conversión ADC
    GOTO $-1
    BANKSEL ADRESH
    MOVF ADRESH, W		; Obtengo el valor convertido (ADC)
    CALL DIVISION
    MOVWF valorADC2
    MOVF valorADC2,W
    MOVWF CCPR2L
    BCF Banderas, 0 
; Se desactiva el ADC y no lee los JoyStick solo sirve la GUI y pantala LCD
    loop1:
    BANKSEL PORTA
    CALL Botones
    BTFSS BanderasBotones,0
    CALL DISPLAY_LCD2
GOTO loop
;*******************************************************************************
; Delay para lectura de ADC y cambio de canal de lectura
;*******************************************************************************
DELAY
    DECFSZ CONT, F
    GOTO $ - 1
    MOVLW .255
    MOVWF CONT
RETURN
;*******************************************************************************
; Delay para inicialización y envio de datos de la pantalla LCD
;*******************************************************************************
DELAY_LCD
    MOVWF CONT2		    ; Dependiendo del valor de CONT2 puede variar el DELAY
    inicio1
    MOVLW .50		    ; DELAY principal para 10 uS
    MOVWF CONT1
    DECFSZ CONT1,1
    GOTO $-1
    DECFSZ CONT2,1
    GOTO inicio1
RETURN
;*******************************************************************************
; Rutina para realizar la division
; "Divide 8 bits in W by the constant value 3"
; By: Andy Warren From: http://www.myke.com/basic.htm
;*******************************************************************************
DIVISION
    MOVWF dividendo
    CLRF resultado
    div_loop:
	BCF STATUS, C
	RRF dividendo, F
	MOVF dividendo, W
	BTFSC STATUS, Z
	GOTO div_done
	ADDWF resultado, F
	RRF dividendo, F
	MOVF dividendo, W
	BTFSC STATUS, Z
	GOTO div_done
	SUBWF resultado, F
	GOTO div_loop
    div_done:
	MOVF resultado, W
	ADDWF resultado, F
	MOVF resultado, W
RETURN
;*******************************************************************************
; Rutina para inicialización del puerto Serial
;*******************************************************************************
INITSERIAL
    BANKSEL SPBRGH
    CLRF SPBRGH			; Parte alta del valor a cargar al BAUD en 0
    
    BANKSEL SPBRG 
    MOVLW .12			; Se carga el valor decimal de 12 para la configuración
    MOVWF SPBRG			; deseada del BAUD, 9,600 a 8 MHz
    
    BANKSEL TXSTA		
    BCF TXSTA,BRGH		; Se coloca en 0 la parte alta de la selección de
    
    BANKSEL BAUDCTL		; 16 bits y se coloca para utilizar solo 8 bits
    BCF BAUDCTL,BRG16
    
    BANKSEL TXSTA
    BCF TXSTA,SYNC		; Se coloca como asíncrono 
    
    BANKSEL RCSTA
    BSF RCSTA,SPEN		; Coloco el puerto serial como activado
    BSF RCSTA,CREN		; Se habilita para la recepción de datos
    
    BANKSEL TXSTA
    BSF TXSTA,TXEN		; Habilito la interrupción por comunicación serial
    
    BANKSEL TXREG
    MOVLW B'11111111'
    MOVWF TXREG
RETURN
;*******************************************************************************
; Rutina para inicialización del ADC
;*******************************************************************************
INITADC
    BANKSEL ADCON0
    BCF ADCON0, ADCS1
    BSF ADCON0, ADCS0		; Fosc/8
    
    BCF ADCON0, CHS3
    BCF ADCON0, CHS2
    BCF ADCON0, CHS1
    BCF ADCON0, CHS0		; SELECCIÓN CANAL AN0
    
    BANKSEL ADCON1
    BCF ADCON1, VCFG1		; REFERENCIA VSS
    BCF ADCON1, VCFG0		; REFERENCIA VDD
    
    BCF ADCON1, ADFM		; JUSTIFICACION IZQUIERDA
    
    BANKSEL ADCON0
    BSF ADCON0, ADON		; ENCIENDO EL MÓDULO ADC
RETURN
;*******************************************************************************
; Rutina para inicialización del PWM
;*******************************************************************************
INITPWM
;*******************************************************************************
; Configuración del primer PWM en el PORTC1
;*******************************************************************************
    BANKSEL TRISC
    BSF TRISC, 1		; COLOCO COMO ENTRADA RC1
    BANKSEL PR2
    MOVLW 155
    MOVWF PR2			; CONFIGURE PERIODO DE PWM
    BANKSEL CCP2CON
    BSF CCP2CON, 3
    BSF CCP2CON, 2
    BCF CCP2CON, 1
    BCF CCP2CON, 0		; CONFIGURANDO MÓDULO CCP2 COMO PWM
    
    BCF CCP2CON, 5
    BCF CCP2CON, 4		; BITS MENOS SIGNIFICATIVOS PARA EL CALCULO DEL ANCHO PULSO
    
    BANKSEL CCPR2L
    MOVLW B'00000000'
    MOVWF CCPR2L		; Cargo el valor para que al iniciar sea 0 el ancho
    
    BANKSEL PIR1
    BCF PIR1, TMR2IF
    
    BANKSEL T2CON
    BSF T2CON, 1
    BSF T2CON, 0		; UTILICE PRESCALER DE 16
    BSF T2CON, TMR2ON
    
    BANKSEL PIR1
    BTFSS PIR1, TMR2IF
    GOTO $-1
    BCF PIR1, TMR2IF
    BANKSEL TRISC
    BCF TRISC, 1		; SALIDA RC1
;*******************************************************************************
; Configuración del primer PWM en el PORTC2
;*******************************************************************************
    BANKSEL TRISC
    BSF TRISC, 2		; COLOCO COMO ENTRADA RC2
    BANKSEL PR2
    MOVLW .155
    MOVWF PR2			; CONFIGURE PERIODO DE PWM
    BANKSEL CCP2CON
    BSF CCP1CON, 3
    BSF CCP1CON, 2
    BCF CCP1CON, 1
    BCF CCP1CON, 0		; CONFIGURANDO MÓDULO CCP2 COMO PWM
    
    BCF CCP1CON, 5
    BCF CCP1CON, 4		; BITS MENOS SIGNIFICATIVOS PARA EL CALCULO DEL ANCHO PULSO
    
    BANKSEL CCPR1L
    MOVLW B'00000000'
    MOVWF CCPR2L		; Cargo el valor para que al iniciar sea 0 el ancho
    
    BANKSEL PIR1
    BCF PIR1, TMR2IF
    
    BANKSEL T2CON
    BSF T2CON, 1
    BSF T2CON, 0		; UTILICE PRESCALER DE 16
    BSF T2CON, TMR2ON
    
    BANKSEL PIR1
    BTFSS PIR1, TMR2IF
    GOTO $-1
    BCF PIR1, TMR2IF
    BANKSEL TRISC
    BCF TRISC, 2		; SALIDA RC2
RETURN
;*******************************************************************************
; Subrutina utilizada para el control de los botones y sus acciones
;*******************************************************************************   
Botones
    BTFSC BanderasComunicacion,0
    GOTO b1
    BTFSC BanderasComunicacion,1
    GOTO b2
    BTFSC BanderasComunicacion,2
    GOTO b3
    BTFSC BanderasComunicacion,3
    GOTO b4
    BTFSC BanderasComunicacion,4
    GOTO Posicion5 
    BTFSC BanderasComunicacion,5
    GOTO PausaADC
    
    BTFSC PORTC,3
    GOTO Posicion1
    BTFSC PORTC,4
    GOTO Posicion2
    BTFSC PORTC,5
    GOTO Posicion3
    BTFSC PORTA,3
    GOTO Posicion4
    BTFSC PORTA,4
    GOTO Posicion5
    BTFSC PORTC,0
    GOTO PausaADC
    
    BCF BanderasBotones,6
    BSF BanderasBotones,7	    ; Funciona boton
    BCF BanderasBotones,1
    BCF BanderasBotones,2
    BCF BanderasBotones,3
    BCF BanderasBotones,4
    MOVLW .0
    MOVWF BanderasComunicacion
    
    RETURN
; Almacena la posición #1 en la memoria EEPROM (2 servos y garra)
    Posicion1:
	BTFSS BanderasBotones,1
	GOTO b1
	BTFSS BanderasBotones,6
	RETURN
; Obtengo el valor y dirección para almacenar en EEPROM utilizando MACRO
	B1Graba:
	BANKSEL address1
	MOVLW 0x00
	MOVWF address1
	BANKSEL ADRESH
	MOVF valorADC1,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1,1
	MOVF valorADC2,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1,1
	BTFSC BanderasBotones, 5
	GOTO uno1
	GOTO cero1
	uno1:
	MOVLW .1
	MOVWF valorPWM11
	GOTO save1
	cero1:
	MOVLW .0
	MOVWF valorPWM11
	GOTO save1
	save1:
	SAVE_DATA valorPWM11, address1
	BSF PORTD,6
	RETURN
; Obtengo el valor de la memoria EEPROM a partir de la dirección deseada
	b1:
	MOVLW 0x00
	MOVWF address2
	BANKSEL ADRESH
	GET_DATA address2
	MOVWF CCPR1L
	INCF address2,1
	GET_DATA address2
	MOVWF CCPR2L
	INCF address2,1
	GET_DATA address2
	MOVWF rpta
	BTFSC rpta,0
	GOTO uno11
	GOTO cero11
	uno11:
	BSF BanderasBotones, 5
	GOTO get1
	cero11
	BCF BanderasBotones, 5
	GOTO get1
	get1:
	BSF PORTD,1
	BSF BanderasBotones,1
	BCF BanderasBotones,2
	BCF BanderasBotones,3
	BCF BanderasBotones,4
	BSF BanderasBotones,7	    ;funciona boton
	MOVLW .0
	MOVWF BanderasComunicacion
	RETURN
; Almacena la posición #2 en la memoria EEPROM (2 servos y garra)
    Posicion2:
	BTFSS BanderasBotones,2
	GOTO b2
	BTFSS BanderasBotones,6
	RETURN
; Obtengo el valor y dirección para almacenar en EEPROM utilizando MACRO
	B2Graba:
	BANKSEL address1
	MOVLW 0x10
	MOVWF address1
	BANKSEL ADRESH
	MOVF valorADC1,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1,1
	MOVF valorADC2,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1,1
	BTFSS BanderasBotones, 5
	GOTO uno2
	GOTO cero2
	uno2:
	MOVLW .1
	MOVWF valorPWM11
	GOTO save2
	cero2:
	MOVLW .0
	MOVWF valorPWM11
	GOTO save2
	save2:
	SAVE_DATA valorPWM11, address1
	BSF PORTD,6
	RETURN
; Obtengo el valor de la memoria EEPROM a partir de la dirección deseada
	b2:
	MOVLW 0x10
	MOVWF address2
	BANKSEL ADRESH
	GET_DATA address2
	MOVWF CCPR1L
	INCF address2,1
	GET_DATA address2
	MOVWF CCPR2L
	INCF address2,1
	GET_DATA address2
	MOVWF rpta
	BTFSC rpta,0
	GOTO uno12
	GOTO cero12
	uno12:
	BSF BanderasBotones, 5
	GOTO get2
	cero12
	BCF BanderasBotones, 5
	GOTO get2
	get2:
	BSF PORTD,2
	BSF BanderasBotones,2
	BCF BanderasBotones,1
	BCF BanderasBotones,3
	BCF BanderasBotones,4
	BSF BanderasBotones,7	    ;funciona boton
	MOVLW .0
	MOVWF BanderasComunicacion
	RETURN
; Almacena la posición #3 en la memoria EEPROM (2 servos y garra)
    Posicion3:
	BTFSS BanderasBotones,3
	GOTO b3
	BTFSS BanderasBotones,6
	RETURN
; Obtengo el valor y dirección para almacenar en EEPROM utilizando MACRO
	B3Graba:
	MOVLW 0x20
	MOVWF address1	
	BANKSEL ADRESH
	MOVF valorADC1,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1, 1
	MOVF valorADC2,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1, 1
	BTFSS BanderasBotones, 5
	GOTO uno3
	GOTO cero3
	uno3:
	MOVLW .1
	MOVWF valorPWM11
	GOTO save3
	cero3:
	MOVLW .0
	MOVWF valorPWM11
	GOTO save3
	save3:
	SAVE_DATA valorPWM11, address1
	BSF PORTD,6
	RETURN
; Obtengo el valor de la memoria EEPROM a partir de la dirección deseada
	b3:
	MOVLW 0x20
	MOVWF address2
	BANKSEL ADRESH
	GET_DATA address2
	MOVWF CCPR1L
	INCF address2, 1
	GET_DATA address2
	MOVWF CCPR2L
	INCF address2, 1
	GET_DATA address2
	MOVWF rpta
	BTFSC rpta,0
	GOTO uno13
	GOTO cero13
	uno13:
	BSF BanderasBotones, 5
	GOTO get3
	cero13
	BCF BanderasBotones, 5
	GOTO get3
	get3:
	BSF PORTD,3
	BSF BanderasBotones,3
	BCF BanderasBotones,1
	BCF BanderasBotones,2
	BCF BanderasBotones,4
	BSF BanderasBotones,7	    ;funciona boton
	MOVLW .0
	MOVWF BanderasComunicacion
	RETURN
; Almacena la posición #4 en la memoria EEPROM (2 servos y garra)
    Posicion4:
	BTFSS BanderasBotones,4
	GOTO b4
	BTFSS BanderasBotones,6
	RETURN
; Obtengo el valor y dirección para almacenar en EEPROM utilizando MACRO
	B4Graba:
	MOVLW 0x30
	MOVWF address1
	BANKSEL ADRESH
	MOVF valorADC1,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1, 1
	MOVF valorADC2,W
	MOVWF valorPWM11
	SAVE_DATA valorPWM11, address1
	INCF address1, 1
	BTFSS BanderasBotones, 5
	GOTO uno4
	GOTO cero4
	uno4:
	MOVLW .1
	MOVWF valorPWM11
	GOTO save4
	cero4:
	MOVLW .0
	MOVWF valorPWM11
	GOTO save4
	save4:
	SAVE_DATA valorPWM11, address1
	BSF PORTD,6
	RETURN
; Obtengo el valor de la memoria EEPROM a partir de la dirección deseada
	b4:
	MOVLW 0x30
	MOVWF address2
	BANKSEL ADRESH
	GET_DATA address2
	MOVWF CCPR1L
	INCF address2, 1
	GET_DATA address2
	MOVWF CCPR2L
	INCF address2, 1
	GET_DATA address2
	MOVWF rpta
	BTFSC rpta,0
	GOTO uno14
	GOTO cero14
	uno14:
	BSF BanderasBotones, 5
	GOTO get4
	cero14
	BCF BanderasBotones, 5
	GOTO get4
	get4:
	BSF PORTD,4
	BSF BanderasBotones,4
	BCF BanderasBotones,1
	BCF BanderasBotones,3
	BCF BanderasBotones,2
	BSF BanderasBotones,7	    ;funciona boton
	MOVLW .0
	MOVWF BanderasComunicacion
	RETURN

    Posicion5:
	MOVLW .0
	MOVWF BanderasComunicacion
	BTFSS BanderasBotones,7		    ; Funciona boton
	RETURN
	BSF PORTD,5
	BTFSS BanderasBotones,5
	GOTO Cerrar
	GOTO Abrir
	RETURN
; Al presionar el botón se abre o cierra la garra del brazo mecánico
	Cerrar:
	BCF PORTD,7
	BCF BanderasBotones,7		    ; No funciona boton hasta que tenga 1
	BSF BanderasBotones,5
	BCF BanderasBotones,1
	BCF BanderasBotones,2
	BCF BanderasBotones,3
	BCF BanderasBotones,4
	RETURN
	Abrir:
	BSF PORTD,7
	BCF BanderasBotones,7	    
	BCF BanderasBotones,5
	BCF BanderasBotones,1
	BCF BanderasBotones,2
	BCF BanderasBotones,3
	BCF BanderasBotones,4
	RETURN
; Al presionar el botón desactiva el ADC para utilizar las posiciones en EEPROM
    PausaADC:
	MOVLW .0
	MOVWF BanderasComunicacion
	BTFSS BanderasBotones,7	    ;funciona boton
	RETURN
	BCF BanderasBotones,7
	BTFSC BanderasBotones,0
	GOTO Apaga
	GOTO Encender
	RETURN
	Apaga:
	BCF PORTD,0
	BCF BanderasBotones,0
	RETURN
	Encender:
	BSF PORTD,0
	BSF BanderasBotones,0
RETURN
;*******************************************************************************
; Rutina para inicialización de la pantalla LCD
;*******************************************************************************
INITLCD
    BANKSEL INTCON
    BCF INTCON, GIE
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .100
    CALL DELAY_LCD
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BSF LCD_D5
    BSF LCD_D4
    CALL SWITCH
    
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BSF LCD_D5
    BSF LCD_D4
    CALL SWITCH
    
    MOVLW .10
    CALL DELAY_LCD
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BSF LCD_D5
    BSF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BSF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BSF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BSF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BSF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BSF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BSF LCD_D6
    BSF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF EN
    BCF RS
    BSF LCD_D7
    BSF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    BSF RS
    BANKSEL INTCON
    BSF INTCON, GIE
RETURN
;*******************************************************************************
; Rutina para activar el envio o carga de datos a la LCD
;*******************************************************************************
SWITCH
    BSF EN
    NOP
    NOP
    NOP
    BCF EN
    MOVLW .200
    CALL DELAY_LCD
    MOVLW .200
    CALL DELAY_LCD
RETURN
;*******************************************************************************
; Rutina para dividir la parte alta y baja para enviar a la LCD
;*******************************************************************************
DISPLAY
    MOVWF VAL
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    BTFSC VAL,7
    BSF LCD_D7
    BTFSC VAL,6
    BSF LCD_D6
    BTFSC VAL,5
    BSF LCD_D5
    BTFSC VAL,4
    BSF LCD_D4
    CALL SWITCH
    
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    BTFSC VAL,3
    BSF LCD_D7
    BTFSC VAL,2
    BSF LCD_D6
    BTFSC VAL,1
    BSF LCD_D5
    BTFSC VAL,0
    BSF LCD_D4
    CALL SWITCH
RETURN
;*******************************************************************************
; Rutina para desplegar la información que se desea en la primera línea
;*******************************************************************************
DISPLAY_LCD1
; Linea 1 del displey 2X16
    BCF RS
    BSF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    BSF RS
; Empieza a desplegar los mensajes
    MOVLW "S"
    CALL DISPLAY
    MOVLW "E"
    CALL DISPLAY
    MOVLW "R"
    CALL DISPLAY
    MOVLW "V"
    CALL DISPLAY
    MOVLW "O"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    MOVLW "1"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    
    MOVLW "S"
    CALL DISPLAY
    MOVLW "E"
    CALL DISPLAY
    MOVLW "R"
    CALL DISPLAY
    MOVLW "V"
    CALL DISPLAY
    MOVLW "O"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    MOVLW "2"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
RETURN
;*******************************************************************************
; Rutina para desplegar la información que se desea en la segunda línea
;*******************************************************************************
DISPLAY_LCD2
; Linea 2 del displey 2X16
    BCF RS
    BSF LCD_D7
    BSF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    
    BCF RS
    BCF LCD_D7
    BCF LCD_D6
    BCF LCD_D5
    BCF LCD_D4
    CALL SWITCH
    BSF RS
    MOVLW " "
    CALL DISPLAY
    MOVLW "*"
    CALL DISPLAY
    MOVF CCPR2L,W
    CALL convCentenas
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVF CCPR2L,W
    CALL convDecenas
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVF CCPR2L,W
    CALL convUnidades
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVLW "*"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    
    BSF RS
    MOVLW " "
    CALL DISPLAY
    MOVLW "*"
    CALL DISPLAY
    MOVF CCPR1L,W
    CALL convCentenas
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVF CCPR1L,W
    CALL convDecenas
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVF CCPR1L,W
    CALL convUnidades
    MOVWF val1
    MOVF val1,W
    ADDLW .48
    CALL DISPLAY
    MOVLW "*"
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
    MOVLW " "
    CALL DISPLAY
RETURN
;*******************************************************************************
; Rutina para dividir centenas, decenas y unidades
;*******************************************************************************
convCentenas
	MOVWF valor
	CLRF unidad
    loop11:
	MOVLW .100
	INCF unidad,F
	SUBWF valor,F
	BTFSC STATUS,C
	GOTO loop11
	DECF unidad,W
    RETURN
    convDecenas
	MOVWF valor
	CLRF unidad
    loop22:
	MOVLW .10
	INCF unidad,F
	SUBWF valor,F
	BTFSC STATUS,C
	GOTO loop22
	DECF unidad,W
	GOTO convUnidades
    convUnidades
	MOVWF unidad
	MOVLW .10
    loop33:
	SUBWF unidad,F
	BTFSC STATUS,C
	GOTO loop33
	ADDWF unidad,W
RETURN
END