package NetXML::Parser;

use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;
use XML::Simple;

use lib "./";
use NetXML::Wireless::Network;

our @EXPORT		=	qw( parsefile kismet_version network_count );
our @EXPORT_OK	=	qw( );
{
	$NetXML::Parser::VERSION = '0.0.1';
}

sub parsefile {
	my $class = shift;
	my $file = shift;
	my $self;
	if (-e $file) {
		if (! -z $file) {
			my $xdoc = XMLin($file) or die colored("There was a problem reading the input file: $!", "bold red");
			#print Dumper($xdoc);
			$self = {
				'kismet_version'	=>	$xdoc->{'kismet-version'},
				'start_time'		=>	$xdoc->{'start-time'}
			};
            if (ref($xdoc->{'wireless-network'}) eq 'ARRAY') {
                foreach my $net ( @{$xdoc->{'wireless-network'}} ) {
                    my $wnet;
                    if (!defined($net->{'SSID'}{'essid'}{'content'})) {
                        $wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, "NONE", $net);
                    } else {
                        $wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, $net->{'SSID'}{'essid'}{'content'}, $net);
                    }
                    push @{$self->{'networks'}}, $wnet;
                }
            } else {
                warn colored("Wireless network object is not an array!", "bold red");
                print color("bold red");
                print ref($xdoc->{'wireless-network'})."\n";
                print Dumper($xdoc->{'wireless-network'});
                print color("reset");
                exit 255;
            }
		} else {
			die colored("The file specified is zero (0) bytes.", "bold red");
		}
	} else {
		die colored("The file specified does not exist.", "bold red");
	}

	bless $self, $class;

	return $self;
}

sub network_count {
	my $self = shift;
	return scalar(@{$self->{'networks'}});
}

sub kismet_version {
	my $self = shift;
	return $self->{'kistmet_version'};
}
