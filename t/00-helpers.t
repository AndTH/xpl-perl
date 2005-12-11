#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;
use t::Helpers qw/:all/;
is(test_error(sub { die 'argh' }),
   'argh',
   'died horribly');

is(test_warn(sub { warn 'danger will robinson' }),
   'danger will robinson',
   'warned nicely');