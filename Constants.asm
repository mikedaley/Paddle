;*******************************************************************************************
; Value Constants
;*******************************************************************************************
SCRN_BUFFER         equ         57856
BM_SCR_ADDR         equ         16384                            ; Location in memory of the bitmap screen data
BM_SCR_SIZE         equ         6144                             ; Size of the bitmap screen data
ATTR_SCRN_ADDR      equ         22528                            ; Location in memory of the screen attribute data
ATTR_SCRN_SIZE      equ         768                              ; Size of the screen attribute data
SCR_SIZE            equ         6911                             ; Full size of both bitmap and attribute screen data
PADDLE_MAX_RIGHT    equ         224                              ; Furthest pixel to the right the paddle can be drawn
SCRN_LEFT           equ         8
SCRN_RIGHT          equ         248
SCRN_TOP            equ         10
SCRN_BOTTOM         equ         175

NUM_BLOCKS          equ         3

; Offsets into the BALL structure
BALL_X_POS          equ         0
BALL_Y_POS          equ         1
BALL_X_DIR          equ         2
BALL_Y_DIR          equ         3
BALL_XSPEED         equ         4
BALL_YSPEED         equ         5
BALL_WIDTH          equ         6
BALL_HEIGHT         equ         7

; BALL constants
BALL_PIXEL_HEIGHT   equ         8
BALL_PIXEL_WIDTH    equ         8

; Offsets into the BAT structure
BAT_X_POS           equ         0
BAT_Y_POS           equ         1
BAT_SPEED           equ         2
BAT_WIDTH           equ         6
BAT_HEIGHT          equ         7

; BAT constants
BAT_PIXEL_HEIGHT    equ         8
BAT_PIXEL_WIDTH     equ         23

; Game States
PLAYING             equ         1
WAITING             equ         2
DEAD                equ         4
DISPLAYLEVEL        equ         8
NEXTLEVEL           equ         16
PLAYERDEAD          equ         32

;*******************************************************************************************
; Block sprite
;*******************************************************************************************
SpriteBlockData:
                    db 2                                         ; Width in bytes
                    db 8                                         ; Height in bits

                    dw SpriteBlock0, SpriteBlock1, SpriteBlock2, SpriteBlock3
                    dw SpriteBlock4, SpriteBlock5, SpriteBlock6, SpriteBlock7

SpriteBlock0:       db %00000000, %00000000, %00000000
                    db %01111111, %11111110, %00000000
                    db %01111111, %11111110, %00000000
                    db %01111111, %11111110, %00000000
                    db %01111111, %11111110, %00000000
                    db %01111111, %11111110, %00000000
                    db %01111111, %11111110, %00000000
                    db %00000000, %00000000, %00000000

SpriteBlock1:       db %00000000, %00000000, %00000000
                    db %00111111, %11111111, %00000000
                    db %00111111, %11111111, %00000000
                    db %00111111, %11111111, %00000000
                    db %00111111, %11111111, %00000000
                    db %00111111, %11111111, %00000000
                    db %00111111, %11111111, %00000000
                    db %00000000, %00000000, %00000000

SpriteBlock2:       db %00000000, %00000000, %00000000
                    db %00011111, %11111111, %10000000
                    db %00011111, %11111111, %10000000
                    db %00011111, %11111111, %10000000
                    db %00011111, %11111111, %10000000
                    db %00011111, %11111111, %10000000
                    db %00011111, %11111111, %10000000
                    db %00000000, %00000000, %00000000

SpriteBlock3:       db %00000000, %00000000, %00000000
                    db %00001111, %11111111, %11000000
                    db %00001111, %11111111, %11000000
                    db %00001111, %11111111, %11000000
                    db %00001111, %11111111, %11000000
                    db %00001111, %11111111, %11000000
                    db %00001111, %11111111, %11000000
                    db %00000000, %00000000, %00000000

SpriteBlock4:       db %00000000, %00000000, %00000000
                    db %00000111, %11111111, %11100000
                    db %00000111, %11111111, %11100000
                    db %00000111, %11111111, %11100000
                    db %00000111, %11111111, %11100000
                    db %00000111, %11111111, %11100000
                    db %00000111, %11111111, %11100000
                    db %00000000, %00000000, %00000000

SpriteBlock5:       db %00000000, %00000000, %00000000
                    db %00000011, %11111111, %11110000
                    db %00000011, %11111111, %11110000
                    db %00000011, %11111111, %11110000
                    db %00000011, %11111111, %11110000
                    db %00000011, %11111111, %11110000
                    db %00000011, %11111111, %11110000
                    db %00000000, %00000000, %00000000

SpriteBlock6:       db %00000000, %00000000, %00000000
                    db %00000001, %11111111, %11111000
                    db %00000001, %11111111, %11111000
                    db %00000001, %11111111, %11111000
                    db %00000001, %11111111, %11111000
                    db %00000001, %11111111, %11111000
                    db %00000001, %11111111, %11111000
                    db %00000000, %00000000, %00000000

SpriteBlock7:       db %00000000, %00000000, %00000000
                    db %00000000, %11111111, %11111100
                    db %00000000, %11111111, %11111100
                    db %00000000, %11111111, %11111100
                    db %00000000, %11111111, %11111100
                    db %00000000, %11111111, %11111100
                    db %00000000, %11111111, %11111100
                    db %00000000, %00000000, %00000000

;*******************************************************************************************
; Ball Sprite
;*******************************************************************************************
SpriteBallData:
                    db 1                                                    ; Width in bytes
                    db 8                                                    ; Height in bits

                    dw SpriteBall0, SpriteBall1, SpriteBall2, SpriteBall3   ; Sprite shift lookup table
                    dw SpriteBall4, SpriteBall5, SpriteBall6, SpriteBall7

SpriteBall0:        db %00111100, %00000000
                    db %01100110, %00000000
                    db %11011111, %00000000
                    db %10111111, %00000000
                    db %10111111, %00000000
                    db %11111111, %00000000
                    db %01111110, %00000000
                    db %00111100, %00000000

SpriteBall1:        db %00011110, %00000000
                    db %00110011, %00000000
                    db %01101111, %10000000
                    db %01011111, %10000000
                    db %01011111, %10000000
                    db %01111111, %10000000
                    db %00111111, %00000000
                    db %00011110, %00000000

SpriteBall2:        db %00001111, %00000000
                    db %00011001, %10000000
                    db %00110111, %11000000
                    db %00101111, %11000000
                    db %00101111, %11000000
                    db %00111111, %11000000
                    db %00011111, %10000000
                    db %00001111, %00000000

SpriteBall3:        db %00000111, %10000000
                    db %00001100, %11000000
                    db %00011011, %11100000
                    db %00010111, %11100000
                    db %00010111, %11100000
                    db %00011111, %11100000
                    db %00001111, %11000000
                    db %00000111, %10000000

SpriteBall4:        db %00000011, %11000000
                    db %00000110, %01100000
                    db %00001101, %11110000
                    db %00001011, %11110000
                    db %00001011, %11110000
                    db %00001111, %11110000
                    db %00000111, %11100000
                    db %00000011, %11000000

SpriteBall5:        db %00000001, %11100000
                    db %00000011, %00110000
                    db %00000110, %11111000
                    db %00000101, %11111000
                    db %00000101, %11111000
                    db %00000111, %11111000
                    db %00000011, %11110000
                    db %00000001, %11100000

SpriteBall6:        db %00000000, %11110000
                    db %00000001, %10011000
                    db %00000011, %01111100
                    db %00000010, %11111100
                    db %00000010, %11111100
                    db %00000011, %11111100
                    db %00000001, %11111000
                    db %00000000, %11110000

SpriteBall7:        db %00000000, %01111000
                    db %00000000, %11001100
                    db %00000001, %10111110
                    db %00000001, %01111110
                    db %00000001, %01111110
                    db %00000001, %11111110
                    db %00000000, %11111100
                    db %00000000, %01111000

;*******************************************************************************************
; Bat Sprite
;*******************************************************************************************
SpriteBatData:  
                    db 3                                                    ; Width in bytes
                    db 8                                                    ; Height in bits

                    dw SpriteBatData0, SpriteBatData1, SpriteBatData2, SpriteBatData3
                    dw SpriteBatData4, SpriteBatData5, SpriteBatData6, SpriteBatData7
    
SpriteBatData0:     db %00111111, %11111111, %11111100, %00000000
                    db %01001001, %00100100, %10010010, %00000000
                    db %01010010, %01001001, %00100110, %00000000
                    db %10100100, %10010010, %01001001, %00000000
                    db %11001001, %00100100, %10010011, %00000000
                    db %01010010, %01001001, %00100110, %00000000
                    db %01100100, %10010010, %01001010, %00000000
                    db %00111111, %11111111, %11111100, %00000000

SpriteBatData1:     db %00011111, %11111111, %11111110, %00000000
                    db %00100100, %10010010, %01001001, %00000000
                    db %00101001, %00100100, %10010011, %00000000
                    db %01010010, %01001001, %00100100, %10000000
                    db %01100100, %10010010, %01001001, %10000000
                    db %00101001, %00100100, %10010011, %00000000
                    db %00110010, %01001001, %00100101, %00000000
                    db %00011111, %11111111, %11111110, %00000000
    
SpriteBatData2:     db %00001111, %11111111, %11111111, %00000000
                    db %00010010, %01001001, %00100100, %10000000
                    db %00010100, %10010010, %01001001, %10000000
                    db %00101001, %00100100, %10010010, %01000000
                    db %00110010, %01001001, %00100100, %11000000
                    db %00010100, %10010010, %01001001, %10000000
                    db %00011001, %00100100, %10010010, %10000000
                    db %00001111, %11111111, %11111111, %00000000

SpriteBatData3:     db %00000111, %11111111, %11111111, %10000000
                    db %00001001, %00100100, %10010010, %01000000
                    db %00001010, %01001001, %00100100, %11000000
                    db %00010100, %10010010, %01001001, %00100000
                    db %00011001, %00100100, %10010010, %01100000
                    db %00001010, %01001001, %00100100, %11000000
                    db %00001100, %10010010, %01001001, %01000000
                    db %00000111, %11111111, %11111111, %10000000

SpriteBatData4:     db %00000011, %11111111, %11111111, %11000000
                    db %00000100, %10010010, %01001001, %00100000
                    db %00000101, %00100100, %10010010, %01100000
                    db %00001010, %01001001, %00100100, %10010000
                    db %00001100, %10010010, %01001001, %00110000
                    db %00000101, %00100100, %10010010, %01100000
                    db %00000110, %01001001, %00100100, %10100000
                    db %00000011, %11111111, %11111111, %11000000

SpriteBatData5:     db %00000001, %11111111, %11111111, %11100000
                    db %00000010, %01001001, %00100100, %10010000
                    db %00000010, %10010010, %01001001, %00110000
                    db %00000101, %00100100, %10010010, %01001000
                    db %00000110, %01001001, %00100100, %10011000
                    db %00000010, %10010010, %01001001, %00110000
                    db %00000011, %00100100, %10010010, %01010000
                    db %00000001, %11111111, %11111111, %11100000

SpriteBatData6:     db %00000000, %11111111, %11111111, %11110000
                    db %00000001, %00100100, %10010010, %01001000
                    db %00000001, %01001001, %00100100, %10011000
                    db %00000010, %10010010, %01001001, %00100100
                    db %00000011, %00100100, %10010010, %01001100
                    db %00000001, %01001001, %00100100, %10011000
                    db %00000001, %10010010, %01001001, %00101000
                    db %00000000, %11111111, %11111111, %11110000

SpriteBatData7:     db %00000000, %01111111, %11111111, %11111000
                    db %00000000, %10010010, %01001001, %00100100
                    db %00000000, %10100100, %10010010, %01001100
                    db %00000001, %01001001, %00100100, %10010010
                    db %00000001, %10010010, %01001001, %00100110
                    db %00000000, %10100100, %10010010, %01001100
                    db %00000000, %11001001, %00100100, %10010100
                    db %00000000, %01111111, %11111111, %11111000

;*******************************************************************************************
; Horizontal block graphic
;*******************************************************************************************
HorizBlockData
                    db 1                                                    ; Width in bytes
                    db 8                                                    ; Height in bits

                    dw HorizBlockData0, HorizBlockData0, HorizBlockData0, HorizBlockData0
                    dw HorizBlockData0, HorizBlockData0, HorizBlockData0, HorizBlockData0

HorizBlockData0
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %00000000, %00000000
                    db %11111111, %00000000

;*******************************************************************************************
; Vertical block graphic right edge
;*******************************************************************************************
VertRBlockData
                    db 1                                                    ; Width in bytes
                    db 8                                                    ; Height in bits

                    dw VertRBlockData0, VertRBlockData0, VertRBlockData0, VertRBlockData0
                    dw VertRBlockData0, VertRBlockData0, VertRBlockData0, VertRBlockData0

VertRBlockData0
                    db %00000001, %00000000
                    db %00000011, %00000000
                    db %00000101, %00000000
                    db %00001001, %00000000
                    db %00010001, %00000000
                    db %00100001, %00000000
                    db %01000001, %00000000
                    db %10000001, %00000000

;*******************************************************************************************
; Vertical block graphic left edge
;*******************************************************************************************
VertLBlockData
                    db 1                                                    ; Width in bytes
                    db 8                                                    ; Height in bits

                    dw VertLBlockData0, VertLBlockData0, VertLBlockData0, VertLBlockData0
                    dw VertLBlockData0, VertLBlockData0, VertLBlockData0, VertLBlockData0

VertLBlockData0
                    db %10000000, %00000000
                    db %11000000, %00000000
                    db %10100000, %00000000
                    db %10010000, %00000000
                    db %10001000, %00000000
                    db %10000100, %00000000
                    db %10000010, %00000000
                    db %10000001, %00000000

;*******************************************************************************************
; Right hand info panel data
;*******************************************************************************************
InfoPanel:
                    db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

;*******************************************************************************************
; Y-Axis screen memory lookup table
;*******************************************************************************************   
ScreenLineLookup:   ds 2 * 192
