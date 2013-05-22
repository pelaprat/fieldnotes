#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/print.pl
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
my $lchc = new LCHC::Notes( 'http://fieldnotes.ucsd.edu/archives' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user     = $cgi->cookie('lchcarchives');
my @id       = $cgi->param('id');
my $keywords = $cgi->param('keywords');
my @fieldnotes = ();
my @comments   = ();

## Check parameter values
$user     = -1 if ! defined $user;
@id       = () if !         @id;
$keywords = '' if ! defined $keywords;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control
$lchc->control_access((index=>0, admin=>1, header=>1));



####
## Start the html
print $cgi->start_html({-title=>'Print Versions',
			-style=>{-src=>$lchc->{uri_css}}});

$lchc->toolbar();

## Go through each fieldnote and
##  get the IDs to make a list.
foreach my $id (@id) {
    if($id =~ m|fieldnote\.(\d+)|) {
	push(@fieldnotes, $1);
    } elsif($id =~ m|comment\.(\d+)|) {
	push(@comments, $1);
    }
}

if(scalar(@fieldnotes) > 0) {
    my(@activities, @kids, @attachments);
    my $idList     = join(',', @fieldnotes);
    my %sqlOptions = (id => "($idList)");
    my %optionsOps = (id => 'in');
    my %displayOps = (keywords => $keywords);

    ## Get the fieldnotes
    my $query   = $db->sql_fieldnote(\%sqlOptions, \%optionsOps);
    my @results = $db->complex_results($query);

    ## Get up the activities
    %sqlOptions    = (fieldnote => "($idList)");
    %optionsOps    = (fieldnote => 'in');
    $query      = $db->sql_fieldnote_activity(\%sqlOptions, \%optionsOps);
    @activities = $db->complex_results($query);

    ## Get up the kids
    $query = $db->sql_fieldnote_kid(\%sqlOptions, \%optionsOps);
    @kids  = $db->complex_results($query);

    ##############################################
    ## Get the attachments for this conference. ##
    %sqlOptions = (fieldnote => "($idList)");
    %optionsOps = (fieldnote => 'in');
    $query       = $db->sql_fieldnote_attachment( \%sqlOptions, \%optionsOps );
    @attachments = $db->complex_results( $query );

    foreach my $fieldnote (@results) {
        ## Print the fieldnote with options, comments
        $lchc->fieldnote_display($fieldnote, \@attachments, \@activities, \@kids, \%displayOps);
	print $cgi->br;
    }
}

if(scalar(@comments) > 0) {
    my $tnComment  = $db->{tnComment};

    my $idList     = join(',', @comments);
    my %sqlOptions = ("$tnComment.id" => "($idList)");
    my %optionsOps = ("$tnComment.id" => 'in');

    ## Get the comment;
    my $query   = $db->sql_comment(\%sqlOptions, \%optionsOps);
    my @results = $db->complex_results($query);

    ##############################################
    ## Get the attachments for this conference. ##
    %sqlOptions     = (comment => "($idList)");
    %optionsOps     = (comment => 'in');
    $query          = $db->sql_comment_attachment( \%sqlOptions, \%optionsOps );
    my @attachments = $db->complex_results( $query );

    foreach my $comment ( @results ) {
	$lchc->comment_display( $comment, \@attachments, { type => 'comment' } );
    }
}

## Footer
$lchc->footer();

print $cgi->end_html();

exit(0);
