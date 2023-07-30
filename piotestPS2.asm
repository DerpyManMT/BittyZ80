 CPU Z80
ORG $0000


USART_DATA:	  EQU 0x0000
USART_CS:     EQU 0x0001
PIODATAa:     EQU $60
PIOCOMMANDa:  EQU $61
PIODATAb:     EQU $62
PIOCOMMANDb:  EQU $63

START:
	LD	SP, 0x0000
	
	
					; Memory is from 0x8000 to 0xFFFF
					; This will wrap around on the first push
					; to 0xFFFF
	
	LD A, $4E		;Set up the USART 8 bit character, x16 Baud Rate, No Parity, 1 stop bit
    OUT (USART_CS), A
    LD A, 0x05			;setup Tx and Rx
    OUT (USART_CS), A
    LD A, 0x15			;Idk
    OUT (USART_CS), A
    LD A, 11001111b
    OUT (PIOCOMMANDa), A
    LD A, 00000000b
    OUT (PIOCOMMANDa), A
    LD A, 11111111b
    OUT (PIODATAa), A
    LD A, 11001111b ; Set to mode 1 on port B
    OUT (PIOCOMMANDb), A
    LD A, 11000000b ; Set I/O on port B
    OUT (PIOCOMMANDb), A
    LD A, $1F ; set lines low
    OUT (PIODATAb), A
    LD BC, 100h
OUTER:
    LD DE, 100h

INNER:
    DEC DE
    LD A, D
    OR E
    JP NZ, INNER
    DEC BC
    LD A, B
    OR C
    JP NZ, OUTER



    LD A, $3F ; Set the lines high
    OUT (PIODATAb), A
 ;   LD E, 0x00

;StartByte:
    ;LD A, E

Init:
    LD DE, $0000  ;Use DE as our message in progress
    LD B, 11  ;Bit count in B
ReadBit:
    IN A, (PIODATAb) ;Read status
    BIT 7, A ;Test if new bit available
    JR NZ, ReadBit ;If not, loop back and try again
    IN A, (PIODATAb) ;Read bit of message
BitShift:
    SRL D
    RR E
    BIT 6, A ;Test message bit from port data
    JR Z, BitZero ;If zero, skip
    SET 7, D ;Else, set lowest bit of message byte
BitZero:
    IN A, (PIODATAb) ;Read status again
    BIT 7, A  ;Test clock line
    JR Z, BitZero ;If still down, wait again until it goes back up
    DJNZ ReadBit  ;Decrement bit counter and loop if nonzero
Send:
 
    RL E
    RL D
    RL E
    RL D
    LD A, D
    CALL TXROUTINE
    JP Init

TXROUTINE:
    PUSH AF
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x01
        JR Z, .LoopPoint
        POP AF
        OUT (USART_DATA), A ; Sends out data from CPU to the USART
        RET	


;HALTLOOP:

;JP HALTLOOP