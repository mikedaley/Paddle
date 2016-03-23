;****************************************************************************************************************
; Paddle - Mike Daley
; 26/09/15
;
; Paddle is a Break Out clone used to learn Z80 Assembly on the ZX Spectrum
;
; Notes
; * Using IM1 so IY can't be used as the IM1 interrupt doesn't prtect it. 
; 
; TODO
; * Implement IM2 to see what can be done with that
; * Implement reading IO Port 0x40FF for the colour attribute currently being read by the ULA. This can cause
;   compatibility issues, but I want to see what can be done by using that rather than HALT to get more time
;   to draw to the screen directly
;****************************************************************************************************************

                org     32768                       ; Put all the code in unconetended memory

;****************************************************************************************************************
; Init
;****************************************************************************************************************           
init 
                ld      a, 0                        ; Set the border colour
                out     (254), a                    
                        
                ld      a, 5                        ; Set the ink colour
                ld      (23693), a  
                
.directDraw     equ     1
    IF !.directDraw
                ; Create a linear y-axis screen memory lookup table
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
                call    shftSprts                   ; Create shifted versions of the sprites being used
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

shftSprts
                ld      hl, SpriteBlock0
                ld      de, SpriteBlock0 + 3 * 8
                ld      b, 3
                ld      c, 8
                call    prShft

                ; Shift Sprite Ball
                ld      hl, SmallBallData0
                ld      de, SmallBallData0 + 2 * 5
                ld      b, 2
                ld      c, 5
                call    prShft

                ; Shift Sprite Bat
                ld      hl, SpriteBatData0
                ld      de, SpriteBatData0 + 4 * 8
                ld      b, 4
                ld      c, 8
                call    prShft

                ld      hl, SpriteBatData1
                ld      de, SpriteBatData1 + 4 * 8
                ld      b, 4
                ld      c, 8
                call    prShft

                ld      hl, SpriteBatData2
                ld      de, SpriteBatData2 + 4 * 8
                ld      b, 4
                ld      c, 8
                call    prShft

                ; Score 115 Sprite
                ld      hl, Score115_0
                ld      de, Score115_0 + 3 * 8
                ld      b, 3
                ld      c, 8
                call    prShft

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
; Main loop
;****************************************************************************************************************
mnLp 
                ld      a, (gmeStte)                ; Check the game state

_chckGmeSttePlyng                                   ; *** Game state PLAYING
                cp      GMESTTE_PLYNG               ; Is the game state PLAYING
                jr      nz, _chckGmeStteWtng        ; If not then check if the state is WAITING
                call    rdCntrlKys                  ; Read the keyboard
                call    mvBll                       ; Move the ball
                call    drwBll                      ; Draw the ball

                call    updtScrSprts
                call    drwScr

                call    updtBtAnmtnFrm
                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

                call    drwBll                      ; Erase the ball (XOR)
                call    drwScr
                call    drwBt                       ; Erase the bat (XOR)
                ld      a, (lvlBlckCnt)             ; Load A with the number of blocks that are still visible
                cp      0                           ; Check the number of blocks against 0
                jr      nz, mnLp                    ; If not yet 0 then loop
                ld      a, GMESTTE_NXTLVL           ; No more blocks yet so set the game state to NEXT LEVEL
                ld      (gmeStte), a                ; Save the game state and loop
                jp      mnLp

_chckGmeStteWtng                                    ; *** Game state WAITING
                cp      GMESTTE_WTNG                ; Is the game state WAITING    
                jp      nz, _chckGmeStteLstLfe      ; If not then check if the state is PLAYER DEAD
                call    rdCntrlKys                  ; Read the keyboard

                ld      a, (objctBat + BTYPS)       ; Get the bats Y position
                ld      b, BLLPXLHGHT               ; Get the pixel height of the ball
                sub     b                           ; Calulcate the bats Y pos minus the balls height putting the ball ontop of the bat
                ld      (objctBall + BLLYPS), a     ; Update the balls Y Position with the bats Y position 
                ld      a, (objctBat + BTXPS)       ; Load the bats X pos
                ld      b, BTPXLWDTH / 2 - BLLPXLWIDTH / 2  ; Calc the X pos middle of the bat
                add     a, b                        ; Calc the new X pos for the ball so its in the middle of the bat
                ld      (objctBall + BLLXPS), a     ; Save the new X pos for the ball
                
                call    updtBtAnmtnFrm
                call    drwBll                      ; Draw the ball

                call    updtScrSprts
                call    drwScr

                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

                call    drwBll                      ; Erase the ball (XOR)
                call    drwScr
                call    drwBt                       ; Erase the bat (XOR)
                ld      bc, 32766                   ; Want to see if SPACE has been pressed
                in      a, (c)                      ; Read the port
                rra                                 ; Rotate Right
                jp      c, mnLp                     ; If SPACE is not pressed then keep looping
                ld      a, GMESTTE_PLYNG            ; Otherwise update the game state to GMESTTE_PLYNG
                ld      (gmeStte), a                ; Save the game state
                jp      mnLp                        ; Loop

_chckGmeStteLstLfe                                  ; *** Game state LOST LIFE
                cp      GMESTTE_LSTLFE              ; Is the game state LOST LIFE
                jr      nz, _gmeStteNxtLvl          ; If not then check if the state is NEXT LEVEL
                ld      a, (lives)                  ; Load A with the lives left
                dec     a                           ; -1 from lives

                push    af                          ; Save AF
                ld      (lives), a                  ; Save the new number of lives
                add     a, 48                       ; Add 48 to the number of lives to get the character code for the lives number
                ld      (lvsTxt + 5), a             ; Update the lives text with the new lives character at position 5 in the string

                ld      de, lvsTxt                  ; Load DE with the levels text
                ld      bc, 6                       ; Set attribute to yellow ink on black background
                call    8252                        ; ROM Print
                pop     af                          ; Restore AF
                cp      0                           ; Check if the players lives have reached 0 
                jp      z, _setGmeStteDead          ; Jump to set the game state to DEAD

                call    rstBt                       ; Reset the bats location
                call    plyDthSnd                   ; Play a death sound 

                ld      a, GMESTTE_WTNG             ; Set the game state to WAITING
                ld      (gmeStte), a                ; Save the game state
                jp      mnLp
_setGmeStteDead
                ld      a, GMESTTE_DEAD 
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
                ld      b, 0                        ; Set b to 0                            
                ld      c, (hl)                     ; Load C with the length of the string to print
                ld      d, h                        ; Load HL the address of the text...
                ld      e, l                        ; ...into DE
                inc     de                          ; + 1 DE which is the start of the actual string
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
                cp      GMESTTE_DEAD
                jp      nz, mnLp
                ld      de, gmeOvrTxt
                ld      bc, 17
                call    8252
                call    watFrSpc
                call    clrScrn
                call    drwBrdrs
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
                call    rstBt
                jp      mnLp

;****************************************************************************************************************
; Update bate animation
; Updates the bats sprite frame number which is used to identify which sprite frame to draw
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
updtBtAnmtnFrm
                ld      a, (objctBat + 3)           ; Point DE at the animation delay counter
                inc     a                           ; Increment the frame count
                ld      (objctBat + 3), a           ; Save the new delay amount    
                cp      6                           ; Check the delay (1/50 * n)
                ret     nz                          ; and return if we've not reached the delay value
                ld      a, 0                        ; Delay has been reached so reset the delay...
                ld      (objctBat + 3), a           ; ...and save it
                ld      a, (objctBat + 4)           ; Load A with the current frame count
                inc     a                           ; Increment the counter
                cp      3                           ; Compare it against the max value allowed...
                jp      nz, _svBtFrm                ; ...and save the new frame count if the max has not been reached
                ld      a, 0
_svBtFrm
                ld      (objctBat + 4), a           ; Save the new frame number
                ret                                 ; Return

;****************************************************************************************************************
; Update Score Sprites
; Updates the score sprites that are displayed on screen when a block has been destroyed. A table is stored at
; objectScore which is used to store the x, y, yspeed and timer for each score sprite that is visible. A score
; is deemed to be visible if the timer is not visible.
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
updtScrSprts
                ld      b, 5                        ; Upto to five scores can be alive at the same time
                ld      hl, objctScore              ; Point HL at the score sprite table
_nxtScr         ld      a, (hl)                     ; Load A with the timer value for the score
                cp      0                           ; Is the timer 0?
                jp      nz, _updtScr                ; If not then update it as its active...
                inc     hl                          ; ...otherwise point HL at the next score object
                inc     hl
                inc     hl
                djnz    _nxtScr                     ; Loop if there are score objects left
                ret
_updtScr
                inc     a                           ; Increment the timer
                cp      25                          ; Has the timer reached 0.5 seconds (1/50 * 25)
                jp      z, _rstScrTmr               ; If the timer has reached its max then reset it... 
                ld      (hl), a                     ; ...otherwise save the new timer value
                inc     hl                          ; Point HL at the Ypos of the score... 
                dec     (hl)                        ; ...and decrement it so the score moves up the screen
                inc     hl                          ; Move HL to the next score object
                inc     hl
                djnz    _nxtScr                     ; Loop if there are score objects letf
                ret
_rstScrTmr
                ld      a, 0                        ; Load A with 0 so that it can...
                ld      (hl), a                     ; ...be saved in the score object marked it inactive
                inc     hl                          ; Point HL at the next score object
                inc     hl
                inc     hl
                djnz    _nxtScr                     ; Loop if there are score objects left
                ret

;****************************************************************************************************************
; Find Inactive Score Sprite
; Returns the address of an inactive score sprite that can be used to display the score for the tile just hit
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   A = 0 for none found or 
;   HL = Address of available score sprite
;****************************************************************************************************************
fndInctvScrSprt
                ld      b, 5                        ; Five scores available
                ld      hl, objctScore              ; Point HL at score object table
_chkNxtScr      ld      a, (hl)                     ; Load A with the timer of the first score object
                cp      0                           ; If it is 0 then...
                jp      z, _fndScrSprt              ; ...its available so return the address in HL
                inc     hl                          ; Move HL to the next score object
                inc     hl                          ; Using INC HL as it is saving 3 t-states over using ADD HL, DE
                inc     hl
                djnz    _chkNxtScr                  ; Loop if B > 0
                ld      a, 0                        ; Nothing found so set A = 0...
                ret
_fndScrSprt
                inc     a                           ; Found a free score so set its timer to 1...
                ld      (hl), a                     ; ...and save it back into the table
                ret                                 ; HL is already pointing at the current object so return

;****************************************************************************************************************
; Draw Title screen
; Loads the title screen bitmap and attribute data into the screen file
;
; Entry Registers:
;   NONE
; Registers Used:
;   B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwTtlScrn
                ld      de, BTMPSCRNSDDR
                ld      hl, ttleScrn
                ld      bc, BTMPSCRSZ + ATTRSCRNSZ
                ldir
                ret

;****************************************************************************************************************
; Draw borders
; Draws the left, top and right borders of the playing area
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
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
; Draw Scores
; Loop through the score sprite table and draw any sprites that have a timer value > 0

; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwScr 
                ld      b, 5                        ; There are a maximum of five scores that can be drawn
                ld      hl, objctScore              ; Point HL at the start of the score object table
_chkScrActv
                ld      a, (hl)                     ; Get the timer for the first score object
                cp      0                           ; Check it against 0
                jp      nz, _drwCrrntScr            ; If its not zero then its active so draw it
                inc     hl
                inc     hl
                inc     hl
                djnz    _chkScrActv                 ; Loop if there are more scores to check
                ret                                 ; Finished

_drwCrrntScr
                push    bc                          ; Save BC as its holding our score loop count in B
                push    hl                          ; Save HL as this is our pointer into the object table
                inc     hl                          ; Point HL at the Y position of the score
                ld      a, (hl)                     ; Load A with the balls Y position
                ld      c, a                        ; Load A into C
                inc     hl                          ; Point HL at the X position of the score
                ld      a, (hl)                     ; Load A with the balls X position
                ld      b, a                        ; Load A into B
                ld      de, Score115                ; Point DE to the ball sprite data
                call    Draw_24x8_Sprite            ; Call the 16x4 pixel sprite routine
                pop     hl                          ; Restore HL
                pop     bc                          ; Restore BC
                inc     hl
                inc     hl
                inc     hl
                djnz    _chkScrActv                 ; Loop if there are more scores to check
                ret                                 ; Finished

;****************************************************************************************************************
; Draw Ball Sprite
; Draws the ball sprite at its current location
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwBll 
                ld      de, SmallBallData           ; Point DE to the ball sprite data
                ld      a, (objctBall + BLLXPS)     ; Load A with the balls X position
                ld      b, a                        ; Put A into B
                ld      a, (objctBall + BLLYPS)     ; Load A with the balls Y position
                ld      c, a                        ; Load C with A so B = X, C = Y
                call    Draw_16x5_Sprite            ; Call the 16x4 pixel sprite routine
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the bat at its current location
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwBt 
                ld      de, SpriteBatData           ; Point DE to the ball sprite data
                ld      a, (objctBat + 4)           ; Load the current animation frame for the ball
                cp      0                           ; If its zero...
                jp      z, _drwBt                   ; ...then just go a draw the bat...
                ld      b, a                        ; Load B with the frame number
                ld      hl, 8                       ; Start off by setting HL to 8
_frmBtLp                          
                add     hl, hl
                djnz    _frmBtLp
                add     hl, de
                push    hl
                pop     de
_drwBt          ld      a, (objctBat + BTXPS)       ; Load A with the bats X position
                ld      b, a                        ; Put A into B
                ld      a, (objctBat + BTYPS)       ; Load A with the bats Y position
                ld      c, a                        ; Load A with A so B = X, C = Y
                call    Draw_32x8_Sprite            ; Call the 32x8 pixel sprite routine
                ret

;****************************************************************************************************************
; Draw Moving Block
; Draws a moving block at its current location
;
; Entry Registers:
;   IX = Points to moving block object data
; Registers Used:
;   A, B, C
; Returned Registers:
;   NONE
;******************************************************1**********************************************************
drwMvngBlck 
                ld      de, SpriteBlockData         ; Point DE to the ball sprite data
                ld      a, (ix + BLLXPS)            ; Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (ix + BLLYPS)
                ld      c, a
                call    Draw_24x8_Sprite
                ret

;************************************************************************************************************************
; Wait For Space
; Loops until the space key is pressed
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, C
; Returned Registers:
;   NONE
;************************************************************************************************************************
watFrSpc
                ld      bc, 32766
                in      a, (c)
                rra 
                ret     nc
                jp      watFrSpc

;************************************************************************************************************************
; Read Control Keys
; Checks the control keys used in the game i.e. 1 = left, 2 = right and if either of these keys are pressed then the bats
; current location is updated based on the key being pressed
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, F, B, C, H, L
; Returned Registers:
;   NONE
;************************************************************************************************************************
rdCntrlKys 
                ; Check if keys one 1 or 2 have been pressed which move the bat
                ld      hl, objctBat                ; HL = X Position
                ld      bc, 63486                   ; Load BC with the port to read 5, 4, 3, 2, 1
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; Outermost bit = key 1
                jp      nc, _mvBtLft                ; Move the bat left
                rra                                 ; Next bit is key 2
                jp      nc, _mvBtRght               ; Move the bat right
                ret
_mvBtLft     
                ld      a, (hl)                     ; Put X pos into A
                inc     hl                          ; Move to the X Speed position 
                sub     (hl)                        ; Subtract the X speed from the X pos
                dec     hl                          ; Move HL to the X pos
                cp      BTMXLFT                     ; Check if we are past the left hand edge of the screen
                jp      c, _btHtLftEdg              ; and jump if we are jump to hitLeftEdge
                ld      (hl), a                     ; Update the X position with A
                ret     
_btHtLftEdg         
                ld      (hl), BTMXLFT               ; Hit the edge so set the X pos to the BTMXLFT value
                ret 
_mvBtRght    
                ld      a, (hl)                     ; Put X pos into A
                inc     hl                          ; Move HL to the X Speed
                add     a, (hl)                     ; Add the X speed to the X pos
                dec     hl                          ; Move HL to the X Pos
                cp      BTMXRGHT                    ; Check if the bat is past left edge
                jp      nc, _btHtRghtEdg            ; and jump if it is
                ld      (hl), a                     ; Update the X Position with A
                ret     
_btHtRghtEdg         
                ld      (hl), BTMXRGHT              ; Hit the edge so set the X pos to the BTMXRGHT value
                ret

;************************************************************************************************************************
; Update Moving Block
; Updates the position of the moving block based on the blocks current +/- speed
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E
; Returned Registers:
;   NONE
;************************************************************************************************************************   
updtMvngBlck
                ld      a, (ix + BLLXPS)
                add     a, (ix + BLLXSPD)
                ld      (ix + BLLXPS), a
                cp      SCRNRGHT - BLCKWDTH
                jp      nc, _blckHtEdg
                cp      SCRNLFT
                jp      c, _blckHtEdg
                ret

_blckHtEdg
                ld      a, (ix + BLLXSPD)
                neg
                ld      (ix + BLLXSPD), a
                ret

;****************************************************************************************************************
; Draw 8x8 pixel sprite
; Draws a sprite that is 8x8 pixels
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
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
; Draw 16x4 pixel sprite
; Draws a sprite that is 16x4 pixels
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
;****************************************************************************************************************
Draw_16x5_Sprite
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

    REPT 5                                          ; Repeat this code 8 times for the 8 pixles rows of a ball sprite
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
; Draw 16x8 pixel sprite
; Draws a sprite that is 16x8 pixels
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
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
; Draw 24x8 pixel sprite
; Draws a sprite that is 24x8 pixels
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
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
; Draw 32x8 pixel sprite
; Draws a sprite that is 32x8 pixels
;
; Entry Registers:
;   DE = Pointer to the sprite data to be drawn
;   BC = Pixel location, B = X, C = Y
; Used Registers:
;   A, B, C, D, E, H, L, IX
; Returned Registers:
;   NONE
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
; Get Character Location 
; Convert a pixel location into a char x, y location
;
; Entry Registers:
;   DE = D = pixel X, E = pixel Y
; Used Registers:
;   A, B, C
; Returned Registers:
;   B = X char position
;   C = Y char position 
;****************************************************************************************************************
getChrLctn 
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
; Move Ball
; Responsible for bouncing the ball sprite around the screen, detecting when it hits the edges of the screen
; and any tile objects
;
; Entry Registers:
;   DE = D = pixel X, E = pixel Y
; Used Registers:
;   A, B, C
; Returned Registers:
;   B = X char position
;   C = Y char position ;
;****************************************************************************************************************
mvBll 
                ld      hl, objctBall               ; Use HL to hold the ball object as using IX is expensive                
_mvX
                ld      a, (hl)                     ; First position in the structure is the X Position
                inc     hl                          ; Move to the X Speed
                add     a, (hl)                     ; Update the balls position using its speed 
                dec     hl                          ; Move HL back to the balls position 
                ld      (hl), a                     ; and save the new position 

                cp      SCRNRGHT - BLLPXLWIDTH      ; Has the ball hit the right edge of the screen?
                jr      nc, _bncLft                 ; Yes

                cp      SCRNLFT                     ; Has the ball hit the left edge of the screen?
                jr      c, _bncRght                 ; Yes

_mvY           
                inc     hl                          ; Point HL at the...
                inc     hl                          ; ...Y positon 
                ld      a, (hl)                     ; Load the balls Y Position into A...
                inc     hl                          ; ...then point HL at the Y Speed...
                add     a, (hl)                     ; ...and add it to the Y Position
                dec     hl                          ; Point HL to the balls Y Postion 
                ld      (hl), a                     ; Save the balls new position 

                cp      SCRNBTTM
                jr      nc, _htBttm                 ; A > SCRNBTTM means the ball has reached the bottom of the screen

                inc     hl                          ; Move HL to the Y Speed
                ld      a, (hl)                     ; Load the Y Speed into A to check if its moving up or down the screen
                cp      0                           ; Is the ball moving down the screen?
                jp      m, _chkTp                   ; If not then check the balls position with the top of the screen
                call    chkBtCllsn                  ; Otherwise ball is moving down the screen so check if its hit the bat
                call    _updtBllChrPs               ; Finally update the balls character x, y position 
                ret

_chkTp
                dec     hl                          ; Point HL to the Y Position
                ld      a, (hl)                     ; Put the Y pos into A
                cp      SCRNTP                      ; Has the ball reached the top of the screen?
                jr      c, _bncDwn                  ; Yes, then bounce down the screen
                call    _updtBllChrPs               ; Finally update the balls character x, y position 
                ret 

_bncDwn
                ld      a, SCRNTP
                ld      (hl), a                     ; Update the Y Position so the ball is up against the top of the screen
                inc     hl                          ; Point HL at the balls Y Speed
                ld      a, (hl)                     ; Load the Y Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                call    _updtBllChrPs
                ret

_htBttm
                ld      a, GMESTTE_LSTLFE
                ld      (gmeStte), a
                jp      _updtBllChrPs
                ret

_bncLft
                inc     hl
                ld      a, (hl)                     ; Load the X Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                dec     hl                          ; Move HL to the X Position
                ld      a, SCRNRGHT - BLLPXLWIDTH    ; Make sure the ball sits right up against the right edge of the screen
                ld      (hl), a                     ; Save the balls new X position
                jp      _mvY                        ; Check for a bounce on the y-axis

_bncRght
                inc     hl
                ld      a, (hl)                     ; Load the X Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                dec     hl                          ; Move HL to point to the X Position 
                ld      a, SCRNLFT                  ; Make sure the ball sits right up against the left edge of the screen
                ld      (hl), a                     ; Save the balls new X position
                jp      _mvY                        ; Check for a bounce in the y-axis

;****************************************************************************************************************
; Update Balls collision points
; Four variables store collision points on the ball, these are middle top, middle right, middle bottom and middle left.
; 
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
_updtBllChrPs                                       ; Update the balls character position used in block collision detection
                ld      hl, objctBall               ; Load HL with the address of the ball object data
                ld      a, (hl)                     ; Load A with the X position of the ball
                add     a, BLLPXLWIDTH / 2          ; Increment A by half the width of the ball sprite 
                ld      d, a                        ; Store A in D 
                inc     hl                          ; Point HL at the...
                inc     hl                          ; ...Y position of the ball
                ld      e, (hl)                     ; Load the Y position into E
                call    getChrLctn                  ; Get the character location based on D = X and Y = E
                ld      (ballMT), bc                ; The character location is returned in BC so we save that

                dec     hl                          ; Point HL at...
                dec     hl                          ; X position of the ball object
                ld      a, (hl)                     ; Load A with the balls X position...
                add     a, BLLPXLWIDTH              ; ...and add the width of the ball to find the right hand edge
                ld      d, a                        ; Save A to D
                inc     hl                          ; Point HL at...
                inc     hl                          ; ...balls Y position
                ld      a, (hl)                     ; Load A with the Y position
                add     a, BLLPXLHGHT / 2           ; Add half the height of the ball sprite to Y
                ld      e, a                        ; Save A in E
                call    getChrLctn                  ; Get the character location based on D = X and E = Y
                ld      (ballMR), bc                ; The character locatiojn is returned in BC so we save that

                dec     hl
                dec     hl
                ld      a, (hl)                     ; Middle Bottom
                add     a, BLLPXLWIDTH / 2
                ld      d, a
                inc     hl
                inc     hl
                ld      a, (hl)
                add     a, BLLPXLHGHT     
                ld      e, a
                call    getChrLctn
                ld      (ballMB), bc

                dec     hl
                dec     hl
                ld      d, (hl)                     ; Middle Left
                inc     hl
                inc     hl
                ld      a, (hl)
                add     a, BLLPXLHGHT / 2
                ld      e, a
                call    getChrLctn
                ld      (ballML), bc

                call    chckBlckCllsn               ; Now go see if the ball has hit something :)

                ret

;****************************************************************************************************************
; Check Bat Collision
; Responsible for checking if the ball has hit the bat. If the ball has hit then bat then depending on the
; y position of the ball on the bat the balls x speed is updated along with its y speed being reversed
;
; Entry Registers:
;   DE = D = pixel X, E = pixel Y
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
chkBtCllsn 
                ld      hl, objctBall              ; Point HL at the ball object

                ; First check if the ball has already passed the top of the bat
                ld      a, (objctBat + BTYPS)       ; Load A with the bat.y
                ld      b, a                        ; Switch B and A
                inc     hl                          ; Point HL at... 
                inc     hl                          ; ...ball.y 
                ld      a, (hl)                     ; Load A with the ball.y
                cp      b                           ; Compare it against the bat.y
                ret     nc                          ; Ball is already passed the top of the bat

                ; Has the ball reached the top of the bat? If not then no point in doing further checks
                add     a, BLLPXLHGHT - 1           ; We need to check if the bottom of the ball has hit/passed bat.y
                cp      b
                ret     c                           ; If not then we are done    

_chkHrzntlPstn                                      
                ; To check where on the bat the ball has collided we put the ball into bat space coordinates
                ; by subtracting the x position of the bat from the x position of the ball
                dec     hl                          ; Point HL at the...
                dec     hl                          ; ...balls X position 
                ld      a, (objctBat + BTXPS)       ; Load A with the bats X pos 
                ld      b, a                        ; Store A in B ready
                ld      a, (hl)                     ; Load A with the balls X position 
                add     a, BLLPXLWIDTH / 2          ; Move to the horizontal center of the ball
                sub     b                           ; Subtract the bat.x from ball.x
                ret     c                           ; A < 0 so the ball is left of the bat
                cp      BTPXLWDTH                   ; Check if ball.x > bat.pixel_width
                ret     nc                          ; If it is then ball to the right of the bat

                push    af                          ; Save A as we are going to play a click which uses it
                ld      b, 20                       ; Load B with the length of the click 
                call    plyClck                     ; Play the click

                ; Check the balls x direction and based on that perform the bats collision checks
                inc     hl                          ; Point HL at the X speed of the ball
                ld      a, (hl)                     ; Load the X speed into A
                cp      0                           ; See which direction its moving    
                jp      m, _bllMvngLft              ; A < 0 means left otherwise right

_bllMvngRght  
                pop     af                          ; Restore A which holds ball.x in bat space
                push    hl
                cp      6                           ;
                jr      nc, _rArea2
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 0
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea2         cp      12
                jr      nc, _rArea3
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea3         cp      18
                jr      nc, _rArea4
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea4         cp      24
                jr      nc, _bncUp
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 3
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_bllMvngLft  
                pop     af
                push    hl
                cp      6
                jr      nc, _lArea2
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 3
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea2         cp      12
                jr      nc, _lArea3
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea3         cp      18
                jr      nc, _lArea4
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea4         cp      24
                jr      nc, _bncUp
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 0
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a

_bncUp 
                ld      a, (objctBat + BTYPS)  ; Update the Y pos of the ball so that it rests ontop of the bat
                sub     BLLPXLHGHT
                inc     hl
                ld      (hl), a
                inc     hl
                ld      a, (hl)
                neg                                 ; Change the balls Y direction
                ld      (hl), a   
                ret 

;****************************************************************************************************************
; Check Block Collision
; Check the collisions points around the ball against the attribute buffer and if a collision is found then Remove
; the block and bounce the ball.  By checking each collision point around the ball sprite we can find out which
; part of the ball has hit a tile. This then allows us to update the sprites X or Y speed causing the ball to 
; appear to bounce off the tile. A collision is identified if the attribute at the collision point is not 5 which
; represents a black background and cyan ink.
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, D, E
; Returned Registers:
;   NONE
;****************************************************************************************************************
chckBlckCllsn 
                ld      a, (objctBall + BLLYSPD)    ; Load the Y Speed of the ball
                cp      0                           ; Compare it with 0 to find out if the balls is moving up...
                jp      p, _mddlBttm                ; or down the screen, if moving down then no need to check the top collision

                ld      de, (ballMT)                ; Load the middle collison point into DE, D = Y, E = X
                push    de                          ; Save DE
                call    getChrctrAttr               ; Get the character attribute at DE
                pop     de                          ; Restore DE
                cp      5                           ; Is the attribute returned Cyan on black...
                jr      z, _mddlBttm                ; ...if so then check the right collision point as there is no block
                
                ld      a, (objctBall + BLLYSPD)    ; Load A with the ball.ySpeed
                neg                                 ; Reverse the ball.ySpeed...
                ld      (objctBall + BLLYSPD), a    ; ...and save it back with the ball data
                call    rmvBlck                     ; Remove the block that has just been hit

_mddlBttm
                ld      de, (ballMB)
                push    de
                call    getChrctrAttr
                pop     de
                cp      5
                jr      z, _mddlRght
                ld      a, (objctBall + BLLYSPD)
                neg
                ld      (objctBall + BLLYSPD), a   
                call    rmvBlck

_mddlRght 
                ld      de, (ballMR)
                push    de
                call    getChrctrAttr
                pop     de
                cp      5
                jr      z, _mddlLft
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a
                call    rmvBlck

_mddlLft 
                ld      de, (ballML)
                push    de
                call    getChrctrAttr
                pop     de
                cp      5
                ret     z
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a   
                call    rmvBlck
                ret

;****************************************************************************************************************
; Remove the block that contains the x,y provided D = Y and E = X
;****************************************************************************************************************
rmvBlck
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
                ld      de, scrTxt                  ; Print the score on the screen
                ld      bc, 12
                call    8252
                pop     bc
                pop     de

                ld      a, (lvlBlckCnt) 
                dec     a                           ; Decrement the number of blocks 
                ld      (lvlBlckCnt), a                    

                ; Remove the block
                ld      a, e
                and     1                           ; Check to see if the number is _odd
                cp      0
                jr      z, _even

_odd             
                ld      a, 5
                push    de
                call    setChrctrAttr
                pop     de
                ld      a, e
                sub     1
                ld      e, a
                ld      a, 5
                push    de
                call    setChrctrAttr
                pop     de

                ld      a, e
                add     a, a
                add     a, a
                add     a, a
                ld      b, a

                ld      a, d
                add     a, a
                add     a, a
                add     a, a
                ld      c, a
                push    bc
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite

                call    fndInctvScrSprt             ; Find an available score sprite
                cp      0                           ; Check if A is equal to 0 and...
                ret     z                           ; ...return if it is
                pop     bc                          ; Save BC which holds the pixel location of the block
                inc     hl                          ; Point HL at the Y position of the score object
                ld      a, c                        ; Load B into A...
                ld      (hl), a                     ; ...and then save into the object 
                inc     hl                          ; Move HL to the X pos...
                ld      a, b                        ; ...and save the X pos...
                ld      (hl), a                     ; ...into the score object

                ret

_even           
                ld      a, 5
                push    de
                call    setChrctrAttr
                pop     de
                inc     e
                ld      a, 5
                push    de
                call    setChrctrAttr
                pop     de
                dec     e
                ld      a, e
                add     a, a
                add     a, a
                add     a, a
                ld      b, a

                ld      a, d
                add     a, a
                add     a, a
                add     a, a
                ld      c, a
                push    bc
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite

                call    fndInctvScrSprt             ; Find an available score sprite
                cp      0                           ; Check if A is zero...
                ret     z                           ; ...and return if it is
                pop     bc                          ; Save BC which holds the pixel location of the block
                inc     hl                          ; Point HL at the Y position of the score object
                ld      a, c                        ; Load B into A...
                ld      (hl), a                     ; ...and then save into the object 
                inc     hl                          ; Move HL to the X pos...
                ld      a, b                        ; ...and save the X pos...
                ld      (hl), a                     ; ...into the score object

                ret

;****************************************************************************************************************
; Set the attribute at the given X, Y
; D = X, E = Y, A = value to set
;****************************************************************************************************************
setChrctrAttr 
                ld      h, 0                        ; Get the Y pos from the corner
                ld      l, d

                add     hl, hl                      ; Multiply the Y position by 32
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl

                ld      b, 0                        ; Get the X position
                ld      c, e
                add     hl, bc                      ; Add it to the Y position 

                ld      de, ATTRSCRNADDR            ; Add on the base ATTR screen address
                add     hl, de

                ld      (hl), a                     ; Load the attribute at HL
                ret

;****************************************************************************************************************
; Get the attribute at the given X, Y
; D = X, E = Y, returns A = given attribute
;****************************************************************************************************************
getChrctrAttr 
                ld      h, 0                        ; Get the Y pos from the corner
                ld      l, d

                add     hl, hl                      ; Multiply the Y position by 32
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl

                ld      b, 0                        ; Get the X position
                ld      c, e
                add     hl, bc                      ; Add it to the Y position 

                ld      de, ATTRSCRNADDR            ; Add on the base ATTR screen address
                add     hl, de

                ld      a, (hl)                     ; Load the attribute at HL
                ret

;****************************************************************************************************************
; Reset the bats X pos to the center of play area
;****************************************************************************************************************
rstBt    
                ld      a, 112
                ld      (objctBat + BTXPS), a
                ld      a, -2
                ld      (objctBall + BLLYSPD), a
                ret

;****************************************************************************************************************
; Load Level
; A = Level to load 
;****************************************************************************************************************
ldLvl 
                ld      de, lvlLkup                 ; Load DE with the address of the Level Loopup Table
                ld      a, (crrntLvl)               ; Load A with the level number to load
                ld      l, a
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the level lookup table entries are words
                add     hl, de                      ; Add base address of level lookup table which is held in DE
                ld      e, (hl)                     ; Pop the address at HL into DE
                inc     hl
                ld      d, (hl)
                ld      (crrntLvlAddr), de          ; Store away 
                ld      hl, (crrntLvlAddr)          ; and load HL with that address

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

                ; Draw the blocks based on the levels block lookup table
_nxtBlckRw      ld      a, 0
                ld      (currntBlckCl), a
                ld      (currntBlckRw), a
                ld      (currntBlckX), a
                ld      a, 32
                ld      (currntBlckY), a

_drwNxtBlck     ld      bc, (currntBlckY)
                ld      a, (hl)
                inc     hl
                cp      1
                jr      nz, _skpBlck

                ld      a, (lvlBlckCnt)
                inc     a
                ld      (lvlBlckCnt), a

                push    hl
                ld      de, SpriteBlockData
                call    Draw_24x8_Sprite
                pop     hl

_skpBlck        ld      a, (currntBlckX)
                add     a, 16
                ld      (currntBlckX), a
                ld      a, (currntBlckCl)
                inc     a
                ld      (currntBlckCl), a
                cp      15
                jr      nz, _drwNxtBlck

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
                jr      nz, _drwNxtBlck

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

prShftWdth      db      0                           ; Holds the width of the sprite to be shifted
prShftHght      db      0                           ; Holds the height of the sprite to be shifted
prShftSize      dw      0                           ; Holds the size of a sprite to shift in bytes

;****************************************************************************************************************
; Text
;****************************************************************************************************************
                        ; Colour, Yellow, Position, X, Y, Text
scrLblTxt       db      16, 6, 22, 0, 1, 'SCORE'
scrTxt          db      16, 6, 22, 0, 8, '0000000'
lvsLblTxt       db      16, 6, 22, 0, 24, 'LIVES'
lvsTxt          db      16, 6, 22, 0, 30, '5'
gmeOvrTxt       db      16, 7, 17, 2, 22, 15, 11, 'GAME  OVER'

;****************************************************************************************************************
; Object data
;****************************************************************************************************************
                        ; Xpos, XSpeed, Ypos, YSpeed, Delay, Frame
objctBall       db      0, 1, 0, -2, 0, 0
    
                        ; Xpos, XSpeed, Ypos
objctBat        db      112, 4, 175         
                db      0 ; Delay counter used to time how long each frame should be visible
                db      0 ; Animation Frame

objctMvngBlck1          ; XPos, XSpeed, YPos, YSpeed
                db      76, 2, 115, 0  

objctMvngBlck2          ; XPos, XSpeed, YPos, YSpeed
                db      16, -1, 16, 0

                        ; Timer, Ypos, Xpos
objctScore      db      0, 0, 0
                ds      4 * 4   

;****************************************************************************************************************
; Includes
;****************************************************************************************************************
include     Constants.asm
include     Levels.asm
include     Title.asm

                END init
