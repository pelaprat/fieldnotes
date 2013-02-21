#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: admin/backup.pl
##

## Make sure we point correctly
BEGIN { push @INC,  '../LCHC'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookieName});

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'admin/backup.pl',
				   action => 'get',
			           target => 'backup' } );

## Access control, we are the index
$lchc->control_access((index=>0, admin=>1, header=>1));



####
## Backup
my $date = `date "+%m-%d-%Y"`;
chomp $date;

my $file = $lchc->{dir_backup_db} . "/$date\.backup";
system("mysqldump -u$db->{db_user} -p$db->{db_pass} -h$db->{db_host} --single-transaction $db->{db_name} > $file");

####
## Now onto main part of the page
print $cgi->start_html({-title=>'Administration Tools', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

print "Database is now backed up for $date.";
print $cgi->br;
print $cgi->a({-href=>$lchc->{admin_index}}, 'Return to Administration Page');

## Footer
$lchc->footer;

print $cgi->end_html;

exit(0);
