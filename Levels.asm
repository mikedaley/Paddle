;*******************************************************************************************
; This file contains the level data for the game.
;*******************************************************************************************

;*******************************************************************************************
; Level Table Constants
;*******************************************************************************************
ROW_CLR_BYTES       equ     30

LVL_CLR_ROW_1       equ     0
LVL_CLR_ROW_2       equ     ROW_CLR_BYTES
LVL_CLR_ROW_3       equ     ROW_CLR_BYTES * 2
LVL_CLR_ROW_4       equ     ROW_CLR_BYTES * 3
LVL_CLR_ROW_5       equ     ROW_CLR_BYTES * 4
LVL_CLR_ROW_6       equ     ROW_CLR_BYTES * 5
LVL_CLR_ROW_7       equ     ROW_CLR_BYTES * 6

LEVEL_ROWS          equ     210

LEVEL_BAT_SPEEDS    equ     LEVEL_ROWS + 105
LEVEL_TITLE         equ     LEVEL_ROWS + 105 + 4

BLOCKS_PER_ROW      equ     11

;*******************************************************************************************
; Level lookup table
;*******************************************************************************************
LevelLookup         dw Level1, Level2, Level3, Level4

;*******************************************************************************************
; Level 1
;*******************************************************************************************
Level1
                    ; Table used to define the colours to be used in the blocks area of the
                    ; screen

Level1Colour        db  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5, 65, 65, 65, 65, 65, 65, 65, 65,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5
                    db  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  5,  5,  5,  5,  5,  5,  5,  5 
                    db  5,  5,  5,  5,  5,  5,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  5,  5,  5,  5
                    db  5,  5,  5,  5,  4,  4, 68, 68,  4,  4, 68, 68,  4,  4, 68, 68,  4,  4, 68, 68,  4,  4, 68, 68,  4,  4, 68, 68,  5,  5
                    db  5,  5,  5,  5,  5,  5, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69,  5,  5,  5,  5
                    db  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  5,  5,  5,  5,  5,  5,  5,  5
                    db  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  7,  7,  7,  7,  7,  7,  7,  7,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5

                    ; Table used to define where blocks are positioned on screen
Level1Rows          db 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0
                    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 
                    db 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 
                    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 
                    db 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 
                    db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 
                    db 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0 

Level1BatSpeed      db 1, 2, 2, 3
Level1Title         db 12, 16, 5, 22, 15, 12, 'LEVEL 1'
Level1TitleClear    db 12, 16, 5, 22, 15, 12, '       '


;*******************************************************************************************
; Level 2
;*******************************************************************************************
Level2
                    ; Table used to define the colours to be used in the blocks area of the
                    ; screen
Level2Colour        db 5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 5, 5
                    db 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5
                    db 5, 5, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 5, 5
                    db 5, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5
                    db 5, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5
                    db 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 5, 5 
                    db 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5

                    ; Table used to define where blocks are positioned on screen
Level2Rows          db 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0 
                    db 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 

Level2BatSpeed      db 1, 2, 2, 3
Level2Title         db 10, 22, 15, 8, 'LEVEL 2'
Level2TitleClear    db 10, 22, 15, 8, '       '

;*******************************************************************************************
; Level 3
;*******************************************************************************************
Level3
                    ; Table used to define the colours to be used in the blocks area of the
                    ; screen
Level3Colour        db 5, 5, 7, 7, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 5, 5
                    db 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5
                    db 5, 5, 5, 5, 69, 69, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 69, 69, 5, 5, 5, 5
                    db 5, 5, 4, 4, 4, 4, 5, 5, 4, 4, 4, 4, 4, 4, 5, 5, 4, 4, 4, 4, 5, 5
                    db 5, 5, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 3, 3, 3, 5, 5
                    db 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 5, 5 
                    db 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5

                    ; Table used to define where blocks are positioned on screen
Level3Rows          db 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0 
                    db 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0 
                    db 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0 
                    db 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0
                    db 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 
                    db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 

Level3BatSpeed      db 1, 2, 2, 3
Level3Title         db 10, 22, 15, 8, 'LEVEL 3'
Level3TitleClear    db 10, 22, 15, 8, '       '

;*******************************************************************************************
; Level 4
;*******************************************************************************************
Level4
                    ; Table used to define the colours to be used in the blocks area of the
                    ; screen
Level4Colour        db 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5, 5, 5
                    db 5, 5, 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5
                    db 5, 5, 5, 5, 1, 1, 7, 7, 7, 7, 1, 1, 7, 7, 7, 7, 1, 1, 5, 5, 5, 5
                    db 5, 5, 5, 5, 1, 1, 7, 7, 2, 2, 1, 1, 7, 7, 2, 2, 1, 1, 5, 5, 5, 5
                    db 5, 5, 5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 5
                    db 5, 5, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 5, 5
                    db 5, 5, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 1, 1, 5, 5, 5, 5

                    ; Table used to define where blocks are positioned on screen
Level4Rows          db 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0 
                    db 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0
                    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0
                    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0
                    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0
                    db 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0
                    db 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0

Level4BatSpeed      db 1, 2, 2, 3
Level4Title         db 10, 22, 15, 8, 'LEVEL 4'
Level4TitleClear    db 10, 22, 15, 8, '       '


