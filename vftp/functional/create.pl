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
my $lchc   = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie($lchc->{cookieName});
my $space = $cgi->param('space');
my $path  = $cgi->param('path');
my $what  = $cgi->param('what');
my $name  = $cgi->param('name');

## Check parameter values
$user  = -1 if ! defined $user;
$space = -1 if ! defined $space;
$path  = '' if ! defined $path;
$what  = '' if ! defined $what;
$name  = '' if ! defined $name;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access Control
$lchc->control_access((index=>0, admin=>0, header=>0));

## If we have a correct space;
if($space > 0) {
    ## The new space id
    my $id = $space;

    ## Get the space data
    my %sqlOptions = (id => $space);
    my $spaceData  = $db->get_space(\%sqlOptions, {});

    if($what eq 'directory' && $spaceData->{server} == 0) {
	$id = $db->simple_add($db->{tvSpace}, ('null', "'$name'", $space, "''", 0));
    } else {
	## Get the directory path
	my $abs = "$spaceData->{path}/$path/$name";

	## Make the directory
	system("mkdir \"$abs\"");

	## Set the permissions
	chmod(0775, $abs);

    }

    print $cgi->redirect({-location=>"$lchc->{uri_browse}?space=$space&path=$path"});
} else {
    print $cgi->redirect({-location=>$lchc->{uri_index}});
}

exit(0);
