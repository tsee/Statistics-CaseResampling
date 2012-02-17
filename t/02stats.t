use strict;
use warnings;
use Test::More tests => 4;
use Statistics::CaseResampling ':all';
use List::Util qw(sum);

my @sample = qw(20 10 1 5.1 -10. 2.1 5.5);

my $mean = sum(@sample) / @sample;
is(mean(\@sample), $mean, "mean");

my @diffsq = map {($_-$mean)**2} @sample;
my $std_dev = sum(@diffsq) / @sample;
my $samp_std_dev = sum(@diffsq) / (@sample-1);

is(sample_standard_deviation($mean, \@sample), $samp_std_dev, "sample_standard_deviation");
is(population_standard_deviation($mean, \@sample), $std_dev, "population_standard_deviation");


my @sample = qw(20 10 1 5.1 -10. 2.1 5.5);
is(median(\@sample), 5.1);

