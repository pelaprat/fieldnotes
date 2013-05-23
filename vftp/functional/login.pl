#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/login.pl
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
my $user = $cgi->param('user');
my $pass = $cgi->param('pass');

## Check parameter values
$user = -1 if ! defined $user;
$pass = '' if ! defined $pass;

## Set some variables
$vftp->set_cgi($cgi);
$vftp->set_db($db);
$vftp->set_user($user);
$db->set_pn($vftp);

# No access control

## Main
my $cookie;

## Try logging in the user
$user = $vftp->login($user, $pass);

if($user >= 1) {
    $cookie = $cgi->cookie(-name    => $lchc->{cookie_name_reg},
			   -value   => $user,
			   -expires => '+1y',
			   -path    => '/',
			   -domain  => '.lchc-resources.org',
			   -secure  => 0);
} else {
    $cookie = '';
}

print $cgi->redirect({-location=>$vftp->{uri_index}, -cookie=>$cookie});

exit(0);
