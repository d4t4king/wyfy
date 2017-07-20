#!/usr/bin/perl -w

use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;
use Getopt::Long;
my ($help, $verbose, $input);
# need to standardize a little to present a unified interface
GetOptions(
	'h|help'		=>	\$help,
	'v|verbose+'	=>	\$verbose,
	'i|input=s'		=>	\$input,
);

use lib "./";
use NetXML::Parser;

&usage() if ($help);
if ((!defined($input)) or ($input eq '')) {
	print "You must specify an input file that is netxml format from kismet or related tools.";
	&usage();
}

my $obj = NetXML::Parser->parsefile($ARGV[0]);

#print Dumper($obj);
print "Found ".$obj->network_count." networks.\n";
foreach my $net ( sort @{$obj->networks} ) {
	print $net->essid." (".$net->bssid.") has ".$net->client_count." clients.\n";
	#print Dumper($net);
	#print "\t\tENC: \n";
	#foreach my $enc ( @{$net->encryption} ) {
	#	print "\t\t\t$enc\n";
	#}
	if ($net->client_count > 1) {
		print "Found a network with more than one client: ".$net->essid." (".$net->client_count.") (".$net->bssid.") \n";
		my %clients;
		foreach my $cli ( @{$net->clients} ) {
			next if (!defined($cli->number));
			$clients{$cli->number} = $cli;
		}
		print "Client ID\tMAC Address       \tChannel\tManufacturer\n";
		foreach my $clid ( sort { $a <=> $b } keys %clients ) {
			printf "%9d\t%-18s\t%6d\t%-15s\n", $clid, $clients{$clid}->mac_address, $clients{$clid}->channel, $clients{$clid}->manufacturer;
		}
	}
}

##########################################################
# Subs
##########################################################
sub usage {
	print <<EOS;

Simply displays information about wireless network data found
in a netxml file from Kismet or airodump-ng.

Usage:
$0 -hv -i <file>

-h|--help		Displays this message then quits.
-v|--verbose		Increase output verbosity.
-i|--input		Specifies the full path to the input file.

EOS
	
	exit 0;
}
