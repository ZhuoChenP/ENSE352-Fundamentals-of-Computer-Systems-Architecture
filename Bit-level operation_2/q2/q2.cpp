#include"q2.h"
int divide_power2(int x, int k)
{
	int w = sizeof(x) << 3;//find input size
	int mask_negative = (x + ((1 << k) - 1) >> k);
	int mask_positive = (x >> k);
	int mask_find_sign = 0x1;
	int sign = (x >> w - 1)&mask_find_sign;//when input is negative sign=1; when it is positive sign=0;

	int return_value=(((sign << w-1) >> w-1)& mask_negative)//including sign bit, find the total bits of the unsigned number
		              + ((((!sign) << w-1) >> w-1)& mask_positive);

	return return_value;
}