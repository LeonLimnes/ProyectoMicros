processor 16f877
include<p16f877.inc>
;PropÃ³sito: sistema para el control de flujo de personas hacia el interior de un
;			 establecimiento en un contexto de pandemia por coronavirus (COVID-19).


CONTADOR  EQU H'20'	
;////////////////////
; CONST RETARDO
;////////////////////
CONST1   EQU H'F2'
CONST2   EQU H'F5'
CONST3   EQU H'1C'

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

;////////////////////
; INICIO
;////////////////////
    ORG  0
    GOTO INICIO
    ORG  5
;///////////////////////
; CONFIGURACION PUERTOS
;///////////////////////
INICIO: CLRF  PORTA
        CLRF  PORTB
		CLRF  PORTC
		CLRF  PORTD  
        BSF   STATUS,5		;CAMBIO DE BANCO
        BCF   STATUS,6
        MOVLW b'00000000'   ;PUERTO B COMO SALIDA
   		MOVWF TRISB
		MOVLW b'11111111'	;PUERTO C COMO ENTRADA
   		MOVWF TRISC
		MOVLW b'11111111'	;PUERTO D COMO ENTRADA
   		MOVWF TRISD
   		MOVLW 0x07
   		MOVWF ADCON1
   		MOVLW b'00000000'	;PUERTO A COMO SALIDA
   		MOVWF TRISA
   		BCF   STATUS,5	 	 ;VUELTA DE BANCO
;///////////////////////////////////////
;		FUNCION DE SELECION DE RUTINA
;///////////////////////////////////////
HOLA: CALL    INICIA_LCD
		MOVF    PORTC,0 ;ENTRADA DE SELECCION
		MOVLW HOME
   		CALL  COMANDO
		MOVLW A'H'
  		CALL  DATOS
  		MOVLW A'o'
  		CALL  DATOS
  		MOVLW A'l'
  		CALL  DATOS
  		MOVLW A'a'
  		CALL  DATOS
		MOVLW ENTER 
  		CALL  COMANDO ;nueva linea
  		MOVLW A'M'
  		CALL  DATOS
 		MOVLW A'u'
  		CALL  DATOS
 		MOVLW A'n'
  		CALL  DATOS
  		MOVLW A'd'
  		CALL  DATOS
  		MOVLW A'o'
  		CALL  DATOS
  		CALL  RETARDO_1s
		GOTO  HOLA
;**********************************************************
;***********************--------------*********************
;						  FUNCIONES
;***********************--------------*********************
;**********************************************************

;/////////////////////////////
; CONFIGURACION INICIAL LCD
;/////////////////////////////
INICIA_LCD   MOVLW 0x38
     		 CALL  COMANDO
     		 MOVLW 0x0C
			 CALL  COMANDO
     		 MOVLW LIMPIA
     		 CALL  COMANDO
     		 MOVLW 0x06
     		 CALL  COMANDO
    		 MOVLW HOME
    		 CALL  COMANDO
    		 RETURN
;/////////////////////////////
; PASO COMANDOS A LCD
;/////////////////////////////
COMANDO: MOVWF PORTB 
    	 CALL  RETARDO_200ms
    	 BCF   PORTA,0       ;RS se pone a 0 (CONTROL)
    	 BSF   PORTA,1       ;Se habilita E (Enable)
    	 CALL  RETARDO_200ms
    	 BCF   PORTA,1
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
MENOR_Q_A:		MOVLW  H'30'			;SI ES MENOR LE SUMA 30
				ADDWF  REGCONV,0
				CALL   DATOS      		;ENVIA LOS DATOS AL LCD
				RETURN
;///////////////////////
; 		DIVISION
;///////////////////////
DIVISION:      CLRF   REGAUX		;Limpieza de registros
			   CLRF   REGDIV
			   CLRF   REGRES
DIVI:		   MOVF   REGA,0
			   MOVWF  REGAUX
			   MOVF   REGB,0
RESTA:		   SUBWF  REGAUX,1	;restas sucesivas lo que esta en reg aux-regb
			   BTFSS  STATUS,C
			   GOTO   RESIDUO		
			   INCF   REGDIV
			   GOTO   RESTA
RESIDUO:       ADDWF  REGAUX,0	;se suma otra vez el dividendo para obtener el residuo
			   MOVWF  REGRES
			   RETURN

 
;******************************
;			RETARDOS
;******************************

;///////////////////
; RETARDO_1s
;///////////////////

RETARDO_1s:    MOVLW  CONST3 	;Carga lo vlaores para el while principal
		  	   MOVWF  REG3
LOOP3:  	   MOVLW  CONST2	;este es el loop más externo
			   MOVWF  REG2
LOOP2:	 	   MOVLW  CONST1	;el loop de enmedio
		 	   MOVWF  REG1	
LOOP1:	  	   DECFSZ REG1		;el loop mas anidado
		  	   GOTO   LOOP1		
		  	   DECFSZ REG2		
		  	   GOTO   LOOP2     ;decrementa en uno hasta que sea 0
		  	   DECFSZ REG3
		  	   GOTO   LOOP3
		  	   RETURN
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
:////////////////////
; RETARDO_20 micro s
;/////////////////// 		   	
RETARDO_20us: 	MOVLW 	H'30'			;W = 30
		 		MOVWF 	VAL				;VAL = W
LOOP:	 		DECFSZ  VAL				;VAL = VAL-1 y VAL = 0?
		 		GOTO 	LOOP			;No: ir a LOOP
		 		RETURN					;Sí: regresar
				END			

