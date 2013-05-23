#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/index.pl
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

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'admin/update.pl',
				   action => 'get',
			           target => 'index' } );

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));


####
## Now onto main part of the page
print $cgi->start_html({-title=>'Administration Tools', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

print $cgi->start_table();
print $cgi->start_Tr();
print $cgi->start_td();

print $cgi->b({ -style => 'font-family: Georgia; font-size: 15px; margin-left: 20px;' }, 'Adding Items' );
print $cgi->p();
&big_button( 'Add Person', "$lchc->{admin_add}?what=person" );
&big_button( 'Add Kid', "$lchc->{admin_add}?what=kid" );
&big_button( 'Add Activity', "$lchc->{admin_add}?what=activity" );
&big_button( 'Add Course',  "$lchc->{admin_add}?what=course"  );
&big_button( 'Add Conference', "$lchc->{admin_add}?what=conference" );
&big_button( 'Add Filespace', "$lchc->{admin_add}?what=space" );

print $cgi->end_td();
print $cgi->start_td();

print $cgi->b({ -style => 'font-family: Georgia; font-size: 15px; margin-left: 20px' }, 'Editing Properties' );
print $cgi->p();
&big_button( 'Edit Person', "$lchc->{admin_edit}?what=person" );
&big_button( 'Edit Kid', "$lchc->{admin_edit}?what=kid" );
&big_button( 'Edit Activity', "$lchc->{admin_edit}?what=activity" );
&big_button( 'Edit Course', "$lchc->{admin_edit}?what=course" );
&big_button( 'Edit Conference', "$lchc->{admin_edit}?what=conference" );

print $cgi->end_td();
print $cgi->start_td();

print $cgi->b({ -style => 'font-family: Georgia; font-size: 15px; margin-left: 20px' }, 'Managing Things' );
print $cgi->p();
&big_button( 'Manage Course Rosters',             $lchc->{admin_course}                 );
&big_button( 'Manage Course Kids and Activities', $lchc->{admin_course_kids_activities} );


print $cgi->end_td();
print $cgi->end_Tr();
print $cgi->end_table();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);


sub big_button( $$ ) {
    my( $text, $uri ) = @_;

    print $cgi->div({ -style => ('font-size: 14px; font-family: Georgia, Time New Roman, sans-serif;    '  .
				 'font-weight: bold; background: #eeeeee; color: #445566; width: 220px; '  .
				 'margin-left: 20px; border: 2px solid #AABBAA; cursor: pointer;        '  .
				 'margin-bottom: 12px; margin-top: 5px; padding: 5px; text-align: center;'),
				 -onclick => "window.location = '$uri';" },
		    $cgi->span({ -style => 'color: #black; font-weight: bold; font-family: Georgia' }, $text ));
				 print $cgi->p;
}
