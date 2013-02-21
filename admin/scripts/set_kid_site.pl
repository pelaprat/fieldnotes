#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/scripts/set_kid_site.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;


my(%sqlOptions, %optionsOps);
my($query);
my(@kids, @fieldnotes);

## Get all the kids
$query = $db->sql_kid({}, {});
@kids  = $db->complex_results($query);

my $count = 0;

foreach my $kid (@kids) {
    ## Now get the sites this kid is listed in
    ##  by retrieving the fieldnotes he is in
    %sqlOptions = (kid => $kid->{id});
    $query      = $db->sql_fieldnote_kid(\%sqlOptions, {});
    @fieldnotes = $db->complex_results($query);

    print "Doing kid: $kid->{id}\n";
    foreach my $fieldnote (@fieldnotes) {
	if($fieldnote->{id} > 0) {
	    $query = ("update $db->{tnKid} set site=$fieldnote->{site} " .
		      "where id=$kid->{id}");
	    $db->do($query);
	}
    }
}

exit(0);
