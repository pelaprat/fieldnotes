#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/logout.pl
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

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);



## Try logging in the user
my $cookie = $cgi->cookie(-name    => $lchc->{cookie_name_arc},
			  -value   => -1,
			  -expires => '-1d',
			  -path    => '/',
			  -domain  => $lchc->{cookie_domain},
			  -secure  => 0);

print $cgi->redirect({-location=>$lchc->{uri_index}, -cookie=>$cookie});

exit(0);
