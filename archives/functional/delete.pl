#!/usr/local/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/delete.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/Users/web/perl'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes( 'http://archives.lchc-resources.org' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user   = $cgi->cookie('lchcarchives');
my $id     = $cgi->param('id');
my $return = $cgi->param('return');

## Check parameter values
$user   = -1 if ! defined $user;
$id     = -1 if ! defined $id;
$return = '' if ! defined $return;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control
$lchc->control_access((index=>0, admin=>1, header=>0));

## Convert the return link
$return =~ s/\*/&/g;

if($id > 0 && $return ne '' && $lchc->{user_admin} == 1) {
    my $tnConference        = $db->{tnConference};
    my $tnFieldnote         = $db->{tnFieldnote};
    my $tnFieldnoteActivity = $db->{tnFieldnoteActivity};
    my $tnFieldnoteKid      = $db->{tnFieldnoteKid};

    my %sqlOptions    = (id => $id);
    my %optionsOps    = ();
    my $fieldnoteData = $db->get_fieldnote(\%sqlOptions, \%optionsOps);

    $db->do("delete from $tnFieldnote         where id=$id");
    $db->do("delete from $tnFieldnoteKid      where fieldnote=$id");
    $db->do("delete from $tnFieldnoteActivity where fieldnote=$id");

    ## Update the number of fieldnotes
    ##  in the conference.
    $db->do("update $tnConference set items=items-1 where id=$fieldnoteData->{conference_id}");

    print $cgi->redirect({-location=>$return});
    exit(0);
}

print $cgi->redirect({-location=>$lchc->{uri_index}});

exit(0);
