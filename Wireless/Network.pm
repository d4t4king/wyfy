package Wireless::Netwoork;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

require Exporter;

our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Wireless::Network::VERSION = '0.0.1';
}

sub new {
	my $class = shift;
	my $self = {
		'bssid'		=>	shift,
		'essid'		=>	shift,
	};

	bless $self, $class;

	return $self;
}

1;
