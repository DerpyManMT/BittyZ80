CPU Z80
ORG $0000



PORT_VDP:    	EQU 0x0020
VDP_RAM:		EQU PORT_VDP+1
VDP_REG:		EQU PORT_VDP+2
USART_DATA:	    EQU 0x0000
USART_CS:   	EQU 0x0001
SOUND: 			EQU 0x0040


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

CHAR_DISP_LOOP:
	CALL RXROUTINE
	SUB A, $20 ; offset from ascii to char base
	INC HL
	CALL VDP_WRITEADDR
	CAll TXROUTINE
	JP CHAR_DISP_LOOP


RXROUTINE:
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x02
        JR Z, .loopPoint
        IN A, (USART_DATA) ; Brings in Data from USART to the CPU
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





