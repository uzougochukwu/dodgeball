



	INCLUDE "hardware.inc"	; hardware constants

SECTION "Header", ROM0[$100]

	jp EntryPoint		; jump to EntryPoint

	ds $150 - @, 0		; Create space for the header
	

EntryPoint:

	



End:
	jp End
