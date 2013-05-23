#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/course.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes( 'archives' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_arc});
my $submit        = $cgi->param('submit');
my $course        = $cgi->param('course');
my $person        = $cgi->param('person');
my @person_add    = $cgi->param('person_add');
my @person_delete = $cgi->param('person_delete');

## Check parameter values
$user          = -1 if ! defined $user;
$submit        = '' if ! defined $submit;
$course        = -1 if ! defined $course;
$person        = -1 if ! defined $person;
@person_add    = () if ! defined @person_add;
@person_delete = () if ! defined @person_delete;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

####
## First see if we need to make any additions or deletions
if($course > 0 && ($submit eq 'delete' || $submit eq 'add')) {
    ## Access control, since we are not printing
    $lchc->control_access((index=>0, admin=>1, header=>0));

    foreach my $person (@person_delete) {
	print "person delete: $person\n";
	    $db->do("delete from $db->{tnPersonCourse} where person=$person and course=$course");
    }

    foreach my $person (@person_add) {
	if($person > 0 && $db->person_course_exists($person, $course) == 0) {
	    $db->simple_add($db->{tnPersonCourse}, ($person, $course));
	}
    }

    print $cgi->redirect({-location=>"$lchc->{admin_course}?course=$course&submit=select"});
    exit(0);

} else {
    ## Access control, since we are printing
    $lchc->control_access((index=>0, admin=>1, header=>1));
}

####
## Now onto main part of the page
print $cgi->start_html({-title=>"Class List", -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

## Print the general form first, and the table IF we are editing
print $cgi->start_form({-method=>'post', -action=>$lchc->{admin_course}});

############
## Course ##
if($submit eq '' && $course <= 0) {
    my %sqlOptions = (order => 'year', sort => 'desc');
    print $cgi->start_div({-class=>'box'});
    print $cgi->start_table();
    print $cgi->Tr($cgi->td('Course: '),
		   $cgi->td($lchc->course_menu('course', {}, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td(),
		   $cgi->td($cgi->submit({-name=>'submit', -value=>'select'})));
    print $cgi->end_table();
    print $cgi->end_div();
}

if($submit eq 'select' && $course > 0) {
    my %menuOptions = ();
    my %sqlOptions  = (id => $course);

    ## Supply the course id
    print $cgi->hidden({-name=>'course', -value=>$course});

    ## Structure table
    print $cgi->start_table();
    print $cgi->start_Tr();
    print $cgi->start_td();

    ## Print the people in the class
    ## Get the existing people in the class
    %sqlOptions = (course => $course);
    my $sql = $db->sql_person_course(\%sqlOptions, {});
    my @res = $db->complex_results($sql);
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Class Listing');
    print $cgi->start_table();
    foreach my $row (@res) {
	if($row->{person} > 0) {
	    print $cgi->Tr($cgi->td($cgi->checkbox({-name=>'person_delete', -label=>'', -value=>$row->{person}}),
				    "$row->{first} $row->{middle} $row->{last} &lt;$row->{email}&gt;"));
	}
    }
    print $cgi->end_table();
    print $cgi->submit({-name=>'submit', -value=>'delete'});
    print $cgi->end_div();

    ## Structure table
    print $cgi->end_td();
    print $cgi->start_td({-style=>'padding-left:9px'});

    ## Print the form to add people
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add People to Class');
    print $cgi->start_table();
    for (1 .. 10) {
	%sqlOptions  = (order => 'last', sort => 'asc');
	%menuOptions = (empty => 1);
	print $cgi->Tr($cgi->td($lchc->person_menu('person_add', \%menuOptions, \%sqlOptions, {})));
    }
    print $cgi->end_table();
    print $cgi->submit({-name=>'submit', -value=>'add'});
    print $cgi->end_div();

    ## End structure table
    print $cgi->end_td();
    print $cgi->end_Tr();
    print $cgi->end_table();
}


## End the general form and table
print $cgi->end_form();
print $cgi->end_table();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
