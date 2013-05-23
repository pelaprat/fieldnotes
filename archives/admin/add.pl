#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/add.pl
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
my $what = $cgi->param('what');

## Check parameter values
$user   = -1 if ! defined $user;
$what   = '' if ! defined $what;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));



####################
## Some variables ##
my(%menuOptions, %sqlOptions, %optionsOps) = ((), (), ());

####################################
## Now onto main part of the page ##
print $cgi->start_html({-title=>'Administration Tools', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

## Print the general form first, and the table
print $cgi->start_form({-method=>'post', -action=>$lchc->{admin_insert}});
print $cgi->hidden({-name=>'what', -value=>$what});

## Toggle on what form is to be used
if($what eq 'course') {
    %sqlOptions = (instructor => 1, order => 'last', sort => 'asc');

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Course');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Instructor:'),
		   $cgi->td({-class=>'value'}, $lchc->person_menu('person', {}, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Program:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'program', -size=>4, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course Number:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'number', -size=>3, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course Name:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Quarter:'),
		   $cgi->td({-class=>'value'}, $lchc->quarter_menu('quarter', \%menuOptions)));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Year'),
		   $cgi->td({-class=>'value'}, $lchc->year_menu('year', \%menuOptions)));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Current Course?"),
		   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'current', -value=>1, -label=>''})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

} elsif($what eq 'conference') {

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Conference');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course:'),
                   $cgi->td({-class=>'value'}, $lchc->course_menu('course', {}, \%sqlOptions, {})));
								  
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Fieldnote Conference?"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'fieldnote', -value=>1, -label=>''})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

}  elsif($what eq 'kid') {
    %sqlOptions  = (order => 'name', sort => 'asc');
    my @v  = ('m', 'f');
    my %l  = (m => 'm',f => 'f');
    my $gm = $lchc->menu('gender', \@v, \%l, {});

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Kid');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'First Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'first', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Last Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'last', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Site:'),
                   $cgi->td({-class=>'value'}, $lchc->site_menu('site', {}, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Gender:'),
                   $cgi->td({-class=>'value'}, $gm));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

} elsif($what eq 'person') {
    my @v  = ('m', 'f');
    my %l  = (m => 'm',f => 'f');
    my $gm = $lchc->menu('gender', \@v, \%l, {});

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Person');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'First Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'first', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Middle Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'middle', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Last Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'last', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Age:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'age', -size=>2, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Gender:'),
                   $cgi->td({-class=>'value'}, $gm));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Email Address:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'email', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Password:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'pass', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Adminstrator"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'admin', -value=>1, -label=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Instructor"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'instructor',
							       -value=>1, -label=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, "Undergrad"),
                   $cgi->td({-class=>'value'}, $cgi->checkbox({-name=>'undergrad', -value=>1, -label=>''})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

} elsif($what eq 'site') {
    # Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Site');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Site Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

} elsif($what eq 'activity') {
    # Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Activity');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Activity Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();

} elsif($what eq 'space') {
    %sqlOptions  = (order => 'year', sort => 'desc');
    %menuOptions = (emtpy => 1);

    ## Print the form elements
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Add Space');
    print $cgi->start_table();
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Space Name:'),
                   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'name', -size=>30, -value=>''})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course:'),
                   $cgi->td({-class=>'value'}, $lchc->course_menu('course', \%menuOptions, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'submit'})));
    print $cgi->end_table();
    print $cgi->end_div();
}

## End the general form
print $cgi->end_form();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
