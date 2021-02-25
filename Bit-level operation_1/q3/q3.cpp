#include"q3.h"


unsigned rotate_left(unsigned x, int n)
{
	int w = sizeof(x)<<3;
	return (x << n) | (x >> w - n);//return the value of conbine the x right shift n units with x left shift w-n units. becasue input x is unsigned number
									// so all right shit value should be 0.
}