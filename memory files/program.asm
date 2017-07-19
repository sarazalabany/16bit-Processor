.section .data

.section .text

_start: .global _start

        .global main
int0:   jump  main
        .type int1, @function
int1:   jump  int1sr
        .type int2, @function
int2:   jump  int2sr
        .type int3, @function
int3:   jump  int3sr
        .type int4, @function
int4:   jump  int4sr
        .type int5, @function
int5:   jump  int5sr
        .type int6, @function
int6:   jump  int6sr
        .type int7, @function
int7:   jump  int7sr
        

        
main:   load  spinit   	# initial value for stack pointer
        store $sp     	# store value in stack pointer register
        load  ENVAL		#save ENVAL to IEN
		store $ien
		load  const1
		add   const4
		call mark0
		add const2
		
li :nop
	nop
	jump li
	
mark0:
		load const20
		sub  const2
		ret
		
int1sr: 
        load   const10	#value of 10 will be saved to ACC
		store  VAR1
		store ADDR	    #store to the debugger 
        reti          	# return from interrupt
		
int2sr: 
        load   const20	#value of 20 will be saved to ACC
		store  VAR1
		store ADDR	    #store to the debugger 
        reti          	# return from interrupt
		

int3sr: 

		load   const30	#value of 20 will be saved to ACC
		store  VAR1
		store ADDR	    #store to the debugger 
        reti          	# return from interrupt

int4sr: nop

int5sr: nop

int6sr: nop

int7sr: nop	
		
const0: .word 0x000
const1: .word 0x001
const2: .word 0x002
const3: .word 0x003
const4: .word 0x004
const5: .word 0x005
const6: .word 0x006
const7: .word 0x006
const10: .word 0x00a
const20: .word 0x014
const30: .word 0x01e

VAR1  : .word 0x000



spinit :  .word 0x7FF

ENVAL  :  .word 0x0082
iflmask:  .word 0x0002

.set    ADDR, 0x0FFF << 1	
		.end