;*******************************************************************************************
; Block sprite
;*******************************************************************************************
SpriteBlockData:
                    db 3                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw SpriteBlock0, SpriteBlock0 + 24 * 1, SpriteBlock0 + 24 * 2, SpriteBlock0 + 24 * 3
                    dw SpriteBlock0 + 24 * 4, SpriteBlock0 + 24 * 5, SpriteBlock0 + 24 * 6, SpriteBlock0 + 24 * 7

SpriteBlock0:       db %11111111, %11111110, %00000000
                    db %11001111, %11111110, %00000000
                    db %10111111, %11111110, %00000000
                    db %10111101, %01010100, %00000000
                    db %11101010, %10101010, %00000000
                    db %01010101, %01010100, %00000000
                    db %10101010, %10101010, %00000000
                    db %00000000, %00000000, %00000000

                    ds 24 * 7

;*******************************************************************************************
; Ball Sprite
;*******************************************************************************************
SpriteBallData:
                    db 2                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw SpriteBall0, SpriteBall0 + 16 * 1, SpriteBall0 + 16 * 2, SpriteBall0 + 16 * 3
                    dw SpriteBall0 + 16 * 4, SpriteBall0 + 16 * 5, SpriteBall0 + 16 * 7, SpriteBall0 + 16 * 7

SpriteBall0:        db %00111100, %00000000
                    db %01100110, %00000000
                    db %11011111, %00000000
                    db %10111111, %00000000
                    db %10111111, %00000000
                    db %11111111, %00000000
                    db %01111110, %00000000
                    db %00111100, %00000000

                    ds 16 * 7
;*******************************************************************************************
; Small Ball Data
;*******************************************************************************************
SmallBallData
                    db 2                          ; Width in bytes
                    db 5                          ; Height in pixels
                    dw SmallBallData0, SmallBallData0 + 10 * 1, SmallBallData0 + 10 * 2, SmallBallData0 + 10 * 3
                    dw SmallBallData0 + 10 * 4, SmallBallData0 + 10 * 5, SmallBallData0 + 10 * 6, SmallBallData0 + 10 * 7

SmallBallData0
                    db %01110000, %00000000
                    db %10011000, %00000000
                    db %10111000, %00000000
                    db %11111000, %00000000
                    db %01110000, %00000000

                    ds 10 * 7

;*******************************************************************************************
; Bat Sprite
;*******************************************************************************************    
SpriteBatFrameTable:
                    dw SpriteBatDataFrame0, SpriteBatDataFrame1, SpriteBatDataFrame2, SpriteBatDataFrame1

SpriteBatDataFrame0:  
                    db 4                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw SpriteBatData0, SpriteBatData0 + 32 * 1, SpriteBatData0 + 32 * 2, SpriteBatData0 + 32 * 3
                    dw SpriteBatData0 + 32 * 4, SpriteBatData0 + 32 * 5, SpriteBatData0 + 32 * 6, SpriteBatData0 + 32 * 7

SpriteBatData0:     
                    db %00000000, %00000000, %00000000, %00000000
                    db %01010101, %01011010, %10101010, %00000000
                    db %11110000, %00111100, %00001111, %00000000
                    db %10111111, %11100111, %11111101, %00000000
                    db %11011111, %11100111, %11111011, %00000000
                    db %10110000, %00111100, %00001101, %00000000
                    db %11111000, %00000000, %00011111, %00000000
                    db %01111111, %11111111, %11111110, %00000000

                    ds 32 * 71     ; Create enough space for the shifted versions of this sprite frame
    
SpriteBatDataFrame1:  
                    ; The bat is animated so there is a lookup table for each frame of animation
                    db 4                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw SpriteBatData1, SpriteBatData1 + 32 * 1, SpriteBatData1 + 32 * 2, SpriteBatData1 + 32 * 3
                    dw SpriteBatData1 + 32 * 4, SpriteBatData1 + 32 * 5, SpriteBatData1 + 32 * 6, SpriteBatData1 + 32 * 7

SpriteBatData1:     
                    db %00000000, %00000000, %00000000, %00000000
                    db %01010101, %01011010, %10101010, %00000000
                    db %11110000, %11000011, %00001111, %00000000
                    db %10111111, %10011001, %11111101, %00000000
                    db %11011111, %10011001, %11111011, %00000000
                    db %10110000, %11000011, %00001101, %00000000
                    db %11111000, %00000000, %00011111, %00000000
                    db %01111111, %11111111, %11111110, %00000000

                    ds 32 * 71

SpriteBatDataFrame2:  
                    db 4                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw SpriteBatData2, SpriteBatData2 + 32 * 1, SpriteBatData2 + 32 * 2, SpriteBatData2 + 32 * 3
                    dw SpriteBatData2 + 32 * 4, SpriteBatData2 + 32 * 5, SpriteBatData2 + 32 * 6, SpriteBatData2 + 32 * 7

SpriteBatData2:     
                    db %00000000, %00000000, %00000000, %00000000
                    db %01010101, %01011010, %10101010, %00000000
                    db %11110011, %00000000, %11001111, %00000000
                    db %10111110, %01111110, %01111101, %00000000
                    db %11011110, %01111110, %01111011, %00000000
                    db %10110011, %00000000, %11001101, %00000000
                    db %11111000, %00000000, %00011111, %00000000
                    db %01111111, %11111111, %11111110, %00000000

                    ds 32 * 71

;*******************************************************************************************
; Score Sprite
;*******************************************************************************************
Score115
                    dw Score115_0, Score115_0 + 48 * 1, Score115_0 + 48 * 2, Score115_0 + 48 * 3
                    dw Score115_0 + 48 * 4, Score115_0 + 48 * 5, Score115_0 + 48 * 6, Score115_0 + 48 * 7

Score115_0
                    db %00111011, %11111110       ; Mask 
                    db %00111011, %11111110       ; Sprite

                    db %01111111, %11111110
                    db %01101110, %11000010

                    db %01111111, %11111110
                    db %01001100, %11011110

                    db %01111111, %11111110
                    db %01101110, %11000110

                    db %00111111, %11111110
                    db %00101110, %11111010

                    db %01111111, %11111110
                    db %01101110, %11111010

                    db %01111111, %11111110
                    db %01000100, %01000110

                    db %01111111, %11111100
                    db %01111111, %11111100


                    ds 48 * 7

;*******************************************************************************************
; Horizontal block graphic
;*******************************************************************************************
HorizBlockData
                    db 1                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw HorizBlockData0, HorizBlockData0, HorizBlockData0, HorizBlockData0
                    dw HorizBlockData0, HorizBlockData0, HorizBlockData0, HorizBlockData0

HorizBlockData0
                    db %00000000
                    db %00000000
                    db %00000000
                    db %00000000
                    db %00000000
                    db %00000000
                    db %00000000
                    db %11111111

;*******************************************************************************************
; Vertical block graphic right edge
;*******************************************************************************************
VertRBlockData
                    db 1                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw VertRBlockData0, VertRBlockData0, VertRBlockData0, VertRBlockData0
                    dw VertRBlockData0, VertRBlockData0, VertRBlockData0, VertRBlockData0

VertRBlockData0
                    db %00000001
                    db %00000011
                    db %00000101
                    db %00001001
                    db %00010001
                    db %00100001
                    db %01000001
                    db %10000001

;*******************************************************************************************
; Vertical block graphic left edge
;*******************************************************************************************
VertLBlockData
                    db 1                          ; Width in bytes
                    db 8                          ; Height in pixels
                    dw VertLBlockData0, VertLBlockData0, VertLBlockData0, VertLBlockData0
                    dw VertLBlockData0, VertLBlockData0, VertLBlockData0, VertLBlockData0

VertLBlockData0
                    db %10000000
                    db %11000000
                    db %10100000
                    db %10010000
                    db %10001000
                    db %10000100
                    db %10000010
                    db %10000001

;*******************************************************************************************
; Y-Axis screen memory lookup table for accessing the screen file
;*******************************************************************************************   
scrnLnLkup:   
                    dw 4000h
                    dw 4100h
                    dw 4200h
                    dw 4300h
                    dw 4400h
                    dw 4500h
                    dw 4600h
                    dw 4700h
                    dw 4020h
                    dw 4120h
                    dw 4220h
                    dw 4320h
                    dw 4420h
                    dw 4520h
                    dw 4620h
                    dw 4720h
                    dw 4040h
                    dw 4140h
                    dw 4240h
                    dw 4340h
                    dw 4440h
                    dw 4540h
                    dw 4640h
                    dw 4740h
                    dw 4060h
                    dw 4160h
                    dw 4260h
                    dw 4360h
                    dw 4460h
                    dw 4560h
                    dw 4660h
                    dw 4760h
                    dw 4080h
                    dw 4180h
                    dw 4280h
                    dw 4380h
                    dw 4480h
                    dw 4580h
                    dw 4680h
                    dw 4780h
                    dw 40A0h
                    dw 41A0h
                    dw 42A0h
                    dw 43A0h
                    dw 44A0h
                    dw 45A0h
                    dw 46A0h
                    dw 47A0h
                    dw 40C0h
                    dw 41C0h
                    dw 42C0h
                    dw 43C0h
                    dw 44C0h
                    dw 45C0h
                    dw 46C0h
                    dw 47C0h
                    dw 40E0h
                    dw 41E0h
                    dw 42E0h
                    dw 43E0h
                    dw 44E0h
                    dw 45E0h
                    dw 46E0h
                    dw 47E0h
                    dw 4800h
                    dw 4900h
                    dw 4A00h
                    dw 4B00h
                    dw 4C00h
                    dw 4D00h
                    dw 4E00h
                    dw 4F00h
                    dw 4820h
                    dw 4920h
                    dw 4A20h
                    dw 4B20h
                    dw 4C20h
                    dw 4D20h
                    dw 4E20h
                    dw 4F20h
                    dw 4840h
                    dw 4940h
                    dw 4A40h
                    dw 4B40h
                    dw 4C40h
                    dw 4D40h
                    dw 4E40h
                    dw 4F40h
                    dw 4860h
                    dw 4960h
                    dw 4A60h
                    dw 4B60h
                    dw 4C60h
                    dw 4D60h
                    dw 4E60h
                    dw 4F60h
                    dw 4880h
                    dw 4980h
                    dw 4A80h
                    dw 4B80h
                    dw 4C80h
                    dw 4D80h
                    dw 4E80h
                    dw 4F80h
                    dw 48A0h
                    dw 49A0h
                    dw 4AA0h
                    dw 4BA0h
                    dw 4CA0h
                    dw 4DA0h
                    dw 4EA0h
                    dw 4FA0h
                    dw 48C0h
                    dw 49C0h
                    dw 4AC0h
                    dw 4BC0h
                    dw 4CC0h
                    dw 4DC0h
                    dw 4EC0h
                    dw 4FC0h
                    dw 48E0h
                    dw 49E0h
                    dw 4AE0h
                    dw 4BE0h
                    dw 4CE0h
                    dw 4DE0h
                    dw 4EE0h
                    dw 4FE0h
                    dw 5000h
                    dw 5100h
                    dw 5200h
                    dw 5300h
                    dw 5400h
                    dw 5500h
                    dw 5600h
                    dw 5700h
                    dw 5020h
                    dw 5120h
                    dw 5220h
                    dw 5320h
                    dw 5420h
                    dw 5520h
                    dw 5620h
                    dw 5720h
                    dw 5040h
                    dw 5140h
                    dw 5240h
                    dw 5340h
                    dw 5440h
                    dw 5540h
                    dw 5640h
                    dw 5740h
                    dw 5060h
                    dw 5160h
                    dw 5260h
                    dw 5360h
                    dw 5460h
                    dw 5560h
                    dw 5660h
                    dw 5760h
                    dw 5080h
                    dw 5180h
                    dw 5280h
                    dw 5380h
                    dw 5480h
                    dw 5580h
                    dw 5680h
                    dw 5780h
                    dw 50A0h
                    dw 51A0h
                    dw 52A0h
                    dw 53A0h
                    dw 54A0h
                    dw 55A0h
                    dw 56A0h
                    dw 57A0h
                    dw 50C0h
                    dw 51C0h
                    dw 52C0h
                    dw 53C0h
                    dw 54C0h
                    dw 55C0h
                    dw 56C0h
                    dw 57C0h
                    dw 50E0h
                    dw 51E0h
                    dw 52E0h
                    dw 53E0h
                    dw 54E0h
                    dw 55E0h
                    dw 56E0h
                    dw 57E0h 



