Dodgeball on the Gameboy Classic DMG-01

Created for GBRetroDev '25: Heroes of Assembly 2

An Assembly language game jam hosted by the University of Alicante.

This was made using Rednex Game Boy Development System. https://github.com/gbdev/rgbds

To build this locally:

git clone https://github.com/uzougochukwu/dodgeball

cd dodgeball

rgbasm -o dodgeball.o dodgeball.asm

rgblink -o dodgeball.gb dodgeball.o

rgbfix -v -p 0xFF dodgeball.gb

Run an emulator (either Emulicious https://emulicious.net/, or BGB https://bgb.bircd.org/) to play this dodgeball game on your computer.