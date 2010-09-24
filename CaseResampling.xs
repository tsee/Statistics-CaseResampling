#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mt.h"
#include "stats.h"


typedef struct mt * Statistics__CaseResampling__RdGen;

void*
U32ArrayPtr (pTHX_ int n)
{
  SV * sv = sv_2mortal( NEWSV( 0, n*sizeof(U32) ) );
  return SvPVX(sv);
}

double
cs_mean_av(pTHX_ AV* sample)
{
  I32 i, n;
  SV** elem;
  n = av_len(sample)+1;
  double sum = 0.;
  for (i = 0; i < n; ++i) {
    if (NULL == (elem = av_fetch(sample, i, 0))) {
      croak("Could not fetch element from array");
    }
    else
      sum += SvNV(*elem);
  }
  return sum/(double)n;
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


MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling
PROTOTYPES: DISABLE

INCLUDE: RdGen.xs.inc

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
    I32 i_run;
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
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, i_run, newSVnv(cs_median(destsample, nelem)));
      }
      Safefree(destsample);
    }
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


AV*
resample_means(sample, runs)
    AV* sample
    I32 runs
  PREINIT:
    I32 nelem;
    I32 i_run;
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
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, i_run, newSVnv(cs_mean(destsample, nelem)));
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
first_quartile(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0)
      RETVAL = 0.;
    else
      RETVAL = cs_first_quartile(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL


double
third_quartile(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0)
      RETVAL = 0.;
    else
      RETVAL = cs_third_quartile(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL


double
mean(sample)
    AV* sample
  CODE:
    RETVAL = cs_mean_av(aTHX_ sample);
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


void
median_simple_confidence_limits(sample, confidence...)
    AV* sample
    double confidence
  PREINIT:
    /* "confidence" is 1-alpha */
    I32 runs, nelem, i_run;
    double *csample, *destsample, *medians;
    struct mt* rnd;
    double median   = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha;
  INIT:
    alpha = 1.-confidence;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = SvUV(ST(2));
    else {
      croak("Usage: ($lower, $median, $upper) = median_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    if (confidence <= 0. || confidence >= 1.) {
      croak("Confidence level has to be in (0, 1)");
    }
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem != 0) {
      median = cs_median(csample, nelem);
      Newx(medians, runs, double);
      Newx(destsample, nelem, double);
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        medians[i_run] = cs_median(destsample, nelem);
      }
      Safefree(destsample);
      /* lower = t - (t*_((R+1)*(1-alpha)) - t)
       * upper = t - (t*_((R+1)*alpha) - t)
       */
      lower_ci = 2.*median - cs_select( medians, runs, (I32)((runs+1.)*(1.-alpha)) );
      upper_ci = 2.*median - cs_select( medians, runs, (I32)((runs+1.)*alpha) );
      Safefree(medians);
    }
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(median);
    mPUSHn(upper_ci);


void
simple_confidence_limits_from_samples(statistic, statistics, confidence)
    double statistic
    AV* statistics
    double confidence
  PREINIT:
    /* "confidence" is 1-alpha */
    I32 nelem;
    double *cstatistics;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha;
  INIT:
    alpha = 1.-confidence;
  PPCODE:
    if (confidence <= 0. || confidence >= 1.) {
      croak("Confidence level has to be in (0, 1)");
    }
    avToCAry(aTHX_ statistics, &cstatistics, &nelem);
    if (nelem != 0) {
      /* lower = t - (t*_((R+1)*(1-alpha)) - t)
       * upper = t - (t*_((R+1)*alpha) - t)
       */
      lower_ci = 2.*statistic - cs_select( cstatistics, nelem, (I32)((nelem+1.)*(1.-alpha)) );
      upper_ci = 2.*statistic - cs_select( cstatistics, nelem, (I32)((nelem+1.)*alpha) );
    }
    Safefree(cstatistics);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(statistic);
    mPUSHn(upper_ci);


double
approx_erf(x)
    double x
  CODE:
    RETVAL = cs_approx_erf(x);
  OUTPUT: RETVAL


double
approx_erf_inv(x)
    double x
  CODE:
    if (x <= 0. || x >= 1.)
      croak("The inverse error function is defined in (0,1). %f is outside that range", x);
    RETVAL = cs_approx_erf_inv(x);
  OUTPUT: RETVAL


double
alpha_to_nsigma(x)
    double x
  CODE:
    RETVAL = cs_alpha_to_nsigma(x);
  OUTPUT: RETVAL


double
nsigma_to_alpha(x)
    double x
  CODE:
    RETVAL = cs_nsigma_to_alpha(x);
  OUTPUT: RETVAL

