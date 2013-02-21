#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/upload.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;
use File::stat;

## Build the basic objects
my $cgi  = new CGI;
my $vftp = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie($vftp->{cookieName});
my $space = $cgi->param('space');
my $name  = $cgi->param('file');
my $data  = $cgi->upload('file');
my $info  = $cgi->uploadInfo($name);
my $path  = $cgi->param('path');

## Check parameter values
$user  = -1 if ! defined $user;
$space = -1 if ! defined $space;
$name  = '' if ! defined $name;
$data  = undef if ! defined $data;
$info  = undef if ! defined $info;
$path  = '' if ! defined $path;

## Set some variables
$vftp->set_cgi($cgi);
$vftp->set_db($db);
$vftp->set_user($user);
$db->set_pn($vftp);

## Do an initial error check
##  in case the user pressed 'stop'
if(!$data && $cgi->cgi_error || !defined $data || !defined $info ||
   $space <= 0) {
    print $cgi->header(-status => $cgi->cgi_error);
    exit(0);
}

## Get the space data
my %sqlOptions = (id => $space);
my $spaceData  = $db->get_space(\%sqlOptions, {});

## Get some extra data before we
##  insert the file into the space.
my($ext, $type) = ('', '');
$type = $info->{'Content-Type'};
if($name =~ m|\.(\w+)$|) {
    $ext = $1;
}

## Do some modifications in case
##  we get a full file path.
if( $name =~ m|([^\\]+)$|i ) {
    $name = $1;
}

## Make a safe version of the name
my $safe = $vftp->safe_single_quotes($name);

## Check we have all the data we need
##  to upload this file to the server.
if($user > 0 && $spaceData->{server} == 0 && $name ne '') {
    ## Make all previous versions historical
    $db->do("update $db->{tvFile} set historical=1 where name='$safe' and space=$space");

    ## Get the new file id
    my $id = $db->simple_add($db->{tvFile}, ('NULL', "'$safe'", $user, $space, 'NOW()',
					     "'$type'", "'$ext'", 0, "''", 0));

    my $path  = "$vftp->{dir_files}/$id\.$ext";
    my $bytes = &upload($path);

    ## Update the size in bytes of the file
    $db->do("update $db->{tvFile} set bytes=$bytes where id=$id");

} elsif($user > 0 && $spaceData->{server} == 1 && $name ne '' && defined $path) {

    ## Get the absolute path to the file
    my $abs = "$spaceData->{path}/$path/$name";

    ## Make live version historical, if needed
    if(-e $abs) {
	## Get the timestamp for the live version
	my $stat = stat($abs);

	## Get the id for this item
	my $bytes = $stat->ctime;
	my $id = $db->simple_add($db->{tvFile}, ('null', "'$safe'", -1, $space,
						 "from_unixtime($bytes)",
						 "'$type'", "'$ext'", $stat->size,
						 "'$path'", 1));

	## Copy the live version to the historical version
	system("cp \"$abs\" $vftp->{dir_files}/$id\.$ext");
    }

    ## Upload the file to the space
    &upload($abs);
}

## Redirect us back to our space
print $cgi->redirect({-location=>"$vftp->{uri_browse}?space=$space&path=$path"});

exit(0);

sub upload($) {
    my($path) = @_;

    ## Copy the data to the permanent file location
    chmod(0776, $vftp->{dir_files});
    my $bytes = 0;
    open(FILE, ">$path") || print "Can't open $path\n\n";
    while(my $k = <$data>) {
        print FILE $k;
        $bytes += length($k);
    }
    close(FILE);

    ## Make sure it's writable by the group
    chmod(0775, $path);

    return $bytes;
}
