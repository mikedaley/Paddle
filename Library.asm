;****************************************************************************************************************
;
; This assmebly file contains library routines that could be re-used in other projects such as sprite drawing or
; pixel address calculation
;
;****************************************************************************************************************

;****************************************************************************************************************
; Calculate the screen address of a pixel location
;
; Entry Registers:
;   D = X pixel location
;   E = Y pixel location
; Used Registers:
;   A, D, E, H, L
; Returned Registers:
;   HL = screen address
;****************************************************************************************************************
getPixelAddr:
            ld      a,e                                 ; Load A with the Y pixel location
            srl     a                                   ; Rotate A three time to the left
            srl     a
            srl     a
            and     24                                  ; 
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
            ld      l,a                 
            ret

;****************************************************************************************************************
; Calculate the screen address which is one row lower than the HL address passed in
;
; Entry Registers:
;   HL = screen address
; Used Registers:
;   A, H, L
; Returned Registers:
;   HL = screen address
;****************************************************************************************************************
moveLineDown   
            inc     h
            ld      a,h
            and     7
            ret     nz
            ld      a,l
            add     a,32
            ld      l,a
            ret     c
            ld      a,h
            sub     8
            ld      h,a                 
            ret

;****************************************************************************************************************
; Preshift sprite data
; Uses source sprite data to create 7 pre-shifted versions
;
; Entry Registers:
;   HL = Sprite source Addr
;   DE = First shift sprite Addr
;   B = Pixels wide
;   C = Pixel high
; Registers Used:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
prShft
                ld      a, b
                ld      (prShftWdth), a             ; Save width
                ld      a, c
                ld      (prShftHght), a             ; Save height
                ld      c, 7                        ; Load B with the number of shifts to perform

_prNxtShft
                ld      a, (prShftHght)             ; Load the height of the sprite to be shifted
                ld      b, a                        ; Save that in B
_prShftY                
                push    bc                          ; Save B onto the stack
                ld      a, (prShftWdth)             ; Load A with the width of the sprite
                ld      b, a                        ; Load A into B
                xor     a                           ; Clear A and flags ready to shift the sprite bytes right
_prShftX
                ld      a, (hl)                     ; Load the first sprite byte into A
                rra                                 ; Rotate right with the carry bit
                ld      (de), a                     ; Save the rotated byte into the shift sprite location
                inc     hl                          ; Move to the next source byte
                inc     de                          ; Move to the next destination byte
                djnz    _prShftX                    ; If there are still width bytes to shift then go shift them

                pop     bc                          ; Restore B which holds the pixel height of the sprite
                djnz    _prShftY                    ; If there is another pixel row to process then go do it

                dec     c                           ; Decrement the number of sprites to generate
                jr      nz, _prNxtShft              ; If we are not yet at zero then process another sprite shift...

                ret                                 ; ...otherwise we are done

;****************************************************************************************************************
; Draws a sprite on screen. The sprite can be any size as defined in the first two bytes of sprite data which holds
; the sprite width in bytes and height in pixels.
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
;   BC = Pixel location B = X, C = Y
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwSprt
                ld      a, (de)                     ; Grab the sprite width...
                ld      (_sprtWdth + 1), a          ; ...and save it for use later in the routine
                inc     de                          ; Move DE to the sprite height
                ld      a, (de)                     ; Grab the sprite height...
                ld      (_sprtHght + 1), a          ; ...and save it for use later in the routine
                inc     de                          ; Move DE to the sprite lookup table

                ld      a, b                        ; Get the Bit rotate count (lower 3 bits of X position)
                and     7   
        
                ; Load DE with the address of the sprite we need to use based on the x location offset in memory
                ld      l, a                        ; Load A with the number of shifts needed
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the lookup table entries are words
                add     hl, de                      ; Add base address of sprite table which is held in DE
                ld      e, (hl)                     ; Load E with the contents of (HL)
                inc     hl                          ; Move HL to the next byte of address in the table
                ld      d, (hl)                     ; Load D with the high byte

                ; Work out the X offset for the screen memory address
                ld      a, b                        ; Work out the X Offset using the shift value
                rra
                rra
                rra
                and     31
                ld      (_xOffst + 1), a            ; Save the x Offset for use later in the routine

                ; Load IX with the first address of the y-axis lookup table
                ld      b, 0                        ; Clear B
                ld      ix, scrnLnLkup              ; Load IY with the lookup table address
                add     ix, bc                      ; Increment IX by the Y pixel position
                add     ix, bc                      ; twice as the table contains word values

_sprtHght       ld      b, 0                        ; The value is overwritten by values at the start of this routine

_drwRw
                ld      a, (ix + 0)                 ; Get the current line
_xOffst         or      0                           ; Merge in our X Offset set earlier in the routine
                ld      l, a                        ; Load the merged low byte in L
                ld      h, (ix + 1)                 ; Get the high byte from the lookup table
                inc     ix  
                inc     ix                          ; Move to the next line which is a word away

                push    bc                          ; Save B as we will load it into the sprite width
_sprtWdth       ld      b, 0                        ; Load B with the width (bytes) of the sprite set earlier in the routine

_drwClmn    
                ld      a, (de)                     ; Load A with a byte of sprite data
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next screen location
                djnz    _drwClmn                    ; Draw another column if needed
                pop     bc                          ; Restore the number of rows left to draw
                djnz    _drwRw                      ; Draw another row if needed

                ret                                 ; All done

;****************************************************************************************************************
; Draw 24x8 pixel sprite using interleaved mask data. The first row of sprite data is the mask, the next row is
; sprite data and so on.
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
;   BC = Pixel location B = X, C = Y
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwMskd24x8Sprt      
                ld      a, b                        ; Get the Bit rotate count (lower 3 bits of X position)
                and     7   
        
                ; Load DE with the address of the sprite we need to use based on the x location offset in memory
                ld      l, a                        ; Load A with the number of shifts needed
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the lookup table entries are words
                add     hl, de                      ; Add base address of sprite table which is held in DE
                ld      e, (hl)                     ; Load E with the contents of (HL)
                inc     hl                          ; Move HL to the next byte of address in the table
                ld      d, (hl)                     ; Load D with the high byte

                ; Work out the X offset for the screen memory address
                ld      a, b                        ; Work out the X Offset using the shift value
                rra
                rra
                rra
                and     31
                ld      b, a                        ; Store the X Byte Offset
                push    bc

                ; Load IX with the first address of the y-axis lookup table
                ld      b, 0                        ; Clear B
                ld      ix, scrnLnLkup              ; Load IY with the lookup table address
                add     ix, bc                      ; Increment IX by the Y pixel position
                add     ix, bc                      ; twice as the table contains word values
                pop     bc                          ; Restore B which holds the X byte offset

    REPT 8                                          ; Repeat this code 8 times for the 8 pixles rows of a ball sprite
                ld      a, (ix + 0)                 ; Get the current line
                or      b                           ; Merge in our X Offset
                ld      l, a                        ; Load the merged low byte in L
                ld      h, (ix + 1)                 ; Get the high byte from the lookup table
                inc     ix  
                inc     ix                          ; Move to the next line which is a word away
    
                ld      a, (de)
                inc     de
                or     (hl)
                ld      (hl), a
                inc     l

                ld      a, (de)
                inc     de
                or     (hl)
                ld      (hl), a
                dec     l

                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                and     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                and     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM               
                ret                                 ; All done! 

;****************************************************************************************************************
; Save the 16x8 screen data at the pixel location in BC and save the data to the location in DE
;
; Entry Registers:
;   BC = Pixel location B = X, C = Y
;   DE = Pointer to where the data should be copied
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
sve16x8
                push    de                          
                ld      d, b
                ld      e, c
                call    getPixelAddr
                pop     de

    REPT 8                                         
                ld      a, (hl)
                ld      (de), a
                inc     de    
                inc     l

                ld      a, (hl)
                ld      (de), a
                inc     de
                dec     l
                call    moveLineDown
    ENDM               
                ret                                 ; All done! 

;****************************************************************************************************************
; Draw 16x8 screen data at the pixel location in BC and from the address DE
;
; Entry Registers:
;   BC = Pixel location B = X, C = Y
;   DE = Pointer to where the data should be read from
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
rstr16x8
                push    de
                ld      d, b
                ld      e, c
                call    getPixelAddr
                pop     de

    REPT 8                                          
                ld      a, (de)
                ld      (hl), a
                inc     de    
                inc     l

                ld      a, (de)
                ld      (hl), a
                inc     de
                dec     l
                call    moveLineDown
    ENDM               
                ret                                 ; All done! 

;****************************************************************************************************************
; Print a string to the screen at pixel coordinates held in DE. This routine does not deal with crossing of
; screen segments
;
; Entry Registers:
;   BC = Pointer to the string to be printed. String to be terminated with 0x00
;   DE = X, Y pixel location to print the string
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
prntStrng
                call    getPixelAddr                ; Get the screen address of the pixel location into HL                
_chrLp1          
                ld      a, (bc)                     ; Read character from string
                or      a                           ; Check to see if the character is 0x00...
                ret     z                           ; ...and if so return as we're finished
                inc     bc                          ; Move to the next character in the string
                cp      0x20                        ; Compare the character to the space character
                jr      nz, _ntSpc                  ; If not a space then process the character
                inc     l                           ; Move one character space to the right on screen...
                jr      _chrLp1                     ; Deal with the next character
_ntSpc
                push    bc                          ; Save BC as it holds the string pointer
                push    hl
                sub     48                          ; Sub the ASCII value for 0...
                cp      10                          ; ...and compare against 10
                jr      c, _ntAlph                  ; If Carry then this is a number
                sub     65-48-10                    ; Otherwise adjust the index for an alpha
_ntAlph
                sla     a                           ; Multiply A by 8...
                sla     a                           ; ... to get the index...
                sla     a                           ; ...into the font data
                ld      l, a                        ; Place A into L...
                ld      h, 0                        ; ...and reset H
                ld      bc, NumberFont              ; Point BC to the start of our font data
                add     hl, bc                      ; Add in the index we calculated to the character we want 
                ex      de, hl                      ; Exchange DE, HL as we want DE to contain the font pointer

                pop     hl                          ; Restore HL which is our screen address
                push    hl
                ld      b, 8                        ; The font is 8 pixels high
_chrLp2
                ld      a, (de)                     ; Load A with a byte of font data
                ld      (hl), a                     ; Place that Font data on screen
                inc     de                          ; Move to the next byte of font data
                inc     h                           ; Move to the next screen row
                djnz    _chrLp2                     ; Draw the next row of the character
                pop     hl                          ; Restore HL which holds the screen address
                inc     l                           ; Move to the next character position along the screen
                pop     bc                          ; Restore BC which holds the string pointer
                jr      _chrLp1                     ; Go back to check for the next character






                