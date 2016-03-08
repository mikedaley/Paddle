;****************************************************************************************************************
; Paddle - Mike Daley
; 26/09/15
;
; Paddle is a Break Out clone used to learn Z80 Assembly on the ZX Spectrum
;
; Notes
; * Using IM1 so IY can't be used as the IM1 interrupt doesn't prtext it. Using IM2 would allow for IY to be used.                  
;****************************************************************************************************************

                org     32768

;****************************************************************************************************************
; init
;****************************************************************************************************************           
init 
                ld      a, 0                        ; Set the border colour
                out     (254), a                    
                        
                ld      a, 5                        ; Set the ink colour
                ld      (23693), a  
                
;****************************************************************************************************************
; init
;**************************************************************************************************************** 
                ; Create the y-axis screen memory lookup table
.directDraw     equ     1

    IF !.directDraw
                ld      hl, scrnLnLkup              ; Point HL at the address of the y axis loopup table
                ld      de, SCRNBFFR                ; Point DE at the address of the screen buffer
                ld      b, 192                      ; We need an address for all 192 lines on screen
_yLkupLp        ld      (hl), e                     ; Save E...
                inc     hl                          ; ...and...
                ld      (hl), d                     ; ...D into the screen lookup table
                inc     hl                          ; Move to the next buffer location
                push    hl                          ; Save HL
                ld      hl, 32                      ; HL is loaded with 32, number of bytes per screen line
                add     hl, de                      ; Add that to DE to get the next lookup address
                ex      de, hl                      ; Switch DE and HL
                pop     hl                          ; Restore HL
                djnz    _yLkupLp                    ; Loop until all lines are done
    ENDIF

                call    drwTtlScrn                  ; Draw the title screen
                call    watFrSpc                    ; Wait for the space key to be pressed
                call    clrScrn                     ; Once pressed clear the screen
                call    drwBrdrs                    ; Draw the screen borders

                ld      de, lvsTxt                  ; Load DE with the address of the Lives Text
                ld      bc, 8                       ; Set the length of the string
                call    8252                        ; ROM print the string

                ld      a, 0                        ; Load A with 0 for the initial level
                ld      (crrntLvl), a               ; Save the level 
                call    ldLvl                       ; Load the current level

                ld      a, GMESTTE_DSPLYLVL         ; Set the game state to DISPLAY LEVEL
                ld      (gmeStte), a                ; Save the game state

                jp      mnLp                        ; Jump tp the main loop

clrScrn     
                call    3503                        ; ROM clear screen

                ld      de, scrLblTxt               ; Point DE to the score label text
                ld      bc, 10                      ; Set the length of the string
                call    8252                        ; ROM print

                ld      de, scrTxt                  ; Point DE to the score text
                ld      bc, 12                      ; Set the length of the string
                call    8252                        ; ROM print

                ld      de, lvsLblTxt               ; Point DE to lives label text
                ld      bc, 10                      ; Set the length of the string
                call    8252                        ; ROM print

                ret

;****************************************************************************************************************
; Main loop
;****************************************************************************************************************
mnLp 
                ld      a, (gmeStte)                ; Check the game state

_chckGmeSttePlyng                                   ; *** Game state PLAYING
                cp      GMESTTE_PLYNG               ; Is the game state PLAYING
                jr      nz, _chckGmeStteWtng        ; If not then check if the state is WAITING
                call    MoveBall                    ; Move the ball
                call    rdCntrlKys                  ; Read the keyboard
                call    drwBll                      ; Draw the ball
                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

    IF !.directDraw
                call    fstCpy                      ; Copy the double buffer to the screen file
    ENDIF

                call    drwBll                      ; Erase the ball (XOR)
                call    drwBt                       ; Erase the bat (XOR)
                ld      a, (lvlBlckCnt)             ; Load A with the number of blocks that are still visible
                cp      0                           ; Check the number of blocks against 0
                jr      nz, mnLp                    ; If not yet 0 then loop
                ld      a, GMESTTE_NXTLVL           ; No more blocks yet so set the game state to NEXT LEVEL
                ld      (gmeStte), a                ; Save the game state and loop
                jp      mnLp

_chckGmeStteWtng                                    ; *** Game state WAITING
                cp      GMESTTE_WTNG                ; Is the game state WAITING    
                jp      nz, _chckGmeSttePlyrDead    ; If not then check if the state is PLAYER DEAD
                call    rdCntrlKys                  ; Read the keyboard

                ld      a, (objctBat + BTYPS)      ; Get the bats Y position
                ld      b, BLLPXLHGHT               ; Get the pixel height of the ball
                sub     b                           ; Calulcate the bats Y pos minus the balls height putting the ball ontop of the bat
                ld      (objctBall + BLLYPS), a     ; Update the balls Y Position with the bats Y position 
                ld      a, (objctBat + BTXPS)      ; Load the bats X pos
                ld      b, (BTPXLWDTH / 2) - (BLLPXLWIDTH / 2)  ; Calc the X pos middle of the bat
                add     a, b                        ; Calc the new X pos for the ball so its in the middle of the bat
                ld      (objctBall + BLLXPS), a     ; Save the new X pos for the ball
                call    drwBll                      ; Draw the ball
                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

    IF !.directDraw
                call    fstCpy                      ; Copy the double buffer to the screen file
    ENDIF

                call    drwBll                      ; Erase the ball (XOR)
                call    drwBt                       ; Erase the bat (XOR)
                ld      bc, 32766                   ; Want to see if SPACE has been pressed
                in      a, (c)                      ; Read the port
                rra                                 ; Rotate Right
                jp      c, mnLp                     ; If SPACE is not pressed then keep looping
                ld      a, GMESTTE_PLYNG            ; Otherwise update the game state to GMESTTE_PLYNG
                ld      (gmeStte), a                ; Save the game state
                jp      mnLp                        ; Loop

_chckGmeStteLstLfe                                  ; *** Game state LOST LIFE
                cp      GMESTTE_DEAD                ; Is the game state PLAYER DEAD
                jr      nz, _gmeStteNxtLvl          ; If not then check if the state is NEXT LEVEL
                ld      a, (lives)                  ; Load A with the lives left
                dec     a                           ; -1 from lives

                push    af                          ; Save AF
                ld      (lives), a                  ; Save the new number of lives
                add     a, 48                       ; Add 48 to the number of lives to get the character code for the lives number
                ld      (lvsTxt + 5), a             ; Update the lives text with the new lives character

                ld      de, lvsTxt                  ; Load DE with the levels text
                ld      bc, 6                       ; Set attribute to yellow ink on black background
                call    8252                        ; ROM Print
                pop     af                          ; Restore AF
                cp      0                           ; Check if the players lives have reached 0 
                jr      z, _setGmeStteLstLfe        ; Jump to set the game state to LOST LIFE

                call    ResetBat                    ; Reset the bats location
                call    plyDthSnd                   ; Play a death sound 

                ld      a, GMESTTE_WTNG             ; Set the game state to WAITING
                ld      (gmeStte), a                ; Save the game state
                jp      mnLp
_setGmeStteLstLfe
                ld      a, GMESTTE_LSTLFE 
                ld      (gmeStte), a
                jp      mnLp

_gmeStteNxtLvl                                      ; *** Game state NEXT LEVEL
                cp      GMESTTE_NXTLVL              ; Is the game state NEXT LEVEL
                jr      nz, _chckGmeStteDsplyLvl    ; If not then check if the game state is DISPLAY LEVEL
                ld      a, (crrntLvl)               ; Load A with the current level
                inc     a                           ; +1 to the current level
                ld      (crrntLvl), a               ; Save the current level
                cp      2                           ; Is the current level 2?
                jr      nz, _incLvl                 ; If not then increment the level
                ld      a, 1                        ; Otherwise set the level back to 1
                ld      (crrntLvl), a               ; and save it.
_incLvl         ld      a, GMESTTE_DSPLYLVL         ; Set the game state to DISPLAY LEVEL
                ld      (gmeStte), a                ; Save the game state
                call    ldLvl                       ; Load the new level
                jp      mnLp                        ; Loop

_chckGmeStteDsplyLvl                                ; *** Game state DISPLAY LEVEL
                cp      GMESTTE_DSPLYLVL            ; Is the game state DISPLAY LEVEL
                jp      nz, _chckGmeSttePlyrDead    ; If not then check if the game state is PLAYER DEAD
                ld      hl, (crrntLvlAddr)          ; Load HL with the current level address
                ld      de, lvlTtl                  ; Load DE with the offset in the level data to the level title
                add     hl, de                      ; Move HL to the level title
                xor     b                           ; Set b to 0                            
                ld      c, (hl)                     ; Load C with contents of the title at HL
                ld      d, h                        ; Load HL
                ld      e, l                        ; into DE
                inc     de                          ; +1 DE
                call    8252                        ; ROM print the title
                ld      de, 100                     ; Load DE with 100 for a delay loop
_lvlDsplyWtng   halt                                ; Wait for the scan line to reach the top of the screen (50hz)
                dec     de                          ; -1 from DE
                ld      a, d                        ; Check to see if...
                or      e                           ; ...the timer has run down
                jr      nz, _lvlDsplyWtng           ; If not then loop again
                ld      hl, (crrntLvlAddr)          ; Load HL with the address of the current level data
                ld      de, lvlTtl                  ; Load DE with the levels title position 
                add     hl, de                      ; and add it to DE
                ld      b, 0                        ; Set the
                ld      c, (hl)
                add     hl, bc
                ld      b, 0
                inc     hl
                ld      c, (hl)
                ld      d, h 
                ld      e, l
                inc     de
                call    8252

                ld      a, GMESTTE_WTNG             ; Set the  
                ld      (gmeStte), a
                jp      mnLp

_chckGmeSttePlyrDead
                cp      GMESTTE_LSTLFE
                jp      nz, mnLp
                ld      de, gmeOvrTxt
                ld      bc, 17
                call    8252
                call    watFrSpc
                call    clrScrn
                ld      a, 5 
                ld      (lives), a
                ld      a, 53                       ; The number five in the character set
                ld      (lvsTxt + 5), a
                ld      de, lvsTxt
                ld      bc, 6
                call    8252
                call    rstScr
                ld      a, 0
                ld      (crrntLvl), a
                call    ldLvl
                ld      a, GMESTTE_DSPLYLVL
                ld      (gmeStte), a
                call    ResetBat
                jp      mnLp

;****************************************************************************************************************
; Load the title screen for the game
;****************************************************************************************************************
drwTtlScrn
                ld      de, BTMPSCRNSDDR
                ld      hl, ttleScrn
                ld      bc, BTMPSCRSZ + ATTRSCRNSZ
                ldir
                ret

;****************************************************************************************************************
; Load the title screen for the game
;****************************************************************************************************************
drwBrdrs
                ; Draw top wall
                ld      h, 0
                ld      b, 8
                ld      c, 2
_hrzntlLp
                push    hl
                push    bc
                ld      de, HorizBlockData
                call    Draw_8x8_Sprite
                pop     bc
                pop     hl
                ld      a, b
                add     a, 8
                ld      b, a
                inc     h
                ld      a, h
                cp      30
                jr      nz, _hrzntlLp

                ; Draw right hand wall
                ld      h, 0
                ld      b, SCRNRGHT
                ld      c, 9
_vrtclLp1
                push    hl
                push    bc
                ld      de, VertLBlockData
                call    Draw_8x8_Sprite
                pop     bc
                pop     hl
                ld      a,c
                add     a, 8
                ld      c, a
                inc     h
                ld      a, h
                cp      22
                jr      nz, _vrtclLp1

                ; Draw Left hand wall
                ld      h, 0
                ld      b, 0
                ld      c, 9
_vrtclLp2
                push    hl
                push    bc
                ld      de, VertRBlockData
                call    Draw_8x8_Sprite
                pop     bc
                pop     hl
                ld      a,c
                add     a, 8
                ld      c, a
                inc     h
                ld      a, h
                cp      22
                jr      nz, _vrtclLp2

                ret

;****************************************************************************************************************
; Draw Ball
; Draws the ball sprite at the location held in the objctBall structure
;****************************************************************************************************************
drwBll 
                ld      de, SmallBallData          ; Point DE to the ball sprite data
                ld      a, (objctBall + BLLXPS); Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (objctBall + BLLYPS)
                ld      c, a
                call    Draw_16x4_Sprite
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the bat sprite at the location held in the objctBat structure
;****************************************************************************************************************
drwBt 
                ld      de, SpriteBatData           ; Point DE to the ball sprite data
                ld      a, (objctBat + BTXPS)  ; Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (objctBat + BTYPS)
                ld      c, a
                call    Draw_32x8_Sprite
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the batn sprite at the location held in the objctBat structure
;******************************************************1**********************************************************
drwMvngBlck 
                ld      de, SpriteBlockData  ; Point DE to the ball sprite data
                ld      a, (ix + BLLXPS)  ; Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (ix + BLLYPS)
                ld      c, a
                call    Draw_24x8_Sprite
                ret

;************************************************************************************************************************
; Wait for space to be pressed
;************************************************************************************************************************
watFrSpc
                ld      bc, 32766
                in      a, (c)
                rra 
                ret     nc
                jp      watFrSpc

;************************************************************************************************************************
; Read Control Keys
;************************************************************************************************************************
rdCntrlKys 
                ; Check if keys one 1 or 2 have been pressed which move the bat
                ld      bc, 63486                   ; Load BC with the port to read 5, 4, 3, 2, 1
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; Outermost bit = key 1
                push    af                          ; Remember that value
                call    nc, MoveBatLeft             ; Move the bat left
                pop     af                          ; Restore A
                rra                                 ; Next bit is key 2
                push    af
                call    nc, MoveBatRight            ; Move the bat right
                pop     af
                ret 

;************************************************************************************************************************
; Move the bat to the left
;************************************************************************************************************************
MoveBatLeft     
                ld      ix, objctBat   
                ld      a, (ix + BTXPS)         ; IX + 0 = X Position
                sub     (ix + BTSPD)            ; IX + 2 = Speed
                cp      8                           ; Check if we are past the 0
                jp      c, HitLeftEdge              ; and jump if we are
                ld      (ix + BTXPS), a         ; Update the X position with A
                ret     
HitLeftEdge         
                ld      (ix + BTXPS), 8         ; Hit the edge so set the X pos to 0
                ret 

;************************************************************************************************************************
; Move bat to the right
;************************************************************************************************************************   
MoveBatRight    
                ld      ix, objctBat   
                ld      a, (ix + BTXPS)         ; IX + 0 = X Position
                add     a, (ix + BTSPD)         ; IX + 2 = Speed
                cp      BTMXRGHT            ; Check if the bat is past right edge
                jp      nc, BatHitRightEdge         ; and jump if it is
                ld      (ix + BTXPS), a         ; Update the X Position with A
                ret     
BatHitRightEdge         
                ld      (ix + BTXPS), BTMXRGHT
                ret

;************************************************************************************************************************
; Updates the position of the moving block
;************************************************************************************************************************   
updtMvngBlck
                ld      a, (ix + BLLXPS)
                add     a, (ix + BLLXSPD)
                ld      (ix + BLLXPS), a
                cp      SCRNRGHT - 16
                jp      nc, BlockHitEdge
                cp      8
                jp      c, BlockHitEdge
                ret

BlockHitEdge
                ld      a, (ix + BLLXSPD)
                neg
                ld      (ix + BLLXSPD), a
                ret

;****************************************************************************************************************
; Draw Sprite 
; Call with DE = Sprite data, B = X, C = Y
;****************************************************************************************************************
Draw_8x8_Sprite      
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
    
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM                
                ret                          

;****************************************************************************************************************
; Draw Sprite 
; Call with DE = Sprite data, B = X, C = Y
;****************************************************************************************************************
Draw_24x8_Sprite      
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
    
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM               
                ret                                 ; All done! 

;****************************************************************************************************************
; Draw Sprite 
; Call with DE = Sprite data, B = X, C = Y
;****************************************************************************************************************
Draw_32x8_Sprite      
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
    
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM                
                ret                                 ; All done!  

;****************************************************************************************************************
; Draw 8x8 Sprite
; B = X, C = Y
; Uses: DE, HL, BC
;****************************************************************************************************************
Draw_16x8_Sprite
                ld      a, b                        ; Load A with the X pixel position
                and     7                           ; Get the Bit rotate count (lower 3 bits of X position)
        
                ; Load DE with the address of the sprite we need to use based on the x location offset in memory as
                ; we are using pre-shifted sprites
                ld      l, a                        ; Load A with the number of shifts needed
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the lookup table entries are words
                add     hl, de                      ; Add base address of sprite table which is held in DE
                ld      e, (hl)                     ; Load E with the contents of (HL)
                inc     hl                          ; Move HL to the next byte of address in the table
                ld      d, (hl)                     ; Load D with the high byte
        
                ; Work out the X offset of the screen memory address based on the X pixel position
                ld      a, b                        ; Work out the X Offset using the shift value
                rra
                rra
                rra
                and     %00011111                   ; 31
                ld      b, a                        ; Store the X pixel byte offset into the screen buffer
                push    bc                          ; Save B as we will be using it to merge the X offset into the 
                                                    ; buffer address

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
    
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM                
                ret                                 ; All done!  

;****************************************************************************************************************
; Draw 8x8 Sprite
; B = X, C = Y
; Uses: DE, HL, BC
;****************************************************************************************************************
Draw_16x4_Sprite
                ld      a, b                        ; Load A with the X pixel position
                and     7                           ; Get the Bit rotate count (lower 3 bits of X position)
        
                ; Load DE with the address of the sprite we need to use based on the x location offset in memory as
                ; we are using pre-shifted sprites
                ld      l, a                        ; Load A with the number of shifts needed
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the lookup table entries are words
                add     hl, de                      ; Add base address of sprite table which is held in DE
                ld      e, (hl)                     ; Load E with the contents of (HL)
                inc     hl                          ; Move HL to the next byte of address in the table
                ld      d, (hl)                     ; Load D with the high byte
        
                ; Work out the X offset of the screen memory address based on the X pixel position
                ld      a, b                        ; Work out the X Offset using the shift value
                rra
                rra
                rra
                and     %00011111                   ; 31
                ld      b, a                        ; Store the X pixel byte offset into the screen buffer
                push    bc                          ; Save B as we will be using it to merge the X offset into the 
                                                    ; buffer address

                ; Load IX with the first address of the y-axis lookup table
                ld      b, 0                        ; Clear B
                ld      ix, scrnLnLkup              ; Load IY with the lookup table address
                add     ix, bc                      ; Increment IX by the Y pixel position
                add     ix, bc                      ; twice as the table contains word values
                pop     bc                          ; Restore B which holds the X byte offset

    REPT 4                                          ; Repeat this code 8 times for the 8 pixles rows of a ball sprite
                ld      a, (ix + 0)                 ; Get the current line
                or      b                           ; Merge in our X Offset
                ld      l, a                        ; Load the merged low byte in L
                ld      h, (ix + 1)                 ; Get the high byte from the lookup table
                inc     ix  
                inc     ix                          ; Move to the next line which is a word away
    
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory

                ld      a, (de)                     ; Grab the second byte of sprite data into A             
                inc     de                          ; Move to the next row of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
    ENDM                
                ret                                 ; All done!  

;****************************************************************************************************************
; Copy the screen buffer to the screen file using a Stack based approach.
; Original code developed by Andrew Owen in Bob.asm that was downloaded from the Z80 Assembly
; Programming for the ZX Spectrum Facebook group
;****************************************************************************************************************
; fstCpy
;                 di                              ; Don't want any interrupts while we are moving the buffer!
;                 ld      (scrnStckPtr), sp      ; Save the current stack pointer

;                 ;First we copy over the attribute data
; ;                 REPT 48, attr               ; write the attributes
; ;                     ld      ix, attributes + 768 - 16 - (attr * 16)
; ;                                             ; last byte of the back_buffer - 16
; ;                     ld      iy, 16384 + 6912 - (attr * 16)
; ;                                             ; last byte of the screen
; ;                     ld      hl, $ + 9       ; set return location (no stack available)
; ;                     ld      (EndCall), hl           
; ;                     jp      Blit            ; call blit
; ;                 ENDM

;                 ; Now copy the bitmap data to the screen file
;                 REPT 2, chunk               
;                     REPT 8, row
;                         REPT 8, cell
;                             REPT 2, line
;                                 ld      ix, SCRNBFFR + BTMPSCRSZ - 16 - (line * (16 - SCRNEDGSZ)) - (cell * 32) - (row * 256) - (chunk * 2048)
;                                 ld      iy, BTMPSCRNSDDR + BTMPSCRSZ - SCRNEDGSZ - (line * (16 - SCRNEDGSZ)) - (cell * 256) - (row * 32) - (chunk * 2048)
;                                 ld      hl, $ + 9
;                                 ld      (EndCall), hl           
;                                 jp      Blit
;                             ENDM
;                         ENDM
;                     ENDM
;                 ENDM

;                 REPT 7, row
;                     REPT 8, cell
;                         REPT 2, line
;                             ld      ix, SCRNBFFR + BTMPSCRSZ - 16 - (line * (16 - SCRNEDGSZ)) - (cell * 32) - (row * 256) - (2 * 2048)
;                             ld      iy, BTMPSCRNSDDR + BTMPSCRSZ - SCRNEDGSZ - (line * (16 - SCRNEDGSZ)) - (cell * 256) - (row * 32) - (2 * 2048)
;                             ld      hl, $ + 9
;                             ld      (EndCall), hl           
;                             jp      Blit
;                         ENDM
;                     ENDM
;                 ENDM

;                 ld      sp, (scrnStckPtr)      ; Restore stack pointer
;                 ei
;                 ret

;****************************************************************************************************************
; Routine to copy 16 bytes from location in IX to location in IY - 16bytes
;****************************************************************************************************************
Blit
                ld      sp, ix
                pop     af              ; read 16 bytes
                pop     bc
                pop     de
                pop     hl
                ex      af, af'         ;'
                exx
                pop     af
                pop     bc
;                 pop     de
;                 pop     hl
                
                ld      sp, iy
;                 push    hl              ; write 16 bytes
;                 push    de
                push    bc
                push    af
                ex      af, af'         ;'
                exx
                push    hl
                push    de
                push    bc
                push    af
                db      0xc3            ; jp endcall
EndCall         dw      EndCall

;****************************************************************************************************************
; Covert the pixel coordinates into char coordinates
; D = Pixel X, E = Pixel Y returning B = Char X, C = Char Y
;****************************************************************************************************************
GetCharLocation 
                ld      a, d
                srl     a                           ; Divide by 8 to get the char X position
                srl     a
                srl     a
                ld      c, a

                ld      a, e                        ; Divide by 8 to get the char y position
                srl     a
                srl     a
                srl     a
                ld      b, a
                ret

;****************************************************************************************************************
; MOVEBALL
; Responsible for bouncing the ball sprite around the screen, detecting when it hits the edges of the screen
; and any tile objects
;****************************************************************************************************************
MoveBall 
                ld      hl, objctBall              ; Use HL to hold the ball object as using IX is expensive                
_MoveX
                ld      a, (hl)                     ; First position in the structure is the X Position
                inc     hl                          ; Move to the X Speed
                add     a, (hl)                     ; Update the balls position using its speed 
                dec     hl
                ld      (hl), a 

                cp      SCRNRGHT - BLLPXLWIDTH
                jr      nc, _BounceLeft             ; Ball has reached or moved past the right hand edge of the screen

                cp      SCRNLFT                   
                jr      c, _BounceRight             ; The ball has reached or moved past the left of the screen

_MoveY           
                inc     hl
                inc     hl                          ; Move HL to point to the Y positon 
                ld      a, (hl)                     ; Load the balls Y Position into A...
                inc     hl                          ; ...then point HL at the Y Speed...
                add     a, (hl)                     ; ...and add it to the Y Position
                dec     hl                          ; Move HL to the balls Y Postion 
                ld      (hl), a                     ; Save the balls new position 

                cp      SCRNBTTM
;                 jr      nc, _HitBottom              ; Ball has reached or moved past the top of the screen

                inc     hl                          ; Move HL to the Y Speed
                ld      a, (hl)                     ; Load the Y Speed into A to check if its moving up or down the screen
                cp      0                           
                jp      c, _CheckTop                ; Ball is not moving down the screen so check for collision at top of screen
                call    CheckBatCollison            ; Only check collision with the bat of the ball is moving down the screen
                call    BallCharPos
                ret

_CheckTop
                dec     hl                          ; Move HL to the Y Position
                ld      a, (hl)
                cp      SCRNTP
                jr      nc, _BounceDown             ; Ball has reached or moved past the top of the screen
                call    BallCharPos
                ret

_BounceDown
                ld      a, SCRNTP
                ld      (hl), a                     ; Update the Y Position so the ball is up against the top of the screen
                inc     hl                          ; Move HL to the Y Speed
                ld      a, (hl)                     ; Load the Y Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                dec     hl                          ; Moved HL to the Y Position
                ld      a, SCRNBTTM - BLLPXLHGHT    ; Make sure the ball sits right up against the edge of the screen
                ld      (hl), a                     ; Save the balls new Y position                
                call    BallCharPos
                ret

_HitBottom
                ld      a, GMESTTE_DEAD
                ld      (gmeStte), a
                jp      BallCharPos
                ret

_BounceLeft
                inc     hl
                ld      a, (hl)                     ; Load the X Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                dec     hl                          ; Move HL to the X Position
                ld      a, SCRNRGHT - BLLPXLWIDTH    ; Make sure the ball sits right up against the right edge of the screen
                ld      (hl), a                     ; Save the balls new X position
                jp      _MoveY                      ; Check for a bounce on the y-axis

_BounceRight
                inc     hl
                ld      a, (hl)                     ; Load the X Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                dec     hl                          ; Move HL to point to the X Position 
                ld      a, SCRNLFT                ; Make sure the ball sits right up against the left edge of the screen
                ld      (hl), a                     ; Save the balls new X position
                jp      _MoveY                      ; Check for a bounce in the y-axis

BallCharPos     ; Update the balls character position used in block collision detection
                ld      hl, objctBall
                ld      a, (hl)                     ; Middle Top
                add     a, BLLPXLWIDTH / 2
                ld      d, a
                inc     hl
                inc     hl
                ld      e, (hl)
                call    GetCharLocation
                ld      (ballMT), bc

                dec     hl
                dec     hl
                ld      a, (hl)                     ; Middle Right
                add     a, BLLPXLWIDTH
                ld      d, a
                inc     hl
                inc     hl
                ld      a, (hl)
                add     a, BLLPXLHGHT / 2
                ld      e, a
                call    GetCharLocation
                ld      (ballMR), bc

                dec     hl
                dec     hl
                ld      a, (hl)        ; Middle Bottom
                add     a, BLLPXLWIDTH / 2
                ld      d, a
                inc     hl
                inc     hl
                ld      a, (hl)
                add     a, BLLPXLHGHT - 1    ; Move 1 pixel up into the ball
                ld      e, a
                call    GetCharLocation
                ld      (ballMB), bc

                dec     hl
                dec     hl
                ld      d, (hl)        ; Middle Left
                inc     hl
                inc     hl
                ld      a, (hl)
                add     a, BLLPXLHGHT / 2
                ld      e, a
                call    GetCharLocation
                ld      (ballML), bc

                call    CheckBlockCollision         ; Now go see if the ball has hit something :)

                ret

;****************************************************************************************************************
; Check to see if the ball has collided with the bat and if so update the properties of the ball as necessart
;****************************************************************************************************************
CheckBatCollison 

;                 ld      hl, objctBall              ; Point HL at the ball object

;                 ; First check if the ball has already passed the top of the bat
;                 ld      a, (objctBat + BTYPS)
;                 inc     hl
;                 inc     hl                          ; Move HL to Y Position 
;                 ld      b, (hl)                     ; Load B with the Y Position 
;                 cp      b                           ; Compare it against the bats Y Position
;                 jr      c, _Check1
;                 jp      _Check2                     ; A < B
; _Check1   
;                 ret     nz                          ; A > B so we are done

; _Check2
;                 ; Now check of the ball has hit the top of the bat
;                 ld      a, (objctBat + BTYPS)  ; Load the Y position of the bat
;                 sub     BLLPXLHGHT           ; Sub the height of the ball in pixels
;                 inc     hl
;                 inc     hl                          ; Move HL to the balls Y Position 
;                 ld      b, (hl)
;                 cp      b                           ; Compare that with the balls y position
;                 jr      c, _SecondCheck             ; Start of A > B check
;                 jp      _PassedBatTop               ; Failed first check so A < B
; _SecondCheck                    
;                 ret     nz                          ; A > B so we are done
                
; _PassedBatTop
;                 ; If the ball has already passed the top of the bat then we are done
;                 ld      a, (objctBat + BTYPS)
;                 cp      b                           ; B still has the balls Y Position in it
;                 ret     c                           ; A < B

;                 ; To check where on the bat the ball has collided we put the ball into bat space coordinates
;                 ; by subtracting the x position of the bat from the x position of the ball
;                 ld      a, (objctBat + BTXPS)
;                 ld      b, a
;                 ld      a, (ix + BLLXPS)
;                 add     a, BLLPXLWIDTH / 2
;                 sub     b                           ; Subtract the bat.x from ball.x
;                 ret     c                           ; A < 0 so the ball is left of the bat
;                 cp      BTPXLWDTH             ; Check if ball.x > bat.pixel_width
;                 ret     nc                          ; If it is then ball to the right of the bat

;                 push    af

;                 ld      b, 20
;                 call    plyClck

;                 ; Check the balls x direction and based on that perform the bats collision checks
;                 ld      a, (ix + BLLXSPD)
;                 cp      0 
;                 jp      m, LeftDirection

; RightDirection  
;                 pop     af
;                 cp      6
;                 jr      nc, RArea2
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 0
;                 add     hl, de
;                 ld      a, (hl)
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; RArea2          cp      12
;                 jr      nc, RArea3
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 1
;                 add     hl, de
;                 ld      a, (hl)
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; RArea3          cp      18
;                 jr      nc, RArea4
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 2
;                 add     hl, de
;                 ld      a, (hl)
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; RArea4          cp      24
;                 jr      nc, AdjustYDir
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 3
;                 add     hl, de
;                 ld      a, (hl)
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir

; LeftDirection  
;                 pop     af
;                 cp      6
;                 jr      nc, LArea2
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 3
;                 add     hl, de
;                 ld      a, (hl)
;                 neg
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; LArea2          cp      12
;                 jr      nc, LArea3
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 2
;                 add     hl, de
;                 ld      a, (hl)
;                 neg
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; LArea3          cp      18
;                 jr      nc, LArea4
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 1
;                 add     hl, de
;                 ld      a, (hl)
;                 neg
;                 ld      (ix + BLLXSPD), a
;                 jp      AdjustYDir
; LArea4          cp      24
;                 jr      nc, AdjustYDir
;                 ld      hl, (crrntLvlAddr)
;                 ld      de, LEVEL_BTSPDS + 0
;                 add     hl, de
;                 ld      a, (hl)
;                 neg
;                 ld      (ix + BLLXSPD), a

; AdjustYDir 
;                 ld      a, (objctBat + BTYPS)  ; Update the Y pos of the ball so that it rests ontop of the bat
;                 sub     4   
;                 ld      (ix + BLLYPS), a
;                 ld      a, (ix + BLLYSPD)
;                 neg                                 ; Change the balls Y direction
;                 ld      (ix + BLLYSPD), a   
;                 pop     hl
                ret 

;****************************************************************************************************************
; Check the edge point on the ball to see if they have collided with a block based on the blocks attribute colour
;****************************************************************************************************************
CheckBlockCollision 
                ld      a, (ballMT)
                ld      d, a
                ld      a, (ballMT + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5               
                jr      z, MiddleRight  
                ld      a, (objctBall + BLLYSPD)
                cp      0
                jp      p, MT0
                neg
                ld      (objctBall + BLLYSPD), a
MT0             call    RemoveBlock
                ret
MiddleRight 
                ld      a, (ballMR)
                ld      d, a
                ld      a, (ballMR + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                jr      z, MiddleBottom
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a
                call    RemoveBlock
                ret
MiddleBottom
                ld      a, (ballMB)
                ld      d, a
                ld      a, (ballMB + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                jr      z, MiddleLeft
                ld      a, (objctBall + BLLYSPD)
                neg
                ld      (objctBall + BLLYSPD), a   
                call    RemoveBlock
                ret
MiddleLeft 
                ld      a, (ballML)
                ld      d, a
                ld      a, (ballML + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                ret     z
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a   
                call    RemoveBlock
                ret

;****************************************************************************************************************
; Remove the block that contains the x,y provided in DE
;****************************************************************************************************************
RemoveBlock
                ld      b, 100
                call    plyClck

                ld      hl, scrTxt + 10      
                ld      b, 6                
                call    updtScr                 
                ld      hl, scrTxt + 11          
                ld      b, 5                        
                call    updtScr    

                push    de
                push    bc
                ld      de, scrTxt               ; Print the score on the screen
                ld      bc, 12
                call    8252
                pop     bc
                pop     de

                ld      a, (lvlBlckCnt) 
                dec     a                           ; Decrement the number of blocks 
                ld      (lvlBlckCnt), a                    

                ; Remove the block
                ld      a, d
                and     1                           ; Check to see if the number is odd
                cp      0
                jr      z, Even

Odd             ld      a, 5
                push    de
                call    SetCharAttr
                pop     de
                ld      a, d
                sub     1
                ld      d, a
                ld      a, 5
                push    de
                call    SetCharAttr
                pop     de

                ld      a, d
                add     a, a
                add     a, a
                add     a, a
                ld      b, a

                ld      a, e
                add     a, a
                add     a, a
                add     a, a
                ld      c, a
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite
                ret

Even            ld      a, 5
                push    de
                call    SetCharAttr
                pop     de
                inc     d
                ld      a, 5
                push    de
                call    SetCharAttr
                pop     de
                dec     d
                ld      a, d
                add     a, a
                add     a, a
                add     a, a
                ld      b, a

                ld      a, e
                add     a, a
                add     a, a
                add     a, a
                ld      c, a
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite
                ret

;****************************************************************************************************************
; Set the attribute at the given X, Y
; D = X, E = Y, A = value to set
;****************************************************************************************************************
SetCharAttr 
                ld      h, 0                        ; Get the Y pos from the corner
                ld      l, e

                add     hl, hl                      ; Multiply the Y position by 32
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl

                ld      b, 0                        ; Get the X position
                ld      c, d
                add     hl, bc                      ; Add it to the Y position 

                ld      de, ATTRSCRNADDR          ; Add on the base ATTR screen address
                add     hl, de

                ld      (hl), a                     ; Load the attribute at HL
                ret

;****************************************************************************************************************
; Get the attribute at the given X, Y
; D = X, E = Y, returns A = given attribute
;****************************************************************************************************************
GetCharAttr 

                ld      h, 0                        ; Get the Y pos from the corner
                ld      l, e

                add     hl, hl                      ; Multiply the Y position by 32
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl

                ld      b, 0                        ; Get the X position
                ld      c, d
                add     hl, bc                      ; Add it to the Y position 

                ld      de, ATTRSCRNADDR          ; Add on the base ATTR screen address
                add     hl, de

                ld      a, (hl)                     ; Load the attribute at HL
                ret

;****************************************************************************************************************
; Reset the bats X pos to the center of play area
;****************************************************************************************************************
ResetBat    
                ld      a, 76                       
                ld      (objctBat + BTXPS), a
                ld      a, -2
                ld      (objctBall + BLLYSPD), a
                ret

;****************************************************************************************************************
; Load Level
; A = Level to load 
;****************************************************************************************************************
ldLvl 
                ld      de, LevelLookup             ; Load DE with the address of the Level Loopup Table
                ld      a, (crrntLvl)                 ; Load A with the level number to load
                ld      l, a
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the level lookup table entries are words
                add     hl, de                      ; Add base address of level lookup table which is held in DE
                ld      e, (hl)                     ; Pop the address at HL into DE
                inc     hl
                ld      d, (hl)
                ld      (crrntLvlAddr), de            ; Store away 
                ld      hl, (crrntLvlAddr)            ; and load HL with that address

                ; Load the block colours from the level data
                ld      de, ATTRSCRNADDR + (32 * 4)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_2
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 5)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_3
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 6)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_4
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 7)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_5
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 8)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_6
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 9)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (crrntLvlAddr)
                ld      de, LVL_CLR_ROW_7
                add     hl, de
                ld      de, ATTRSCRNADDR + (32 * 10)
                ld      bc, ROW_CLR_BYTES
                ldir

                ; Draw the blocks based on the levels block loopup table
NextBlockRow    ld      a, 0
                ld      (currntBlckCl), a
                ld      (currntBlckRw), a
                ld      (currntBlckX), a
                ld      a, 32
                ld      (currntBlckY), a

DrawNextBlock   ld      bc, (currntBlckY)
                ld      a, (hl)
                inc     hl
                cp      1
                jr      nz, SkipBlock

                ld      a, (lvlBlckCnt)
                inc     a
                ld      (lvlBlckCnt), a

                push    hl
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite
                pop     hl

SkipBlock       ld      a, (currntBlckX)
                add     a, 16
                ld      (currntBlckX), a
                ld      a, (currntBlckCl)
                inc     a
                ld      (currntBlckCl), a
                cp      15
                jr      nz, DrawNextBlock

                ld      a, 0
                ld      (currntBlckX), a
                ld      a, (currntBlckY)
                add     a, 8
                ld      (currntBlckY), a
                ld      a, 0
                ld      (currntBlckCl), a

                ld      a, (currntBlckRw)
                inc     a
                ld      (currntBlckRw), a
                cp      7
                jr      nz, DrawNextBlock

                ret

;****************************************************************************************************************
; Update the score
;****************************************************************************************************************
updtScr         ld      a, (hl)                     ; current value of digit.
                add     a, b                        ; add points to this digit.
                ld      (hl), a                     ; place new digit back in string.
                cp      58                          ; more than ASCII value '9'?
                ret     c                           ; no - relax.
                sub     10                          ; subtract 10.
                ld      (hl), a                     ; put new character back in string.
_updtScr0        dec     hl                         ; previous character in string.
                inc     (hl)                        ; up this by one.
                ld      a, (hl)                     ; what's the new value?
                cp      58                          ; gone past ASCII nine?
                ret     c                           ; no, scoring done.
                sub     10                          ; down by ten.
                ld      (hl), a                     ; put it back
                jp      _updtScr0                   ; go round again.

;****************************************************************************************************************
; Reset score to 0000000
;****************************************************************************************************************
rstScr
                ld      de, scrTxt + 5
                ld      b, 7
                ld      a, '0'
_mkZero         ld      (de), a
                inc     de
                djnz    _mkZero
                ld      de, scrTxt                  ; Print the score on the screen
                ld      bc, 12
                call    8252
                ret

;****************************************************************************************************************
; Play click sound with b = length of the loop
;****************************************************************************************************************
plyClck       
                ld      a, 16
                and     248
                out     (254), a
_clickLp0       djnz    _clickLp0
                ld      a, 0
                and     248
                out     (254), a

                ld      a, 16
                and     248
                out     (254), a
_clickLp1       djnz    _clickLp1
                ld      a, 0
                and     248
                out     (254), a
                ret

;****************************************************************************************************************
; Play death sound with b = length of the loop
;****************************************************************************************************************
plyDthSnd
                ld      a, 0
                ld      (23624), a                  ; Set the Border colour BASIC variable to black
                ld      hl,500                      ; starting pitch.
                ld      b,150                       ; length of pitch bend.
_dthSndLp       push    bc
                push    hl                          ; store pitch.
                ld      de,1                        ; very short duration.
                call    949                         ; ROM beeper routine.
                pop     hl                          ; restore pitch.
                inc     hl                          ; pitch going up.
                pop     bc
                djnz    _dthSndLp                   ; repeat.
                ret

;****************************************************************************************************************
; Variables
;****************************************************************************************************************
gmeStte         db      0                           ; 1 = GMESTTE_PLYNG, 2 = GMESTTE_WTNG to Start, 4 = GMESTTE_DEAD
lvlBlckCnt      db      0                           ; Number of blocks in this level

crrntLvl        db      0                           ; Stores the current level

currntBlckRw    db      0                           ; Variables used to store detalis of the blocks when rendering...
currntBlckCl    db      0                           ; ...a level
currntBlckY     db      0
currntBlckX     db      0
crrntLvlAddr    dw      0

; Stores the x, y attr position of the balls collision points
ballMT          dw      0                           ; Middle Top
ballMR          dw      0                           ; Middle Right
ballMB          dw      0                           ; Middle Bottom
ballML          dw      0                           ; Middle Left

lives           db      5                           ; Number of lives each player has at the start of the game
scrnStckPtr     dw      0                           ; Holds the original SP location during screen buffer copy

;****************************************************************************************************************
; Text
;****************************************************************************************************************
                        ; Colour, Yellow, Position, X, Y, Text
scrLblTxt       db      16, 6, 22, 0, 1, 'SCORE'
scrTxt          db      16, 6, 22, 0, 8, '0000000'
lvsLblTxt       db      16, 6, 22, 0, 24, 'LIVES'
lvsTxt          db      16, 6, 22, 0, 30, '5'
gmeOvrTxt       db      16, 2, 17, 2, 22, 15, 11, 'GAME  OVER'

;****************************************************************************************************************
; Object data
;****************************************************************************************************************
                        ; Xpos, XSpeed, Ypos, YSpeed
objctBall       db      0, 1, 0, -2 
                        ; Xpos, Ypos, XSpeed
objctBat        db      121, 175, 4                      

objctMvngBlck1          ; XPos, XSpeed, YPos, YSpeed
                db      76, 2, 115, 0  

objctMvngBlck2          ; XPod, XSpeed, YPos, YSpeed
                db      16, -1, 16, 0   

;****************************************************************************************************************
; Includes
;****************************************************************************************************************
include     Constants.asm
include     Levels.asm
include     Title.asm

                END init
