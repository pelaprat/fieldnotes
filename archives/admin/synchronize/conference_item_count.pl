#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/synchronize/conference_item_count.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/home/lchc'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;

## Set all items to zero before recounting
$db->do("update $db->{tnConference} set items=0");

## Now grab the fieldnotes in question, count, and set.
my $query   = "select conference, count(id) as items from $db->{tnFieldnote} group by conference";
my @results = $db->complex_results($query);
foreach my $res (@results) {
    my($id, $items) = ($res->{conference}, $res->{items});
    print "update $db->{tnConference} set items=$items where id=$id\n";
    $db->do("update $db->{tnConference} set items=$items where id=$id");
}

exit(0);
