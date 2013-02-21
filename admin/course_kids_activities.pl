#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/edit.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc   = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookieName});
my $submit     = $cgi->param('submit');
my $course     = $cgi->param('course');

my $kid_counter      = $cgi->param('kid-counter');
my $activity_counter = $cgi->param('activity-counter');

## Check parameter values
$user       = -1 if ! defined $user;
$submit     = '' if ! defined $submit;
$course     = -1 if ! defined $course;

$kid_counter      =  0 if ! defined $kid_counter;
$activity_counter =  0 if ! defined $activity_counter;

## Some variables
my(%sqlOptions, %menuOptions, %optionsOps);

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'admin/course_kids_activities.pl',
				   action => 'update',
			           target => 'kids_activities' } );

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));

####
## Now onto main part of the page
print $cgi->start_html({-title=>"Edit Kids and Activities for a Course",
			-style=>{-src=>$lchc->{uri_css}},
			-script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}}});

## Toolbar
$lchc->toolbar();


###########################
## Update if we need to. ##
if( $course > 0 && $submit eq 'Update the kids and activities' ) {

    ## First, delete the kid/activity
    ##  associations with the course
    $db->do("delete from $db->{tnCourseKid}      where course = $course");
    $db->do("delete from $db->{tnCourseActivity} where course = $course");

    ## Update the kids and activities
    ##  for this course.
    foreach my $lKid (1 .. $kid_counter) {
	my $k = $cgi->param("kid$lKid");
	if(defined $k && $k > 0 &&
	   $db->course_kid_exists($course, $k) == 0) {
	    $db->simple_add($db->{tnCourseKid}, ($course, $k));
	}
    }

    foreach my $lActivity (1 .. $activity_counter) {
	my $k = $cgi->param("activity$lActivity");
	if(defined $k && $k > 0 &&
	   $db->course_activity_exists($course, $k) == 0) {
	    $db->simple_add($db->{tnCourseActivity}, ($course, $k));
	}
    }
    

}

############
## Course ##
if( $course > 0 ) {

    ## Some variables for this administation panel
    my( $courseData      );
    my( @results, $query );

    ## Get course data
    %sqlOptions = ("$db->{tnCourse}.id" => $course);
    $courseData = $db->get_course(\%sqlOptions, {});

    ## Begin the kids/activities as a single pane of 2-columns
    print $cgi->start_center();
    print $cgi->start_form({-method=>'get', -action=>$lchc->{admin_course_kids_activities}});
    print $cgi->hidden({ -name => 'course', -value => $course });
    print $cgi->start_table({ -style => 'width: 640px; margin-bottom: 10px; padding-bottom: 10px'} );
    print $cgi->Tr( $cgi->td({ -style => 'border-bottom: 2px solid black;', -colspan => 2 },
			     $cgi->span({ -class => 'header' },
					( "$courseData->{program} $courseData->{number} - " .
					  "$courseData->{name} [$courseData->{quarter}    " .
					  "$courseData->{year}]                        "))));
    print $cgi->start_Tr();
    print $cgi->start_td({ -style => 'width: 310px; padding-top: 10px;' });

    ## Kids pane
    %sqlOptions = ( order => 'first', sort => 'asc' );
    $lchc->js_kid_menu( 'kid',{}, \%sqlOptions, {} );

    ## Now add each kid one by one who
    ##  is associated with the course.
    %sqlOptions = ( course => $course );
    $query      = $db->sql_course_kid(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    foreach my $row (@results) {
	print $cgi->script({ -language => 'javascript'}, "moreFields('kid', $row->{id})" );
    }

    print $cgi->end_td();
    print $cgi->start_td({ -style => 'margin-left: 20px; padding-left: 20px; padding-top: 10px; width: 320px' });

    ## Activities pane
    %sqlOptions  = (order => 'name', sort => 'asc');
    %menuOptions = (menuOnly => 1);

    $lchc->js_activity_menu( 'activity', \%menuOptions, \%sqlOptions, {} );

    ## Now add each activity one by one who
    ##  is associated with the course.
    %sqlOptions = (course => $course);
    $query      = $db->sql_course_activity(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    foreach my $row (@results) {
	print $cgi->script({-language=>'javascript'}, "moreFields('activity', $row->{activity})");
    }

    print $cgi->end_td();
    print $cgi->end_Tr();
    print $cgi->Tr( $cgi->td({ -colspan => 2 },
			     $cgi->br, $cgi->br,
			     $cgi->submit( -name  => 'submit', -value => 'Update the kids and activities',
					   -style => 'font-size: 18px; font-weight: bold' )));
    print $cgi->end_table();
    print $cgi->end_center();

    print $cgi->p, $cgi->p;
    print $cgi->br;
    print $cgi->br;
    print $cgi->br;

} else {

    ###########################
    ## Print current courses ##
    %optionsOps = ();
    %sqlOptions = ( current => 1, order => 'year', sort => 'desc' );
    print $cgi->start_center();
    print $cgi->start_div({ -style => 'width: 440px; text-align: left;' });
    print $cgi->span({ -class => 'header' }, 'Choose your course:' );
    print $cgi->p;
    &courses( $db->sql_course(\%sqlOptions, \%optionsOps) ); 
    print $cgi->end_div();
    print $cgi->end_center();
    print $cgi->p;
    print $cgi->br;
    print $cgi->br;
    print $cgi->br;

}

## End the general form and table
print $cgi->end_table();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);


sub courses( $ ) {
    my( $query ) = @_;

    ## Get the results and print the courses
    my @res = $db->complex_results($query);
    foreach my $row (@res) {

        my $text = "$row->{program} $row->{number} - $row->{name} [$row->{quarter} $row->{year}]";
	my $uri  = "course_activity_kids_map.php?course=$row->{id}&submit=edit";
        my $link = $cgi->a({-href=>"$uri"}, $text);

	print $cgi->div({ -style => ('font-size: 14px; font-family: Georgia, Time New Roman, sans-serif;    '  .
				     'font-weight: bold; background: #eeeeee; color: #99BB99; width: 425px; '  .
				     'margin-left:  0px; border: 2px solid #AABBAA; cursor: pointer;        '  .
				     'padding: 5px; text-align: center;'),
				     -onclick => "window.location = '$uri';" },
			$cgi->span({ -style => 'color: #black; font-weight: bold; font-family: Georgia' }, $text ));
				     print $cgi->p;
    }

}
