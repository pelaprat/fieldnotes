#!/usr/bin/perl -w

####
## Vftp
##  Etienne Pelaprat
##  epelapra@dss.ucsd.edu
##
## file: browse.pl
##

## Make sure we point correctly
BEGIN { push @INC, '/Users/web/perl'; }

use warnings;
use diagnostics;
use strict;
use CGI;
use LCHC::Vftp;
use LCHC::Notes;
use LCHC::SQL::Vftp;

## Build the basic objects
my $cgi       = new CGI;
my $lchc      = new LCHC::Vftp;
my $fieldnote = new LCHC::Notes;
my $db        = new LCHC::SQL::Vftp;

## Restore parameters
$cgi->restore_parameters();

## Retrieve parameter values
my $user  = $cgi->cookie($lchc->{cookieName});
my $space = $cgi->param('space');
my $path  = $cgi->param('path');
my $order = $cgi->param('order');
my $sort  = $cgi->param('sort');

#my $hist  = $cgi->param('hist');

## Check parameter values
$user  = -1 if ! defined $user;
$space = -1 if ! defined $space;
$path  = '' if ! defined $path;
$order = 'name' if ! defined $order;
$sort  = 'asc'  if ! defined $sort;

#$hist  = 'off'       if ! defined $hist;

## Toggle values
my %toggle = (sort=>'asc', hist=>'off');
$toggle{sort} = 'desc'  if $sort eq 'asc';
#$toggle{hist} = 'on'   if $hist eq 'off';

## Set some variables
$lchc->set_cgi($cgi);
$lchc->set_db($db);
$lchc->set_user($user);
$db->set_pn($lchc);

######################
## Log the activity ##
$lchc->log_user_activity( $user, { url    => 'vftp/browse.pl',
				   action => 'browse',
			           target => $space });

## Access control, we are the index
$lchc->control_access((index=>0, admin=>0, header=>1));



## Redirect out of here if the necessary params
##  are not supplied.
if($space <= 0) {
    print $cgi->redirect({-location=>$lchc->{uri_index}});
}

## Some variables for sql functions
my %sqlOptions = (id => $space);
my %optionsOps = ();

## Get the data for the space
my $spaceData = $db->get_space(\%sqlOptions, \%optionsOps);

## Get the proper data structure
##  given the type of space.
my @order = ();
my %data  = ();
if($spaceData->{server} == 1 && $spaceData->{path} ne '') {
    ## Are we in a sub directory
    ##  of the space?
    my($optr, $dptr);
    if($path ne '') {
	# Remove all the dot-dots
	$path =~ s/\/\.\.//g;
	($optr, $dptr) = &directory("$spaceData->{path}/$path");
    } else {
	($optr, $dptr) = &directory($spaceData->{path});
    }
    @order = @$optr;
    %data  = %$dptr;
} else {
    my($optr, $dptr) = &virtual($spaceData->{id});
    @order = @$optr;
    %data  = %$dptr;
}

####################################
## Now onto main part of the page ##
print $cgi->start_html({-title=>"$spaceData->{name} -- VirtualFTP",
			-style=>{-src=>$lchc->{uri_css}}});

## Toolbar
$lchc->toolbar();

## Start the main structure table
print $cgi->start_table({-style=>'width: 100%'});
print $cgi->start_Tr();
print $cgi->start_td({-style=>'width: 180px'});

#####################
## Left-hand boxes ##
print $cgi->start_div({-class=>'box', style=>'width: 180px'});
print $cgi->div({-class=>'box-title'}, 'Add file:');
print $cgi->start_multipart_form({-name=>'upload', -method=>'post',
				  -action=>$lchc->{uri_upload},
				  -style=>'margin-bottom:0;'});
print $cgi->hidden({-name=>'space', -value=>$space});
print $cgi->hidden({-name=>'path',  -value=>$path});
print $cgi->filefield(-style=>'font-size: 9px;',
		      -name=>'file',
		      -default=>'',
		      -size=>9,
		      -maxlength=>80);
print $cgi->submit({-name=>'submit', -value=>'upload', -style=>'font-size: 9px;'});
print $cgi->br;
#print $cgi->textarea({-name=>'comment', -cols=>20, -rows=>10});
print $cgi->end_form;
print $cgi->end_div();
print $cgi->br;
print $cgi->start_div({-class=>'box', -style=>'width: 180px'});
print $cgi->div({-class=>'box-title'}, 'Tools:');
print $cgi->start_form({-method=>'post', action=>$lchc->{uri_create}});
print $cgi->hidden({-name=>'what',  -value=>'directory'});
print $cgi->hidden({-name=>'space', -value=>$space});
print $cgi->hidden({-name=>'path',  -value=>$path});
print $cgi->div({-style=>'height: 16px; vertical-align: top;'},
		$cgi->img({-src=>"$lchc->{uri_images}/directory.gif", -border=>0,
			   -style=>'vertical-align: bottom;'}),
		$cgi->textfield({-name=>'name', -style=>'font-size: 9px;', -size=>17}),
		$cgi->submit({-name=>'submit',  -style=>'font-size: 9px', -value=>'create'}));
print $cgi->end_form();
print $cgi->br;
#print $cgi->a({-href=>$lchc->{uri_index}},
#	       $cgi->img({-src=>"$lchc->{uri_images}/trash.gif", -border=>0,
#			  -style=>'vertical-align: bottom'}), 'delete selected');
print $cgi->end_form;

## Any courses attached to this space?
print $cgi->div({-class=>'box-title'}, 'Courses:');
%sqlOptions = (space => $space);
my $sql = $db->sql_course_space(\%sqlOptions, {});
my @res = $db->complex_results($sql);
foreach my $row (@res) {
    print $cgi->img({-src=>"$fieldnote->{uri_images}/database.gif", -border=>0,
		     -style=>'vertical-align: bottom; width: 16px; height: 16px'});
    print ' ';
    print $cgi->a({-href=>"$fieldnote->{uri_course}?course=$row->{course}"},
		  "$row->{program} $row->{number} - $row->{course_name}");
    print $cgi->br;
}
print $cgi->end_div();

## Structuring table...
print $cgi->end_td();
print $cgi->start_td({-style=>'padding-left: 9px;'});

####################
## The data table ##
print $cgi->start_table({-class=>'space'});

## Print the name of the space
print $cgi->Tr($cgi->td({-colspan=>3}, $cgi->span({-style=>'font-weight: bold'}, $spaceData->{name})),
	       $cgi->td({-colspan=>2, -style=>'text-align: right'}));

## Navigation Row
print $cgi->start_Tr();
print $cgi->start_td({-colspan=>3, -style=>'vertical-align: top;'});
if($spaceData->{server} == 1) {
    ## Home link
    print $cgi->a({-href=>&link((path => '/'))},
		  $cgi->img({-src=>"$lchc->{uri_images}/home.gif", -border=>0}));

    ## Each subdirectory
    my $p = '';
    my @d = split('/', $path);
    foreach my $d (@d) {
	if($d ne '') {
	    my $l = &link((path => "$p/$d"));
	    my $q = $cgi->a({-href=>$l}, $d);
	    print " / $q ";
	    $p .= "/$d";
	}
    }
} else {
    ## Parent space link
    if($spaceData->{parent} > 0) {
	print $cgi->a({-href=>&link((space => $spaceData->{parent}))},
		      $cgi->img({-src=>"$lchc->{uri_images}/home.gif", -border=>0}), 'parent');
    }
}
print $cgi->end_td();
print $cgi->td({-colspan=>2, -style=>'text-align: right; padding-right: 0px'}, &jump());

print $cgi->end_Tr();

####################
## Column Headers ##
my($alink, $flink, $hlink, $plink, $slink, $tlink) =
    (&link((order=>'person',    sort=>$toggle{sort})),
     &link((order=>'name',      sort=>$toggle{sort})),
     &link((hist=>$toggle{hist})),
     &link((space=>$spaceData->{parent})),
     &link((order=>'bytes',     sort=>$toggle{sort})),
     &link((order=>'timestamp', sort=>$toggle{sort})));

$flink = &link((order=>'name',      sort=>$toggle{sort})) if $order eq 'name';
$alink = &link((order=>'person',    sort=>$toggle{sort})) if $order eq 'person';
$slink = &link((order=>'bytes',     sort=>$toggle{sort})) if $order eq 'bytes';
$tlink = &link((order=>'timestamp', sort=>$toggle{sort})) if $order eq 'timestamp';

$plink = ($cgi->a({-href=>$plink}, 'parent') . ' | ');
$plink = '' if $spaceData->{parent} <= 0;
$hlink = $cgi->a({-href=>$hlink}, "History: $toggle{hist}");

print $cgi->Tr($cgi->th({-style=>'width: 16px; padding-right: 0px'}),
	       $cgi->th($cgi->a({-href=>$flink}, 'Filename')),
	       $cgi->th($cgi->a({-href=>$alink}, 'Author')),
	       $cgi->th($cgi->a({-href=>$tlink}, 'When')),
	       $cgi->th($cgi->a({-href=>$slink}, 'Size')));

#############################
## Print filess one-by-one ##
foreach my $name (@order) {
    my $ptr  = $data{$name};
    my %file = %$ptr;

    ## Prepare some values
    my $icon = $cgi->img({-src=>$file{icon}});
    my $link = &click($ptr);

    print $cgi->start_Tr({-class=>'file'});
    print $cgi->td({-style=>'padding-right: 0px;'}, $icon);
    print $cgi->td($link);
    print $cgi->td($file{person});
    print $cgi->td($file{timestamp});
    print $cgi->td($file{size});
    print $cgi->end_Tr();
}

################
## Bottom Row ##
my $ptr   = $data{'..stats'};
my %stats = %$ptr;
print $cgi->Tr($cgi->td({-colspan=>5, -style=>'border-top: 1px solid #000000'}));
print $cgi->Tr($cgi->td(), $cgi->td("$stats{files} files / $stats{dirs} directories"),
	       $cgi->td(), $cgi->td(), $cgi->td($lchc->size($stats{bytes})));

## End structure table
print $cgi->end_table();

## Footer and stuff
print $cgi->end_td();
print $cgi->end_Tr();
print $cgi->end_table();

$lchc->footer;

## End the form and
##  and the HTML
print $cgi->end_html;

exit(0);

#####################
## ---FUNCTIONS--- ##
sub click($) {
    my($ptr) = @_;
    my %file = %$ptr;
    my $click;

    if($file{type} eq 'directory' || $file{ext} eq 'directory') {
	if($spaceData->{server} == 1) {
	    $click = $cgi->a({-href=>&link((path => "$path/$file{name}"))}, $file{name});
	} else {
	    $click = $cgi->a({-href=>&link((path=>'', space=>$file{id}))}, $file{name});
	}
    } elsif($spaceData->{server} == 1) {
	$click = $cgi->a({-href=>"$lchc->{uri_download}?space=$space&path=$path&name=$file{name}"}, $file{name});
    } else {
	$click = $cgi->a({-href=>"$lchc->{uri_download}?id=$file{id}"}, $file{name});
    }

    return $click;
}

sub link(%) {
    my(%values) = @_;
    my($ls, $lp, $lo, $lr) = ($space, $path, $order, $sort);

    $ls = $values{space} if defined $values{space} && $values{space} > 0;
    $lp = $values{path}  if defined $values{path}  && $values{path} ne '';

    $lo = $values{order} if defined $values{order} && $values{order} ne '';
    $lr = $values{sort}  if defined $values{sort}  && $values{sort}  ne '';
#    $lh = $values{hist}  if defined $values{hist}  && $values{hist}  ne '';

    return "$lchc->{uri_browse}?space=$ls&path=$lp&order=$lo&sort=$lr";
}

####################################
## We have the right params,      ##
##  retrieve and prepare the data ##
sub directory($) {
    my($path) = @_;
    my %stats = (dirs => 0, files => 0, bytes => 0);

    ## Get the order and sorting for the command right
    my($x, $y);
    if($order eq 'bytes') {
	$x = 'S';
    } elsif($order eq 'timestamp') {
	$x = 't';
    } else {
	$x = '';
    }

    if($sort eq 'desc') {
	$y = 'r';
    } else {
	$y = '';
    }

    my $command   = "ls -lQ${x}${y} $path";
    my $results   = `$command`;
    my %structure = ();
    my @order = ();

    ## Get the result of command
    foreach my $line (split('\n', $results)) {
	if($line =~ m|^([drwx\-]+)\s+\d+\s(\w+)\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+:\d+)\s+"(.+)"$|) {
	    my $name = $8;

	    ## Build the data
	    my %data = (perms => $1,
			owner => $2,
			group => $3,
			bytes => $4,
			month => $5,
			day   => $6,
			time  => $7,
			name  => $8);

	    ## Get a formatted timestamp
	    $data{timestamp} = `date --date='$data{month} $data{day} $data{time}' '+\%b \%e, %Y @ $data{time}'`;
	    chomp($data{timestamp});

	    ## Get a little extra data
	    $data{ext} = '';
	    if($name =~ m|([^\.]+)$|) {
		$data{ext} = $1;
	    }

	    $data{size}   = $lchc->size($data{bytes});
	    $data{person} = "$data{owner} (server)";

	    ## Get the right icon
	    if(-f "$path/$name") {
		$data{icon} = $lchc->icon($data{ext});
		$data{type} = $data{ext};
		$stats{files}++;
	    } elsif(-d "$path/$name") {
		$data{icon} = $lchc->icon('directory');
		$data{type} = 'directory';
		$stats{dirs}++;
	    }

	    ## Build the stats
	    $stats{bytes} += $data{bytes};

	    ## Add to the structure
	    $structure{$name} = \%data;

	    ## Keep the order
	    push(@order, $name);
	}
    }

    ## Add the stats to the structure
    $structure{'..stats'} = \%stats;

    return (\@order, \%structure);
}

sub virtual($) {
    my($space)     = @_;
    my %stats      = (dirs => 0, files => 0, bytes => 0);
    my %sqlOptions = ();

    my %current   = ();
    my @order     = ();
    my @subspaces = ();

    ## Get all the current files
    %sqlOptions = (order => 'name', sort => 'asc', space => $space, historical => 0);
    my $sql = $db->sql_file(\%sqlOptions, {});
    my @res = $db->complex_results($sql);
    foreach my $row (@res) {
	my %data = (id        => $row->{id},
		    name      => $row->{name},
		    bytes     => $row->{bytes},
		    timestamp => $row->{timestamp},
		    person    => "$row->{first} $row->{middle} $row->{last}",
		    type      => $row->{type});

	$data{size} = $lchc->size($data{bytes});
	$data{icon} = $lchc->icon($row->{type});

	## Build the stats
	$stats{bytes} += $data{bytes};
	$stats{files}++;

	$current{$row->{name}} = \%data;
	push(@order, $row->{name});
    }

    ## Get all the sub-spaces
    %sqlOptions = (parent => $space, order => 'name', sort => 'asc');
    $sql = $db->sql_space(\%sqlOptions, {});
    @res = $db->complex_results($sql);
    foreach my $row (@res) {
	my %data = (id        => $row->{id},
		    name      => $row->{name},
		    size      => '-',
		    person    => '-',
		    timestamp => '-',
		    type      => 'directory');

	$data{icon} = $lchc->icon('directory');

	## Build the stats
	$stats{dirs}++;

	$current{$row->{name}} = \%data;
	push(@order, $row->{name});

	push(@subspaces, \%data);
    }

    ## Do name sorting
    if($order eq 'name') {
	if($sort eq 'asc') {
	    @order = sort {lc $a cmp lc $b} @order;
	} else {
	    @order = reverse sort {lc $a cmp lc $b} @order;
	}
    }

    ## Add the stats to the structure
    $current{'..stats'} = \%stats;

    ## Return the order, listing
    return (\@order, \%current);

#    ## Now the historical files, if needed
#    %sqlOptions = (space=>$space, historical=>1, order=>$order, sort=>$sort)
#    $sql = $db->sql_file(\%sqlOptions, {});
#    @res = $db->complex_results($sql);
#    my %history = ();
#    if($hist eq 'on') {
#	foreach my $row (@res) {
#	    my %data = &local_data($row);
#	    my @values = ();
#	    if(defined $history{$row->{name}}) {
#		my $ref = $history{$row->{name}};
#		@values = @$ref;
#	    }
#	    push(@values, \%data);
#	    $history{$row->{name}} = \@values;
#	}
#    }

}

sub jump() {
    my $return = '';

#    $return .= $cgi->start_form({-style=>'margin-bottom: 0;', -method=>'post', -action=>$lchc->{uri_jump}});
#    $return .= $lchc->spaces_menu((parent => -1, style=>'font-size: 9px'));
#    $return .= $cgi->submit(-style=>'font-size: 9px;', -name=>'submit', -value=>'go');
#    $return .= $cgi->end_form;

    return $return;
}
