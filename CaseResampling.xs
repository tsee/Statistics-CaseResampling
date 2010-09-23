#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mt.h"

typedef struct mt * Statistics__CaseResampling__RdGen;

void * U32ArrayPtr ( int n ) {
    SV * sv = sv_2mortal( NEWSV( 0, n*sizeof(U32) ) );
    return SvPVX(sv);
}

/*
void
cs_sort(double arr[], I32 beg, I32 end)
{
  double t;
  if (end > beg + 1)
  {
    double piv = arr[beg];
    I32 l = beg + 1, r = end;
    while (l < r)
    {
      if (arr[l] <= piv)
        l++;
      else {
        t = arr[l];
        arr[l] = arr[--r];
        arr[r] = t;
      }
    }
    t = arr[--l];
    arr[l] = arr[beg];
    arr[beg] = t;
    cs_sort(arr, beg, l);
    cs_sort(arr, r, end);
  }
}
*/

/*
double
cs_median(double* sample, I32 n)
{
  cs_sort(sample, 0, n);
  if (n & 1) {
    return sample[n/2];
  }
  else {
    return 0.5*(sample[n/2-1]+sample[n/2]);
  }
}
*/

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

double
cs_select(double* sample, I32 n, U32 k) {
  U32 i, ir, j, l, mid;
  double a, tmp;

  l = 0;
  ir = n-1;
  while(1) {
    if (ir <= l+1) { 
      if (ir == l+1 && sample[ir] < sample[l]) {
	SWAP(sample[l], sample[ir]);
      }
      return sample[k];
    }
    else {
      mid = (l+ir) >> 1; 
      SWAP(sample[mid], sample[l+1]);
      if (sample[l] > sample[ir]) {
	SWAP(sample[l], sample[ir]);
      }
      if (sample[l+1] > sample[ir]) {
	SWAP(sample[l+1], sample[ir]);
      }
      if (sample[l] > sample[l+1]) {
	SWAP(sample[l], sample[l+1]);
      }
      i = l+1; 
      j = ir;
      a = sample[l+1]; 
      while(1) { 
	do i++; while (sample[i] < a); 
	do j--; while (sample[j] > a); 
	if (j < i)
          break; 
	SWAP(sample[i], sample[j]);
      } 
      sample[l+1] = sample[j]; 
      sample[j] = a;
      if (j >= k)
        ir = j-1; 
      if (j <= k)
        l = i;
    }
  }
}

double
cs_median(double* sample, I32 n)
{
  U32 k = n/2 - !(n & 1);
  return cs_select(sample, n, k);
}


void
do_resample(double* original, I32 n, struct mt* rdgen, double* dest)
{
  I32 rndElem;
  I32 i;
  for (i = 0; i < n; ++i) {
    rndElem = (I32) (mt_genrand(rdgen) * n);
    dest[i] = original[rndElem];
  }
}

void
avToCAry(pTHX_ AV* in, double** out, I32* n)
{
  I32 thisN;
  double* ary;
  SV** elem;
  I32 i;
  thisN = av_len(in)+1;
  *n = thisN;
  if (thisN == 0)
    return;

  Newx(ary, thisN, double);
  *out = ary;
  for (i = 0; i < thisN; ++i) {
    if (NULL == (elem = av_fetch(in, i, 0))) {
      Safefree(ary);
      croak("Could not fetch element from array");
    }
    else
      ary[i] = SvNV(*elem);
  }
}

void
cAryToAV(pTHX_ double* in, AV** out, I32 n)
{
  SV* elem;
  I32 i;
  *out = newAV();
  if (n == 0)
    return;

  av_extend(*out, n-1);

  for (i = 0; i < n; ++i) {
    elem = newSVnv(in[i]);
    if (NULL == av_store(*out, i, elem))
      SvREFCNT_dec(elem);
  }
}

struct mt*
get_rnd(pTHX)
{
  IV tmp;
  SV* therndsv = get_sv("Statistics::CaseResampling::Rnd", 0);
  if (therndsv == NULL
      || !SvROK(therndsv)
      || !sv_derived_from(therndsv, "Statistics::CaseResampling::RdGen"))
  {
    croak("Random number generator not set up!");
  }
  tmp = SvIV((SV*)SvRV(therndsv));
  return INT2PTR(struct mt*, tmp);
}


MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling::RdGen PREFIX=mt_
PROTOTYPES: DISABLE

Statistics::CaseResampling::RdGen
mt_setup(seed)
  U32     seed
  CODE:
    RETVAL = mt_setup(seed);
  OUTPUT:
    RETVAL

Statistics::CaseResampling::RdGen
mt_setup_array( array, ... )
  CODE:
    U32 * array = U32ArrayPtr( items );
    U32 ix_array = 0;
    while (items--) {
      array[ix_array] = (U32)SvIV(ST(ix_array));
      ix_array++;
    }
    RETVAL = mt_setup_array( (uint32_t*)array, ix_array );
  OUTPUT:
    RETVAL

void
mt_DESTROY(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    mt_free(self);

double
mt_genrand(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    RETVAL = mt_genrand(self);
  OUTPUT:
    RETVAL

MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling
PROTOTYPES: DISABLE

AV*
resample(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample;
    double* destsample;
    struct mt* rnd;
  CODE:
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      do_resample(csample, nelem, rnd, destsample);
      cAryToAV(aTHX_ destsample, &RETVAL, nelem);
      Safefree(destsample);
    }
    else
      RETVAL = newAV();
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL

AV*
resample_medians(sample, runs)
    AV* sample
    I32 runs
  PREINIT:
    I32 nelem;
    I32 iRun;
    double* csample;
    double* destsample;
    struct mt* rnd;
  CODE:
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    RETVAL = newAV();
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      av_extend(RETVAL, runs-1);
      for (iRun = 0; iRun < runs; ++iRun) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, iRun, newSVnv(cs_median(destsample, nelem)));
      }
      Safefree(destsample);
    }
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL

double
median(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0)
      RETVAL = 0.;
    else
      RETVAL = cs_median(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL


double
select_kth(sample, kth)
    AV* sample
    I32 kth
  PREINIT:
    I32 nelem;
    double* csample;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (kth < 1 || kth > nelem) {
      croak("Can't select %ith smallest element from a list of %i elements", kth, nelem);
    }
    RETVAL = cs_select(csample, nelem, kth-1);
    Safefree(csample);
  OUTPUT: RETVAL

