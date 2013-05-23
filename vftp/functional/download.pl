#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/download.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use diagnostics;
use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;
use File::stat;


## Build the basic objects
my $cgi  = new CGI;
my $pn   = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie($pn->{cookie_name_reg});
my $id    = $cgi->param('id');
my $space = $cgi->param('space');
my $path  = $cgi->param('path');
my $name  = $cgi->param('name');

## Check parameter values
$user  = -1 if ! defined $user;
$id    = -1 if ! defined $id;
$space = -1 if ! defined $space;
$path  = '' if ! defined $path;
$name  = '' if ! defined $name;


## Set some variables
$pn->set_cgi($cgi);
$pn->set_db($db);
$pn->set_user($user);
$db->set_pn($pn);


## Access control, we are the index
$pn->control_access((index=>0, admin=>0, header=>0));

my %sqlOptions = ();
my %optionsOps = ();

## Do an initial error check
##  in case the user pressed 'stop'
if($cgi->cgi_error) {
    print $cgi->header(-status => $cgi->cgi_error);
    exit(0);
}

## Check we have all the data we need
##  to upload this file to the server.
if($user > 0 && $id > 0) {
    %sqlOptions = ("$db->{tvFile}.id" => $id);
    my $file = $db->get_file(\%sqlOptions, {});
    my $path = "$pn->{dir_files}/$id\.$file->{ext}";

    &transfer($path, $file->{ext}, $file->{name}, $file->{bytes});

} elsif($user > 0 && $space > 0 && $name ne '') {
    %sqlOptions = (id => $space);
    my $spaceData = $db->get_space(\%sqlOptions, {});
    my $local = "$spaceData->{path}/$path/$name";
    my $stat  = stat($local) or die "No $local: $!";

    &transfer($local, 'text/plain', $name, $stat->size);
}

exit(0);

sub transfer($$$) {
    my($path, $type, $name, $size) = @_;

    # send proper mime type
    print $cgi->header(-type=>$type,
                       -Content_Disposition=>"attachment; filename=\"$name\"",
                       -Content_Transfer_Encoding=>'binary',
                       -Content_Length=>$size);

    # send the data
    open(FILE, $path);
    while(my $x = <FILE>) {
        print $x;
    }
    close(FILE);

}
