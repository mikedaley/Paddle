;****************************************************************************************************************
; Level Table Constants
;****************************************************************************************************************

LEVEL_BCC_AT_SPEEDS    equ     224
LEVEL_TITLE         equ     228

BLOCKS_PER_ROW      equ     11

BYTS_PER_CLMN       equ     2
NMBR_CLMNS          equ     14
NMBR_RWS            equ     8

STRT_X_POS          equ     2 * 8
STRT_CHR_X_POS      equ     2
STRT_Y_POS          equ     6 * 8
STRT_CHR_Y_POS      equ     6

BLCK_CLR            equ     0
BLCK_HIT_CNT        equ     1

LVL_TTL_Y_POS       equ     17

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
                ld      hl, (crrntLvlAddr)
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

                ld      ix, (crrntLvlAddr)          ; Grab the current levels address
                ld      b, NMBR_CLMNS               ; Setup the number of columns
_rwLp         
                push    bc                          ; B holds the column counter so save it
                ld      a, (ix + BLCK_HIT_CNT)      ; Grab the hit count for the current block
                or      a                           ; Check if its zero
                jr      nz, _drwBlck                ; If not then draw the block
                ld      hl, blckChrX                ; Not drawing a block so we need to increment the...
                inc     (hl)                        ; ...CHAR X pos
_nxtClmn
                ld      hl, blckChrX                ; Need to increment the CHAR X pos again as each...
                inc     (hl)                        ; ...block is two char cells wide
                ld      a, (blckX)                  ; Grab the Blocks X Pixel position 
                add     a, 16                       ; Each block is 16 pixels wide so add to the X pos
                ld      (blckX), a                  ; Save it
                inc     ix                          ; Move to the next column in the level data
                inc     ix                          ; Two bytes per column so two inc's

                pop     bc                          ; Restore the loop counter
                djnz    _rwLp                       ; Process the next column

_nxtRw
                ld      a, STRT_CHR_X_POS           ; Grab the initial CHAR X position 
                ld      (blckChrX), a               ; Save it as the current CHAR X pos
                ld      a, STRT_X_POS               ; Grab the initial Pixel X position
                ld      (blckX), a                  ; Save it as the current pixel x pos

                ld      a, (blckChrY)               ; Grab the blocks CHAR Y pos
                inc     a                           ; Increase it as we are on the next row
                cp      STRT_CHR_Y_POS + NMBR_RWS   ; Once all rows are rendered return
                ret     z

                ld      hl, blckChrY
                ld      (blckChrY), a               ; Save the CHAR Y pos
                ld      a, (blckY)                  ; Grab the pixel Y pos
                add     a, 8                        ; Each block is 8 pixels high 
                ld      (blckY), a                  ; Save it

                ld      b, NMBR_CLMNS               ; Load the number of columns 
                jp      _rwLp                       ; Go back to processing the columns

_drwBlck
                ld      hl, lvlBlckCnt              ; Get the address of the block count variable
                inc     (hl)                        ; Increment the block count variable 
                ld      de, SpriteBlockData         ; Point to the block sprite data 
                ld      bc, (blckPosYX)             ; Grab the Y and X position of the block
                push    bc                          ; Save the blocks position 
                xor     a                           ; Want to draw to the screen file
                call    drwSprt                     ; Draw the sprite
                ld      de, SpriteBlockData         ; Point to the block sprite data 
                pop     bc                          ; Restore the blocks position
                ld      a, 1                        ; Want to draw to the screen buffer
                call    drwSprt                     ; Draw sprite
                
                ld      a, (ix + BLCK_CLR)          ; Grab the colour for this block
                ld      de, (blckChrYX)             ; Grab the blocks Y, X position     
                push    de                          ; Save the blocks attribute position
                call    setChrctrAttr               ; Set the attributes for that position
                
                ld      hl, blckChrX                ; Move to the next char cell as blocks...
                inc     (hl)                        ; ...are two cells wide

                pop     de                          ; Restore the blocks attribute position 
                inc     e                           ; INC to the next cell
                call    setChrctrAttr               ; Set the attribute colour to what is in A

                jp      _nxtClmn                    ; Next column

;****************************************************************************************************************
; Level lookup table
;****************************************************************************************************************
lvlLkup         dw      Level1, Level2, Level1, Level2, Level1, Level2, Level1

;****************************************************************************************************************
; Level 1
;****************************************************************************************************************
                org     ($ + 255) & $ff00
Level1
                ; Colour, # of hits to destroy
                ; Each column represents a block which is 16 pixels wide and 8 pixels deep
                ; A column containing 0,0 means there is no block at that position    
                ; 14 columns of two bytes * 8 rows = 224 bytes

                db  0,0,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  0,0
                db  0,0,  2,1,  3,1,  4,1,  6,1,  7,3,  7,3,  7,3,  7,3,  6,1,  4,1,  3,1,  2,1,  0,0
                db  0,0,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  0,0
                db 69,1,  2,0,  3,1,  4,1,  6,1, 65,1, 65,0, 65,0, 65,1,  6,1,  4,1,  3,1,  2,0, 69,1
                db 69,1,  2,0,  3,1,  4,1,  6,1, 66,1, 65,0, 65,0, 66,1,  6,1,  4,1,  3,1,  2,0, 69,1
                db  0,0,  2,1,  3,1,  4,1,  6,1, 65,1, 65,0, 65,0, 65,1,  6,1,  4,1,  3,1,  2,1,  0,0
                db  0,0,  2,1,  3,1,  4,1,  6,1, 66,1, 65,1, 65,1, 66,1,  6,1,  4,1,  3,1,  2,1,  0,0
                db  0,0,  2,1,  3,1,  4,1,  6,1, 71,5, 71,5, 71,5, 71,5,  6,1,  4,1,  3,1,  2,1,  0,0

Level1BatSpeed      
                db 1, 2, 2, 3
Level1Title         
                db Level1TitleEnd - 1 - Level1Title, CC_FLASH, 1, CC_PAPER, BLUE, CC_INK, YELLOW, CC_AT, LVL_TTL_Y_POS, 11, ' ROUND 1 ', CC_FLASH, 0
Level1TitleEnd
Level1TitleClear    
                db Level1TitleClearEnd - 1 - Level1TitleClear, CC_PAPER, BLACK, CC_INK, CYAN, CC_AT, LVL_TTL_Y_POS, 11, '         '
Level1TitleClearEnd

;****************************************************************************************************************
; Level 2
;****************************************************************************************************************
Level2
                ; Colour, # of hits to destroy
                ; Each column represents a block which is 16 pixels wide and 8 pixels deep
                ; A column containing 0,0 means there is no block at that position    
                ; 14 columns of two bytes * 8 rows = 224 bytes

                db 66,3, 66,3, 66,3, 66,3, 65,1, 65,1, 70,3, 70,3, 65,1, 65,1, 65,1, 68,3, 68,3, 65,1
                db 65,1, 65,1, 65,1, 66,3, 65,1, 70,3, 65,1, 65,1, 70,3, 65,1, 68,3, 65,1, 65,1, 68,3
                db 65,1, 65,1, 65,1, 66,3, 65,1, 70,3, 65,1, 65,1, 70,3, 65,1, 68,3, 65,1, 65,1, 68,3
                db 65,1, 65,1, 66,3, 65,1, 65,1, 65,1, 70,3, 70,3, 65,1, 65,1, 68,3, 65,1, 65,1, 68,3
                db  1,1,  2,3,  1,1,  1,1,  1,1,  6,3,  1,1,  1,1,  6,3,  1,1,  4,3,  1,1,  1,1,  4,3
                db  2,3,  1,1,  1,1,  1,1,  1,1,  6,3,  1,1,  1,1,  6,3,  1,1,  4,3,  1,1,  1,1,  4,3
                db  2,3,  1,1,  1,1,  1,1,  1,1,  6,3,  1,1,  1,1,  6,3,  1,1,  4,3,  1,1,  1,1,  4,3
                db  2,3,  2,3,  2,3,  2,3,  1,1,  1,1,  6,3,  6,3,  1,1,  1,1,  1,1,  4,3,  4,3,  1,1

Level2BatSpeed      
                db 1, 2, 2, 3
Level2Title         
                db Level2TitleEnd - 1 - Level2Title, CC_FLASH, 1, CC_PAPER, BLUE, CC_INK, YELLOW, CC_AT, LVL_TTL_Y_POS, 11, ' ROUND 2 ', CC_FLASH , 0
Level2TitleEnd
Level2TitleClear    
                db Level2TitleClearEnd - 1 - Level2TitleClear, CC_PAPER, BLACK, CC_INK, CYAN, CC_AT, LVL_TTL_Y_POS, 11, '         '
Level2TitleClearEnd

