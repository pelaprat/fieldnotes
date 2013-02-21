#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/synchronize/site_sync_with_kids_and_activities.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;

#####################
## Some variables. ##
my %sites = ();
my $nulls = 0;

#####################
## Read the sites. ##
my $query   = 'select id, name from t_site';
my @results = $db->complex_results( $query );
foreach my $row ( @results ) {
    $sites{$row->{name}} = { id         => $row->{id},
			     kids       => [],
			     activities => [] };
}

######################
## Delete old data. ##
$db->do( 'delete from tnSiteKid'      );
$db->do( 'delete from tnSiteActivity' );

#######################
## Get all the kids. ##
$query   = ( 'select kid, t_site.name as "name" from t_fieldnote_kid                 ' .
	     ' left join tn_fieldnote on t_fieldnote_kid.fieldnote = tn_fieldnote.id ' .
	     ' left join t_site on tn_fieldnote.site = t_site.id                     ');
@results = $db->complex_results( $query );
foreach my $row ( @results ) {
    if( defined $row->{name} ) {
	my $site = $sites{$row->{name}};
	my $kids = $site->{kids};
	push( @$kids, $row->{kid} );
    } else {

	##############################################################
	## These are if the site name is undefined for this kid.    ##
	## It doesn't check to see if the fieldnote is still valid. ##
	$nulls++;
    }
}

#############################
## Get all the activities. ##
$query   = ( 'select activity, t_site.name as "name" from t_fieldnote_activity                 ' .
	     ' left join tn_fieldnote on t_fieldnote_activity.fieldnote = tn_fieldnote.id ' .
	     ' left join t_site on tn_fieldnote.site = t_site.id                     ');
@results = $db->complex_results( $query );
foreach my $row ( @results ) {
    if( defined $row->{name} ) {
	my $site       = $sites{$row->{name}};
	my $activities = $site->{activities};
	push( @$activities, $row->{activity} );
    } else {

	################################################################
	## These are if the site name is undefined for this activity. ##
	## It doesn't check to see if the fieldnote is still valid.   ##
	$nulls++;
    }
}

###############################################
## Now go through each site and make         ##
##  unique lists for the kids and activities ##
##  and put them in the database.            ##
foreach my $site ( keys ( %sites ) ) {
    my $site_id    = $sites{$site}->{id};
    my $kids       = $sites{$site}->{kids};
    my $activities = $sites{$site}->{activities};

    #################
    ## First kids. ##
    my @saw         = undef;
    my @ukids       = grep(!$saw[$_]++, @$kids);
    foreach my $kid ( @ukids ) {
	$db->simple_add( 'tnSiteKid', ( $site_id, $kid ));
    }

    ######################
    ## Then activities. ##
       @saw         = undef;
    my @uactivities = grep(!$saw[$_]++, @$activities);
    foreach my $activity ( @uactivities ) {
	$db->simple_add( 'tnSiteActivity', ( $site_id, $activity ));
    }

}

print "Number of site nulls: $nulls\n";

exit(0);
