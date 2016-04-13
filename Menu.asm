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
                ld      bc, 32 * 6
                ldir

                ld      de, Logo                    ; Draw the logo sprite
                ld      bc, 0x0000
                call    drwSprt

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
                ld      b, 5                        ; Pause for (1/50 * A) seconds

_pause          halt                                ; Wait for V-Sync
                push    bc                          ; Save B as it contains our pause counter
                call    rdOptnKys                   ; Action any key presses
                pop     bc                          ; Restore B
                djnz    _pause

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
                cp      4                           ; Compare with 4
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
