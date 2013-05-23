#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/password.pl
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
my $lchc = new LCHC::Notes( 'archives' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_arc});
my $submit     = $cgi->param('submit');
my $person     = $cgi->param('person');
my $p1         = $cgi->param('p1');
my $p2         = $cgi->param('p2');

## Check parameter values
$user       = -1 if ! defined $user;
$submit     = '' if ! defined $submit;
$person     = -1 if ! defined $person;
$p1         = -1 if ! defined $p1;
$p2         = -1 if ! defined $p2;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));


my(%sqlOptions, %optionsOps);

####
## Now onto main part of the page
print $cgi->start_html({-title=>'Reset Password', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

## Print the general form first, and the table IF we are editing
if($submit eq '') {
    %sqlOptions = (order => 'last', sort => 'asc');

    print $cgi->start_form({-method=>'post', -action=>$lchc->{admin_password}});
    print $cgi->start_table();

    ## Print the form elements
    print $cgi->Tr($cgi->td($cgi->div({-style=>'width: 120px'})), $cgi->td());
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Person:'),
		   $cgi->td({-class=>'value'}, $lchc->person_menu('person', {}, \%sqlOptions, {})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Password:'),
		   $cgi->td({-class=>'value'}, $cgi->password_field({-name=>'p1', -size=>15})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Again:'),
		   $cgi->td({-class=>'value'}, $cgi->password_field({-name=>'p2', -size=>15})));

    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'reset'})));
    print $cgi->end_form();

    ## End the general form and table
    print $cgi->end_table();

} elsif($submit eq 'reset' && $person > 0 && $p1 eq $p2 && $p1 ne '') {
    $p1 = $lchc->safe_single_quotes($p1);
    $db->do("update $db->{tPerson} set pass=md5('$p1') where id=$person");

    print "Password has been reset for user \#$person";
    print $cgi->br;
    print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to admin page');

} else {
    print "Error: passwords do not match!";
    print $cgi->br;
    print $cgi->a({-href=>$lchc->{admin_password}}, 'Try again.');
}


## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
