use strict;
use warnings;
use Test::More;
use Statistics::CaseResampling ':all';

# SCR-01: Empty array handling without wild pointer deallocation / crashes
{
  my $r = resample([]);
  is_deeply($r, [], 'resample([]) returns empty array without crash');

  my $rm = resample_medians([], 10);
  is_deeply($rm, [], 'resample_medians([], 10) returns empty array without crash');

  my $rme = resample_means([], 10);
  is_deeply($rme, [], 'resample_means([], 10) returns empty array without crash');

  is(median([]), 0, 'median([]) returns 0 without crash');
  is(median_absolute_deviation([]), 0, 'median_absolute_deviation([]) returns 0 without crash');
  is(first_quartile([]), 0, 'first_quartile([]) returns 0 without crash');
  is(third_quartile([]), 0, 'third_quartile([]) returns 0 without crash');

  my ($l, $med, $u) = median_simple_confidence_limits([], 0.95);
  is($l, 0, 'median_simple_confidence_limits([]) lower is 0');
  is($med, 0, 'median_simple_confidence_limits([]) median is 0');
  is($u, 0, 'median_simple_confidence_limits([]) upper is 0');

  my ($l2, $st, $u2) = simple_confidence_limits_from_samples(0, [], 0.95);
  is($l2, 0, 'simple_confidence_limits_from_samples([]) lower is 0');
  is($st, 0, 'simple_confidence_limits_from_samples([]) stat is 0');
  is($u2, 0, 'simple_confidence_limits_from_samples([]) upper is 0');
}

done_testing();
