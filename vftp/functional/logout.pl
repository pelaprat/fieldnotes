#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/logout.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi  = new CGI;
my $vftp = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($vftp->{cookie_name_reg});

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$vftp->set_cgi($cgi);
$vftp->set_db($db);
$vftp->set_user($user);
$db->set_pn($vftp);


## Try logging in the user
my $cookie = $cgi->cookie(-name    => $lchc->{cookie_name_reg},
			  -value   => -1,
			  -expires => '-1d',
			  -path    => '/',
			  -domain  => '.lchc-resources.org',
			  -secure  => 0);

print $cgi->redirect({-location=>$vftp->{uri_index}, -cookie=>$cookie});

exit(0);
