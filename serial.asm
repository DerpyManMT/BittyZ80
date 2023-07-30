CPU Z80
ORG $0000

    LD SP, 0x0000
    LD A, $4E
    OUT (USART_CS), A
    LD A, 0x05
    OUT (USART_CS), A
    LD A, 0x15
    OUT (USART_CS), A


MainLoop:
    ;CALL RXROUTINE


    LD A, $41
    CALL TXROUTINE
 


    JP MainLoop


TXROUTINE:
    PUSH AF
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x01
        JR Z, .LoopPoint
        POP AF
        OUT (USART_DATA), A
        RET

RXROUTINE:
    .LoopPoint:
        IN A, (USART_CS)
        AND 0x02
        JR Z, .loopPoint
        IN A, (USART_DATA)
        RET


;WAIT_FOR_ONE:
 ;LD A, (USART_CS)
 ;AND 0x02   		;compare bits to check if recieved
 ;JR Z, WAIT_FOR_ONE
 ;RET
 

USART_DATA: EQU 0x0000
USART_CS:   EQU 0x0001

