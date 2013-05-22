#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/synchronize/rosters.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/home/lchc'; }

use strict;
use LCHC::SQL::Notes;

## Build the basic objects
my $db   = new LCHC::SQL::Notes;



my $query   = "select id from $db->{tnCourse}";
my @courses = $db->simple_one_field_results($query);
foreach my $course (@courses) {
    my $query   = ("select person from $db->{tnFieldnote} " .
		   "where course=$course group by person  ");
    my @persons = $db->simple_one_field_results($query);

    foreach my $person (@persons) {
	if($db->person_course_exists($person, $course) == 0) {
	    $db->do("insert into $db->{tnPersonCourse} values($person, $course)");
	}
    }
}



exit(0);
