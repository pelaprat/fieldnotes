#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: search/results.pl
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

my @quarters     = $cgi->param('quarters');
my $person       = $cgi->param('person');
my $course       = $cgi->param('course');
my $conference   = $cgi->param('conference');
my $keywords     = $cgi->param('keywords');
my $site         = $cgi->param('site');

my $day_begin    = $cgi->param('day_begin');
my $month_begin  = $cgi->param('month_begin');
my $year_begin   = $cgi->param('year_begin');
my $day_end      = $cgi->param('day_end');
my $month_end    = $cgi->param('month_end');
my $year_end     = $cgi->param('year_end');

my $kid_counter      = $cgi->param('kid-counter');
my $activity_counter = $cgi->param('activity-counter');

my $r_begin  = $cgi->param('r_begin');
my $r_limit  = $cgi->param('r_limit');

## Check parameter values
$user        = -1   if ! defined $user;
$person      = -1   if ! defined $person;
$day_begin   = 1    if ! defined $day_begin;
$month_begin = 1    if ! defined $month_begin;
$year_begin  = 1989 if ! defined $year_begin;
$day_end     = 1    if ! defined $day_end;
$month_end   = 1    if ! defined $month_end;
$year_end    = 1989 if ! defined $year_end;

$kid_counter      = 0 if ! defined $kid_counter;
$activity_counter = 0 if ! defined $activity_counter;

## Insert the activities and kids for this fieldnote
my @activities = ();
foreach my $activity (1 .. $activity_counter) {
    my $act = $cgi->param("activity$activity");
    if(defined $act && $act > 0) {
	push( @activities, $act );
    }
}

my @kids = ();
foreach my $kid (1 .. $kid_counter) {
    my $act = $cgi->param("kid$kid");
    if(defined $act && $act > 0) {
	push( @kids, $act );
    }
}

$r_begin     = 0   if ! defined $r_begin;
$r_limit     = 100 if ! defined $r_limit;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control
$lchc->control_access((index=>0, admin=>1, header=>1));



## input values:
##  course:     <course>
##  quarters:   <quarters, ...>
##  day_begin, month_begin, year_begin
##  day_end,   month_end,   year_end
##
##  conference: <conference>
##  person:     <person>
##  site:       <site>
##  kids:       <kid, ...>
##  activities: <activity, ...>
##  keywords:   <word, ...>
##

## Toolbar
$lchc->toolbar();

##########################################
## STEP 1: Set the base paramters to be ##
##  retrieved from the search query.    ##
##
my $query          = ("select SQL_CALC_FOUND_ROWS              " .
		      "$db->{tnFieldnote}.id  as 'fieldnote',  " .
		      "$db->{tPerson}.id      as 'person',     " .
		      "$db->{tnConference}.id as 'conference', " .
		      "$db->{tnCourse}.id     as 'course',     " .

		      "DATE_FORMAT($db->{tnFieldnote}.dateofvisit, $lchc->{format_date}) as 'dateofvisit',  " .
		      "CONCAT_WS(' ', $db->{tPerson}.first, $db->{tPerson}.middle  ,                        " .
		      "           $db->{tPerson}.last) as 'person_name',                                    " .

		      "$db->{tnConference}.name as 'conference_name', " .

		      "$db->{tnCourse}.name as 'course_name',          " .
		      "$db->{tnCourse}.quarter, $db->{tnCourse}.year,  " .
		      "$db->{tnCourse}.program, $db->{tnCourse}.number " .

		      "from $db->{tnFieldnote}                         " .

		      "left join $db->{tPerson}      on $db->{tnFieldnote}.person     = $db->{tPerson}.id      " .
		      "left join $db->{tnConference} on $db->{tnFieldnote}.conference = $db->{tnConference}.id " .
		      "left join $db->{tnCourse}     on $db->{tnFieldnote}.course     = $db->{tnCourse}.id     ");

#######################################
## STEP 2:  Then Kids and Activities ##
##
$query .= " left join $db->{tnFieldnoteKid} on $db->{tnFieldnote}.id = $db->{tnFieldnoteKid}.fieldnote "
    if( scalar( @kids ) > 0 );

$query .= " left join $db->{tnFieldnoteActivity} on $db->{tnFieldnote}.id = $db->{tnFieldnoteActivity}.fieldnote "
    if( scalar( @activities ) > 0 );

##############################################
## STEP 3: Are there specifying parameters? ##
##         Do we need a where clause?       ##
##
if( scalar(@quarters) > 0   || $course >= 1 || $conference     >= 1 || $person >= 1              ||
    $keywords         ne '' || $site   >= 1 || scalar( @kids ) >  0 || scalar( @activities ) > 0 ||
    $day_begin != $day_end  || $month_begin != $month_end || $year_begin != $year_end ) {

    ###########################
    ## Add the where clause. ##
    $query .= ' where 1=1 ';

    ##########################
    ## Kids and activities. ##
    $query .= " and $db->{tnFieldnoteKid}.kid in (" . join(',', @kids) . ') '
	if( scalar( @kids ) > 0 );
    $query .= " and $db->{tnFieldnoteActivity}.activity in (" . join(',', @activities) . ') '
	if( scalar( @activities ) > 0 );
}

##################################
## STEP 4: Set Time Parameters. ##
##
if(scalar(@quarters) > 0) {
    my @info = ();
    foreach my $quarter (@quarters) {
	$quarter =~ m|^(\d+)\.(\w+)|;
	push( @info, "($db->{tnCourse}.year = $1 and $db->{tnCourse}.quarter = '$2') ");
    }
    $query .= (' and (' . join(' or ', @info) . ') ');
}

###########################################
## STEP 5: Then the time/date parameters ##
##
if((($day_begin*10) + ($month_begin*10000) + ($year_begin*1000000)) <=
   (($day_end*10)   + ($month_end*10000)   + ($year_end*1000000)) &&
   !($day_begin   == 1    && $day_end   == 1 &&
     $month_begin == 1    && $month_end == 1 &&
     $year_begin  == 1989 && $year_end  == 1989)) {

    ## Now edit the SQL
    $query .= ("and $db->{tnFieldnote}.dateofvisit >= '$year_begin-$month_begin-$day_begin 00:00:00' " .
	       "and $db->{tnFieldnote}.dateofvisit <= '$year_end-$month_end-$day_end 23:59:59'       ");
}

########################################
## STEP 6: Set Course and Conference. ##
##
$query .= " and $db->{tnFieldnote}.course=$course         " if $course     >= 1;
$query .= " and $db->{tnFieldnote}.conference=$conference " if $conference >= 1;
$query .= " and $db->{tnFieldnote}.person=$person         " if $person     >= 1;
$query .= " and $db->{tnFieldnote}.site=$site             " if $site       >= 1;

###########@@@@@@@@######################
## STEP 7: Then the keyword paramters. ##
##
$keywords =~ s/\n//g;
$keywords =~ s/\r//g;

if($keywords ne '') {
    my $k = $keywords;
    $k =~ s/\sand\s//g;
    $k =~ s/\sor\s//g;
    $k =~ s/\*//g;
    $k =~ s/(\w+)/+$1/g;
    $k = $lchc->safe_single_quotes($k);

    $query .= " and match(general, narrative, gametask, reflection) against('$k' in boolean mode) ";
}

############################################
#### AND THEN FINALLY CONTENT SPECIFIC #####

## Retrieval limits, spans
$query .= " order by $db->{tnFieldnote}.dateofvisit desc";
$query .= " limit $r_begin, $r_limit";

########################
## Perform the Search ##

my @results  = $db->complex_results($query);
my @num_rows = $db->simple_one_field_results("select found_rows()");
my $num_rows = pop(@num_rows);

###########################################
## Prepare some of the display variables ##
my $nr_k     = 0;
my $nr_page  = 1;
my $previous = '';
my $next     = '';
my $to_value = $r_begin  +  $r_limit;
   $to_value = $num_rows if ($to_value > $num_rows);

my $show_all;
my $deselect_all = $cgi->a({-onClick=>'uncheckAllBoxes(document.forms[0]);', -href=>'#'}, 'Select None');
my $select_all   = $cgi->a({-onClick=>'checkAllBoxes(document.forms[0]);', -href=>'#'}, 'Select All');
my $print_all    = ($cgi->a({-onClick=>'uncheckAllBoxes(document.forms[0].submit());', -href=>'#'},
			    $cgi->img({-src=>"$lchc->{uri_images}/print.gif", -border=>0, -style=>'vertical-align: bottom'})) .
		    $cgi->a({-onClick=>'uncheckAllBoxes(document.forms[0].submit());', -href=>'#'}, 'Print Selected'));

if($r_limit != 100) {
    $show_all = $cgi->a({-href=>&search_url(0, 100)}, 'Show first 100');
} else {
    $show_all = $cgi->a({-href=>&search_url(0, $num_rows)}, 'Show all');
}

## Previous / next page links
if($r_limit == 100 && $num_rows > $r_limit) {
    my($url);

    if(($r_begin+1) > $r_limit) {
	$url  = &search_url(($r_begin-$r_limit), $r_limit);
	$previous = ('< ' . $cgi->a({-href=>$url}, 'Previous'));
    }

    if(($r_begin+1) > $r_limit && ($r_begin + $r_limit) < $num_rows) {
	$previous .= $cgi->span({-style=>'padding-left: 2px'}, '&nbsp;');
    }

    if(($r_begin + $r_limit) < $num_rows) {
	$url  = &search_url(($r_begin+$r_limit), $r_limit);
	$next = ($cgi->a({-href=>$url}, 'Next') . ' ' . ' >');
    }
}


############################
## Main Page / Start HTML ##
print $cgi->start_html({-title=>'Fieldnotes DB Search Results',
			-style=>{-src=>$lchc->{uri_css}},
			-script=>{-language=>'javascript',
				  -src=>$lchc->{uri_javascript}}});

print $cgi->start_form({-name=>'print_items', -method=>'get', -action=>$lchc->{uri_print}});
print $cgi->hidden({-name => 'keywords', -value => $keywords});

######
## Search Results Toolbar
print $cgi->start_table({-class=>'resultsToolbar', -width => '100%'});
print $cgi->start_Tr();
print $cgi->td({-class=>'left'},
	       "$num_rows results found.  ", $cgi->br,
	       "Showing ", ($r_begin+1), " to ", $to_value);
print $cgi->start_td({-class=>'pages', -colspan=>2});
while($nr_k < $num_rows) {
    if($nr_k == $r_begin) {
	print "$nr_page ";
    } else {
	my $link = &search_url($nr_k, $r_limit);
	print $cgi->a({-href=>$link}, $nr_page);
	print ' ';
    }
    $nr_k += $r_limit;
    $nr_page++;
}
print $cgi->end_td();
print $cgi->td({-class=>'right'},
	       $select_all, ' | ', $deselect_all, $cgi->br,
	       $print_all,  ' | ', $show_all);
print $cgi->end_Tr();

print $cgi->start_Tr({-class=>'toolbar'});
print $cgi->td({-class=>'left'}, $previous);
print $cgi->td({-colspan=>2});
print $cgi->td({-class=>'right'}, $next);
print $cgi->end_Tr();
print $cgi->end_table();

######
## Now the Results
print $cgi->start_table({-class=>'results'});
print $cgi->Tr($cgi->th(''), $cgi->th('Date of Visit'), $cgi->th('Name'), $cgi->th('Course'));

foreach my $row (@results) {
    # Get the link
    my $link = ("$lchc->{uri_course}?" . 
		"course=$row->{course}&" .
		"conference=$row->{conference}&" .
		"keywords=$keywords#$row->{fieldnote}");

    # Get the checkbox
    my $checkbox = $cgi->checkbox({-name=>'id', -value=>"fieldnote\.$row->{fieldnote}",
				   -label=>'',  -onClick=>'toggleRow(this);'});

    print $cgi->Tr({-class => 'result'},
		   $cgi->td({-class=>'check', -onClick => ';'}, $checkbox),
		   $cgi->td({-onClick => "return followLink(event, this, \'$link\');"},
			    $cgi->span({-class=>'date'},   $row->{dateofvisit})),
		   $cgi->td({-onClick => "return followLink(event, this, \'$link\');"},
			    $cgi->span({-class=>'person'}, $row->{person_name})),
		   $cgi->td({-onClick => "return followLink(event, this, \'$link\');"},
			    $cgi->span({-class=>'title'},  ("$row->{program} - $row->{number} $row->{course_name} " .
							    "[$row->{quarter} $row->{year}]"))));

    print $cgi->Tr($cgi->td({-class=>'divider', -colspan=>4}));
}
print $cgi->end_table();
print $cgi->end_form();

######################
## Footer and stuff ##
$lchc->footer;

print $cgi->end_html;

exit(0);

###########################
sub search_url($$) {
    my($s_begin, $s_limit) = @_;

    my $q   = join('&quarters=',  @quarters)  || '';
    my $p   = join('&person=',    $person)    || '';
    my $c   = $course                         || '';
    my $f   = $conference                     || '';
    my $k   = $keywords                       || '';

    $q   = "&quarters=$q"   if $q ne '';
    $p   = "&person=$p"     if $p ne '';
    $c   = "&course=$c"     if $c ne ''; 
    $f   = "&conference=$f" if $c ne ''; 
    $k   = "&keywords=$k";

    return ("$lchc->{uri_results}?$q$p$c$f$k&" .
	    "day_begin=$day_begin&month_begin=$month_begin&year_begin=$year_begin&" .
	    "day_end=$day_end&month_end=$month_end&year_end=$year_end&" .
	    "r_begin=$s_begin&r_limit=$s_limit");
}

sub result_td($) {

}
