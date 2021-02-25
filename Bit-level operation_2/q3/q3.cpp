#include"q3.h"

int mul3div4(int x) {

	int w = sizeof(x) << 3;//find input size
	int mask_one_w = ~0x0;//get only one w size of bits
	int input_mul_3 = ((x << 1) + x)& mask_one_w;//x*2^1+x=>3*x;with only one input type size of bits
	int output;



	int mask_negative = (input_mul_3 + ((1 << 2) - 1) >> 2);
	int mask_positive = (input_mul_3 >> 2);
	int mask_find_sign = 0x1;
	int sign = (input_mul_3 >> w - 1)& mask_find_sign;//when input is negative sign=1; when it is positive sign=0;

	output = (((sign << w - 1) >> w - 1)& mask_negative)//including sign bit, find the total bits of the unsigned number
		+ ((((!sign) << w - 1) >> w - 1)& mask_positive);


	return output;
}


