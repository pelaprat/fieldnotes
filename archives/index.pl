#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: index.pl
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

my(%sqlOptions, %optionsOps);

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);

$db->set_pn($lchc);

## Access control, we are the index
$lchc->control_access(( index => 1, admin => 0, header => 1 ));



####
## Now onto main part of the page
print $cgi->start_html({-title=>'LCHC Fieldnotes DB', -style=>{-src=>$lchc->{uri_css}}});

####
## Nobody is logged in,
##  so let them log in.
if($user <= 0) {

    print $cgi->start_form({-method=>'post', -action=>$lchc->{uri_login}});
    print $cgi->start_center;
    print $cgi->start_div({-class=>'box', -style=>'width: 300px; border: 3px solid #000000'});
    print $cgi->start_div({-class=>'login'});
    print $cgi->div({-class=>'box-title', -style=>'font-size: 14px'}, 'LCHC Database ARCHIVES');
    print '(list is alphabetically sorted by last name)';
    print $lchc->person_menu( 'user', {}, { admin => 1 }, { order => 'last', sort => 'asc' });
    print $cgi->br;
    print $cgi->password_field({-name=>'pass', -size=>'25'});
    print $cgi->br;
    print $cgi->submit({-name=>'submit', -value=>'login'});
    print $cgi->end_div;
    print $cgi->end_div;
    print $cgi->br;
    print $cgi->img({-src=>'http://gallery.photo.net/photo/2265830-md.jpg', -style=>'border: 3px solid #000000'});
    print $cgi->p;
    print $cgi->a({-href=>'http://www.photo.net/photodb/photo?photo_id=2265830', -style=>'font-size: 9px'},
		  'photo credit');
    print $cgi->end_center;
    print $cgi->end_form;

} else {
    ## Toolbar
    $lchc->toolbar();

    ## Table to organize the front page
    print $cgi->start_table();
    print $cgi->start_Tr();
    print $cgi->start_td();

    ## Splash
    print $cgi->img({-src=>"$lchc->{uri_images}/database.gif", -style=>'width: 23px; height: 25px'});
    print $cgi->span({-class=>'header', -style=>'padding-left: 5px'}, 'Archive Database');
    print $cgi->br;
    print $cgi->span({ -style => 'font-size: 12px; font-weight: bold; color: red' },
		     $cgi->a({ -href => 'http://fieldnotes.ucsd.edu/index.pl' }, 'Regular Fieldnotes Database' ));
    print $cgi->hr({-size=>1});
    print $cgi->p;

    ## Print current courses
    %optionsOps = ( );
    %sqlOptions = ( order => 'year', sort => 'desc' );
    &courses('Current Courses',  $db->sql_course(\%sqlOptions, \%optionsOps));
    print $cgi->p;

    ## Structure table
#    print $cgi->end_td();
#    print $cgi->start_td({-style=>'padding-left: 9px; width: 400px'});

    ## End Structure Table
    print $cgi->end_td();
    print $cgi->end_Tr();
    print $cgi->end_table();

    ####
    ## Footer and stuff
    $lchc->footer;
}

print $cgi->end_html;
exit(0);

sub courses($$) {
    my($title, $query) = @_;
    my $year = 0;

    ## Get the results and print the courses
    my @res = $db->complex_results($query);
    print $cgi->start_div({-class=>'box'});
    print $cgi->div({-class=>'box-title'}, $title);
    print $cgi->start_table;
    foreach my $row (@res) {
	if($year != $row->{year}) {
	    print $cgi->Tr($cgi->td($cgi->br, $cgi->span({-style=>'font-weight: bold'}, $row->{year})));
	    $year = $row->{year};
	}

        my $text = "$row->{program} $row->{number} - $row->{name} [$row->{quarter} $row->{year}]";
        my $link = $cgi->a({-href=>"$lchc->{uri_course}?course=$row->{id}"}, $text);
        print $cgi->Tr($cgi->td($link));
    }
    print $cgi->end_table;
    print $cgi->end_div;
}
