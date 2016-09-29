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
&get_clients();

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
						warn colored("Network exists but not verified! ", "bold red");
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
					my $netsql = "";
					if ($net->essid =~ /\\/) {
						my $tmpessid = $net->essid;
						$tmpessid =~ s/\\/\\\\/g;
						$netsql = "INSERT INTO networks (bssid,essid,date_found,last_updated,num_clients,encryption,max_rate,type,channel,manufacturer,cloaked,frequency) VALUES ('".$net->bssid."','".$tmpessid."','$date_found','$last_updated','".$net->client_count."','".$net->encryption."','".$net->max_rate."','".$net->type."','".$net->channel."','".$net->manufacturer."','".$net->is_cloaked."','".$net->frequency."')";
					} else {
						$netsql = "INSERT INTO networks (bssid,essid,date_found,last_updated,num_clients,encryption,max_rate,type,channel,manufacturer,cloaked,frequency) VALUES ('".$net->bssid."','".$net->essid."','$date_found','$last_updated','".$net->client_count."','".$net->encryption."','".$net->max_rate."','".$net->type."','".$net->channel."','".$net->manufacturer."','".$net->is_cloaked."','".$net->frequency."')";
					}
					print "$netsql \n";
					my $sth = $dbh->prepare($netsql) or die $DBI::errstr;
					my $rtv = $sth->execute() or die $DBI::errstr;
					print colored("INSERT RTV: $rtv \n", "bold yellow") if ($verbose);
					$sth->finish;
					&get_networks();
				}
				my $net_id = &get_net_id($net->bssid);
				if ($net->client_count > 0) {
					if (defined($net->clients)) {
						foreach my $client ( @{$net->clients} ) {
							if (exists($db_clients{$client->mac_address})) {
								if (&client_record_verified($client)) {
									print colored("UPDATE clients SET last_updated='$last_updated' WHERE mac_addr='".$client->mac_address."'\n", "green");
									my $sth = $dbh->prepare("UPDATE clients SET last_updated='$last_updated' WHERE mac_addr='".$client->mac_address."'") or die $DBI::errstr;
									my $rtv = $sth->execute() or die $DBI::errstr;
									print colored("UPDATE CLIENT RTV: $rtv \n", "magenta") if ($verbose);
									$sth->finish or die $DBI::errstr;
								} else {
									# update changes (?)
									warn colored("Client not verified: ".$client->mac_address."! ", "bold red");
									&diff_client($client);
									#exit 1;
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
									my $man = $client->manufacturer;
									$man =~ s/,/\\,/g;
									print "INSERT INTO clients (mac_addr,type,manufacturer,channel,first_found,last_updated) VALUES ('".$client->mac_address."','".$client->type."','".$man."','".$client->channel."','$date_found_c','$last_updated');\n";
									my $sth = $dbh->prepare("INSERT INTO clients (mac_addr,type,manufacturer,channel,first_found,last_updated) VALUES ('".$client->mac_address."','".$client->type."','".$man."','".$client->channel."','$date_found_c','$last_updated');") or die $DBI::errstr;
									my $rtv = $sth->execute or die $DBI::errstr;
									print colored("INSERT CLIENT RTV: $rtv \n", "bold yellow") if ($verbose);
									$sth->finish;
									&get_clients();
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
								my $man = $client->manufacturer;
								$man =~ s/,/\\,/g;
								print "INSERT INTO clients (mac_addr,type,manufacturer,channel,first_found,last_updated) VALUES ('".$client->mac_address."','".$client->type."','".$man."','".$client->channel."','$date_found_c','$last_updated');\n";
								my $sth = $dbh->prepare("INSERT INTO clients (mac_addr,type,manufacturer,channel,first_found,last_updated) VALUES ('".$client->mac_address."','".$client->type."','".$man."','".$client->channel."','$date_found_c','$last_updated');") or die $DBI::errstr;
								my $rtv = $sth->execute or die $DBI::errstr;
								print colored("INSERT CLIENT RTV: $rtv \n", "bold yellow") if ($verbose);
								$sth->finish;
								&get_clients();
							}
							my $cid = &get_client_id($client->mac_address);
							my $rid = &get_relation_id($net_id, $cid);
							if (defined($rid)) {
								print colored("Relation exists.\n", "cyan");
							} else {
								my $sth = $dbh->prepare("INSERT INTO network_clients (net_id,client_id) VALUES ('$net_id','$cid')");
								$sth->execute() or die $DBI::errstr;
								$sth->finish or die $DBI::errstr;
								$rid = &get_relation_id($net_id, $cid);
							}
						}
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
#print Dumper(\%db_clients);

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
	my $sth = $dbh->prepare("SELECT distinct bssid FROM networks") or die $DBI::errstr;
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
	if ((defined($net_id)) and ($net_id != 0)) { return 1; } 
	else { return 0; }
}

sub get_net_id {
	my $bssid = shift;
	my $sql = "SELECT id FROM networks WHERE bssid='".$bssid."';";
	my $dbh	= DBI->connect($dsn, $user, $pass);
	my $net_id = $dbh->selectrow_array($sql);
	$dbh->disconnect;
	return $net_id;
}	

sub get_clients {
	my $dbh	= DBI->connect($dsn, $user, $pass);
	my $sth = $dbh->prepare("SELECT DISTINCT mac_addr FROM clients") or die $DBI::errstr;
	$sth->execute() or die $DBI::errstr;
	while (my @row = $sth->fetchrow_array()) {
		$db_clients{$row[0]}++;
	}
	$sth->finish or die $DBI::errstr;
	$dbh->disconnect;
}

sub client_record_verified {
	my $c = shift;
	my $sql = "SELECT id FROM clients WHERE mac_addr='".$c->mac_address."' AND manufacturer='".$c->manufacturer."' AND channel='".$c->channel."' AND type='".$c->type."'";
	my $dbh	= DBI->connect($dsn, $user, $pass);
	my $client_id = $dbh->selectrow_array($sql);
	$dbh->disconnect;
	if ((defined($client_id)) and ($client_id != 0)) { return 1; }
	else { return 0; }
}

sub get_client_id {
	my $mac_addr = shift;
	my $sql = "SELECT id FROM clients WHERE mac_addr='$mac_addr'";
	my $dbh = DBI->connect($dsn, $user, $pass);
	my $client_id = $dbh->selectrow_array($sql);
	$dbh->disconnect;
	return $client_id;
}

sub get_relation_id {
	my ($nid, $cid) = @_;
	my $sql = "SELECT id FROM network_clients WHERE net_id='$nid' AND client_id='$cid'";
	my $dbh = DBI->connect($dsn, $user, $pass);
	my $relid = $dbh->selectrow_array($sql);
	$dbh->disconnect;
	return $relid;
}

sub diff_client {
	my $c = shift;
	my $sql = "SELECT mac_addr,manufacturer,type,channel FROM clients where mac_addr='".$c->mac_address."'";
	my $dbh = DBI->connect($dsn, $user, $pass);
	my $sth = $dbh->prepare($sql) or die $DBI::errstr;
	my $rtv = $sth->execute() or die $DBI::errstr;
	print ("DIFF RTV: $rtv \n", "bold cyan");
	my ($dmac,$dmanuf,$dtype,$dchan);
	while (my @row = $sth->fetchrow_array()) {
		($dmac,$dmanuf,$dtype,$dchan) = @row;
	}
	print $c->mac_address." | $dmac \n";
	print $c->manufacturer." | $dmanuf \n";
	print $c->type." | $dtype \n";
	print $c->channel." | $dchan \n";
}
