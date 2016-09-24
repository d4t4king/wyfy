#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Term::ANSIColor;
use Getopt::Long;
use XML::Simple;

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

print Dumper($xdoc);

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
