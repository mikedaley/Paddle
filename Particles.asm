;****************************************************************************************************************
; Generate three particles from the particle pool using the location passed in BC
;****************************************************************************************************************
genPrtcl
                inc     b                           ; Move to the center of the block
                inc     b
                inc     b
                inc     b

                push    bc
                call    fndInctvPrtcl
                pop     bc
                or      a                           ; Check if A is zero...
                ret     z                           ; ...and return if it is 

                ld      a, 35                       ; Set lifespan of particle
                ld      (hl), a                     ; save it
                inc     l                           ; Move HL to...
                inc     l                           ; ...the XVector
                ld      a, (rndmNmbr1)
                ld      (hl), a                     ; Load 0 into the XVector
                inc     l                           ; Move HL to...
                ld      (hl), 0x00                  ; Load 0 into the XVector
                inc     l                           ; ...the Xpos
                ld      (hl), 0                     ; Set the low byte to 0
                inc     l                           ; Move to high byte
                ld      (hl), b                     ; Set high byte to B
                inc     l                           ; Move to the YVector
                ld      a, (rndmNmbr3)
                ld      (hl), a                     ; Load YVextor low byte
                inc     l                           ; Move HL to...
                ld      (hl), 0xfd                  ; Load YVextor high byte
                inc     l                           ; ...the ypos
                ld      (hl), 0                     ; Set the low byte to 0
                inc     l                           ; Move to high byte
_prtcl_y_1      ld      (hl), c                     ; Set high byte to C

                push    bc
                call    fndInctvPrtcl
                pop     bc
                or      a                           ; Check if A is zero...
                ret     z                           ; ...and return if it is 

                ld      a, 35                       ; Set lifespan of particle
                ld      (hl), a                     ; save it
                inc     l                           ; Move HL to...
                inc     l                           ; ...the XVector
                ld      a, (rndmNmbr2)
                ld      (hl), a                     
                inc     l                           
                ld      (hl), 0xff                  
                inc     l                         
                ld      (hl), 0                   
                inc     l                         
_prtcl_x_2      ld      (hl), b                   
                inc     l                         
                ld      a, (rndmNmbr3)
                ld      (hl), a                   
                inc     l                         
                ld      (hl), 0xfd                
                inc     l                         
                ld      (hl), 0                   
                inc     l                         
_prtcl_y_2      ld      (hl), c                   

                push    bc
                call    fndInctvPrtcl
                pop     bc
                or      a                           ; Check if A is zero...
                ret     z                           ; ...and return if it is 

                ld      a, 35                       ; Set lifespan of particle
                ld      (hl), a                     ; save it
                inc     l                           ; Move HL to...
                inc     l                           ; ...the XVector
                ld      a, (rndmNmbr1)
                ld      (hl), 0                     
                inc     l                           
                ld      (hl), 0                  
                inc     l                         
                ld      (hl), 0                   
                inc     l                         
_prtcl_x_3      ld      (hl), b                   
                inc     l                         
                ld      a, (rndmNmbr3)
                ld      (hl), a                   
                inc     l                         
                ld      (hl), 0xfc                
                inc     l                         
                ld      (hl), 0                   
                inc     l                         
_prtcl_y_3      ld      (hl), c

                ret

;****************************************************************************************************************
; Find the address of a particle that is not currently active
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   A = > 0 means a particle was found
;   HL = Address of available score sprite
;****************************************************************************************************************
fndInctvPrtcl
                ld      b, NUMPRTCLS                ; Load B with the total number of available particles 
                ld      hl, objctPrtcls + 1         ; Load HL with the address of the first particles timer value
_chkNxtPrtcl     
                ld      a, (hl)                     ; Load A with the time value from the particle
                or      a                           ; If its zero...
                jr      z, _foundPrtcl              ; ...then its available and we can finish...
                ld      de, PRTCLSZ                 ; ...otherwise we load DE with the size of a particle...
                add     hl, de                      ; ... and increment HL to get to the next particle
                djnz    _chkNxtPrtcl                ; Loop if necessary
                xor     a                           ; Getting here means no available particles, so reset A
                ret                                 ; Return
_foundPrtcl
                inc     a                           ; We found a particle so increment the timer to mark is used
                ld      (hl), a
                dec     l                           ; Move to the start of the particle struct
                ret

;****************************************************************************************************************
; Updates active particles by adjusting their current position using their current vector. A particle is active
; if it has a timer value > 0
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
updtPrtcls
                ld      b, NUMPRTCLS                ; Load B with the total number of particles available
                ld      hl, objctPrtcls             ; Point HL at the particle objects object pool

_nxtPrtcl 
                ld      c, (hl)                     ; Save lifespan
                inc     hl                          ; Move to timer
                ld      a, (hl)                     ; Load timer
                cp      0                           ; Is timer > 0           
                jp      nz, _updtPrtcl              ; Yes then update
                ld      de, PRTCLSZ - 1             ; Move to next particle     
                add     hl, de                      ; Increase HL
                djnz    _nxtPrtcl                   ; Loop
                ret
_updtPrtcl
                inc     a                           ; Increment timer
                cp      c                           ; Compare with lifespan
                jp      z, _rstPrtclTmr             ; If 0 then reset the timer
                push    bc
                push    hl
                ld      (hl), a                     ; Save new timer value
                inc     l                           ; Move to the x vector address

                ; Update X Position with XVector
                ld      c, (hl)                     ; Load the low byte of the xVector into C
                inc     l                           ; Move to the hight byte
                ld      b, (hl)                     ; Load the hight byte of the xVector into B
                inc     l
                ld      e, (hl)                     ; Load low byte of xpos into E
                inc     l                           ; Move to the high byte
                ld      d, (hl)                     ; Load the high byte of xpos into D
                ex      de, hl                      ; Exchange DE and HL 
                add     hl, bc                      ; Add the xvector to the xpos
                ex      de, hl                      ; Exchange DE and HL again to get the particle address back into HL

                ld      a, d                        ; Check to see if the X location 
                cp      SCRNLFT                     ; ...has passed the left edge of the screen area
                jr      nc, _chkRght                ; If not then check the right screen edge
                ld      d, SCRNLFT                  ; otherwise set the balls X pos to the screens edge
_chkRght        
                cp      SCRNRGHT - BLLPXLWIDTH      ; Check to see if the X location has passed the right screen edge
                jp      c, _sveXPos                 ; If not then save the current X pos
                ld      d, 256 - 16 - BLLPXLWIDTH   ; ...otherwise set the X pos to be the right screen edge
_sveXPos
                ld      (hl), d                     ; Save high byte of xpos
                dec     l                           ; Move to the low byte
                ld      (hl), e                     ; Save the low byte of xpos
                inc     l                           ; Move to the YVector
                inc     l                           ; ...which is a word away    

                ; Apply gravity to YVector
                ld      c, (hl)                     ; Load the low byte of the xVector into C
                inc     l                           ; Move to the hight byte
                ld      b, (hl)                     ; Load the hight byte of the xVector into B
                ld      a, (grvty)
                ld      e, a
                ld      a, (grvty + 1)
                ld      d, a
                ex      de, hl  
                add     hl, bc
                ex      de, hl
                
                ; Update Y Position using YVector
                ld      c, e
                ld      b, d
                dec     l
                ld      (hl), e
                inc     l
                ld      (hl), d
                inc     l
                ld      e, (hl)                     ; Load low byte of xpos into E
                inc     l                           ; Move to the high byte
                ld      d, (hl)                     ; Load the high byte of xpos into D
                ex      de, hl                      ; Exchange DE and HL 
                add     hl, bc                      ; Add the xvector to the xpos
                ex      de, hl                      ; Exchange DE and HL again to get the particle address back into HL
                ld      (hl), d                     ; Save high byte of xpos
                dec     l                           ; Move to the low byte
                ld      (hl), e                     ; Save the low byte of xpos
                inc     l                           ; Move to the YVector
                inc     l                           ; ...which is a word away 

                ; Move to the next particle
                pop     hl                          ; Resotore HL before we started moving around
                pop     bc                          ; Restore our particle counter in B
                ld      de, PRTCLSZ - 1             ; Load DE with the size of a particle struct - 1
                add     hl, de                      ; Move HL to the next particle address
                djnz    _nxtPrtcl                   ; Loop
                ret

_rstPrtclTmr    ; Reset the timer for the current particle as its not dead
                xor     a                           ; Clear A
                ld      (hl), a                     ; Save A to the timer basically resetting it
                ld      de, PRTCLSZ - 1             ; Load DE with the size of a particle struct - 1
                add     hl, de                      ; Move HL to the next particle address
                djnz    _nxtPrtcl                   ; Loop
                ret