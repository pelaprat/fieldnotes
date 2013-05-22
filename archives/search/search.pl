#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: search/search.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/Users/web/perl'; }

use strict;
use CGI;
use LCHC::Notes;
use LCHC::SQL::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc = new LCHC::Notes( 'http://fieldnotes.ucsd.edu/archives' );

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie('lchcarchives');

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control
$lchc->control_access((index=>0, admin=>1, header=>1));


my %sqlOptions     = ();
my %sqlOptionsOps  = ();
my %menuOptions    = ();


#### 
## Now onto main part of the page
print $cgi->start_html({-title=>'Advanced Search',
                        -style=>{-src=>$lchc->{uri_css}},
                        -script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}},
			-onLoad=>"moreFields('kid'); moreFields('activity')"});


print $cgi->start_form({-method=>'get', -action=>$lchc->{uri_results}});

## Toolbar
$lchc->toolbar();

######
## Structure table
print $cgi->start_table();
print $cgi->start_Tr();
print $cgi->start_td();

######
## Time Span Selections
print $cgi->start_div({-class=>'box'});

## By Course
%menuOptions = (empty=>1, selected=>-1);
%sqlOptions  = (order => 'year', sort=>'desc');
print $cgi->div({-class=>'box-title'}, 'by course');
print $lchc->course_menu('course', \%menuOptions, \%sqlOptions, \%sqlOptionsOps);
print $cgi->br;
print $cgi->br;

## By Quarter
my $lyear = 0;
print $cgi->div({-class=>'box-title'}, 'by quarter');
my $sql = "select year from $db->{tnCourse} group by year order by year desc";
my @res = $db->simple_one_field_results($sql);
foreach my $year (@res) {
    if($year != $lyear) {
	print "$year: ";
	$lyear = $year;
    }

    my $sql2 = ("select id, quarter from $db->{tnCourse} course where year=$year " .
		"group by quarter order by quarter desc");
    my @res2 = $db->complex_results($sql2);
    foreach my $row (@res2) {
	print $cgi->checkbox({-name=>'quarters', -label=>'', -value=>"$year\.$row->{quarter}"});
	print "$row->{quarter} ";
    }

    print $cgi->br;
}
print $cgi->br;

## By Time Span
%menuOptions = %sqlOptions = %sqlOptionsOps = ();
print $cgi->div({-class=>'box-title'}, 'by time span');
print $lchc->day_menu('day_begin',     \%menuOptions);
print $lchc->month_menu('month_begin', \%menuOptions);
print $lchc->year_menu('year_begin',   \%menuOptions);
print ' to ';
print $cgi->br;
print $lchc->day_menu('day_end',     \%menuOptions);
print $lchc->month_menu('month_end', \%menuOptions);
print $lchc->year_menu('year_end',   \%menuOptions);
print $cgi->end_div();

print $cgi->end_td();
print $cgi->start_td({-style=>'padding-left: 9px; width: 200px;'});

######
## Search: Elementary Search Criteria
print $cgi->start_div({-class=>'box'});

print $cgi->div({-class=>'box-title'}, 'Student / Instructor');
%menuOptions = (empty=>1, selected=>-1);
%sqlOptions  = (order => 'last', sort => 'asc');
print $lchc->person_menu('person', \%menuOptions, \%sqlOptions, \%sqlOptionsOps);
print $cgi->p;

print $cgi->div({-class=>'box-title'}, 'Site');
%sqlOptions  = (order => 'name', sort => 'asc');
print $lchc->site_menu('site', \%menuOptions, \%sqlOptions, \%sqlOptionsOps);
print $cgi->p;

# $cgi->a({-onClick=>'this.parentNode.parentNode.removeChild(this.parentNode);'}, 'remove');

print $cgi->div({-class=>'box-title'}, 'Kids (',
		$cgi->a({-onClick=>"moreFields('kid')"}, 'add kid'), ')');
%sqlOptions  = (order => 'first', sort => 'asc');
print "<input type=hidden name='kid-counter' id='kid-counter' value=0>";
print $cgi->div({-id=>'box-kid', -style=>'display: none;'},
		$lchc->kid_menu('kid', \%menuOptions, \%sqlOptions, \%sqlOptionsOps));
print $cgi->span({-id=>'kid-insert'});
print $cgi->p;

print $cgi->div({-class=>'box-title'}, 'Activity (',
		$cgi->a({-onClick=>"moreFields('activity')"}, 'add activity'), ')');
%sqlOptions  = (order => 'name', sort => 'asc');
print "<input type=hidden name='activity-counter' id='activity-counter' value=0>";
print $cgi->div({-id=>'box-activity', -style=>'display: none;'},
		$lchc->activity_menu('activity', \%menuOptions, \%sqlOptions, \%sqlOptionsOps));
print $cgi->span({-id=>'activity-insert'});
print $cgi->p;

print $cgi->div({-class=>'box-title'}, 'Keywords');
print $cgi->textarea({-name=>'keywords', -cols=>40, -rows=>3});
print $cgi->p;

print $cgi->submit({-class=>'search', -name=>'submit', -value=>'begin search'});

print $cgi->end_div();
print $cgi->p;

print $cgi->end_td();
print $cgi->start_td({-style=>'padding-left: 9px; width: 200px'});

print $cgi->start_div({-class=>'box', -style=>''});
print $cgi->div({-class=>'box-title'}, 'Search Tips');
print $cgi->p("1. Searching 'by course' and 'by quarter' is either mutually  " ,
	      "exclusive or redundant, but searching by either category with " ,
	      "a timespan is not necessarily mutually exclusive or redundant.");
print $cgi->p("2. You must specify at least one keyword to search for.");
print $cgi->p("3. You can specify wildcards, like 'read*'.");
print $cgi->p("4. There are no 'OR' searches.  More than one keyword searched " ,
	      " with always be as an 'AND'.");
print $cgi->end_div();
print $cgi->p;

######
## End Structure table
print $cgi->end_td();
print $cgi->end_Tr();
print $cgi->end_table();

####
## End Search Form
print $cgi->end_form;

####
## Footer and stuff
$lchc->footer();

print $cgi->end_html;
exit(0);

