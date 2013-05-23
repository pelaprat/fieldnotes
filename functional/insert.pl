#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/insert.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::SQL::Vftp;
use LCHC::Notes;
use LCHC::Vftp;
use Mail::Sendmail;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $vftp = new LCHC::SQL::Vftp;
my $vpn  = new LCHC::Vftp;
my $lchc = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user       = $cgi->cookie($lchc->{cookie_name_reg});
my $type       = $cgi->param('type');
my $course     = $cgi->param('course');
my $conference = $cgi->param('conference');
my $fieldnote  = $cgi->param('fieldnote');
my $site       = $cgi->param('site');

# For fieldnotes;
my $dov_day          = $cgi->param('dov_day');
my $dov_month        = $cgi->param('dov_month');
my $dov_year         = $cgi->param('dov_year');
my $kid_counter      = $cgi->param('kid-counter');
my $activity_counter = $cgi->param('activity-counter');
my $file_counter     = $cgi->param('file-counter');
my $general          = $cgi->param('general');
my $narrative        = $cgi->param('narrative');
my $gametask         = $cgi->param('gametask');
my $reflection       = $cgi->param('reflection');

my $sendmail = "/usr/sbin/sendmail -oi -t -odq";
my $id    = -1;
my $short = '';

# For comment;
my $subject    = $cgi->param('subject');
my $body       = $cgi->param('body');

## Check parameter values
$user       = -1    if ! defined $user;
$type       = ''    if ! defined $type;
$course     = -1    if ! defined $course;
$conference = -1    if ! defined $conference;
$fieldnote  = -1    if ! defined $fieldnote;
$site       = -1    if ! defined $site;

# For fieldnotes;
$dov_day          = '' if ! defined $dov_day;
$dov_month        = '' if ! defined $dov_month;
$dov_year         = '' if ! defined $dov_year;
$kid_counter      =  0 if ! defined $kid_counter;
$activity_counter =  0 if ! defined $activity_counter;
$file_counter     =  0 if ! defined $file_counter;
$general          = '' if ! defined $general;
$narrative        = '' if ! defined $narrative;
$gametask         = '' if ! defined $gametask;
$reflection       = '' if ! defined $reflection;

## For comment;
$subject    = ''    if ! defined $subject;
$body       = ''    if ! defined $body;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

$vpn->set_cgi(  $cgi  );
$vpn->set_db(   $vftp );
$vpn->set_user( $user );
$vftp->set_pn(  $vpn  );

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'functional/insert.pl',
				   action => 'post' });

## Access control
$lchc->control_access((index=>0, admin=>0, header=>0));

####
## Check we have, for each type, the right variables and that they have content
if($course <= 0 || $conference <= 0 ||
   ($type eq 'comment'   && ($subject eq ''     || $body eq ''))   ||
   ($type eq 'fieldnote' && !($dov_day > 0      || $dov_month > 0  || $dov_year > 0 ||
			      $site   <= 0      || $general eq ''  || 
			      $narrative  eq '' || $gametask eq '' ||
			      $reflection eq ''))) {

    ## problem, bug out

}

#############################
## COMMENT or SITE COMMENT ##
if($type eq 'comment' || $type eq 'commentsite') {
    $body    = $lchc->safe_single_quotes($body);
    $subject = $lchc->safe_single_quotes($subject);

    my $table = '';
    if($type eq 'comment') {
	$table = $db->{tnComment};
    } else {
	$table = $db->{tnCommentSite};
    }

    $id = $db->simple_add($table,'NULL', $user, $course, $conference,
			  $fieldnote, "'$subject'", 'NOW()', "'$body'");

    ######################
    ## Add attachments. ##
    &add_attachments( 'comments', $id );

    if($fieldnote <= 0 && $type eq 'comment') {
	$db->do("update $db->{tnConference} set items=items+1 where id=$conference");
    }

    $short =  $id;
}

###############
## FIELDNOTE ##
if($type eq 'fieldnote')  {
    $general    = $lchc->safe_single_quotes($general);
    $narrative  = $lchc->safe_single_quotes($narrative);
    $gametask   = $lchc->safe_single_quotes($gametask);
    $reflection = $lchc->safe_single_quotes($reflection);

    ## Insert the fieldnote
    $id = $db->simple_add($db->{tnFieldnote},
			  ('NULL', $user, $course, $conference, $site,
			   "'$dov_year-$dov_month-$dov_day 12:00:00'",
			   'NOW()', "'$general'", "'$narrative'",
			   "'$gametask'", "'$reflection'"));
    $short = $id;

    ######################
    ## Add attachments. ##
    &add_attachments( 'fieldnote', $id );


    #######################################################
    ## Insert the activities and kids for this fieldnote ##
    foreach my $activity (1 .. $activity_counter) {
	my $act = $cgi->param("activity$activity");
	my $min = $cgi->param("minutes$activity");
	my $tkc = $cgi->param("taskcard$activity");

	## Remove non-integers.
	$min =~ s/[^0-9]//g;

	## May not be defined; give default value
	$min = 0 if ! defined $min || $min eq '';
	$tkc = 0 if ! defined $tkc || $tkc eq '';

	## Insert if it doesn't exist.
	if(defined $act && defined $min && $act > 0 && $min >= 0 &&
	   $db->fieldnote_activity_exists($id, $act) == 0) {

	    ## Add the joint insert.
	    $db->simple_add($db->{tnFieldnoteActivity},
			    ($id, $act, $tkc, $min));

	    ## Update activity referenced
	    $lchc->update_last_reference( $db->{tnActivity}, $act );
	}
    }

    foreach my $kid (1 .. $kid_counter) {
	my $k = $cgi->param("kid$kid");

	if(defined $k && $k > 0 &&
	   $db->fieldnote_kid_exists($id, $k) == 0) {

	    ## Add the joint insert.
	    $db->simple_add($db->{tnFieldnoteKid}, ($id, $k));

	    ## Update activity referenced
	    $lchc->update_last_reference( $db->{tnKid}, $k );
	}
    }

    ## Update reference to site.
    $lchc->update_last_reference( $db->{tnSite}, $site );

    ## Update Various Counts
    $db->do("update $db->{tnConference} set items=items+1 where id=$conference");
}


####################
### EMAIL PEOPLE ###
if(($type eq 'comment' || $type eq 'commentsite') && $fieldnote > 0) {
    my %sqlOptions = (id => $fieldnote);
    my %optionsOps = ();

    ## Get data for the parent
    my $data = $db->get_fieldnote(\%sqlOptions, \%optionsOps);

    ## Some basic shared data
    my $link     = "$lchc->{uri_course}?course=$course&conference=$conference#fieldnote\.$data->{id}";

    ## Content for people in the conversation
    my $content  = ("Hi!\n\n$lchc->{user_name} has contributed to a conversation " .
		    "you're having regarding a fieldnote.\n\n                    " .
		    "You can view the comment by clicking on the link below!\n\n " . 
		    "$link\n\n--LCHC");

    my $subject  = 'Subject: Reply to your fieldnote or comment';
    my $reply_to = "Reply-to: LCHC <lchc\@lchc.ucsd.edu>";
    my $send_to  = 'To: ' . $data->{person_email};

    open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
    print SENDMAIL $reply_to;
    print SENDMAIL $subject;
    print SENDMAIL $send_to;
    print SENDMAIL "Content-type: text/plain\n\n";
    print SENDMAIL $content;
    close(SENDMAIL);

}

if($short ne '') {
    print $cgi->redirect({-location=>"$lchc->{uri_course}?course=$course&conference=$conference#$short"});
} else {
    print $cgi->redirect({-location=>"$lchc->{uri_course}?course=$course&conference=$conference"});
}

exit(0);


#######################################
## THE MAJORITY OF THIS CODE NOW IS  ##
##  COPIED FROM THE FOLLOWIING FILE: ##
##
##  /home/lchc/lchc-resources.org/fieldnote_vftp/functional/upload.pl
##

sub add_attachments( $$ ) {
    my( $o_type, $o_id ) = @_;
    my  $space       = $cgi->param('space');

    #################################
    ## Go through each attachment. ##
    foreach my $file (1 .. $file_counter) {

	##############################
	## Get the variables first. ##
	my $name  = $cgi->param("file$file");
	my $data  = $cgi->upload("file$file");
	my $info  = $cgi->uploadInfo($name);
	my $path  = $cgi->param('path');

	##########################
	## Check the variables. ##
	$name  = ''    if ! defined $name;
	$data  = undef if ! defined $data;
	$info  = undef if ! defined $info;
	$path  = ''    if ! defined $path;

	#######################################
	## Do an initial error check         ##
	##  in case the user pressed 'stop'  ##
#	if(!$data && $cgi->cgi_error || !defined $data || !defined $info ||
#	   $space <= 0) {
#	    print $cgi->header(-status => $cgi->cgi_error);
#	    exit(0);
#	}

	########################
	## Get the space data ##
	my %sqlOptions = (id => $space);
	my $spaceData  = $vftp->get_space(\%sqlOptions, {});

	######################################
	## Get some extra data before we    ##
	##  insert the file into the space. ##
	my($ext, $type) = ('', '');
	$type = $info->{'Content-Type'};
	if($name =~ m|\.(\w+)$|) {
	    $ext = $1;
	}

	###################################
	## Do some modifications in case ##
	##  we get a full file path.     ##
	if( $name =~ m|([^\\]+)$|i ) {
	    $name = $1;
	}

	#####################################
	## Make a safe version of the name ##
	my $safe = $lchc->safe_single_quotes($name);

	#########################################
	## Check we have all the data we need  ##
	##  to upload this file to the server. ##
	if($user > 0 && $spaceData->{server} == 0 && $name ne '') {

	    ###########################################
	    ## Make all previous versions historical ##
	    $db->do("update $db->{tvFile} set historical=1 where name='$safe' and space = $space");

	    #########################
	    ## Get the new file id ##
	    my $id = $db->simple_add($db->{tvFile}, ('NULL', "'$safe'", $user, $space, 'NOW()',
						     "'$type'", "'$ext'", 0, "''", 0));
	    
	    my $path  = "$vpn->{dir_files}/$id\.$ext";
	    my $bytes = &upload( $path, $data );

	    ##########################################
	    ## Update the size in bytes of the file ##
	    $db->do("update $db->{tvFile} set bytes=$bytes where id=$id");

	    #################################################
	    ## Link this file to the fieldnote or comment. ##
	    if( $o_type eq 'comments' ) {
		my $link = $db->simple_add( $db->{tnCommentAttachment},
					 ( $o_id, $id ));
	    } elsif( $o_type eq 'fieldnote' ) {
		my $link =$db->simple_add( $db->{tnFieldnoteAttachment},
					( $o_id, $id ));
	    }

	} elsif($user > 0 && $spaceData->{server} == 1 && $name ne '' && defined $path) {

	    ###################################
	    ## We're disallowing these here. ##
	    ###################################

	}
    }
}

sub upload( $$ ) {
    my( $path, $data ) = @_;

    ##################################################
    ## Copy the data to the permanent file location ##
    chmod( 0776, $vpn->{dir_files} );
    my $bytes = 0;
    open( FILE, ">$path" ) || print "Can't open $path\n\n";
    while( my $k = <$data> ) {
        print FILE $k;
        $bytes += length( $k );
    }
    close( FILE );

    ## Make sure it's writable by the group
    chmod( 0775, $path );

    return $bytes;
}
