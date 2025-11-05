//.equ data_array, 0x700
.equ result_array, 0x2000
.equ terminate, 0x80808080

.global _start
_start:
	LDR R0, =data_array
	LDR R1, =result_array
	LDR R2, =terminate
	
	BAL loop
	
loop:
	// operation
	LDR R3, [R0], #4
	
	// check for termination code 0x80808080
	CMP R3, R2
	BEQ end
	
	// 1st operand
	LDR R4, [R0], #4
	// 2nd operand
	LDR R5, [R0], #4
	
	// addition
	CMP R3, #0
	ADDEQ R6, R4, R5
	
	// subtraction
	CMP R3, #1
	SUBEQ R6, R4, R5
	
	// multiplication
	CMP R3, #2
	MULEQ R6, R4, R5
	
	// division
	CMP R3, #3
	
	// using stack because in subroutine DIVIDE register R4 is changing due to successive subtraction
	PUSH {R4, R5}
	BLEQ divide
	POP {R4, R5}
	
	// store the result in result array
	STR R6, [R1], #4
	MOV R6, #0
	BAL loop
	
divide:
    CMP R4, R5
    BXLO LR
    SUB R4, R4, R5
    ADD R6, R6, #1
    BAL divide
	
end:
	// terminating resultant block with 0xffffffff
	MOV R6, #0xffffffff
	STR R6, [R1]


.data
.org 0x700
data_array:
	.word 0x3, 0xfffffeff, 0x10, 0x1, 0x1f4, 0xfffffd44, 0x2, 0xfffffffe, 0xa, 0x3, 0xfffff000, 0xffffffc0, 0x80808080
