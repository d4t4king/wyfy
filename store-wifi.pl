#!/usr/bin/perl

use strict;
use warnings;
require 5.0010;
use Term::ANSIColor;
use Data::Dumper;
use DBI;
use Date::Calc qw( Today_and_Now );

use lib "../wyfy/";
use NetXML::Parser;

use Getopt::Long;
my ($help, $verbose, $input, $pw);
$verbose = 0;
GetOptions(
	'h|help'	=>	\$help,
	'v|verbose+'	=>	\$verbose,
	'i|input=s'	=>	\$input,
	'p|pass=s'	=>	\$pw,
);

die colored("Need an input file.  Try the -i option.", "bold red") if ((!defined($input)) or ($input eq ""));
die colored("Need the database password.  Use -p ", "bold red") if ((!defined($pw)) or ($pw eq ""));

my $database	=	"wireless";
my $dbhost		=	"192.168.1.50";
my $dsn			=	"DBI:mysql:database=$database;host=$dbhost";
my $user		=	"root";
my $pass		=	"$pw";

my (%db_networks, %db_clients);
&get_networks();

my %mon2num;
$mon2num{'Jan'} = '01';
$mon2num{'Feb'} = '02';
$mon2num{'Mar'}	= '03';
$mon2num{'Apr'}	= '04';
$mon2num{'May'}	= '05';
$mon2num{'Jun'}	= '06';
$mon2num{'Jul'}	= '07';
$mon2num{'Aug'}	= '08';
$mon2num{'Sep'}	= '09';
$mon2num{'Oct'}	= '10';
$mon2num{'Nov'}	= '11';
$mon2num{'Dec'}	= '12';

my $time = time();
my ($Ty,$Tm,$Td,$TH,$TM,$TS) = Today_and_Now($time);
$Tm = &pad_zero($Tm); $Td = &pad_zero($Td); 
$TH = &pad_zero($TH); $TM = &pad_zero($TM); $TS = &pad_zero($TS);
my $last_updated = "$Ty/$Tm/$Td $TH:$TM:$TS";

if ( -e $input ) {
	if ( ! -z $input ) {
		my $dbh	= DBI->connect($dsn, $user, $pass);
		my $obj = NetXML::Parser->parsefile($input);
		print "Found ".$obj->network_count." networks in the input file.\n";
		if ($obj->network_count > 0) {
			foreach my $net ( @{$obj->networks} ) {
				if (exists($db_networks{$net->bssid})) {
					if (&record_verified($net)) {
						# update time
						print colored("UPDATE networks SET last_updated='$last_updated' WHERE bssid='".$net->bssid."'\n", "green");
						my $sth = $dbh->prepare("UPDATE networks SET last_updated='$last_updated' WHERE bssid='".$net->bssid."'") or die $DBI::errstr;
						my $rtv = $sth->execute() or die $DBI::errstr;
						print colored("UPDATE RTV: $rtv \n", "bold magenta") if ($verbose);
						$sth->finish or die $DBI::errstr;
					} else {
						# update changes (?)
					}
				} else {
					my $first_seen = $net->first_time;
					#Thu Sep 22 23:18:01 2016
					my $date_found;
					if ($first_seen =~ /(?:[a-zA-Z]+?) ([a-zA-Z]+?) (\d+) (\d+):(\d+):(\d+) (\d+)/) {
						my $mon = $1; my $day = $2; my $H = $3; my $M = $4; my $S = $5; my $y = $6;
						print "|$mon| $day $H $M $S $y \n" if (($verbose) and ($verbose > 1));
						$mon = $mon2num{$mon};
						$date_found = "$y/$mon/$day $H:$M:$S";
					} else {
						die colored("Didn't match date string ($first_seen) ", "bold red");
					}
					print "INSERT INTO networks (bssid,essid,date_found,last_updated,num_clients,encryption,max_rate,type,channel,manufacturer,cloaked,frequency) VALUES ('".$net->bssid."','".$net->essid."','$date_found','$last_updated','".$net->client_count."','".$net->encryption."','".$net->max_rate."','".$net->type."','".$net->channel."','".$net->manufacturer."','".$net->is_cloaked."','".$net->frequency."');\n";
					my $sth = $dbh->prepare("INSERT INTO networks (bssid,essid,date_found,last_updated,num_clients,encryption,max_rate,type,channel,manufacturer,cloaked,frequency) VALUES ('".$net->bssid."','".$net->essid."','$date_found','$last_updated','".$net->client_count."','".$net->encryption."','".$net->max_rate."','".$net->type."','".$net->channel."','".$net->manufacturer."','".$net->is_cloaked."','".$net->frequency."');") or die $DBI::errstr;
					my $rtv = $sth->execute() or die $DBI::errstr;
					print colored("INSERT RTV: $rtv \n", "bold yellow") if ($verbose);
					$sth->finish;
				}
				my $net_id = &get_net_id($net->bssid);
				if ($net->client_count > 0) {
					if (defined($net->clients)) {
						#if (ref($net->clients) eq 'ARRAY') {
							foreach my $client ( @{$net->clients} ) {
								if (exists($db_clients{$client->mac_address})) {
									if (&client_record_verified($client)) {
										print colored("UPDATE clients SET last_updated='$last_updated' WHERE mac_address='".$client->mac_address."'\n", "green");
									} else {
										# update changes (?)
									}
								} else {
									my $first_seen_c = $client->first_time;
									my $date_found_c;
									if ($first_seen_c =~ /(?:[a-zA-Z]+?) ([a-zA-Z]+?) (\d+) (\d+):(\d+):(\d+) (\d+)/) {
										my $mon = $1; my $day = $2; my $H = $3; my $M = $4; my $S = $5; my $y = $6;
										print "|$mon| $day $H $M $S $y \n" if (($verbose) and ($verbose > 1));
										$mon = $mon2num{$mon};
										$date_found_c = "$y/$mon/$day $H:$M:$S";
									} else {
										die colored("Didn't match date string ($first_seen_c) ", "bold red");
									}
								}
								print "INSERT INTO clients (mac_address,type,manufacturer,channel) VALUES ('".$client->mac_address."','".$client->type."','".$client->manufacturer."','".$client->channel."'\n";
							}
						#} else {
						#	warn colored("Network clients property not an array! (".ref($net->clients)."). Client count: ".$net->client_count.".", "bold red");
						#	print Dumper($net->clients);
						#	exit 1;
						#}
					}
				}
			}
		}
	} else {
		die colored("The specified input file appears to be zero (0) bytes ", "bold red");
	}
} else {
	die colored("Specified input file does not exist ", "bold red");
}

#print Dumper(\%db_networks);

###############################################################################
# Subs
###############################################################################
sub usage {

}

sub rtrim { my $s = shift; $s =~ s/^\s+//;       return $s; }
sub ltrim { my $s = shift; $s =~ s/\s+$//;       return $s; }
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s; }

sub pad_zero {
	my $n = shift;
	if ($n < 10) { return "0$n"; }
	else { return $n; }
}

sub get_networks {
	my $dbh	= DBI->connect($dsn, $user, $pass);
	my $sth = $dbh->prepare("SELECT distinct bssid FROM networks") or die $DBI::errstr;;
	$sth->execute() or die $DBI::errstr;
	while (my @row = $sth->fetchrow_array()) {
		$db_networks{$row[0]}++;
	}
	$sth->finish or die $DBI::errstr;
	$dbh->disconnect;
}

sub record_verified {
	my $n = shift;
	my $sql = "SELECT id FROM networks WHERE bssid='".$n->bssid."' AND essid='".$n->essid."' AND manufacturer='".$n->manufacturer."' AND encryption='".$n->encryption."' AND channel='".$n->channel."'";
	my $dbh	= DBI->connect($dsn, $user, $pass);
	#my $sth = $dbh->prepare($sql) or die $DBI::errstr;
	#my $rtv = $sth->execute() or die $DBI::errstr;
	#print colored("VERIFY RTV: $rtv \n", "yellow") if ($verbose);
	my $net_id = $dbh->selectrow_array($sql);
	#$sth->finish or die $DBI::errstr;
	$dbh->disconnect;
	if ((defined($net_id)) and ($net_id != 0)) {
		return 1;
	} else {
		return 0;
	}
}

sub get_net_id {
	my $bssid = shift;
	my $sql = "SELECT id FROM networks WHERE bssid='".$bssid."';";
	my $dbh	= DBI->connect($dsn, $user, $pass);
	my $net_id = $dbh->selectrow_array($sql);
	$dbh->disconnect;
	return $net_id;
}	

