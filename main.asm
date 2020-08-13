processor 16f877
include<p16f877.inc>
;PropÃƒÂ³sito: sistema para el control de flujo de personas hacia el interior de un
;			 establecimiento en un contexto de pandemia por coronavirus (COVID-19).

;////////////////////
; COMANDOS LCD
;////////////////////
HOME 	EQU H'02'
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
REGA      EQU H'29'      ;donde estará el número hexadecimal
REGB      EQU H'2A'      ;Aquí se guardara el divisor 
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
REGVAL    EQU H'31' 		;registro donde está el valor a convertir
REG01     EQU H'32'			;
REG02     EQU H'33'			;Registros de ayuda para las operaciones	
REG03     EQU H'34'			;
REG04     EQU H'35'			;
REGCONT   EQU H'36'			;contador

CONTADOR EQU H'37'
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
				BSF   	INTCON,T0IE	  	;Habilita interrupcion por desbordamiento del TIMER0
				BSF   	INTCON,GIE	  	;Habilita interrupciones generales
	;Configuracion de PWM
				MOVLW 	D'255'			;W = D'255'
				MOVWF 	PR2				;Periodo de la seÃ±al = D'255'
				MOVLW 	B'00001100'		;W = B'00001100'
				MOVWF 	CCP2CON			;Configura a CCP2 como PWM
				MOVLW 	B'00000111'		;W = B'00000111'
				MOVWF	T2CON			;Activacion del Timer 2
										;Pre-divisor Timer 2 = b'11'
				MOVLW 	D'120'			;W = D'120'
				MOVWF 	CCPR2L			;Define el tiempo en alto de la seÃ±al
	;Inicializaciones
				CALL	INICIA_LCD		;Inicializar el LCD
				CLRF  	PORTB			;Limpia el puerto B
				CLRF	PORTC			;Limpia el puerto C
				CLRF  	CONTADOR		;Limpiar el registro CONTADOR
				CALL	MENSAJE_1
				GOTO  	$				;Loop infinito
INTERRUPCIONES:	BTFSS 	INTCON,T0IF	  	;ï¿½T0IF = 1?
				GOTO  	SAL_NO_FUE_TMR0 ;No: ir a SAL_NO_FUE_TMR0
				INCF  	CONTADOR		;Si: incrementar CONTADOR
				MOVLW 	D'150'		  	;W = D'150'
				SUBWF 	CONTADOR,W	  	;W = CONTADOR - D'150'
				BTFSS 	STATUS,Z		;ï¿½CONTADOR = D'150'?
				GOTO  	SAL_INT		  	;No: ir a SAL_INT
				CALL	MENSAJE_1		;Si: ir a MENSAJE_1
				CALL    RETARDO_1s		;un retardo
			;/////////////////////////
			;Envio valor leido a lcd
			;/////////////////////////
				MOVLW   0x80
   				CALL    COMANDO 
VALOR_AD:		CALL    LEEAD
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
				GOTO    VALOR_AD
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
; 		MENSAJE 1
;/////////////////////////////
MENSAJE_1:		MOVLW   HOME
   				CALL    COMANDO 		;LCD: "VENGA AL SENSOR"
   				MOVLW  	A'V'
	        	CALL   	DATOS
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
;////////////////////
; 	 LECTURA A-D
;////////////////////		
LEEAD:  		BSF   	ADCON0,2		;Bandera GO/DONE = 1 para iniciar la conversion
				CALL  	RETARDO_20us	;Esperar 20 micro segundos
ESPERA: 		BTFSC 	ADCON0,2		;Â¿GO/DONE = 0? (termino conversion)
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
;Convierte un número hexadecimal , donde en un registro esta la parte entera y 
;en el otro la mantisa a un numero en base 10 con 3 cifras
;-------------------------------------------------------------------------------
CONVIERTE_DEC: MOVF		REG03,W    ;Aquí va regsal1
			   MOVWF 	REGCONV
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02     	;Se limpian registros para usarlos
			   MOVLW  	A'.'
	           CALL   	DATOS
			   MOVLW 	H'0B'	  	;se mueve un 11 a regcont para multiplidcar por 10
			   MOVWF 	REGCONT	
			   CALL  	MULTIPLICA	;se muiltplica por 10 
			   MOVF  	REG03,W	;Aquí va regsal2
			   MOVWF 	REGCONV
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02		;se realiza la multiplciacion con lo que quedó en la parte decimal de la multplicacion
			   MOVLW 	H'0B'
			   MOVWF 	REGCONT
			   CALL  	MULTIPLICA
			   MOVF  	REG03,W	;Aquí va regsal3
			   MOVWF 	REGCONV
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02
			   MOVLW 	H'0B'
			   MOVWF 	REGCONT
			   CALL  	MULTIPLICA
			   MOVF  	REG03,W	;Aquí va regsal4
			   MOVWF 	REGCONV
			   CALL  	CONVERTIR
			   CLRF  	REG03
			   CLRF  	REG02
			   MOVLW   	A'V'
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
		 		RETURN					;Sï¿½: regresar
;///////////////////
; RETARDO_1s
;///////////////////
RETARDO_1s:    MOVLW  CONST3 	;Carga lo vlaores para el while principal
		  	   MOVWF  REG3
LOOP3:  	   MOVLW  CONST2	;este es el loop mÃ¡s externo
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
