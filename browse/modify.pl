#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/modify
##

## Make sure we point correctly
BEGIN { push @INC, '../LCHC'; }

use diagnostics;
use strict;
use CGI;
use LCHC::SQL::Notes;
use LCHC::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user     = $cgi->cookie($lchc->{cookie_name_reg});
my $id       = $cgi->param('id');
my $submit   = $cgi->param('submit');

my $general    = $cgi->param('general');
my $narrative  = $cgi->param('narrative');
my $gametask   = $cgi->param('gametask');
my $reflection = $cgi->param('reflection');

my $kid_counter      = $cgi->param('kid-counter');
my $activity_counter = $cgi->param('activity-counter');

## Check parameter values
$user     = -1 if ! defined $user;
$id       = -1 if ! defined $id;
$submit   = '' if ! defined $submit;

$general    = '' if ! defined $general;
$narrative  = '' if ! defined $narrative;
$gametask   = '' if ! defined $gametask;
$reflection = '' if ! defined $reflection;

$kid_counter      =  0 if ! defined $kid_counter;
$activity_counter =  0 if ! defined $activity_counter;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

#################################
## Check if modified fieldnote ##
if($submit eq 'update') {
    my $query;

    $general    = $lchc->safe_single_quotes($general);
    $narrative  = $lchc->safe_single_quotes($narrative);
    $gametask   = $lchc->safe_single_quotes($gametask);
    $reflection = $lchc->safe_single_quotes($reflection);

    ## Now update the database
    $query = ('update tn_fieldnote set       ' .
	      " general    = '$general',     " .
	      " narrative  = '$narrative',   " .
	      " reflection = '$reflection',  " .
	      " gametask   = '$gametask'     " .
	      " where id = $id               ");

    $db->do($query);

    ########################################################
    ## Update the activities and the children             ##
    ##                                                    ##
    ## First delete the existing associations             ##
    ##
    $db->do("delete from $db->{tnFieldnoteActivity} where fieldnote = $id");
    ##
    ## Insert the activities and kids for this fieldnote  ##
    ##
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
            $db->simple_add($db->{tnFieldnoteActivity},
                            ($id, $act, $tkc, $min));
        }
    }


    ########################################################
    ## Update the activities and the children             ##
    ##                                                    ##
    ## First delete the existing associations             ##
    ##
    $db->do("delete from $db->{tnFieldnoteKid} where fieldnote = $id");
    ##
    ## Insert the activities and kids for this fieldnote  ##
    ##
    foreach my $kid (1 .. $kid_counter) {
        my $k = $cgi->param("kid$kid");

        if(defined $k && $k > 0 &&
           $db->fieldnote_kid_exists($id, $k) == 0) {
            $db->simple_add($db->{tnFieldnoteKid}, ($id, $k));
        }
    }



} elsif($submit eq 'delete') {
    my $tnFieldnote         = $db->{tnFieldnote};
    my $tnFieldnoteKid      = $db->{tnFieldnoteKid};
    my $tnFieldnoteActivity = $db->{tnFieldnoteActivity};

    $db->do("delete from $tnFieldnote         where id=$id");
    $db->do("delete from $tnFieldnoteKid      where fieldnote=$id");
    $db->do("delete from $tnFieldnoteActivity where fieldnote=$id");

    print $cgi->redirect({-location=>$lchc->{uri_modify}});
    exit(0);
}



###############################
## Grab some fieldnote data. ##
##
my(%sqlOptions, %optionsOps, $fieldnote) = ((), (), undef);
%sqlOptions = (id => "$id");
$fieldnote  = $db->get_fieldnote(\%sqlOptions, {});

## Access control
$lchc->control_access((index=>0, admin=>1, header=>1));

####
## Start the html
print $cgi->start_html({-title=>'Modify',
			-style=>{-src=>$lchc->{uri_css}},
			-script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}}});

$lchc->toolbar();

## Jump form
print $cgi->start_form({-action=>'/fieldnote/browse/modify.pl', -method=>'post'});
print $cgi->textfield({-name=>'id', -size=>6, -value=>$id});
print $cgi->submit({-name=>'submit', -value=>'go!'});
print $cgi->end_form();

print $cgi->p;

print $cgi->a({ -href => "$lchc->{uri_course}?course=$fieldnote->{course_id}&conference=$fieldnote->{conference_id}#fieldnote.$fieldnote->{id}"}, 'Return to Conference');

if($db->fieldnote_exists($id) == 0) {
    print 'Fieldnote does not exist.';

} elsif(1 == 1) {

    #############
    ### SET UP ##
    my(%menuOptions, $query, @results, @sActivities, @sKids, @fKids,
       @fActivities) = ((), undef, (), (), (), (), ());

    ##########
    ## Kids ##
    %sqlOptions = (fieldnote => $id);
    $query   = $db->sql_fieldnote_kid(\%sqlOptions, {});
    @results = $db->complex_results($query);
    foreach my $row (@results) {
	push (@fKids, $row->{kid});
    }

    ################################################
    ## First see if we can narrow down the field  ##
    ## of kids and activities;                    ##
    ##


    %sqlOptions = (course => $fieldnote->{course_id});
    $query      = $db->sql_course_kid(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    if(scalar @results > 1) {
	foreach my $row (@results) {
	    push(@sKids, $row->{kid});
	}
    }

    #####################################################
    #####################################################

    print $cgi->start_form({-action=>'/fieldnote/browse/modify.pl', -method=>'post'});
    print $cgi->start_table();
    print $cgi->start_Tr();
    print $cgi->start_td();

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Name');
    print $fieldnote->{person_name}, "<$fieldnote->{person_email}>";
    print $cgi->p;

    print $cgi->div({-class=>'box-title'}, 'Site');
    print $fieldnote->{site_name};
    print $cgi->p;

    print $cgi->div({-class=>'box-title'}, 'Date of Visit');
    print $fieldnote->{dateofvisit};
    print $cgi->p;


    #####################################################
    #####################################################

    ######################################## 
    ##             Kids menus             ##
    ##                                    ##
    ## First get a list of the activities ##
    ##  specific to this course.          ##
    ##
    %sqlOptions = (course => $fieldnote->{course_id});
    $query      = $db->sql_course_kid(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    if(scalar @results > 1) {
	foreach my $row (@results) {
	    push(@sKids, $row->{kid});
	}

	my $ActString = join(',', @sKids);
	%sqlOptions = (id => "($ActString)", order => 'first', sort => 'asc');
	%optionsOps = (id => 'in');

    } else {
	%sqlOptions = (order => 'first', sort => 'asc');
	%optionsOps = ();
    }

    #############################
    ## Place the kid menu ##
    #
    $lchc->js_kid_menu( 'kid', \%menuOptions,
			\%sqlOptions, \%optionsOps );

    ########################################
    ##                                    ##
    ##  Add the proper activities to this ##
    ##   fieldnote.                       ##
    ##
    %sqlOptions = (fieldnote => $id);
    $query   = $db->sql_fieldnote_kid(\%sqlOptions, {});
    @results = $db->complex_results($query);
    foreach my $row (@results) {
	print "<script language=javascript>moreFields('kid', $row->{kid}, 0, 0)</script>";
    }


    print $cgi->p;
    print $cgi->p;


    ######################################## 
    ##       Activities menus             ##
    ##                                    ##
    ## First get a list of the activities ##
    ##  specific to this course.          ##
    ##
    %sqlOptions = (course => $fieldnote->{course_id});
    $query      = $db->sql_course_activity(\%sqlOptions, {});
    @results    = $db->complex_results($query);
    if(scalar @results > 1) {
	foreach my $row (@results) {
	    push(@sActivities, $row->{activity});
	}

	my $ActString = join(',', @sActivities);
	%sqlOptions = (id => "($ActString)", order => 'name', sort => 'asc');
	%optionsOps = (id => 'in');

    } else {
	%sqlOptions = (order => 'name', sort => 'asc');
	%optionsOps = ();
    }

    #############################
    ## Place the activity menu ##
    #
    $lchc->js_activity_menu( 'activity',   \%menuOptions,
			     \%sqlOptions, \%optionsOps );

    ########################################
    ##                                    ##
    ##  Add the proper activities to this ##
    ##   fieldnote.                       ##
    ##
    %sqlOptions = (fieldnote => $id);
    $query   = $db->sql_fieldnote_activity(\%sqlOptions, {});
    @results = $db->complex_results($query);
    foreach my $row (@results) {
	print ("<script language=javascript>moreFields('activity', $row->{activity}, ",
	       "$row->{timeontask}, $row->{taskcard})</script>");
    }


    ##################
    ## Rest of form ##
    print $cgi->div({-class=>'box-title'}, 'I. General Site Observations');
    print $cgi->textarea({-name=>'general', -default=>$fieldnote->{general}, -rows=>20, -columns=>60});
    print $cgi->end_div();
    print $cgi->p;
    print $cgi->hidden({-name=>'id', -value=>$id});
    print $cgi->center($cgi->submit({-name=>'submit', -value=>'update'}));
##		       $cgi->submit({-name=>'submit', -value=>'delete'}));

    print $cgi->end_td();
    print $cgi->start_td({-style=>'padding-left: 9px'});

    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'II. Narrative');
    print $cgi->textarea({-name=>'narrative', -default=>$fieldnote->{narrative}, -rows=>11, -columns=>60});
    print $cgi->p;

    print $cgi->div({-class=>'box-title'}, 'III. Game-task Level Summary');
    print $cgi->textarea({-name=>'gametask', -default=>$fieldnote->{gametask}, -rows=>11, -columns=>60});
    print $cgi->p;

    print $cgi->div({-class=>'box-title'}, 'IV. Reflection');
    print $cgi->textarea({-name=>'reflection', -default=>$fieldnote->{reflection}, -rows=>12, -columns=>60});
    print $cgi->end_div();

    print $cgi->end_td();
    print $cgi->end_Tr();
    print $cgi->end_table();
    print $cgi->end_form();

}

## Footer
$lchc->footer();

print $cgi->end_html();

exit(0);
