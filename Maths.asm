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
                add hl, hl    
                rla           
                cp c
                jr c, $+4
                sub c
                inc l
    ENDM             
                ret

;                 ld      a, c
;                 ld      d, a
;                 ld      e, 0
;                 ld      b, 8
; _div            xor     a
;                 sbc     hl, de
;                 inc     hl
;                 jp      p, _noAdd
;                 add     hl, de
;                 dec     hl
; _noAdd          add     hl, hl
;                 djnz    _div
;                 ret