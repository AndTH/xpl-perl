package xPL::Validation::IP;

# $Id: IP.pm,v 1.4 2005/12/06 15:00:49 beanz Exp $

=head1 NAME

xPL::Validation::IP - Perl extension for xPL Validation IP address class

=head1 SYNOPSIS

  # this class is not expected to be used directly

  use xPL::Validation;

  my $validation = xPL::Validation->new(type => 'IP');

=head1 DESCRIPTION

This module creates an xPL validation which is used to validate fields
of xPL messages.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use xPL::Validation::Any;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(xPL::Validation::Any);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = qw/$Revision: 1.4 $/[1];

=head2 C<new(%parameter_hash)>

The constructor creates a new xPL::Validation::IP object.
The constructor takes a parameter hash as arguments.  Common
parameters are described in L<xPL::Validation>.  This validator type
has no additional parameters.

It returns a blessed reference when successful or undef otherwise.

=head2 C<valid( $value )>

This method returns true if the value is valid.

=cut

sub valid {
  my $self = shift;
  my $o = '([0-9]|1?[0-9][0-9]|2([0-4][0-9]|5[0-5]))';
  return defined $_[0] && $_[0] =~ /^$o\.$o\.$o\.$o$/o;
}

=head2 C<error( )>

This method returns a suitable error string for the validation.

=cut

sub error {
  my $self = shift;
  return 'It should be an IP address.';
}

1;
__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

Project website: http://www.xpl-perl.org.uk/

=head1 AUTHOR

Mark Hindess, E<lt>xpl-perl@beanz.uklinux.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Mark Hindess

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut