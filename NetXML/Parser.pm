package NetXML::Parser;

use strict;
use warnings;
use Term::ANSIColor;
use Data::Dumper;

use lib "./";
use NetXML::Wireless::Network;

our @EXPORT		=	qw( parsefile );
our @EXPORT_OK	=	qw( );
{
	$NetXML::Parser::VERSION = '0.0.1';
}


