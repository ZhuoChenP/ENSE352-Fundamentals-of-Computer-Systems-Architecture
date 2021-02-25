#pragma once
template <typename T>
T shuffle_words(T x, T y) {
	int w = sizeof(T) << 3;

	T y_shift = (((y >> 8) << 16) >> 8);//get the middle part of result with possible msb is 1
	T find_middle = 0xFF;//make a mask for rightest 8 bits are 1 
	find_middle = find_middle << w - 8;//shift all 1 to leftest 8 bits
	find_middle = ~find_middle;//reverse all 1 to 0, and zero to one, make only left 8 bits are 0, remaining is one
	T middle = find_middle & y_shift;// get the value of only the middle part, with msb and lsb are 0



	T x_MSB = (x >> w - 8)<< w - 8;//get the value of only msb
	T x_LSB = x & 0xFF;//get the value of only lsb


	T result = x_MSB | middle | x_LSB;//combine msb, middle and lsb for the final result
	return result;
}
