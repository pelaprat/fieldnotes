#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: index.pl
##

## Make sure we point correctly
BEGIN { push @INC, 'LCHC'; }

use strict;
use CGI;
use LCHC::Notes;
use LCHC::SQL::Notes;

## Build the basic objects
my $cgi  = new CGI;
my $db   = new LCHC::SQL::Notes;
my $lchc   = new LCHC::Notes;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($lchc->{cookieName});

## Check parameter values
$user = -1 if ! defined $user;

my(%sqlOptions, %optionsOps);

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'index.pl',
				   action => 'view',
			           target => 'index' } );

## Access control, we are the index
$lchc->control_access((index=>1, admin=>0, header=>1));



####
## Now onto main part of the page
print $cgi->start_html({-title=>'LCHC Fieldnotes DB', -style=>{-src=>$lchc->{uri_css}}});

####
## Nobody is logged in,
##  so let them log in.
if( $user <= 0 ) {

    ##############################################
    ## Get the correct list of people to login. ##
    my @currents = ();
    my $query    = $db->sql_person_course({ current => 1 }, { order => 't_person.last', sort => 'asc' });
    my @results  = $db->complex_results($query);
    foreach my $current (@results) {
	push( @currents, $current->{person} );
    }

    %sqlOptions = ( admin => 1 );
    $query   = $db->sql_person( \%sqlOptions, {} );
    @results = $db->complex_results( $query );
    foreach my $admin (@results) {
	push( @currents, $admin->{id} );
    }

    ######################################
    ## Not logged, suggest they log in. ##
    my $finalList = join( ',', @currents );
    %optionsOps = ( id => 'in');
    %sqlOptions = ( id => "($finalList)", order  => 'last', sort => 'asc' );

    print $cgi->start_form({-method=>'post', -action=>$lchc->{uri_login}});
    print $cgi->start_center;
    print $cgi->start_div({-class=>'box', -style=>'width: 300px; border: 3px solid #000000'});
    print $cgi->start_div({-class=>'login'});
    print $cgi->div({-class=>'box-title', -style=>'font-size: 14px'}, 'LCHC Database');
    print '(list is alphabetically sorted by last name)';
    print $lchc->person_menu('user', {}, \%sqlOptions, \%optionsOps);
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

    ## Splash
    print $cgi->start_center();
    print $cgi->start_div({ -style => 'padding-left: 20px; width: 440px' });
    print $cgi->img({-src=>"$lchc->{uri_images}/database.gif", -style=>'width: 23px; height: 25px'});
    print $cgi->span({-class=>'header', -style=>'padding-left: 5px'}, 'LCHC Fieldnotes Database');
    print $cgi->br;
    print $cgi->p({-style=>'text-align: justify; font-size: 13px'},
		  'Welcome to the LCHC Fieldnotes Database, web software that will allow you to post, ',
		  'retrieve and find fieldnotes for your courses and others.  We hope that this ',
		  'software can also help you write your research papers by giving you access to ',
		  'over 15 years of valuable LCHC data.  For more information on LCHC, please ',
		  $cgi->a({-href=>'http://lchc.ucsd.edu'}, ' follow this link to the homepage.'),
		  'If you have trouble using the LCHC Database or Webboard, please contact ',
		  $cgi->a({-href=>'mailto:bjones@ucsd.edu'}, 'Bruce Jones.'),
		  'Otherwise, select your course from below to get started!');
    print $cgi->br;
    print $cgi->hr({ -size=>1 });
    print $cgi->div({ -style => 'text-align: left;' }, $cgi->br, $cgi->b('Courses:'), $cgi->p );

    ###########################
    ## Print current courses ##
    %optionsOps = ( year => '>=', program => '!=' );
    %sqlOptions = ( year => $lchc->{_year_base}, order => 'year', sort => 'desc' );
    &courses( $db->sql_course(\%sqlOptions, \%optionsOps) ); 
    print $cgi->br;
    print $cgi->br;
    print $cgi->br;
    print $cgi->end_div();
    print $cgi->end_center();

    ######################
    ## Footer and stuff ##
    $lchc->footer;
}

print $cgi->end_html;
exit(0);

sub courses( $ ) {
    my( $query ) = @_;

    ## Get the results and print the courses
    my @res = $db->complex_results($query);
    foreach my $row (@res) {

        my $text = "$row->{program} $row->{number} - $row->{name} [$row->{quarter} $row->{year}]";
	my $uri  = "$lchc->{uri_course}?course=$row->{id}";
        my $link = $cgi->a({-href=>"$uri"}, $text);

	print $cgi->div({ -style => ('font-size: 14px; font-family: Georgia, Time New Roman, sans-serif;    '  .
				     'font-weight: bold; background: #eeeeee; color: #445566; width: 425px; '  .
				     'margin-left:  0px; border: 2px solid #AABBAA; cursor: pointer;        '  .
				     'margin-bottom: 12px; margin-top: 5px; padding: 5px; text-align: center;'),
				     -onclick => "window.location = '$uri';" },
			$cgi->span({ -style => 'color: #black; font-weight: bold; font-family: Georgia' }, $text ));
				     print $cgi->p;
    }

}
