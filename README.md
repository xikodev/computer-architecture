# Computer Architecture

Faculty of Electrical Engineering and Computing

---

## Lab 1

In memory at address `0x700`, there is a data array where each data item is a structure consisting
of three 32-bit numbers. At the beginning of the structure, there is a 32-bit number that specifies
an arithmetic operation, as follows:

- 0 - addition
- 1 - subtraction
- 2 - multiplication
- 3 - division

Following the arithmetic operation code, there are two 32-bit numbers stored in 2’s complement
format. The number of data entries in the block is not predefined, but it is known that it is terminated
by the data entry `0x8080 8080` at the operation position within the structure. An example of part of
the memory is shown in Table 1.

### Table 1: Memory Representation

|#|Address  |Description|Data     |
|-|---------|-----------|---------|
|1|0000 0700|Operation  |0000 0003|
| |0000 0704|1st operand|FFFF FEFF|
| |0000 0708|2nd operand|0000 0010|
|2|0000 070C|Operation  |0000 0001|
| |0000 0710|1st operand|0000 01F4|
| |0000 0714|2nd operand|FFFF FD44|
|3|0000 0718|Operation  |0000 0002|
| |0000 071C|1st operand|FFFF FFFE|
| |0000 0720|2nd operand|0000 000A|
|4|0000 0724|Operation  |0000 0003|
| |0000 0728|1st operand|FFFF F000|
| |0000 072C|2nd operand|FFFF FFC0|
|X|         |           |8080 8080|

Write a program for the ARM processor that processes all data in the block by performing the
arithmetic operation specified at the beginning of each structure on the two data values in the
structure. After performing the operation, the program stores the 32-bit 2’s complement result
in memory starting at address `0x2000`. The resultant block should be terminated with the entry
`0xFFFF FFFF`. You can assume that the result of the operation will never match the value used to
terminate the resultant block. An example of the resultant block for the data from Table 1 is shown
in Table 2.
For subtraction and division operations that are not commutative, the 1st operand represents
the minuend or dividend, and the 2nd operand represents the subtrahend or divisor.

### Table 2: Resultant Memory Block

|Address  |Result   |
|---------|---------|
|0000 2000|FFFF FFF0|
|0000 2004|0000 04B0|
|0000 2008|FFFF FFEC|
|0000 200C|0000 0040|
|0000 2010|FFFF FFFF|

Write a subroutine `DIVIDE` that performs integer division of two numbers using the method of
successive subtraction. The subroutine receives parameters via the stack and returns the result
in register `R0`. Use the `DIVIDE` subroutine in the main program solution for the division operation
of two data values in the structure. In case of division by zero, the subroutine returns `0`. The
multiplication operation can be implemented using mnemonics available for the ARM processor.
The multiplication and division operations must preserve the sign of the data (e.g., multiplying a
positive and a negative number results in a negative number). You can assume that all operations
will yield a valid result within 32 bits.

[Problem solution](lab01.s)

---

## Lab 2

In the computer system, there is an ARM processor, the GPIO1 module at address 0xFFFF0F00,
the GPIO2 module at address 0xFFFF0B00, and the RTC module at address 0xFFFF0E00. On
port A of the GPIO2 module, LED diodes and a button are connected as follows:

- bit 0 - button
- bit 5 - red
- bit 6 - yellow
- bit 7 - green

To port B of the GPIO1 module, an LCD display described in the lectures is connected. The task
is to implement the functionality of a simple coffee machine using this system. The machine can
only make coffee with milk according to the cycles whose states are defined in Table 1.

### Table 1:  Overview of Possible States

| State | Description                  | Red | Yellow | Green | LCD Output |
|-------|------------------------------|-----|--------|-------|------------|
| 1     | Machine ready for operation  | 0   | 0      | 0     | WELCOME    |
| 2     | Heating the machine          | 1   | 0      | 0     | HEATING    |
| 3     | Pouring coffee               | 0   | 1      | 0     | COFFEE     |
| 4     | Pouring milk                 | 0   | 0      | 1     | MILK       |
| 5     | Coffee is done               | 1   | 1      | 1     | DONE       |


The initial state of the machine is state 1. The cycle (state 2 - state 5) is started by pressing
the button within the simulation. When the cycle ends, the machine should return to state 1 and
wait for the button to be pressed again. States 2, 3, 4, and 5 each have an equal duration of exactly
10 seconds, during which the LED diodes specified in Table 1 are lit. The cycle duration must be
measured using the RTC module, which operates in interrupt mode and is connected to the IRQ
pin. The input to the RTC module is connected to a pulse generator with a frequency of 265 Hz.
The output describing each state should be implemented with separate subroutines, where
each subroutine for displaying a character on the LCD uses the LCDWR subroutine explained in
the lectures.

[Problem solution](lab02.s)

---

## Lab 3

In the computer system, there is a FRISC-V processor along with the GPIO 1 module at address
0xFFFF 0F00 and the GPIO 2 module at address 0xFFFF 0B00, as shown in the lectures. On
port A of the GPIO 2 module, a switch and a button are connected as follows:

- bit 0 - button
- bit 1 - switch

An LCD display is connected to port B of the GPIO 1 module in the configuration shown during the
lectures. For this system, it is necessary to write a program that counts button presses while
the switch is closed. When the switch is open, button presses are ignored. The counter value
must be displayed on the LCD every time it changes. When the switch is opened, the display does
not change because the counter value remains the same. At the start of the program, it is not
necessary to display the value 0. The maximum counter value is twelve, after which the counting
restarts with the next button press, meaning the next displayed value will be 1.
Digit extraction for displaying numbers on the LCD should be implemented using the subroutine
process. The subroutine receives the counter value via register x17 and returns the ASCII-codes
of the digits for display via registers x10 (tens) and x11 (units). For displaying numbers on the LCD,
you may use the example from the lectures, but be mindful of the registers being used.
Note: Numbers with a single digit should be displayed as such on the LCD. For example, the
number 1 should appear as "1" and not "01".


[Problem solution](lab03.s)
