#!/usr/bin/perl -w
#
# Copyright (C) 2005, 2009 by Mark Hindess

use strict;
use Test::More tests => 10;

use_ok('xPL::Message');

my $msg;
my $payload =
'xpl-stat
{
hop=1
source=vendor-device.instance
target=*
}
fred.schema
{
b=value-b
c=value-c
a=value-a
}
';

my $str = xPL::Message->new_from_payload($payload)->string;
is($str, $payload, 'new_from_payload');

my $payload_pre =
'xpl-stat
{
hop=1
source=vendor-device.instance
target=*
}
fred.schema
{
';
my $payload_body =
'b=value-b
c=value-c
a=value-a
b=value-b2
b=value-b3
}
';

$payload = $payload_pre.$payload_body;
$msg = xPL::Message->new_from_payload($payload);
ok($msg, 'new_from_payload with duplicate field - constructor');
is($msg->string, $payload,
   'new_from_payload with duplicate field - content in');
is(join(",", $msg->body_fields()), 'b,c,a',
   'new_from_payload with duplicate field - fields');
$payload_body =
'b=value-b
b=value-b2
b=value-b3
c=value-c
a=value-a
}
';
$payload = $payload_pre.$payload_body;
is($msg->summary,
   ('xpl-stat/fred.schema: vendor-device.instance -> * '.
    'value-b/value-b2/value-b3/value-c/value-a'),
   'new_from_payload decoding');
is($msg->string, $payload,
   'new_from_payload with duplicate field - content out');

$payload =
'xpl-stat
{
hop=1
source=vendor-device.instance
target=*
}
fred.schema
{
}
';

is(xPL::Message->new_from_payload($payload)->string, $payload,
   'new_from_payload with empty body');

$payload =
'xpl-stat
{
hop=1
source=vendor-device.instance
target=*
}
hbeat.basic
{
interval=5
}
';

my $m = xPL::Message->new_from_payload($payload);
ok($m, 'new_from_pauload hbeat.basic');
is($m->string, $payload, 'new_from_payload hbeat.basic body');
