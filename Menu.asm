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
;                 ld      hl, logoAttrFx              ; Load in the attribute FX data
;                 ld      de, ATTRSCRNADDR
;                 ld      bc, 32 * 6
;                 ldir

                ld      hl, ATTRSCRNADDR              ; Load in the attribute FX data
                ld      de, ATTRSCRNADDR + 1
                ld      bc, 32 * 6
                ld      (hl), 7
                ldir

;                 ld      de, Logo                    ; Draw the logo sprite
;                 ld      bc, 0x0000
;                 call    drwSprt

                ld      hl, BTMPSCRNSDDR
                ld      de, BTMPSCRNSDDR + 1
                ld      bc, 6144
                ld      (hl), 255
                ldir

                ld      hl, ATTRSCRNADDR + (6 * 32) ; Fill the rest of the screen with cyan on black
                ld      de, ATTRSCRNADDR + (6 * 32) + 1
                ld      (hl), RED + BLUE
                ld      bc, ATTRSCRNSZ - 1
                ldir

                ; Print the menu options
                ld      de, kybrdTxt
                ld      bc, kybrdTxtEnd - kybrdTxt
                call    8252

                ld      de, snclrTxt
                ld      bc, snclrTxtEnd - snclrTxt
                call    8252

                ld      de, kmpstnTxt
                ld      bc, kmpstnTxtEnd - kmpstnTxt
                call    8252

                ld      de, strtTxt
                ld      bc, strtTxtEnd - strtTxt
                call    8252

                ; Set channel to the bottom of the screen and print the copyright
                ld      a, 1
                call    5633

                ld      de, cpyrght
                ld      bc, cpyrghtEnd - cpyrght
                call    8252

                ;*************************************
                ; Debug
IF .debug
                ld      e, 184
                ld      d, 8*1
                call    getPixelAddr
                ld      a, 256 - PAGE0E               ; Space left in Page 0                
                call    HexByte


                ld      e, 184
                ld      d, 8*4
                call    getPixelAddr
                ld      a, 256 - PAGE1E               ; Space left in Page 0                
                call    HexByte
                ;*************************************
ENDIF
                ld      hl, logoAttrFx              ; Load HL with the logo attr FX address
                ld      (attrFxAddr), hl            ; ...and save it to memory

_mnuLp
                ld      hl, 549                 ; 10T          

                halt                             ; Ts = 0
wait
                dec     hl                      ; 6T
                ld      a, h                    ; 9T
                or      l                       ; 4T
                jp      nz, wait                ; 7T + 12T when falls through

                ld      hl, 0x0202              ; 10T
                ld      de, 0x0404              ; 10T
                di
                ld      (oldStack), sp          ; 20T
                ld      sp, ATTRSCRNADDR + 32   ; 10T

                ; Total Ts to here is 14336

                push    hl                      ; 11T * 16 = 176T
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl

                ld      bc, 0                   ; 18 * 3 = 30
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                nop                             ; 4 * 2 = 8
                nop

                ld      sp, ATTRSCRNADDR + 32   ; 10T

                ; Total Ts 224

                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de
                push    de

                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0
                ld      bc, 0

                ld      sp, ATTRSCRNADDR + 32   ; 10T

                push    hl                      ; 11T
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl
                push    hl

                ld      sp, (oldStack)
                ei

                call    rdOptnKys                   ; Action any key presses


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
                ld      bc, 0xEFFE                  ; B = 0xED (67890), C = port 0xFE
                in      a, (c)                      ; Load A with the keys that have been pressed
                rra                                 ; Outermost bit = key 0
                jp      nc, strtNewGame 
                ret

;****************************************************************************************************************
; Variables
attrFxAddr      dw      0
logoFXCnt       db      0
oldStack        dw      0x0000

;****************************************************************************************************************
; Menu Text
strtTxt         db      17, PAPER * BLACK, 16, WHITE, 22, 11, 10, "0. START"
strtTxtEnd
kybrdTxt        db      17, PAPER * BLACK, 16, WHITE, 22, 13, 10, "1. KEYBOARD"
kybrdTxtEnd     
snclrTxt        db      17, PAPER * BLACK, 16, WHITE, 22, 15, 10, "2. SINCLAIR"
snclrTxtEnd
kmpstnTxt       db      17, PAPER * BLACK, 16, WHITE, 22, 17, 10, "3. KEMPTSTON"
kmpstnTxtEnd
cpyrght         db      17, BLUE, 16, GREEN, 22, 1, 8, "Mike Daley 2016"
cpyrghtEnd

LOGOFXINKCLR1   equ     YELLOW + BRIGHT
LOGOFXINKCLR2   equ     CYAN
logoAttrFx
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2

                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2

                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1

                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1

                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2

                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2

                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1

                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1
                db      LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1

                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
                db      LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2, LOGOFXINKCLR1, LOGOFXINKCLR1, LOGOFXINKCLR2, LOGOFXINKCLR2
