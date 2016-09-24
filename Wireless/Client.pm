package Wireless::Client;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

require Exporter;

our @EXPORT		= qw( new mac_address );
our @EXPORT_OK	= qw( );
{
	$Wireless::Client::VERSION = '0.0.1';
}

my ($mac_address,$manufacturer,$max_seen_rate,$type,$channel,$first_time,$last_time,$number);
my (%device,%portid,%snr_info,%packets);

sub new {
	my $class = shift;
	my $self;
	if (scalar(@_) == 1) {
		# must be the MAC
		$self->{'mac_address'} = shift if (&_is_mac($_[0]));
	} elsif ((scalar(@_) == 2) and (ref($_[1]) eq 'HASH')) {
		$self->{'mac_address'} = shift if (&_is_mac($_[0]));
		print color("bold yellow");
		print Dumper($_[0]);
		print color('reset');
		foreach my $k ( keys %{$_[0]} ) {
			next if ($k eq 'client-mac');
			if ($k eq 'client-manuf') {
				$self->{'manufacturer'} = $_[0]->{$k};
			} elsif ($k eq 'snr-info') {
				$self->{'snr_info'} = $_[0]->{$k};
			} else {
				$self->{$k} = $_[0]->{$k};
			}
		}
	} else {
		die colored(scalar(@_)." elements in \@_\n", "bold red");
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

sub mac_address {
	my $self = shift;
	return $self->{'mac_address'};
}

sub first_time {
	my $self = shift;
	return $self->{'first-time'};
}

sub last_time {
	my $self = shift;
	return $self->{'last-time'};
}

sub channel {
	my $self = shift;
	return $self->{'channel'};
}

sub signal_to_noise_ratio_info {
	my $self = shift;
	return $self->{'snr_info'};
}

1;
