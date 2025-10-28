



	INCLUDE "hardware.inc"	; hardware constants

SECTION "Header", ROM0[$100]

	jp EntryPoint		; jump to EntryPoint

	ds $150 - @, 0		; Create space for the header
	

EntryPoint:

WaitForvBlank:
	; wait until vBlank, then draw player controlled character	
	ld a, [rLY]		; move the value of the Y coordinate of the vertical scanline into the accumulator
	cp a, 144		; 144 - 153 is the vBlank period
	jp z, Main			; if zero flag set, accumulator equals 144, so we jump to main and now we can do all of our work in the vBlank period

Main:
	



End:
	jp End
