
#include"q2.h"


int a(int x) //Any bit of x equals 0.
{
	int mask = 0x0;
	return !!(~x^mask);
}
int b(int x) // Any bit of x equals 1.
{
	return !!(x);
}
int c(int x) //Any bit in the LSB of x equals 0.
{
	x = ~x;
	int mask = 0xff;
	return !!(x&mask);

}
int d(int x) //Any bit in the MSB of x equals 1.
{
	int w = sizeof(x) << 3;
	x = x >> w - 8;
	int mask = 0xFF;
	return !!(x&mask);
}
