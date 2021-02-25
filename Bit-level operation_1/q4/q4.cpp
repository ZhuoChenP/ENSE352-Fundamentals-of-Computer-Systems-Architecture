#include"q4.h"
int64_t minimum_2s_comp_bits(int64_t x){
	
	int64_t find_sign, get_unsigned,get_return,get_msb;

	find_sign = (!((!!x) & (x >> 63)));

	get_unsigned = (((find_sign << 63) >> 63)& (x)<<1)//including sign bit, find the total bits of the unsigned number
			+((((!find_sign) << 63) >> 63)& (~x +1));
	get_unsigned = get_unsigned | (get_unsigned >> 1);
	get_unsigned = get_unsigned | (get_unsigned >> 2);
	get_unsigned = get_unsigned | (get_unsigned >> 4);
	get_unsigned = get_unsigned | (get_unsigned >> 8);
	get_unsigned = get_unsigned | (get_unsigned >> 16);
	get_unsigned = get_unsigned | (get_unsigned >> 32);

	get_return= !!get_unsigned;//find 0

	get_msb= (get_return << 63) >> 63& ((get_unsigned >> 1) + 1);


	int64_t get_zeros,mask_32,mask_16,mask_8,mask_4,mask_2,mask_1,catch_value,tracker,mask_0;
	mask_32=0xFFFFFFFF00000000;
	mask_16=0xFFFF0000;
	mask_8=0xFF00;
	mask_4=0xF0;
	mask_2=12;
	mask_1=2;
	mask_0=1;
	catch_value=0;

	tracker=get_msb;
	get_zeros=get_msb&mask_32;//find if the leading 1 is on the upper or lower range



		catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))//when msb is on the upper range, assign catch_value=catch_value
					+((((!get_zeros) << 63) >> 63)& (catch_value+32));//when msb is on the lower range, assign catch_calue+=32
		get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>32))//shift to right for 32 bits position when the leading 1 is on upper range
					+((((!get_zeros) << 63) >> 63)& tracker);//assign tracker to the get_zero value if leading is on the lower range


		tracker=get_zeros;//assign the value of current leading position (after shifting)
		get_zeros=tracker&mask_16;//find leading 1 eight upper or lower range with 16 bits for each
				catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))
					+((((!get_zeros) << 63) >> 63)& (catch_value+16));
				get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>16))
					+((((!get_zeros) << 63) >> 63)& tracker);


		tracker=get_zeros;
		get_zeros=tracker&mask_8;//find leading 1 eight upper or lower range with 8 bits for each

				catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))
					+((((!get_zeros) << 63) >> 63)& (catch_value+8));
				get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>8))
					+((((!get_zeros) << 63) >> 63)& tracker);

		
		tracker=get_zeros;
		get_zeros=tracker&mask_4;//find leading 1 eight upper or lower range with 4 bits for each
				catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))
					+((((!get_zeros) << 63) >> 63)& (catch_value+4));
				get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>4))
					+((((!get_zeros) << 63) >> 63)& tracker);


		tracker=get_zeros;
		get_zeros=tracker&mask_2;//find leading 1 eight upper or lower range with 2 bits for each

				catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))
					+((((!get_zeros) << 63) >> 63)& (catch_value+2));
				get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>2))
					+((((!get_zeros) << 63) >> 63)& tracker);


		tracker=get_zeros;
		get_zeros=tracker&mask_1;//find leading 1 eight upper or lower range with 1 bits for each
				catch_value=(((!!get_zeros << 63) >> 63)& (catch_value))
					+((((!get_zeros) << 63) >> 63)& (catch_value+1));
				get_zeros=(((!!get_zeros << 63) >> 63)& (get_zeros>>1))
					+((((!get_zeros) << 63) >> 63)& tracker);


	return (64-catch_value);/*Since the question implicitly show that the size 
						of int64_t is 64 bits, the min numberr of bits ca
						n be expressed 64-catch_value. otherwise, need to use 
						sizeof() to get the size of input value
															*/
}


