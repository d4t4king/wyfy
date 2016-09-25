
###############################################################################
##									     ##
##	Copyright (c) 2016 by Charlie Heselton				     ##
##	All rights reserved.						     ##
##									     ##
##	This package is free doftware; you can redistribute it 		     ##
##	and/or modify it under the same terms as Perl itself.		     ##
##									     ##
###############################################################################
#
package Wireless::Network;


=pod 

=head1 NAME

Wireless::Network

=head1 VERSION

This man page documents "Wireless::Network" version 0.0.1.

=head1 SYNOPSIS

This package attempts to objectify a wireless network described in the *.netxml output of wireless analysis tools like kismet and airodump-ng.

=cut 

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

my %to_bool = (
	0	=>	'false',
	1	=>	'true'
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
				} elsif ((!defined($self->{$k})) or ($self->{$k} eq "")) {
					$self->{$k} = undef;
				} else {
					#my $wcli = Wireless::Client->new($self->{'wireless-client'}{'client-mac'}, $self->{'wireless-client'});
					#push @{$self->{'clients'}}, $wcli;
					print Dumper($self->{$k});
					die colored("error", "bold red");
				}
			#} elsif ($k eq 'freqmhz') {
			#	$self->{$k} =~ s/ /./;
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

=pod 

=head1 PROPERTIES

=head2 first_time

Shows the datetime for the initial observation of the network

=cut

sub first_time {
	my $self = shift;
	return $self->{'first-time'};
}

=pod

=head2 last_time

Shows the datetime for the last observation of the network

=cut 

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
	return $self->{'SSID'}{'max-rate'};
}

sub frequency {
	my $self = shift;
	return $self->{'freqmhz'};
}

sub signal_to_noise_ratio_info {
	my $self = shift;
	return $self->{'snr-info'};
}


sub clients {
	my $self = shift;
	if ((!defined($self->{'clients'})) or ($self->{'clients'} eq "")) {
		return [];
	} else {
		if (ref($self->{'clients'}) eq 'ARRAY') {			
			return @{$self->{'clients'}};
		} else {
			die colored("Client object not an array! \n", "bold red");
		}
	}
}

=pod 

=head1 METHODS

=cut

sub is_cloaked {
	my $self = shift;
	return $from_bool{$self->{'SSID'}{'essid'}{'cloaked'}};
}

sub client_count {
	my $self = shift;
	if ((!defined($self->{'clients'})) or ($self->{'clients'} eq "")) {
		return 0;
	} else {
		if (ref($self->{'clients'}) eq 'ARRAY') {
			return scalar(@{$self->{'clients'}});
		} else {
			die colored("Clients object not an array! \n", "bold red");
		}
	}
}

=pod 

=head1 AUTHOR

=begin html

<div class="codeblock">
	<pre>
		Charlie Heselton
		mailto:charles.heselton [at] gmail [dot] com
	</pre>
</div>

=end html

=head1 COPYRIGHT

Copyright (c) 2016 by Charlie Heselton.  All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute it under the same terms as Perl itself, i.e., at your option, under the terms either of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

1;
