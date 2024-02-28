;---------------------------------------------------------------------
P5		EQU	0F8h		; adres P5 w obszarze SFR
P7		EQU	0DBh		; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS		EQU	P5		; wiersze na P5.7-4
COLS		EQU	P7		; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
;---------------------------------------------------------------------

ORG 0
;loop:
	;mov	A, #2
	;lcall	kbd_select_row
	;lcall	kbd_read_row
	;sjmp	loop
main_loop:
	lcall	kbd_read
	lcall	kbd_display
	sjmp	main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
	mov		R1, A
	
	anl		A, #0FCh		; sprawdzenie czy numer wiersza wiekszy od 3 (1111 1100 & (11 / 10 / 01 / 00))
	jnz		set_all			; jesli otrzymany wynik jest niezerowy oznacza to, ze w A byla liczba wieksza od 3
	
	mov		R0, #01111111b		; przenosimy do R0 wartosc 0111 1111 ktora poczatkowo wskazuje na aktywny zerowy wiersz
check_acc:
	mov		A, R1			; w akumulatorze jest numer wiersza ktory posluzy za licznik
	jz		set_P5			; jesli licznik rowny 0 przejdz do ustawienia P5
	
	dec		A			
	mov		R1, A			; odlozenie zmniejszonego licznika do R1
	
	mov		A, R0
	rr 		A			; obrot o jeden bit w prawo - zmiana "aktywnego" wiersza na kolejny
	mov		R0, A			; odlozenie zmodyfikowanej wartosci do R0
	sjmp		check_acc		; ponowne sprawdzenie licznika
	
set_all:
	orl		ROWS, #0F0h		; wylaczenie wszystkich wierszy
	sjmp		end_select_row
	
set_P5:
	mov		A, R0
	mov		ROWS, A			; wlaczenie pojedynczego wiersza 

end_select_row:
	ret

;---------------------------------------------------------------------
; Odczyt wybranego wiersza klawiatury
;
; Wejscie: A  - numer wiersza (0 .. 3)
; Wyjscie: CY - stan wiersza (0 - brak klawisza, 1 - wcisniety klawisz)
;	   A  - kod klawisza (0 .. 3)
;---------------------------------------------------------------------
kbd_read_row:
	lcall		kbd_select_row	; aktywowanie wiersza
	
	mov		R3, COLS		; zapisanie stanu kolumn (P7)
	mov		R2, #1			; "wskaznik" na kolumne, ktory poczatkowo wskazuje na kolumne 0 (0001)
	mov		R4, #0			; nr aktualnej kolumny
	
check_column:
	mov		A, R2			; w akumulatorze jest informacja o aktualnie sprawdzanej kolumnie
	anl		A, R3			; sprawdzenie czy w danej kolumnie jest stan niski 
	jz		save_result		; jesli stan niski to przechodzi do zwrocenia wyniku
	
	inc		R4			; jesli nie ma stanu niskiego sprawdz kolejna kolumne
	mov		A, R2
	rl		A
	mov		R2, A			; przesuwam "wskaznik" na kolejna kolumne
	
	mov		A, R4
	anl		A, #0FCh		; sprawdzenie czy numer kolumny jest wiekszy od 3 (1111 1100 & (11 / 10 / 01 / 00))
	jz		check_column		; jesli nie jest wiekszy od 3 sprawdz kolejna kolumne
	
	clr 		C			; jesli nr kolumny wiekszy niz 3 to zwroc informacje o niewcisnietym klawiszu
	sjmp		end_read_row	
	
save_result:
	setb	C				; ustawienie informacji o wcisnieciu klawisza
	mov		A, R4			; przeniesienie do akumulatora informacji o nr kolumny 
end_read_row:
	ret

;---------------------------------------------------------------------
; Odczyt calej klawiatury
;
; Wyjscie: CY - stan klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_read:
	mov		R5, #0
read_row:
	mov		A, R5			; nr wiersza
	lcall		kbd_read_row
	jc		save_result_2		; jesli flaga ustawiona na 1 to znaczy ze w tym wierszu jest wcisniety klawisz
	
	inc		R5			; jesli nie bylo wcisnietego klawisza, przejdz do kolejnego wiersza
	mov		A, R5
	anl		A, #0FCh		; sprawdzenie czy numer wiersza jest wiekszy od 3 (1111 1100 & (11 / 10 / 01 / 00))
	jz		read_row		; jesli nr wiersza nie wiekszy od 3 przejdz do czytania wiersza
	;cjne		R5, #4, read_row
	clr		C			; jesli nr wiersza wiekszy od 3 podaj informacje o braku wcisnietego klawisza
	sjmp		end_kbd_read
	
save_result_2:
	mov		R6, A			; przenies do R1 informacje o nr klawisza
	mov		B, #4
	mov		A, R5			; przenies do akumulatora informacje o nr aktywnego wiersza
	mul		AB			; A = nr wiersza * 4
	add		A, R6			; A = (nr wiersza * 4) + nr klawisza
	setb 		C			; ustaw informacje o wcisnietym przycisku
end_kbd_read:
	ret

;---------------------------------------------------------------------
; Wyswietlenie stanu klawiatury
;
; Wejscie: CY - stanu klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A  - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_display:
	jnc		shut_leds		; jesli brak wcisnietego klawisza przejdz do wylaczenia ledow
	xrl		A, #0FFh		; ustawienie przeciwnych wartosci za pomoca xora
	clr		ACC.7			; ustawienie najstarszego bitu na 0 (ON)
	mov		LEDS, A			; wlaczenie diod
	sjmp		end_kdb_display	
	
shut_leds:
	mov	 	LEDS, #0FFh		; wylaczenie diod
end_kdb_display:
	mov		A, #4
	lcall		kbd_select_row		; wylaczenie rzedow
	ret

END