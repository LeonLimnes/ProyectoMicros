processor 16f877
include<p16f877.inc>
;Proposito: sistema para el control de flujo de personas hacia el interior de un
;			 establecimiento en un contexto de pandemia por coronavirus (COVID-19).

;////////////////////
; COMANDOS LCD
;////////////////////
HOME 	   EQU H'02'
ENTER      EQU H'C0'
LIMPIALCD  EQU H'01'
;////////////////////////////////
; REGISTROS PARA INTERRUPCIONES
;////////////////////////////////
CONTADOR1		EQU   0X40
CONTADOR2		EQU   0X41	
DATO            EQU H'38'
APUNTA	 	    EQU H'39'
;////////////////////
; CONST RETARDO
;////////////////////
CONST1    EQU H'F2'
CONST2    EQU H'F5'
CONST3    EQU H'1C'

VALOR1    EQU H'20'
VALOR2    EQU H'21'

VAL       EQU H'24'			;VARIABLE PARA EL CONTADOR
;////////////////////
; REG RETARDO
;////////////////////
REG1 	  EQU H'25'
REG2 	  EQU H'26'
REG3 	  EQU H'27'
;////////////////////
; REG HEX a LCD
;////////////////////
REGCONV	  EQU H'28'  ;Numero a convertir
;///////////////////////
; REGISTROS DIVISION
;///////////////////////
REGA      EQU H'29'      ;donde estar� el n�mero hexadecimal
REGB      EQU H'2A'      ;Aqu� se guardara el divisor 
REGAUX    EQU H'2B'      ;Registro auxiliar
REGDIV    EQU H'2C'      ;Registro que almacena el resultado
REGRES    EQU H'2D'		 ;Registro que almacena el residuo
REGNUM    EQU H'2E'
;////////////////////
; REG FUNCIONES
;////////////////////
REGA1  	  EQU H'2F'
REGB1     EQU H'30'

;Registros de rutina 11
REGVAL    EQU H'31' 		;registro donde est� el valor a convertir
REG01     EQU H'32'			;
REG02     EQU H'33'			;Registros de ayuda para las operaciones	
REG03     EQU H'34'			;
REG04     EQU H'35'			;
REGCONT   EQU H'36'			;contador

CONTADOR EQU H'37'
;////////////////////////////////
;REGISTROS LECTURA A/D CONVERTIDA
;////////////////////////////////
REGAD1 		EQU H'38'
REGAD2      EQU H'39'
REGAD3      EQU H'3A'
;////////////////////////////////
;REGISTROS PARA COMPARACION
;////////////////////////////////
REGCOMP1 		EQU H'3B'
REGCOMP2      	EQU H'3C'
REGCOMP3      	EQU H'3D'
;////////////////////
; INICIO
;////////////////////
				ORG   	0				;
				GOTO  	INICIO		  	;Define vector de Reset
				ORG   	4				;
				GOTO  	INTERRUPCIONES  ;Define vector de Interrupcion
				ORG   	5				;Indica origen para inicio del programa
INICIO:			BSF   	STATUS,5		;Cambio de banco
				BCF   	STATUS,6		;Cambio al banco 1
				CLRF   	ADCON1			;Configura al puerto A como entrada analogica
				CLRF  	TRISB			;Configura al puerto B como salida (LCD)
				CLRF  	TRISC			;Configura al puerto C como salida
				MOVLW 	H'FF'			;
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
				BSF   	INTCON,T0IE	  	;Habilita interrupcion por desbordamiento del TIMER0
				BSF   	INTCON,GIE	  	;Habilita interrupciones generales
	;Configuracion de PWM
				MOVLW 	D'255'			;W = D'255'
				MOVWF 	PR2				;Periodo de la señal = D'255'
				MOVLW 	B'00001100'		;W = B'00001100'
				MOVWF 	CCP2CON			;Configura a CCP2 como PWM
				MOVLW 	B'00000111'		;W = B'00000111'
				MOVWF	T2CON			;Activacion del Timer 2
										;Pre-divisor Timer 2 = b'11'
				MOVLW 	D'0'			;W = D'0'
				MOVWF 	CCPR2L			;Define el tiempo en alto de la señal
	;Inicializaciones
				CALL	INICIA_LCD		;Inicializar el LCD
				CLRF  	PORTB			;Limpia el puerto B
				CLRF	PORTC			;Limpia el puerto C
				CLRF  	CONTADOR		;Limpiar el registro CONTADOR
				CALL	MENSAJE_1
				GOTO  	$				;Loop infinito
INTERRUPCIONES:	BTFSS 	INTCON,T0IF	  	;�T0IF = 1?
				GOTO  	SAL_NO_FUE_TMR0 ;No: ir a SAL_NO_FUE_TMR0
				INCF  	CONTADOR		;Si: incrementar CONTADOR
				MOVLW 	D'150'		  	;W = D'150'
				SUBWF 	CONTADOR,W	  	;W = CONTADOR - D'150'
				BTFSS 	STATUS,Z		;�CONTADOR = D'150'?
				GOTO  	SAL_INT		  	;No: ir a SAL_INT
				CLRF  	CONTADOR		;Limpiar el registro CONTADOR
SENSOR_1:       BTFSS   PORTD,0         ;¿Hay alguien en el sensor para tomar la temperatura?
                GOTO    SENSOR_1        ;No: volver a preguntar
			;/////////////////////////
			;Envio valor leido a lcd
			;/////////////////////////
VALOR_AD:		CALL	MENSAJE_3;	MENSAJE DE TEMPERATURA
				MOVLW  	0xC4
	        	CALL   	COMANDO
				CALL    LEEAD
	        	MOVF    REGA,0
	        	MOVWF   REGVAL
				MOVF 	REGVAL,W
				MOVWF 	REG01
				CALL 	DIVIDE_ENTRE_64
				MOVF 	REG01,W
				MOVWF	REG03
				MOVF 	REG02,W
				MOVWF 	REG04
				MOVF 	REGVAL,W
				MOVWF 	REG01
				CLRF  	REG02
				CALL 	DIVIDE_ENTRE_256
				CALL 	SUMA
				CALL 	CONVIERTE_DEC
;/////////////////////////
;Comparacion temperatura
;/////////////////////////
				MOVLW 	H'03' ;SE MUEVE UN 3 AL REGISTRO DE COMPARACION1
				MOVWF   REGCOMP1 
				MOVF    REGAD1,W ;SE MEUVEN LAS DECENAS A W
				SUBWF	REGCOMP1,REGCOMP1	;SE RESTA 3 - DECENAS
				BTFSS	STATUS,C ;SI CARRY ES 0 ENTONCES ES MAYOR A 3
				GOTO	MENSAJE_2; DEBE DECIRLE QUE VAYA AL MEDICO
				MOVLW 	H'03' ;HABRA QUE PREGUNTAS SI ES EXACTAMENTE IGUAL A 3
				MOVWF   REGCOMP1 
				MOVF    REGAD1,W ;SE MEUVEN LAS DECENAS A W
				SUBWF	REGCOMP1,REGCOMP1	;SE RESTA 3 - DECENAS
				BTFSS   STATUS,Z ;SE PREGUNTA SI EL RESULTADO ES 0(SON IGUALES)
				GOTO	MENSAJE_5 ;LO MANDA A TOMAR GEL, TIENE MENOS DE 37 DE TEMPERTATURA
				MOVLW 	H'07' ;SE MUEVE UN 7 AL REGISTRO DE COMPARACION1
				MOVWF   REGCOMP1 
				MOVF    REGAD2,W ;SE MUEVEN LAS UNIDAES A W
				SUBWF	REGCOMP1,REGCOMP1	;SE RESTA 7 - UNIDADES
				BTFSS	STATUS,C ;SI CARRY ES 0 ENTONCES ES MAYOR A 7
				GOTO 	MENSAJE_2
				MOVLW 	H'07' ;HABRA QUE PREGUNTAS SI ES EXACTAMENTE IGUAL A 7
				MOVWF   REGCOMP1 
				MOVF    REGAD1,W ;SE MEUVEN LAS DECENAS A W
				SUBWF	REGCOMP1,REGCOMP1	;SE RESTA 7 - DECENAS
				BTFSS   STATUS,Z ;SE PREGUNTA SI EL RESULTADO ES 0(SON IGUALES)
				GOTO	MENSAJE_5 ;LO MANDA A TOMAR GEL, TIENE MENOS DE 37 DE TEMPERTATURA
				MOVLW 	H'03' ;SE MUEVE UN 3 AL REGISTRO DE COMPARACION1
				MOVWF   REGCOMP1 
				MOVF    REGAD3,W ;SE MEUVEN LAS CENTECIMAS
				SUBWF	REGCOMP1,REGCOMP1	;SE RESTA 3 - CENTECIMAS
				BTFSS	STATUS,C ;SI CARRY ES 0 ENTONCES ES MAYOR A 3
				GOTO	MENSAJE_2; DEBE DECIRLE QUE VAYA AL MEDICO
				GOTO	MENSAJE_5;SI NO PUEDE PASAR
SAL_INT:		BCF   	INTCON,T0IF	  	;Bandera de desbordamiento. T0IF = 0
SAL_NO_FUE_TMR0:RETFIE				  	;Return de interrupcion

TOMAR_GEL:		BTFSS   PORTD,1         ;¿Hay alguien en el sensor para tomar la temperatura?
                GOTO    MENSAJE_5        ;No: volver a preguntar
				CALL 	ENCENDER_MOTOR	;DA GEL
				CALL	MENSAJE_4		;PUEDE INGRESAR
				BSF 	PORTC,3			;LED DE INDICACION
				CALL	RETARDO_1s
				CALL	RETARDO_1s		;TIENE 3 SEGUNDOS PARA INGRESAR
				CALL	RETARDO_1s
				BCF		PORTC,3			;SE APAGA LED
				GOTO 	INICIO			;INICIO					
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
    			MOVLW 	HOME
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
    	 		BCF   	PORTC,2
    	 		RETURN	
;/////////////////////////////
; PASO DATOS A LCD
;/////////////////////////////
DATOS:	 		MOVWF 	PORTB
    	 		CALL 	RETARDO_200ms
    	 		BSF   	PORTC,0       	;RS se pone a 1 (DATOS)
    	 		BSF   	PORTC,2       	;Se habilita E (Enable)
    	 		CALL  	RETARDO_200ms
    	 		BCF   	PORTC,2
    	 		CALL  	RETARDO_200ms
    	 		CALL  	RETARDO_200ms
   		 		RETURN
;******************************
;	FUNCIONES DE RUTINAS
;******************************
;/////////////////////////////
; 		ENCENDER MOTOR
;/////////////////////////////
ENCENDER_MOTOR: MOVLW 	D'150'			;W = D'150'
				MOVWF 	CCPR2L			;Define el tiempo en alto de la se�al
				CALL	RETARDO_1s 		;Llamar a retardo
				CALL	RETARDO_1s 		;Llamar a retardo
				CLRF 	CCPR2L			;Tiempo en alto de la se�al
				RETURN
;/////////////////////////////
; 		MENSAJE 1
;/////////////////////////////
MENSAJE_1:		CALL	INICIA_LCD
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				MOVLW   0x81
   				CALL    COMANDO 		;LCD: "VENGA AL SENSOR"
   		    	MOVLW  	A'V'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'N'
	        	CALL   	DATOS
	        	MOVLW  	A'G'
	        	CALL   	DATOS
	        	MOVLW  	A'A'
	        	CALL   	DATOS
	        	MOVLW  	A' '
	        	CALL   	DATOS
	        	MOVLW  	A'A'
	        	CALL   	DATOS
	        	MOVLW  	A'L'
	        	CALL   	DATOS
	        	MOVLW  	A' '
	        	CALL   	DATOS
	        	MOVLW  	A'S'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'N'
	        	CALL   	DATOS
	        	MOVLW  	A'S'
	        	CALL   	DATOS
	        	MOVLW  	A'O'
	        	CALL   	DATOS
	        	MOVLW  	A'R'
	        	CALL   	DATOS
	        	CALL	RETARDO_1s
	        	RETURN
;/////////////////////////////
; 		MENSAJE 2
;/////////////////////////////
MENSAJE_2:		CALL	INICIA_LCD
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				MOVLW   0x83
   				CALL    COMANDO 		;LCD: "VISITE UN MEDICO"
   				MOVLW  	A'V'
	        	CALL   	DATOS
   		    	MOVLW  	A'I'
	        	CALL   	DATOS
	        	MOVLW  	A'S'
	        	CALL   	DATOS
	        	MOVLW  	A'I'
	        	CALL   	DATOS
	        	MOVLW  	A'T'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A' '
	        	CALL   	DATOS
	        	MOVLW  	A'U'
	        	CALL   	DATOS
	        	MOVLW  	A'N'
	        	CALL   	DATOS
	        	MOVLW  	0xC64
	        	CALL   	COMANDO
	        	MOVLW  	A'M'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'D'
	        	CALL   	DATOS
				MOVLW  	A'I'
	        	CALL   	DATOS
	        	MOVLW  	A'C'
	        	CALL   	DATOS
	        	MOVLW  	A'O'
	        	CALL   	DATOS
	        	CALL	RETARDO_1s
				CALL	RETARDO_1s
				CALL	RETARDO_1s
		        GOTO 	INICIO
;/////////////////////////////
; 		MENSAJE 3
;/////////////////////////////
MENSAJE_3:		CALL	INICIA_LCD
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				MOVLW   0x83
   				CALL    COMANDO 		;LCD: "TEMPERATURA"
   				MOVLW  	A'T'
	        	CALL   	DATOS
   		    	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'M'
	        	CALL   	DATOS
	        	MOVLW  	A'P'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'R'
	        	CALL   	DATOS
	        	MOVLW  	A'A'
	        	CALL   	DATOS
	        	MOVLW  	A'T'
	        	CALL   	DATOS
	        	MOVLW  	A'U'
	        	CALL   	DATOS
	        	MOVLW  	A'R'
	        	CALL   	DATOS
	        	MOVLW  	A'A'
	      		CALL 	DATOS
				CALL    RETARDO_1s
	        	RETURN
;/////////////////////////////
; 		MENSAJE 4
;/////////////////////////////
MENSAJE_4:		CALL	INICIA_LCD
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				MOVLW   0x81
   				CALL    COMANDO 		;LCD: "PUEDE INGRESAR"
   				MOVLW  	A'P'
	        	CALL   	DATOS
				MOVLW  	A'U'
	        	CALL   	DATOS
				MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'D'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A' '
	        	CALL   	DATOS
	        	MOVLW  	A'I'
	        	CALL   	DATOS
	        	MOVLW  	A'N'
	        	CALL   	DATOS
	        	MOVLW  	A'G'
	        	CALL   	DATOS
	        	MOVLW  	A'R'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'S'
	        	CALL   	DATOS
	        	MOVLW  	A'A'
	        	CALL   	DATOS
	        	MOVLW  	A'R'
	        	CALL   	DATOS
	        	CALL	RETARDO_1s
	        	RETURN
;/////////////////////////////
; 		MENSAJE 5
;/////////////////////////////
MENSAJE_5:		CALL	INICIA_LCD
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				CALL    RETARDO_200ms
				MOVLW   0x83
   				CALL    COMANDO 		;LCD: "TOME GEL"
   				MOVLW  	A'T'
	        	CALL   	DATOS
				MOVLW  	A'O'
	        	CALL   	DATOS
				MOVLW  	A'M'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A' '
	        	CALL   	DATOS
	        	MOVLW  	A'G'
	        	CALL   	DATOS
	        	MOVLW  	A'E'
	        	CALL   	DATOS
	        	MOVLW  	A'L'
	        	CALL   	DATOS
	        	CALL	RETARDO_1s
	        	GOTO 	TOMAR_GEL
;////////////////////
; 	 LECTURA A-D
;////////////////////		
LEEAD:  		BSF   	ADCON0,2		;Bandera GO/DONE = 1 para iniciar la conversion
				CALL  	RETARDO_20us	;Esperar 20 micro segundos
ESPERA: 		BTFSC 	ADCON0,2		;�GO/DONE = 0? (termino conversion)
				GOTO  	ESPERA			;No: espera
				MOVF  	ADRESH,W		;Si: W = Resultado del convertidor A/D (ADRESH)
				MOVWF 	REGA			;Se mueve el resultado al REGA
				RETURN
;//////////////////////////////
;	CONVERSION A CODIGO LCD
;//////////////////////////////
CONVERTIR:		MOVLW  H'0A'
				SUBWF  REGCONV,0
				BTFSC  STATUS,C        ;REVISA SI EL NUMERO ES MENOR
				GOTO   MAYOR_IGUAL_Q_A ;O MAYOR O IGUAL QUE A
				GOTO   MENOR_Q_A
MAYOR_IGUAL_Q_A:MOVLW  H'37'			;SI ES MAYOR O IGUAL LE SUMA 37
			    ADDWF  REGCONV,0
				CALL   DATOS    		;ENVIA LOS DATOS AL LCD
				RETURN
MENOR_Q_A:		MOVLW  H'30'			;SI ES MENOR LE SUMA 30
				ADDWF  REGCONV,0
				CALL   DATOS			;ENVIA LOS DATOS AL LCD
				RETURN
;///////////////////////
; 		DIVISION
;///////////////////////
DIVISION:   CLRF	REGAUX		;Limpieza de registros
			CLRF    REGDIV
			CLRF    REGRES
DIVI:		MOVF    REGA,0
			MOVWF   REGAUX
			MOVF    REGB,0
RESTA:		SUBWF   REGAUX,1	;restas sucesivas lo que esta en reg aux-regb
			BTFSS   STATUS,C
			GOTO    RESIDUO		
			INCF    REGDIV
			GOTO    RESTA
RESIDUO:    ADDWF   REGAUX,0	;se suma otra vez el dividendo para obtener el residuo
			MOVWF   REGRES
			RETURN
;////////////////////
; DIVISION ENTRE 64
;////////////////////
DIVIDE_ENTRE_64: MOVLW  H'06'
				 MOVWF  REGCONT
				 CALL   DIVIDE_ENTRE_2
				 RETURN
;////////////////////
; DIVISION ENTRE 2
;////////////////////
;-----------------------------------------------------------------------------------
; Recorre un registro a la derecha y guarda el valor del LSB en el registro contiguo
;-----------------------------------------------------------------------------------
DIVIDE_ENTRE_2:	 BCF    STATUS,C	;limpia estatus
			     RRF	REG02		;Recorre a la derecha el REG02
			     BCF    STATUS,C	
			     RRF	REG01		;recorre a la derecha el REG01
			     BTFSC  STATUS,C	;recorre y ve el valor del LSB
			     GOTO   UNO 
			     GOTO   CERO
CERO:		     BCF    REG02,7		;si es 0 escribe un 0 en el MSB
			     GOTO   DEC
UNO:		     BSF    REG02,7		;si es 1 escribe un 1 en el MSB
			     GOTO   DEC
DEC:		     DECFSZ REGCONT
				 GOTO   DIVIDE_ENTRE_2
				 RETURN
;//////////////////////
; DIVISION ENTRE 256
;//////////////////////
;--------------------------------------------------------------------------------------
; Dividir entre 2 implica recorrer 8 veces el registro, es el lo mismo que moverlo todo
;-------------------------------------------------------------------------------------
DIVIDE_ENTRE_256:MOVF   REG01,W 	;se compia el registro a W
				 MOVWF  REG02	 	;se mueve al REG02
				 CLRF   REG01	 	;se limpia REG01
				 RETURN
;//////////////////////
;	SUMA
;//////////////////////
;-----------------------------------------------------------------
;Suma numeros de 8 bits y si hay carry lo deja en otro registro
;---------------------------------------------------------------
SUMA:		MOVF    REG02,W
			ADDWF   REG04,1
			BTFSC   STATUS,C
			INCF    REG03
			RETURN
;////////////////////
; LIMPIEZA REGISTROS
;////////////////////
LIMPIA:		CLRF    REG01		;Limpia regitros de operaciones
			CLRF    REG02		
			CLRF    REG03		
		    CLRF    REG04		
			RETURN
;//////////////////////
; CONVERSION A DECIMAL
;//////////////////////
;-------------------------------------------------------------------------------
;Convierte un n�mero hexadecimal , donde en un registro esta la parte entera y 
;en el otro la mantisa a un numero en base 10 con 3 cifras
;-------------------------------------------------------------------------------
CONVIERTE_DEC: MOVLW  	A' '
	           CALL   	DATOS
			   MOVF		REG03,W    ;Aqu� va regsal1
			   MOVWF 	REGCONV
			   MOVWF    REGAD1     ;SE MUEVEN LA DECENAS
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02     	;Se limpian registros para usarlos
			   MOVLW 	H'0B'	  	;se mueve un 11 a regcont para multiplidcar por 10
			   MOVWF 	REGCONT	
			   CALL  	MULTIPLICA	;se muiltplica por 10 
			   MOVF  	REG03,W	;Aqu� va regsal2
			   MOVWF 	REGCONV
			   MOVWF    REGAD2     ;SE MUEVEN LAS UNIDADES
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02		;se realiza la multiplciacion con lo que qued� en la parte decimal de la multplicacion
			   MOVLW  	A'.'
	           CALL   	DATOS
			   MOVLW 	H'0B'
			   MOVWF 	REGCONT
			   CALL  	MULTIPLICA
			   MOVF  	REG03,W	;Aqu� va regsal3
			   MOVWF 	REGCONV
			   MOVWF    REGAD3     ;SE MUEVEN LAS CENTECIMAS
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02
			   MOVLW 	H'0B'
			   MOVWF 	REGCONT
			   CALL  	MULTIPLICA
			   MOVF  	REG03,W	;Aqu� va regsal4
			   MOVWF 	REGCONV
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02
			   MOVLW   	A'C'
	           CALL    	DATOS
	           CALL		RETARDO_1s
			   RETURN 
;//////////////////////
; MULTIPLICA POR 10
;//////////////////////	
;-------------------------------------------------------------------------------
;Multiplica dos numeros de 8 bits con la posibilidad de tener un resultado de 16
;-------------------------------------------------------------------------------
MULTIPLICA:	DECFSZ  REGCONT ;El registro de control del numero de vese que se debe sumar
			GOTO    SUMA_M  
			MOVF    REG02,W
			MOVWF   REG04	
			RETURN
SUMA_M:     MOVF    REG04,W  ;suma de dos numeros de 8 bits, con la posibilidad de tener un resultaod de 16 bit
			ADDWF   REG02,1	
			BTFSC   STATUS,C
			INCF    REG03
			GOTO    MULTIPLICA
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
		 		RETURN					;S�: regresar
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


		  	   END