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

#############################
## Get all the fieldnotes. ##
my $query = ( " select to_days(dateofvisit)     as d,    " .
	      "   tn_fieldnote.id               as fid,  " .
	      "   tn_fieldnote.person           as pid,  " .
	      "   tn_fieldnote.site             as sid,  " .
	      "   t_fieldnote_kid.kid           as kid,  " .
	      "   t_fieldnote_activity.activity as actid " .
	      "   from tn_fieldnote " .
	      "   left join t_fieldnote_activity on tn_fieldnote.id = t_fieldnote_activity.fieldnote " .
	      "   left join t_fieldnote_kid on tn_fieldnote.id      = t_fieldnote_kid.fieldnote" );

my @fieldnotes  = $db->complex_results($query);

my %persons    = ();
my %sites      = ();
my %kids       = ();
my %activities = ();

foreach my $fieldnote ( @fieldnotes ) {

    #############
    ## Persons ##
    if( defined $fieldnote->{pid} && $fieldnote->{pid} > 0 && 
	defined $fieldnote->{d}   && $fieldnote->{d}   > 0 ) {
	if( defined $persons{$fieldnote->{pid}} ) {
	    if( $fieldnote->{d} > $persons{$fieldnote->{pid}} ) {
		$persons{$fieldnote->{pid}} = $fieldnote->{d};
	    }
	} else {
	    $persons{$fieldnote->{pid}} = $fieldnote->{d};
	}
    }

    ###########
    ## Sites ##
    if( defined $fieldnote->{sid} && $fieldnote->{sid} > 0 && 
	defined $fieldnote->{d}   && $fieldnote->{d}   > 0 ) {
	if( defined $sites{$fieldnote->{sid}} ) {
	    if( $fieldnote->{d} > $sites{$fieldnote->{sid}} ) {
		$sites{$fieldnote->{sid}} = $fieldnote->{d};
	    }
	} else {
	    $sites{$fieldnote->{sid}} = $fieldnote->{d};
	}
    }

    ##########
    ## Kids ##
    if( defined $fieldnote->{kid} && $fieldnote->{kid} > 0 &&
	defined $fieldnote->{d}   && $fieldnote->{d}   > 0 ) {
	if( defined $kids{$fieldnote->{kid}} ) {
	    if( $fieldnote->{d} > $kids{$fieldnote->{kid}} ) {
		$kids{$fieldnote->{kid}} = $fieldnote->{d};
	    }
	} else {
	    $kids{$fieldnote->{kid}} = $fieldnote->{d};
	}
    }

    ################
    ## Activities ##
    if( defined $fieldnote->{actid} && $fieldnote->{actid} > 0 &&
	defined $fieldnote->{d}     && $fieldnote->{d}   > 0 ) {
	if( defined $activities{$fieldnote->{actid}} ) {
	    if( $fieldnote->{d} > $activities{$fieldnote->{actid}} ) {
		$activities{$fieldnote->{actid}} = $fieldnote->{d};
	    }
	} else {
	    $activities{$fieldnote->{actid}} = $fieldnote->{d};
	}
    }


}

print "Done getting all the data.\n";

print "Now entering person reference data.\n";
foreach my $pid ( keys(%persons) ) {
    my $day = $persons{$pid};
    $db->do( "update t_person set last_activity = from_days( $day ) where id = $pid");
}

print "Now entering site reference data.\n";
foreach my $sid ( keys(%sites) ) {
    my $day = $sites{$sid};
    $db->do( "update t_site set last_referenced = from_days( $day ) where id = $sid");
}

print "Now entering kids reference data.\n";
foreach my $kid ( keys(%kids) ) {
    my $day = $kids{$kid};
    $db->do( "update t_kid set last_referenced = from_days( $day ) where id = $kid");
}

print "Now entering activities reference data.\n";
foreach my $actid ( keys(%activities) ) {
    my $day = $activities{$actid};
    $db->do( "update t_activity set last_referenced = from_days( $day ) where id = $actid");
}

exit(0);
