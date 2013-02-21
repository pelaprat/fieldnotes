#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/scripts/make_attachment_space.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;

my( %sqlOptions, %optionsOps   );
my( $query, @courses, @results );

## Get all the kids
$query   = $db->sql_course( {}, {} );
@courses = $db->complex_results( $query );

foreach my $course ( @courses ) {


    ##########################################################
    ## Check to see if this course has an attachment space. ##
    %sqlOptions = ( course => $course->{id}, type => 1 );
    $query      = $db->sql_course_space( %sqlOptions );
    @results    = $db->complex_results( $query );

    if( scalar( @results ) <= 0 ) {

	######################
	## Make a new space ##
	my $attachment = $db->simple_add( $db->{tvSpace},
					  ( 'null', "'$course->{name}-attachment'", -1, "''", 0 ));

	###################################################
	## Link it to the course as an attachment space. ##
	my $linkage_id = $db->simple_add( $db->{tvCourseSpace}, ( $course->{id}, $attachment, 1 ))
	    if( $attachment > 0 );

    } else {
	print "Got one for $course->{id}\n";
    }

}

exit(0);
