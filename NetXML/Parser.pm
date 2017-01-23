package NetXML::Parser;

use strict;
use warnings;
#use experimental 'smartmatch';
use feature qw( switch );
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use Term::ANSIColor;
use Data::Dumper;
use XML::Simple;

use lib "./";
use NetXML::Wireless::Network;
use NetXML::Wireless::Card;

our @EXPORT		=	qw( parsefile kismet_version network_count networks );
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
			if (exists($xdoc->{'card-source'})) {
				if (ref($xdoc->{'card-source'}) eq 'HASH') {
					my $card = NetXML::Wireless::Card->new($xdoc->{'card-source'}{'uuid'}, $xdoc->{'card-source'});
					$self->{'source-card'} = $card;
				} else {
					warn colored("card source object not a hash!", "yellow");
					print color('yellow');
					print Dumper($xdoc->{'card_source'});
					print color('reset');
				}
			}
			if (ref($xdoc->{'wireless-network'}) eq 'ARRAY') {
				foreach my $net ( @{$xdoc->{'wireless-network'}} ) {
					my $wnet;
					print colored(ref($net)."\n", "bold magenta");
					if (ref($net) eq 'HASH') {
						if (ref($net->{'SSID'}) eq 'HASH') {
							given (ref($net->{'SSID'}{'essid'})) {
								when ('HASH') {
									if (exists($net->{'SSID'}{'essid'}{'content'})) {
										$wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, $net->{'SSID'}{'essid'}{'content'}, $net);
									} else {
										$wnet = NetXML::Wireless::Network->new($net->{'BSSID'}, "Unknown", $net);
									}
									push @{$self->{'networks'}}, $wnet;
								}
								when ('ARRAY') {
									print Dumper($net->{'SSID'}{'essid'});
									exit 1;
								}
								default { 
									warn colored("SSID object is either a string or nil.", "yellow");
								}
							}#given
						} else { 	#if (ref($net->{'SSID'}) eq 'HASH')
							print Dumper($net->{'SSID'});
						}
					} else {	#if (ref($net) eq 'HASH')
						print Dumper($net);
						exit 1;
					}
				}#foreach
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

sub networks {
	my $self = shift;
	return \@{$self->{'networks'}};
}
