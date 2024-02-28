ORG 0

	sjmp	test_sum_iram	; przyklad testu wybranej procedury

test_sum_iram:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	sum_iram
	sjmp	$

test_copy_iram_iram_inv:
	mov	R0, #30h	; adres poczatkowy obszaru zrodlowego
	mov	R1, #40h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_iram_iram_inv
	sjmp	$

test_copy_xram_iram_z:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #30h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_iram_z
	sjmp	$

test_copy_xram_xram:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #LOW(8010h)	; adres poczatkowy obszaru docelowego
	mov	R1, #HIGH(8010h)
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_xram
	sjmp	$

test_count_even_gt10:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	count_even_gt10
	sjmp	$

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci wewnetrznej (IRAM)
;
; Wejscie: R0    - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_iram:
	mov R6, #0
	mov R7, #0
	mov A, R2
	jz koniec1
	
dodawanie1:
			mov A, @R0
			add A, R6
			mov R6, A
			jnc zerowe_przeniesienie
			inc R7
			
	zerowe_przeniesienie:
			inc R0
			djnz R2, dodawanie1
			
koniec1:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci wewnetrznej (IRAM) z odwroceniem
;
; Wejscie: R0 - adres poczatkowy obszaru zrodlowego
;          R1 - adres poczatkowy obszaru docelowego
;          R2 - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_iram_iram_inv:
	mov A, R2
	jz koniec2
	
	mov A, R1
	add A, R2
	mov R1, A
	
kopiowanie2:
			dec R1
			mov A, @R0
			mov @R1, A
			inc R0
			djnz R2, kopiowanie2
			
koniec2:    
			
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinny byc pominiete elementy zerowe
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_z:
	mov A, R2
	jz koniec3
	
kopiowanie3:
			movx A, @DPTR
			jz element_zero
			mov @R0, A
			inc R0
	
element_zero:
			inc DPTR
			djnz R2, kopiowanie3
	
koniec3:
			
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci zewnetrznej (XRAM -> XRAM)
;
; Wejscie: DPTR  - adres poczatkowy obszaru zrodlowego
;          R1|R0 - adres poczatkowy obszaru docelowego
;          R2    - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_xram:
	mov A, R2
	jz koniec4
	
kopiowanie4:
			movx A, @DPTR

			mov R7, DPH				;starsza czesc adresu DPTR
			mov R6, DPL				;mlodsza czesc adresu DPTR
			mov DPH, R1
			mov DPL, R0

			movx @DPTR, A
			inc DPTR

			mov R1, DPH
			mov R0, DPL
			mov DPH, R7
			mov DPL, R6

			inc DPTR
			djnz R2, kopiowanie4
	
koniec4:
			
	ret

;---------------------------------------------------------------------
; Zliczanie w bloku danych w pamieci wewnetrznej (IRAM)
; liczb parzystych wiekszych niz 10
;
; Wejscie: R0 - adres poczatkowy bloku danych
;          R2 - dlugosc bloku danych
; Wyjscie: A  - liczba elementow spelniajacych warunek
;---------------------------------------------------------------------
count_even_gt10:
	mov R6, #0						;R6 przechowuje liczbe elementow spelniajacych warunek
	mov A, R2
	jz koniec5
	
	policz:
			mov A, @R0
			cjne A, #11, warunek
	warunek:
			jc niespelnia
			jb ACC.0, niespelnia
			inc R6
	niespelnia:
			inc R0
			djnz R2, policz
			mov A, R6
	koniec5:
	
	ret

END