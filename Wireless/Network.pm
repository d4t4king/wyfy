package Wireless::Network;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

require Exporter;

use lib "../";
use Wireless::Client;

our @EXPORT		= qw( new first_time bssid last_time data_packets llc_packets retry_packets packet_fragments total_packets crypto_packets is_cloaked max_rate encryption type essid manufacturer number channel frequency signal_to_noise_ratio_info );
our @EXPORT_OK	= qw( );
{
	$Wireless::Network::VERSION = '0.0.1';
}

my %from_bool = (
	'false'	=>	0,
	'FALSE'	=>	0,
	'False'	=>	0,
	'true'	=>	1,
	'TRUE'	=>	1,
	'True'	=>	1
);

sub new {
	my $class = shift;
	my $self;
	if (scalar(@_) == 2) {
		$self->{'bssid'} = shift if (&_is_mac($_[0]));
		$self->{'essid'} = shift;
	} elsif ((scalar(@_) == 3) and (ref($_[2]) eq 'HASH')) {
		$self->{'bssid'} = shift if (&_is_mac($_[0]));
		$self->{'essid'} = shift;
		print color("bold yellow");
		print Dumper($_[0]);
		print color("reset");
		foreach my $k ( keys %{$_[0]} ) {
			next if ($k eq 'BSSID');
			if ($k eq 'manuf') {
				$self->{'manufacturer'} = $_[0]->{$k};
			} elsif ($k eq 'wireless-client') {
				if (ref($k) eq 'ARRAY') {
					foreach my $wc ( @{$k} ) {
						my $wcli = Wireless::Client->new($wc->{'client-mac'}, $wc);
						push @{$self->{'clients'}}, $wcli;
					}
				}
			} else {
				$self->{$k} = $_[0]->{$k};
			}
		}
	} else {
		die colored(scalar(@_)." elements in \@_", "bold yellow");
	}

	bless $self, $class;

	return $self;
}

sub _is_mac {
	my $str = shift;
	if ($str =~ /(?:[0-9a-fA-F]{2}(?::|-)){5}[0-9a-fA-F]{2}/) {
		return 1;
	} else {
		return 0;
	}
}

sub first_time {
	my $self = shift;
	return $self->{'first-time'};
}

sub last_time {
	my $self = shift;
	return $self->{'last-time'};
}

sub bssid {
	my $self = shift;
	return $self->{'bssid'};
}

sub type {
	my $self = shift;
	return $self->{'type'};
}

sub essid {
	my $self = shift;
	return $self->{'essid'};
}

sub manufacturer {
	my $self = shift;
	return $self->{'manufacturer'};
}

sub number {
	my $self = shift;
	return $self->{'number'};
}

sub channel {
	my $self = shift;
	return $self->{'channel'};
}

sub data_packets {
	my $self = shift;
	return $self->{'packets'}{'data'};
}

sub llc_packets {
	my $self = shift;
	return $self->{'packets'}{'LLC'};
}

sub retry_packets {
	my $self = shift;
	return $self->{'packets'}{'retries'};
}

sub packet_fragments {
	my $self = shift;
	return $self->{'packets'}{'fragments'};
}

sub total_packets {
	my $self = shift;
	return $self->{'packets'}{'total'};
}

sub crypto_packets {
	my $self = shift;
	return $self->{'packets'}{'crypt'};
}

sub encryption {
	my $self = shift;
	return $self->{'SSID'}{'encryption'};
}

sub max_rate {
	my $self = shift;
	return $elf->{'SSID'}{'max-rate'};
}

sub is_cloaked {
	my $self = shift;
	return $from_bool{$self->{'SSID'}{'essid'}{'cloaked'}};
}

sub frequency {
	my $self = shift;
	return $self->{'freqmhz'};
}

sub signal_to_noise_ratio_info {
	my $self = shift;
	return $self->{'snr-info'};
}

1;
