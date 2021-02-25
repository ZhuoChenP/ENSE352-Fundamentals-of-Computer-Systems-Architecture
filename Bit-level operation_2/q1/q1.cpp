#include"q1.h"
#include <stdio.h>
#include <stdint.h>
unsigned f2u(float f)
{
	unsigned result;
	uint8_t* byte_ptr = (uint8_t*)&f;//can access each byte
	uint8_t* result_ptr= (uint8_t*)&result;//declare a new ptr to store each byte(information) from f, in bit_level
	for (int x = 0;x <4;x++) //since it is 32bit_unsigned number, so 32/8=4 times are needed to be excuted.  
	{
		result_ptr[x] = byte_ptr[x];//for loop to store every byte of information from byte_ptr to result_ptr
	}

	unsigned* value = (unsigned*)result_ptr;//declare a return value which is assigned by a casted value from a pointer, result_ptr
	return *value;
}

