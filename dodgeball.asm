	INCLUDE "hardware.inc"	; hardware constants


SECTION "Header", ROM0[$100]

	jp EntryPoint	; jump to EntryPoint

	ds $150 - @, 0		; Create space for the header

	; initialise globals
	ld a, 0
	ld [FrameCounter], a
	ld [CurKeys], a
	ld [NewKeys], a
	ld [BallCaught], a
	ld [PlayerBallThrown], a

	ld [ReadyToThrow], a
	ld a, 1
	ld [MoveRight], a
	
	

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
	call Memcpy
		


	; copy the tilemap data
	ld de, Tilemap 		; load the memory start address of the Tilemap data
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap ; amount of memory needed
	call Memcpy
	

	; clearing object attribute memory (OAM)

	ld a, 0			; we want to put 0 in every location in OAM
	ld b, 160		; OAM is 160 bytes, so we use b as the index
	ld hl, _OAMRAM		; load the start address of OAM into hl


	
	; copy the player tiles
	ld de, PlayerCharacter
	ld hl, $8000
	ld bc, PlayerCharacterEnd - PlayerCharacter
	call Memcpy

	; copy the ball tiles
	ld de, Ball
	ld hl, $8010
	ld bc, BallEnd - Ball
	call Memcpy


ClearOam:
	ld [hli], a
	dec b
	jp nz, ClearOam		; clear memory until index, b, is 0

	; create player controlled character (one 8x8 sprite)

	ld hl, _OAMRAM
	ld a, 128 + 16 		; y coordinate is 128, stored at an offset of 16 in memory
	ld [hli], a
	ld a, 53 + 8		; x coordinate is 53, stored at an offset of 8 in memory
	ld [hli], a
	ld a, 0			; tile id 0
	ld [hli], a
	ld [hli], a		; attribute is 0 so 8x8

	; create ball (one 8x8 sprite)
	ld hl, _OAMRAM + 4
	ld a, 79 + 16		; y coord is 79, middle of screen
	ld [hli], a
	ld a, 57 + 8		; x coord is 57, middle of screen
	ld [hli], a
	ld a, 1			; tile ID is 1
	ld [hli], a
	ld a, 0
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

	; check the keys each frame and move left or right
	call UpdateKeys



	call MoveBallFromPlayer


CheckBallCaughtByPlayer:
	; if ball has been caught by the player, run the ball-caught update routine
	ld a, [BallCaught]
	cp a, 1
	jp z, CaughtBallMove	; if ball hasn't been caught, go to CheckLeft
	jp CheckLeft

CaughtBallMove:	
	; ball caught, find out the position of the player and keep the ball close to that position
	ld a, [_OAMRAM]		; y pos of player
	sub a, 5		; move ball slightly above player
	ld [_OAMRAM + 4], a	; y pos of ball becomes y pos of player, minus gap

	ld a, [_OAMRAM + 1]	; x pos of player
	ld [_OAMRAM + 5], a	; x pos of ball becomes x pos of player

	
	; if ball hasn't been caught, then the movement is handled by the direction it was thrown, and the frame counter, which determines whether it is in motion or stopped

	; check if left button is pressed
CheckLeft:
	ld a, [CurKeys]
	and a, PADF_LEFT	; accumulator bits only set if they are set in PADF_LEFT, which is a constant defined in hardware.inc as $20
	jp z, CheckRight	; if the zero flag is set, then it means that value in a shows left key not set, so now check the right key
Left:
	; move the paddle one pixel to the left
	ld a, [_OAMRAM + 1]	; we add one to the _OAMRAM address because the first byte is the Y position and the second byte is the X position, we want x
	dec a			; decrement a because moving left means a decrease in x coord

	; if already reached the wall, then stop
	cp a, 7		; left wall edge has x coord of 15, if x coord is 0, then we reached the left wall
	jp z, Main
	ld [_OAMRAM + 1], a	; if we haven't reached the wall, then we know that the x coord in OAM needs to be updated
	jp Main

	; check right button

CheckRight:
	ld a, [CurKeys]
	and a, PADF_RIGHT
	jp z, CheckUp			; if zero, go to CheckUp
	; else, move the object to the right

Right:
	ld a, [_OAMRAM + 1]
	inc a			; moving to right is increase in x coord

	; check we have't reached right wall
	cp a, 113
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

	; check up button
CheckUp:
	ld a, [CurKeys]
	and a, PADF_UP
	jp z, CheckDown		; if zero go to CheckDown
	; else, move the object up

Up:
	ld a, [_OAMRAM]		; the y coordinate is the first piece of info in OAM, so we don't need to add any bytes
	dec a			; decreasing a moves the object up

	; check if we are at the top
	cp a, 15
	jp z, Main		; if we are then stop
	ld [_OAMRAM], a		; if not, load in the new y coordinate
	jp Main
	
CheckDown:
	ld a, [CurKeys]
	and a, PADF_DOWN
	jp z, CheckCatchY

	; move the object down
	ld a, [_OAMRAM]
	inc a
	; check if we are at bottom
	cp a, 158
	jp z, Main
	ld [_OAMRAM], a
	jp Main

CheckCatchY:

	; load a with player position and b with ball position
	; assume player is lower down on screen than ball
	; make ball move through a slightly smaller playfield, to accomodate this
	ld a, [_OAMRAM+4]		; y coord of ball in a
	ld b, a			        ; y coord of ball in b
	ld a, [_OAMRAM]			; y coord of player in a
	sub a, b
	cp a, 10
	; if a is less than 10, the c flag is set
	; if c flag set, we want to continue with the check
	jp c, CheckCatchX
	jp CheckThrow		; but if c not set, c greater than or equal to 10, so we want to exit the CheckCatch and go back to main 
	; maybe jp Throw is better, this is not the same as the left, right, up down checks
	

;	TODO-1: provide tolerance for X catch -> the player should not have to perfectly line up with the x coord of the ball in order to catch!
; have separate checkcatchx routine for when a > b and for when b > a
CheckCatchX:
; cp a, b does a - b


	ld a, [_OAMRAM + 5]	; x coord of ball in a
	ld b, a			; x coord of ball in b
	ld a, [_OAMRAM + 1]	; x coord of player in a
	; check whether a or b is greater
	cp a, b
	jp c, CheckCatchXNegResult ; if carry flag is set, that means that a < b
	sub a, b				; so at this point we know that a > b
	cp a, 10				; if the carry flag is set, then a < 10 which means the player's x coord is close enough to catch
	jp nc, CheckThrow		; if the carry flag is not set then x coords aren't close enough, can't catch, back to CheckThrow
	jp ActualCheckCatch		; to make sure that the catch sound can potentially be played, since the player is close enough to catch			

CheckCatchXNegResult:
; so we know that x-player < x-ball
; so load the coords in the other register, have x coord of ball in a and x coord of player in b
; this ensures that once again, a is actually greater than b
	ld a, [_OAMRAM + 1] ; x coord of player in a
	ld b, a 			; x coord of player in b
	ld a, [_OAMRAM + 5] ; x coord of ball in a 
	sub a, b
	cp a, 10				; if the carry flag is set, then a < 10 which means the player's x coord is close enough to catch
	jp nc, CheckThrow		; if the carry flag is not set then x coords aren't close enough, can't catch, back to CheckThrow
	jp ActualCheckCatch		; to make sure that the catch sound can potentially be played, since the player is close enough to catch	


	
; designed to play the catch sound
ActualCheckCatch:
	
	ld a, [CurKeys]
	and a, PADF_B		; PADF_B maps to A on a keyboard
	jp z, CheckThrow
	ld a, 1
	ld [BallCaught], a	; set BallCaught flag to 1
	ld a, 0
	ld [PlayerBallThrown], a ; set PlayerBallThrown flag to 0
	ld a, 0
	ld a, $16
	ld [$FF10], a		; set sweep time to 1 (sweep time allows freq. to gradually increase or decrease), but 1 means it stays samee
	ld a, $40
	ld [$FF11], a		; set length of sound
	ld a, $73
	ld [$FF12], a		; volume and how volume changes
	ld a, $0
	ld [$FF13], a		; set frequency
	ld a, $C3
	ld [$FF14], a		; playback length for sound (not sure how this differs from usual length)
	
CheckThrow:
	ld a, [CurKeys]
	and a, PADF_A		; PADF_A maps to S on a keyboard
	jp z, Main		; if it wasn't pressed then go to Main
	; else ball was thrown
	ld a, 0			
	ld [BallCaught], a
	ld a, 1
	ld [PlayerBallThrown], a ; set PlayerBallThrown flag to 1
	ld a, 0

	ld a, $30
	ld [$FF10], a		; set sweep time to 1 (sweep time allows freq. to gradually increase or decrease), but 1 means it stays samee
	ld a, $60
	ld [$FF11], a		; set length of sound
	ld a, $73
	ld [$FF12], a		; volume and how volume changes
	ld a, $80
	ld [$FF13], a		; set frequency
	ld a, $FF
	ld [$FF14], a		; playback length for sound (not sure how this differs from usual length)
	jp Main

UpdateKeys:
	
	; Poll half the controller
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a 			; B7-4 = 1 B3 - 0 = unpressed buttons

	; poll the other half
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a			; A7-4 = unpressed directions A3-0 = 1
	xor a, b		; A = pressed buttons + directions
	ld b, a			; B = pressed buttons + directions

	; now release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a

	; Combine with previous CurKeys to make NewKeys
	ld a, [CurKeys]
	xor a, b		; A = keys that changed state
	and a, b		; A = keys that changed to pressed
	ld [NewKeys], a
	ld a, b
	ld [CurKeys], a
	ret

.onenibble
	ldh [rP1], a		; switch the key matrix, P1 is defined in hardware.inc and means $FF00,this memory address is actually a register and is used to read joypad input
	call .knownret		; expend 10 cycles calling a known return
	ldh a, [rP1]		; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]		; it is ldh rather than ld as ld is only for loading to and from the hl register
	ldh a, [rP1]   ; to handle debouncing, this is the only read we use
	or a, $F0      ; A7-4 = 1 A3-0 = unpressed keys
.knownret
	ret


HitLowerWall:
	ret

HitPlayer:
	ret
	

MoveBallFromPlayer:
	ld a, [PlayerBallThrown]
	cp a, 1
	jp nz, NotThrown

	; now add check to see if it has hit wall, if it has jp to HitWall
	ld a, [_OAMRAM + 4]
	cp a, 15
	jp c, HitWall

	; now check to see if it has hit the opponent, if it has jp to HitOpponent
	ld a, [_OAMRAM+8]	; y coord of opponent in a
	ld b, a			; y coord of opponent in b
	ld a, [_OAMRAM+4]	; y coord of ball in a
	; for ease of programming, test that they are equal only
	cp a, b
	jp nz, CanMove		; if the y coords of ball and opponent are not equal, go to CanMove

	ld a, [_OAMRAM+9]	; x coord of opponent in a
	ld b, a			; x coord of opponent in b
	ld a, [_OAMRAM+5]	; x coord of ball in a
	cp a, b


CanMove:	
	ld a, [_OAMRAM + 4]
		dec a
	;sub a, 2
	ld [_OAMRAM + 4], a
	

	ret

NotThrown:	
	
	ret

HitWall:
	; if ball has hit wall, we don't move it up
	; and we set the PlayerBallThrown flag to 0
	ld a, 0
	ld [PlayerBallThrown], a

	ret


DoMove:
	; if x coord exceeds 100, moveRight flag set to 0
	; if x coord is less than 5, moveRight flag set to 1
	; flag set at top of DoMove function, movement takes place after y coord handled
	; check right wall
	ld a, [_OAMRAM + 9]	; x coord opponent
	cp a, 100
	jp nc, MoveRightOff
	jp CheckLeftWall

MoveRightOff:
	ld a, 0
	ld [MoveRight], a

CheckLeftWall:
	ld a, [_OAMRAM + 9]	; x coord opponent
	cp a, 15
	jp nc, BeginMovement
	; if c is set, a is less than 5, so moveRight flag must be set to 1
	ld a, 1
	ld [MoveRight], a
	
	
BeginMovement:
	
	ld a, [_OAMRAM + 8]     ;y coord of opponent
	inc a
	ld [_OAMRAM + 8], a	; move opponent down

	; do x movement based on flag
	ld a, [MoveRight]
	cp a, 1
	jp nz, LeftMovement
	; a was 1, so we move right
	ld a, [_OAMRAM + 9]	; x coord opponent
	add a, 10
	ld [_OAMRAM + 9], a

LeftMovement:

	ld a, [_OAMRAM + 9]	; x coord opponent
	sub a, 10
	ld [_OAMRAM + 9], a

	
ReadyMove:
	ld a, [MoveRight]
	cp a, 1
	jp nz, MoveLeft
	ld a, [_OAMRAM + 8]	; y pos of opponent is in a
	inc a
	ld [_OAMRAM + 8], a

	ld a, [_OAMRAM + 9]	; x pos of opponent is in a
	; check if opponent has hit wall
	cp a, 108
	jp nc, MoveLeft
	add a, 5
	ld [_OAMRAM + 9], a



MoveLeft:
	ld a, 0
	ld [MoveRight], a
	
	
	ld a, [_OAMRAM + 9]	; x pos of opponent is in a
	cp a, 10
	ld a, 1
	ld [MoveRight], a
	ret
	
	; copy data from one memory location to another
	; de: Source
	; hl: Destination
	; bc: Length
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

Ball:
    dw `33333333
    dw `33333333
    dw `33333333
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
BallEnd:


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

SECTION "Input Variables", WRAM0
CurKeys: db
NewKeys: db
BallCaught: db
PlayerBallThrown: db
ReadyToThrow: db
MoveRight: db
