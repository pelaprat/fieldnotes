#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/insert.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use strict;
use CGI;
use LCHC::Notes;
use LCHC::SQL::Notes;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $vftp = new LCHC::SQL::Vftp;
my $lchc = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_reg});
my $what = $cgi->param('what');

my $person  = $cgi->param('person');
my $program = $cgi->param('program');
my $number  = $cgi->param('number');
my $name    = $cgi->param('name');
my $quarter = $cgi->param('quarter');
my $year    = $cgi->param('year');
my $current = $cgi->param('current');

my $course    = $cgi->param('course');
my $fieldnote = $cgi->param('fieldnote');

my $first      = $cgi->param('first');
my $middle     = $cgi->param('middle');
my $last       = $cgi->param('last');
my $age        = $cgi->param('age');
my $gender     = $cgi->param('gender');
my $email      = $cgi->param('email');
my $pass       = $cgi->param('pass');
my $admin      = $cgi->param('admin');
my $instructor = $cgi->param('instructor');
my $undergrad  = $cgi->param('undergrad');
my $site       = $cgi->param('site');
my $birthdate  = $cgi->param('birthdate');

## Check parameter values
$user = -1 if ! defined $user;
$what = '' if ! defined $what;

$person  = -1 if ! defined $person;
$program = '' if ! defined $program;
$number  = -1 if ! defined $number;
$name    = '' if ! defined $name;
$quarter = '' if ! defined $quarter;
$year    = -1 if ! defined $year;
$current = 0  if ! defined $current;

$course    = -1 if ! defined $course;
$fieldnote =  0 if ! defined $fieldnote;

$first      = ''  if ! defined $first;
$middle     = ''  if ! defined $middle;
$last       = ''  if ! defined $last;
$age        = 0   if (! defined $age || $age eq '');
$gender     = 'm' if ! defined $gender;
$email      = ''  if ! defined $email;
$pass       = ''  if ! defined $pass;
$admin      =  0  if ! defined $admin;
$instructor =  0  if ! defined $instructor;
$undergrad  =  0  if ! defined $undergrad;
$site       = -1 if ! defined $site;
$birthdate  = '0000-00-00' if ! defined $birthdate;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'admin/insert.pl',
				   action => 'insert',
			           target => $what } );

## Access control, we are the index
$lchc->control_access((admin => 1, insert => 1, header => 0));



## Add a course?
if($what eq 'course' && $person > 0 && $program ne '' &&
   $number > 0       && $name ne '' && $quarter ne '' &&
   $year > 0         && $current > -1) {

    my $attach = -1;

    # Safe quote some variables
    $name    = $lchc->safe_single_quotes($name);
    $quarter = $lchc->safe_single_quotes($quarter);

    $course = $db->simple_add($db->{tnCourse},
			      ('null', $person, "'$program'", $number,
			       "'$name'", "'$quarter'", $year, $current));


    ##################################################
    ## THEN ADD THE ATTACHMENT SPACE FOR THE COURSE ##
    my $space = -1;

    $space  = $db->simple_add($vftp->{tvSpace}, ('null', "'$name-attachment'", -1, "''", 0));
    $attach = $db->simple_add($vftp->{tvCourseSpace}, ( $course, $space, 1 )) if($space > 0);

}

## Add a conference?
if($what eq 'conference' && $course > 0 && $name ne '' && $fieldnote > -1) {

    # Safe quote some variables
    $name = $lchc->safe_single_quotes($name);

    $db->simple_add($db->{tnConference},
		    ('null', $course, "'$name'", $fieldnote, 0));
}

## Add a person?
if($what eq 'person' && $first ne ''  && $last ne ''   &&
   $email ne ''      && $age  >= 0    && $gender ne '' &&
   $undergrad > -1   && $pass ne ''   && $admin > -1   &&
   $instructor > -1) {

    # Safe quote some variables
    $first  = $lchc->safe_single_quotes($first);
    $middle = $lchc->safe_single_quotes($middle);
    $last   = $lchc->safe_single_quotes($last);
    $email  = $lchc->safe_single_quotes($email);
    $pass   = $lchc->safe_single_quotes($pass);

    $db->simple_add($db->{tPerson}, ('null', "'$first'", "'$middle'", "'$last'",
				      $age, "'$gender'", "'$email'", "md5('$pass')",
				      $admin, $instructor, $undergrad, 'NOW()' ));

}

## Add a kid?
if($what eq 'kid' && $first ne '' && $gender ne '') {

    # Safe quote some variables
    $first     = $lchc->safe_single_quotes($first);
    $last      = $lchc->safe_single_quotes($last);
    $birthdate = $lchc->safe_single_quotes($birthdate);

    $db->simple_add($db->{tnKid}, ('null', "'$first'", "'$last'", 
				   "'$gender'", $site, "'$birthdate'", 'NOW()' ));
}

## Add a site?
if($what eq 'site' && $name ne '') {
    $name = $lchc->safe_single_quotes($name);
    $db->simple_add($db->{tnSite}, ('null', "'$name'", 'NOW()' ));
}

## Add an activity?
if($what eq 'activity' && $name ne '') {
    $name = $lchc->safe_single_quotes($name);
    $db->simple_add($db->{tnActivity}, ('null', "'$name'", 'NOW()' ));
}

## Add a space?
if($what eq 'space' && $name ne '' && $course > 0) {
    my $space = -1;

    $name  = $lchc->safe_single_quotes($name);
    $space = $db->simple_add($vftp->{tvSpace}, ('null', "'$name'", -1, "''", 0));

    $db->simple_add($vftp->{tvCourseSpace}, ($course, $space, 2)) if($space > 0);
}

print $cgi->redirect({-location=>$lchc->{admin_index}});

exit(0);
