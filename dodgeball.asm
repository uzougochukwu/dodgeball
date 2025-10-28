



	INCLUDE "hardware.inc"	; hardware constants

SECTION "Header", ROM0[$100]

	jp EntryPoint		; jump to EntryPoint

	ds $150 - @, 0		; Create space for the header
	

EntryPoint:

WaitForvBlank:
	; wait until vBlank
	ld a, [rLY] 		; move the value of the Y coordinate of the vertical scanline into the accumulator
	cp 144			; 44 - 153 is the vBlank period
	jp c, WaitForvBlank	; cp automatically compares the accumulator value with 144, by subtracting 144 from a. if carry, it means that a - 144 was negative and set the carry bit, which means a was less than 144, so we go back to the start of the loop. if the carry bit is not set, then a is greater than or equal to 144, so we are in vBlank



End:
	jp End
