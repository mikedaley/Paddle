;****************************************************************************************************************
;
; This assmebly file contains the code used to display and manage the main menu
;
; 0. Start
; 1. Keyboard
; 2. Kempston
; 3. Sinclair
;
;****************************************************************************************************************

menu
                ; Clear the screen
                ld      hl, BTMPSCRNSDDR            ; Point HL at the screen buffer
                ld      bc, BTMPSCRSZ               ; Load BC with the number of bytes to clear
                call    clrMem                      ; Clear memory

                ; Draw logo
                ld      hl, logoAttrFx              ; Load in the attribute FX data
                ld      de, ATTRSCRNADDR
                ld      bc, 32 * 7
                ldir

                ld      de, Logo                    ; Draw the logo sprite
                ld      bc, 0x0009
                call    drwSprt

                ld      hl, ATTRSCRNADDR + (6 * 32) ; Fill the rest of the screen with cyan on black
                ld      de, ATTRSCRNADDR + (6 * 32) + 1
                ld      (hl), RED + BLUE
                ld      bc, ATTRSCRNSZ - 1
                ldir

                ; Print the menu options
                call    drwMenu

                ; Set channel to the bottom of the screen and print the copyright
                ld      a, 1
                call    5633

                call    romPrntStrng
                db      CC_BRIGHT, 1, CC_PAPER, BLACK, CC_INK, MAGENTA, CC_AT, 1, 8, "Mike Daley 2016", CC_BRIGHT, 0, 0xff

                ld      hl, logoAttrFx              ; Load HL with the logo attr FX address
                ld      (attrFxAddr), hl            ; ...and save it to memory

_mnuLp
                ld      b, 3                        ; Pause for (1/50 * A) seconds
_pause          
                halt
                djnz    _pause

                call    rdOptnKys                   ; Action any key presses

                ld      hl, (attrFxAddr)            ; Load HL with the current FX address 
                ld      de, ATTRSCRNADDR            ; Load DE with the screen address
                ld      bc, 192                     ; Load BC with 6 rows e.g. 32 * 6
                ldir                                ; Move the attributes to screen

                ld      hl, (attrFxAddr)            ; Load HL with the attribute fx address
                ld      de, 32                      ; Add 32 to the address...
                add     hl, de                      ; ...moving to the next line
                ld      (attrFxAddr), hl            ; Save that back to the variable

                ld      a, (logoFXCnt)              ; Load A with the current FX count
                inc     a                           ; Inc it
                ld      (logoFXCnt), a              ; Save it
                cp      6                           ; Compare with 6
                jp      nz, _mnuLp                  ; Loop if not reached

                xor     a                           ; Clear A
                ld      (logoFXCnt), a              ; Reset the fx count
                ld      hl, logoAttrFx              ; Reset HL with the logo attribute fx
                ld      (attrFxAddr), hl            ; Save it to the variable

                jp      _mnuLp                      ; Loop

;****************************************************************************************************************
; Read the keyboard and run the appropriate routine based on what has been pressed
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
rdOptnKys
                ld      bc, 0xeffe                  ; B = 0xEF (67890), C = port 0xFE (6, 7, 8, 9, 0)
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; LSB = 0
                jp      nc, strtNewGame             ; 0 = not pressed, 1 = pressed

                ld      bc, 0xf7fe                  ; B 0xF7, C = 0xFE (5, 4, 3, 2, 1)
                in      a, (c)
                rra 
                jp      nc, _keyboard
                rra     
                jp      nc, _sinclair
                rra      
                jp      nc, _kempston
                ret
_keyboard
                ld      a, 0
                ld      (inptOption), a
                call    drwMenu
                ret
_sinclair
                ld      a, 1
                ld      (inptOption), a    
                call    drwMenu
                ret    
_kempston        
                ld      a, 2
                ld      (inptOption), a    
                call    drwMenu
                ret

;****************************************************************************************************************
; Draw the menu options with the current option highlighted
;
; Entry Registers:
;   NONE
; Registers Used:
;   A, B, D, E, H, L
; Returned Registers:
;   NONE
;****************************************************************************************************************
drwMenu
                ld      a, 0xfe                     ; Make sure that the upper screen area is select
                call    0x1601                      ; Before clearing the screen

                call    _highlightOff

                call    romPrntStrng
                db      CC_AT, 11, 10, "0. START", 0xff
                
                ld      a, (inptOption)
                or      a
                call    z, _highlightOn
                call    romPrntStrng
                db      CC_AT, 13, 10, "1. KEYBOARD", 0xff                
                call    _highlightOff

                ld      a, (inptOption)
                cp      1
                call    z, _highlightOn
                call    romPrntStrng
                db      CC_AT, 15, 10, "2. SINCLAIR", 0xff
                call    _highlightOff
                
                ld      a, (inptOption)
                cp      2
                call    z, _highlightOn
                call    romPrntStrng
                db      CC_AT, 17, 10, "3. KEMPSTON", 0xff       
                call    _highlightOff

                ret
_highlightOn
                call    romPrntStrng
                db      CC_BRIGHT, 1, CC_FLASH, 1, CC_PAPER, YELLOW, CC_INK, BLUE, 0xff
                ret
_highlightOff
                call    romPrntStrng
                db      CC_BRIGHT, 0, CC_FLASH, 0, CC_PAPER, BLACK, CC_INK, WHITE, 0xff
                ret

;****************************************************************************************************************
; Variables
attrFxAddr      dw      0
logoFXCnt       db      0

LOGOFXCC_INKCLR1   equ     YELLOW + BRIGHT
LOGOFXCC_INKCLR2   equ     CYAN
logoAttrFx
;                 db      WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE
;                 db      WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE

                db      YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW
                db      YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW

                db      CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN
                db      CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN

                db      GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN                
                db      GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN                

                db      MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA
                db      MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA

                db      RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED 
                db      RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED 

                db      BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE                
                db      BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE

;                 db      WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE
;                 db      WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE

                db      YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW
                db      YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW

                db      CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN
                db      CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN, CYAN

                db      GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN                
                db      GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN                

                db      MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA
                db      MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA, MAGENTA

                db      RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED 
                db      RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED, RED 

                db      BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE                
                db      BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE

;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2

;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2

;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1

;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1

;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2

;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2

;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1

;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1
;                 db      LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1

;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2
;                 db      LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR1, LOGOFXCC_INKCLR2, LOGOFXCC_INKCLR2

;*******************************************************************************************
; Logo
;*******************************************************************************************
Logo
                    db 32                          ; Width in bytes
                    db 39                          ; Height in pixels
                    dw LogoData0, LogoData0, LogoData0, LogoData0
                    dw LogoData0, LogoData0, LogoData0, LogoData0

LogoData0           db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    db 0x00, 0x00, 0x00, 0x00, 0x0F, 0xFF, 0xFF, 0xFF, 0xC0, 0x01, 0xFF, 0xFF, 0xFF, 0xF8
                    db 0x00, 0x1F, 0xFF, 0xFF, 0xFC, 0x00, 0x03, 0xFF, 0xFF, 0xFF, 0x80, 0x00, 0x7F, 0xFF
                    db 0x00, 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF, 0xE0, 0x0F, 0xFF, 0xFF, 0xFF, 0xC0, 0x01
                    db 0xFF, 0xFF, 0xFF, 0xF8, 0x00, 0x1F, 0xFF, 0xFF, 0xFC, 0x00, 0x03, 0xFF, 0xFF, 0xFF
                    db 0x80, 0x00, 0x7F, 0xFF, 0x00, 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF, 0xE0, 0x38, 0x3F
                    db 0xFF, 0xFF, 0xFC, 0x07, 0x07, 0xFF, 0xFF, 0xFE, 0x00, 0x70, 0x7F, 0xFF, 0xFF, 0xC0
                    db 0x0E, 0x0F, 0xFF, 0xFF, 0xF8, 0x01, 0x81, 0xFF, 0xC0, 0x00, 0x01, 0xC1, 0xFF, 0xFF
                    db 0xFF, 0xF8, 0x38, 0x3F, 0xFF, 0xFF, 0xFC, 0x07, 0x07, 0xFF, 0xFF, 0xFE, 0x00, 0x60
                    db 0x7F, 0xFF, 0xFF, 0xC0, 0x0C, 0x0F, 0xFF, 0xFF, 0xF8, 0x01, 0x81, 0xFF, 0xC0, 0x00
                    db 0x01, 0xC1, 0xFF, 0xFF, 0xFF, 0xF8, 0x38, 0x3F, 0xFF, 0xFF, 0xFF, 0x07, 0x07, 0xFF
                    db 0xFF, 0xFF, 0x80, 0x60, 0x7F, 0xFF, 0xFF, 0xF0, 0x0C, 0x0F, 0xFF, 0xFF, 0xFE, 0x01
                    db 0x81, 0xFF, 0xC0, 0x00, 0x01, 0xC1, 0xFF, 0xFF, 0xFF, 0xF8, 0x38, 0xFF, 0xFF, 0xFF
                    db 0xFF, 0x07, 0x1F, 0xFF, 0xFF, 0xFF, 0x80, 0x63, 0xFF, 0xFF, 0xFF, 0xF0, 0x0C, 0x7F
                    db 0xFF, 0xFF, 0xFE, 0x01, 0x8F, 0xFF, 0xC0, 0x00, 0x01, 0xC7, 0xFF, 0xFF, 0xFF, 0xF8
                    db 0x38, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0x1F, 0xFF, 0xFF, 0xFF, 0xE0, 0x63, 0xFF, 0xFF
                    db 0xFF, 0xFC, 0x0C, 0x7F, 0xFF, 0xFF, 0xFF, 0x81, 0x8F, 0xFF, 0xC0, 0x00, 0x01, 0xC7
                    db 0xFF, 0xFF, 0xFF, 0xE0, 0x38, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0x1F, 0xFF, 0xFF, 0xFF
                    db 0xE0, 0x63, 0xFF, 0xFF, 0xFF, 0xFC, 0x0C, 0x7F, 0xFF, 0xFF, 0xFF, 0x81, 0x8F, 0xFF
                    db 0xC0, 0x00, 0x01, 0xC7, 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xFC, 0x3F, 0xFF, 0x07
                    db 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x7F, 0xFC, 0x0F, 0xFF, 0xFC, 0x0F
                    db 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF
                    db 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x3F, 0xFC
                    db 0x0F, 0xFF, 0xFC, 0x07, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0
                    db 0x00, 0x00, 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F
                    db 0xFF, 0xE0, 0x1F, 0xFC, 0x0F, 0xFF, 0xFC, 0x03, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00
                    db 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF
                    db 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81
                    db 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xF8, 0x1F
                    db 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF
                    db 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00
                    db 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x7F, 0xFF, 0xE0
                    db 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF
                    db 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0xFF, 0xFF
                    db 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF
                    db 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07
                    db 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01
                    db 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF
                    db 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC
                    db 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xFF
                    db 0xFF, 0xF8, 0x3F, 0xFF, 0xF8, 0x1F, 0xFF, 0x07, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x7F
                    db 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00
                    db 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF, 0xFC, 0x3F, 0xFF, 0x07, 0xFF, 0xFF
                    db 0xFF, 0xFF, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81
                    db 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF, 0xFF, 0xFF
                    db 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF
                    db 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0
                    db 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0
                    db 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF
                    db 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0xFF, 0xFF, 0x00, 0x7F
                    db 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF
                    db 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0x07
                    db 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC, 0x0F, 0xFF, 0xFC, 0x01
                    db 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF
                    db 0xFF, 0xFF, 0xFC, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x0F, 0xFC
                    db 0x0F, 0xFF, 0xFC, 0x01, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0
                    db 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF, 0xFC, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F
                    db 0xFF, 0xE0, 0x1F, 0xFC, 0x0F, 0xFF, 0xFC, 0x03, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00
                    db 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF, 0xE0, 0x07, 0xFF, 0xFF
                    db 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x3F, 0xFC, 0x0F, 0xFF, 0xFC, 0x07, 0xFF, 0x81
                    db 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0xFF
                    db 0xE0, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xE0, 0x7F, 0xFC, 0x0F, 0xFF
                    db 0xFC, 0x0F, 0xFF, 0x81, 0xFF, 0xFF, 0xC0, 0x00, 0x01, 0xFF, 0xFF, 0xC0, 0x00, 0x00
                    db 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF
                    db 0xFF, 0xFC, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0xFF
                    db 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F
                    db 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0x81, 0xFF, 0xFF
                    db 0xFF, 0xFF, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07
                    db 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF, 0xFF, 0xFF
                    db 0xFF, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF
                    db 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFC
                    db 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0x81, 0xFF, 0xFF, 0xFF, 0xFF, 0xC1, 0xFF, 0xFF, 0xFF
                    db 0xFF, 0xF8, 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F
                    db 0xFF, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0x81, 0xFF, 0xFF, 0xFF, 0xFF
                    db 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF
                    db 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0x81
                    db 0xFF, 0xFF, 0xFF, 0xFF, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF, 0xF8, 0x00
                    db 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF
                    db 0xFF, 0xFF, 0xFE, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8
                    db 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F, 0xE0, 0x7F, 0xFF, 0xFF
                    db 0xFF, 0xF0, 0x0F, 0xFF, 0xFF, 0xFF, 0xFC, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xC1, 0xFF
                    db 0xFF, 0xFF, 0xFF, 0xF8, 0x3F, 0xFF, 0xF8, 0x00, 0x00, 0x07, 0xFF, 0xFF, 0x00, 0x7F
                    db 0xE0, 0x7F, 0xFF, 0xFF, 0xFF, 0xF0, 0x0F, 0xFF, 0xFF, 0xFF, 0xFC, 0x01, 0xFF, 0xFF
                    db 0xFF, 0xFF, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0x0F, 0xFF, 0xE0, 0x00, 0x00, 0x01
                    db 0xFF, 0xFC, 0x00, 0x1F, 0x80, 0x1F, 0xFF, 0xFF, 0xFF, 0xC0, 0x03, 0xFF, 0xFF, 0xFF
                    db 0xF0, 0x00, 0x7F, 0xFF, 0xFF, 0xFF, 0x00, 0x7F, 0xFF, 0xFF, 0xFF, 0xE0, 0x0F, 0xFF
                    db 0xE0, 0x00, 0x00, 0x01, 0xFF, 0xFC, 0x00, 0x1F, 0x80, 0x1F, 0xFF, 0xFF, 0xFF, 0xC0
                    db 0x03, 0xFF, 0xFF, 0xFF, 0xF0, 0x00, 0x7F, 0xFF, 0xFF, 0xFF, 0x00, 0x7F, 0xFF, 0xFF
                    db 0xFF, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
