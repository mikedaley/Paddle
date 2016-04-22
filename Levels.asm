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

BYTS_PER_CLMN       equ     2
NMBR_CLMNS          equ     14
NMBR_RWS            equ     8

STRT_X_POS          equ     2 * 8
STRT_Y_POS          equ     7 * 8

;****************************************************************************************************************
; Load Level
; A = Level to load 
;****************************************************************************************************************
ldLvl 
                ld      hl, SCRNBFFR                ; Point HL at the screen buffer
                ld      bc, 6144                    ; Load BC with the number of bytes to clear
                call    clrMem                      ; Call the clear mem routine

                ld      de, lvlLkup                 ; Load DE with the address of the Level Lookup Table
                ld      a, (crrntLvl)               ; Load A with the level number to load
                ld      l, a
                ld      h, 0                        ; Reset the HL high byte
                add     hl, hl                      ; Double HL as the level lookup table entries are words
                add     hl, de                      ; Add base address of level lookup table which is held in DE
                ld      e, (hl)                     ; Load the address at HL into DE
                inc     hl
                ld      d, (hl)
                ld      (crrntLvlAddr), de          ; Store away 

                ; Copy the level row data into the temp level data structure. This will be used to check how many
                ; hits a block needs to be destroyed.
;                 ld      de, LEVEL_ROWS
;                 add     hl, de
                push    de                          ; Save the current level address
                ld      de, lvlData
                ld      bc, BYTS_PER_CLMN * NMBR_CLMNS * NMBR_RWS
                ldir
                pop     hl                          ; Put the current level address into HL

                ; When calculating the index into the level data the following calculation should be used  i = (x - 16) / 16
                ; LD A, (XPOS)
                ; SUB 16
                ; RRA
                ; RRA
                ; RRA
                ; RRA
                ; LD (INDEX), A
                ; LD A, (YPOS)
                ; SUB 56
                ; RRA
                ; RRA
                ; RRA
                ; LD B, (INDEX)
                ; ADD A, B
                ; LD (INDEX), A







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
lvlLkup         dw      Level1, Level2

;*******************************************************************************************
; Level 1
;*******************************************************************************************
                org     ($ + 255) & $ff00
Level1
                ; Colour, # of hits to destroy
                ; Each column represents a block which is 16 pixels wide and 8 pixels deep
                ; A column containing 0,0 means there is no block at that position    
                ; 15 columns of two bytes * 8 rows = 240 bytes

                db  0,0,  0,0,  0,0,  0,0,  0,0, 65,1, 65,1, 65,1, 65,1,  0,0,  0,0,  0,0,  0,0,  0,0
                db  0,0,  0,0,  0,0,  0,0,  2,1,  2,1,  2,1,  2,1,  2,1,  2,1,  0,0,  0,0,  0,0,  0,0
                db  0,0,  0,0,  0,0,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  0,0,  0,0,  0,0
                db  0,0,  0,0, 68,1,  4,1, 68,1,  4,1, 68,1,  4,1, 68,1,  4,1, 68,1, 68,1,  0,0,  0,0
                db  0,0,  0,0,  0,0,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  3,1,  0,0,  0,0,  0,0
                db  0,0,  0,0,  0,0,  0,0,  2,1,  2,1,  2,1,  2,1,  2,1,  2,1,  0,0,  0,0,  0,0,  0,0
                db  0,0,  0,0,  0,0,  0,0,  0,0, 65,1, 65,1, 65,1, 65,1,  0,0,  0,0,  0,0,  0,0,  0,0
                db  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0,  0,0

Level1BatSpeed      
                db 1, 2, 2, 3
Level1Title         
                db 12, 16, 5, 22, 15, 12, 'LEVEL 1'
Level1TitleClear    
                db 12, 16, 5, 22, 15, 12, '       '


;*******************************************************************************************
; Level 2
;*******************************************************************************************
                    org     ($ + 255) & $ff00
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

