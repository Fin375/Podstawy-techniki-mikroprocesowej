;------------------------------------------------------------------------------
LEDS		EQU	P1					; diody LED na P1 (0 = ON)
;------------------------------------------------------------------------------
TIME_MS		EQU	10					; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
SEC_100		EQU	30h					; sekundy x 0.01
SEC			EQU	31h					; sekundy
MIN			EQU	32h					; minuty
HOUR		EQU	33h					; godziny
;------------------------------------------------------------------------------

ORG 0
	;mov R7, #5
	lcall	leds_change_2		; inicjowanie czasu
time_loop:
	lcall	delay_10ms				; opoznienie 10 ms
	lcall	update_time				; aktualizacja czasu
	jnc	time_loop					; nie bylo zmiany sekund
									; tutaj zmiana sekund
	sjmp	time_loop

leds_loop:
	mov	R7, #50						; opoznienie 500 ms
	lcall	delay_nx10ms
	lcall	leds_change_1			; zmiana stanu diod
	sjmp	leds_loop

;---------------------------------------------------------------------
; Opoznienie 10 ms (zegar 12 MHz)
;---------------------------------------------------------------------
delay_10ms:							; 2		lcall
	mov R6, #103					; 1		
	nop
	nop
	nop
	nop								; 4 * 1 = 4
delay_97us:		
	mov R5, #47						; 1
	djnz R5, $						; 2 -> 47 * 2 = 94
	djnz R6, delay_97us  			; 2
									; -> 2 + 1 + 4 + 103*97 +2 = 10000				
	ret								; 2

;---------------------------------------------------------------------
; Opoznienie n * 10 ms (zegar 12 MHz)
; R7 - czas x 10 ms
;---------------------------------------------------------------------
delay_nx10ms:  						; 2		lcall
	mov A, R7						; 1
	jz koniec						; 2		sprawdzenie, czy n jest rózne od zera
	dec A							; 1
	cjne A, #0, wiecej				; 2		sprawdzenie, czy n jest wieksze od 1
	jnc jedynka						; 2		sprawdzenie, czy n jest rowne 1
wiecej:								; gdy n>1
	dec R7							; 1
lcall_delay_10ms:
	lcall delay_10ms
	djnz R7, lcall_delay_10ms		; (n-1) * 10 ms
	nop								; 1
jedynka:							; gdy n>=1
	mov R5, #104					; 1
delay_96us:
	mov R6, #46						; 1		
	djnz R6, $						; 2	-> 2 * 46 = 92
	nop								; 1
	djnz R5, delay_96us				; 2	
	nop
	nop
	nop								; 1 * 3 = 3
koniec:								; gdy n>=0
	ret  							; 2

;---------------------------------------------------------------------
; Opoznienie 10 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_10ms:					; 2		lcall
	clr TR0							; 1		zatrzymanie timera
	anl TMOD, #11110000b			; 2		wyzerowanie timera 0
	orl TMOD, #00000001b			; 2		ustawienie timera 0
	mov TL0, #LOW(LOAD)				; 2		wpisanie wartosci do rejestrow licznika
	mov TH0, #HIGH(LOAD)			; 2
	clr TF0							; 1		wyzerowanie flagi przepelnienia timera
	setb TR0						; 1		uruchomienie timera
	mov R6, #15						; 2 + 1 + 2 + 2 + 2 + 2 + 1 + 1 = 13
dodaj:	
	inc TL0							; uwzglednienie rozkazow przed wlaczeniem timera
	djnz R6, dodaj
	jnb TF0, $						; czekanie na ustawienie flagi przepelnienia timera
	ret								; 2		
									; 13 + 2 = 15

;---------------------------------------------------------------------
; Inicjowanie czasu w zmiennych: HOUR, MIN, SEC, SEC_100
;---------------------------------------------------------------------
init_time:
	mov SEC_100, #99
	mov SEC, #59
	mov MIN, #59
	mov HOUR, #23
	ret

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | SEC_100
; Przy wywolywaniu procedury co 10 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Wyjscie: CY - sygnalizacja zmiany sekund (0 - nie, 1 - tak)
;---------------------------------------------------------------------
update_time:
	clr F0							; wartosc poczatkowa f0
	inc SEC_100	
	mov A, SEC_100			
	cjne A, #100, koniec5			; sprawdzenie, czy osiagnal wartosc graniczna
	mov SEC_100, #0					; wyzerowanie, jesli tak sie stalo
	setb F0							; ustawienie flagi zmiany sekund
	inc SEC					
	mov A, SEC				
	cjne A, #60, koniec5
	mov SEC, #0	
	inc MIN					
	mov A, MIN				
	cjne A, #60, koniec5		
	mov MIN, #0
	inc HOUR				
	mov A, HOUR				
	cjne A, #24, koniec5		
	mov HOUR, #0
koniec5:
	mov C, F0						; przeniesienie flagi zmiany sekund do flagi CY
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - wedrujaca w lewo dioda
;---------------------------------------------------------------------
leds_change_1:
	mov A, LEDS
	cjne A, #11111111b, przesuniecie 	; sprawdzenie, czy diody nie sa w wejsciowym stanie
	mov LEDS, #11111110b				; zapalenie ostatniej diody
	sjmp koniec6					 
przesuniecie:
	mov	A, LEDS			 
	rl A								; przesuniecie zapalonej diody w lewo
	mov LEDS, A			
koniec6:	
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od prawej
;---------------------------------------------------------------------
leds_change_2:
	mov A, LEDS
	cjne A, #11111111b, dalej			; sprawdzenie, czy diody sa w wejsciowym stanie
	mov LEDS, #11111110b				; zapalenie ostatniej diody
	sjmp koniec7
dalej:
	cjne A, #00000000b, dalej2			; sprawdzenie, czy wszystkie diody sa zapalone
	mov LEDS, #11111111b				; zgaszenie wszystkich diod
	sjmp koniec7					 	 
dalej2:
	mov A, LEDS			 
	rl A								; przesuniecie zapalonej diody w lewo
	anl A, #11111110b					; zapalenie ostatniej diody
	mov LEDS, A				 
koniec7:
	ret

END