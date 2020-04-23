
INIT_DISPLAY
                .as
                ;set the display size - 128 x 64
                LDA #128
                STA COLS_PER_LINE
                LDA #64
                STA LINES_MAX

                ;set the visible display size - 80 x 60
                LDA #80
                STA COLS_VISIBLE
                LDA #60
                STA LINES_VISIBLE
                ;LDA #32
                ;STA BORDER_X_SIZE
                ;STA BORDER_Y_SIZE

                ; set the border to purple
                setas
                ;LDA #$20
                ;STA BORDER_COLOR_B
                ;STA BORDER_COLOR_R
                ;LDA #0
                ;STA BORDER_COLOR_G

                ; enable the border
                LDA #0 ;LDA #Border_Ctrl_Enable
                STA BORDER_CTRL_REG

                ; enable graphics, tiles and sprites display
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Bitmap_En + Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Sprite_En + Mstr_Ctrl_Text_Mode_En; + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L

                ; display intro screen
                ; wait for user to press a key or joystick button

                ;----------------------------------------------
                ; load tiles
.comment
                setaxl
                LDX #<>TILES
                LDY #0
                LDA #$2000 ; 256 * 32 - this is two rows of tiles
                MVN <`TILES,$B0; load tiles

.endc
                setaxl
                LDX #<>TILES_NB +$20000; +$2000
                LDY #0
                LDA #$8000 ; 256 * 128 - this is 8 rows of tiles
                MVN <`TILES_NB+$20000,$B0
.comment
                setaxl
                LDX #<>TILES_NB_RAW
                LDY #0
                LDA #$8000 ; 256 * 128 - this is 8 rows of tiles
                MVN <`TILES_NB_RAW,$B0
.endc
                ;----------------------------------------------
                ; load LUT
                ; GRPH_LUT1_PTR contain the pallete fron the BMP loaes before

                LDX #<>PALETTE_NB
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                ;MVN <`PALETTE_NB,<`GRPH_LUT0_PTR


                LDX #<>PALETTE
                LDY #<>GRPH_LUT1_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT1_PTR ; for the sprit block as it seam to only use  LUT 1 if you sellect the 0 in the config Byte

                ;LDX #<>PALETTE
                ;LDY #<>GRPH_LUT0_PTR
                ;LDA #1024
                ;MVN <`PALETTE,<`GRPH_LUT0_PTR

                setas
                ;----------------------------------------------
                ; enable tiles
                LDA #TILE_Enable + TILE_PAL0 + TILESHEET_256x256_En
                STA @lTL0_CONTROL_REG
.comment                ;---
                LDA #$00
                STA TL1_START_ADDY_L
                STA TL1_START_ADDY_M
                LDA #$B1
                STA TL1_START_ADDY_H
                LDX#0
                LDA#0
Loop_tile_map_1:
                STA TILE_MAP0,X
                INC A
                CMP #255
                BNE nnnsesd
                LDA #0
nnnsesd:        INX
                CPX #$8000
                BNE Loop_tile_map_1
                LDA #TILE_Enable + TILE_PAL3 + TILESHEET_256x256_En
                STA @lTL1_CONTROL_REG
.endc
                ; load tileset in tile hardware table 0
                JSR LOAD_TILESET_0
                setas
                LDA #0
                STA SECONDE_L_CLK
                STA SECONDE_H_CLK
                STA MINUTE_L_CLK
                STA MINUTE_H_CLK
                STA HOURS_L_CLK
                STA HOURS_H_CLK

                JSR UPDATE_CLOCK_DISPLAY

                ; render the first frame
                ;JSR LOAD_SPRITES

                ;JSR INIT_PLAYER
                ;JSR INIT_NPC

                ;LDA #$9F ; - joystick in initial state
                ;JSR UPDATE_DISPLAY
                RTS

LOAD_SPRITES
                .as

                LDA #0
                STA sprite_addr
                LDA #$B1
                STA sprite_addr + 2

                XBA
                LDX #0  ; X increments in steps of 8
    LS_LOOP
                ; enable sprites
                LDA #0
                STA @lSP00_ADDY_PTR_L,X
                LDA #SPRITE_Enable + TILE_PAL0
                STA @lSP00_CONTROL_REG,X
                STA @lSP00_ADDY_PTR_H,X
                TXA
                LSR
                STA @lSP00_ADDY_PTR_M,X
                STA sprite_addr + 1
                ASL

                JSR READ_SPRITE

                CLC
                ADC #8
                TAX
                CPX #128
                BNE LS_LOOP

                RTS

; *************************************************************
; * Read a sprite from tile memory
; *************************************************************
sprite_line    = $6
sprite_addr    = $10
READ_SPRITE
                .as
                PHA
                setal
                ; in our tileset, we have 8 sprites per line
                LDA game_array+6,X ; 0 to 15
                AND #$7
                asl
                asl
                asl
                asl ; multiply by 32
                asl
                STA sprite_line
                LDA game_array+6,X ; 0 to 15
                AND #8
                BEQ LOAD_X

                LDA #$2000 ; add 32 lines at 256 pixels

        LOAD_X
                CLC
                ADC sprite_line
                TAX

                LDA #32 ; sprites are 32 lines high
                STA sprite_line


    NEXT_LINE

                LDY #0

        NEXT_PIXEL
                setas
                LDA TILES + 256 * 32,X
                STA [sprite_addr],Y
                INX
                INY
                CPY #32 ; sprites are 32 pixels wide
                BNE NEXT_PIXEL
                setal
                TXA
                CLC
                ADC #256-32
                TAX

                LDA sprite_addr
                CLC
                ADC #32
                STA sprite_addr

                DEC sprite_line
                BNE NEXT_LINE
                LDA #0

                setas
                PLA
                RTS
; *************************************************************
; * Initialize default clock digits
; *************************************************************
DIGIT_START_TILE_INDEX
.byte 00,03,06,09,12
.byte 64,67,70,73,76

SECONDE_L_CLK .byte 0
SECONDE_H_CLK .byte 0
MINUTE_L_CLK .byte 0
MINUTE_H_CLK .byte 0
HOURS_L_CLK .byte 0
HOURS_H_CLK .byte 0

UPDATE_CLOCK_DISPLAY
                ; setup the tile size to copy
                LDA #3 ; Whidth size of the source tile
                STA TILE_BLOC_SIZE_X
                LDA #4  ; Hight size of the source tile
                STA TILE_BLOC_SIZE_Y
                ;-------------------------------------------
                ;               hour High
                setas
                LDA HOURS_H_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #10 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE
                ;-------------------------------------------
                ;              hour Low
                setas
                LDA HOURS_L_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #13 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE

                ;-------------------------------------------
                ;                 min High
                setas
                LDA MINUTE_H_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #17 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE

                ;-------------------------------------------
                ;                 min Low
                setas
                LDA MINUTE_L_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #20 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE

                ;-------------------------------------------
                ;                 second High
                setas
                LDA SECONDE_H_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #24 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE

                ;-------------------------------------------
                ;                 second Low
                setas
                LDA SECONDE_L_CLK;
                TAX
                setas
                LDA DIGIT_START_TILE_INDEX,X
                setaxl
                ; load the destination
                PHA
                LDA #27 ; destination position X in the tile map
                TAX
                LDA #12 ; destination position Y in the tile map
                TAY
                PLA
                JSL COPY_BLOC_TILE

                RTS

; *************************************************************
; * Copy the tile bloc from A at position X,Y on the tile Map
; *************************************************************

TILE_BLOC_START     .word $0
TILE_BLOC_SIZE_X    .word $3
TILE_BLOC_SIZE_Y    .word $4

TILE_BLOC_DEST_POSITION_X   .word $0
TILE_BLOC_DEST_POSITION_Y   .word $0
;TILE_BLOC_DEST_LINEAR_ADDRESS .word $0

TILE_MAP_SIZE_X     .word 64
TILE_MAP_SIZE_Y     .word 32

COPY_BLOC_TILE
                ; Save the first tile number to copy
                setal
                AND #$00FF ; only 256 tile avaliable
                STA TILE_BLOC_START
                ; Save the X and Y potision
                TXA
                STA TILE_BLOC_DEST_POSITION_X
                TYA
                STA TILE_BLOC_DEST_POSITION_Y

                ; convert X,Y coordinate into a lineare one so TILE_MAP_SIZE_X * Y + X
                LDA TILE_MAP_SIZE_X
                STA @l M0_OPERAND_A
                LDA TILE_BLOC_DEST_POSITION_Y
                STA @l M0_OPERAND_B
                LDA @l M0_RESULT
                STA @l ADDER32_A_LL          ; Store in 32Bit Adder (A)
                LDA @l M0_RESULT+2
                STA @l ADDER32_A_HL          ; Store in 32Bit Adder (A)
                LDA TILE_BLOC_DEST_POSITION_X
                STA @l ADDER32_B_LL          ; Put the X Position Adder (B)
                LDA #$0000
                STA @l ADDER32_B_HL
                LDA @l ADDER32_R_LL          ; Put the Results in TEMP
                STA @l ADDER32_A_LL ; TILE_BLOC_DEST_LINEAR_ADDRESS ofste
                LDA @l ADDER32_R_HL          ; Put the Results in TEMP
                STA @l ADDER32_A_HL ;TILE_BLOC_DEST_LINEAR_ADDRESS+2 ofste;

                LDA #<>TILE_MAP0
                STA @l ADDER32_B_LL          ; Put the X Position Adder (B)
                LDA #$00AF
                STA @l ADDER32_B_HL
                LDA @l ADDER32_R_LL          ; Put the Results in TEMP
                STA USER_TEMP ; TILE_BLOC_DEST_LINEAR_ADDRESS
                LDA @l ADDER32_R_HL          ; Put the Results in TEMP
                STA USER_TEMP+2 ;TILE_BLOC_DEST_LINEAR_ADDRESS+2;

                ; From here we have to write the first line of tile index at this address
                ; the next line just need to start at TILE_BLOC_DEST_LINEAR_ADDRESS + TILE_MAP_SIZE_X
                ; so the grafoics will be aline

                ; comput the tile index to write in the tile Map
                ;-----------------------------------------
                LDA TILE_BLOC_START
                LDX #0
                LDY #0
                setas
                PHA
                BRA COPY_BLOC_TILE__NEXT_TILE
                ;-----------------------------
 COPY_BLOC_TILE__NEXT_LINE:
                setas
                LDY #0
 COPY_BLOC_TILE__NEXT_TILE:
                PLA
                STA [USER_TEMP],y ; user temp contain the tile map ofset to write to, Need ter be in banc 0 and with y to use the indirectr addressing
                INY ; next tile ofset
                INC A ; set the next tile val
                PHA
                TYA
                CMP TILE_BLOC_SIZE_X
                ;-----------------------------
                BNE COPY_BLOC_TILE__NEXT_TILE
                INX ; next line
                PLA
                ; comput the new til value
                LDA TILE_BLOC_START
                CLC
                ADC #$10 ; aixe of a till map in tile unit 16*16 => 256 differnt tile
                STA TILE_BLOC_START
                PHA
                setal
                LDA USER_TEMP
                STA @l ADDER32_A_LL
                LDA USER_TEMP+2
                STA @l ADDER32_A_HL
                LDA TILE_MAP_SIZE_X
                STA @l ADDER32_B_LL
                LDA #$0000
                STA @l ADDER32_B_HL
                LDA @l ADDER32_R_LL          ; Put the Results in TEMP
                STA USER_TEMP ; new TILE_BLOC_DEST_LINEAR_ADDRESS
                LDA @l ADDER32_R_HL          ; Put the Results in TEMP
                STA USER_TEMP+2 ;new TILE_BLOC_DEST_LINEAR_ADDRESS+2;

                TXA ; X contain the Y address ofset as the indrect adressing can't only usr the X register
                CMP TILE_BLOC_SIZE_Y
                BNE COPY_BLOC_TILE__NEXT_LINE
                setas
                PLA
                RTL
; *************************************************************
; * Initialize player position
; *************************************************************
INIT_PLAYER
                ; start at position (100,100)
                setal
                LDA #8 * 32 + 32
                STA PLAYER_X
                STA @lSP15_X_POS_L
                LDA #10 * 32 + 64
                STA PLAYER_Y
                STA @lSP15_Y_POS_L
                setas
                RTS

; *************************************************************
; * Initialize non-player components, from the game_array
; *************************************************************
INIT_NPC
                .as
                setal
                LDX #0

        INIT_NPC_LOOP
                LDA game_array + 2,X ; X POSITION
                STA @lSP00_X_POS_L,X
                LDA game_array + 4,X ; Y POSITION
                STA @lSP00_Y_POS_L,X

                TXA
                CLC
                ADC #8
                TAX
                CPX #120
                BNE INIT_NPC_LOOP

                setas
                RTS

; ****************************************************
; * A contains the joystick byte
; ****************************************************
TICK_COUNT .byte 0
UPDATE_CLOCK
                setas
                LDA TICK_COUNT
                INC A
                STA TICK_COUNT
                CMP #60
                BNE UPDATE_CLOCK_NOTHING_TO_DO_1
                BRA UPDATE_CLOCK__UPDATE_TIME_VARIABLE
UPDATE_CLOCK_NOTHING_TO_DO_1:
                BRL UPDATE_CLOCK_NOTHING_TO_DO
UPDATE_CLOCK__UPDATE_TIME_VARIABLE:
                LDA #0
                STA TICK_COUNT
                LDA SECONDE_L_CLK
                INC A
                STA SECONDE_L_CLK
                CMP #10
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA SECONDE_L_CLK
                LDA SECONDE_H_CLK
                INC A
                STA SECONDE_H_CLK
                CMP #06
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA SECONDE_H_CLK
                LDA MINUTE_L_CLK
                INC A
                STA MINUTE_L_CLK
                CMP #10
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA MINUTE_L_CLK
                LDA MINUTE_H_CLK
                INC A
                STA MINUTE_H_CLK
                CMP #06
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA MINUTE_H_CLK
                LDA HOURS_L_CLK
                INC A
                STA HOURS_L_CLK
                CMP #10
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA HOURS_L_CLK
                LDA HOURS_H_CLK
                INC A
                STA HOURS_H_CLK
                CMP #02
                BNE UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME
                LDA #0
                STA HOURS_H_CLK
UPDATE_CLOCK_NO_NEEED_TO_UPDATE_TIME:
                JSR UPDATE_CLOCK_DISPLAY
UPDATE_CLOCK_NOTHING_TO_DO:
                setal
                RTS
; ****************************************************
; * A contains the joystick byte
; ****************************************************
UPDATE_DISPLAY
                .as
                PHA
                JSR UPDATE_HOME_TILES
                JSR UPDATE_WATER_TILES
                PLA
                setal
        JOY_UP
                BIT #1 ; up
                BNE JOY_DOWN
                JSR PLAYER_MOVE_UP
                BRA JOY_DONE

        JOY_DOWN
                BIT #2 ; down
                BNE JOY_LEFT
                JSR PLAYER_MOVE_DOWN
                BRA JOY_DONE

        JOY_LEFT
                BIT #4
                BNE JOY_RIGHT
                JSR PLAYER_MOVE_LEFT
                BRA JOY_DONE

        JOY_RIGHT
                BIT #8
                BNE JOY_DONE
                JSR PLAYER_MOVE_RIGHT
                BRA JOY_DONE

        JOY_DONE
                setas
                JSR UPDATE_NPC_POSITIONS
                JSR COLLISION_CHECK
                RTS

; ****************************************************
; * Update non-players
; ****************************************************
UPDATE_NPC_POSITIONS
                .as
                setal
                LDX #0

        UNPC_LOOP
                LDA game_array + 2,X ; X POSITION
                CLC
                ADC game_array,X ; add the speed
                BCC GRT_LFT_MRG

                CMP #16
                BCS GRT_LFT_MRG
                LDA #640-32 ; right edge
                BRA LESS_RGT_MRG

        GRT_LFT_MRG
                CMP #640 - 32
                BCC LESS_RGT_MRG
                LDA #0

        LESS_RGT_MRG
                STA @lSP00_X_POS_L,X
                STA game_array + 2,X


                TXA
                CLC
                ADC #8
                TAX
                CPX #120
                BNE UNPC_LOOP

                setas
                RTS

; ********************************************
; * Player movements
; ********************************************
PLAYER_MOVE_DOWN
                .al
                LDA PLAYER_Y
                CLC
                ADC #32
                ; check for collisions and out of screen
                CMP #480 - 96
                BCC PMD_DONE
                LDA #480 - 96 ; the lowest position on screen

        PMD_DONE
                STA PLAYER_Y
                STA SP15_Y_POS_L
                RTS

PLAYER_MOVE_UP
                LDA PLAYER_Y
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #96
                BCS PMU_DONE
                LDA #96

        PMU_DONE
                STA PLAYER_Y
                STA SP15_Y_POS_L
                RTS

PLAYER_MOVE_RIGHT
                LDA PLAYER_X
                CLC
                ADC #32
                ; check for collisions and out of screen
                CMP #640 - 64
                BCC PMR_DONE
                LDA #640 - 64 ; the lowest position on screen

        PMR_DONE
                STA PLAYER_X
                STA SP15_X_POS_L
                RTS

PLAYER_MOVE_LEFT
                LDA PLAYER_X
                SEC
                SBC #32
                ; check for collisions and out of screen
                CMP #32
                BCS PML_DONE
                LDA #32

        PML_DONE
                STA PLAYER_X
                STA SP15_X_POS_L
                RTS

; *****************************************************************
; * Compare the location of each sprite with the player's position
; * Sprites are 32 x 32 so the math is pretty simple.
; * Collisions occur with cars and buses and with water.
; * Frog can hop on logs.
; *****************************************************************
COLLISION_CHECK
                .as
                setal
                LDA PLAYER_Y
                CMP #256 ; mid-screen

                BCC WATER_COLLISION
                JSR STREET_COLLISION
                setas
                RTS

        WATER_COLLISION
                .al
        ; here do the water collision routine
                CMP #224
                BCS CCW_DONE

                CMP #128
                BCC HOME_LINE

                LDX #0

        NEXT_WATER_ROW
                LDA game_array+4,X  ; read the Y position
                CMP PLAYER_Y
                BNE CCW_CONTINUE

                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position
                BEQ FLOAT
                BCC CHECK_RIGHT_BOUND_W
        CHECK_LEFT_BOUND_W
                LDA game_array+2,X
                ADC #32
                CMP PLAYER_X
                BCS FLOAT
                BRA CCW_CONTINUE
        CHECK_RIGHT_BOUND_W
                ADC #32
                CMP game_array+2,X  ; read the X position
                BCS FLOAT


        CCW_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                CPX #8*16-8
                BNE NEXT_WATER_ROW
                BRA COLLISION

        CCW_DONE
                setas
                RTS

        FLOAT
                .al
                ; move the frog with the NPC
                CLC
                LDA PLAYER_X
                ADC game_array,X
                CMP #32
                BCC COLLISION
                CMP #640-32
                BCS COLLISION

                STA PLAYER_X
                STA SP15_X_POS_L
                setas
                RTS

        HOME_LINE
                .al
                LDA PLAYER_X
                LSR
                LSR
                LSR
                LSR ; divide by 16
                TAX
                setas
                LDA game_board + 280,X
                AND #$FF
                CMP #'H'
                BNE COLLISION

                setas
                RTS

        COLLISION
                .al
                ; restart the player at first row
                setas
                JSR INIT_PLAYER
                RTS

STREET_COLLISION
                .al
                LDX #0
        NEXT_STREET_ROW
                LDA game_array+4,X  ; read the Y position
                CMP PLAYER_Y
                BNE CCS_CONTINUE

                LDA PLAYER_X
                CMP game_array+2,X  ; read the X position

                BEQ COLLISION
                BCC CHECK_RIGHT_BOUND
        CHECK_LEFT_BOUND
                LDA game_array+2,X
                ADC #32
                CMP PLAYER_X
                BCS COLLISION
                BRA CCS_CONTINUE

        CHECK_RIGHT_BOUND
                ADC #32
                CMP game_array+2,X  ; read the X position
                BCS COLLISION

        CCS_CONTINUE
                TXA
                CLC
                ADC #8
                TAX
                CPX #8*16-8
                BNE NEXT_STREET_ROW
        CC_DONE
                setas
                RTS

HOME_CYCLE      .byte 0
EVEN_TILE_VAL   .byte $12
ODD_TILE_VAL    .byte $13
UPDATE_HOME_TILES
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA HOME_CYCLE
                INC A
                CMP #15 ; only update every N SOF cycle
                BNE UT_SKIP
                LDA #0
                STA HOME_CYCLE

                LDX #280 ; line 8 in the game board`
                LDY #7 * 64 ; line 8 in the tileset
                setdbr $AF

        UT_GET_TILE
                LDA game_board,X
                CMP #'H'
                BNE UT_DONE

                TXA
                AND #1
                BEQ UT_EVEN_TILE
                LDA EVEN_TILE_VAL

                STA TILE_MAP0,Y
                BRA UT_DONE

        UT_EVEN_TILE
                LDA ODD_TILE_VAL
                STA TILE_MAP0,Y

        UT_DONE
                INY
                INX
                CPX #320
                BNE UT_GET_TILE

                ; alternate the tiles
                LDA EVEN_TILE_VAL
                CMP #$12
                BEQ ALT_ODD
                ; A is $13
                STA ODD_TILE_VAL
                LDA #$12
                STA EVEN_TILE_VAL
                RTS

        ALT_ODD
                ; A is 12
                STA ODD_TILE_VAL
                LDA #$13
                STA EVEN_TILE_VAL

                RTS

    UT_SKIP
                STA HOME_CYCLE
                RTS



WATER_CYCLE     .byte 0
EVEN_WTILE_VAL  .byte $4
ODD_WTILE_VAL   .byte $14
UPDATE_WATER_TILES
                .as
                ; alternate the HOME tiles to imitate wind motion
                LDA WATER_CYCLE
                INC A
                CMP #12 ; only update every N SOF cycle
                BNE UW_SKIP
                LDA #0
                STA WATER_CYCLE

                LDX #8 * 40 ; line 9 in the game board`
                LDY #8 * 64 ; line 8 in the tileset
                setdbr $AF

        UW_GET_TILE
                LDA game_board,X
                CMP #'W'
                BNE UW_DONE

                ;check if X is even/odd
                TXA
                AND #1
                BEQ UW_EVEN_TILE
                LDA EVEN_WTILE_VAL

                STA TILE_MAP0,Y
                BRA UW_DONE

        UW_EVEN_TILE
                LDA ODD_WTILE_VAL
                STA TILE_MAP0,Y

        UW_DONE
                INY
                setal
                TYA
                AND #$3F
                CMP #40
                BNE WT_NEXT_TILE
                TYA
                CLC
                ADC #24
                TAY

    WT_NEXT_TILE
                setas

                INX
                CPX #14 * 40
                BNE UW_GET_TILE

                ; alternate the tiles
                LDA EVEN_WTILE_VAL
                CMP #4
                BEQ W_ALT_ODD
                ; A is $14
                STA ODD_WTILE_VAL
                LDA #$4
                STA EVEN_WTILE_VAL
                RTS

        W_ALT_ODD
                ; A is 4
                STA ODD_WTILE_VAL
                LDA #$14
                STA EVEN_WTILE_VAL

                RTS

    UW_SKIP
                STA WATER_CYCLE
                RTS
; ****************************************************
; * Write a Hex Value to the position specified by Y
; * Y contains the screen position
; * A contains the value to display
HEX_MAP         .text '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
LOW_NIBBLE      .byte 0
HIGH_NIBBLE     .byte 0
WRITE_HEX
                .as
                .xl
        PHA
            PHX
                PHY
                PHA
                    AND #$F0
                    lsr A
                    lsr A
                    lsr A
                    lsr A
                    setxs
                    TAX
                    LDA HEX_MAP,X
                    STA @lLOW_NIBBLE

                PLA
                AND #$0F
                TAX
                LDA HEX_MAP,X
                STA @lHIGH_NIBBLE

                setaxl
                PLY
                LDA @lLOW_NIBBLE
                STA [SCREENBEGIN], Y
                ; change the foreground color of the text
                LDA #$1010
                TYX
                STA @lCS_COLOR_MEM_PTR, X
                setas
            PLX
        PLA
                RTS

; *********************************************************
; * Convert the game_board to a tile set
; *********************************************************
LOAD_TILESET_0
                LDX #0
                LDY #0
                setdbr $AF
                setas
    GET_TILE_0
                LDA game_board_0,X
                STA TILE_MAP0,Y
                INY
                setal
                TYA
                AND #$3F
                CMP #40 ; 1 line is 40 tile
                BNE LT_NEXT_TILE_0
                TYA
                CLC
                ADC #24
                TAY

    LT_NEXT_TILE_0
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GET_TILE_0
                RTS
; *********************************************************
; * Convert the game_board to a tile set
; *********************************************************
LOAD_TILESET_1
                LDX #0
                LDY #0
                setdbr $AF
                setas
    GET_TILE_1
                LDA game_board_1,X
                STA TILE_MAP1,Y
                INY
                setal
                TYA
                AND #$3F
                CMP #40 ; 1 line is 40 tile
                BNE LT_NEXT_TILE_1
                TYA
                CLC
                ADC #24
                TAY

    LT_NEXT_TILE_1
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GET_TILE_1
                RTS
; *********************************************************
; * Convert the game_board to a tile set
; *********************************************************
LOAD_TILESET_2
                LDX #0
                LDY #0
                setdbr $AF
                setas
    GET_TILE_2
                LDA game_board_2,X
                STA TILE_MAP2,Y
                INY
                setal
                TYA
                AND #$3F
                CMP #40 ; 1 line is 40 tile
                BNE LT_NEXT_TILE_2
                TYA
                CLC
                ADC #24
                TAY

    LT_NEXT_TILE_2
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GET_TILE_2
                RTS
; *********************************************************
; * Convert the game_board to a tile set
; *********************************************************
LOAD_TILESET
                LDX #0
                LDY #0
                setdbr $AF
                setas
    GET_TILE
                LDA game_board,X
                STA TILE_MAP0,Y
                BRL LT_DONE


        ;DOT:
                CMP #'.'
                BNE GRASS
                LDA #0
                STA TILE_MAP0,Y
                BRL LT_DONE

        GRASS
                CMP #'G'
                BNE HOME
                LDA #2
                STA TILE_MAP0,Y
                BRL LT_DONE

        HOME
                CMP #'H'
                BNE WATER

                TXA
                AND #1
                BEQ EVEN_TILE
                LDA #$13
                STA TILE_MAP0,Y
                BRL LT_DONE

            EVEN_TILE
                LDA #$12
                STA TILE_MAP0,Y
                BRL LT_DONE

        WATER
                CMP #'W'
                BNE CONCRETE
                LDA #4
                STA TILE_MAP0,Y
                BRL LT_DONE

        CONCRETE
                CMP #'C'
                BNE ASHPHALT
                LDA #1
                STA TILE_MAP0,Y
                BRL LT_DONE

        ASHPHALT
                CMP #'A'
                BNE DIRT
                LDA #5
                STA TILE_MAP0,Y
                BRL LT_DONE

        DIRT
                CMP #'D'
                BNE LT_DONE
                LDA #3
                STA TILE_MAP0,Y
                BRL LT_DONE

    LT_DONE
                INY
                setal
                TYA
                AND #$3F
                CMP #40
                BNE LT_NEXT_TILE
                TYA
                CLC
                ADC #24
                TAY

    LT_NEXT_TILE
                setas
                INX
                CPX #(640/16) * (480 / 16)
                BNE GET_TILE_1_Long
                RTS
GET_TILE_1_Long
                BRL GET_TILE
; our resolution is 640 x 480 - tiles are 16 x 16 - therefore 40 x 30
game_board    ; all the same for now
game_board_1
game_board_2
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,6
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
game_board_0
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
PALETTE
.binary "assets/simple-tiles.data.pal"

PALETTE_NB
.binary "assets/nb_till.pal"

* = $170000
TILES
.binary "assets/simple-tiles.data"
* = $180000
TILES_NB_RAW
.binary "assets/nb_till.pixel"
* = $1B0000
TILES_NB
.binary "assets/nb_till.bmp"
