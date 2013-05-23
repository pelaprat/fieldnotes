#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/login.pl
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
my $user = $cgi->param('user');
my $pass = $cgi->param('pass');

## Check parameter values
$user = -1 if ! defined $user;
$pass = '' if ! defined $pass;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

# No access control

## Main
my $cookie;

## Try logging in the user
$user = $lchc->login($user, $pass);

if($user >= 1) {

    $cookie = $cgi->cookie(-name    => $lchc->{cookie_name_arc},
			   -value   => $user,
			   -expires => '+1y',
			   -path    => '/',
			   -domain  => $lchc->{cookie_domain},
			   -secure  => 0);
} else {
    $cookie = '';
}

print $cgi->redirect({-location=>$lchc->{uri_index}, -cookie=>$cookie});

exit(0);
