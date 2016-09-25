#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;
use Getopt::Long;
use XML::Simple;

use lib './';
use Wireless::Client;
use Wireless::Network;

my ($help,$verbose,$input);
$verbose = 0;
GetOptions(
	'h|help'		=>	\$help,
	'v|verbose+'	=>	\$verbose,
	'i|input=s'		=>	\$input,
);

&usage if ($help);
if ((!defined($input)) or ($input eq "")) {
	warn colored("No input file specified!", "bold red");
	&usage;
}

my $xdoc = XMLin($input);

if (ref($xdoc->{'wireless-network'}) eq 'ARRAY') {
	foreach my $wnet ( @{$xdoc->{'wireless-network'}} ) {
		if (ref($wnet->{'wireless-client'}) eq 'ARRAY') {
			foreach my $wc ( @{$wnet->{'wireless-client'}} ) {
				print Dumper($wc) if ($verbose);
				my $wcli = Wireless::Client->new($wc->{'client-mac'}, $wc);
				print Dumper($wcli) if ($verbose);
				print "#" x 80; print "\n";
				printf "%-40s %-s\n", "MAC Address:", $wcli->mac_address;
				printf "%-40s %-s\n", "First Time:", $wcli->first_time;
				printf "%-40s %-s\n", "Last Time:", $wcli->last_time;
				printf "%-40s %-s\n", "Channel:", $wcli->channel;
				printf "%-40s %-s\n", "Type:", $wcli->type;
				printf "%-40s %-s\n", "Packet Fragments:", $wcli->packet_fragments;
				printf "%-40s %-s\n", "Crypto Packets:", $wcli->crypto_packets;
				printf "%-40s %-s\n", "Packet Retries:", $wcli->packet_retries;
				printf "%-40s %-s\n", "Data Packets:", $wcli->data_packets;
				printf "%-40s %-s\n", "LLC Packets:", $wcli->llc_packets;
				printf "%-40s %-s\n", "Total Packets:", $wcli->total_packets;
				printf "%-40s %-s\n", "Manufacturer:", $wcli->manufacturer;
				printf "%-40s %-s\n", "Number:", $wcli->number;
				printf "%-40s %-s\n", "Max Seen Rate:", $wcli->max_seen_rate;
			}
		} else {
			next if (!defined($wnet->{'wireless-client'}));
			if (ref($wnet->{'wireless-client'}) eq 'HASH') {
				print Dumper($wnet->{'wireless-client'}) if ($verbose);
				#my $wcli = Wireless::Client->new($wnet->{'wireless-client'}{'client-mac'}, { number => $xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'number'}, type => $xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'type'} });
				my $wcli = Wireless::Client->new($wnet->{'wireless-client'}{'client-mac'}, $wnet->{'wireless-client'});
				print Dumper($wcli) if ($verbose);
				print "#" x 80; print "\n";
				printf "%-40s %-s\n", "MAC Address:", $wcli->mac_address;
				printf "%-40s %-s\n", "First Time:", $wcli->first_time;
				printf "%-40s %-s\n", "Last Time:", $wcli->last_time;
				printf "%-40s %-s\n", "Channel:", $wcli->channel;
				printf "%-40s %-s\n", "Type:", $wcli->type;
				printf "%-40s %-s\n", "Packet Fragments:", $wcli->packet_fragments;
				printf "%-40s %-s\n", "Crypto Packets:", $wcli->crypto_packets;
				printf "%-40s %-s\n", "Packet Retries:", $wcli->packet_retries;
				printf "%-40s %-s\n", "Data Packets:", $wcli->data_packets;
				printf "%-40s %-s\n", "LLC Packets:", $wcli->llc_packets;
				printf "%-40s %-s\n", "Total Packets:", $wcli->total_packets;
				printf "%-40s %-s\n", "Manufacturer:", $wcli->manufacturer;
				printf "%-40s %-s\n", "Number:", $wcli->number;
				printf "%-40s %-s\n", "Max Seen Rate:", $wcli->max_seen_rate;
			} else {
				warn colored("Wireless client object not an array or hash!", "bold red"); print "\n";
				print color('bold red');
				print ref($wnet->{'wireless-client'})."\n";
				print Dumper($wnet->{'wireless-client'});
				print color("reset");
				exit 255;
			}
		}
	}
} else {
	warn colored("Wireless network object not an array! \n", "bold red");
	print Dumper($xdoc->{'wireless-network'});
	exit 254;
}
#print Dumper($xdoc->{'wireless-network'}[0]{'wireless-client'}[0]) if ($verbose);
#my $wcli = Wireless::Client->new($xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'client-mac'}, { number => $xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'number'}, type => $xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'type'} });
#my $wcli = Wireless::Client->new($xdoc->{'wireless-network'}[0]{'wireless-client'}[0]{'client-mac'}, \%{$xdoc->{'wireless-network'}[0]{'wireless-client'}[0]});
#print Dumper($wcli) if ($verbose);
#print "#" x 80; print "\n";
#printf "%-40s %-s\n", "MAC Address:", $wcli->mac_address;
#printf "%-40s %-s\n", "First Time:", $wcli->first_time;
#printf "%-40s %-s\n", "Last Time:", $wcli->last_time;
#printf "%-40s %-s\n", "Channel:", $wcli->channel;
#printf "%-40s %-s\n", "Type:", $wcli->type;
#printf "%-40s %-s\n", "Packet Fragments:", $wcli->packet_fragments;
#printf "%-40s %-s\n", "Crypto Packets:", $wcli->crypto_packets;
#printf "%-40s %-s\n", "Packet Retries:", $wcli->packet_retries;
#printf "%-40s %-s\n", "Data Packets:", $wcli->data_packets;
#printf "%-40s %-s\n", "LLC Packets:", $wcli->llc_packets;
#printf "%-40s %-s\n", "Total Packets:", $wcli->total_packets;
#printf "%-40s %-s\n", "Manufacturer:", $wcli->manufacturer;
#printf "%-40s %-s\n", "Number:", $wcli->number;
#printf "%-40s %-s\n", "Max Seen Rate:", $wcli->max_seen_rate;

###############################################################################
# Subs
###############################################################################
sub usage {

	print <<END;

$0 [-h|--help] [-v|--verbose] [-i|--input] <input_file>

Where:

-h|--help				Displays this useful message, then exits.
-v|--verbose				Displays more than normal output.  Usually useful for debugging.  YMMV.  Repeat
						to increase verbosity.
-i|--input				Specifies the path to the input file.  Expects a *.netxml file from kismet or airodump-ng.

END
	exit 0;
}
