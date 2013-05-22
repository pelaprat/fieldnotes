#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/edit.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/Users/web/perl'; }

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
my $user = $cgi->cookie('lchcarchives');
my $what       = $cgi->param('what');
my $submit     = $cgi->param('submit');
my $course     = $cgi->param('course');
my $conference = $cgi->param('conference');
my $person     = $cgi->param('person');
my $kid        = $cgi->param('kid');
my $site       = $cgi->param('site');
my $activity   = $cgi->param('activity');

## Check parameter values
$user       = -1 if ! defined $user;
$what       = '' if ! defined $what;
$submit     = '' if ! defined $submit;
$course     = -1 if ! defined $course;
$conference = -1 if ! defined $conference;
$person     = -1 if ! defined $person;
$kid        = -1 if ! defined $kid;
$site       = -1 if ! defined $site;
$activity   = -1 if ! defined $activity;

## Some variables
my(%sqlOptions, %menuOptions, %optionsOps);

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));



####
## Now onto main part of the page
print $cgi->start_html({-title=>"Edit $what",
			-style=>{-src=>$lchc->{uri_css}},
			-script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}}});

## Toolbar
$lchc->toolbar();

## Print the general form first, and
##   the table IF we are editing.
if($submit eq '') {
    print $cgi->start_form({-method=>'get', -action=>$lchc->{admin_edit}});
} elsif($submit eq 'edit') {
    print $cgi->start_form({-method=>'get', -action=>$lchc->{admin_update}});
}
print $cgi->hidden({-name=>'what', -value=>$what});

############
## Course ##
if($what eq 'course' && $submit eq '' && $course <= 0) {
    %sqlOptions = (order=>'id', sort=>'desc');
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select course');
    print $lchc->course_menu('course', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'edit'});
    print $cgi->submit({-name=>'submit', -value=>'delete'});
    print $cgi->br;
    print $cgi->end_div();

}

if($what eq 'course' && $submit eq 'edit' && $course > 0) {
    ## Some variables for this administation panel
    my($courseData, $personMenu, $quarterMenu, $yearMenu);
    my(@results, $query);

    ## Get course data
    %sqlOptions = ("$db->{tnCourse}.id" => $course);
    $courseData = $db->get_course(\%sqlOptions, {});

    ## Set up the various menus
    %sqlOptions  = (instructor => 1);
    %menuOptions = (selected => $courseData->{instructor}, selectedOp => '==');
    $personMenu  = $lchc->person_menu('person', \%menuOptions, \%sqlOptions, {});

    %menuOptions = (selected => $courseData->{quarter}, selectedOp => 'eq');
    $quarterMenu = $lchc->quarter_menu('quarter', \%menuOptions);

    %menuOptions = (selected => $courseData->{year}, selectedOp => '==');
    $yearMenu    = $lchc->year_menu('year', \%menuOptions);

    ## Supply the course id
    print $cgi->hidden({-name=>'course', -value=>$course});

    ## Print the main table properties
    ##  that can be edited

    ## Course property pane
    print $cgi->start_div({-class=>'box', -style=>'float: left; width: 380px; clear: both; margin-bottom: 10px'});
    print $cgi->div({-class=>'box-title'}, 'Edit course properties');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Instructor:'),
		   $cgi->td({-class=>'value'}, $personMenu));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Program:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'program', -size=>6, -value=>$courseData->{program}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course Number:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'number', -size=>4, -value=>$courseData->{number}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course Name:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>$courseData->{name}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Quarter:'),
		   $cgi->td({-class=>'value'}, $quarterMenu));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Year'),
		   $cgi->td({-class=>'value'}, $yearMenu));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Current Course?'),
		   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'current', -value=>1,
							       -label=>'', -checked=>$courseData->{current}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, ''),
		   $cgi->td({-class=>'value'}, $cgi->submit({-name=>'submit', -value=>'update', -style=>'clear:both; margin-left: 5px;'})));

    print $cgi->end_table();
    print $cgi->end_div();

    ## Begin the kids/activities as a single pane of 2-columns
    print $cgi->start_div({-style=>'margin-left: 400px; margin-bottom: 10px; width: 300px;'});

    ## Kids pane
    %sqlOptions = (order => 'first', sort => 'asc');
    print $cgi->start_div({-class=>'box', -style=>'width: 180px; margin-bottom: 10px; float: left;'});
    $lchc->js_kid_menu('kid', {}, \%sqlOptions, {});
    print $cgi->end_div();

    ## Now add each kid one by one who
    ##  is associated with the course.
    %sqlOptions = (course => $course);
    $query      = $db->sql_course_kid(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    foreach my $row (@results) {
	print $cgi->script({-language=>'javascript'}, "moreFields('kid', $row->{id})");
    }

    ## Activities pane
    %sqlOptions  = (order => 'name', sort => 'asc');
    %menuOptions = (menuOnly => 1);
    print $cgi->start_div({-class=>'box', -style=>'margin-left: 200px; margin-bottom: 10px; width: 310px;'});
    $lchc->js_activity_menu('activity', \%menuOptions, \%sqlOptions, {});
    print $cgi->end_div();

    ## Now add each activity one by one who
    ##  is associated with the course.
    %sqlOptions = (course => $course);
    $query      = $db->sql_course_activity(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    foreach my $row (@results) {
	print $cgi->script({-language=>'javascript'}, "moreFields('activity', $row->{activity})");
    }

    print $cgi->end_div();
    print $cgi->p, $cgi->p;


}

if($what eq 'course' && $submit eq 'delete' && $course > 0) {
    $db->do("delete from $db->{tnConference} where course=$course");
    $db->do("delete from $db->{tnCourse}     where id=$course");

    print "Course \#$course deleted from the database.";
    print $cgi->p;
    print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to admin page');
}

################
## Conference ##
if($what eq 'conference' && $submit eq '' && $course <= 0) {
    %sqlOptions = (order => 'year', sort => 'desc');

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select course');
    print $lchc->course_menu('course', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'select'});
    print $cgi->br;
    print $cgi->end_div();

}

if($what eq 'conference' && $submit eq 'select' && $course > 0) {

    ## Get the conference information for this course
    %sqlOptions = (course => $course);
    my $query = $db->sql_conference(\%sqlOptions, {});
    my @res = $db->complex_results($query);

    print $cgi->start_form({-method=>'get', -action=>$lchc->{admin_update}});
    print $cgi->hidden({-name=>'what', -value=>'conference'});
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select course');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td('Fieldnote?'), $cgi->td('Name'), $cgi->td());
    foreach my $row (@res) {
	my $delete = $cgi->a({-href=>"$lchc->{admin_edit}?what=conference&submit=delete&conference=$row->{id}"},
			     'delete');
	print $cgi->hidden({-name=>'conference', -value=>$row->{id}});
	print $cgi->Tr($cgi->td($cgi->checkbox({-name=>"$row->{id}\.fieldnote",
						-value=>1, -label=>'', -checked=>$row->{fieldnote}})),
		       $cgi->td($cgi->textfield({-name=>"$row->{id}\.name", -size=>30, -value=>$row->{name}})),
		       $cgi->td($delete));
    }
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'update'})));
    print $cgi->end_table();
    print $cgi->end_div();
    print $cgi->end_form();

}

if($what eq 'conference' && $submit eq 'delete' && $conference > 0) {
    $db->do("delete from $db->{tnConference} where id=$conference");

    print "Conference \#$conference deleted from the database.";
    print $cgi->p;
    print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to admin page');
}

############
## Person ##
if($what eq 'person' && $submit eq '' && $person <= 0) {
    %sqlOptions = (order => 'last', sort => 'asc');

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select person');
    print $lchc->person_menu('person', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'edit'});
    print $cgi->br;
    print $cgi->end_div();

}

if($what eq 'person' && $person > 0 && $submit eq 'edit') {
    ## get the person data
    %sqlOptions = (id => $person);
    my $data = $db->get_person(\%sqlOptions, {});

    # Gender menu
    my $gm = $lchc->gender_menu('gender', $data->{gender});

    ## Supply the person id
    print $cgi->hidden({-name=>'person', -value=>$person});

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Edit person');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'First Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'first', -size=>30, -value=>$data->{first}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Middle Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'middle', -size=>30, -value=>$data->{middle}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Last Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'last', -size=>30, -value=>$data->{last}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Age:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'age', -size=>3, -value=>$data->{age}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Gender:'),
                   $cgi->td({-class=>'value'}, $gm));

    print $cgi->Tr($cgi->td({-class=>'label'}, 'Email Address:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'email', -size=>30, -value=>$data->{email}})));

    print $cgi->Tr($cgi->td({-class=>'label'}, "Adminstrator"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'admin', -value=>1, -checked=>$data->{admin}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Instructor"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'instructor',
							       -value=>1, -checked=>$data->{instructor}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Undergrad"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'undergrad', -value=>1, -checked=>$data->{undergrad}})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'update'})));
    print $cgi->end_table();
    print $cgi->end_div();


}

if($what eq 'person' && $submit eq 'delete' && $person > 0) {
    $db->do("delete from $db->{tPerson}     where id=$person");

    print "Person \#$person deleted from the database.";
    print $cgi->p;
    print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to admin page');
}

#########
## Kid ##
if($what eq 'kid' && $submit eq '' && $kid <= 0) {
    %sqlOptions = (order => 'first', sort => 'asc');

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select kid');
    print $lchc->kid_menu('kid', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'edit'});
    print $cgi->br;
    print $cgi->end_div();

}

if($what eq 'kid' && $kid > 0 && $submit eq 'edit') {
    ## Get the kid data
    %sqlOptions = (id => $kid);
    my $data = $db->get_kid(\%sqlOptions, {});

    ## Site menu
    %sqlOptions  = (order => 'name', sort => 'asc');
    %menuOptions = (selected => $data->{site}, selectedOp => '==');

    ## Gender menu
    my $gm = $lchc->gender_menu('gender', $data->{gender});

    ## Supply the kid id
    print $cgi->hidden({-name=>'kid', -value=>$kid});

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Edit person');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'First Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'first', -size=>30, -value=>$data->{first}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Last Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'last', -size=>30, -value=>$data->{last}})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Site:'),
                   $cgi->td({-class=>'value'}, $lchc->site_menu('site', \%menuOptions, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Gender:'),
                   $cgi->td({-class=>'value'}, $gm));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'update'})));
    print $cgi->end_table();
    print $cgi->end_div();    

}

if($what eq 'kid' && $submit eq 'delete' && $kid > 0) {
    $db->do("delete from $db->{tnKid} where id=$kid");

    print "Kid \#$kid deleted from the database.";
    print $cgi->p;
    print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to admin page');
}


##########
## Site ##
if($what eq 'site' && $site <= 0 && $submit eq '') {
    %sqlOptions = (order => 'name', sort => 'asc');

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select site');
    print $lchc->site_menu('site', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'edit'});
    print $cgi->br;
    print $cgi->end_div();
}

if($what eq 'site' && $site > 0 && $submit eq 'edit') {
    ## get the person data
    %sqlOptions = (id => $site);
    my $data = $db->get_site(\%sqlOptions, {});

    ## Print the form elements
    print $cgi->hidden({-name=>'site', -value=>$site});
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Edit person');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Site Name: '),
                   $cgi->td({-class=>'value'}, "<input type=textfield size=30 name=name value='$data->{name}'>"));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'update'})));
    print $cgi->end_table();
    print $cgi->end_div();

}

##############
## Activity ##
if($what eq 'activity' && $activity <= 0 && $submit eq '') {
    %sqlOptions = (order => 'name', sort => 'asc');

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Select activity');
    print $lchc->activity_menu('activity', {}, \%sqlOptions, {});
    print $cgi->p;
    print $cgi->submit({-name=>'submit', -value=>'edit'});
    print $cgi->br;
    print $cgi->end_div();

}

if($what eq 'activity' && $activity > 0 && $submit eq 'edit') {
    ## get the person data
    %sqlOptions = (id => $activity);
    my $data = $db->get_activity(\%sqlOptions, {});

    ## Print the form elements
    print $cgi->hidden({-name=>'activity', -value=>$activity});
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Edit person');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Activity Name: '),
                   $cgi->td({-class=>'value'}, "<input type=textfield size=30 name=name value='$data->{name}'>"));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'update'})));
    print $cgi->end_table();
    print $cgi->end_div();
}


## End the general form and table
print $cgi->end_table();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
