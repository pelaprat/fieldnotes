#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/index.pl
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

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));



####
## Now onto main part of the page
print $cgi->start_html({-title=>'Administration Tools', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

print $cgi->start_table();
print $cgi->start_Tr({-style => 'background: #EEEEEE; border: 1px #888888 solid; margin-bottom: 2px;'});
print $cgi->td({-style => 'text-align: center; font-weight: bold', -colspan=>2}, 'Fieldnote Database');
print $cgi->td({-style => 'text-align: center; font-weight: bold'}, 'Vftp');
print $cgi->td({-style => 'text-align: center; font-weight: bold'}, 'LCHC Management');
print $cgi->end_Tr();
print $cgi->start_Tr();


## Person Tools
print $cgi->start_td();
print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Person Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=person"}, 'Add Person');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=person"}, 'Edit/Delete Person');
print $cgi->br;
print $cgi->a({-href=>$lchc->{admin_password}}, 'Reset Password');
print $cgi->p;

## Kid Tools
print $cgi->div({-class=>'box-title'}, 'Kid Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=kid"}, 'Add Kid');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=kid"}, 'Edit/Delete Kid');
print $cgi->p;

## Site Tools
print $cgi->div({-class=>'box-title'}, 'Site Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=site"}, 'Add Site');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=site"}, 'Edit/Delete Site');
print $cgi->p;

## Activity Tools
print $cgi->div({-class=>'box-title'}, 'Activity Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=activity"}, 'Add Activity');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=activity"}, 'Edit/Delete Activity');
print $cgi->end_div();
print $cgi->end_td();

## Course Tools
print $cgi->start_td({-style=>'padding-left: 10px'});
print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Course Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=course"}, 'Add Course');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=course"}, 'Edit/Delete Course');
print $cgi->br;
print $cgi->a({-href=>$lchc->{admin_course}}, 'Manage Course Lists');
print $cgi->p;

## Conference Tools
print $cgi->div({-class=>'box-title'}, 'Conference Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=conference"}, 'Add Conference');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=conference"}, 'Edit/Delete Conference');
print $cgi->end_div();
print $cgi->end_td();


## Space Tools
print $cgi->start_td({-style=>'padding-left: 10px'});
print $cgi->start_div({-class=>'box'});

print $cgi->div({-class=>'box-title'}, 'Space Tools');
print $cgi->a({-href=>"$lchc->{admin_add}?what=space"}, 'Add Space');
print $cgi->br;
print $cgi->a({-href=>"$lchc->{admin_edit}?what=space"}, 'Edit/Delete Space');
print $cgi->end_div();
print $cgi->end_td();

##  Various Tools
print $cgi->start_td({-style=>'padding-left: 10px'});
print $cgi->start_div({-class=>'box', -style=>'width: 250px'});
print $cgi->div({-class=>'box-title'}, 'Various Tools');
print $cgi->a({-href=>$lchc->{admin_backup}},  'Backup the Database');
print $cgi->br;
print ' (this may take a minute or two, be patient)';
print $cgi->p;
print $cgi->a({-href=>$lchc->{admin_item_count}},  'Automatically Update Course Rosters');
print $cgi->br;
print ' (this will not drop anybody from the course roster, but will ';
print 'put on it those people who have posted a fieldnote or comment to the course)';
print $cgi->p;
print $cgi->end_div();
print $cgi->end_td();

print $cgi->end_Tr();
print $cgi->end_table();

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
