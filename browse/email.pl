#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse/email.pl
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
my $submit     = $cgi->param('submit');
my $course     = $cgi->param('course');
my $subject    = $cgi->param('subject');
my $message    = $cgi->param('message');

## Check parameter values
$user       = -1 if ! defined $user;
$submit     = '' if ! defined $submit;
$course     = -1 if ! defined $course;
$subject    = '' if ! defined $subject;
$message    = '' if ! defined $message;

my $sendmail = "/usr/sbin/sendmail -oi -t -odq";

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access((index=>0, admin=>0, header=>1));



####
## Now onto main part of the page
print $cgi->start_html({-title=>'Email Page', -style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

if($submit eq 'send' && $course > 0 && $message ne '') {
    ## Make the variables safe
#    $message = $lchc->safe_single_quotes($message);
    $subject = ('Subject: ' . $lchc->safe_single_quotes($subject));

    ## Get all the people
    my %sqlOptions = (course=>$course);
    my $query      = $db->sql_person_course(\%sqlOptions, {});
    my @results    = $db->complex_results($query);

    my $from     = "From: $lchc->{user_name} <$lchc->{user_email}>";
#    my $from     = 'From: The Wizard <lchc@lchc-resources.org>';
    my $to       = 'To: ';
    my $reply_to = 'Reply-To: nobody@ucsd.edu';

    ## Email al the people
    foreach my $person (@results) {
	$to .= "$person->{email}, ";
    }

    open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
    print SENDMAIL "$reply_to\n";
    print SENDMAIL "$subject\n";
    print SENDMAIL "$from\n";
    print SENDMAIL "$to\n";
    print SENDMAIL "Content-type: text/plain\n\n";
    print SENDMAIL "$message\n\n";
    close(SENDMAIL) or warn "sendmail didn't close nicely";

    ## Print the details
    print "The email was sent.";
    print $cgi->br;
    print $cgi->a({-href=>"$lchc->{uri_course}?course=$course"}, 'Return to the course page!');
    print $cgi->p;

} else {
    ## Start the form
    print $cgi->start_form({-method=>'post', -action=>$lchc->{admin_email}});
    print $cgi->hidden({-name=>'course', -value=>$course});
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, 'Send E-mail to Class');
    print $cgi->start_table();

    ## Get persons
    my %sqlOptions = ("$db->{tnCourse}.id" => $course);
    my $courseData = $db->get_course(\%sqlOptions, {});

    ## Print the form elements
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Course:'),
		   $cgi->td({-class=>'value'}, "$courseData->{program} $courseData->{number} - $courseData->{name}"));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Subject:'),
		   $cgi->td({-class=>'value'}, $cgi->textfield({-name=>'subject', -size=>25})));
    print $cgi->Tr($cgi->td({-class=>'label'}, 'Message:'),
		   $cgi->td({-class=>'value'}, $cgi->textarea({-name=>'message', -rows=>20, -cols=>60})));

    print $cgi->Tr($cgi->td(), $cgi->td($cgi->submit({-name=>'submit', -value=>'send'})));

    print $cgi->end_form();
    print $cgi->end_table();
    print $cgi->end_div();
}

## Footer
$lchc->footer;

print $cgi->end_html;
exit(0);
