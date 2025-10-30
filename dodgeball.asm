	INCLUDE "hardware.inc"	; hardware constants


SECTION "Header", ROM0[$100]

	jp EntryPoint	; jump to EntryPoint

	ds $150 - @, 0		; Create space for the header

	; initialise globals
	ld a, 0
	ld [FrameCounter], a
	

EntryPoint:

WaitForvBlank:
	; wait until vBlank
	ld a, [rLY] 		; move the value of the Y coordinate of the vertical scanline into the accumulator
	cp 144			; 44 - 153 is the vBlank period
	jp c, WaitForvBlank	; cp automatically compares the accumulator value with 144, by subtracting 144 from a. if carry, it means that a - 144 was negative and set the carry bit, which means a was less than 144, so we go back to the start of the loop. if the carry bit is not set, then a is greater than or equal to 144, so we are in vBlank

	
	; turn off LCD screen
	ld a, 0
	ld [rLCDC], a		; load 0 into the LCD control register to turn it off

	; copy the tile data
	ld de, Tiles
	ld hl, $9000		; mem address hex 9000
	ld bc, TilesEnd - Tiles	; amount of memory needed

CopyTiles:
	ld a, [de]		; Tiles start memory address loaded into accumulator
	ld [hli], a		; load data from start of Tiles memory into address hex 9000 plus index i
	inc de
	dec bc
	ld a, b			; upper 8 bits of amount of memory value, is now in accumulator
	or a, c			; bitwise or of accumulator with lower 8 bits of amount of memory value, this combines the upper and lower 8 bits of the memory value, into the single 8 bit accumulator
	jp nz, CopyTiles
		


	; copy the tilemap data
	ld de, Tilemap 		; load the memory start address of the Tilemap data
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap ; amount of memory needed

CopyTilemap:
	ld a, [de]
	ld [hli], a              ; load data from start of Tilemap memory into address hex 9800 plus index i
	inc de
	dec bc
	ld a, b                ; upper 8 bits of amount of memory value, is now in accumulator
	or a, c			; bitwise or of accumulator with lower 8 bits of amount of memory value, this combines the upper and lower 8 bits of the memory value, into the single 8 bit accumulator
	jp nz, CopyTilemap
	

	; clearing object attribute memory (OAM)

	ld a, 0			; we want to put 0 in every location in OAM
	ld b, 160		; OAM is 160 bytes, so we use b as the index
	ld hl, _OAMRAM		; load the start address of OAM into hl


	
	; copy the player tile
	ld de, PlayerCharacter
	ld hl, $8000
	ld bc, PlayerCharacterEnd - PlayerCharacter
CopyPlayerCharacter:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyPlayerCharacter


ClearOam:
	ld [hli], a
	dec b
	jp nz, ClearOam		; clear memory until index, b, is 0

	; create player controlled character (one 8x16 sprite)

	ld hl, _OAMRAM
	ld a, 128 + 16 		; y coordinate is 128
	ld [hli], a
	ld a, 16 + 8		; x coordinate is 16
	ld [hli], a
	ld a, 0			; tile id 0
	ld [hli], a
	ld [hli], a


	; turn on LCD screen, with objects enabled
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON ; bitwise OR of LCD on, LCD background on and LCD object on flags to combine them into one 8 bit register
	ld [rLCDC], a		    ; load that into the LCD control register to turn it on

	; initialise background
	ld a, %11100100		; select gray shades to colour numbers of background and window tiles. light gray for colour number 1, dark gray for colour number 2, black for colour number 3
	ld [rBGP], a
	; initialise the first pallette
	ld a, %11100100		; select the gray shades to colour numbers of sprites. light gray for colour number 1, dark gray for colour number 2, black for colour number 3
	ld [rOBP0], a

	; initialise globals
	ld a, 0
	ld [FrameCounter], a

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main

WaitForvBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitForvBlank2

	ld a, [FrameCounter]
	inc a
	ld [FrameCounter], a
	cp a, 15		; every 15 frames, run the next code
	jp nz, Main

	; Reset the frame count back to 0
	ld a, 0
	ld [FrameCounter], a

	; move the player-character one pixel to the right
	ld a, [_OAMRAM + 1]
	inc a
	ld [_OAMRAM + 1], a
	jp Main

	; copy data from one memory location to another
	; @param de: Source
	; @param hl: Destination
	; @param bc: Length
Memcpy:
	ld a, [de]
	ld [hli], a 		; hli means that after access, hl is incremented
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcpy
	ret
	

End:
	jp End

PlayerCharacter:
    dw `13333331
    dw `30033003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PlayerCharacterEnd:

Tiles:

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
; ANCHOR: custom_logo
	dw `00000000
	dw `00000000
	dw `00000000
	; Paste your logo here:
	; tile number is reference to logo, not global area
	
	; row 0
	; tile 0
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111113
	dw `11111133
	dw `11111333
	dw `11113333

	; tile 1
	dw `11111111
	dw `11111111
	dw `11111111
	dw `13111111
	dw `33111111
	dw `03311111
	dw `00331111
	dw `00331111


	; tile 2
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	
	; tile 3
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111


	; row 1

	; tile 0
	dw `11111333
	dw `11111333
	dw `11111330
	dw `11113300
	dw `11133300
	dw `11133300
	dw `11133000
	dw `11133003

	; tile 1
	dw `00033111
	dw `00003311
	dw `00000331
	dw `00000033
	dw `00030000
	dw `00300000
	dw `03000000
	dw `30000000

	; tile 2
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `33111111
	dw `03311111
	dw `00331111
	dw `00033111
	
	; tile 3
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111

	; row 2

	; tile 0
	dw `11133003
	dw `11133030
	dw `11133030
	dw `11330030
	dw `11330030
	dw `11330030
	dw `11330300
	dw `13300302

	; tile 1
	dw `00000000
	dw `00000000
	dw `00011100
	dw `00111111
	dw `01111111
	dw `00000000
	dw `00000000
	dw `22222222

	; tile 2
	dw `00033111
	dw `00003311
	dw `00000331
	dw `11000033
	dw `11100000
	dw `00000000
	dw `22222000
	dw `22222200
	
	; tile 3
	dw `11111111
	dw `11111111
	dw `33111111
	dw `33111111
	dw `03311111
	dw `00331111
	dw `00033111
	dw `00003311

	; row 3

	; tile 0
	dw `33300302
	dw `33003002
	dw `33003022
	dw `33030000
	dw `00030000
	dw `00030000
	dw `00300011
	dw `00300011

	; tile 1
	dw `22222222
	dw `22222222
	dw `22222222
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11111111
	dw `11111111

	; tile 2
	dw `22222200
	dw `22222220
	dw `22222222
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11111111
	dw `11111111
	
	; tile 3
	dw `00003311
	dw `00000331
	dw `20000331
	dw `22000331
	dw `00000033
	dw `00000000
	dw `11111100
	dw `11111110
	



TilesEnd:


; ANCHOR_END: custom_logo

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 3,3,3,3,3,3,3,3,3,3,3,3
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:

SECTION "Count", WRAM0
FrameCounter: db		; count how many frames have elapsed since moving the player-character
