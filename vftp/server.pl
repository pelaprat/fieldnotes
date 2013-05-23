#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: server.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi  = new CGI;
my $pn   = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie('user');
my $path  = $cgi->param('path');

my $order = $cgi->param('order');
my $sort  = $cgi->param('sort');
my $hist  = $cgi->param('hist');

## Check parameter values
$user  = -1 if ! defined $user;
$path  = '' if ! defined $path;

$order = 'timestamp' if ! defined $order;
$sort  = 'asc'       if ! defined $sort;
$hist  = 'off'       if ! defined $hist;

## Toggle values
my %toggle = (sort=>'asc', hist=>'off');
#$toggle{sort} = 'desc' if $sort eq 'asc';
#$toggle{hist} = 'on'   if $hist eq 'off';

## Set some variables
$pn->set_cgi($cgi);
$pn->set_db($db);
$pn->set_user($user);
$db->set_pn($pn);

## Access control, we are the index
#$pn->control_access((index=>0, admin=>0, header=>1));



####
## Redirect out of here if the necessary params
##  are not supplied.
## No trailing '/' on the dir
$path =~ s/\/+$//g;
#my $sql = $db->SQL_open_directory((path=>$path));
#my @res = $db->complex_results($sql);
if($path eq '' ) {
    print $cgi->redirect({-location=>$pn->{uri_index}});
    exit(0);
}

####################################
## We have the right params,      ##
##  retrieve and prepare the data ##
my $command   = "ls -lQ $path";
my $results   = `$command`;
my %structure = ();

## Get the result of command
foreach my $line (split('\n', $results)) {
    if($line =~ m|^([drwx\-]+)\s+\d+\s(\w+)\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+:\d+)\s+"(.+)"$|) {
	my $name = $8;

	## Build the data
	my %data = (perms => $1,
		    owner => $2,
		    group => $3,
		    bytes => $4,
		    month => $5,
		    day   => $6,
		    time  => $7,
		    name  => $8);

	## Get a formatted timestamp
	$data{timestamp} = `date --date='$data{month} $data{day} $data{time}' '+%m'`;
	chomp($data{timestamp});

	## Get a little extra data
	$data{ext} = '';
	if($name =~ m|([^\.]+)$|) {
	    $data{ext} = $1;
	}

	$data{icon} = $pn->icon($data{ext});
	$data{size} = $pn->icon($data{bytes});

	## Add to the structure
	$structure{$name} = \%data;
    }
}


exit(0);

#####################
## ---FUNCTIONS--- ##
sub print_item($$) {
    my($class, $data) = @_;
    my $icon = '';

       $icon = $cgi->img({-src=> &icon($data->{type})}) if $class eq 'current';
    my $link = $cgi->a({href=>"$pn->{uri_download}?id=$data->{id}"}, $data->{name});

    print $cgi->Tr({-class=>$class},
		   $cgi->td({-style=>'width: 16px'},
			    $icon),
		   $cgi->td($link),
		   $cgi->td($data->{person}),
		   $cgi->td($data->{timestamp}),
		   $cgi->td(&size($data->{bytes})));
}

sub browse_link(%) {
    my(%values) = @_;
    my $space = 0;
    my($ls, $lo, $lr, $lh) = ($space, $order, $sort, $hist);

    $ls = $values{space} if defined $values{space} && $values{space} > 0;
    $lo = $values{order} if defined $values{order} && $values{order} ne '';
    $lr = $values{sort}  if defined $values{sort}  && $values{sort}  ne '';
    $lh = $values{hist}  if defined $values{hist}  && $values{hist}  ne '';

    return "$pn->{uri_browse}?space=$ls&order=$lo&sort=$lr&hist=$lh";
}

