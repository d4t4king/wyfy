package Wireless::Network;

use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;

require Exporter;

use lib "../";
use Wireless::Client;

our @EXPORT		= qw( new );
our @EXPORT_OK	= qw( );
{
	$Wireless::Network::VERSION = '0.0.1';
}

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

1;
