package xPL::Base;

# $Id: Base.pm,v 1.8 2005/12/06 17:27:11 beanz Exp $

=head1 NAME

xPL::Base - Perl extension for an xPL Base Class

=head1 SYNOPSIS

  use xPL::Base;
  our @ISA = qw/xPL::Base/;

=head1 DESCRIPTION

This is a module for a common base class for the xPL modules.  It
contains a number of helper methods.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use English qw/-no_match_vars/;
use FileHandle;
use Socket;

use Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';
our $CVSVERSION = qw/$Revision: 1.8 $/[1];

=head1 COLLECTION STRUCTURE API

A number of the classes maintain collections of items.  For instance,
the L<xPL::Hub> maintains a collection of clientsa and the
L<xPL::Listener> maintains a collection for timers and another for
callbacks for xPL Messages.  These methods provide the basic interface
for those collections.

=head2 C<init_items($type)>

This method must be called before a collection is used.  It
is typically called from the constructor.

=cut

sub init_items {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} and
    $self->argh("BUG: item type, $type, already initialized");
  $self->{_col}->{$type} = {};
  return 1;
}

=head2 C<add_item($type, $id, \%attributes)>

This method is used by L<add_input>, L<add_timer>, etc. to add
items to their respective collections.

=cut

sub add_item {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} or
    $self->argh("BUG: item type, $type, invalid");
  my $id = shift or $self->argh('BUG: item id missing');
  my $attribs = shift or $self->argh('BUG: item attribs missing');
  if ($self->exists_item($type, $id)) {
    $self->argh("$type item '$id' already registered");
  }
  return $self->{_col}->{$type}->{$id} = $attribs;
}

=head2 C<exists_item($type, $id)>

This method is used by L<exists_input>, L<exists_timer>, etc. to check
for existence of items in their respective collections.

=cut

sub exists_item {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} or
    $self->argh("BUG: item type, $type, invalid");
  my $id = shift or $self->argh('BUG: item id missing');
  return exists $self->{_col}->{$type}->{$id};
}

=head2 C<remove_item($type, $id)>

This method is used by L<remove_input>, L<remove_timer>, etc. to remove
items from their respective collections.

=cut

sub remove_item {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} or
    $self->argh("BUG: item type, $type, invalid");
  my $id = shift or $self->argh('BUG: item id missing');
  unless ($self->exists_item($type, $id)) {
    return $self->ouch("$type item '$id' not registered");
  }

  delete $self->{_col}->{$type}->{$id};
  return 1;
}

=head2 C<item_attrib($type, $id, $attrib)>

This method is used by L<input_attrib>, L<timer_attrib>, etc. to query
the value of attributes of registered items in their respective
collections.

=cut

sub item_attrib {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} or
    $self->argh("BUG: item type, $type, invalid");
  my $id = shift or $self->argh('BUG: item id missing');
  unless ($self->exists_item($type, $id)) {
    return $self->ouch("$type item '$id' not registered");
  }
  my $key = shift or $self->argh('missing key');
  if (@_) {
    $self->{_col}->{$type}->{$id}->{$key} = $_[0];
  }
  return $self->{_col}->{$type}->{$id}->{$key};
}

=head2 C<items($type)>

This method is used by L<timers>, L<inputs>, etc. to query
the ids of registered items in their respective collections.

=cut

sub items {
  my $self = shift;
  my $type = shift or $self->argh('BUG: item type missing');
  exists $self->{_col}->{$type} or
    $self->argh("BUG: item type, $type, invalid");
  return keys %{$self->{_col}->{$type}};
}

=head2 C<add_callback_item($type, $id, \%attributes)>

This method is a wrapper around L<add_item> to handle some
functionality for adding items that happen to be callbacks - which
most of the items used internally by this module are at the moment.

=cut

sub add_callback_item {
  my $self = shift;
  my $attribs = $self->add_item(@_);
  exists $attribs->{callback} or $attribs->{callback} = sub { 1; };
  exists $attribs->{arguments} or $attribs->{arguments} = [];
  $attribs->{callback_count} = 0;
  return $attribs;
}

=head1 METHOD MAKER METHODS

=head2 C<make_collection(collection1 => [attrib1, attrib2]);

This method creates some wrapper methods for a collection.  For instance,
if called as:

  __PACKAGE__->make_collection_method('client' => ['source', 'identity']);

it creates a set of methods called "add_client", "exists_client", ...
corresponding to the collection methods above.  It also creates methods
"client_source" and "client_identity" to retrieve client item attributes.

=cut

sub make_collection {
  my $pkg = shift;
  my %collections = @_;
  foreach my $collection_name (keys %collections) {
    foreach my $method (qw/add_X exists_X remove_X Xs X_attrib init_Xs/) {
      $pkg->make_collection_method($collection_name, $method);
    }
    foreach my $attr (@{$collections{$collection_name}}) {
      $pkg->make_item_attribute_method($collection_name, $attr);
    }
  }
  return 1;
}

=head2 C<make_collection_method($collection_type, $method_template)>

This class method makes a type safe method to wrap the collection api.
For instance, if called as:

  __PACKAGE__->make_collection_method('peer', 'add_X');

it creates a method that can be called as:

  $obj->add_peer($peer_id, { attr1 => $val1, attr2 => $val2 });

which is 'mapped' to a call to:

  $obj->add_item('peer', $peer_id, { attr1 => $val1, attr2 => $val2 });

=cut

sub make_collection_method {
  my $pkg = shift;
  my $collection_type = shift or $pkg->argh('BUG: missing collection type');
  my $method_template = shift or $pkg->argh('BUG: missing method template');
  my $new = $method_template;
  $new =~ s/X/$collection_type/;
  $new = $pkg.q{::}.$new;
  return if (defined &{"$new"});
  my $parent = $method_template;
  $parent =~ s/X/item/;
  #print STDERR "  $new => $parent\n";
  no strict 'refs';
  *{"$new"} =
    sub {
      my $self = shift;
      $self->$parent($collection_type, @_);
    };
  use strict 'refs';
  return 1;
}

=head2 C<make_item_attribute_method($collection_type, $attribute_name)>

This class method makes a type safe method to wrap the collection api.
For instance, called as:

  __PACKAGE__->make_item_attribute_method('peer', 'name');

it creates a method that can be called as:

  $obj->peer_name($peer_id);

or as:

  $obj->peer_name($peer_id, $name);

=cut

sub make_item_attribute_method {
  my $pkg = shift;
  my $collection_type = shift or $pkg->argh('BUG: missing collection type');
  my $attribute_name = shift or $pkg->argh('BUG: missing attribute name');
  my $new = $pkg.q{::}.$collection_type.q{_}.$attribute_name;
  return if (defined &{"$new"});
  #print STDERR "  $new => item_attrib\n";
  no strict 'refs';
  *{"$new"} =
    sub {
      my $self = shift;
      my $item = shift;
      $self->item_attrib($collection_type, $item, $attribute_name, @_);
    };
  use strict 'refs';
  return 1;
}

=head2 C<make_readonly_accessor($attrib)>

This class method makes a type safe method to access object attributes.
For instance, called as:

  __PACKAGE__->make_item_attribute_method('listen_port');

it creates a method that can be called as:

  $obj->listen_port();

=cut

sub make_readonly_accessor {
  my $pkg = shift;
  unless (@_) { $pkg->argh('BUG: missing attribute name'); }
  foreach my $attribute_name (@_) {
    my $new = $pkg.q{::}.$attribute_name;
    return if (defined &{"$new"});
    #print STDERR "  $new => readonly_accessor\n";
    no strict 'refs';
    *{"$new"} =
      sub {
        my $self = shift;
        $self->ouch_named($attribute_name,
                          'called with an argument, but '.
                            $attribute_name.' is readonly')
          if (@_);
        return $self->{'_'.$attribute_name};
      };
    use strict 'refs';
  }
  return 1;
}

=head1 HELPERS

=head2 C<default_interface_info()>

This method returns a hash reference containing keys for 'device',
'address', 'broadcast', and 'netmask' for the interface that the
simple heuristic thinks would be a good default.  The heuristic
is currently first interface that isn't loopback.

=cut

sub default_interface_info {
  my $self = shift;
  my $res = $self->interfaces() or return;
  foreach my $if (@$res) {
    next if ($if->{device} eq "lo");
    return $if;
  }
  return;
}

=head2 C<is_local_address( $ip )>

This method returns true if the given IP address is one of the
addresses of our interfaces.

=cut

sub is_local_address {
  my $self = shift;
  my $ip = shift;
  my $res = $self->interfaces() or return;
  foreach my $if (@$res) {
    return 1 if ($if->{ip} eq $ip);
  }
  return;
}

=head2 C<interface_ip($if)>

This method returns the ip address associated with the named interface.

=cut

sub interface_ip {
  my $self = shift;
  my $res = $self->interface_info(@_);
  return $res ? $res->{ip} : undef;
}

=head2 C<interface_broadcast($if)>

This method returns the broadcast address associated with the named
interface.

=cut

sub interface_broadcast {
  my $self = shift;
  my $res = $self->interface_info(@_);
  return $res ? $res->{broadcast} : undef;
}

=head2 C<interface_info($if)>

This method returns a hash reference containing keys for 'device',
'address', 'broadcast', and 'netmask' for the named interface.

=cut

sub interface_info {
  my $self = shift;
  my $ifname = shift;
  my $res = $self->interfaces() or return;
  foreach my $if (@$res) {
    return $if if ($if->{device} eq $ifname);
  }
  return;
}

=head2 C<interfaces()>

This method returns a list reference of network interfaces.  Each
element of the list is a hash reference containing keys for
'device', 'address', 'broadcast', and 'netmask'.

=cut

sub interfaces {
  my $self = shift;
  my @res;
  # cache the results of interface lookups
  unless (exists $self->{_interfaces}) {
    # I was going to use Net::Ifconfig::Wrapper but it appears to hide
    # the order of interfaces.  This is important since I wanted to make
    # the first non-loopback interface the default
    $self->{_interfaces} =
      $self->interfaces_ifconfig() || $self->interfaces_ip() || [];
  }
  return $self->{_interfaces};
}

=head2 C<interfaces_ip()>

This method returns a list reference of network interfaces.  Each
element of the list is a hash reference containing keys for
'device', 'address', 'broadcast', and 'netmask'.  It is implemented
using the modern C<ip> command.

=cut

sub interfaces_ip {
  my $self = shift;
  my $command = $self->find_in_path("ip") or return;
  my @res;
  my $fh = FileHandle->new($command.' addr show|') or return;
  my $if;
  while (<$fh>) {
    if (/^\d+:\s+([a-zA-Z0-9:]+):/) {
      $if = $1;
    } elsif (/inet (\d+\.\d+\.\d+\.\d+)\/\d+\s+brd\s+(\d+\.\d+\.\d+\.\d+)/i) {
      push @res, { device => $if, ip => $1, broadcast => $2, src => 'ip' };
    } elsif ($if =~ /^lo/ && /inet (\d+\.\d+\.\d+\.\d+)\/(\d+)/) {
      push @res,
        {
         device => $if,
         ip => $1,
         broadcast => broadcast_from_class($1,$2),
         src => 'ip',
        };
    }
  }
  $fh->close;
  return \@res;
}

=head2 C<interfaces_ifconfig()>

This method returns a list reference of network interfaces.  Each
element of the list is a hash reference containing keys for
'device', 'address', 'broadcast', and 'netmask'.  It is implemented
using the traditional C<ifconfig> command.

=cut

sub interfaces_ifconfig {
  my $self = shift;
  my $command = $self->find_in_path("ifconfig") or return;
  my @res;
  my $fh = FileHandle->new($command.' -a|') or return;
  {
    local $/;
    $/ = "\n\n";
    while (<$fh>) {
      if (/^([a-zA-Z0-9:]+) .*
           inet\s+addr:(\d+\.\d+\.\d+\.\d+)\s+
           bcast:(\d+\.\d+\.\d+\.\d+)/six) {
        push @res,
          {
           device => $1,
           ip => $2,
           broadcast => $3,
           src => 'ifconfig',
          };
      } elsif (/^(lo[a-zA-Z0-9:]*) .*
           inet\s+addr:(\d+\.\d+\.\d+\.\d+)\s+
           mask:(\d+\.\d+\.\d+\.\d+)/six) {
        # special case to cope with loopback even though it isn't
        # strictly a broadcast interface
        push @res,
          {
           device => $1,
           ip => $2,
           broadcast => broadcast_from_mask($2,$3),
           src => 'ifconfig'
          };
      }
    }
    $fh->close;
  }
  return \@res;
}

=head2 C<broadcast_from_mask( $ip, $mask )>

This function returns the broadcast address based on a given ip address
and netmask.

=cut

sub broadcast_from_mask {
  my $ip = shift;
  my $mask = shift;
  my @ip = unpack("C4", inet_aton($ip));
  my @m = unpack("C4",inet_aton($mask));
  my @b;
  foreach (0..3) {
    push @b, $ip[$_] | 255-$m[$_];
  }
  return join ".",@b;
}

=head2 C<broadcast_from_class( $ip, $class )>

This function returns the broadcast address based on a given ip address
and an number of bits representing the address class.

=cut

sub broadcast_from_class {
  my $ip = shift;
  my $class = shift;
  my @m;
  foreach (0..3) {
    if ($class > 8) {
      $m[$_] = 255;
      $class-=8;
    } else {
      $m[$_] = 255-(2**(8-$class)-1);
      $class=0
    }
  }
  return broadcast_from_mask($ip, join(".",@m));
}

=head2 C<find_in_path( $command )>

This method is use to find commands in the PATH.  It is mostly
here to avoid the error messages that might appear if you try
to execute something that isn't in the PATH.

=cut

sub find_in_path {
  my $self = shift;
  my $command = shift;
  my @path = split /:/, $ENV{PATH};
  # be sure to check /sbin unless we are in the Test::Harness
  push @path, '/sbin' unless ($ENV{HARNESS_ACTIVE});
  foreach my $path (@path) {
    my $f = $path.'/'.$command;
    if (-x $f) {
      return $f;
    }
  }
  return;
}

=head2 C<module_available( $module, [ @import_arguments ])>

This method returns true if the named module is available.
Any optional additional arguments are passed to import
when loading the module.

=cut

sub module_available {
  my $self = shift;
  my $module = shift;
  return $self->{_mod}->{$module} if (exists $self->{_mod}->{$module});
  my $file = $module;
  $file =~ s!::!/!g;
  $file .= '.pm';
  return $self->{_mod}->{$module} = 1 if (exists $INC{$file});
  eval "require $module; import $module \@_;";
  return $self->{_mod}->{$module} = $EVAL_ERROR ? 0 : 1;
}

=head2 C<verbose( [ $new_verbose_setting ] )>

The method sets the verbose setting on the object.  Setting it to zero
should mean little or no output.  Setting it to 1 or more should
result in more messages.

=cut

sub verbose {
  my $self = shift;
  if (@_) {
    $self->{_verbose} = $_[0];
  }
  return $self->{_verbose};
}

=head2 C<argh(@message)>

This methods is just a helper to 'die' a helpful error messages.

=cut

sub argh {
  my $pkg = shift;
  if (ref $pkg) { $pkg = ref $pkg }
  my ($file, $line, $method) = (caller 1)[1,2,3];
  $method =~ s/.*:://;
  die $pkg."->$method: @_\n  at $file line $line.\n";
}

=head2 C<ouch(@message)>

This methods is just a helper to 'warn' a helpful error messages.

=cut

sub ouch {
  my $pkg = shift;
  if (ref $pkg) { $pkg = ref $pkg }
  my ($file, $line, $method) = (caller 1)[1,2,3];
  $method =~ s/.*:://;
  warn $pkg."->$method: @_\n  at $file line $line.\n";
  return;
}

=head2 C<argh_named(@message)>

This methods is just another helper to 'die' a helpful error messages.

=cut

sub argh_named {
  my $pkg = shift;
  my $name = shift;
  if (ref $pkg) { $pkg = ref $pkg }
  my ($file, $line) = (caller 1)[1,2];
  die $pkg."->$name: @_\n  at $file line $line.\n";
}

=head2 C<ouch_named(@message)>

This methods is just another helper to 'warn' a helpful error messages.

=cut

sub ouch_named {
  my $pkg = shift;
  my $name = shift;
  if (ref $pkg) { $pkg = ref $pkg }
  my ($file, $line) = (caller 1)[1,2];
  warn $pkg."->$name: @_\n  at $file line $line.\n";
  return;
}

1;
__END__

=head1 EXPORT

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