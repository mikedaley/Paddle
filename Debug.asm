;****************************************************************************************************************
; Print out a hex Byte or Word. HL = Screen address and BC = Word / A = Byte
; This is simple and does not handle crossing screen segments, so make sure that the Y location of the debug
; print does not cause a character to cross a screen segment
;****************************************************************************************************************

HexWord:    ld      a,b                                 ; Load A with the first byte of the Word
            ex      af,af'                              ; Switch AF with AF'
            ld      a,c                                 ; Load a with the second byte of the word
            call    HexByte                             ; Deal with the first byte of the word
            ex      af,af'                              ; Switch AF' to AF

HexByte:    ld      c,a                                 ; Store A in C
            call    HexDigit                            ; Print the hex digit in c
            ld      a,c                                 ; Restore A
            sra     a                                   ; This is the second...                       
            sra     a                                   ; ...character of the hex
            sra     a                                   ; ...byte so shift it right 4 times
            sra     a                                   ; ...so we are left with the left nibble

HexDigit:   and     15                                  ;
            push    hl                                  ; Save HL
            push    hl                                  ; Save HL again so we can restore it easily later

            rl      a                                   ; Multiple the value...    
            rl      a                                   ; ...in A by 8 to give...
            rl      a                                   ; ...us the offset into the font data
            ld      l,a                                 ; Load the offset into L...
            ld      h,0                                 ; ...and zero H

            ld      de, NumberFont                      ; Put the location of the number font data into DE...
            add     hl,de                               ; ...and add in the offset for the number we are dealing with
            pop     de                                  ; Restore HL into DE

            ld      b,8                                 ; The font is 8 pixels high
HexLoop:
            ld      a,(hl)                              ; Load A with the first byte of the font character data
            ld      (de),a                              ; Save A into the screen location in DE
            inc     hl                                  ; Move HL to the next byte of font character data
            inc     d                                   ; Increment to the next screen row address
            djnz    HexLoop                             ; Draw the next row of the character

            pop     hl                                  ; Restore HL with the original HL screen address
            dec     l                                   ; Move HL to the next character to the LEFT 
            ret

;****************************************************************************************************************
; Prints out the binary representation of A at screen address HL
;****************************************************************************************************************
BinByte:
            ld      b,8                                 ; 8 bits to be drawn
BinLoop:
            ld      c,a                                 ; Load A into C for processing
            and     1                                   ; Clear all the bits but the LSB
            push    bc                                  ; Save BC as C contains the byte we are processing
            call    HexDigit                            ; Print the current bit value using HexDigit
            pop     bc                                  ; Restore BC
            ld      a,c                                 ; Load C back into A
            rrca                                        ; Rotate A right ready to process the LSB
            djnz    BinLoop                             ; Loop while B > 0
            ret

;****************************************************************************************************************
; Return the screen address in HL for the pixel location provided in DE
;****************************************************************************************************************
Pixaddr:
            ld      a,e
            srl     a
            srl     a
            srl     a
            and     24
            or      64

            ld      h,a
            ld      a,e
            and     7
            or      h
            ld      h,a

            ld      a,e
            add     a,a
            add     a,a
            and     224
            ld      l,a

            ld      a,d
            srl     a
            srl     a
            srl     a
            or      l
            ld      l,a                 ; HL now contains the screen address
            ret