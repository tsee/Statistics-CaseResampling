package Statistics::CaseResampling;
use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  resample
  resample_medians
  resample_means
  select_kth
  median
  mean
);
our @EXPORT = qw();
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Statistics::CaseResampling', $VERSION);

our $Rnd = Statistics::CaseResampling::RdGen::setup(rand());


1;
__END__

=head1 NAME

Statistics::CaseResampling - Efficient resampling

=head1 SYNOPSIS

  use Statistics::CaseResampling ':all';

  my $sample = [1,3,5,7,1,2,9];
  my $resampled = resample($sample);
  # $resampled is now a random set of measurements from $sample,
  # including potential duplicates
  
  my $medians = resample_medians($sample, $n_resamples);
  # $medians is not an array reference containing the medians
  # of $n_resamples resample runs
  # this is vastly more efficient that doing the same thing with
  # repeated resample() calls
  my $means = resample_means($sample, $n_resamples);
  
  # utility functions:
  print median([1..5]), "\n"; # prints 3
  print mean([1..5]), "\n"; # prints 3, too, surprise!
  print select_kth([1..5], 1), "\n"; # inefficient way to calculate the minimum

=head1 DESCRIPTION

This is a simple XS module for resampling a set of numbers efficiently.
As a convenience (for my use case), it can calculate the medians
(in O(n) using a selection algorithm) of many resamples and return those instead.

Since this involves drawing B<many> random numbers, the module comes
with an embedded Mersenne twister (taken from C<Math::Random::MT>).

If you want to change the seed of the RNG, do this:

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup($seed);
 
or

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup(@seed);

Do not use the embedded random number generator for other purposes.
Use C<Math::Random::MT> instead!

=head2 EXPORT

None by default.

Can export any of the functions that are documented below
using standard C<Exporter> semantics, including the
customary C<:all> group.

=head1 FUNCTIONS

=head2 resample(ARRAYREF)

Returns a reference to an array containing N random elements from the
input array, where N is the length of the original array.

=head2 resample_medians(ARRAYREF, NMEDIANS)

Returns a reference to an array containing the medians of
C<NMEDIANS> resamples of the original input sample.

=head2 resample_means(ARRAYREF, NMEANS)

Returns a reference to an array containing the means of
C<NMEANS> resamples of the original input sample.

=head2 median(ARRAYREF)

Calculates the median of a sample. Works in linear time thanks
to using a selection instead of a sort. Unfortunately, the way
this is implemented, the median of an even number of parameters
is, here, defined as the C<n/2-1>th largest number and not
the average of the C<n/2-1>th and the C<n/2>th number. This shouldn't
matter for nontrivial sample sizes.

=head2 mean(ARRAYREF)

Calculates the meean of a sample.

=head2 select_kth(ARRAYREF, K)

Selects the kth smallest element from the sample.

You get the median with this definition of K:

  my $k = int(@$sample/2) + (@$sample & 1);
  my $median = select_kth($sample, $k);

=head1 TODO

One could calculate other statistics than the median and mean
in C for performance.

=head1 SEE ALSO

L<Math::Random::MT>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
