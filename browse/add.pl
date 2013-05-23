#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/add.pl
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc   = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_reg});
my $conference = $cgi->param('conference');
my $fieldnote  = $cgi->param('fieldnote');
my $type       = $cgi->param('type');

## Check parameter values
$user       = -1 if ! defined $user;
$conference = -1 if ! defined $conference;
$fieldnote  = -1 if ! defined $fieldnote;
$type       = '' if ! defined $type;


## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'browse/add.pl',
				   action => 'post',
			           target => 'fieldnote/comment' });


## Access control
$lchc->control_access((index=>0, admin=>0, header=>1));



####
## Make sure this operation is possible and ok
if($type eq '' || $conference <= 0) {
    print $cgi->redirect({-location=>$lchc->{uri_index}});
    exit(0);
}

## Variables
my(%sqlOptions, %optionsOps, %menuOptions);
my($activityData, $conferenceData, $courseData,
   $fieldnoteData, $kidData);

####
## Retrieve a bunch of data if we can
%sqlOptions     = (id => $conference);
$conferenceData = $db->get_conference(\%sqlOptions, {}) if defined $conference && $conference > 0;
%sqlOptions     = (id => $fieldnote);
$fieldnoteData  = $db->get_fieldnote(\%sqlOptions, {})  if defined $fieldnote  && $fieldnote > 0;
%sqlOptions     = ("$db->{tnCourse}.id" => $conferenceData->{course});
$courseData     = $db->get_course(\%sqlOptions, {});

my(@activities, @kids, @files) = (undef, undef);
if(($type eq 'comment' || $type eq 'commentsite') && $fieldnote > 0) {
    my $query;

    ## Get up the activities
    %sqlOptions = (fieldnote => $fieldnote);
    $query      = $db->sql_fieldnote_activity(\%sqlOptions, {});
    @activities = $db->complex_results($query);

    ## Get up the kids
    $query = $db->sql_fieldnote_kid(\%sqlOptions, {});
    @kids  = $db->complex_results($query);

}

my $attachment = -1;
my $query   = $db->sql_course_space(( course => $courseData->{id}, type => 1 ));
my @results = $db->complex_results( $query );
if( scalar( @results ) > 0 ) {
    $attachment = $results[0]->{space};
}


####
## Print the fieldnote data
print $cgi->start_html({-title=>"Add $type",
			-style=>{-src=>$lchc->{uri_css}},
			-script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}}});
print $cgi->a({-name=>'top'});



## Toolbar
$lchc->toolbar();

if($courseData->{current} != 1 && $type eq 'fieldnote') {
    print $cgi->span({-class=>'header'},
		     'Sorry, but this course is over and no more fieldnotes can be posted.');

} else {
    ## get current day month yeah
    my $today =  `date "+%d %m %Y"`;
    my($d, $m, $y);
    if($today =~ m|(\d+)\s+(\d+)\s+(\d+)|) {
	$d = $1;
	$m = $2;
	$y = $3;
    }

    print $cgi->start_multipart_form({ -action => $lchc->{uri_insert},
				       -method => 'post', -name=>'addform',
				       -style  => 'margin-bottom:0;' });

    print $cgi->hidden({-name=>'type',       -value=>$type});
    print $cgi->hidden({-name=>'course',     -value=>$conferenceData->{course}});
    print $cgi->hidden({-name=>'conference', -value=>$conferenceData->{id}});
    print $cgi->hidden({-name=>'fieldnote',  -value=>$fieldnote});

    ## For Fieldnote
    if($type eq 'fieldnote') {
	my($query, @results, @sActivities, @sKids);

	###############################################
	## First see if we can narrow down the field ##
	## of kids and activities *using* the table  ##
	## t_kid_activity and t_course_activity      ##
	%sqlOptions = (course => $courseData->{id});
	$query      = $db->sql_course_activity(\%sqlOptions, {});
	@results    = $db->complex_results($query);
	if(scalar @results > 1) {
	    foreach my $row (@results) {
		push(@sActivities, $row->{activity});
	    }
	}

	%sqlOptions = (course => $courseData->{id});
	$query      = $db->sql_course_kid(\%sqlOptions, {});
	@results    = $db->complex_results($query);
	if(scalar @results > 1) {
	    foreach my $row (@results) {
		push(@sKids, $row->{kid});
	    }
	}

	#################################################
	## If we fail to narrow the field using either ##
	##  of those fields, then we will narrow the   ##
	##  field using last_referenced and _year_base ##
	if( scalar @sActivities <= 0 ) {
	    $query = $db->sql_activity( { 'year(last_referenced)' => $lchc->{_year_base}}, { 'year(last_referenced)' => '>=' } );
	    @results    = $db->complex_results($query);
	    if(scalar @results > 1) {
		foreach my $row (@results) {
		    push(@sActivities, $row->{id});
		}
	    }
	}

	if( scalar @sKids <= 0 ) {
	    $query = $db->sql_kid( { 'year(last_referenced)' => $lchc->{_year_base}}, { 'year(last_referenced)' => '>=' } );
	    @results    = $db->complex_results($query);
	    if(scalar @results > 1) {
		foreach my $row (@results) {
		    push(@sKids, $row->{id});
		}
	    }
	}

	##########################
	## Now Prepare the HTML ##
	##
	%menuOptions = ();
	%sqlOptions  = (order => 'name', sort => 'asc' );

	print $cgi->start_table();
	print $cgi->start_Tr();
	print $cgi->start_td();

	print $cgi->start_div({-class=>'box'});
	print $cgi->div({-class=>'box-title'}, 'Name');
	print $lchc->{user_name}, "<$lchc->{user_email}>";
	print $cgi->p;
	print $cgi->br;

        print $cgi->div({-class=>'box-title'}, 'Site');
	print $lchc->site_menu('site', 
			       {selected => 39, selectedOp => '==' },
			       { 'year(last_referenced)' => $lchc->{_year_base}, order => 'name', sort => 'asc' },
			       { 'year(last_referenced)' => '>' });

        print $cgi->p;
	print $cgi->br;

        print $cgi->div({-class=>'box-title'}, 'Date of Visit');
	%menuOptions = (selected => $m, selectedOp => '==');
	print $lchc->month_menu('dov_month', \%menuOptions, \%sqlOptions, {});
	%menuOptions = (selected => $d, selectedOp => '==');
	print $lchc->day_menu('dov_day',     \%menuOptions, \%sqlOptions, {});
	%menuOptions = (selected => $y, selectedOp => '==');
	print $lchc->year_menu('dov_year',   \%menuOptions, \%sqlOptions, {});
        print $cgi->p;
	print $cgi->br;

	## Kids menus
	if(scalar @sKids > 1) {
	    my $kidString = join(',', @sKids);
	    %optionsOps = (id => 'in');
	    %sqlOptions = (id => "($kidString)", order => 'first', sort => 'asc');
	} else {
	    %sqlOptions = (order => 'first', sort => 'asc');
	    %optionsOps = ();
	}
	$lchc->js_kid_menu('kid', {}, \%sqlOptions, \%optionsOps);
	print $cgi->script({-language=>'javascript'}, "moreFields('kid', 1)");
	print $cgi->br;

	####################
	## Activity Menus ##
	if(scalar @sActivities > 1) {
	    my $activityString = join(',', @sActivities);
	    %optionsOps = (id => 'in');
	    %sqlOptions = (id => "($activityString)", order => 'name', sort => 'asc');
	} else {
	    %sqlOptions = (order => 'name', sort => 'asc');
	    %optionsOps = ();
	}
	$lchc->js_activity_menu('activity', {}, \%sqlOptions, \%optionsOps);
	print $cgi->script({-language=>'javascript'}, "moreFields('activity', 1)");
	print $cgi->br;

        ## File FIelds for Upload / Attachment
        $lchc->js_file_upload( 'file', $attachment, '' );
        print $cgi->script({ -language => 'javascript' }, "moreFields('file', 1)" );
	print $cgi->br;

	## Rest of form
        print $cgi->div({-class=>'box-title'}, 'I. General Site Observations');
	print $cgi->textarea({-name=>'general', -rows=>20, -columns=>60});
	print $cgi->end_div();

	print $cgi->end_td();
	print $cgi->start_td({-style=>'padding-left: 9px'});

	print $cgi->start_div({-class=>'box'});
        print $cgi->div({-class=>'box-title'}, 'II. Narrative');
	print $cgi->textarea({-name=>'narrative', -rows=>14, -columns=>40});
        print $cgi->p;
	print $cgi->br;

        print $cgi->div({-class=>'box-title'}, 'III. Game-task Level Summary / Letter to Wizard');
        print $cgi->textarea({-name=>'gametask', -rows=>14, -columns=>40});
        print $cgi->p;
	print $cgi->br;

        print $cgi->div({-class=>'box-title'}, 'IV. Reflection');
        print $cgi->textarea({-name=>'reflection', -rows=>14, -columns=>40});
	print $cgi->end_div();

	print $cgi->br;

	## -onClick=>'return checkForm(document.forms[0]);',
	print $cgi->submit({-name=>'submit', -value=>"submit $type",
			    -style=>'text-transform: uppercase; border: 2px solid #000000; width: 200px; font-size: 20px;'});

	print $cgi->br;

	print $cgi->end_td();
	print $cgi->end_Tr();
	print $cgi->end_table();
	print $cgi->br;
	print $cgi->br;
	print $cgi->br;
    }

    ## For Comment;
    elsif($type eq 'comment' || $type eq 'commentsite') {
	## Add table
	print $cgi->start_table();
	print $cgi->start_Tr();
	print $cgi->start_td();

	#############################
	## We have a fieldnote we  ##
	##  we are responding to.  ##
	if( defined $fieldnoteData && $fieldnoteData->{id} > 0 ) {

	    #############################################
	    ## Get the attachments for this fieldnote. ##
	    my @attachments = ();
	    %sqlOptions     = ( fieldnote => $fieldnoteData->{id} );
	    $query          = $db->sql_fieldnote_attachment( \%sqlOptions, {} );
	    @attachments    = $db->complex_results( $query );

	    $lchc->fieldnote_display($fieldnoteData, \@attachments, \@activities, \@kids, {});
	}

	print $cgi->end_td();
	print $cgi->start_td();


	my $subject;
	if($type eq 'comment' && defined $fieldnoteData && $fieldnoteData->{id} > 0) {
	    $subject = ('Re: ' . $conferenceData->{name} . ' fieldnote');
	}

	# Display
	print $cgi->start_div({-class=>'box', -style=>'margin-left: 5px;'});
	print $cgi->div({-class=>'box-title'}, 'Submit Message');
	print $lchc->{user_name}, ' &lt;', $lchc->{user_email}, '&gt;';
	print $cgi->br;
	print 'Subject: ', $cgi->textfield({-name=>'subject', -size=>'25', -value=>$subject});
	print $cgi->br;
	print $cgi->textarea({-name=>'body', -rows=>25, -columns=>40});

        ## File FIelds for Upload / Attachment
        $lchc->js_file_upload( 'file', $attachment, '' );
        print $cgi->script({ -language => 'javascript' }, "moreFields('file', 1)" );

	print $cgi->end_div();

	## End the form
	print $cgi->submit({-onClick=>'return checkForm(document.forms[0]);',
			    -name=>'submit', -value=>"submit $type",
			    -style=>'text-transform: uppercase; border: 2px solid #000000; width: 200px; margin-left: 5px'});
				
#				print $cgi->submit({-name=>'submit', -value=>"submit $type"}));

	print $cgi->end_td();
	print $cgi->end_Tr();
	print $cgi->end_table();

    }

    print $cgi->end_form();
}

## Footer
$lchc->footer();

print $cgi->end_html();

exit(0);
