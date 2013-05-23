#!/usr/bin/perl -w

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
my(@confs, $query);

## Get all the kids
$query = $db->sql_conference({}, {});
@confs  = $db->complex_results($query);

foreach my $conf (@confs) {
    my $tnConference = $db->{tnConference};

    $query    = "select count(*) from tn_fieldnote where conference=$conf->{id}";
    my @count = $db->simple_one_field_results($query);
    my $count = pop @count;

    $db->do("update $tnConference set items=$count where id=$conf->{id}");
}

exit(0);
