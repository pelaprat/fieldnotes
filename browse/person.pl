#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/person.pl
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
my $lchc = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookie_name_reg});
my $id   = $cgi->param('id');

## Check parameter values
$user       = -1 if ! defined $user;
$id         = -1 if ! defined $id;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);


######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'browse/print.pl',
				   action => 'view' });

## Access control
$lchc->control_access((index=>0, admin=>0, header=>1));



## Variables
my(@courses, @comments, $query, $person, @fieldnotes, %sqlOptions, %optionsOps);

## Retrieve the person data
%sqlOptions = (id => $id);
$person     = $db->get_person(\%sqlOptions, {});

## Print the fieldnote data
print $cgi->start_html({-title=>"Profile: $person->{first} $person->{middle} $person->{last}",
                        -style=>{-src=>$lchc->{uri_css}},
                        -script=>{-language=>'javascript',
                                  -src=>$lchc->{uri_javascript}}});

## Toolbar
$lchc->toolbar();

####
## Personal information
print $cgi->start_table();
print $cgi->start_Tr();

## Name/email
print $cgi->start_td();
print $cgi->span({-class=>'subheader'}, 'Personal Information');
print $cgi->br;

print $cgi->start_table({-class=>''});
print $cgi->Tr($cgi->td({-class=>'label'}, 'Name:'),
	       $cgi->td({-class=>'value'}, "$person->{first} $person->{middle} $person->{last}"));
print $cgi->Tr($cgi->td({-class=>'label'}, 'Email:'),
	       $cgi->td({-class=>'value'}, $person->{email}));
print $cgi->end_table();
print $cgi->end_td();

## Courses they are in
%sqlOptions = (person=>$id);
$query      = $db->sql_person_course(\%sqlOptions, {});
@courses    = $db->complex_results($query);

print $cgi->start_td({-style=>'padding-left: 25px'});
print $cgi->span({-class=>'subheader'}, 'Subscribed Courses');
print $cgi->br;
print $cgi->start_table({-class=>''});
foreach my $row (@courses) {
    my $link = "$lchc->{uri_course}?course=$row->{course}";
    print $cgi->Tr($cgi->td($cgi->a({-href=>$link}, ("$row->{program} $row->{number} - $row->{name} " .
						     "[$row->{quarter} $row->{year}]"))));
}
print $cgi->end_table();
print $cgi->end_td();

print $cgi->end_Tr();
print $cgi->end_table();

#################################################
## Get all the fieldnote posts for this person ##
%sqlOptions = (person => $id);
%optionsOps = (order  => 'rtimestamp', sort => 'desc');
$query      = $db->sql_fieldnote(\%sqlOptions, \%optionsOps);
@fieldnotes = $db->complex_results($query);

## Print them
print $cgi->p;
print $cgi->start_table({-class=>'results'});
print $cgi->Tr($cgi->td({-colspan=>4}, ("Your fieldnotes (" . scalar(@fieldnotes) . " total)")));
print $cgi->Tr($cgi->th('Date'), $cgi->th('Subject'), $cgi->th('Conference'), $cgi->th('Course'));
foreach my $row (@fieldnotes) {
    my $link = "$lchc->{uri_course}?course=$row->{course_id}&conference=$row->{conference_id}#$row->{id}";
    print $cgi->Tr({-onClick => "return followLink(event, this, \"$link\");",
                    -class   => 'results'}, 
		   $cgi->td($cgi->span({-class=>'date'},   $row->{timestamp})),
		   $cgi->td($cgi->span({-class=>'title'},  '--')),
		   $cgi->td($cgi->span({-class=>'person'}, $row->{conference_name})),
		   $cgi->td($cgi->span({-class=>'person'},
				       ("$row->{course_program} $row->{course_number} - " .
					"$row->{course_name} [$row->{course_quarter} $row->{course_year}]"))));
}
print $cgi->end_table();


#################################################
## Get all the comment posts for this person ##
%sqlOptions = (person => $id);
%optionsOps = (order  => 'rtimestamp', sort => 'desc');
$query      = $db->sql_comment(\%sqlOptions, \%optionsOps);
@comments   = $db->complex_results($query);

## Print them
print $cgi->p;
print $cgi->start_table({-class=>'results'});
print $cgi->Tr($cgi->td({-colspan=>4}, ("Your comments (" . scalar(@comments) . " total)")));
print $cgi->Tr($cgi->th('Date'), $cgi->th('Subject'), $cgi->th('Conference'), $cgi->th('Course'));
foreach my $row (@comments) {
    my $link = "$lchc->{uri_course}?course=$row->{course_id}&conference=$row->{conference_id}#comment.$row->{id}";

    print $cgi->Tr({-onClick => "return followLink(event, this, \"$link\");",
		    -class   => 'result'},
		   $cgi->td($cgi->span({-class=>'date'},   $row->{timestamp})),
		   $cgi->td($cgi->span({-class=>'title'},  $row->{subject})),
		   $cgi->td($cgi->span({-class=>'person'}, $row->{conference_name})),
		   $cgi->td($cgi->span({-class=>'person'},
				       ("$row->{course_program} $row->{course_number} - " .
					"$row->{course_name} [$row->{course_quarter} $row->{course_year}]"))));
}
print $cgi->end_table();


## Footer
$lchc->footer();

## End
print $cgi->end_html();

exit(0);
