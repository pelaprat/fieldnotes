#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/synchronize/dates.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;


###########################################
## Get fieldnotes with no date of visit. ##
my $query   = ( "select id, dateofvisit, timestamp from tn_fieldnote " .
		" where dateofvisit = '0000-00-00 00:00:00'          ");
my @results = $db->complex_results( $query );

####################################
## Go through each bad fieldnote. ##
foreach my $row ( @results ) {

    ########################
    ## Replacement query. ##
    $query = "update tn_fieldnote set dateofvisit = '$row->{timestamp}' where id = $row->{id}";
    $db->do( $query );

}

exit(0);
