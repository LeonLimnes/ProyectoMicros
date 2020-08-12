processor 16f877
include<p16f877.inc>
;PropÃ³sito: sistema para el control de flujo de personas hacia el interior de un
;			 establecimiento en un contexto de pandemia por coronavirus (COVID-19).

CONTADOR  EQU H'20'	
;////////////////////
; CONST RETARDO
;////////////////////		
VALOR1    EQU H'21'
VALOR2    EQU H'22'
VAL 	  EQU H'24'
;////////////////////
; REG FUNCIONES
;////////////////////	
REGA  	  EQU H'23'		;Registro donde se almacena resultado de conversion A/D

				ORG   	0				;
				GOTO  	INICIO		  	;Define vector de Reset
				ORG   	4				;
				GOTO  	INTERRUPCIONES  ;Define vector de Interrupcion
				ORG   	5				;Indica origen para inicio del programa
INICIO:			BSF   	STATUS,5		;Cambio de banco
				BCF   	STATUS,6		;Cambio al banco 1
				CLRF   	ADCON1			;Configura al puerto A como entrada analogica
				CLRF  	TRISB			;Configura al puerto B como salida
				CLRF  	TRISC			;Configura al puerto C como salida
				MOVLW 	H'C0'			;
				MOVWF  	TRISD			;Configura al puerto D[0,1] como entrada
				MOVLW 	B'00000111'	  	;PS2=1,PS1=1,PS=1
				MOVWF 	OPTION_REG	  	;Pre-divisor del TMR0 = 256
				BCF   	STATUS,5		;Cambio al banco 0
	;Configuracion de convertidor A/D
				MOVLW  	B'11000001'		;W = 11000001
		 		MOVWF  	ADCON0			;ADCON0 = 11 (frecuencia del reloj)
		 								;		  000(canal de entrada)
		 								;		  001(Encender el convertidor A/D)
	;Configuracion de interrupciones
				BCF   	INTCON,T0IF	  	;Bandera de desbordamiento. T0IF = 0
				BSF   	INTCON,T0IE	  	;Habilita interrupciÃ³n por desbordamiento del TIMER0
				BSF   	INTCON,GIE	  	;Habilita interrupciones generales
	;Configuracion de PWM
				MOVLW 	D'255'			;W = D'255'
				MOVWF 	PR2				;Periodo de la señal = D'255'
				MOVLW 	B'00001100'		;W = B'00001100'
				MOVWF 	CCP2CON			;Configura a CCP2 como PWM
				MOVLW 	B'00000111'		;W = B'00000111'
				MOVWF	T2CON			;Activacion del Timer 2
										;Pre-divisor Timer 2 = b'11'
				MOVLW 	D'120'			;W = D'120'
				MOVWF 	CCPR2L			;Define el tiempo en alto de la señal
	;Inicializaciones
				CLRF  	PORTB			;Limpia el puerto B
				CLRF	PORTC			;Limpia el puerto C
				CLRF  	CONTADOR		;Limpiar el registro CONTADOR

				GOTO  	$				;Loop infinito
INTERRUPCIONES:	BTFSS 	INTCON,T0IF	  	;¿T0IF = 1?
				GOTO  	SAL_NO_FUE_TMR0 ;No: ir a SAL_NO_FUE_TMR0
				INCF  	CONTADOR		;Si: incrementar CONTADOR
				MOVLW 	D'150'		  	;W = D'150'
				SUBWF 	CONTADOR,W	  	;W = CONTADOR - D'150'
				BTFSS 	STATUS,Z		;¿CONTADOR = D'150'?
				GOTO  	SAL_INT		  	;No: ir a SAL_INT
				COMF  	PORTB			;Si: Limpiar el puerto B
				CLRF  	CONTADOR		;Limpiar el registro CONTADOR
SAL_INT:		BCF   	INTCON,T0IF	  	;Bandera de desbordamiento. T0IF = 0
SAL_NO_FUE_TMR0:RETFIE				  	;Return de interrupcion
;**********************************************************
;***********************--------------*********************
;						  FUNCIONES
;***********************--------------*********************
;**********************************************************
;/////////////////////////////
; CONFIGURACION INICIAL LCD
;/////////////////////////////
INICIA_LCD: 	MOVLW 	H'38'
     			CALL  	COMANDO
     			MOVLW 	H'0C'
				CALL  	COMANDO
     			MOVLW 	H'01'
     			CALL  	COMANDO
     			MOVLW 	H'06'
     			CALL  	COMANDO
    			MOVLW 	H'02'
    			CALL  	COMANDO
    			RETURN
;/////////////////////////////
; PASO COMANDOS A LCD
;/////////////////////////////
COMANDO: 		MOVWF 	PORTB 
    	 		CALL  	RETARDO_200ms
    	 		BCF  	PORTC,0       	;RS se pone a 0 (CONTROL)
    	 		BSF   	PORTC,2       	;Se habilita E (Enable)
    	 		CALL  	RETARDO_200ms
    	 		BCF   	PORTC,1
    	 		RETURN	
;/////////////////////////////
; PASO DATOS A LCD
;/////////////////////////////
DATOS:	 		MOVWF 	PORTB
    	 		CALL 	RETARDO_200ms
    	 		BSF   	PORTC,0       	;RS se pone a 1 (DATOS)
    	 		BSF   	PORTC,2       	;Se habilita E (Enable)
    	 		CALL  	RETARDO_200ms
    	 		BCF   	PORTC,1
    	 		CALL  	RETARDO_200ms
    	 		CALL  	RETARDO_200ms
   		 		RETURN
;******************************
;	FUNCIONES DE RUTINAS
;******************************
;////////////////////
; 	 LECTURA A-D
;////////////////////		
LEEAD:  		BSF   	ADCON0,2		;Bandera GO/DONE = 1 para iniciar la conversion
				CALL  	RETARDO_20us	;Esperar 20 micro segundos
ESPERA: 		BTFSC 	ADCON0,2		;¿GO/DONE = 0? (termino conversion)
				GOTO  	ESPERA			;No: espera
				MOVF  	ADRESH,W		;Si: W = Resultado del convertidor A/D (ADRESH)
				MOVWF 	REGA			;Se mueve el resultado al REGA
				RETURN
;******************************
;			RETARDOS
;******************************
;///////////////////
; RETARDO_200ms
;///////////////////
RETARDO_200ms: 	MOVLW  	H'02'
       		   	MOVWF  	VALOR2 
CICLO1:		   	MOVLW  	D'164'
               	MOVWF  	VALOR1
CICLO2:	       	DECFSZ 	VALOR1,1
      		   	GOTO   	CICLO2
      		   	DECFSZ 	VALOR2,1
      		   	GOTO   	CICLO1
      		   	RETURN
;///////////////////
; RETARDO_20 micro s
;/////////////////// 		   	
RETARDO_20us: 	MOVLW 	H'30'			;W = 30
		 		MOVWF 	VAL				;VAL = W
LOOP:	 		DECFSZ  VAL				;VAL = VAL-1 y VAL = 0?
		 		GOTO 	LOOP			;No: ir a LOOP
		 		RETURN					;Sí: regresar
				END			