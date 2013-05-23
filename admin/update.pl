#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/update.pl
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
my $user = $cgi->cookie($lchc->{cookie_name_reg});
my $what       = $cgi->param('what');
my $course     = $cgi->param('course');
my @conference = $cgi->param('conference');
my $person     = $cgi->param('person');
my $kid        = $cgi->param('kid');
my $site       = $cgi->param('site');
my $activity   = $cgi->param('activity');

my $kid_counter      = $cgi->param('kid-counter');
my $activity_counter = $cgi->param('activity-counter');

my $program = $cgi->param('program');
my $number  = $cgi->param('number');
my $name    = $cgi->param('name');
my $quarter = $cgi->param('quarter');
my $year    = $cgi->param('year');
my $current = $cgi->param('current');

my $first      = $cgi->param('first');
my $middle     = $cgi->param('middle');
my $last       = $cgi->param('last');
my $age        = $cgi->param('age');
my $gender     = $cgi->param('gender');
my $email      = $cgi->param('email');
my $admin      = $cgi->param('admin');
my $instructor = $cgi->param('instructor');
my $undergrad  = $cgi->param('undergrad');
my $birthdate  = $cgi->param('birthdate');

## Check parameter values
$user   = -1 if ! defined $user;
$what   = '' if ! defined $what;
$course = -1 if ! defined $course;
$person = -1 if ! defined $person;
$kid    = -1 if ! defined $person;

$program = '' if ! defined $program;
$number  = -1 if ! defined $number;
$name    = '' if ! defined $name;
$quarter = '' if ! defined $quarter;
$year    = -1 if ! defined $year;
$current = 0  if ! defined $current;

@conference = () if ! defined @conference;

$first      = ''  if ! defined $first;
$middle     = ''  if ! defined $middle;
$last       = ''  if ! defined $last;
$gender     = 'm' if ! defined $gender;
$age        =  0  if ! defined $age;
$email      = ''  if ! defined $email;
$admin      =  0  if ! defined $admin;
$instructor =  0  if ! defined $instructor;
$undergrad  =  0  if ! defined $undergrad;
$birthdate  = '0000-00-00' if ! defined $birthdate;

$kid_counter      =  0 if ! defined $kid_counter;
$activity_counter =  0 if ! defined $activity_counter;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'admin/update.pl',
				   action => 'update',
			           target => $what } );

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>0));



## Update a course?
if($what eq 'course' && $course > 0 && $person > 0 && $program ne '' && $number > 0 &&
   $name ne '' && $quarter ne '' && $year > 0 && $current > -1) {
    my($query);

    ## Safe quote some variables
    $name    = $lchc->safe_single_quotes($name);
    $quarter = $lchc->safe_single_quotes($quarter);

    ## Now update the general properties for the course
    $query = ("update $db->{tnCourse} set instructor=$person, program='$program', number=$number, " .
	      "                           name='$name', quarter='$quarter',   " .
	      "                           year=$year, current=$current        " .
	      " where id=$course");

    $db->do($query);
}

## Update a conference or set of conferences?
if($what eq 'conference' && scalar(@conference) > 0) {
    foreach my $conference (@conference) {
	my $fieldnote = $cgi->param("$conference\.fieldnote");
	my $name      = $cgi->param("$conference\.name");

	$fieldnote = 0  if ! defined $fieldnote;
	$name      = '' if ! defined $name;

	$name = $lchc->safe_single_quotes($name);

	if($name ne '') {
	    my $query = ("update $db->{tnConference} set fieldnote=$fieldnote, name='$name' " .
		       "where id=$conference");
	    $db->do($query);
	}
    }
}

## Update a person?
if($what eq 'person' && $person > 0 && $first ne ''  && $last ne '' &&
   $email ne '' && $admin > -1 && $instructor > -1) {

    # Safe quote some variables
    $first  = $lchc->safe_single_quotes($first);
    $middle = $lchc->safe_single_quotes($middle);
    $last   = $lchc->safe_single_quotes($last);
    $email  = $lchc->safe_single_quotes($email);

    my $query = ("update $db->{tPerson} set first='$first', middle='$middle',     " .
	       "                          last='$last', email='$email',         " .
	       "                          age=$age, gender='$gender',           " .
	       "                          admin=$admin, instructor=$instructor, " .
	       "                          undergrad=$undergrad                  " .
	       " where id=$person");

    $db->do($query);

}

## Update a kid?
if($what eq 'kid' && $kid > 0 && $first ne ''  && $last ne '' &&
   $site > 0 && $gender ne '') {

    # Safe quote some variables
    $first = $lchc->safe_single_quotes($first);
    $last  = $lchc->safe_single_quotes($last);
    $birthdate = $lchc->safe_single_quotes($birthdate);

    my $query = ("update $db->{tnKid} set first='$first', last='$last',   " .
		 "                         site=$site,  gender='$gender', " .
		 "                        birthdate = '$birthdate'            " .
		 " where id=$kid");

    $db->do($query);

}

## Update a site?
if($what eq 'site' && $site > 0 && $name ne '') {
    $name = $lchc->safe_single_quotes($name);
    my $query = "update $db->{tnSite} set name='$name' where id=$site";
    $db->do($query);
}

## Update a activity?
if($what eq 'activity' && $activity > 0 && $name ne '') {
    $name = $lchc->safe_single_quotes($name);
    my $query = "update $db->{tnActivity} set name='$name' where id=$activity";
    $db->do($query);
}

print $cgi->redirect({-location=>$lchc->{admin_index}});

exit(0);
