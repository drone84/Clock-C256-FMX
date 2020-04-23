INIT_DISPLAY
                setas
                ; diable the border
                LDA #0
                STA BORDER_CTRL_REG

                ; enable graphics hardware and the BitMap
                LDA #Mstr_Ctrl_Graph_Mode_En + Mstr_Ctrl_Bitmap_En; + Mstr_Ctrl_TileMap_En + Mstr_Ctrl_Sprite_En ; + Mstr_Ctrl_Text_Mode_En + Mstr_Ctrl_Text_Overlay
                STA MASTER_CTRL_REG_L

				;for debug purpos, erase the screen before loading (usefull to see if the code is properly loades by the IDE)
                setaxl
                LDX #<>$0

                LDX #<>$0
                LDA #$0
              erase_Byte_00:
                STA @l $B00000,x
                INX
                CPX #0
                BNE erase_Byte_00
              erase_Byte_01:
                STA @l $B10000,x
                INX
                CPX #0
                BNE erase_Byte_01
              erase_Byte_02:
                STA @l $B20000,x
                INX
                CPX #0
                BNE erase_Byte_02
              erase_Byte_03:
                STA @l $B30000,x
                INX
                CPX #0
                BNE erase_Byte_03
              erase_Byte_04:
                STA @l $B40000,x
                INX
                CPX #0
                BNE erase_Byte_04

				;Load the color palet
                setaxl
                ; load LUT
                LDX #<>PALETTE
                LDY #<>GRPH_LUT0_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT0_PTR

                LDX #<>PALETTE
                LDY #<>GRPH_LUT1_PTR
                LDA #1024
                MVN <`PALETTE,<`GRPH_LUT1_PTR
				
				;Load the Bitmap in VRAM starting at B0:0000
				:not sure if LDA #$FFFF will copy 0x1:0000 byte si I doing it in 2 passes
                ;----------------------
                LDX #<>HL_1
                LDY #<>$B00000
                LDA #$8000
                MVN <`HL_1,<`$B00000

                LDX #<>HL_1+$8000
                LDY #<>$B08000
                LDA #$8000
                MVN <`HL_1,<`$B08000
                ;----------------------
                LDX #<>HL_2
                LDY #<>$B10000
                LDA #$8000
                MVN <`HL_2,<`$B10000

                LDX #<>HL_2+$8000
                LDY #<>$B18000
                LDA #$8000
                MVN <`HL_2,<`$B18000
                ;----------------------
                LDX #<>HL_3
                LDY #<>$B20000
                LDA #$8000
                MVN <`HL_3,<`$B20000

                LDX #<>HL_3+$8000
                LDY #<>$B28000
                LDA #$8000
                MVN <`HL_3,<`$B28000
                ;----------------------
                LDX #<>HL_4
                LDY #<>$B30000
                LDA #$8000
                MVN <`HL_4,<`$B30000

                LDX #<>HL_4+$8000
                LDY #<>$B38000
                LDA #$8000
                MVN <`HL_4,<`$B38000
                ;----------------------
                LDX #<>HL_5
                LDY #<>$B40000
                LDA #$B000
                MVN <`HL_5,<`$B40000
                ;----------------------

				; enable the Bitmap harware and sellect the first pallete(LUT)
                setas
                LDA #1+2
                STA @l BM_CONTROL_REG
				
				; set the address where the bitmap is starting from the VRAM point of vue
				: ex : 
				; VRAM : 0x00:0000 <=> CPU 0xB0:0000
				; VRAM : 0x01:0000 <=> CPU 0xB0:1000
				; VRAM : 0x01:0000 <=> CPU 0xB1:0000
				; VRAM : 0x01:0020 <=> CPU 0xB1:0020
				; etc
				
                LDA #00
                STA @l BM_START_ADDY_L
                STA @l BM_START_ADDY_M
                LDA #00
                STA @l BM_START_ADDY_H

                setal
                LDA #640
                STA @l BM_X_SIZE_L
                LDA #480
                STA @l BM_Y_SIZE_L


                RTS
				
				
PALETTE
.binary "assets/halflife.pal"
* = $1a0000
TILES
.binary "assets/simple-tiles.data"
;BITMAP
* = $1B0000
HL_1
.binary "assets/halflife_1.pixel"
* = $1C0000
HL_2
.binary "assets/halflife_2.pixel"
* = $1D0000
HL_3
.binary "assets/halflife_3.pixel"
* = $1E0000
HL_4
.binary "assets/halflife_4.pixel"
* = $1F0000
HL_5
.binary "assets/halflife_5.pixel"