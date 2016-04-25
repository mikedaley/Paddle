;*******************************************************************************************
; This file contains the level data for the game.
;*******************************************************************************************

;*******************************************************************************************
; Level Table Constants
;*******************************************************************************************

LEVEL_BAT_SPEEDS    equ     224
LEVEL_TITLE         equ     228

BLOCKS_PER_ROW      equ     11

BYTS_PER_CLMN       equ     2
NMBR_CLMNS          equ     14
NMBR_RWS            equ     8

STRT_X_POS          equ     2 * 8
STRT_CHR_X_POS      equ     2
STRT_Y_POS          equ     5 * 8
STRT_CHR_Y_POS      equ     5

BLCK_CLR            equ     0
BLCK_HIT_CNT        equ     1

;****************************************************************************************************************
; Variables on a byte boundary
;****************************************************************************************************************
                org     ($ + 255) & $ff00

crrntRw         db      0
crrntCl         db      0

blckPosYX
blckY           db      0
blckX           db      0

blckChrYX       
blckChrX        db      0
blckChrY        db      0

;****************************************************************************************************************
; Load Level
; A = Level to load 

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
                push    de                          ; Save the current level address
                ld      de, lvlData
                ld      bc, BYTS_PER_CLMN * NMBR_CLMNS * NMBR_RWS
                ldir
                pop     hl                          ; Put the current level address into HL

                ; Init the variables for drawing the levels blocks to screen
                xor     a                           ; Clear A
                ld      (crrntRw), a                ; Reset the current row variable
                ld      (crrntCl), a                ; Reset the current column variable
                ld      a, STRT_X_POS               
                ld      (blckX), a                  ; Init the Block X pos
                ld      a, STRT_Y_POS
                ld      (blckY), a                  ; Init the Block Y pos
                ld      a, STRT_CHR_X_POS
                ld      (blckChrX), a               ; Init the Block X char pos
                ld      a, STRT_CHR_Y_POS
                ld      (blckChrY), a               ; Init the Block Y char pos

                ld      ix, (crrntLvlAddr)
                ld      b, NMBR_CLMNS
_rwLp         
                push    bc
                ld      a, (ix + BLCK_HIT_CNT)
                or      a
                jr      nz, _drwBlck
                ld      a, (blckChrX)
                inc     a
                ld      (blckChrX), a
_nxtClmn
                ld      a, (blckChrX)
                inc     a
                ld      (blckChrX), a
                ld      a, (blckX)
                add     a, 16
                ld      (blckX), a
                inc     ix
                inc     ix

                pop     bc
                djnz    _rwLp

_nxtRw
                ld      a, STRT_CHR_X_POS
                ld      (blckChrX), a
                ld      a, STRT_X_POS
                ld      (blckX), a

                ld      a, (blckChrY)
                inc     a
                cp      STRT_CHR_Y_POS + NMBR_RWS
                ret     z

                ld      (blckChrY), a
                ld      a, (blckY)
                add     a, 8
                ld      (blckY), a

                ld      b, NMBR_CLMNS
                jp      _rwLp

_drwBlck
                ld      a, (lvlBlckCnt)
                inc     a
                ld      (lvlBlckCnt), a
                ld      de, SpriteBlockData         ; Point to the block sprite data 
                ld      bc, (blckPosYX)             ; Grab the Y and X position of the block
                push    bc
                xor     a                           ; Want to draw to the screen file
                call    drwSprt
                ld      de, SpriteBlockData         ; Point to the block sprite data 
                pop     bc
                ld      a, 1
                call    drwSprt                
                
                ld      a, (ix + BLCK_CLR)
                ld      de, (blckChrYX)
                call    setChrctrAttr
                
                ld      a, (blckChrX)
                inc     a
                ld      (blckChrX), a

                ld      a, (ix + BLCK_CLR)
                ld      de, (blckChrYX)
                call    setChrctrAttr

                jp      _nxtClmn

;*******************************************************************************************
; Level lookup table
;*******************************************************************************************
lvlLkup         dw      Level1, Level1, Level1, Level1, Level1, Level1, Level1

;*******************************************************************************************
; Level 1
;*******************************************************************************************
                org     ($ + 255) & $ff00
Level1
                ; Colour, # of hits to destroy
                ; Each column represents a block which is 16 pixels wide and 8 pixels deep
                ; A column containing 0,0 means there is no block at that position    
                ; 14 columns of two bytes * 8 rows = 224 bytes

                db  1,1,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  1,1
                db  1,1,  2,1,  3,1,  4,1,  6,1, 65,1, 65,1, 65,1, 65,1,  6,1,  4,1,  3,1,  2,1,  1,1
                db  1,1,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  1,1
                db  1,1,  2,0,  3,0,  4,1,  6,1, 65,1, 65,0, 65,0, 65,1,  6,1,  4,1,  3,0,  2,0,  1,1
                db  1,1,  2,0,  3,0,  4,1,  6,1, 66,1, 65,0, 65,0, 66,1,  6,1,  4,1,  3,0,  2,0,  1,1
                db  1,1,  2,1,  3,1,  4,1,  6,1, 65,1, 65,0, 65,0, 65,1,  6,1,  4,1,  3,1,  2,1,  1,1
                db  1,1,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  1,1
                db  1,1,  2,1,  3,1,  4,1,  6,1, 65,1, 70,1, 70,1, 65,1,  6,1,  4,1,  3,1,  2,1,  1,1

Level1BatSpeed      
                db 1, 2, 2, 3
Level1Title         
                db 12, 16, 5, 22, 15, 12, 'LEVEL 1'
Level1TitleClear    
                db 12, 16, 5, 22, 15, 12, '       '


