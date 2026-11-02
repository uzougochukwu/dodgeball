# Dodgeball on the Gameboy Classic DMG-01

This was made using the Rednex Game Boy Development System. https://github.com/gbdev/rgbds


## How to play

Windows:

**Emulator**

Download Emulicious (https://emulicious.net/downloads/) or BGB (https://bgb.bircd.org/). I find that the 32 bit emulators work on my computer, despite my computer being 64 bits, but your experience may vary.

For Emulicious you can either download the version with Java or the version without Java. If you download the version with Java, make sure that you choose the correct option out of the 64bit or 32bit versions.

For BGB, just click on the download link on the page, choose either the 64 bit version or the version with no description on the number of bits (this is the 32 bit version).

When you have downloaded your emulator of choice, go to your Downloads folder and double click on the Emulicious or BGB zip file (the zip file will have a zip on the logo). 

Then double click on the BGB or Emulicious executable file, it should say 'Application' in the type column. Click extract all.

You now have your emulator. 

**Game file**

Click on the dodgeball.gb file in this repo, then click on the 'Download raw file' button.

Now go to the unzipped emulator folder (the unzipped version won't have a zip on the logo), double click on the Emulicious or BGB executable (it should say 'Application' in the type column). 

We still need to load the game file into the emulator.

**Emulicious**

For Emulicious, go to the top left and click on 'File' then 'Open File'.

Double click on 'Desktop' on the left, then double click on 'Downloads'. 

Then double click on 'dodgeball.gb'.

**BGB**

For BGB, right click on the screen then click 'Load ROM'.

Then double click on 'Desktop', then double click on 'Downloads'.

Then double click on 'dodgeball.gb'.

## Game Instructions

Use the arrows to move the player left, right, up and down.

The A keyboard key is to grab the ball. You need to be exactly in line with the ball on the vertical axis for this to work.

The S keyboard key is to throw the ball.


## To build this locally:

git clone https://github.com/uzougochukwu/dodgeball

cd dodgeball

rgbasm -o dodgeball.o dodgeball.asm

rgblink -o dodgeball.gb dodgeball.o

rgbfix -v -p 0xFF dodgeball.gb

Run an emulator (either Emulicious https://emulicious.net/, or BGB https://bgb.bircd.org/) to play this dodgeball game on your computer.
