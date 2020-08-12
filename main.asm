processor 16f877
include<p16f877.inc>
;PropÃ³sito: sistema para el control de flujo de personas hacia el interior de un
;			 establecimiento en un contexto de pandemia por coronavirus (COVID-19).

; PORTB BUS DE DATOS B0-D0 ... B7-D7
 ; RS - A0
 ; E - A1
 ; R/W - GND

 processor 16f877
 include<p16f877.inc>
;////////////////////
; COMANDOS LCD
;////////////////////
HOME 	EQU H'02'
ENTER   EQU H'C0'
LIMPIA  EQU H'01'
MOVCI   EQU H'10' ;Mover el cursor a la izquierda
;////////////////////
; CONST RETARDO
;////////////////////
CONST1   EQU H'F2'
CONST2   EQU H'F5'
CONST3   EQU H'1C'

VALOR1   EQU H'20'
VALOR2   EQU H'21'
VALOR3   EQU H'22'

CONTADOR EQU H'23'
;////////////////////
; REG RETARDO
;////////////////////
REG1 EQU H'24'
REG2 EQU H'25'
REG3 EQU H'26'
;////////////////////
; REG HEX a LCD
;////////////////////
REGCONV 	EQU H'27'  ;Numero a convertir

;///////////////////////
; REGISTROS DIVISION
;///////////////////////
REGA      EQU H'28'      ;donde estará el número hexadecimal
REGB      EQU H'29'      ;Aquí se guardara el divisor 
REGAUX    EQU H'2A'      ;Registro auxiliar
REGDIV    EQU H'2B'      ;Registro que almacena el resultado
REGRES    EQU H'2C'		 ;Registro que almacena el residuo
REGNUM    EQU H'2D'
;////////////////////
; REG FUNCIONES
;////////////////////
REGA1  EQU H'2E'
REGB1  EQU H'2F'

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
DATOS:	 MOVWF PORTB
    	 CALL  RETARDO_200ms
    	 BSF   PORTA,0       ;RS se pone a 1 (DATOS)
    	 BSF   PORTA,1       ;Se habilita E (Enable)
    	 CALL  RETARDO_200ms
    	 BCF   PORTA,1
    	 CALL  RETARDO_200ms
    	 CALL  RETARDO_200ms
   		 RETURN 
;//////////////////////////////
;	CONVERSION A CODIGO LCD
;//////////////////////////////
CONVERTIR:		MOVLW  H'0A'
				SUBWF  REGCONV,0
				BTFSC  STATUS,C        ;REVISA SI EL NUMERO ES MENOR
				GOTO   MAYOR_IGUAL_Q_A ;O MAYOR O IGUAL QUE A
				GOTO   MENOR_Q_A
MAYOR_IGUAL_Q_A:MOVLW  H'37'		   ;SI ES MAYOR O IGUAL LE SUMA 37
			    ADDWF  REGCONV,0
				CALL   DATOS      		;ENVIA LOS DATOS AL LCD
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
;///////////////////
; RETARDO_200ms
;///////////////////


RETARDO_200ms: MOVLW  0x02
       		   MOVWF  VALOR2 
CICLO1:		   MOVLW  d'164'
               MOVWF  VALOR1
CICLO2:	       DECFSZ VALOR1,1
      		   GOTO   CICLO2
      		   DECFSZ VALOR2,1
      		   GOTO   CICLO1
      		   RETURN

  END
