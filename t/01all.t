use strict;
use warnings;
use Test::More tests => 51;
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

my @tests = (
  [  [1], 1  ],
  [  [1,2], 1  ],
  [  [1,2,3], 2  ],
  [  [1,2,3,4], 2  ],
  [  [4,3,2,1], 2  ],
  [  [4,1,2,3], 2  ],
  [  [5,4,1,2,3], 3  ],
);
for my $test (@tests) {
  my ($data, $result) = @$test;
  is_approx(median($data), $result, "[@$data] has median $result");
  my $k = int(@$data/2) + (@$data & 1);
  my $kth = select_kth($data, $k);
  my $median = median($data);
  is_approx(median($data), $kth, "[@$data] median() and select_kth() agree");
}

eval {select_kth([1..10], -3)};
ok($@);
eval {select_kth([1..10], 0)};
ok($@);
eval {select_kth([1..10], 11)};
ok($@);
eval {select_kth([1..10], 10)};
ok(!$@);
eval {select_kth([1..10], 1)};
ok(!$@);

foreach my $i (1..5) {
  is_approx(select_kth([5..9], $i), $i+4, "selecting ${i}th works");
}

sub is_approx {
  cmp_ok($_[0]+1.e-9, '>=', $_[1], $_[2]);
  cmp_ok($_[0]-1.e-9, '<=', $_[1], $_[2]);
}

