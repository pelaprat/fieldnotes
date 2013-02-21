#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/jump.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi  = new CGI;
my $vftp   = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie($vftp->{cookieName});
my $space = $cgi->param('space');

## Check parameter values
$user  = -1 if ! defined $user;
$space = -1 if ! defined $space;

## Set some variables
$vftp->set_cgi($cgi);
$vftp->set_db($db);
$vftp->set_user($user);
$db->set_pn($vftp);

## Access Control
$vftp->control_access((index=>0, admin=>0, header=>0));



## Get the space data
my %sqlOptions = (id => $space);
my $spaceData  = $db->get_space(\%sqlOptions, {});

if($spaceData->{server} == 1) {
    print $cgi->redirect({-location=>"$vftp->{uri_browse}?space=$spaceData->{id}&path="});
} else {
    print $cgi->redirect({-location=>"$vftp->{uri_browse}?space=$spaceData->{id}"});
}

exit(0);
