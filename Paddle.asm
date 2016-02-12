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
; Init
;****************************************************************************************************************           
SetBorder 
                ld      a, 0
                out     (254), a                    
                        
                ld      a, 5                        ; Set the ink colour
                ld      (23693), a  
                
;****************************************************************************************************************
; Init
;****************************************************************************************************************
Init 
                call    DrawTitleScreen
                call    WaitForSpace
                call    ClearScreen

                ld      de, LivesText
                ld      bc, 8
                call    8252

                ld      a, 0
                ld      (CurLvl), a
                call    LoadLevel

                ld      a, DISPLAYLEVEL
                ld      (GameState), a

                jp      MainLoop

ClearScreen     
                call    3503    

                call    DrawInfoPanel       

                ld      de, ScoreLabelText
                ld      bc, 10
                call    8252

                ld      de, ScoreText
                ld      bc, 12
                call    8252

                ld      de, LivesLabelText
                ld      bc, 10
                call    8252

                call    DrawBorders
                ret

;****************************************************************************************************************
; Main loop
;****************************************************************************************************************
MainLoop 
                ld      a, (GameState)              ; Check the game state
CheckPlaying
                cp      PLAYING 
                jr      nz, CheckWaiting

                call    MoveBall
                ld      ix, ObjectMovingBlock1
                call    UpdateMovingBlock
                ld      ix, ObjectMovingBlock2
                call    UpdateMovingBlock
                call    ReadControlKeys
                call    DrawBall
                ld      ix, ObjectMovingBlock1
                call    DrawMovingBlock                
                ld      ix, ObjectMovingBlock2
                call    DrawMovingBlock                
                call    DrawBat                     ; Draw the ball and bat
                halt
                call    DrawBall
                ld      ix, ObjectMovingBlock1
                call    DrawMovingBlock                
                ld      ix, ObjectMovingBlock2
                call    DrawMovingBlock                
                call    DrawBat                     ; Erase the ball and bat (XOR)

                ld      a, (LevelBlockCount)
                cp      0
                jr      nz, MainLoop
                ld      a, NEXTLEVEL
                ld      (GameState), a
                jp      MainLoop

CheckWaiting
                cp      WAITING
                jr      nz, CheckDead

                ; Put the balls location at the center of the bat1
                ld      ix, ObjectMovingBlock1
                call    UpdateMovingBlock
                ld      ix, ObjectMovingBlock2
                call    UpdateMovingBlock
                call    ReadControlKeys
                ld      a, (ObjectBat + BAT_Y_POS)
                ld      b, BALL_PIXEL_HEIGHT
                sub     b
                ld      (ObjectBall + BALL_Y_POS), a
                ld      a, (ObjectBat + BAT_X_POS)
                ld      b, BAT_PIXEL_WIDTH / 2 - 3
                add     a, b
                ld      (ObjectBall + BALL_X_POS), a
                call    DrawBall
                ld      ix, ObjectMovingBlock1
                call    DrawMovingBlock                
                ld      ix, ObjectMovingBlock2
                call    DrawMovingBlock                
                call    DrawBat                     ; Draw the ball and bat
                halt
                call    DrawBall
                ld      ix, ObjectMovingBlock1
                call    DrawMovingBlock                
                ld      ix, ObjectMovingBlock2
                call    DrawMovingBlock
                call    DrawBat                     ; Erase the ball and bat (XOR)

                ld      bc, 32766                   ; Check to see if SPACE has been pressed
                in      a, (c)
                rra
                jp      c, MainLoop                 ; If not then keep looping
                ld      a, PLAYING                  ; Otherwise update the game state to PLAYING
                ld      (GameState), a
                jp      MainLoop

CheckDead
                cp      DEAD
                jr      nz, NextLevel
                ld      a, (Lives)
                dec     a

                push    af
                ld      (Lives), a
                add     a, 48
                ld      (LivesText + 5), a

                ld      de, LivesText
                ld      bc, 6
                call    8252
                pop     af
                cp      0
                jr      z, PlayerDead

                call    ResetBat
                call    PlayDeath

                ld      a, WAITING
                ld      (GameState), a

NextLevel
                cp      NEXTLEVEL
                jr      nz, CheckDisplayLevel
                ld      a, (CurLvl)
                inc     a
                ld      (CurLvl), a
                cp      2
                jr      nz, IncreaseLevel
                ld      a, 1
                ld      (CurLvl), a
IncreaseLevel   ld      a, DISPLAYLEVEL
                ld      (GameState), a
                call    LoadLevel
                jp      MainLoop
PlayerDead      ld      a, PLAYERDEAD
                ld      (GameState), a
                jp      MainLoop

CheckDisplayLevel
                cp      DISPLAYLEVEL
                jp      nz, CheckPlayerDead
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_TITLE
                add     hl, de
                ld      b, 0
                ld      c, (hl)
                ld      d, h 
                ld      e, l
                inc     de
                call    8252
                ld      de, 100
LevelDispWait   halt
                dec     de
                ld      a, d
                or      e
                jr      nz, LevelDispWait
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_TITLE
                add     hl, de
                ld      b, 0
                ld      c, (hl)
                add     hl, bc
                ld      b, 0
                inc     hl
                ld      c, (hl)
                ld      d, h 
                ld      e, l
                inc     de
                call    8252

                ld      a, WAITING
                ld      (GameState), a
                jp      MainLoop

CheckPlayerDead
                cp      PLAYERDEAD
                jp      nz, MainLoop
                ld      de, GameOverText
                ld      bc, 17
                call    8252
                call    WaitForSpace
                call    ClearScreen
                ld      a, 5 
                ld      (Lives), a
                ld      a, 53                       ; The number five in the character set
                ld      (LivesText + 5), a
                ld      de, LivesText
                ld      bc, 6
                call    8252
                call    ResetScore
                ld      a, 0
                ld      (CurLvl), a
                call    LoadLevel
                ld      a, DISPLAYLEVEL
                ld      (GameState), a
                call    ResetBat
                jp      MainLoop

;****************************************************************************************************************
; Load the title screen for the game
;****************************************************************************************************************
DrawTitleScreen
                ld      de, BM_SCR_ADDR
                ld      hl, TitleScreen
                ld      bc, BM_SCR_SIZE + ATTR_SCRN_SIZE
                ldir
                ret

;****************************************************************************************************************
; Load the title screen for the game
;****************************************************************************************************************
DrawBorders
                ; Draw top wall
                ld      h, 0
                ld      b, 8
                ld      c, 2
HorizLoop1      
                push    hl
                push    bc
                ld      de, HorizBlockData
                call    DrawSprite
                pop     bc
                pop     hl
                ld      a, b
                add     a, 8
                ld      b, a
                inc     h
                ld      a, h
                cp      30
                jr      nz, HorizLoop1

                ; Draw right hand wall
                ld      h, 0
                ld      b, SCRN_RIGHT
                ld      c, 9
VertLoop1
                push    hl
                push    bc
                ld      de, VertLBlockData
                call    DrawSprite
                pop     bc
                pop     hl
                ld      a,c
                add     a, 8
                ld      c, a
                inc     h
                ld      a, h
                cp      22
                jr      nz, VertLoop1

                ; Draw Left hand wall
                ld      h, 0
                ld      b, 0
                ld      c, 9
VertLoop2
                push    hl
                push    bc
                ld      de, VertRBlockData
                call    DrawSprite
                pop     bc
                pop     hl
                ld      a,c
                add     a, 8
                ld      c, a
                inc     h
                ld      a, h
                cp      22
                jr      nz, VertLoop2

                ret

;****************************************************************************************************************
; Draw Ball
; Draws the ball sprite at the location held in the ObjectBall structure
;****************************************************************************************************************
DrawBall 
                ld      de, SpriteBallData          ; Point DE to the ball sprite data
                ld      a, (ObjectBall + BALL_X_POS); Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (ObjectBall + BALL_Y_POS)
                ld      c, a
                call    DrawSprite
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the batn sprite at the location held in the ObjectBat structure
;******************************************************1**********************************************************
DrawBat 
                ld      de, SpriteBatData           ; Point DE to the ball sprite data
                ld      a, (ObjectBat + BAT_X_POS)  ; Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (ObjectBat + BAT_Y_POS)
                ld      c, a
                call    DrawSprite
                ret

;****************************************************************************************************************
; Draw Bat
; Draws the batn sprite at the location held in the ObjectBat structure
;******************************************************1**********************************************************
DrawMovingBlock 
                ld      de, SpriteBatData           ; Point DE to the ball sprite data
                ld      a, (ix + BAT_X_POS)  ; Load BC with the ball sprite objects location
                ld      b, a
                ld      a, (ix + BAT_Y_POS)
                ld      c, a
                call    DrawSprite
                ret

;************************************************************************************************************************
; Wait for space to be pressed
;************************************************************************************************************************
WaitForSpace
                ld      bc, 32766
                in      a, (c)
                rra 
                ret     nc
                jp      WaitForSpace

;************************************************************************************************************************
; Read Control Keys
;************************************************************************************************************************
ReadControlKeys 
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
                ld      ix, ObjectBat   
                ld      a, (ix + BAT_X_POS)         ; IX + 0 = X Position
                sub     (ix + BAT_SPEED)            ; IX + 2 = Speed
                cp      8                           ; Check if we are past the 0
                jp      c, HitLeftEdge              ; and jump if we are
                ld      (ix + BAT_X_POS), a         ; Update the X position with A
                ret     
HitLeftEdge         
                ld      (ix + BAT_X_POS), 8         ; Hit the edge so set the X pos to 0
                ret 

;************************************************************************************************************************
; Move bat to the right
;************************************************************************************************************************   
MoveBatRight    
                ld      ix, ObjectBat   
                ld      a, (ix + BAT_X_POS)         ; IX + 0 = X Position
                add     a, (ix + BAT_SPEED)         ; IX + 2 = Speed
                cp      PADDLE_MAX_RIGHT            ; Check if the bat is past right edge
                jp      nc, BatHitRightEdge         ; and jump if it is
                ld      (ix + BAT_X_POS), a         ; Update the X Position with A
                ret     
BatHitRightEdge         
                ld      (ix + BAT_X_POS), PADDLE_MAX_RIGHT
                ret

;************************************************************************************************************************
; Updates the position of the moving block
;************************************************************************************************************************   
UpdateMovingBlock
;                 ld      ix, ObjectMovingBlock
                ld      a, (ix + BALL_X_POS)
                add     a, (ix + BALL_XSPEED)
                ld      (ix + BALL_X_POS), a
                cp      PADDLE_MAX_RIGHT
                jp      nc, BlockHitEdge
                cp      8
                jp      c, BlockHitEdge
                ret

BlockHitEdge
                ld      a, (ix + BALL_XSPEED)
                neg
                ld      (ix + BALL_XSPEED), a
                ret

;****************************************************************************************************************
; Draw Sprite 
; Call with DE = Sprite data, B = X, C = Y
;****************************************************************************************************************
DrawSprite      
                ; Grab the width and height of the sprite we are going to draw
                ld      a, (de)
                ld      (_SpriteWidth + 1), a
                inc     de
                ld      a, (de)
                ld      (_SpriteHeight + 1), a
                inc     de

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
                ld      (_XOffset + 1), a           ; Store the X Byte Offset
        
                ; Load IX with the first address of the y-axis lookup table
                ld      b, 0                        ; Clear B
                ld      ix, ScreenLineLookup        ; Load IY with the lookup table address
                add     ix, bc                      ; Increment IX by the Y pixel position
                add     ix, bc                      ; twice as the table contains word values
                
_SpriteHeight   ld      b, 0                        ; Load the pixel height of the sprite (bits)
    
DrawRow             
                ld      a, (ix + 0)                 ; Get the current line
_XOffset        or      0                           ; Merge in our X Offset
                ld      l, a                        ; Load the merged low byte in L
                ld      h, (ix + 1)                 ; Get the high byte from the lookup table
                inc     ix  
                inc     ix                          ; Move to the next line which is a word away
    
                push    bc                          ; Save B as we will load it with the sprite width
_SpriteWidth    ld      b, 0                        ; Load B with the number of bytes the sprite is wide
    
DrawColumn  
                ld      a, (de)                     ; Grab the first byte of sprite data into A             
                inc     de                          ; Move to the next byte of sprite data
                xor     (hl)                        ; Merge the screen contents with the sprite data
                ld      (hl), a                     ; Load the merged data back into the screen
                inc     l                           ; Move to the next byte of screen memory
                djnz    DrawColumn                  ; Draw another column if needed
    
                pop     bc                          ; Restore B which holds the row count
                
                ld      a, (de)                     ; Again for byte 2          
                inc     de  
                xor     (hl)                            
                ld      (hl), a     
                inc     l   
                    
                djnz    DrawRow                     ; If not zero process the next line
    
                ret                                 ; All done!

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
                ld      ix, ObjectBall
MoveX
                ld      a, (ix + BALL_X_POS)
                add     a, (ix + BALL_XSPEED)
                cp      SCRN_RIGHT - BALL_PIXEL_WIDTH
                jr      nc, BounceX
                cp      SCRN_LEFT
                jr      c, BounceX
                ld      (ix + BALL_X_POS), a
MoveY           
                ld      a, (ix + BALL_Y_POS)
                add     a, (ix + BALL_YSPEED)
                cp      SCRN_BOTTOM
                jr      nc, HitBottom
                cp      SCRN_TOP
                jr      c, BounceY
                ld      (ix + BALL_Y_POS), a
                ld      a, (ix + BALL_YSPEED)
                cp      0
                jp      m, BallCharPos              ; Only check for a bat collision of the ball is moving down the screen
                call    CheckBatCollison
                jp      BallCharPos
HitBottom
                ld      a, DEAD
                ld      (GameState), a
                jp      BallCharPos
BounceX         
                ld      a, (ix + BALL_XSPEED)
                neg
                ld      (ix + BALL_XSPEED), a
                cp      0
                jp      m, AlignRight
                ld      a, SCRN_LEFT
                ld      (ix + BALL_X_POS), a
                jp      MoveY
AlignRight      ld      a, SCRN_RIGHT - BALL_PIXEL_WIDTH
                ld      (ix + BALL_X_POS), a 
                jp      MoveY
BounceY         
                ld      a, (ix + BALL_YSPEED)
                neg
                ld      (ix + BALL_YSPEED), a
                ld      a, SCRN_TOP
                ld      (ix + BALL_Y_POS), a

BallCharPos     ; Update the balls character position used in block collision detection
                ld      a, (ix + BALL_X_POS)        ; Middle Top
                add     a, BALL_PIXEL_WIDTH / 2
                ld      d, a
                ld      e, (ix + BALL_Y_POS)
                dec     e                           ; Move 1 pixel left
                call    GetCharLocation
                ld      (BallMT), bc

                ld      a, (ix + BALL_X_POS)        ; Middle Right
                add     a, BALL_PIXEL_WIDTH - 1
                ld      d, a
                ld      a, (ix + BALL_Y_POS)
                add     a, BALL_PIXEL_HEIGHT / 2
                ld      e, a
                call    GetCharLocation
                ld      (BallMR), bc

                ld      a, (ix + BALL_X_POS)        ; Middle Bottom
                add     a, BALL_PIXEL_WIDTH / 2
                ld      d, a
                ld      a, (ix + BALL_Y_POS)
                add     a, BALL_PIXEL_HEIGHT - 1    ; Move 1 pixel up into the ball
                ld      e, a
                call    GetCharLocation
                ld      (BallMB), bc

                ld      d, (ix + BALL_X_POS)        ; Middle Left
                inc     d                           ; Move 1 pixel right
                ld      a, (ix + BALL_Y_POS)
                add     a, BALL_PIXEL_HEIGHT / 2
                ld      e, a
                call    GetCharLocation
                ld      (BallML), bc

                call    CheckBlockCollision         ; Now go see if the ball has hit something :)

                ret

;****************************************************************************************************************
; Check to see if the ball has collided with the bat and if so update the properties of the ball as necessart
;****************************************************************************************************************
CheckBatCollison 

                ; First check if the bottom of the ball has reached the top of the bat
                ld      a, (ObjectBat + BAT_Y_POS)  ; Load the Y position of the bat
                sub     (ix + BAT_HEIGHT)           ; Sub off the height of the ball in pixels
                cp      (ix + BAT_Y_POS)            ; Compare that with the balls y position
                ret     nc                          ; NC = A > B so we are done
                
                ; If the ball has already passed the top of the bat then carry on
                ld      a, (ObjectBat + BAT_Y_POS)
                cp      (ix + BALL_Y_POS)
                ret     c

                ; To check where on the bat the ball has collided we put the ball into bat space coordinates
                ; by subtracting the x position of the bat from the x position of the ball
                ld      a, (ObjectBat + BAT_X_POS)
                ld      b, a
                ld      a, (ix + BALL_X_POS)
                add     a, BALL_PIXEL_WIDTH / 2
                sub     b                           ; Subtract the bat.x from ball.x
                ret     c                           ; A < 0 so the ball is left of the bat
                cp      BAT_PIXEL_WIDTH             ; Check if ball.x > bat.pixel_width
                ret     nc                          ; If it is then ball to the right of the bat

                push    af

                ld      b, 20
                call    PlayClick

                ; Check the balls x direction and based on that perform the bats collision checks
                ld      a, (ix + BALL_XSPEED)
                cp      0 
                jp      m, LeftDirection

RightDirection  
                pop     af
                cp      6
                jr      nc, RArea2
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 0
                add     hl, de
                ld      a, (hl)
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
RArea2          cp      12
                jr      nc, RArea3
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
RArea3          cp      18
                jr      nc, RArea4
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
RArea4          cp      24
                jr      nc, AdjustYDir
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 3
                add     hl, de
                ld      a, (hl)
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir

LeftDirection  
                pop     af
                cp      6
                jr      nc, LArea2
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 3
                add     hl, de
                ld      a, (hl)
                neg
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
LArea2          cp      12
                jr      nc, LArea3
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 2
                add     hl, de
                ld      a, (hl)
                neg
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
LArea3          cp      18
                jr      nc, LArea4
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 1
                add     hl, de
                ld      a, (hl)
                neg
                ld      (ix + BALL_XSPEED), a
                jp      AdjustYDir
LArea4          cp      24
                jr      nc, AdjustYDir
                ld      hl, (CurLvlAddr)
                ld      de, LEVEL_BAT_SPEEDS + 0
                add     hl, de
                ld      a, (hl)
                neg
                ld      (ix + BALL_XSPEED), a

AdjustYDir 
                ld      a, (ObjectBat + BAT_Y_POS)  ; Update the Y pos of the ball so that it rests ontop of the bat
                sub     8   
                ld      (ix + BALL_Y_POS), a
                ld      a, (ix + BALL_YSPEED)
                neg                                 ; Change the balls Y direction
                ld      (ix + BALL_YSPEED), a   
                ret 

;****************************************************************************************************************
; Check the edge point on the ball to see if they have collided with a block based on the blocks attribute colour
;****************************************************************************************************************
CheckBlockCollision 
                ld      a, (BallMT)
                ld      d, a
                ld      a, (BallMT + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5               
                jr      z, MiddleRight  
                ld      a, (ObjectBall + BALL_YSPEED)
                cp      0
                jp      p, MT0
                neg
                ld      (ObjectBall + BALL_YSPEED), a
MT0             call    RemoveBlock
                ret
MiddleRight 
                ld      a, (BallMR)
                ld      d, a
                ld      a, (BallMR + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                jr      z, MiddleBottom
                ld      a, (ObjectBall + BALL_XSPEED)
                neg
                ld      (ObjectBall + BALL_XSPEED), a
                call    RemoveBlock
                ret
MiddleBottom
                ld      a, (BallMB)
                ld      d, a
                ld      a, (BallMB + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                jr      z, MiddleLeft
                ld      a, (ObjectBall + BALL_YSPEED)
                neg
                ld      (ObjectBall + BALL_YSPEED), a   
                call    RemoveBlock
                ret
MiddleLeft 
                ld      a, (BallML)
                ld      d, a
                ld      a, (BallML + 1)
                ld      e, a
                push    de
                call    GetCharAttr
                pop     de
                cp      5
                ret     z
                ld      a, (ObjectBall + BALL_XSPEED)
                neg
                ld      (ObjectBall + BALL_XSPEED), a   
                call    RemoveBlock
                ret

;****************************************************************************************************************
; Remove the block that contains the x,y provided in DE
;****************************************************************************************************************
RemoveBlock
                ld      b, 100
                call    PlayClick

                ld      hl, ScoreText + 10      
                ld      b, 6                
                call    UpdateScore                 
                ld      hl, ScoreText + 11          
                ld      b, 5                        
                call    UpdateScore    

                push    de
                push    bc
                ld      de, ScoreText               ; Print the score on the screen
                ld      bc, 12
                call    8252
                pop     bc
                pop     de

                ld      a, (LevelBlockCount) 
                dec     a                           ; Decrement the number of blocks 
                ld      (LevelBlockCount), a                    

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
                call    DrawSprite
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
                call    DrawSprite
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

                ld      de, ATTR_SCRN_ADDR          ; Add on the base ATTR screen address
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

                ld      de, ATTR_SCRN_ADDR          ; Add on the base ATTR screen address
                add     hl, de

                ld      a, (hl)                     ; Load the attribute at HL
                ret

;****************************************************************************************************************
; Reset the bats X pos to the center of play area
;****************************************************************************************************************
ResetBat    
                ld      a, 76                       
                ld      (ObjectBat + BALL_X_POS), a
                ret

;****************************************************************************************************************
; Load Level
; A = Level to load 
;****************************************************************************************************************
LoadLevel 
                ld      de, LevelLookup             ; Load DE with the address of the Level Loopup Table
                ld      a, (CurLvl)                 ; Load A with the level number to load
                ld      l, a
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the level lookup table entries are words
                add     hl, de                      ; Add base address of level lookup table which is held in DE
                ld      e, (hl)                     ; Pop the address at HL into DE
                inc     hl
                ld      d, (hl)
                ld      (CurLvlAddr), de            ; Store away 
                ld      hl, (CurLvlAddr)            ; and load HL with that address

                ; Load the block colours from the level data
                ld      de, ATTR_SCRN_ADDR + (32 * 4)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_2
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 5)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_3
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 6)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_4
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 7)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_5
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 8)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_6
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 9)
                ld      bc, ROW_CLR_BYTES
                ldir

                ld      hl, (CurLvlAddr)
                ld      de, LVL_CLR_ROW_7
                add     hl, de
                ld      de, ATTR_SCRN_ADDR + (32 * 10)
                ld      bc, ROW_CLR_BYTES
                ldir

                ; Draw the blocks based on the levels block loopup table
NextBlockRow    ld      a, 0
                ld      (CurBlockCol), a
                ld      (CurBlockRow), a
                ld      (CurBlockX), a
                ld      a, 32
                ld      (CurBlockY), a

DrawNextBlock   ld      bc, (CurBlockY)
                ld      a, (hl)
                inc     hl
                cp      1
                jr      nz, SkipBlock

                ld      a, (LevelBlockCount)
                inc     a
                ld      (LevelBlockCount), a

                push    hl
                ld      de, SpriteBlockData
                call    DrawSprite
                pop     hl

SkipBlock       ld      a, (CurBlockX)
                add     a, 16
                ld      (CurBlockX), a
                ld      a, (CurBlockCol)
                inc     a
                ld      (CurBlockCol), a
                cp      15
                jr      nz, DrawNextBlock

                ld      a, 0
                ld      (CurBlockX), a
                ld      a, (CurBlockY)
                add     a, 8
                ld      (CurBlockY), a
                ld      a, 0
                ld      (CurBlockCol), a

                ld      a, (CurBlockRow)
                inc     a
                ld      (CurBlockRow), a
                cp      7
                jr      nz, DrawNextBlock

                ret

;****************************************************************************************************************
; Update the score
;****************************************************************************************************************
UpdateScore     ld      a, (hl)                     ; current value of digit.
                add     a, b                        ; add points to this digit.
                ld      (hl), a                     ; place new digit back in string.
                cp      58                          ; more than ASCII value '9'?
                ret     c                           ; no - relax.
                sub     10                          ; subtract 10.
                ld      (hl), a                     ; put new character back in string.
UpdateScore0    dec     hl                          ; previous character in string.
                inc     (hl)                        ; up this by one.
                ld      a, (hl)                     ; what's the new value?
                cp      58                          ; gone past ASCII nine?
                ret     c                           ; no, scoring done.
                sub     10                          ; down by ten.
                ld      (hl), a                     ; put it back
                jp      UpdateScore0                ; go round again.

;****************************************************************************************************************
; Reset score to 0000000
;****************************************************************************************************************
ResetScore
                ld      de, ScoreText + 5
                ld      b, 7
                ld      a, '0'
MakeZero        ld      (de), a
                inc     de
                djnz    MakeZero
                ld      de, ScoreText               ; Print the score on the screen
                ld      bc, 12
                call    8252
                ret

;****************************************************************************************************************
; Draw the info panel
;****************************************************************************************************************
DrawInfoPanel 
                ld      b, 24
                ld      de, ATTR_SCRN_ADDR + 22
                ld      (InfoPanelAddr), de

InfoPanelLoop   
                push    bc
                ld      hl, InfoPanel
                ld      bc, 10
                ldir

                ld      de, 32
                ld      hl, (InfoPanelAddr)
                add     hl, de
                ld      d, h
                ld      e, l
                ld      (InfoPanelAddr), de

                pop     bc
                djnz    InfoPanelLoop
                ret

;****************************************************************************************************************
; Play click sound with b = length of the loop
;****************************************************************************************************************
PlayClick       
                ld      a, 16
                and     248
                out     (254), a
ClickLoop0      djnz    ClickLoop0
                ld      a, 0
                and     248
                out     (254), a

                ld      a, 16
                and     248
                out     (254), a
ClickLoop1      djnz    ClickLoop1
                ld      a, 0
                and     248
                out     (254), a
                ret

;****************************************************************************************************************
; Play death sound with b = length of the loop
;****************************************************************************************************************
PlayDeath
                ld      a, 0
                ld      (23624), a                  ; Set the Border colour BASIC variable to black
                ld      hl,500                      ; starting pitch.
                ld      b,150                       ; length of pitch bend.
DeathLoop       push    bc
                push    hl                          ; store pitch.
                ld      de,1                        ; very short duration.
                call    949                         ; ROM beeper routine.
                pop     hl                          ; restore pitch.
                inc     hl                          ; pitch going up.
                pop     bc
                djnz    DeathLoop                   ; repeat.
                ret

;****************************************************************************************************************
; Variables
;****************************************************************************************************************
GameState       db      0                           ; 1 = Playing, 2 = Waiting to Start, 4 = Dead
LevelBlockCount db      0                           ; Number of blocks in this level

CurLvl          db      0                           ; Stores the current level

CurBlockRow     db      0                           ; Variables used to store detalis of the blocks when rendering
CurBlockCol     db      0
CurBlockY       db      0
CurBlockX       db      0
CurLvlAddr      dw      0

BallMT          dw      0                           ; Stores the x, y attr position of the balls collision points
BallMR          dw      0
BallMB          dw      0
BallML          dw      0

InfoPanelAddr   dw      0                           ; Stores a pointer to the info panel attribute data

Lives           db      5                           ; Number of lives each player has at the start of the game

;****************************************************************************************************************
; Text
;****************************************************************************************************************
ScoreLabelText  db      16, 6, 22, 0, 1, 'SCORE'
ScoreText       db      16, 6, 22, 0, 8, '0000000'
LivesLabelText  db      16, 6, 22, 0, 24, 'LIVES'
LivesText       db      16, 6, 22, 0, 30, '5'
GameOverText    db      16, 2, 17, 2, 22, 15, 11, 'GAME  OVER'

;****************************************************************************************************************
; Object data
;****************************************************************************************************************
ObjectBall      db      92                          ; IX + 0 = X position
                db      130                         ; IX + 1 = Y position
                db      1                           ; IX + 2 = Xdir
                db      1                           ; IX + 3 = Ydir
                db      1                           ; IX + 4 = XSpeed
                db      2                           ; IX + 5 = YSpeed
                db      1                           ; IX + 6 = Sprite data width (bytes)
                db      8                           ; IX + 7 = Sprite data height (bits)
                        
ObjectBat       db      76                          ; IX + 0 = X Position                       
                db      175                         ; IX + 1 = Y Position
                db      4                           ; IX + 2 = Speed
                db      0                           ; IX + 3 = unused   
                db      0                           ; IX + 4 = unused   
                db      0                           ; IX + 5 = unused
                db      3                           ; IX + 6 = Sprite data width (bytes)
                db      8                           ; IX + 7 = Sprite data height (bits)

ObjectMovingBlock1
                db      76                          ; IX + 0 = X position
                db      120                         ; IX + 1 = Y position
                db      0                           ; IX + 2 = Xdir
                db      0                           ; IX + 3 = Ydir
                db      2                           ; IX + 4 = XSpeed
                db      0                           ; IX + 5 = YSpeed
                db      3                           ; IX + 6 = Sprite data width (bytes)
                db      8                           ; IX + 7 = Sprite data height (bits)

ObjectMovingBlock2
                db      76                          ; IX + 0 = X position
                db      130                         ; IX + 1 = Y position
                db      0                           ; IX + 2 = Xdir
                db      0                           ; IX + 3 = Ydir
                db      -2                           ; IX + 4 = XSpeed
                db      0                           ; IX + 5 = YSpeed
                db      3                           ; IX + 6 = Sprite data width (bytes)
                db      8                           ; IX + 7 = Sprite data height (bits)

;****************************************************************************************************************
; Includes
;****************************************************************************************************************
include     Constants.asm
include     Levels.asm
include     Title.asm

                END SetBorder
