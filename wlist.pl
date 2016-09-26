#!/usr/bin/perl -w

use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;

use lib "./";
use NetXML::Parser;

my $obj = NetXML::Parser->parsefile($ARGV[0]);

#print Dumper($obj);
print "Found ".$obj->network_count." networks.\n";

foreach my $net ( sort @{$obj->networks} ) {
	print $net->essid."(".$net->bssid.") has ".$net->client_count." clients.\n";
}
