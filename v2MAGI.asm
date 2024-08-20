CPU Z80
ORG $0000


PORT_VDP:    	EQU 0x0020
VDP_RAM:		EQU PORT_VDP+1
VDP_REG:		EQU PORT_VDP+2
USART_DATA:	    EQU 0x0000
USART_CS:   	EQU 0x0001
SOUND: 			EQU 0x0040
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

    LD A, $CF
    OUT (PIOCOMMANDa), A
    LD A, $00
    OUT (PIOCOMMANDa), A
    LD A, $FF
    OUT (PIODATAa), A
    LD A, $CF ; Set to mode 1 on port B
    OUT (PIOCOMMANDb), A
    LD A, $C0 ; Set I/O on port B
    OUT (PIOCOMMANDb), A



	

    LD A, $3F ; Set the lines high

    OUT (PIODATAb), A
	SOUND_INIT:
	

	LD A, $8F
	CALL SOUND_LOOP

	LD A, $01
	CALL SOUND_LOOP

	LD A, $AF
	CALL SOUND_LOOP

	LD A, $01
	CALL SOUND_LOOP

	LD A, $9F
	CALL SOUND_LOOP

	LD A, $81
	CALL SOUND_LOOP

	LD A, $B5
	CALL SOUND_LOOP

	LD A, $9F
	CALL SOUND_LOOP

	LD A, $BF
	CALL SOUND_LOOP

	LD A, $DF
	CALL SOUND_LOOP

	LD A, $FF
	CALL SOUND_LOOP

	LD	B, 0		
	LD	A, 0x00		; Text mode, no ext
	CALL	VDP_WRITEREG
	
	LD	B, 1		
	LD	A, 0xD0		; 16k, enable display, disable int
	CALL	VDP_WRITEREG
	
	LD	B, 2		
	LD	A, 0x02		; Name table = 0x0800
	CALL	VDP_WRITEREG
	
	LD	B, 3		
	LD	A, 0x00		; Unused colour table
	CALL	VDP_WRITEREG
	
	LD	B, 4		
	LD	A, 0x00		; Addr of pattern table = 0x0000
	CALL	VDP_WRITEREG
	
	LD	B, 5		
	LD	A, 0x20		; Addr of unused sprite attr table = 0x1000
	CALL	VDP_WRITEREG
	
	LD	B, 6		
	LD	A, 0x00		; Addr of unused sprite pattern tbl = 0x0000
	CALL	VDP_WRITEREG
	
	LD	B, 7		
	LD	A, 0x31		; COLOR
	CALL	VDP_WRITEREG
	
	; Clear VDP memory
	LD	HL, 0x0000
	LD	A, 0x00
	CALL	VDP_WRITEADDR
	LD	BC, 0xFF40	; 16kB loop here - 1

CLRLOOP:
	CALL	VDP_WRITENEXT
	DJNZ	CLRLOOP
	DEC	C
	JR	NZ, CLRLOOP
	
	; Start writing to pattern table offset 0
	LD	HL, 0x0000	; Pattern table base
	LD	A, 0x00		; Assume first byte is 0 to be lazy
	CALL	VDP_WRITEADDR	; Start writing to pattern table offset 0
	LD	HL, FONT_HEAD+1 
	; Copy the 96 * 8 -1 bytes from the font to the pattern table
	LD	C, 3		; 8 * 96 bytes = 3 * 256 
	LD	B, 255		; -1 since we wrote the first byte early

FONTLOOP:
	LD	A, (HL)
	CALL	VDP_WRITENEXT
	INC	HL
	DJNZ	FONTLOOP  	; Loop 256 times
	DEC	C
	JR	NZ, FONTLOOP


CHAR_DISP:
LD HL, 0x0801 	;set screen spot and NAME table base
CALL VDP_WRITEADDR

GETSCANCODE:
	CALL Init
	CP A, $F0
	JR Z, KEYUP
	

KEYDOWN:
	
	CALL SCANCODETOASCII
	RET

KEYUP:
	CALL Init
	JP GETSCANCODE




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
SCANCODEIN:
 
    RL E
    RL D
    RL E
    RL D
    LD A, D
Ret






SCANCODETOASCII:
	PUSH HL
	LD HL, SCANCODE_TABLE ;Pointer to start of scancode>ASCII translation table
    LD E, A ;ScanCode ;Scancode to use as an offset
    LD D, 0    ;Upper byte zero
    ADD HL, DE ;Add offset to base
    LD A, (HL)  ;Get translated value
	POP HL
	CP A, $08
	JR Z, .BACKSPACE
	SUB A, $20
	CALL VDP_WRITEADDR
	INC HL

   
    JP GETSCANCODE

	.Enter:
		
		

	.BACKSPACE:
		LD A, $00
		DEC HL
		CALL VDP_WRITEADDR
		LD A, $00
		CALL VDP_WRITEADDR
		JP GETSCANCODE



RXROUTINE:
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x02
        JR Z, .loopPoint
        IN A, (USART_DATA) ; Brings in Data from USART to the CPU
        RET

SOUND_LOOP:
    NOP
    NOP
    NOP
    OUT (SOUND), A
    RET

TXROUTINE:
    PUSH AF
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x01
        JR Z, .LoopPoint
        POP AF
        OUT (USART_DATA), A ; Sends out data from CPU to the USART
        RET	



;Cursor timer, set for one second

OUTERCURSOR:
    LD DE, 1000h

INNERCURSOR:
    DEC DE
    LD A, D
    OR E
    JP NZ, INNERCURSOR
    DEC BC
    LD A, B
    OR C
    JP NZ, OUTERCURSOR
	RET





	
; Data in A, reg (low 3 bits) in B
VDP_WRITEREG:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	OUT	(VDP_REG), A		; Write data bits
	LD	A, B
	OR	$80			; Set high bit
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	OUT	(VDP_REG), A		; Write address
	RET
	

; Read VDP status register (into A)
VDP_READSTAT:
	IN	A, (VDP_REG)
	RET
	

; This is what is mainly used to put data onto the screen or memory in general within VRAM
; Change addr to HL (14-bit) then write A
VDP_WRITEADDR:
	PUSH	AF
	LD	A, L
	OUT	(VDP_REG), A		; Output low byte of address
	LD	A, H
	AND	$7F			; Set bit 7 low
	OR	$40			; Set bit 6 high
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	OUT	(VDP_REG), A		; Output high byte (6-bits) of address
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	POP	AF
	OUT	(VDP_RAM), A		; Write first byte
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET

VDP_WRITENEXT:
	OUT	(VDP_RAM), A
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET

; Change addr to HL (14-bit) then read into A
VDP_READADDR:
	LD	A, L
	OUT	(VDP_REG), A		; Output low byte of address
	LD	A, H
	AND	$3F			; Set bit 7 and 6 low
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	OUT	(VDP_REG), A		; Output high byte (6-bits) of address
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	IN	A, (VDP_RAM)		; Read first byte
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET


VDP_READNEXT:
	IN	A, (VDP_RAM)
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET


SCANCODE_TABLE:
DB $00 ; 00
DB $00 ; 01
DB $00 ; 02
DB $00 ; 03
DB $00 ; 04
DB $00 ; 05
DB $00 ; 06
DB $00 ; 07
DB $00 ; 08
DB $00 ; 09
DB $00 ; 0A
DB $00 ; 0B
DB $00 ; 0C
DB $00 ; 0D
DB '`' ; 0E
DB $00 ; 0F
DB $00 ; 10
DB $00 ; 11
DB $00 ; 12 
DB $00 ; 13
DB $00 ; 14
DB 'Q' ; 15
DB '1' ; 16
DB $00 ; 17
DB $00 ; 18
DB $00 ; 19
DB 'Z' ; 1A
DB 'S' ; 1B
DB 'A' ; 1C
DB 'W' ; 1D
DB '2' ; 1E
DB $00 ; 1F
DB $00 ; 20
DB 'C' ; 21
DB 'X' ; 22
DB 'D' ; 23
DB 'E' ; 24
DB '4' ; 25
DB '3' ; 26
DB $00 ; 27
DB $00 ; 28
DB ' ' ; 29
DB 'V' ; 2A
DB 'F' ; 2B
DB 'T' ; 2C
DB 'R' ; 2D
DB '5' ; 2E
DB $00 ; 2F
DB $00 ; 30
DB 'N' ; 31
DB 'B' ; 32
DB 'H' ; 33
DB 'G' ; 34
DB 'Y' ; 35
DB '6' ; 36
DB $00 ; 37
DB $00 ; 38
DB $00 ; 39
DB 'M' ; 3A
DB 'J' ; 3B
DB 'U' ; 3C
DB '7' ; 3D
DB '8' ; 3E
DB $00 ; 3F
DB $00 ; 40
DB ',' ; 41
DB 'K' ; 42
DB 'I' ; 43
DB 'O' ; 44
DB '0' ; 45
DB '9' ; 46
DB $00 ; 47
DB $00 ; 48
DB '.' ; 49
DB '/' ; 4A
DB 'L' ; 4B
DB ';' ; 4C
DB 'P' ; 4D
DB '-' ; 4E
DB $00 ; 4F
DB $00 ; 50
DB $00 ; 51
DB "'" ; 52
DB $00 ; 53
DB '[' ; 54
DB '=' ; 55
DB $00 ; 56
DB $00 ; 57
DB $00 ; 58
DB $00 ; 59
DB $0A ; 5A
DB ']' ; 5B
DB $00 ; 5C
DB $5C ; 5D
DB $00 ; 5E
DB $00 ; 5F
DB $00 ; 60
DB $00 ; 61
DB $00 ; 62
DB $00 ; 63
DB $00 ; 64
DB $00 ; 65
DB $08 ; 66
DB $00 ; 67
DB $00 ; 68
DB '1' ; 69
DB $00 ; 6A
DB '4' ; 6B
DB '7' ; 6C
DB $00 ; 6D
DB $00 ; 6E
DB $00 ; 6F
DB '0' ; 70
DB '.' ; 71
DB '2' ; 72
DB '5' ; 73
DB '6' ; 74
DB '8' ; 75
DB $00 ; 76
DB $00 ; 77
DB $00 ; 78
DB '+' ; 79
DB '3' ; 7A 
DB '-' ; 7B
DB '*' ; 7C
DB '9' ; 7D
DB $00 ; 7E
DB $00 ; 7F 
DB $00 ; 80
DB $00 ; 81
DB $00 ; 82
DB $00 ; 83




;Character table



FONT_HEAD: 
db $00, $00, $00, $00, $00, $00, $00, $00; U+0020 (space) (offset $00)
db $18, $3c, $3c, $18, $18, $00, $18, $00; U+0021 (!) (offset $01)
db $6c, $6c, $00, $00, $00, $00, $00, $00; U+0022 (") (offset $02)
db $6c, $6c, $fe, $6c, $fe, $6c, $6c, $00; U+0023 (#) (offset $03)
db $30, $7c, $c0, $78, $0c, $f8, $30, $00; U+0024 ($) (offset $04)
db $00, $c6, $cc, $18, $30, $66, $c6, $00; U+0025 (%) (offset $05)
db $38, $6c, $38, $76, $dc, $cc, $76, $00; U+0026 (&) (offset $06)
db $60, $60, $c0, $00, $00, $00, $00, $00; U+0027 (') (offset $07)
db $18, $30, $60, $60, $60, $30, $18, $00; U+0028 (() (offset $08)
db $60, $30, $18, $18, $18, $30, $60, $00; U+0029 ()) (offset $09)
db $00, $66, $3c, $ff, $3c, $66, $00, $00; U+002A (*) (offset $0a)
db $00, $30, $30, $fc, $30, $30, $00, $00; U+002B (+) (offset $0b)
db $00, $00, $00, $00, $00, $30, $30, $60; U+002C (,) (offset $0c)
db $00, $00, $00, $fc, $00, $00, $00, $00; U+002D (-) (offset $0d)
db $00, $00, $00, $00, $00, $30, $30, $00; U+002E (.) (offset $0e)
db $06, $0c, $18, $30, $60, $c0, $80, $00; U+002F (/) (offset $0f)
db $7c, $c6, $ce, $de, $f6, $e6, $7c, $00; U+0030 (0) (offset $10)
db $30, $70, $30, $30, $30, $30, $fc, $00; U+0031 (1) (offset $11)
db $78, $cc, $0c, $38, $60, $cc, $fc, $00; U+0032 (2) (offset $12)
db $78, $cc, $0c, $38, $0c, $cc, $78, $00; U+0033 (3) (offset $13)
db $1c, $3c, $6c, $cc, $fe, $0c, $1e, $00; U+0034 (4) (offset $14)
db $fc, $c0, $f8, $0c, $0c, $cc, $78, $00; U+0035 (5) (offset $15)
db $38, $60, $c0, $f8, $cc, $cc, $78, $00; U+0036 (6) (offset $16)
db $fc, $cc, $0c, $18, $30, $30, $30, $00; U+0037 (7) (offset $17)
db $78, $cc, $cc, $78, $cc, $cc, $78, $00; U+0038 (8) (offset $18)
db $78, $cc, $cc, $7c, $0c, $18, $70, $00; U+0039 (9) (offset $19)
db $00, $30, $30, $00, $00, $30, $30, $00; U+003A (:) (offset $1a)
db $00, $30, $30, $00, $00, $30, $30, $60; U+003B (;) (offset $1b)
db $18, $30, $60, $c0, $60, $30, $18, $00; U+003C (<) (offset $1c)
db $00, $00, $fc, $00, $00, $fc, $00, $00; U+003D (=) (offset $1d)
db $60, $30, $18, $0c, $18, $30, $60, $00; U+003E (>) (offset $1e)
db $78, $cc, $0c, $18, $30, $00, $30, $00; U+003F (?) (offset $1f)
db $7c, $c6, $de, $de, $de, $c0, $78, $00; U+0040 (@) (offset $20)
db $30, $78, $cc, $cc, $fc, $cc, $cc, $00; U+0041 (A) (offset $21)
db $fc, $66, $66, $7c, $66, $66, $fc, $00; U+0042 (B) (offset $22)
db $3c, $66, $c0, $c0, $c0, $66, $3c, $00; U+0043 (C) (offset $23)
db $f8, $6c, $66, $66, $66, $6c, $f8, $00; U+0044 (D) (offset $24)
db $fe, $62, $68, $78, $68, $62, $fe, $00; U+0045 (E) (offset $25)
db $fe, $62, $68, $78, $68, $60, $f0, $00; U+0046 (F) (offset $26)
db $3c, $66, $c0, $c0, $ce, $66, $3e, $00; U+0047 (G) (offset $27)
db $cc, $cc, $cc, $fc, $cc, $cc, $cc, $00; U+0048 (H) (offset $28)
db $78, $30, $30, $30, $30, $30, $78, $00; U+0049 (I) (offset $29)
db $1e, $0c, $0c, $0c, $cc, $cc, $78, $00; U+004A (J) (offset $2a)
db $e6, $66, $6c, $78, $6c, $66, $e6, $00; U+004B (K) (offset $2b)
db $f0, $60, $60, $60, $62, $66, $fe, $00; U+004C (L) (offset $2c)
db $c6, $ee, $fe, $fe, $d6, $c6, $c6, $00; U+004D (M) (offset $2d)
db $c6, $e6, $f6, $de, $ce, $c6, $c6, $00; U+004E (N) (offset $2e)
db $38, $6c, $c6, $c6, $c6, $6c, $38, $00; U+004F (O) (offset $2f)
db $fc, $66, $66, $7c, $60, $60, $f0, $00; U+0050 (P) (offset $30)
db $78, $cc, $cc, $cc, $dc, $78, $1c, $00; U+0051 (Q) (offset $31)
db $fc, $66, $66, $7c, $6c, $66, $e6, $00; U+0052 (R) (offset $32)
db $78, $cc, $e0, $70, $1c, $cc, $78, $00; U+0053 (S) (offset $33)
db $fc, $b4, $30, $30, $30, $30, $78, $00; U+0054 (T) (offset $34)
db $cc, $cc, $cc, $cc, $cc, $cc, $fc, $00; U+0055 (U) (offset $35)
db $cc, $cc, $cc, $cc, $cc, $78, $30, $00; U+0056 (V) (offset $36)
db $c6, $c6, $c6, $d6, $fe, $ee, $c6, $00; U+0057 (W) (offset $37)
db $c6, $c6, $6c, $38, $38, $6c, $c6, $00; U+0058 (X) (offset $38)
db $cc, $cc, $cc, $78, $30, $30, $78, $00; U+0059 (Y) (offset $39)
db $fe, $c6, $8c, $18, $32, $66, $fe, $00; U+005A (Z) (offset $3a)
db $78, $60, $60, $60, $60, $60, $78, $00; U+005B ([) (offset $3b)
db $c0, $60, $30, $18, $0c, $06, $02, $00; U+005C (\) (offset $3c)
db $78, $18, $18, $18, $18, $18, $78, $00; U+005D (]) (offset $3d)
db $10, $38, $6c, $c6, $00, $00, $00, $00; U+005E (^) (offset $3e)
db $00, $00, $00, $00, $00, $00, $00, $ff; U+005F (_) (offset $3f)
db $30, $30, $18, $00, $00, $00, $00, $00; U+0060 (`) (offset $40)
db $00, $00, $78, $0c, $7c, $cc, $76, $00; U+0061 (a) (offset $41)
db $e0, $60, $60, $7c, $66, $66, $dc, $00; U+0062 (b) (offset $42)
db $00, $00, $78, $cc, $c0, $cc, $78, $00; U+0063 (c) (offset $43)
db $1c, $0c, $0c, $7c, $cc, $cc, $76, $00; U+0064 (d) (offset $44)
db $00, $00, $78, $cc, $fc, $c0, $78, $00; U+0065 (e) (offset $45)
db $38, $6c, $60, $f0, $60, $60, $f0, $00; U+0066 (f) (offset $46)
db $00, $00, $76, $cc, $cc, $7c, $0c, $f8; U+0067 (g) (offset $47)
db $e0, $60, $6c, $76, $66, $66, $e6, $00; U+0068 (h) (offset $48)
db $30, $00, $70, $30, $30, $30, $78, $00; U+0069 (i) (offset $49)
db $0c, $00, $0c, $0c, $0c, $cc, $cc, $78; U+006A (j) (offset $4a)
db $e0, $60, $66, $6c, $78, $6c, $e6, $00; U+006B (k) (offset $4b)
db $70, $30, $30, $30, $30, $30, $78, $00; U+006C (l) (offset $4c)
db $00, $00, $cc, $fe, $fe, $d6, $c6, $00; U+006D (m) (offset $4d)
db $00, $00, $f8, $cc, $cc, $cc, $cc, $00; U+006E (n) (offset $4e)
db $00, $00, $78, $cc, $cc, $cc, $78, $00; U+006F (o) (offset $4f)
db $00, $00, $dc, $66, $66, $7c, $60, $f0; U+0070 (p) (offset $50)
db $00, $00, $76, $cc, $cc, $7c, $0c, $1e; U+0071 (q) (offset $51)
db $00, $00, $dc, $76, $66, $60, $f0, $00; U+0072 (r) (offset $52)
db $10, $30, $7c, $30, $30, $34, $18, $00; U+0074 (t) (offset $54)
db $00, $00, $cc, $cc, $cc, $cc, $76, $00; U+0075 (u) (offset $55)
db $00, $00, $cc, $cc, $cc, $78, $30, $00; U+0076 (v) (offset $56)
db $00, $00, $c6, $d6, $fe, $fe, $6c, $00; U+0077 (w) (offset $57)
db $00, $00, $c6, $6c, $38, $6c, $c6, $00; U+0078 (x) (offset $58)
db $00, $00, $cc, $cc, $cc, $7c, $0c, $f8; U+0079 (y) (offset $59)
db $00, $00, $fc, $98, $30, $64, $fc, $00; U+007A (z) (offset $5a)
db $1c, $30, $30, $e0, $30, $30, $1c, $00; U+007B () (offset $5b)
db $18, $18, $18, $00, $18, $18, $18, $00; U+007C (|) (offset $5c)
db $e0, $30, $30, $1c, $30, $30, $e0, $00; U+007D () (offset $5d)
db $76, $dc, $00, $00, $00, $00, $00, $00; U+007E (~) (offset $5e)

