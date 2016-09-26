#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;
use Getopt::Long;
use XML::Simple;

use lib './';
use NetXML::Wireless::Client;
use NetXML::Wireless::Network;

my ($help,$verbose,$input,$one);
$verbose = 0; $one = 0;
GetOptions(
	'h|help'		=>	\$help,
	'v|verbose+'		=>	\$verbose,
	'i|input=s'		=>	\$input,
	'1|one'			=>	\$one
);

&usage if ($help);
if ((!defined($input)) or ($input eq "")) {
	warn colored("No input file specified!", "bold red");
	&usage;
}

my $xdoc = XMLin($input);

if (ref($xdoc->{'wireless-network'}) eq 'ARRAY') {
	foreach my $net ( @{$xdoc->{'wireless-network'}} ) {
		if ($verbose) {
			print color("bold yellow");
			print Dumper($net);
			print color("reset");
		}
		my $wnet;
		if (!defined($net->{'SSID'}{'essid'}{'content'})) {
			$wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, "NONE", $net);
		} else {
			$wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, $net->{'SSID'}{'essid'}{'content'}, $net);
		}
		if ($verbose) {
			print color("bold magenta");
			print Dumper($wnet);
			print color("reset");
		}
		printf "%-40s %-s\n", colored("ESSID: ", "bold green"), colored($wnet->essid, "magenta");
		printf "%-40s %-s\n", colored("BSSID: ", "bold green"), colored($wnet->bssid, "magenta");
		printf "%-40s %-s\n", colored("First Time: ", "bold green"), colored($wnet->first_time, "cyan");
		printf "%-40s %-s\n", colored("Last Time: ", "bold green"), colored($wnet->last_time, "cyan");
		printf "%-40s %-s\n", colored("Type: ", "bold green"), colored($wnet->type, "magenta");
		printf "%-40s %-s\n", colored("Manufacturer: ", "bold green"), colored($wnet->manufacturer, "magenta");
		printf "%-40s %-s\n", colored("Number: ", "bold green"), colored($wnet->number, "red");
		printf "%-40s %-s\n", colored("Channel: ", "bold green"), colored($wnet->channel, "red");
		printf "%-40s %-s\n", colored("Data Packets: ", "bold green"), colored($wnet->data_packets, "red");
		printf "%-40s %-s\n", colored("LLC Packets: ", "bold green"), colored($wnet->llc_packets, "red");
		printf "%-40s %-s\n", colored("Packet Retries: ", "bold green"), colored($wnet->retry_packets, "red");
		printf "%-40s %-s\n", colored("Packet Fragments: ", "bold green"), colored($wnet->packet_fragments, "red");
		printf "%-40s %-s\n", colored("Total Packets: ", "bold green"), colored($wnet->total_packets, "red");
		printf "%-40s %-s\n", colored("Crypto Packets: ", "bold green"), colored($wnet->crypto_packets, "red");
		printf "%-40s %-s\n", colored("Encryption: ", "bold green"), colored($wnet->encryption, "magenta");
		printf "%-40s %-s\n", colored("Max Rate: ", "bold green"), colored($wnet->max_rate, "magenta");
		printf "%-40s %-s\n", colored("Is Cloaked: ", "bold green"), colored($wnet->is_cloaked, "red");
		printf "%-40s %-s\n", colored("Frequency: ", "bold green"), colored($wnet->frequency, "magenta");
		printf "%-40s %-s\n", colored("Client count: ", "bold green"), colored($wnet->client_count, "red");
		printf colored("Clients: \n", "bold green");
		print color("yellow"); print Dumper($wnet->clients); print color("reset");
		last if ($one);
	}
} else {
	warn colored("Wireless network object is not an array!", "bold red");
	print color("bold red");
	print ref($xdoc->{'wireless-network'})."\n";
	print Dumper($xdoc->{'wireless-network'});
	print color("reset");
	exit 254;
}

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
