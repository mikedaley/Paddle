;****************************************************************************************************************
; Devides the number in HL (Dividend) by the number in C (Divisor). It returns HL as the result of HL/C with the remainder in A
;
; Entry Registers:
;   HL = Dividend
;   C = Divisor
; Used Registers:
;   A, C, HL
; Returned Registers:
;   HL = Quotient
;   A = Remainder
;****************************************************************************************************************
dvd_HL_C
                xor a                               ; Clear A     
    REPT 16
                add     hl, hl    
                rla           
                cp      c
                jr      c, $ + 4
                sub     c
                inc     l
    ENDM             
                ret

;****************************************************************************************************************
; Multiplies the unsigned number in H (Multiplier) with the unsigned number in E (Multipland)
;
; Entry Registers:
;   H = Multiplier
;   E = Multipland
; Used Registers:
;   A, C, HL
; Returned Registers:
;   HL = Result
;****************************************************************************************************************
mult_H_E
                sla     h       ; optimised 1st iteration
                jr      nc, $ + 3
                ld      l, e
    REPT 7
                add     hl, hl       ; unroll 7 times
                jr      nc, $ + 3      ; ...
                add     hl, de       ; ...
    ENDM
                ret