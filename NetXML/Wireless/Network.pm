
###############################################################################
##																		     ##
##	Copyright (c) 2016 by Charlie Heselton								     ##
##	All rights reserved.						   							 ##
##																		     ##
##	This package is free doftware; you can redistribute it 				     ##
##	and/or modify it under the same terms as Perl itself.				     ##
##																		     ##
###############################################################################

package NetXML::Wireless::Network;


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
use NetXML::Wireless::Client;

our @EXPORT		= qw( new first_time bssid last_time data_packets llc_packets retry_packets packet_fragments total_packets crypto_packets is_cloaked max_rate encryption type essid manufacturer number channel frequency signal_to_noise_ratio_info );
our @EXPORT_OK	= qw( );
{
	$NetXML::Wireless::Network::VERSION = '0.0.1';
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
		#print "Got 2 parameters\n";
		$self->{'bssid'} = shift if (&_is_mac($_[0]));
		$self->{'essid'} = shift;
	} elsif (scalar(@_) == 3) {
		#print "Got 3 parameters\n";
		if (ref($_[2]) eq 'HASH') {
			$self->{'bssid'} = $_[0] if (&_is_mac($_[0]));
			$self->{'essid'} = $_[1];
			foreach my $k ( keys %{$_[2]} ) {
				next if ($k eq 'BSSID');
				if ($k eq 'manuf') {
					$self->{'manufacturer'} = $_[2]->{$k};
				} elsif ($k eq 'wireless-client') {
					if (ref($_[2]->{$k}) eq 'ARRAY') {
						foreach my $wc ( @{$_[2]->{$k}} ) {
							my $wcli = NetXML::Wireless::Client->new($wc->{'client-mac'}, $wc);
							push @{$self->{'clients'}}, $wcli;
						}
					} elsif (ref($_[2]->{$k}) eq 'HASH') {
						# hash means that there is just one client
						my $wcli = NetXML::Wireless::Client->new($_[2]->{$k}{'client-mac'}, $_[2]->{$k});
						push @{$self->{'clients'}}, $wcli;
					} else {
						warn colored("Wireless client object not an array or hash!", "bold red");
						print color("bold red");
						print "REF: ".ref($_[2]->{$k})."\n";
						print Dumper($_[2]->{$k});
						print color("reset");
						exit 255;
					}
				} elsif ($k eq 'freqmhz') {
					if (ref($_[2]->{$k}) eq 'ARRAY') {
						foreach my $freq ( @{$_[2]->{$k}} ) {
							$freq =~ s/ /./;
							if (exists($self->{$k})) { $self->{$k} .= " $freq"; }
							else { $self->{$k} = $freq; }
						}
					} else {
						$_[2]->{$k} =~ s/ /./;
						$self->{$k} = $_[2]->{$k};
					}
				} else {
					$self->{$k} = $_[2]->{$k};
				}
			}
		} else {
			die colored("Expected a HASH and got ".ref($_[2])." for 3rd parameter.\n", "bold red");
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
	if (exists($self->{'SSID'}{'encryption'})) {
		return $self->{'SSID'}{'encryption'};
	} else {
		return "Unknown";
	}
}

sub max_rate {
	my $self = shift;
	if (exists($self->{'SSID'}{'max-rate'})) {
		return $self->{'SSID'}{'max-rate'};
	} else {
		return 0;
	}
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
			return $self->{'clients'};
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
	if (exists($self->{'SSID'}{'essid'}{'cloaked'})) {
		return $from_bool{$self->{'SSID'}{'essid'}{'cloaked'}};
	} else {
		return $from_bool{'false'};
	}
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
