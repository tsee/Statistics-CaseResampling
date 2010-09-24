#ifndef _S_CS_STATS_H_
#define _S_CS_STATS_H_

#include "EXTERN.h"
#include "perl.h"

#include "mt.h"

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

/* O(n) selection algorithm selecting the kth value from the sample of size n */
double cs_select(double* sample, I32 n, U32 k);

/* fast median in O(n) using selection */
double cs_median(double* sample, I32 n);

/* run-of-the-mill mean */
double cs_mean(double* sample, I32 n);

/* resample the sample into the provided destination array (doesn't malloc for you!) */
void do_resample(double* original, I32 n, struct mt* rdgen, double* dest);

/* an unoptimized quicksort implementation. Currently not used */
/* void cs_sort(double arr[], I32 beg, I32 end); */

/* median using the unoptimized quicksort. Currently not used */
/* double cs_median(double* sample, I32 n)  */

#endif
