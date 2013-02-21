#!/usr/bin/perl -w

####
## Fieldnotes Database
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: functional/login.pl
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
my $user = $cgi->param('user');
my $pass = $cgi->param('pass');

## Check parameter values
$user = -1 if ! defined $user;
$pass = '' if ! defined $pass;

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

# No access control

## Main
my $cookie;

#####################################
## First are they allowd to login? ##
my @currents = ();
my $query    = $db->sql_person_course({ current => 1 }, { order => 't_person.last', sort => 'asc' });
my @results  = $db->complex_results($query);
foreach my $current (@results) {
    push( @currents, $current->{person} );
}

my %sqlOptions = ( admin => 1 );
$query   = $db->sql_person( \%sqlOptions, {} );
@results = $db->complex_results( $query );
foreach my $admin (@results) {
    push( @currents, $admin->{id} );
}

########################################
## Try logging in the user only if    ##
##  the proposed user is in the list. ##
if( $lchc->in( $user, @currents )) {
    $user = $lchc->login( $user, $pass );
} else {
    $user = -1;
}

if( $user >= 1 ) {

    $cookie = $cgi->cookie(-name    => $lchc->{cookieName},
			   -value   => $user,
			   -expires => '+1y',
			   -path    => '/',
			   -domain  => '.fieldnotes.ucsd.edu',
			   -secure  => 0);

    ######################
    ## Log the activity ##
    $lchc->log_user_activity( $user, { url    => 'functional/login.pl',
				       action => 'login' });

} else {
    $cookie = '';
}

print $cgi->redirect({-location=>$lchc->{uri_index}, -cookie=>$cookie});

exit(0);
