section 0x0
word 0x1f4
word 0x50
word 0x7a

section 0x20
word 0x80000000
//0x22, 0x23, 0x24 Reserved for AXI IIC values

//Reset ISR//
//Terrible implementation
section 0x50
ori $p_state $p_state 0x01 //re-enable GIE
movi $r2 0xfb
Keep_Checking_Status:
no-op
movi $r0 0x0104 //Status Register (BB)
jump_l AXI_READ
ori $r0 $r0 0xfb
bneq $r0 $r2 Keep_Checking_Status

sw 34($zero) $zero

movi $r0 0x40 //Soft Reset Register
movi $r1 0xa
jump_l AXI_WRITE

movi $r0 0x1c
lw 32($zero) $r1
jump_l AXI_WRITE

movi $r0 0x28
movi $r1 0x02
jump_l AXI_WRITE

movi $r0 0x20
movi $r1 0x0
jump_l AXI_WRITE

movi $r0 0x120
movi $r1 0x02
jump_l AXI_WRITE

movi $r0 0x100
movi $r1 0x02
jump_l AXI_WRITE

movi $r0 0x100
movi $r1 0x01
jump_l AXI_WRITE
iret

//I2C ISR//
//***************************//
section 0x7a
//ori $p_state $p_state 0x01 //Don't enable GIE else, reset handler can stop transmission

movi $r0 0x028
jump_l AXI_READ

//I2C Data Read (Upper Bits)
movi $r0 0x10c
jump_l AXI_READ

//Upper Bits
mov $r1 $r0
btsli $r1 $r1 8

//I2C Data Read (Lower Bits)
movi $r0 0x10c
jump_l AXI_READ

//Combine Upper and Lower Bits
add $r0 $r1 $r0

sw 33($zero) $r0 //Store the I2C data

movi $r0 0x020
jump_l AXI_READ

andi $r0 $r5 0x0a
movi $r6 0x08

bneq $r5 $r6 Restart

movi $r0 0x20
movi $r1 0x08
jump_l AXI_WRITE
jump endif

Restart:
no-op
movi $r0 0x20
movi $r1 0x02
jump_l AXI_WRITE

jump_l Start_Transmission
endif:
ori $p_state $p_state 0x01 //Renable GIE only after Clearing I2C interrupt
iret
//***************************//

section 0x0f0
Start_Transmission:
mov $temp $lr

movi $r0 0x108
movi $r1 0x168
jump_l AXI_WRITE

movi $r0 0x108
movi $r1 0x05
jump_l AXI_WRITE

movi $r0 0x108
movi $r1 0x169
jump_l AXI_WRITE

movi $r0 0x108
movi $r1 0x202
jump_l AXI_WRITE

mov $pc $temp


section 0x100
AXI_READ:
sw 35($zero) $r0
movi $r3 0x08
sw 34($zero) $r3
//movi $r5 0x08

//Label_Read_Int:
//no-op
//lw 576($zero) $r4
//bneq $r4 $r5 Label_Read_Int

lw 34($zero) $r5
andi $r5 $r5 0xfff7
ori $r5 $r5 0x10
sw 34($zero) $r5

//movi $r5 0x10

//Wait_B_Valid_Read_Int:
//no-op
//lw 576($zero) $r4
//bneq $r4 $r5 Wait_B_Valid_Read_Int

lw 34($zero) $r5
andi $r5 $r5 0xffef
sw 34($zero) $r5


//Return
lw 577($zero) $r0
mov $pc $lr

AXI_WRITE:
sw 36($zero) $r1
sw 35($zero) $r0
movi $r3 0x03
sw 34($zero) $r3
//movi $r5 0x03
//Label_Write_Restart_0:
//no-op
//lw 576($zero) $r4 //4 cycles :(
//Too slow
//Maybe introduce hardware to slow down
//bneq $r4 $r5 Label_Write_Restart_0

lw 34($zero) $r5
andi $r5 $r5 0xfffc
ori $r5 $r5 0x04
sw 34($zero) $r5

//movi $r5 0x04

//Wait_B_Valid_Write_Restart_0:
//no-op
//lw 576($zero) $r4
//bneq $r4 $r5 Wait_B_Valid_Write_Restart_0

lw 34($zero) $r5
andi $r5 $r5 0xfffb
sw 34($zero) $r5

mov $pc $lr


section 0x130:
Setup:
int 0x01  //Reset Interrupt


jump_l Start_Transmission


Loop:
jump Loop