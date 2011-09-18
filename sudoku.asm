section .data
	sudoku times 9*9 dd 0	; el sudoku
	nums_disp times 81*9 dd 1 ; nums disponibles por c/casilla
	cuant_disp times 9*9 dd 9 ; cuantos disponibles hay por casilla
	cuadro1 dd 0,1,2,9,10,11,18,19,20 ; posiciones de los cuadros
	cuadro2 dd 3,4,5,12,13,14,21,22,23
	cuadro3 dd 6,7,8,15,16,17,24,25,26
	cuadro4 dd 27,28,29,36,37,38,45,46,47
	cuadro5 dd 30,31,32,39,40,41,48,49,50
	cuadro6 dd 33,34,35,42,43,44,51,52,53
	cuadro7 dd 54,55,56,63,64,65,72,73,74
	cuadro8 dd 57,58,59,66,67,68,75,76,77
	cuadro9 dd 60,61,62,69,70,71,78,79,80
	i dd 0			; contador i (filas)
	j dd 0			; contador j (columnas)
	endl dd 0xa		; fin de linea
	msg1 db 0xa, "Opciones:",0xa
	msg2 db "1 -> Generar 1 sudoku aleatorio.", 0xa
	msg3 db "2 -> Generar 1 sudoku con secuencia predefinida.", 0xa
	msg4 db "3 -> Generar 100 sudokus aleatorios.", 0xa
	msg5 db "4 -> Generar 100 sudokus con secuencia predefinida.", 0xa
	msgLen equ $-msg1

	secuencia times 10 db 3,4,1,7,4,3,2,1

	arch1 db "mnuOpcion1.txt",0
	arch2 db "mnuOpcion2.txt",0
	arch3 db "mnuOpcion3.txt",0
	arch4 db "mnuOpcion4.txt",0
	
section .bss
	rnd resd 1		; random
	c resd 1		; valor a asignar
	conf resd 1		; conflicto?
	op resd 1		; define modo, con o sin secuencia
	pos_rnd resd 1		; posicion en la secuencia random

	arch_desc resd 1	; archivo a escribir

section .text
	global main

main:
	pop eax
	pop eax
	cmp eax, 2		; debe habar 1 argumento real
	jne print_msg		; imprime opciones

	pop eax
	mov ebx, [eax+4]
	mov eax, [ebx]		; compara argumento ingresado
	cmp al, 0x31
	je gen_1sudoku
	cmp al, 0x32
	je gen_1sudoku_pred
	cmp al, 0x33
	je gen_100sudokus
	cmp al, 0x34
	je gen_100sudokus_pred
	jmp print_msg

	;; genera un sudoku aleatorio
gen_1sudoku:	
	mov dword [op], 0
	mov eax, 8
	mov ebx, arch1
	mov ecx, 00644Q
	int 0x80
	mov [arch_desc], eax
	mov edx, 1		; 1 sudoku
	jmp gen_sudokus

	;; genera un sudoku con secuencia predefinida
gen_1sudoku_pred:
	mov dword [op], 1
	mov dword [pos_rnd], 0
	mov eax, 8
	mov ebx, arch2
	mov ecx, 00644Q
	int 0x80
	mov [arch_desc], eax
	mov edx, 1		; 1 sudoku
	jmp gen_sudokus

	;; genera 100 sudokus aleatorios
gen_100sudokus:	
	mov dword [op], 0
	mov eax, 8
	mov ebx, arch3
	mov ecx, 00644Q
	int 0x80
	mov [arch_desc], eax
	mov edx, 100		; 100 sudoku
	jmp gen_sudokus

	;; genera 100 sudokus con secuencia predefinida
gen_100sudokus_pred:
	mov dword [op], 1
	mov dword [pos_rnd], 0
	mov eax, 8
	mov ebx, arch4
	mov ecx, 00644Q
	int 0x80
	mov [arch_desc], eax
	mov edx, 100		; 100 sudokus
	jmp gen_sudokus
	
gen_sudokus:	
	mov ecx, 0		; contador = 0
ciclo_sudokus:
	cmp ecx, edx		; contador < numero de sudokus a imprimir
	je fin
	push edx
	push ecx
	push ecx
	call print
	pop ecx
	call println
	call generar_sudoku	; genera sudoku
	pop ecx
	pop edx
	call println
	inc ecx			; contador ++
	jmp ciclo_sudokus
generar_sudoku:
	push ebp
	mov ebp, esp
	mov edx, 0		; contador nums disponibles por casilla
	mov edi, 0		; contador posiciones
	mov dword [i], 0	; i = 0
ciclo1:
	cmp dword [i], 9	; i < 9?
	je fin_ciclo1	
	mov dword [j], 0	; j = 0
ciclo2:
	cmp dword [j], 9	; j < 9?
	je fin_ciclo2

	cmp dword [cuant_disp+4*edi], 0 ; cuant_disp[i][j] != 0?
	je else_ciclo2

	call gen_random		; genera el random en rnd
	
	mov eax, [rnd]
	push eax
	call get_num_disp	; obtiene sig numero disponible
	pop eax
                                           	
	mov esi, [c]
	dec esi
	add esi, edx
	mov dword [nums_disp+4*esi], 0 ; numero obtenido no esta disponible ya
	dec dword [cuant_disp+4*edi]   ; hay menos numeros disponibles

	mov eax, [i]		; parametros i, j, c para genera conflicto
	push eax
	mov eax, [j]
	push eax
	mov eax, [c]
	push eax
	call gen_conflicto
	pop eax
	pop eax
	pop eax
	
	cmp dword [conf], 1	; hay conflicto?
	je ciclo2
	mov eax, [c]
	mov dword [sudoku+4*edi], eax ; sudoku[i][j] = c

	inc dword [j]		; j++
	inc edi			; avanza casilla
	add edx, 9
	jmp ciclo2

else_ciclo2:
	mov esi, edx
	mov ecx, 0
ciclo_reset:			; resetea contenidos para hacer backtracking
	cmp ecx, 9
	je fin_ciclo_reset
	mov dword[nums_disp+4*esi], 1
	inc esi
	inc ecx
	jmp ciclo_reset
fin_ciclo_reset:	
	mov dword [cuant_disp+4*edi], 9
	mov byte [sudoku+4*edi], 0
	sub edx, 9
	dec edi			; retrocede casilla
	cmp dword [j], 0	; j == 0?
	je subir_fila
	dec dword [j]		; j--
	jmp ciclo2
subir_fila:	
	mov dword [j], 8	; j = 8
	dec dword [i]		; i = 0
	jmp ciclo2
fin_ciclo2:
	inc dword [i]
	jmp ciclo1
fin_ciclo1:
	call print_sudoku	; imprime el sudoku
	call reset		; resetea contenidos
	pop ebp
	ret
fin:
	mov eax, 1
	mov ebx, 0
	int 0x80		; fin del programa

	;; genera un numero aleatorio entre 0-8
gen_random:
	cmp dword [op], 0	; secuencia predefinida?
	je no_pred
	mov esi, [pos_rnd]
	mov al, [secuencia+esi]
	mov byte [rnd], al	; obtiene sig random en rnd
	cmp dword [pos_rnd], 79
	je re_pos_rnd
	inc dword [pos_rnd]	; pasa a sig posicion rnd
	ret
re_pos_rnd:
	mov dword [pos_rnd], 0
	ret
no_pred:	
	push edx
	rdtsc			; obtiene ciclos de reloj en eax (semilla aleatoria)
	mov edx, 0
	mov ebx, eax
	mov eax, 0
	mov al, bl
	mov ebx, [cuant_disp+4*edi]
	div bl 
	mov byte [rnd], ah	; obtiene modulo y lo almacena en rnd
	pop edx
	ret

	;; obtiene siguiene numero disponible
	;; recibe de parametro el random generado
get_num_disp:
	push ebp
	mov ebp, esp
	inc dword [ebp+8]
	mov esi, edx		; contador numeros disponibles casilla actual
ciclo_num_disp:
	cmp dword [ebp+8], 0
	je fin_num_disp
	cmp dword [nums_disp+4*esi], 1 ; esta disponible?
	jne no_disp
	dec dword [ebp+8]	; rnd--
no_disp:
	inc esi			; contador++
	jmp ciclo_num_disp
fin_num_disp:
	sub esi, edx
	mov [c], esi		; retorna el sig numero disponible en c
	pop ebp
	ret

	;; establece si un numero c genera conflicto en fila i columna j
	;; recibe estos valores como parametros
gen_conflicto:
	push ebp
	mov ebp, esp
	push edx
	mov eax, [ebp+16]
	mov ebx, 9
	mul ebx
	mov edx, 0
	mov esi, eax
	mov eax, [ebp+8]
ciclo_filas:			; verifica conflicto en fila i
	cmp esi, edi
	je verificar_columnas

	cmp dword [sudoku+4*esi], eax
	je conflicto
	inc esi
	jmp ciclo_filas

verificar_columnas:		; verifica conflicto en columna j
	mov esi, [ebp+12]
ciclo_columnas:
	cmp esi, edi
	je verificar_cuadros

	cmp [sudoku+4*esi], eax
	je conflicto
	add esi, 9
	jmp ciclo_columnas

verificar_cuadros:		; verifica conflicto en cuadro 3x3 correspondiente
	mov eax, [ebp+16]
	mov ebx, 3
	div ebx
	mul ebx
	
	mov ecx, eax

	mov eax, [ebp+12]
	div ebx

	add eax, ecx		; eax = (int)(i/3)*3+(int)(j/3) -> cuadro correspondiente

	mov ebx, 9
	mul ebx
	
	lea ebx, [cuadro1+4*eax]
	mov esi, [ebx]

	mov eax, [ebp+8]
	mov ecx, 0
ciclo_cuadros:
	cmp esi, edi
	je fin_cuadros
	cmp [sudoku+4*esi], eax
	je conflicto
	add ebx, 4
	mov esi, [ebx]
	inc ecx
	jmp ciclo_cuadros
fin_cuadros:	
	mov dword [conf], 0	; no hay conflicto
	jmp fin_gen_conflicto
conflicto:
	mov dword [conf], 1	; hay conflicto
fin_gen_conflicto:
	pop edx
	pop ebp
	ret

	;; imprime el sudoku generado
print_sudoku:
	push ecx
	push edx
	mov esi, 0
	mov ecx, 0
ciclo_print1:
	cmp ecx, 9
	je fin_ciclo_print1
	mov edx, 0
ciclo_print2:
	cmp edx, 9
	je fin_ciclo_print2

	mov eax, [sudoku+4*esi]
	push eax
	call print
	pop eax
	
	inc esi
	inc edx
	jmp ciclo_print2
fin_ciclo_print2:
	inc  ecx

	call println
	
	jmp ciclo_print1
fin_ciclo_print1:	
	pop edx
	pop ecx
	ret

	;; imprime fin de linea
println:
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edx
	mov eax, 4
	mov ebx, [arch_desc]
	mov ecx, endl
	mov edx, 1
	int 0x80
	pop edx
	pop ecx
	pop ebx
	pop eax	
	pop ebp
	ret

	;; imprime un digito adicionando el ascii correspondiente
print:
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edx
	mov eax, 4
	mov ebx, [arch_desc]
	lea ecx, [ebp+8]
	add dword [ecx], 0x30
	mov edx, 1
	int 0x80
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret

	;; reinica los contenidos para generar nueva matriz
reset:
	push ebp
	mov ebp, esp
	mov ecx, 0
ciclo_reset1:
	cmp ecx, 81
	je fin_ciclo_reset1
	mov dword [sudoku+4*ecx], 0
	mov dword [cuant_disp+4*ecx], 9
	inc ecx
	jmp ciclo_reset1
fin_ciclo_reset1:
	mov ecx, 0
ciclo_reset2:
	cmp ecx, 729
	je fin_ciclo_reset2
	mov dword [nums_disp+4*ecx], 1
	inc ecx
	jmp ciclo_reset2
fin_ciclo_reset2:
	pop ebp
	ret

	;; imprime opciones de ejecucion del programa
print_msg:
	mov eax, 4
	mov ebx, 1
	mov ecx, msg1
	mov edx, msgLen
	int 0x80
	call println
	jmp fin

