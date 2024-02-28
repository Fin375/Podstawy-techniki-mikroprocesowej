WR_CMD		EQU	0FF2Ch					; zapis rejestru komend
WR_DATA		EQU	0FF2Dh					; zapis rejestru danych
RD_STAT		EQU	0FF2Eh					; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh					; odczyt rejestru danych

// dane ze strony 24 (tabela 6) z dokumentacji sterownika
#define 	INIT_DISPLAY 	0x38		; 0 0 1 DL=1 N=1 F=0 x x 	- function set, N - ustawienie 2 linii wyswietlacza
#define 	CLEAR_DISPLAY 	0x01 		; 0 0 0 0 0 0 0 1 			- czyszczenie ekranu - clear display
#define 	LCD_ON 			0x0f		; 0 0 0 0 1 D=1 C=1 B=1 	- display on/off

ORG 0

	lcall	lcd_init					; inicjowanie wyswietlacza

	mov		A, #04h						; x = 4, y = 0
	lcall	lcd_gotoxy					; przejscie do pozycji (4, 0)

	mov		DPTR, #text_hello			; wyswietlenie tekstu
	lcall	lcd_puts

	mov		A, #14h						; x = 4, y = 1
	lcall	lcd_gotoxy					; przejscie do pozycji (4, 1)

	mov		DPTR, #text_number			; wyswietlenie tekstu
	lcall	lcd_puts

	mov		A, #12						; wyswietlenie liczby
	lcall	lcd_dec_2

	sjmp	$

;=====================================================================

;---------------------------------------------------------------------
; Zapis komendy
;
; Wejscie: A - kod komendy
;---------------------------------------------------------------------
lcd_write_cmd:
	push	ACC					; przeniesienie kodu komendy na stos, aby nie stracic go w dalszych krokach
	mov		DPTR, #RD_STAT		; w rejestr DPTR przekazujemy informacje o statusie wyswietlacza
loop:							; petla odpowiada za sprawdzanie busy flag (BF), tak dlugo az nie zwróci 0 (wyswietlacz nie bedzie zajety)
	movx	A, @DPTR			
	jb		ACC.7, loop

	mov		DPTR, #WR_CMD		; w rejestr DPTR przekazujemy komorke z zapisem rejestru komend
	pop		ACC					; zabieramy ze stosu wczesniej odlozony kod komendy
	movx	@DPTR, A
	ret

;---------------------------------------------------------------------
; Zapis danych
;
; Wejscie: A - dane do zapisu
;---------------------------------------------------------------------
lcd_write_data:
	push	ACC					; przeniesienie danych do zapisu na stos, aby nie stracic ich w dalszych krokach
	mov		DPTR, #RD_STAT		; w rejestr DPTR przekazujemy informacje o statusie wyswietlacza
loop1:							; petla odpowiada za sprawdzanie busy flag (BF), tak dlugo az nie zwróci 0 (wyswietlacz nie bedzie zajety)
	movx	A, @DPTR
	jb		ACC.7, loop1

	mov		DPTR, #WR_DATA		; w rejestr DPTR przekazujemy komorke z zapisem rejestru danych
	pop		ACC					; zabieramy ze stosu wczesniej odlozone dane do zapisu
	movx	@DPTR, A
	ret

;---------------------------------------------------------------------
; Inicjowanie wyswietlacza
;---------------------------------------------------------------------
lcd_init:
	mov		A, #INIT_DISPLAY	; przekazanie informacji o N=1, czyli ustawieniu dwoch linii wyswietlacza
	lcall 	lcd_write_cmd
	
	mov		A, #CLEAR_DISPLAY	; czyszczenie ekranu
	lcall 	lcd_write_cmd
	
	mov		A, #LCD_ON			; wlaczenie wyswietlacza
	lcall 	lcd_write_cmd
	ret

;---------------------------------------------------------------------
; Ustawienie biezacej pozycji wyswietlania
;
; Wejscie: A - pozycja na wyswietlaczu: ---y | xxxx
;---------------------------------------------------------------------
lcd_gotoxy:
;	anl		A, #00011111b
;	jnb		ACC.4, wyslij
;	clr		ACC.4
; 	add		A, #40h
; wyslij:
;	orl		A, #80h				; operacja sprawi, ze w akumulatorze otrzymamy 1000 0000 lub 1100 0000
;	lcall 	lcd_write_cmd
 

	mov		R7, A				; odlozenie pozycji na wyswietlaczu do rejestru R7
	anl		A, #10h				; operacja sprawi, ze w akumulatorze otrzymamy 0000 0000 lub 0001 0000 zaleznie od poczatkowego y
	rl		A					; podwojne przesuniecie bitow w lewo, dzieki czemu wynikiem operacji bedzie 0000 0000 lub 0100 0000
	rl		A
	orl		A, #80h				; operacja sprawi, ze w akumulatorze otrzymamy 1000 0000 lub 1100 0000
								; dzieki powyzszym operacjom mamy ustawiona docelowa informacja na temat wiersza do wyswietlenia 
	mov		R6, A				
	mov		A, R7				; ponowne wziecie poczatkowej pozycji na wyswietlaczu do akumulatora
	anl		A, #0Fh				; wyzerowanie czterech starszych bitow 
	orl		A, R6				; stworzenie reprezentacji skladajacej sie z wczesniej zmienionych 4 starszych bitow oraz niezmienionych 4 mlodszych bitow
	lcall 	lcd_write_cmd
	ret

;---------------------------------------------------------------------
; Wyswietlenie tekstu od biezacej pozycji
;
; Wejscie: DPTR - adres pierwszego znaku tekstu w pamieci kodu
;---------------------------------------------------------------------
lcd_puts:				
	clr		A
	movc	A, @A+DPTR			; pobranie znaku tekstu na ktory wskazuje DPTR
	jz		koniec				; sprawdzenie czy jest zerem (czy napis nie jest zakonczony)
	push	DPL
	push	DPH
	lcall	lcd_write_data		; wyslanie danych o znaku do sterownika
	pop		DPH
	pop		DPL
	inc 	DPTR				; przejscie do kolejnego znaku napisu
	sjmp 	lcd_puts
koniec:
	ret

;---------------------------------------------------------------------
; Wyswietlenie liczby dziesietnej
;
; Wejscie: A - liczba do wyswietlenia (00 ... 99)
;---------------------------------------------------------------------
lcd_dec_2:
	mov		B, #10				; wstawienie do rejestru B dzielnika (liczby 10)
	div		AB					; dzielenie zawartosci akumulatora przez zawartosc rejestru B
	add		A, #'0'				; w akumulatorze znajduje sie wynik dzielenia, dodajemy do niego '0' dzieki czemu przeksztalcamy go na kod ascii
	lcall	lcd_write_data

	mov 	A, B				; przenosimy reszte z dzielenia do akumulatora
	add		A, #'0'				; konwertujemy reszte z dzielenia na kod ascii
	lcall	lcd_write_data
	ret

;---------------------------------------------------------------------
; Definiowanie wlasnego znaku
;
; Wejscie: A    - kod znaku (0 ... 7)
;          DPTR	- adres tabeli opisu znaku w pamieci kodu
;---------------------------------------------------------------------
lcd_def_char:

	ret

text_hello:
	db	'Hello word', 0
text_number:
	db	'Number = ', 0

END