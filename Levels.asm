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


;****************************************************************************************************************
; Load Level
; A = Level to load 
;****************************************************************************************************************
ldLvl 
                ld      hl, SCRNBFFR                ; Point HL at the screen buffer
                ld      bc, 6144                    ; Load BC with the number of bytes to clear
                call    clrMem                      ; Call the clear mem routine

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
                push    de

                ; Copy the level row data into the temp level data structure. This will be used to check how many
                ; hits a block needs to be destroyed.
                ld      de, LEVEL_ROWS
                add     hl, de
                ld      de, lvlData
                ld      bc, 15 * 7
                ldir
                pop     hl

                ; Load the block colours from the level data into the attribute buffer starting at the 4th row
                ld      a, 7                        ; Number of rows to load
                ld      de, ATTRSCRNADDR + (32 * 7) ; Load into the 4th row of attributes
_lvlRwLp
                ld      bc, ROW_CLR_BYTES           ; Set how many bytes to copy
                ldir                                ; Perform the copy
                inc     de                          ; Move DE to the start of the next row in the...
                inc     de                          ; ...attribute buffer
                dec     a                           ; Reduce the row count...
                jp      nz, _lvlRwLp                ; ...and loop if there are more rows to copy

                ; Draw the blocks based on the levels block lookup table
_nxtBlckRw      xor     a                           ; Clear A
                ld      (currntBlckCl), a
                ld      (currntBlckRw), a
                ld      (currntBlckX), a
                ld      a, 8 * 7
                ld      (currntBlckY), a

_drwNxtBlck     ld      bc, (currntBlckY)
                ld      a, (hl)
                inc     hl
                cp      0
                jr      z, _skpBlck

                ld      a, (lvlBlckCnt)
                inc     a
                ld      (lvlBlckCnt), a

                push    hl
                push    bc
                ld      de, SpriteBlockData
                xor     a
                call    drwSprt
                pop     bc
                ld      de, SpriteBlockData
                ld      a, 1
                call    drwSprt
                pop     hl

_skpBlck        ld      a, (currntBlckX)
                add     a, 16
                ld      (currntBlckX), a
                ld      a, (currntBlckCl)
                inc     a
                ld      (currntBlckCl), a
                cp      15
                jr      nz, _drwNxtBlck

                xor     a
                ld      (currntBlckX), a
                ld      a, (currntBlckY)
                add     a, 8
                ld      (currntBlckY), a
                xor     a
                ld      (currntBlckCl), a

                ld      a, (currntBlckRw)
                inc     a
                ld      (currntBlckRw), a
                cp      7
                jr      nz, _drwNxtBlck

                ret
                
;*******************************************************************************************
; Level lookup table
;*******************************************************************************************
lvlLkup         dw Level1, Level2, Level3, Level4

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
                    db 0, 0, 0, 0, 0, 0, 5, 5, 5, 5, 0, 0, 0, 0, 0 

Level1BatSpeed      db 1, 2, 2, 3
Level1Title         db 12, 16, 5, 22, 15, 12, 'LEVEL 1'
Level1TitleClear    db 12, 16, 5, 22, 15, 12, '       '


;*******************************************************************************************
; Level 2
;*******************************************************************************************
Level2
                    ; Table used to define the colours to be used in the blocks area of the
                    ; screen
Level2Colour
                    db  5,  5,  7,  7,  7,  7,  7,  7,  7,  7,  5,  5,  5,  5,  7,  7,  7,  7,  5,  5,  5,  5,  5,  5,  7,  7,  7,  7,  5,  5
                    db  5,  5,  5,  5,  5,  5,  5,  5,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7
                    db  5,  5,  5,  5,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7
                    db  5,  5,  5,  5,  7,  7,  5,  5,  5,  5,  5,  5,  7,  7,  7,  7,  7,  7,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7
                    db  5,  5,  7,  7,  5,  5,  5,  5,  5,  5,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7
                    db  5,  5,  7,  7,  5,  5,  5,  5,  5,  5,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7,  5,  5,  7,  7,  5,  5,  5,  5,  7,  7
                    db  5,  5,  7,  7,  7,  7,  7,  7,  7,  7,  5,  5,  5,  5,  7,  7,  7,  7,  5,  5,  5,  5,  5,  5,  7,  7,  7,  7,  5,  5

                    ; Table used to define where blocks are positioned on screen
Level2Rows
                    db 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0
                    db 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1
                    db 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1
                    db 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1
                    db 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1
                    db 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1
                    db 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0

Level2BatSpeed      db 1, 2, 2, 3
Level2Title         db 12, 16, 5, 22, 15, 12, 'LEVEL 2'
Level2TitleClear    db 12, 16, 5, 22, 15, 12, '       '

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


