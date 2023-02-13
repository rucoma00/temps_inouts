    list    p=16F877A
    include <p16f877a.inc>

	 ;configuracion
	 __CONFIG    _XT_OSC & _WDT_OFF & _LVP_OFF
	 org 0



	BSF STATUS,RP0            		;Paso al banco 1 de la memoria de datos
	CLRF TRISD				;para definir el PORTD como salida
	MOVLW b'10000001'			;  
	MOVWF TRISB	                	; Defino RB1:RB6 como salidas y dejo RB0 y RB7 como entradas
	BCF TRISA,2	      				;Y la linea 2 del puerto A como salida (solo linea, no puerto)
	MOVLW 0x07            			;Prepara TMR0 para contar pulsos de oscilador y
	MOVWF OPTION_REG			;le asigna un prescaler de 256
	BCF OPTION_REG,INTEDG			;Asignar a flanco de bajada (No me haria falta, ya lo hace la linea 15)
	BCF STATUS,RP0        			;Volvemos al banco 0
	MOVLW b'00101010'     			;
	MOVWF PORTB	      			;Precargo el puerto B con la primera combinacion a mostrar
	
; Definicion e inicializacion de variables y puertos
TIEMPO equ 0x20            						;Variable para las decimas a mostrar en el display
				MOVLW 0x05         				;Para precargar la variable a 5, primero cargo el valor en w
				MOVWF TIEMPO       			;y luego en TIEMPO
EFECTO equ 0x21            						;Variable de efecto (0,1,2)
				CLRF EFECTO        				;Iniciamos el efecto 0 (Alternancia)
				CLRF PORTD         				;Ponemos a cero el PORTD para que tenga ese valor inicial
IZQUIERDA equ 0x22          					;Variable para el sentido del efecto 2 
				MOVLW 0x01         				;(IZQUIERDA=1 => rota a izquierda)
				MOVWF IZQUIERDA    			;Comienza rotndao a izquierda, con lo cual, precargo 1
AUX equ 0x23               						;Variable para cambios en el efecto 2 antes de mostrarlo
				MOVLW b'00000010'  			;Precarga de la variable AUX en W
				MOVWF AUX          				;y luego en la variable
CUENTA equ 0x24            						;Variable para multiplicar por 2
				CLRF CUENTA        				;Precarga de CUENTA en 0
ANTES equ 0x25             						;Variable para mirar como estaba RA4 antes
				CLRF ANTES         				;Se inicia la variable a 0
                           
	
	BCF PORTA,2        							;Encendemos el display
	
	;Bucle principal 
	;(se repite a intervalos de tiempo constante marcados
	;por la temporizacion)
BUCLE	CALL MOSTRAR_TIEMPO  			; Llamada al programa que muestra las decimas en el display
			MOVF PORTA,W        		 			;Carga el valor actual de PORTA en W
			MOVWF ANTES          					;Y de W a ANTES (para recordarlo al mirar RA4)
			CALL LEDS            						; Llamada al programa que muestra el efecto en los LEDs
			CALL TEMPORIZAR     	 				; Llamada al programa que temporiza las decimas de segundo
	
			BTFSC INTCON,INTF    					;Compruebo si hay una nueva pulsacion en el pulsador de tiempo (RB0)
			CALL SUBIR_TIEMPO  					;comprobando el estado de INTF. Si la hay (INTF=1), modifico el tiempo
			BTFSS PORTA,4        					;Luego compruebo si hay una nueva pulsacion en el pulsador de 
			CALL CAMBIAR_EFECTO 			;cambio de efecto. Si la hay (RA4=0), cambio el efecto
			GOTO BUCLE                   		 	;Fin del bucle principal
	

	
	;Subprograma SUBIR_TIEMPO
SUBIR_TIEMPO
	BCF INTCON,INTF				     	;Pongo INTF a 0
	INCF TIEMPO          					;incremento TIEMPO en 1
	MOVLW d'10'          					;Numero siguiente al numero a mostrar
	XORWF TIEMPO,W       			;Compruebo si TIEMPO a alcanzado ese valor
	BTFSC STATUS,Z	    				;miro si z es 0 o 1
	CALL CARGAR_1        				;si es 1 es que era d'10' asi que cargo el 1
	RETURN               					;retorno al BUCLE
	
	
	;Subprograma CARGAR_1
	;Carga d'1' en TIEMPO
CARGAR_1
	MOVLW d'1'
	MOVWF TIEMPO 						;Carga 1 en TIEMPO
	RETURN       							;Retorno a SUBIR_TIEMPO
	

	
	
	;Subprograma LEDS
LEDS
					MOVF EFECTO,W
					ADDWF PCL,F             		;Miro en que efecto estoy
					GOTO EFE_0					;Voy al efecto 0 (ALTERNANCIA)
					GOTO EFE_1              		;Voy al efecto 1 (PARPADEO)
					GOTO EFE_2              		;Voy al efecto 2 (DESPLAZAMIENTO)
	
EFE_0	COMF PORTB,F            ;Niego el actual valor de el puerto
			RETURN            			;vuelta al BUCLE
	
EFE_1	COMF PORTB,F            ;Niego el actual valor de el puerto
			RETURN						;Vuelta al BUCLE
	
EFE_2	BTFSC IZQUIERDA,0         ;miro si el primer bit de IZQUIERDA es 0 o 1
			GOTO IZQD               		;si es 1 roto izquierda
			GOTO DCHA	        			;si es 0 roto derecha.
 
IZQD	MOVF AUX,W              			;pongo AUX en PORTB (asi se muestra encendido el primer LED)
		MOVWF PORTB             		;salida por puerto B
		BCF STATUS,C            			;CARRY a 0
		RLF AUX,F               				;roto AUX a la izquierda 
		BTFSC AUX,6             			;compruebo si esta a 1 el bit 6 de AUX
		CLRF IZQUIERDA          		;Si lo esta, pongo IZQUIERDA a 0
		RETURN           					;vuelta al BUCLE

DCHA	MOVF AUX,W              		;pongo AUX en PORTB (asi se muestra encendido el ultimo LED)
			MOVWF PORTB             	;saida por puerto B
			BCF STATUS,C            		;CARRY a 0
			RRF AUX,F               		;roto AUX a la derecha
			BTFSC AUX,1             		;compruebo si esta a 1 el bit 1 de AUX
			INCF IZQUIERDA          		;Si lo esta, pongo IZQUIERDA a 1
			RETURN            	            ;vuelta al BUCLE


;Subprograma TEMPORIZAR
;Temporiza los efectos
TEMPORIZAR 
			CALL X2                 			;Multiplica TIEMPO por dos y lo almacena en CUENTA
DECR	DECFSZ CUENTA,F         	;Decremento cuenta en uno y cuando llegue a 0 retorno
			GOTO T_50ms             		;Si todavia no llego a 0 cuenta 50ms
			RETURN                  			;Cuando llegue a 0 retorno al BUCLE 

;Temporizacion 50ms
T_50ms
				MOVLW d'61'             	;Carga el valor 61 en el registro TMR0 (con este
				MOVWF TMR0             ;valor se temporizan 50ms)
ESPERA	BTFSS INTCON,T0IF     ;Compruebo si esta a 1
				GOTO ESPERA            ;Si sigue a 0, espero a que cambie a 1
				BCF INTCON,T0IF         ;Flag del contador a 0 
				GOTO DECR               	;Retorna a TEMPORIZAR cuando el flag es 1
	

;Subprograma X2
;Multiplica un numero por 2
X2
	MOVF TIEMPO,W           	;Cargo TIEMPO en W
	MOVWF CUENTA           	;y cargo W en CUENTA
	BCF STATUS,C            		;Carry a 0
	RLF CUENTA,F            		;Roto a la izquierda CUENTA
	RETURN                  			;Retorno al subprograma TEMPORIZAR




;Subprograma MOSTRAR_TIEMPO
;Toma el valor cargado en la posición TIEMPO,busca en la TABLA los segmentos a 
;iluminar y los saca al PORTD
MOSTRAR_TIEMPO
	MOVF TIEMPO,W ;cargamos inicialmente el valor de CUENTA en W
	CALL TABLA    ;LLamada al subprograma tabla
	MOVWF PORTD   ;sacamos w por el puerto D
	RETURN        ;retorno del subprograma
	
;Subprograma TABLA
TABLA
	ADDWF PCL,F       	;Suma del PCL con TIEMPO (que se encuentra en W)
        RETLW 0xC0          	;0
        RETLW 0xF9          	;1
        RETLW 0xA4          	;2
        RETLW 0xB0          	;3
        RETLW 0x99          	;4
        RETLW 0x92          	;5
        RETLW 0x82          	;6
        RETLW 0xF8          	;7
        RETLW 0x80          	;8
        RETLW 0x90          	;9
	

; Subprograma CAMBIAR_EFECTO
;cambio de efecto
CAMBIAR_EFECTO
				BTFSC ANTES,4        		;Miro como estaba el bit 4 del PORTA antes
				RETURN          		            ;Si estaba a 1 salimos del subprograma
				INCF EFECTO          			;si no, incremento EFECTO en 1
				MOVLW d'3'           			;Numero siguiente al numero de efecto mas alto(2)
				XORWF EFECTO,W       	;Compruebo si EFECTO a alcanzado ese valor
				BTFSC STATUS,Z	     		;miro si z es 0 o 1
				CLRF EFECTO          		;si es 1 es que era d'3' asi que cargo el 0
				MOVF EFECTO,W	     	;si es 0 es que no era d'3' asi que sigo. 
				ADDWF PCL,F          		;Mro en que efecto estoy para inicializar PORTB
				GOTO INI_0           			;inicializo para el efecto 0
				GOTO INI_1           			;inicializo para el efecto 1
				GOTO INI_2           			;inicializo para el efecto 2
														;retorno al BUCLE
	
INI_0 
	MOVLW b'00101010'
	MOVWF PORTB         	 ;cargo el valor inicial en el PUERTO B
	RETURN          			  	;Vuelvo al BUCLE
	
INI_1
	MOVLW 0x00
	MOVWF PORTB          	;cargo el valor inicial en el PUERTO B
	RETURN          				;Vuelvo al BUCLE
	
INI_2
	MOVLW b'00000010'		;valor inicial de AUX
	MOVWF PORTB          	;cargo el valor inicial en PORTB
	MOVLW 0x01         		;valor inicial de IZQUIERDA
	MOVWF IZQUIERDA		;Cargo el valor inical de izquierda
	RETURN          				;Vuelvo al BUCLE

    END
