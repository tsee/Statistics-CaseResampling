use strict;
use warnings;
use Test::More tests => 20;
use Statistics::CaseResampling ':all';
use List::Util ('min', 'max');

my $sample = [1..11];
my $resample = resample($sample);

ok(ref($resample) && ref($resample) eq 'ARRAY');
is(scalar(@$resample), 11);
cmp_ok(min(@$resample), '>=', 1);
cmp_ok(max(@$resample), '<=', 11);

my $medians = resample_medians($sample, 30);
ok(ref($medians) && ref($medians) eq 'ARRAY');
is(scalar(@$medians), 30);
cmp_ok(min(@$medians), '>=', 1);
cmp_ok(max(@$medians), '<=', 11);

is_approx(median([1,2]), 1);
is_approx(median([1,2,3]), 2);
is_approx(median([1,2,3,4]), 2);
is_approx(median([4,3,2,1]), 2);
is_approx(median([4,1,2,3]), 2);
is_approx(median([5,4,1,2,3]), 3);

sub is_approx {
  cmp_ok($_[0]+1.e-9, '>=', $_[1]);
  cmp_ok($_[0]-1.e-9, '<=', $_[1]);
}

