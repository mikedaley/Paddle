 ;****************************************************************************************************************
; Paddle - Mike Daley
; 26/09/15
;
; Paddle is a Break Out clone used to learn Z80 Assembly on the ZX Spectrum
; 
; TODO
; * Implement reading IO Port 0x40FF for the colour attribute currently being read by the ULA. This can cause
;   compatibility issues, but I want to see what can be done by using that rather than HALT to get more time
;   to draw to the screen directly
; * Improve sound so that it does not use the ROM routine. This should allow part of a given sound FX to be
;   generated each frame. The ROM routine blocks until its complete which causes everything to pause...not good
; * Power ups/downs:
;       - Beer Bottle which makes paddle controls work backwards
;       - Clock which slows down time
;       - Multi ball powerups
;
;****************************************************************************************************************

;*******************************************************************************************
;Constants
;*******************************************************************************************
CONTENDEDADDR           equ                 24064   ; Address to load contended memory contents
CODESTART               equ                 32768   ; Address to load fast code

SCRNBFFR                equ                 57856   ; Address of screen back buffer    
BTMPSCRNSDDR            equ                 16384   ; Address of bitmap screen file
BTMPSCRSZ               equ                 6144    ; Size of the bitmap screen
ATTRSCRNADDR            equ                 22528   ; Address of screen attribute data
ATTRSCRNSZ              equ                 768     ; Size of the screen attribute data
SCRNSZ                  equ                 BTMPSCRSZ + ATTRSCRNSZ

; Screen boundaries in pixels used when bouncing the ball
SCRNLFT                 equ                 16
SCRNRGHT                equ                 240
SCRNTP                  equ                 17
SCRNBTTM                equ                 180
            
; Offsets into the BALL structure       
BLLXPS                  equ                 0
BLLXSPD                 equ                 1
BLLYPS                  equ                 2
BLLYSPD                 equ                 3
            
; BALL constants            
BLLPXLHGHT              equ                 5
BLLPXLWIDTH             equ                 5
BLLHLFWIDTH             equ                 3
            
; Bat constants
BTMXRGHT                equ                 SCRNRGHT - BTPXLWDTH ; Furthest pixel to the right the paddle can be drawn
BTMXLFT                 equ                 SCRNLFT       ; Furthes pixel to the left the bat can be drawn

; Offsets into the BCC_AT structure        
BTXPS                   equ                 0
BTSPD                   equ                 1
BTYPS                   equ                 2
BTANMTONDLY             equ                 3
BTANMTONFRM             equ                 4
            
; BCC_AT constants         
BTPXLHGHT               equ                 8
BTPXLWDTH               equ                 24
BTHLFWDTH               equ                 BTPXLWDTH / 2
            
; Block constants           
BLCKWDTH                equ                 16
            
; Game States           
GMESTTE_PLYNG           equ                 1
GMESTTE_WTNG            equ                 2
GMESTTE_DEAD            equ                 4
GMESTTE_DSPLYLVL        equ                 8
GMESTTE_NXTLVL          equ                 16
GMESTTE_LSTLFE          equ                 32

; Colours 
BLACK                   equ                 0
BLUE                    equ                 1
RED                     equ                 2
MAGENTA                 equ                 3
GREEN                   equ                 4
CYAN                    equ                 5
YELLOW                  equ                 6
WHITE                   equ                 7
BRIGHT                  equ                 64


CC_PAPER                equ                 17      ; RST 10 control codes for colour
CC_INK                  equ                 16
CC_AT                   equ                 22      ; RST 10 control codes for location
CC_FLASH                equ                 18
CC_BRIGHT               equ                 19

NUMPRTCLS               equ                 6

ROMPRINT                equ                 8252

; Powerups
PWRUP_BEER              equ                 1

;****************************************************************************************************************
; Start of Contended Memory
;****************************************************************************************************************           

                org         CONTENDEDADDR           ; Set origin just above the system variables in contended memory

                include     Menu.asm                ; Load the main menu code
                include     Font.asm                ; Load the custom font graphics
                include     Levels.asm              ; Load the level code

bffrLkup                                            ; Location for the screen buffer line lookup table
                ds 384

;****************************************************************************************************************
; PAGE 0: Page boundary for tables and variables
;****************************************************************************************************************
PAGE0           
                org     32768

gmeStte         db      0                           ; 1 = GMESTTE_PLYNG, 2 = GMESTTE_WTNG to Start, 4 = GMESTTE_DEAD
lvlBlckCnt      db      0                           ; Number of blocks in this level
crrntLvl        db      0                           ; Stores the current level index
currntBlckRw    db      0                           ; Variables used to store detalis of the blocks when rendering...
currntBlckCl    db      0                           ; ...a level
currntBlckY     db      0
currntBlckX     db      0
crrntLvlAddr    dw      0                           ; Address of the currently loaded level

; Stores the x, y attr position of the balls collision points
ballMT          dw      0                           ; Middle Top
ballMR          dw      0                           ; Middle Right
ballMB          dw      0                           ; Middle Bottom
ballML          dw      0                           ; Middle Left

lives           db      5                           ; Number of lives each player has at the start of the game

prShftWdth      db      0                           ; Holds the width of the sprite to be shifted
prShftHght      db      0                           ; Holds the height of the sprite to be shifted
prShftSize      dw      0                           ; Holds the size of a sprite to shift in bytes

crrntScrCnt     db      0                           ; How many scores are visible on screen

grvty           dw      0x0035                      ; Gravity to be applied to particles each frame

index           db      0                           ; Index into the level data for collision detection

pwrUpCnt        db      0                           ; Stores the number of current powerups on screen

crrntPwrUps     db      0                           ; Each bit of this byte defines a different powerup. 1 = active
                                                    
sndFxDrtn       db      0

inptOption      db      0                           ; Holds the input selection that has been chossen
                                                    ; 0 = Keyboard, 1 = Sinclair, 2 = Kempston

tempSprite      ds      2 * 13

; Text
                        ; Colour, Yellow, Position, X, Y, Text
scrLblTxt       db      CC_INK, YELLOW, CC_AT, 0, 1, 'SCORE'
scrLblTxtEnd

scrTxt          db      '0000000', 0x00
scrTxtEnd

lvsLblTxt       db      CC_INK, YELLOW, CC_AT, 0, 24, 'LIVES'
lvsLblTxtEnd

lvsTxt          db      '5', 0x00

rndTxt          db      '1', 0x00

; Object data
                        ; Xpos, XSpeed, Ypos, YSpeed
objctBall       db      0, 1, 0, -2
    
                        ; Xpos, XSpeed, Ypos
objctBat        db      112, 4, 150         
                db      0 ; Delay counter used to time how long each frame should be visible
                db      0 ; Animation Frame
                db      0 ; Frame delay

; PAGE0 END
;****************************************************************************************************************

;****************************************************************************************************************
; PAGE 1: Page boundary Temp Level Data
PAGE1
                org     ($ + 255) & $ff00
                        
lvlData         ; Temp Level Data. Holds a copy of the levels row data that defines how many hits it takes to destroy a block
                ds      224
; PAGE1 END
;****************************************************************************************************************

;****************************************************************************************************************
; PAGE 2: Page boundary Particle Storage
PAGE2
                org     ($ + 255) & $ff00

objctPrtcls             
                db      0                           ; Lifespan
                db      0                           ; Timer
                dw      0x0000, 0x0000              ; Xvector, Xpos
                dw      0x0000, 0x0000              ; YVector, Ypos
                ds      10                          ; Space needed to store the background of the particle sprite
objctPrtclsEnd
PRTCLSZ         equ     objctPrtclsEnd - objctPrtcls; Calculate the size of a particle
                ds      PRTCLSZ * (NUMPRTCLS - 1)   ; Reserve the space for particles

; PAGE2 END
;****************************************************************************************************************

;****************************************************************************************************************
; PAGE 3: IM 2 jump table
PAGE3
                org     ($ + 255) & $ff00

intJmpTbl
                ds      256

; PAGE3 END
;****************************************************************************************************************

;****************************************************************************************************************
; PAGE 4: Page boundary Particle Storage
PAGE4
                org     ($ + 255) & $ff00

pxlData
                db      %10000000, %01111111
                db      %01000000, %10111111
                db      %00100000, %11011111
                db      %00010000, %11101111
                db      %00001000, %11110111
                db      %00000100, %11111011
                db      %00000010, %11111101
                db      %00000001, %11111110

; PAGE4 END
;****************************************************************************************************************

;****************************************************************************************************************
; PAGE 5: Page boundary Powerups
PAGE5
                org     ($ + 255) & $ff00
objctPwrUps
                db      0                           ; Xpos
                db      0                           ; YPos
                ds      16 * 13                     ; Space needed to store the background behind the powerup sprite
objctPwrUpsEnd
PWRUPSZ         equ     objctPwrUpsEnd - objctPwrUps; Calculate the size of a powerup object

; PAGE5 END
;****************************************************************************************************************

;****************************************************************************************************************
; Main code
;****************************************************************************************************************           

.debug          equ     0

init 
                call    stupInt                     ; Setup IM 2
                call    genLnrYLkupTbl              ; Generate linear YAxis lookup table

                xor     a                           ; Set the border colour
                out     (0xfe), a                   ; Output the border colour to the FE port
                        
                ld      a, CYAN + BRIGHT            ; Set the CC_INK colour
                ld      (0x5c8d), a                 ; Set the SYSVAR for CC_INK colour  

                call    shftSprts                   ; Create shifted versions of the sprites being used
                call    menu                        ; Start off by showing the main menu
 
                                                    ; Just in case we get here go back to basic
                IM      1                           ; Switch back to IM 1
                ret                                 ; Return to basic
 
;****************************************************************************************************************
; Pre-shift the sprites
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

                ; Shift Sprite Bat animation frames
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

                ret

;****************************************************************************************************************
; Debug Print
;****************************************************************************************************************
IF .debug
dbgPrnt
                ld      e, 168
                ld      d, 8 * 4
                call    getPixelAddr
                ld      a, (inptOption)               ; Bat X Position
                call    HexByte

;                 ld      e, 168
;                 ld      d, 8*6
;                 call    getPixelAddr
;                 ld      a, (objctPrtcls + 1 + PRTCLSZ * 1)               ; Bat X Position
;                 call    HexByte

;                 ld      e, 168
;                 ld      d, 8*9
;                 call    getPixelAddr
;                 ld      a, (objctPrtcls + 1 + (PRTCLSZ * 2))               ; Bat X Position
;                 call    HexByte

                ret
ENDIF

;****************************************************************************************************************
; Start new game
;****************************************************************************************************************
strtNewGame
                call    fdeToBlck
                call    romClrScrn
                call    rstScr                      ; Reset the score
                call    rstBt
                call    stupPrtcls

                ld      a, 5 
                ld      (lives), a
                ld      a, 53                       ; The number five in the character set
                ld      (lvsTxt), a
                
                xor     a                           ; Reset the level...
                ld      (lvlBlckCnt), a             ; ...block count
                ld      a, 1
                ld      (crrntLvl), a               ; Save the level 
                call    drwUI 
                call    ldLvl                       ; Load the current level
                call    drwBrdrs

                ld      a, GMESTTE_DSPLYLVL         ; Set the game state to DISPLAY LEVEL
                ld      (gmeStte), a                ; Save the game state

;****************************************************************************************************************
; Main loop
;****************************************************************************************************************
mnLp 
                ld      a, (gmeStte)                ; Check the game state

;****************************************************************************************************************
; PLAYING
_chckGmeSttePlyng                                   ; *** Game state PLAYING
                cp      GMESTTE_PLYNG               ; Is the game state PLAYING
                jr      nz, _chckGmeStteWtng        ; If not then check if the state is WAITING

                call    rdCntrlKys                  ; Read the keyboard
                call    mvBll                       ; Move the ball
                call    drwBll                      ; Erase the ball (XOR)
                call    drwPrtcls                   ; Draw any active particles
                call    updtBtAnmtnFrm              ; Update the bats animation frame
                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

                call    drwBll                      ; Draw the ball
                call    rstrScrBckgrnd              ; Restore the background behind the particles
                call    drwBt                       ; Erase the bat (XOR)
                call    updtPrtcls                  ; Update any active particles

                call    genRndmNmbr                 ; Generate three random numbers

                ld      a, (lvlBlckCnt)             ; Load A with the number of blocks that are still visible
                or      a                           ; Check the number of blocks against 0
                jr      nz, mnLp                    ; If not yet 0 then loop
                ld      a, GMESTTE_NXTLVL           ; No more blocks so set the game state to NEXT LEVEL
                ld      (gmeStte), a                ; Save the game state and loop
                jp      mnLp

;****************************************************************************************************************
; WAITING
_chckGmeStteWtng                                    ; *** Game state WAITING
                cp      GMESTTE_WTNG                ; Is the game state WAITING    
                jp      nz, _chckGmeStteLstLfe      ; If not then check if the state is PLAYER DEAD

                call    rdCntrlKys                  ; Read the keyboard

                ld      a, (objctBat + BTYPS)       ; Get the bats Y position
                ld      b, BLLPXLHGHT               ; Get the pixel height of the ball
                sub     b                           ; Calculate the bats Y pos minus the balls height putting the ball on top of the bat
                ld      (objctBall + BLLYPS), a     ; Update the balls Y Position with the bats Y position 
                ld      a, (objctBat + BTXPS)       ; Load the bats X pos
                ld      b, BTHLFWDTH - BLLHLFWIDTH  ; Calc the X pos middle of the bat
                add     a, b                        ; Calc the new X pos for the ball so its in the middle of the bat
                ld      (objctBall + BLLXPS), a     ; Save the new X pos for the ball
                
                call    drwBll                      ; Draw the ball
                call    updtBtAnmtnFrm
                call    drwBt                       ; Draw the bat

                halt                                ; Wait for the scan line to reach the top of the screen

                call    drwBll                      ; Erase the ball (XOR)
                call    drwBt                       ; Erase the bat (XOR)

                call    genRndmNmbr
                
;                 ld      bc, 0x7ffe                  ; Want to see if SPACE has been pressed
;                 in      a, (c)                      ; Read the port
;                 rra                                 ; Rotate Right
;                 jp      c, mnLp                     ; Loop if SPACE has not been pressed

                ld      a, (inptOption)             ; Get the currently selected input option
_keybrdFire
                cp      0                           ; KEYBOARD
                jr      nz, _sincJoyFire
                ld      bc, 0x7ffe                  ; B = 0xDF (QUIOP), C = port 0xFE
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; Outermost bit = key 1
                jp      nc, _gameOn                 ; Space bar has been pressed
                jp      mnLp
_sincJoyFire
                cp      1                           ; SINCLAIR PORT 1
                jr      nz, _kempJoyFire 
                ld      bc, 0xf7fe
                in      a, (c)
                rra
                rra
                rra
                rra
                rra
                jp      nc, _gameOn
                jp      mnLp
_kempJoyFire                                        ; KEMPSTON
                cp      2
                ret     nz
                ld      bc, 31
                in      a, (c)
                and     16
                jp      nz, _gameOn
                jp      mnLp         
_gameOn
                ld      a, GMESTTE_PLYNG            ; Otherwise update the game state to GMESTTE_PLYNG
                ld      (gmeStte), a                ; Save the game state
                jp      mnLp                        ; Loop

;****************************************************************************************************************
; LOST LIFE
_chckGmeStteLstLfe                                  ; *** Game state LOST LIFE
                cp      GMESTTE_LSTLFE              ; Is the game state LOST LIFE
                jr      nz, _gmeStteNxtLvl          ; If not then check if the state is NEXT LEVEL
                ld      a, (lives)                  ; Load A with the lives left
                dec     a                           ; -1 from lives

                push    af                          ; Save AF
                ld      (lives), a                  ; Save the new number of lives
                add     a, 48                       ; Add 48 to the number of lives to get the character code for the lives number
                ld      (lvsTxt), a                 ; Update the lives text with the new lives character at position 5 in the string

                ld      de, 0xf000
                ld      bc, lvsTxt                  ; Load DE with the lives text
                call    prntStrng

                pop     af                          ; Restore AF
                or      a                           ; Check if the players lives have reached 0 
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

;****************************************************************************************************************
; NEXT LEVEL
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
_incLvl         
                ld      a, GMESTTE_DSPLYLVL         ; Set the game state to DISPLAY LEVEL
                ld      (gmeStte), a                ; Save the game state
                call    stupPrtcls                  ; Clear any current particles
                call    ldLvl                       ; Load the new level
                jp      mnLp                        ; Loop

;****************************************************************************************************************
; DISPLAY LEVEL
_chckGmeStteDsplyLvl                                ; *** Game state DISPLAY LEVEL
                cp      GMESTTE_DSPLYLVL            ; Is the game state DISPLAY LEVEL
                jp      nz, _chckGmeSttePlyrDead    ; If not then check if the game state is PLAYER DEAD
                ld      hl, (crrntLvlAddr)          ; Load HL with the current level address
                ld      de, LEVEL_TITLE             ; Load DE with the offset in the level data to the level title
                add     hl, de                      ; Move HL to the level title
                ld      b, 0                        ; Set b to 0                            
                ld      c, (hl)                     ; Load C with the length of the string to print
                ld      d, h                        ; Load HL the address of the text...
                ld      e, l                        ; ...into DE
                inc     de                          ; + 1 DE which is the start of the actual string
                call    ROMPRINT                    ; ROM print the title
                ld      de, 100                     ; Load DE with 100 for a delay loop
_lvlDsplyWtng   
                halt                                ; Wait for the scan line to reach the top of the screen (50hz)
                dec     de                          ; -1 from DE
                ld      a, d                        ; Check to see if...
                or      e                           ; ...the timer has run down
                jr      nz, _lvlDsplyWtng           ; If not then loop again
                ld      hl, (crrntLvlAddr)          ; Load HL with the address of the current level data
                ld      de, LEVEL_TITLE             ; Load DE with the levels title position...
                add     hl, de                      ; ...and add it to DE
                ld      b, 0                        ; Reset B
                ld      c, (hl)                     ; Put the length of the level title into C
                add     hl, bc                      
                ld      b, 0
                inc     hl
                ld      c, (hl)
                ld      e, l
                ld      d, h 
                inc     de
                call    ROMPRINT
                ld      a, GMESTTE_WTNG             ; Set the game state to WAITING
                ld      (gmeStte), a

                jp      mnLp

;****************************************************************************************************************
; PLAYER DEAD
_chckGmeSttePlyrDead
                cp      GMESTTE_DEAD
                jp      nz, mnLp

                call    romPrntStrng
                db      CC_FLASH, 1, CC_INK, WHITE, CC_PAPER, RED, CC_AT, 15, 11, ' GAME OVER ', CC_FLASH, 0, 0xff

                call    watFrSpc
                call    fdeToBlck
                jp      menu

;****************************************************************************************************************
; Setup the particle objects by clearing out all the values
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
stupPrtcls
                ld      hl, objctPrtcls             ; Point HL at the particle pool
                ld      bc, NUMPRTCLS * 26          ; Load BC with the number of bytes to clear
                call    clrMem                      ; Call the clear mem routine
                ret

;****************************************************************************************************************
; Update bat animation
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
                ld      a, (objctBat + BTANMTONDLY) ; Point DE at the animation delay counter
                inc     a                           ; Increment the frame delay counter
                ld      (objctBat + BTANMTONDLY), a ; Save the new delay amount
                cp      7                           ; Check the delay (1/50 * n)
                ret     nz                          ; and return if we've not reached the delay value

                xor     a                           ; Delay has been reached so reset the delay...
                ld      (objctBat + BTANMTONDLY), a ; ...and save it
                ld      a, (objctBat + BTANMTONFRM) ; Load A with the current frame count
                inc     a                           ; Increment the counter
                cp      4                           ; Compare it against the max value allowed...
                jp      nz, _svBtFrm                ; ...and save the new frame count if the max has not been reached
                xor     a                           ; Reset the animation frame to 0
_svBtFrm
                ld      (objctBat + BTANMTONFRM), a ; Save the new frame number
                ret                                 ; Return

;****************************************************************************************************************
; Restores the background behind each active particle. When a particle sprite is drawn the contents of the screen
; buffer at the particles location is saved to the particle to be drawn. This data is then restored to erase the
; particle sprite and restore the background underneath it using this routine.
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
rstrScrBckgrnd
                ld      b, NUMPRTCLS                ; Load B with number of particles
                ld      hl, objctPrtcls + 1         ; Point HL at timer in the first particle
_nxtBckgrnd     ld      a, (hl)                     ; Load A with the timer value for the score
                or      a                           ; Is the timer 0?
                jp      nz, _updtBckgrnd            ; If not then update it as its active...
                ld      de, PRTCLSZ                 ; Move to the next...
                add     hl, de                      ; ...particle
                djnz    _nxtBckgrnd                 ; Loop if there are particles objects left
                ret
_updtBckgrnd
                push    hl
                push    bc
                inc     l                           ; Point HL at the  
                inc     l                           ; ... 
                inc     l                           ; ... 
                inc     l                           ; high byte of the x position 
                ld      b, (hl)                     ; Load B with the x pos high byte
                inc     l                           ; Point HL at the                       
                inc     l                           ; ...                       
                inc     l                           ; ...                       
                inc     l                           ; high byte of the y position                       
                ld      c, (hl)                     ; Load C with the y pos high byte
                inc     l                           ; Point HL at background data
                ex      de, hl                      ; Put HL into DE
                ld      hl, 0x0205                  ; Load HL with the size of sprite to restore
                call    rstrScrnBlck                ; Restore the screen with the background data held with the particle
                pop     bc                          ; Restore the particle counter
                pop     hl                          ; Restore the table pointer

                ld      de, PRTCLSZ                 ; Load DE with the size of a single particle...
                add     hl, de                      ; ...and add that to HL to move to the next particle
                djnz    _nxtBckgrnd                 ; Loop if there are particle objects left
                ret

;****************************************************************************************************************
; Update Balls collision points
; Four variables store collision points on the ball, these are middle top, middle right, middle bottom and middle left.
; 
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
updtBllChrPs                                       ; Update the balls character position used in block collision detection
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
                ld      (ballMR), bc                ; The character location is returned in BC so we save that

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

                ret                                 ; Return

;****************************************************************************************************************
; Draw the text UI elements e.g. the score, round and lives
;
; Entry Registers:
;   NONE
; Registers Used:
;   B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwUI

                call    romPrntStrng
                db      CC_INK, YELLOW, CC_AT, 0, 1, 'SCORE', 0xff

                call    romPrntStrng
                db      CC_PAPER, GREEN, CC_INK, BLACK, CC_AT, 0, 7, '0000000', 0xff

                call    romPrntStrng
                db      CC_PAPER, BLACK, CC_INK, YELLOW, CC_AT, 0, 24, 'LIVES', 0xff

                call    romPrntStrng
                db      CC_PAPER, GREEN, CC_INK, BLACK, CC_AT, 0, 30, '5', 0xff

                ld      de, 0xf000
                ld      bc, lvsTxt                  ; Load DE with the address of the Lives Text
                call    prntStrng

                call    romPrntStrng
                db      CC_PAPER, BLACK, CC_INK, YELLOW, CC_AT, 0, 15, "ROUND", 0xff

                call    romPrntStrng
                db      CC_PAPER, GREEN, CC_INK, BLACK, CC_AT, 0, 21, "02", 0xff

;                 ld      de, 0xa800
;                 ld      bc, rndTxt
;                 call    prntStrng

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
                ; Setup the attributes for the borders
                ld      d, 1
                ld      e, 1
_hrzClr
                ld      a, MAGENTA
                push    de
                call    setChrctrAttr
                pop     de
                inc     e
                ld      a, e
                cp      31
                jr      nz, _hrzClr

                ld      d, 1
                ld      e, 1
_VrtClr
                ld      e, 1
                ld      a, MAGENTA
                push    de
                call    setChrctrAttr
                pop     de
                ld      e, 30
                push    de
                call    setChrctrAttr
                pop     de

                inc     d
                ld      a, d
                cp      24
                jr      nz, _VrtClr

                ; Draw top wall
                ld      h, 0
                ld      b, SCRNLFT
                ld      c, 8
_hrzntlLp
                push    hl
                push    bc
                ld      de, LoopHSpriteData
                xor     a
                call    drwSprt
                pop     bc
                push    bc
                ld      de, LoopHSpriteData
                ld      a, 1
                call    drwSprt
                pop     bc                
                pop     hl
                ld      a, b
                add     a, 16
                ld      b, a
                inc     h
                ld      a, h
                cp      14
                jr      nz, _hrzntlLp

                ; Draw right hand wall
                ld      h, 0
                ld      b, SCRNRGHT
                ld      c, 16
_vrtclLp1
                push    hl
                push    bc
                ld      de, LoopVSpriteData
                xor     a
                call    drwSprt
                pop     bc
                push    bc
                ld      de, LoopVSpriteData
                ld      a, 1
                call    drwSprt
                pop     bc                
                pop     hl
                ld      a,c
                add     a, 16
                ld      c, a
                inc     h
                ld      a, h
                cp      11
                jr      nz, _vrtclLp1

                ; Draw Left hand wall
                ld      h, 0
                ld      b, SCRNLFT - 8
                ld      c, 16
_vrtclLp2
                push    hl
                push    bc
                ld      de, LoopVSpriteData
                xor     a
                call    drwSprt
                pop     bc
                push    bc
                ld      de, LoopVSpriteData
                ld      a, 1
                call    drwSprt
                pop     bc                
                pop     hl
                ld      a,c
                add     a, 16
                ld      c, a
                inc     h
                ld      a, h
                cp      11
                jr      nz, _vrtclLp2

                ld      de, LoopLCSpriteData
                ld      b, SCRNLFT - 8
                ld      c, 8
                ld      a, 0
                call    drwSprt

                ld      de, LoopRCSpriteData
                ld      b, SCRNRGHT
                ld      c, 8
                ld      a, 0
                call    drwSprt

                ret

;****************************************************************************************************************
; Loop through all particles and draw active ones on the screen
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwPrtcls 
                ld      b, NUMPRTCLS
                ld      hl, objctPrtcls + 1         ; Point HL at the first particles timer data
_chkPrtclActv
                ld      a, (hl)                     ; Get the timer for the particle
                or      a                           
                jp      nz, _drwCrrntPrtcl          ; If its not zero then its active so draw it
                ld      de, PRTCLSZ                 ; Move to the next particle
                add     hl, de
                djnz    _chkPrtclActv               ; Loop if there are more particles
                ret                                 ; Finished

_drwCrrntPrtcl
                push    bc                          ; Save BC as its holding our score loop count in B
                push    hl                          ; Save HL as this is our pointer into the object table
                inc     l                           ; XVector Low
                inc     l                           ; XVector high
                inc     l                           ; Xpos low
                inc     l                           ; Xpos high
                ld      b, (hl)
                inc     l
                inc     l
                inc     l
                inc     l
                ld      c, (hl)
                inc     l
                ex      de, hl
                push    bc
                ld      hl, 0x0205
                call    sveScrnBlck
                pop     bc

                xor     a
                ld      de, ParticleSpriteData
                call    drwMskdSprt

                pop     hl
                pop     bc
                ld      de, PRTCLSZ                 ; Move to the next particle
                add     hl, de
                djnz    _chkPrtclActv               ; Loop if there are more particles 

                ret

;****************************************************************************************************************
; Draw Ball Sprite
; Draws the ball sprite at its current location
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, DE
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwBll 
                ld      de, SmallBallData           ; Point DE to the ball sprite data
                ld      a, (objctBall + BLLXPS)     ; Load A with the balls X position
                ld      b, a                        ; Put A into B
                ld      a, (objctBall + BLLYPS)     ; Load A with the balls Y position
                ld      c, a                        ; Load C with A so B = X, C = Y
                xor     a
                call    drwSprt                     ; Draw sprite
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the bat at its current location
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, DE, HL
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwBt 
                ld      a, (objctBat + BTANMTONFRM) ; Load the current frame number
                ld      e, a                        ; Load the frame into E...
                ld      d, 0                        ; ...and clear D
                ld      hl, SpriteBatFrameTable     ; Load HL with the address of the frame table
                add     hl, de                      ; Add the frame number to the frame table...
                add     hl, de                      ; ...twice as the table is made up of word entries
                ld      e, (hl)                     ; Load E with the LSB of the frame address
                inc     hl                          ; Move to the MSB of the address
                ld      d, (hl)                     ; Load D with the MSB of the frame address
                ld      a, (objctBat + BTXPS)       ; Load A with the bats X position
                ld      b, a                        ; Put A into B
                ld      a, (objctBat + BTYPS)       ; Load A with the bats Y position
                ld      c, a                        ; Load A with A so B = X, C = Y
                xor     a
                call    drwSprt                     ; Draw sprite
                ret

;************************************************************************************************************************
; Read Control Keys
; Checks the control keys used in the game e.g. O = left, P = right, SPACE = fire when using the keyboard. If either of these keys are pressed then the bats
; current location is updated based on the key being pressed. When the bat is moved, if the balls x position is more than 10 pixels from either end of the bat
; then the bat moves at double speed until the ball is within range. This helps deal with balls that come off the bat or blocks at an oblique angle 
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, F, B, C, D, E, H, L
; Returned Registers:
;   NONE
;************************************************************************************************************************
rdCntrlKys 
                ld      a, (inptOption)             ; Get the currently selected input option
_keybrd
                cp      0                           ; KEYBOARD
                jr      nz, _sincJoy
                ld      bc, 0xdffe                  ; B = 0xDF (QUIOP), C = port 0xFE
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; Outermost bit = key 1
                jp      nc, mvBtRght               ; Move the bat left
                rra                                 ; Next bit is key 2
                jp      nc, mvBtLft                ; Move the bat right
                ret
_sincJoy
                cp      1                           ; SINCLAIR PORT 1
                jr      nz, _kempJoy 
                ld      bc, 0xf7fe
                in      a, (c)
                rra
                jp      nc, mvBtLft
                rra
                jp      nc, mvBtRght
                ret
_kempJoy                                            ; KEMPSTON
                cp      2
                ret     nz
                ld      bc, 31
                in      a, (c)
                and     2
                jp      nz, mvBtLft
                in      a, (c)
                and     1
                jp      nz, mvBtRght
                ret

;************************************************************************************************************************
; Responsible for moving the players bat to the left. It manages the bat colliding with the left edge of the screen and
; also doubles the speed of the bat while the bats left edge is more than 15 pixels away from the x position of the ball 
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, D, E, H, L
; Returned Registers:
;   NONE
;************************************************************************************************************************
mvBtLft     
                ld      hl, objctBat                ; HL = X Position
                ld      a, (hl)                     ; Grab te bars X position into A
                ld      de, (objctBall + BLLXPS)    ; Grab the balls current X position into E
                sub     e                           ; Subtract the balls X pos from the bats X pos
                cp      15                          ; Check it the difference is >= 20...
                jp      m, _noLftBoost              ; ...and if not then don't update the bats x speed
                ld      a, (hl)
                inc     l
                sub     (hl)
                sub     (hl)
                dec     l
                jp      _sveLftBtXpos
_noLftBoost
                ld      a, (hl)                     ; Put X pos into A
                inc     l                           ; Move to the X Speed position 
                sub     (hl)                        ; Subtract the X speed from the X pos
                dec     l                           ; Move HL to the X pos
_sveLftBtXpos
                cp      BTMXLFT                     ; Check if we are past the left hand edge of the screen
                jp      c, _btHtLftEdg              ; and jump if we are jump to hitLeftEdge
                ld      (hl), a                     ; Update the X position with A
                ret     
_btHtLftEdg         
                ld      (hl), BTMXLFT               ; Hit the edge so set the X pos to the BTMXLFT value
                ret 

;************************************************************************************************************************
; Responsible for moving the players bat to the left. It manages the bat colliding with the right edge of the screen and
; also doubles the speed of the bat while the bats right edge is more than 10 pixels away from the x position of the ball
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, D, E, H, L
; Returned Registers:
;   NONE
;************************************************************************************************************************
mvBtRght    
                ld      hl, objctBat                ; HL = X Position
                ld      a, (hl)                     ; Put X pos into A
                ld      de, (objctBall + BLLXPS)
                add     a, BTPXLWDTH
                sub     e
                cp      -10
                jp      p, _noRghtBoost
                ld      a, (hl)
                inc     l
                add     a, (hl)
                add     a, (hl)
                dec     l
                jp      _sveRghtBtXpos
_noRghtBoost
                ld      a, (hl)
                inc     l
                add     a, (hl)
                dec     l
_sveRghtBtXpos
                cp      BTMXRGHT                    ; Check if the bat is past left edge
                jp      nc, _btHtRghtEdg            ; and jump if it is
                ld      (hl), a                     ; Update the X Position with A
                ret     
_btHtRghtEdg         
                ld      (hl), BTMXRGHT              ; Hit the edge so set the X pos to the BTMXRGHT value
                ret

;****************************************************************************************************************
; Move Ball
; Responsible for bouncing the ball sprite around the screen.
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
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
                or      a                           ; Is the ball moving down the screen?
                jp      m, _chkTp                   ; If not then check the balls position with the top of the screen
                call    chkBtCllsn                  ; Otherwise ball is moving down the screen so check if its hit the bat
                call    updtBllChrPs                ; Finally update the balls character x, y position 
                ret

_chkTp
                dec     hl                          ; Point HL to the Y Position
                ld      a, (hl)                     ; Put the Y pos into A
                cp      SCRNTP                      ; Has the ball reached the top of the screen?
                jr      c, _bncDwn                  ; Yes, then bounce down the screen
                call    updtBllChrPs                ; Finally update the balls character x, y position 
                ret 

_bncDwn
                ld      a, SCRNTP
                ld      (hl), a                     ; Update the Y Position so the ball is up against the top of the screen
                inc     hl                          ; Point HL at the balls Y Speed
                ld      a, (hl)                     ; Load the Y Speed into A...
                neg                                 ; ...so it can be reversed...
                ld      (hl), a                     ; ...and saved back into the data table
                call    updtBllChrPs
                ret

_htBttm
                ld      a, GMESTTE_LSTLFE
                ld      (gmeStte), a
                jp      updtBllChrPs
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
; Check Bat Collision
; Responsible for checking if the ball has hit the bat. If the ball has hit the bat then depending on the
; y position of the ball on the bat the balls x speed is updated along with its y speed being reversed
;
; Entry Registers:
;   NONE
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
                or      a                           ; See which direction its moving    
                jp      m, _bllMvngLft              ; A < 0 means left otherwise right

_bllMvngRght  
                pop     af                          ; Restore A which holds ball.x in bat space
                push    hl
                cp      6                           ;
                jr      nc, _rArea2
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 0
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea2         cp      12
                jr      nc, _rArea3
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea3         cp      18
                jr      nc, _rArea4
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                pop     hl
                ld      (hl), a
                jp      _bncUp

_rArea4         cp      24
                jr      nc, _bncUp
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 3
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
                ld      de, LEVEL_BCC_AT_SPEEDS + 3
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea2         cp      12
                jr      nc, _lArea3
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea3         cp      18
                jr      nc, _lArea4
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                neg
                pop     hl
                ld      (hl), a
                jp      _bncUp

_lArea4         cp      24
                jr      nc, _bncUp
                ld      hl, (crrntLvlAddr)
                ld      de, LEVEL_BCC_AT_SPEEDS + 0
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
; Check the collisions points around the ball against the attribute buffer and if a collision is found then Remove
; the block and bounce the ball.  By checking each collision point around the ball sprite we can find out which
; part of the ball has hit a tile. This then allows us to update the sprites X or Y speed causing the ball to 
; appear to bounce off the tile. A collision is identified if the attribute at the collision point is not 5 which
; represents a black background and cyan CC_INK.
;
; Entry Registers:
;   NONE
; Used Registers:
;   A, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
chckBlckCllsn 
                ld      a, (objctBall + BLLYSPD)    ; Load the Y Speed of the ball
                or      a                           ; Compare it with 0 to find out if the balls is moving up...
                jp      p, _mddlBttm                ; ...if p then moving down the screen so check the bottom of the ball

                ld      de, (ballMT)                ; Load the middle collison point into DE, D = Y, E = X
                push    de                          ; Save DE
                call    chkBlckState
                pop     de
                or      a                           ; Is the attribute returned Cyan on black...
                jr      z, _mddlRght                ; ...if so then check the right collision point as there is no block
                
                ld      a, (objctBall + BLLYSPD)    ; Load A with the ball.ySpeed
                neg                                 ; Reverse the ball.ySpeed...
                ld      (objctBall + BLLYSPD), a    ; ...and save it back with the ball data
                ld      a, b
                or      a
                jp      nz, _mddlBttm
                call    rmvBlck
                ld      hl, 125
                call    incScr
                call    prntScr

_mddlBttm
                ld      de, (ballMB)
                push    de
                call    chkBlckState
                pop     de
                or      a
                jr      z, _mddlRght
                ld      a, (objctBall + BLLYSPD)
                neg
                ld      (objctBall + BLLYSPD), a   
                ld      a, b
                or      a
                jp      nz, _mddlRght
                call    rmvBlck
                ld      hl, 125
                call    incScr
                call    prntScr

_mddlRght 
                ld      a, (objctBall + BLLXSPD)
                or      a
                jp      m, _mddlLft                 ; Only check the right edge if moving right
                ld      de, (ballMR)
                push    de
                call    chkBlckState
                pop     de
                or      a
                jr      z, _mddlLft
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a
                ld      a, b
                or      a
                jp      nz, _mddlLft
                call    rmvBlck
                ld      hl, 125
                call    incScr
                call    prntScr

_mddlLft 
                ld      a, (objctBall + BLLXSPD)
                or      a
                ret     p                           ; Only check the left edge if moving left
                ld      de, (ballML)
                push    de
                call    chkBlckState
                pop     de
                or      a
                ret     z
                ld      a, (objctBall + BLLXSPD)
                neg
                ld      (objctBall + BLLXSPD), a   
                ld      a, b
                or      a
                ret     nz
                call    rmvBlck
                ld      hl, 125
                call    incScr
                call    prntScr
                ret


;****************************************************************************************************************
; This routine takes the an X and Y character location and checks to see if a block exists at that location and
; it so reduces the blocks hit count
;
; Entry Registers:
;   D = Y
;   E = X
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   A = 0 No block was hit, = 1 Block was hit
;   B = 0 Block was hit and should be removed, = 1 Block was hit but should not be removed e.g. hit count > 0
;****************************************************************************************************************
chkBlckState
                ld      a, e                        ; Grab the X pos
                rra                                 ; Divide by 8
                sub     1                           ; Sub 1
                ld      b, a                        ; Save the result in B

                ld      a, d                        ; Grab the Y pos
                sub     STRT_CHR_Y_POS              ; Subtract the starting Y position for the blocks on screen

                jp      p, _calcIndx                ; If the result is positive then calculate the index of the block
_LssThnZro
                ld      a, 0                        ; Index was < 0 so set A to 0 
                ret                                 ; and return
_calcIndx
                ld      l, 0                        
                ld      h, 14                       ; Multiplier
                ld      d, 0
                ld      e, a                        ; Multipland
                call    mult_H_E                    ; Multiply H with E

                ld      a, l                        ; Grab the result of the multiplication 
                add     a, b                        ; and add it to the index in B
                ld      (index), a                  ; Save the index to memory 

                cp      112                         ; Maximum block data index
                jp      c, _inRnge
_outRnge
                ld      a, 0                        ; Index is out of range so set A to 0
                ld      (index), a                  ; and save it to the index memory variable
                ret
_inRnge
                ld      ix, lvlData                 ; Grab the lvlData location
                add     a, a                        ; Double A as each column is two bytes
                ld      e, a                        ; Put the index into E
                ld      d, 0                        ; Clear D
                add     ix, de                      ; Add the index to the level data location
                ld      b, 0                        ; B = 0 on return means remove the block as this is the last hit
                ld      a, (ix + BLCK_HIT_CNT)      ; Get the hit count for the block
                or      a                           ; See if its 0
                jr      z, _chkBlckFnsh             ; and if so then no need to save it
                dec     a                           ; otherwise decrement the hit count
                ld      (ix + BLCK_HIT_CNT), a      ; and save it back to the block
                or      a                           ; Check if A == 0
                jp      z, _htZro                   ; and if so then the block should be hit AND removed
                ld      b, 1                        ; B = 1 on return a block was hit but should NOT be removed
_htZro
                ld      a, 1                        ; Return 1 to say that the block should be hit
_chkBlckFnsh
                ret

;****************************************************************************************************************
; Increment the players score by the value in the HL register
;
; Entry Registers:
;   HL = Value to be added to the current score
; Used Registers:
;   NONE
; Returned Registers:
;   NONE
;****************************************************************************************************************
incScr
                ld      b, 6                        ; Number of digits in score - 1 
_scrLp
                ld      c, 10                       ; Load C with the devisor we want to use
                call    dvd_HL_C                    ; Divide HL by C
                ld      c, a                        ; Load C with the remainder
                push    bc 
                push    hl
                call    _addToScr                   ; Add the digit to the score
                pop     hl
                pop     bc
                djnz    _scrLp
                ret
_addToScr
                ld      hl, scrTxt                  ; Point HL at the score string address
                ld      e, b                        ; Load E with B which holds the digit count
                ld      d, 0                        ; Reset D so DE holds just the digit count
                add         hl, de                  ; Add the digit count to HL (string address)
_cryOneLp
                ld      a, (hl)                     ; Load A with the digit al HL    
                add     a, c                        ; Add A with C (the remainder)
                cp      0x3a                        ; Is the new digit > 9
                jr      c, _incScrDn                ; If yes then we are done with this digit
                
                ; Move on
                sub     10                          ; If not then sub 10 from A
                ld      (hl), a                     ; and load the digit back into the string
                ld      c, 1                        ; Set C to 1
                dec     hl                          ; Move along the score string
                djnz    _cryOneLp                   ; Loop if digits left
                ret
_incScrDn
                ld      (hl), a                     ; Save the digit in A
                ret

;****************************************************************************************************************
; Print the current score onto the screen
;
; Entry Registers:
;   NONE
; Used Registers:
;   DE, BC
; Returned Registers:
;   NONE
;****************************************************************************************************************
prntScr
                ld      de, 0x3800                                      
                ld      bc, scrTxt
                call    prntStrng
                ret

;****************************************************************************************************************
; Remove the block that contains the x,y provided D = Y and E = X
;
; Entry Registers:
;   DE = Y, X
; Used Registers:
;   A, B, C, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
rmvBlck
                ld      b, 100
                call    plyClck

                ld      a, (lvlBlckCnt) 
                dec     a                           ; Decrement the number of blocks 
                ld      (lvlBlckCnt), a                    

                ; Remove the block
                ld      a, e
                and     1                           ; Check to see if the number is _odd
                or      a
                jr      z, _even

_odd             
                ld      a, CYAN + BRIGHT            ; Load A with 5 = Cyan on Black
                push    de                          ; Save the coords in DE
                call    setChrctrAttr               ; set the attribute at DE to a value of 5
                pop     de                          ; Restore DE
                ld      a, e                        ; Load A with E
                sub     1                           ; Subtract 1 to get the preceeding attribute X value
                ld      e, a                        ; Load E with the new X coord value
                ld      a, CYAN + BRIGHT            ; Load A with 5 for Cyan on Black
                push    de                          ; Save DE on the stack
                call    setChrctrAttr               ; Set this attribute as well
                pop     de                          ; Restore DE

                ld      a, e                        ; Load A with E (X coord)
                add     a, a                        ; Multply A with 8...
                add     a, a                        ; ...to convert from character to pixel coords
                add     a, a                        ; ADD A, A uses less t-states than RL A
                ld      b, a

                ld      a, d                        ; Multiply the Y coord by 8
                add     a, a
                add     a, a
                add     a, a
                ld      c, a
                push    bc                          ; Save BC
                push    bc
                ld      de, SpriteBlockData         ; Point to the block sprite data
                xor     a
                call    drwSprt                     ; Draw the block (XOR) to remove block
                pop     bc 
                ld      de, SpriteBlockData
                ld      a, 1
                call    drwSprt

                pop     bc                          ; Restore BC which holds the pixel location of the block
                call    genPrtcl
                ret

_even           
                ld      a, CYAN + BRIGHT
                push    de
                call    setChrctrAttr
                pop     de
                inc     e
                ld      a, CYAN + BRIGHT
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
                push    bc
                xor     a                           ; A = 0 as we are drawing the block to the screen file
                ld      de, SpriteBlockData         ; Point to the block data
                call    drwSprt                     ; XOR the sprite onto the screen file
                pop     bc
                ld      a, 1                        ; A = 1 as we are drawing the block to the back buffer
                ld      de, SpriteBlockData         ; Point to the block sprite data
                call    drwSprt                     ; XOR the sprite onto the back buffer

                pop     bc                          ; Restore BC with the blocks position 
                call    genPrtcl
                ret

;****************************************************************************************************************
; Reset the bats X pos to the center of play area
;****************************************************************************************************************
rstBt    
                ld      a, 112
                ld      (objctBat + BTXPS), a
                ld      a, 175
                ld      (objctBat + BTYPS), a
                ld      a, -2
                ld      (objctBall + BLLYSPD), a
                ret

;****************************************************************************************************************
; Reset score to 0000000
;****************************************************************************************************************
rstScr
                ld      hl, scrTxt                  ; Point HL at the score string address
                ld      de, scrTxt + 1              ; Point DE at the score string address + 1
                ld      bc, 6                       ; Load BC with the length of the string
                ld      (hl), '0'                   ; Load (HL) with a 0 which will be copied using...
                ldir                                ; ...LDIR
                call    prntScr
                ret

;****************************************************************************************************************
; Play click sound with b = length of the loop
;****************************************************************************************************************
plyClck       
                ld      a, 16
                and     248
                out     (254), a
_clickLp0       djnz    _clickLp0
                xor     a
                and     248
                out     (254), a

                ld      a, 16
                and     248
                out     (254), a
_clickLp1       djnz    _clickLp1
                xor     a
                and     248
                out     (254), a
                ret

;****************************************************************************************************************
; Play death sound with b = length of the loop
;****************************************************************************************************************
plyDthSnd
                xor     a
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
; Includes
;****************************************************************************************************************
                include     Library.asm
                include     Particles.asm
                include     Maths.asm
                include     Graphics.asm

        IF .debug
                include     Debug.asm               ; Only need the debug routines during development
        ENDIF

                END init
