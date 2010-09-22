package Statistics::CaseResampling;
use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  resample
  resample_medians
  median
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.02';

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
  
  # utility function:
  print median([1..4]), "\n"; # prints 2.5

=head1 DESCRIPTION

This is a simple XS module for resampling a set of numbers efficiently.
As a convenience (for my use case), it can calculate the medians
(unfortunately in O(n*log(n))) of many resamples and return those instead.

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

=head1 TODO

One could calculate other statistics than the median in C for performance.

It is possible to calculate the median in O(n) without sorting.
That would also take care of losing my bog-standard quick sort implementation.

Beware of memory leaks. So far, this module is not well tested.

=head2 EXPORT

None by default.

Can export C<:all>, C<resample>, C<median>, and C<resample_medians>.

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
