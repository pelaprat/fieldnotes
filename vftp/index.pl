#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: index.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/Users/web/perl'; }

use strict;
use CGI;
use LCHC::Vftp;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi  = new CGI;
my $vftp = new LCHC::Vftp;
my $db   = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user = $cgi->cookie($vftp->{cookieName});

## Check parameter values
$user = -1 if ! defined $user;

## Set some variables
$vftp->set_cgi($cgi);
$vftp->set_db($db);
$vftp->set_user($user);
$db->set_pn($vftp);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'vftp/index.pl',
				   action => 'view' });

## Access control, we are the index
$vftp->control_access((index=>1, admin=>0, header=>1));



####
## Now onto main part of the page
print $cgi->start_html({-title=>'Virtual FTP!', -style=>{-src=>$vftp->{uri_css}}});

if($user <= 0) {
    my %sqlOptions = (order => 'last', sort => 'asc', pass => "''");
    my %optionsOps = (pass => '!=');

    ## Not logged, suggest they log in
    print $cgi->start_form({-method=>'get', -action=>$vftp->{uri_login}});
    print $cgi->start_div({-class=>'box', -style=>'width: 300px'});
    print $cgi->start_div({-class=>'login'});
    print $cgi->div({-class=>'box-title'}, 'Vftp Login!');
    print $vftp->person_menu('user', {}, \%sqlOptions, \%optionsOps);
    print $cgi->br;
    print $cgi->password_field({-name=>'pass', -size=>'25'});
    print $cgi->br;
    print $cgi->submit({-name=>'submit', -value=>'login'});
    print $cgi->end_div;
    print $cgi->end_div;
    print $cgi->end_form;

} else {
    ## Toolbar
    $vftp->toolbar();

    ## Get some of the spaces
    my %sqlOptions = (parent => -1);
    my $sql = $db->sql_space(\%sqlOptions, {});
    my @res = $db->complex_results($sql);

    foreach my $row (@res) {
	print $cgi->a({-href=>"$vftp->{uri_browse}?space=$row->{id}"},
		      $row->{name});
	print $cgi->br;
    }

    ####
    ## Footer and stuff
    $vftp->footer;
}

print $cgi->end_html;
exit(0);
