#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/course.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../../LCHC'; }

use strict;
use CGI;
use LCHC::Notes;
use LCHC::Vftp;
use LCHC::SQL::Notes;
use LCHC::SQL::Vftp;


## Build the basic objects
my $cgi    = new CGI;
my $db     = new LCHC::SQL::Notes;
my $vftp   = new LCHC::Vftp;
my $vftpDB = new LCHC::SQL::Vftp;
my $lchc = new LCHC::Notes( 'archives' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_arc});
my $course     = $cgi->param('course');
my $conference = $cgi->param('conference');
my $keywords   = $cgi->param('keywords');


## Check parameter values
$user       = -1 if ! defined $user;
$course     = -1 if ! defined $course;
$conference = -1 if ! defined $conference;
$keywords   = '' if ! defined $keywords;

## Basic Variables
my %sqlOptions = ();
my %optionsOps = ();
my($courseData, $conferenceData, $attachmentData);
my($query, @results);

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

# Access control
$lchc->control_access((index=>0, admin=>1, header=>1,
		       course=>$course, conference=>$conference));

###############################
## Get all the data possible ##
## Retrieve the course data
%sqlOptions = ( "$db->{tnCourse}.id" => $course);
$courseData = $db->get_course(\%sqlOptions, \%optionsOps);

## Retrieve conference data
if($conference > 0) {
    %sqlOptions = (id => $conference);
    $conferenceData = $db->get_conference(\%sqlOptions, \%optionsOps);

    if(defined $conferenceData->{fieldnote} && $conferenceData->{fieldnote} == 1) {
	$conferenceData->{type} = 'fieldnote';
    } else {
	$conferenceData->{type} = 'comment';
    }
}

## Retrieve the fieldnotes and comments for this conference 
my($post, $print);

my @comments     = ();
my @fieldnotes   = ();
my @commentsite  = ();
my @toPrint      = ();

my @cattachments = ();
my @attachments  = ();
my @activities   = ();
my @kids         = ();
my %comment      = ();


###############################
## FIELDNOTE CONFERENCE DATA ##
if($conference >= 1 && $conferenceData->{type} eq 'fieldnote') {
    my($query, @results);

    ## Set the sql options
    %sqlOptions = ("$db->{tnFieldnote}.course"     => $course,
		   "$db->{tnFieldnote}.conference" => $conference);

    %optionsOps = (order => 'dateofvisit', sort => 'asc');

    ## Retrieve all the fieldnotes for this conference
    $query      = $db->sql_fieldnote(\%sqlOptions, \%optionsOps);
    @fieldnotes = $db->complex_results($query);

    ## Add to print list
    foreach my $fieldnote (@fieldnotes) {
	push(@toPrint, $fieldnote->{id});
    }

    ## Prepare for some queries for activities/kids
    my $idList     = join(',', @toPrint);
    if(scalar(@toPrint) > 0) {
	%sqlOptions    = (fieldnote => "($idList)");
	%optionsOps    = (fieldnote => 'in');

	##############################################
	## Get the attachments for this conference. ##
	$query       = $db->sql_fieldnote_attachment( \%sqlOptions, \%optionsOps );
	@attachments = $db->complex_results( $query );

	## Get activities for this conference
	$query      = $db->sql_fieldnote_activity(\%sqlOptions, \%optionsOps);
	@activities = $db->complex_results($query);

	## Get the kids for this conference
	$query = $db->sql_fieldnote_kid(\%sqlOptions, \%optionsOps);
	@kids  = $db->complex_results($query);
    } else {
	@attachments = @activities = @kids = ();
    }

    ## Retrieve all the comments for these fieldnotes
    if(scalar @toPrint > 0) {
	%sqlOptions = ("$db->{tnComment}.course"     => $course,
		       "$db->{tnComment}.conference" => $conference,
		       "$db->{tnComment}.fieldnote"  => "($idList)");
	%optionsOps = ("$db->{tnComment}.fieldnote"  => 'in');
	$query    = $db->sql_comment(\%sqlOptions, \%optionsOps);
	@comments = $db->complex_results($query);

	#######################################
	## Get all the attachments for these ##
	##  fieldnotes comments.             ##
	my @p = ();
	foreach my $r ( @comments ) { push( @p, $r->{id} ); }
	if( scalar( @p ) > 0 ) {
	    my $p = join(',', @p);

	    %sqlOptions    = ( comment => "($p)");
	    %optionsOps    = ( comment => 'in');
	    $query         = $db->sql_comment_attachment( \%sqlOptions, \%optionsOps );
	    @cattachments  = $db->complex_results( $query );
	}

    } else {
	@comments = ();
    }

    ###########################################################
    ## Retrieve all the *site* comments for these fieldnotes ##
    if(scalar @toPrint > 0 && $lchc->{user_instr} == 1) {
	%sqlOptions  = ("$db->{tnCommentSite}.course"     => $course,
			"$db->{tnCommentSite}.conference" => $conference,
			"$db->{tnCommentSite}.fieldnote"  => "($idList)");
	%optionsOps  = ("$db->{tnCommentSite}.fieldnote"  => 'in');
	$query       = $db->sql_comment_site(\%sqlOptions, \%optionsOps);
	@commentsite = $db->complex_results($query);
    } else {
	@commentsite = ();
    }

}

#############################
## COMMENT CONFERENCE DATA ##
if( $conference >= 1 && $conferenceData->{type} eq 'comment' ) {
    my $query;

    ## Set the sql options
    %sqlOptions = ( course => $course, conference => $conference );
    %optionsOps = ( order  => 'timestamp', sort => 'asc'         );

    ## Retrieve all the comments for this conference
    $query    = $db->sql_comment(\%sqlOptions, \%optionsOps);
    @comments = $db->complex_results($query);

    ## Add to print list
    foreach my $comment (@comments) {
        push(@toPrint, $comment->{id});
    }

    ##############################################
    ## Get the attachments for this conference. ##
    $query       = $db->sql_comment_attachment( \%sqlOptions, \%optionsOps );
    @attachments = $db->complex_results( $query );
}

#################
## Set some links
$post         = &postLink($conferenceData);
$print        = &printLink($conferenceData, \@toPrint);
my $pageTitle = ("$courseData->{program} $courseData->{number} - $courseData->{name} " .
		 "[$courseData->{quarter} $courseData->{year}]: $conferenceData->{name}");

##############################################
## Print the Course and/possibly Conference ##

## Start the html
print $cgi->start_html({-title=>$pageTitle, -style=>{-src=>$lchc->{uri_css}}});
print $cgi->a({-name=>'top'});


##  -----START----- Modified 11/10/2008  by Ivan Rosero  ( irosero@ucsd.edu )

## include javascript for jQuery and lightbox
print "\n\n";

print "<script type='text/javascript' src='js/jquery.js'></script>\n";
print "<script type='text/javascript' src='js/jquery.lightbox-0.5.js'></script>\n";
print "<script type='text/javascript'>         \n" . 
      "\$(function() {                         \n" .
      "  \$('a[\@rel*=lightbox]').lightBox();  \n" .
      "});                                     \n" .
      "</script> \n";

print "\n\n";

##  -----END-----

## Print the toolbar
$lchc->toolbar();

########################
## Course table, etc. ##
print $cgi->start_table({-class=>'course'});

##############################################
## TOP ROW: Identification, Headline, Tools ##
print $cgi->start_Tr({-class=>'conference-toolbar'});
print $cgi->start_td({-style=>'border-right: none;'});

print $cgi->div({-class=>'box-course'},
		$courseData->{name}, $cgi->br,
		"$courseData->{quarter} $courseData->{year}");

print $cgi->end_td();
print $cgi->start_td({-class=>'right', -style=>'border-left: none;'});

if(defined $conference && $conference > 0) {
    ## Start the search form
    print $cgi->start_form({-method=>'get',    -action=>$lchc->{uri_results}});
    print $cgi->hidden({-name=>'conference',   -value=>$conference});
    print $cgi->hidden({-name=>'course',       -value=>$course});

    print $cgi->span({-class=>'header'}, $conferenceData->{name});
    print $cgi->br;
    print $post, ' | ';
    print $cgi->img({-src=>"$lchc->{uri_images}/print.gif",
                     -style=>'padding-right: 2px; padding-bottom: 2px; vertical-align: bottom;'});
    print $print;
    print ' | ';
    print $cgi->img({-src=>"$lchc->{uri_images}/search.gif",
		     -style=>'padding-right: 2px; padding-bottom: 2px; vertical-align: bottom;'});
    print 'Search: ';
    print $cgi->textfield({-name=>'keywords',
			   -size=>15,
			   -style=>'font-size: 10px',
			   -default=>''});
    print $cgi->submit({-name=>'submit',
			-style=>'font-size: 10px;',
			-value=>'search'});
    print $cgi->end_form();
}

print $cgi->end_td;
print $cgi->end_Tr;
##############################################


###################################################
## Main Row: Conferences and Conference Contents ##
print $cgi->start_Tr;
print $cgi->start_td({-class=>'left'});
print $cgi->br;

## Link to email the class
print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Course Tools');
print $cgi->img({-src=>"$lchc->{uri_images}/email.gif", -style=>'vertical-align: bottom'});
print ' ';
print $cgi->a({-href=>"$lchc->{uri_email}?course=$course&subject=&message="}, 'Send email to class');
print $cgi->end_div();
print $cgi->br;

#################################
## File Spaces for this course ##
%sqlOptions = (course => $course, type => 2);
$query   = $vftpDB->sql_course_space(\%sqlOptions, {});
@results = $db->complex_results($query);

print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Files Spaces');
foreach my $row (@results) {
    print $cgi->img({-src=>"$lchc->{uri_images}/directory.gif", -style=>'vertical-align: bottom'});
    print ' ';
    print $cgi->a({-href=>"$vftp->{uri_browse}?space=$row->{space}"}, $row->{space_name});
    print $cgi->br;
}
print $cgi->end_div();
print $cgi->br;

## CONFERENCES TABLE ##
## Fieldnote Conferences
%sqlOptions = (course => $course, fieldnote => 1);
$query   = $db->sql_conference(\%sqlOptions, {});
@results = $db->complex_results($query);

print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Fieldnote Conferences');
print $cgi->start_table();
foreach my $conference (@results) {
    my $link = $cgi->a({-href=>("$lchc->{uri_course}?course=$course" .
				"&conference=$conference->{id}")}, "$conference->{name}");
    print $cgi->Tr($cgi->td("($conference->{items})"),
		   $cgi->td({-style=>'padding-left: 4px'}, $link));
}
print $cgi->end_table();
print $cgi->end_div();
print $cgi->br;

## Comment conferences
%sqlOptions = (course => $course, fieldnote => 0);
$query   = $db->sql_conference(\%sqlOptions, {});
@results = $db->complex_results($query);

print $cgi->start_div({-class=>'box'});
print $cgi->div({-class=>'box-title'}, 'Other Conferences');
print $cgi->start_table();
foreach my $conference (@results) {
    my $link = $cgi->a({-href=>("$lchc->{uri_course}?course=$course" .
				"&conference=$conference->{id}")}, "$conference->{name}");
    print $cgi->Tr($cgi->td("($conference->{items}) "),
		   $cgi->td($link));
}
print $cgi->end_table();
print $cgi->end_div();
print $cgi->br;

print $cgi->end_td;


#####################
## CONFERENCE DATA ##
print $cgi->start_td({-class=>'right'});
print $cgi->p;

my $count = 1;
if(defined $conference && $conference > 0) {
    ## Set the display options
    my %fieldnoteOptions = (keywords => $keywords);
    my %commentOptions   = (keywords => $keywords, indent => 1);

    ###############
    ## FIELDNOTE ##
    if($conferenceData->{type} eq 'fieldnote') {
	## Iterate through each fieldnote, print each one by one
	foreach my $fieldnote (@fieldnotes) {
	    ## Print the fieldnote with options
	    $lchc->fieldnote_display($fieldnote, \@attachments, \@activities, \@kids, \%fieldnoteOptions);

	    ## Print the comments for the fieldnote
	    $commentOptions{type} = 'comment';
	    foreach my $comment (@comments) {
		if($comment->{fieldnote} == $fieldnote->{id}) {
		    $lchc->comment_display($comment, \@cattachments, \%commentOptions);
		}
	    }

	    ## Print the commentsite for the fieldnote
	    $commentOptions{type} = 'commentsite';
	    foreach my $commentsite (@commentsite) {
		if($commentsite->{fieldnote} == $fieldnote->{id}) {
		    $lchc->comment_display($commentsite, \@cattachments, \%commentOptions);
		}
	    }
	}
    }

    #############
    ## COMMENT ##
    %commentOptions   = (keywords => $keywords, type => 'comment');
    if($conferenceData->{type} eq 'comment') {
        foreach my $comment (@comments) {
	    $lchc->comment_display($comment, \@attachments, \%commentOptions);
	}
    }


} else {
    print $cgi->p;
    print $cgi->p;
    print $cgi->p;
    print $cgi->span({-class=>'header'}, 'No conference selected.');
}
print $cgi->end_td;
print $cgi->end_Tr;
####################################


print $cgi->end_table;

## Footer
$lchc->footer();

print $cgi->end_html();

exit(0);


sub postLink($) {
    my($confData) = @_;

    my $link = ("$lchc->{uri_add}?" .
		"type=$confData->{type}&" .
		"conference=$conference");

    return $cgi->a({-href=>$link}, "POST: $confData->{type}");
}

sub printLink($$) {
    my($confData, $toPrint) = @_;

    my $printList = join("&id=$confData->{type}\.", @$toPrint);
    my $link      = "$lchc->{uri_print}?id=$conferenceData->{type}\.$printList";

    return $cgi->a({-href=>$link, -target=>'_new'}, 'Print Conference');
}
