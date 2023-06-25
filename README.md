# NeoGen
A repository so I can store stuff here from my NeoGen line of homebrew projects that people can also use.
I'm new to posting stuff on Github so pardon me if my stuff and layout is sloppy.
This project is made specifically for my particular system, but feel free to adapt the code to your use!
This is a Z80-based system with:
32kB of SRAM
32kB of EEPROM
A TMS9918 Video chip with an SRAM hack that has 16kB of VRAM available.
An Z80 Z8420A PIO IC.
An SN76489 Sound Generator.
An Intel 8251 USART running at 9600 Baud.
And A CF Port with an IDE Pinout.

I/O Space is as follows:
$00 - USART (DATA is $00, CommandStatus-CS is $01)
$20 - VDP (VRAM is $21, and VDP Register is $22)
$40 - SOUND
$60 - PIO (DataPortA-$60, CmdPortA-$61, DataPortB-$62, CmdPortB-$63)
$80 - I/O PORT 4 (On expansion connector)
$E0 - PATA IDE FOR COMPACT FLASH

Stay tuned for more updates I suppose
