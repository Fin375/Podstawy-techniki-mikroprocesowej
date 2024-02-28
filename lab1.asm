ORG 0

	sjmp	test_swap_regs
;---------------------------------------------------------------------
; Test procedury - wywolanie w petli
;---------------------------------------------------------------------
test_dec_iram:
	mov	R0, #30h				; liczba w komorkach IRAM 30h i 31h
	lcall	dec_iram			; wywolanie procedury
	sjmp	test_dec_iram		; petla

;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
test_inc_xram:
	mov	DPTR, #8000h			; liczba w komorkach XRAM 8000h i 8001h
	lcall	inc_xram			; wywolanie procedury
	sjmp	test_inc_xram		; powtarzanie

;=====================================================================
test_add_xram:
	mov	DPTR, #8000h			; liczba w komorkach XRAM 8000h i 8001h
	lcall	add_xram			; wywolanie procedury
	sjmp	test_add_xram		; powtarzanie
;=====================================================================
test_sub_iram:
	mov	R0, #30h				; liczba w komorkach IRAM 30h i 31h
	mov R1,	#40h
	lcall	sub_iram			; wywolanie procedury
	sjmp	test_sub_iram		; petla
;---------------------------------------------------------------------
test_set_bits:
	mov	R7,#30h
	mov R6,#40h				; liczba w komorkach IRAM 30h i 31h
	lcall	set_bits			; wywolanie procedury
	sjmp	test_set_bits		; petla
;---------------------------------------------------------------------
test_shift_left:
	mov R6,#24h
	mov R7,#63h			; liczba w komorkach XRAM 8000h i 8001h
	lcall	shift_left			; wywolanie procedury
	sjmp	test_shift_left		; powtarzanie
;---------------------------------------------------------------------
test_get_code_const:
	mov R6,#11h
	mov R7,#43h	
	mov DPTR,#code_const
	lcall	get_code_const			; wywolanie procedury
	sjmp	test_get_code_const		; powtarzanie

;=====================================================================
test_swap_regs:
	mov	DPTR, #5678h
	mov R7,#14h			; liczba w komorkach XRAM 8000h i 8001h
	mov R6,#18h
	mov A,#14h
	lcall	swap_regs			; wywolanie procedury
	sjmp	test_swap_regs		; powtarzanie

;=====================================================================


;---------------------------------------------------------------------
; Dekrementacja liczby dwubajtowej w pamieci wewnetrznej (IRAM)
; R0 - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
dec_iram:
	mov		A, @R0
	clr		C
	subb	A, #1
	mov		@R0, A

	inc		R0
	mov		A, @R0
	subb	A, #0
	mov		@R0, A

	ret

;---------------------------------------------------------------------
; Inkrementacja liczby dwubajtowej w pamieci zewnetrznej (XRAM)
; DPTR - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
inc_xram:
	movx A,@DPTR
	add A,#1
	movx @DPTR,A

	inc DPTR
	movx A,@DPTR
	addc A,#0
	movx @DPTR,A

	ret

;---------------------------------------------------------------------
; Odjecie liczb dwubajtowych w pamieci wewnetrznej (IRAM)
; R0 - adres mlodszego bajtu (Lo) odjemnej A oraz roznicy (A <- A - B)
; R1 - adres mlodszego bajtu (Lo) odjemnika B
;---------------------------------------------------------------------
sub_iram:
	mov A,@R0
	clr C
	subb A,@R1
	mov @R0,A
	inc R0
	inc R1
	mov A,@R0
	subb A,@R1
	mov @R0,A

	ret

;---------------------------------------------------------------------
; Ustawienie bitow parzystych (0,2, ..., 14) w liczbie dwubajtowej
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
set_bits:
	mov A,R7
	orl A,#01010101b
	mov R7,A

	mov A,R6
	orl A,#01010101b
	mov R6,A

	ret

;---------------------------------------------------------------------
; Przesuniecie w lewo liczby dwubajtowej (mnozenie przez 2)
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
shift_left:
	mov A,R6
	clr C
	rlc A
	mov R6,A
	mov A,R7
	rlc A
	mov R7,A


	ret

;---------------------------------------------------------------------
; Pobranie liczby dwubajtowej z pamieci kodu
; Wejscie: DPTR  - adres mlodszego bajtu (Lo) liczby w pamieci kodu
; Wyjscie: R7|R6 - pobrane dane
;---------------------------------------------------------------------
get_code_const:
	movx A,@DPTR
	mov R6,A

	inc DPTR
	movx A,@DPTR
	mov R7,A

	ret

;---------------------------------------------------------------------
; Zamiana wartosci rejestrow DPTR i R7|R6
; Nie niszczy innych rejestrow
;---------------------------------------------------------------------
swap_regs:
	push ACC
	mov A,DPH
	xch A,R7
	mov DPH,A
	mov A,DPL
	xch A,R6
	mov DPL,A
	pop ACC

	ret

;---------------------------------------------------------------------
; Dodanie 10 do danych w obszarze pamieci zewnetrznej (XRAM)
; DPTR - adres poczatku obszaru
; R2   - dlugosc obszaru
;---------------------------------------------------------------------
add_xram:
	movx A,@DPTR
	add A,#10
	movx @DPTR,A
	inc DPTR
	djnz R2,add_xram
	ret

;---------------------------------------------------------------------
code_const:
	DB	LOW(1234h)
	DB	HIGH(1234h)

END