;****************************************************************************************************************
;
; This assmebly file contains the code used to display and manage the main menu
;
; 1. Keyboard
; 2. Kempston
; 3. Sinclair
; 0. Start
;
;****************************************************************************************************************

mnuLp
                ; Clear the screen
                ld      hl, BTMPSCRNSDDR            ; Point HL at the screen buffer
                ld      bc, BTMPSCRSZ               ; Load BC with the number of bytes to clear
                call    clrMem                      ; Clear memory

                ; Draw logo
                ld      hl, ATTRSCRNADDR
                ld      de, ATTRSCRNADDR + 1
                ld      (hl), 2
                ld      bc, ATTRSCRNSZ - 1
                ldir

                xor     a
                ld      de, Logo
                ld      bc, 0x0010
                call    drwSprt

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

                ld      a, 1
                call    5633

                ld      de, cpyrght
                ld      bc, cpyrghtEnd - cpyrght
                call    8252

                ld      a, 6
                ld      bc, 0x0000

_mnuLp
                halt
                ld      hl, ATTRSCRNADDR
                ld      de, ATTRSCRNADDR + 1
                ld      (hl), a
                ld      bc, 7*32
                ldir

                ld      b, 6
_pause          halt
                djnz    _pause

                dec     a
                jp      nz, _mnuLp
                ld      a, 6
                jp      _mnuLp

strtTxt         db      17, PAPER * BLACK, 16, WHITE, 22, 11, 10, "0. START"
strtTxtEnd
kybrdTxt        db      17, PAPER * BLACK, 16, WHITE, 22, 13, 10, "1. KEYBOARD"
kybrdTxtEnd     
snclrTxt        db      17, PAPER * BLACK, 16, WHITE, 22, 15, 10, "2. SINCLAIR"
snclrTxtEnd
kmpstnTxt       db      17, PAPER * BLACK, 16, WHITE, 22, 17, 10, "3. KEMPTSTON"
kmpstnTxtEnd
cpyrght         db      17, BLUE, 16, GREEN, 22, 1, 9, "Mike Daley 2016"
cpyrghtEnd