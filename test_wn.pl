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

foreach my $net ( @{$xdoc->{'wireless-network'}} ) {
	my $wnet = Wireless::Network->new($net->{'BSSID'}, $net->{'SSID'}{'essid'}{'content'}, $net);
	print colored("ESSID: ", "bold green"); print colored($wnet->essid."\n", "magenta");
	print colored("BSSID: ", "bold green"); print colored($wnet->bssid."\n", "magenta");
	print colored("First Time: ", "bold green"); print colored($wnet->first_time."\n", "cyan");
	print colored("Last Time: ", "bold green"); print colored($wnet->last_time."\n", "cyan");
	print colored("Type: ", "bold green"); print colored($wnet->type."\n", "magenta");
	print colored("Manufacturer: ", "bold green"); print colored($wnet->manufacturer."\n", "magenta");
	print colored("Number: ", "bold green"); print colored($wnet->number."\n", "red");
	print colored("Channel: ", "bold green"); print colored($wnet->channel."\n", "red");
	print colored("Data Packets: ", "bold green"); print colored($wnet->data_packets."\n", "red");
	print colored("LLC Packets: ", "bold green"); print colored($wnet->llc_packets."\n", "red");
	print colored("Packet Retries: ", "bold green"); print colored($wnet->retry_packets."\n", "red");
	print colored("Packet Fragments: ", "bold green"); print colored($wnet->packet_fragments."\n", "red");
	print colored("Total Packets: ", "bold green"); print colored($wnet->total_packets."\n", "red");
	print colored("Crypto Packets: ", "bold green"); print colored($wnet->crypto_packets."\n", "red");
	print colored("Encryption: ", "bold green"); print colored($wnet->encryption."\n", "magenta");
	print colored("Max Rate: ", "bold green"); print colored($wnet->max_rate."\n", "magenta");
	print colored("Is Cloaked: ", "bold green"); print colored($wnet->is_cloaked."\n", "red");
	print colored("Frequency: ", "bold green"); print colored($wnet->frequency."\n", "magenta");
	print colored("Client count: ", "bold green"); print colored($wnet->client_count."\n", "red");
	print colored("Clients: \n", "bold green");
	print colored(Dumper($wnet->clients), "yellow");
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
