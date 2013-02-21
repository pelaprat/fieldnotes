#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/scripts/set_site_activity.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use warnings;
use diagnostics;
use LCHC::Notes;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes;

## Set some variables
$lchc->set_db($db);
$db->set_pn($lchc);

my(%sqlOptions, %optionsOps);
my($query);
my(@sites, @fieldnotes, @activities);

## Get all the sites 
$query = $db->sql_site({}, {});
@sites = $db->complex_results($query);

my $count = 0;

foreach my $site (@sites) {
    ## Now get all the fieldnotes that have
    ##  this site as their id
    %sqlOptions = (site => $site->{id});
    $query      = $db->sql_fieldnote(\%sqlOptions, {});

    $count = scalar(@fieldnotes);
    @fieldnotes = $db->complex_results($query);

    my @list = ();
    foreach my $fieldnote (@fieldnotes) {
	push(@list, $fieldnote->{id});
    }

    my $list = join(',', @list);
    $query = ("select distinct activity from $db->{tnFieldnoteActivity} " .
	      "where fieldnote in ($list)");

    @activities = $db->complex_results($query);
    foreach my $activity (@activities) {
	if(! $db->site_activity_exists($site->{id}, $activity->{activity})) {
	    $query = ("insert into $db->{tnSiteActivity} values " .
		      " ($site->{id}, $activity->{activity})");
	    $db->do($query);
	}
    }

}

exit(0);
