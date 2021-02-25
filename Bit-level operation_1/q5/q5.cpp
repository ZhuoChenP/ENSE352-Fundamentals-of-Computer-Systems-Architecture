#include"q5.h"

int16_t saturating_add(int16_t x, int16_t y)
{

	int16_t sum = x + y;
	int16_t w =( sizeof(int16_t)<<3) - 1;
	int16_t sum_mask_msb,x_mask_msb, y_mask_msb;
	sum_mask_msb = sum >> w;
	x_mask_msb = x >> w;
	y_mask_msb = y >> w;


	int16_t  noflow_mask,positive_mask, negative_mask;


	positive_mask = ~x_mask_msb & ~y_mask_msb & sum_mask_msb;//determin sum is positive follow addition mask with only having positive flow
	negative_mask= x_mask_msb & y_mask_msb & ~sum_mask_msb;//determin sum is negative follow addition mask with only having negative flow

	noflow_mask = positive_mask | negative_mask;//find no_flow mask
	int16_t value;

	value = ((~noflow_mask & sum) | (positive_mask & INT_MAX) | (negative_mask & INT_MIN));//combine the result with only one situation. either noflow, positive flow or negative flow

	return value;
}

