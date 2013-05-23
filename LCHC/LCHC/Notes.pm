package LCHC::Notes;

use strict;
use diagnostics;
use LCHC;
use DBI;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use vars qw($VERSION @ISA);
use Date::Calc qw(Today Delta_YMD Add_Delta_YM Delta_Days Date_to_Text);

require Exporter;
require AutoLoader;

$VERSION = '0.93';
@ISA     = qw(LCHC Exporter AutoLoader);

####
## Constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $root  = shift;
    my $self  = LCHC->new( $root );

    $self->{uri_css}           = $self->{uri_root} .         '/display/lchc.css';

    ## Normal pages
    $self->{uri_add}           = $self->{working_uri_root} . "/browse/add.pl";
    $self->{uri_backup}        = $self->{working_uri_root} . "/admin/backup.pl";
    $self->{uri_course}        = $self->{working_uri_root} . "/browse/course.pl";
    $self->{uri_delete}        = $self->{working_uri_root} . "/functional/delete.pl";
    $self->{uri_edit}          = $self->{working_uri_root} . "/browse/edit.pl";
    $self->{uri_email}         = $self->{working_uri_root} . "/browse/email.pl";
    $self->{uri_files}         = '/fieldnote_vftp/files/';
    $self->{uri_index}         = $self->{working_uri_root} . "/index.pl";
    $self->{uri_images}        = $self->{working_uri_root} . "/images";
    $self->{uri_insert}        = $self->{working_uri_root} . "/functional/insert.pl";
    $self->{uri_javascript}    = $self->{working_uri_root} . '/display/lchc.js';
    $self->{uri_login}         = $self->{working_uri_root} . "/functional/login.pl";
    $self->{uri_logout}        = $self->{working_uri_root} . "/functional/logout.pl";
    $self->{uri_modify}        = $self->{working_uri_root} . "/browse/modify.pl";
    $self->{uri_person}        = $self->{working_uri_root} . "/browse/person.pl";
    $self->{uri_print}         = $self->{working_uri_root} . "/browse/print.pl";
    $self->{uri_results}       = $self->{working_uri_root} . "/search/results.pl";
    $self->{uri_search}        = $self->{working_uri_root} . "/search/search.pl";
    $self->{uri_update}        = $self->{working_uri_root} . "/functional/update.pl";

    ## Admin pages
    $self->{admin_root}                   = $self->{working_uri_root}   . '/admin';
    $self->{admin_add}                    = $self->{admin_root} . "/add.pl";
    $self->{admin_item_count}             = $self->{admin_root} . "/synchronize/conference_item_count.pl";
    $self->{admin_backup}                 = $self->{admin_root} . "/backup.pl";
    $self->{admin_course}                 = $self->{admin_root} . "/course.pl";
    $self->{admin_course_kids_activities} = $self->{admin_root} . "/course_kids_activities.pl";
    $self->{admin_edit}                   = $self->{admin_root} . "/edit.pl";
    $self->{admin_index}                  = $self->{admin_root} . "/index.pl";
    $self->{admin_insert}                 = $self->{admin_root} . "/insert.pl";
    $self->{admin_password}               = $self->{admin_root} . "/password.pl";
    $self->{admin_stats}                  = $self->{admin_root} . "/statistics.pl";
    $self->{admin_update}                 = $self->{admin_root} . "/update.pl";

    ## Arhives pages
    $self->{archives_index}               = $self->{working_uri_root} . '/archives/index.pl';

    bless($self, $class);
    return $self;
}

####
## Access Control & Header
##
sub control_access($%) {
    my($self, %options) = @_;
    my $cgi = $self->{var_cgi};
    my $db  = $self->{var_db};

    ## Redirect if no user, or if they are not
    ##  an admin trying to view an admin page
    if((defined $options{index} && $options{index} == 0 && $self->{var_user}   <= 0) ||
       (defined $options{admin} && $options{admin} == 1 && $self->{user_admin} == 0)) {
        print $cgi->redirect({-location=>$self->{uri_index}});
        exit(0);
    }

    ## Keep track of time
    $self->{starttime} = [gettimeofday()];

    ## Print the header if requested
    $self->http_header() if (defined $options{header} && $options{header} == 1);

    return 1;
}

####
## Toolbars
sub toolbar($) {
    my($self) = @_;
    my $cgi   = $self->{var_cgi};

    my $admin = '';
    $admin = ($cgi->a({-href=>$self->{admin_index}}, 'Administration') . ' | ')
	if $self->{user_admin} == 1;

    my $archives = '';
    $archives = ($cgi->a({-href=>$self->{archives_index}}, 'Archives') . ' | ')
	if $self->{user_admin} == 1;

    print $cgi->start_div({-class=>'toolbar'});
    print $cgi->a({-href=>$self->{uri_index}},  'Home'), ' | ';
    print $cgi->a({-href=>$self->{uri_search}}, 'Search'), ' | ';
    print $admin;
    print $archives;
    print "Logged in as: ";
    print $cgi->a({-href=>"$self->{uri_person}?id=$self->{var_user}"}, $self->{user_name});
    print ' (', $cgi->a({-href=>$self->{uri_logout}}, 'LOGOUT'), ')';
    print $cgi->end_div();
    print $cgi->br;

    return 1;
}

####
## Footer
sub footer($) {
    my($self)   = @_;
    my $cgi     = $self->{var_cgi};
    my $elapsed = tv_interval($self->{starttime}, [gettimeofday()]);

    print $cgi->p;
    print $cgi->div({-class=>'footer'},
		    "&copy; 1989-2009 LCHC | $elapsed seconds");

    return 1;
}

####
## Various HTML items
sub course_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the course menu
    my $sql = $db->sql_course($sqlOptions, $sqlOptionsOps);
    my @res = $db->complex_results($sql);
    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = "[$row->{program} $row->{number}] $row->{name} ($row->{quarter} $row->{year})";
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub activity_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the activity menu
    my $query = $db->sql_activity($sqlOptions, $sqlOptionsOps);
    my @res   = $db->complex_results($query);
    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = $row->{name};
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub kid_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the kid menu
    my $query = $db->sql_kid($sqlOptions, $sqlOptionsOps);
    my @res   = $db->complex_results($query);

    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = "$row->{fullname}";
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub recent_kid_menu($$$$$$) {
    my($self, $name, $year, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the kid menu
    my $query = $db->sql_recent_kid( $year, $sqlOptions, $sqlOptionsOps);
    my @res   = $db->complex_results($query);

    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = "$row->{fullname}";
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub site_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the site menu
    my $query = $db->sql_site($sqlOptions, $sqlOptionsOps);
    my @res   = $db->complex_results($query);
    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = $row->{name};
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub site_activity_menu($$$$) {
    my( $self, $name, $menuOptions, $site ) = @_;
    my $db = $self->{var_db};
    my $tnSiteActivity = $db->{tnSiteActivity};

    my @list    = ();
    my $query   = $db->sql_site_activity( { "$tnSiteActivity.site" => $site }, {} );
    my @results = $db->complex_results( $query );
    foreach my $row ( @results ) {
        push( @list, $row->{activity} );
    }
    my $list = join(',', @list);
    return $self->activity_menu( $name, $menuOptions, { id => "($list)", order => 'name', sort => 'asc' }, { id => 'in' } );
}

sub site_kid_menu($$$$) {
    my( $self, $name, $menuOptions, $site ) = @_;
    my $db = $self->{var_db};
    my $tnSiteKid = $db->{tnSiteKid};

    my @list    = ();
    my $query   = $db->sql_site_kid( { "$tnSiteKid.site" => $site }, {} );
    my @results = $db->complex_results( $query );
    foreach my $row ( @results ) {
	push( @list, $row->{kid} );
    }
    my $list = join(',', @list);
    return $self->kid_menu( $name, $menuOptions, { id => "($list)", order => 'first', sort =>'asc' }, { id => 'in' } );
}

####
## Display a Database Fieldnote
##
sub fieldnote_display($$$$$) {
    my($self, $fieldnote, $attachments, $activities, $kids, $options) = @_;
    my $cgi = $self->{var_cgi};
    my $db  = $self->{var_db};

    ## Prepare some data and links
    my $general    =  $fieldnote->{general};
       $general    =~ s/\n/<br>/g;
    my $narrative  =  $fieldnote->{narrative};
       $narrative  =~ s/\n/<br>/g;
    my $gametask   =  $fieldnote->{gametask};
       $gametask   =~ s/\n/<br>/g;
    my $reflection =  $fieldnote->{reflection};
       $reflection =~ s/\n/<br>/g;

    # Keywords
    if(defined $options->{keywords}) {
	$options->{keywords} =~ s/\sand\s//g;
	$options->{keywords} =~ s/\sor\s//g;
	$options->{keywords} =~ s/\*//g;

	foreach my $word (split(' ', $options->{keywords})) {
	    $general    =~ s/([^\w]+)($word)([^\w]+)/$1<span class=keyword>$2<\/span>$3/ig;
	    $narrative  =~ s/([^\w]+)($word)([^\w]+)/$1<span class=keyword>$2<\/span>$3/ig;
	    $gametask   =~ s/([^\w]+)($word)([^\w]+)/$1<span class=keyword>$2<\/span>$3/ig;
	    $reflection =~ s/([^\w]+)($word)([^\w]+)/$1<span class=keyword>$2<\/span>$3/ig;
	}
    }

    # Various links
    my $course_link     = ("$self->{uri_course}?course=$fieldnote->{course_id}");
    my $conference_link = ("$self->{uri_course}?course=$fieldnote->{course_id}" .
			   "&conference=$fieldnote->{conference_id}");

    ## Now print the fieldnote
    print $cgi->a({-name=>"$fieldnote->{id}"});
    print $cgi->start_div({-style => ("padding: 5px; background: #E5EFFF; " .
				      "border: 1px solid #AAAAAA; margin-bottom: 5px;")});

    ## Course
    print $cgi->span({-style=>'font-weight: bold'}, "Course: ");
    print $cgi->a({-href=>$course_link}, $fieldnote->{course_name});
    print $cgi->br;

    ## Conference
    print $cgi->span({-style=>'font-weight: bold'}, 'Conference:');
    print $cgi->a({-href=>$conference_link}, $fieldnote->{conference_name});
    print $cgi->br;

    ## Fieldnote
    print $cgi->span({-style=>'font-weight: bold'}, 'Name: ');
    print $cgi->a({-href=>"$self->{uri_person}?id=$fieldnote->{person_id}"}, $fieldnote->{person_name});
    print " &lt;$fieldnote->{person_email}&gt;";
    print $cgi->br;

    print $cgi->span({-style=>'font-weight: bold;'}, 'Date of Visit: ');
    print $cgi->span({-class=>'date'}, $fieldnote->{dateofvisit});
    print $cgi->br;

    print $cgi->span({-style=>'font-weight: bold'}, 'Date Filed: ');
    print $cgi->span({-class=>'date'}, $fieldnote->{timestamp});
    print $cgi->br;

    ## Tools
    my $edit_link   = '';
    my $delete_link = '';
    if($self->{user_admin} == 1) {
	my $return_href = "$self->{uri_course}?course=$fieldnote->{course_id}&conference=$fieldnote->{conference_id}";
	$return_href =~ s/&/\*/g;
	my $delete_href = "$self->{uri_delete}?id=$fieldnote->{id}&return=$return_href";
	$delete_link    =  $cgi->a({-href=>$delete_href}, 'Delete Fieldnote (<b color=red>this is irreversible!!</b>)');

    }

    # Print Tools
    my $reply_link = ("$self->{uri_add}?type=comment&fieldnote=$fieldnote->{id}&" .
		      "conference=$fieldnote->{conference_id}");
    my $cs_link    = ("$self->{uri_add}?type=commentsite&fieldnote=$fieldnote->{id}&" .
		      "conference=$fieldnote->{conference_id}");
    my $print_link = ("$self->{uri_print}?id=fieldnote.$fieldnote->{id}&keywords=$options->{keywords}");

    print $cgi->span({-style=>'font-weight: bold'}, 'Tools: ');


    print $cgi->a({-href=>$reply_link}, 'Post a Comment');
    print ' | ';
    if($self->{user_instr} == 1) {
	print $cgi->a({-href=>$cs_link}, 'Post an Administrator-Only Comment');
	print ' | ';
    }

    print $cgi->a({-href=>$print_link, -target=>'_new'}, 'Print Version');

    print $edit_link;
#    print $cgi->div({-style=>'float: right; clear: both'},
#		    $cgi->a({ -href => "/fieldnote/browse/modify.pl?id=$fieldnote->{id}"},
#			    'Modify Fieldnote')); ## Delete link used to go there
    print $cgi->br({-style=>'clear: both'});
    print $cgi->hr({-size=>1});

    ## Print the Kids
    if(defined $kids && $fieldnote->{course_program} ne 'PSM' ) {
	print $cgi->br;
	print $cgi->span({-style=>'font-weight: bold'}, 'Kids: ');

	my @kids = @$kids;
	foreach my $kid (@kids) {
	    if($kid->{fieldnote} == $fieldnote->{id}) {

		my( $by, $bm, $bd ) = ( 00, 00, 00 );
		if( defined $kid->{birthdate} && $kid->{birthdate} =~ m|^(\d+)-(\d+)-(\d+)$| ) {
		    ( $by, $bm, $bd ) = ( $1, $2, $3 );
		}

		my( $fy, $fm, $fd ) = ( 00, 00, 00 );
		if( defined $fieldnote->{date_dateofvisit} && $fieldnote->{date_dateofvisit} =~ m|^(\d+)-(\d+)-(\d+)$| ) {
		    ( $fy, $fm, $fd ) = ( $1, $2, $3 );
		}

		if( $by > 0 && $bm > 0 && $bd > 0 && $fy > 0 && $fm > 0 && $fd > 0 ) {

		    my $date_of_visit = [ $fy, $fm, $fd ];
		    my $birthdate_kid = [ $by, $bm, $bd ];

		    my $delta = Normalize_Delta_YMD( $birthdate_kid, $date_of_visit );

		    print $cgi->br;
		    print "$kid->{first} $kid->{last} ";

		    printf (" (%dy, %dm, %dd)", $delta->[0], $delta->[1], $delta->[2] );

		} else {
		    print $cgi->br;
		    print "$kid->{first} $kid->{last}";
		}

	    }
	}
    }
    print $cgi->p;

    ## Print the Activities
    if(defined $activities && $fieldnote->{course_program} ne 'PSM' ) {
	print $cgi->br;
	print $cgi->span({-style=>'font-weight: bold'}, 'Activities: ');

	my @activities = @$activities;
	foreach my $activity (@activities) {
	    if($activity->{fieldnote} == $fieldnote->{id}) {
		print $cgi->br;
		print "$activity->{name} ($activity->{timeontask}m; ";
		if($activity->{taskcard} == 1) {
		    print ' with taskcard)';
		} else {
		    print ' no taskcard) ';
		}
	    }
	}
    }
    print $cgi->p;

    ## Body of the Fieldnote
    print $cgi->br;
    if( $fieldnote->{course_program} eq 'PSM' ) {
	print $cgi->span({-style=>'font-weight: bold'}, 'Initial Circumstances of Site Visit:');
    } else {
	print $cgi->span({-style=>'font-weight: bold'}, 'General:');
    }

    print $cgi->br, $general, $cgi->p, $cgi->br;

    if( $fieldnote->{course_program} eq 'PSM' ) {
	print $cgi->span({-style=>'font-weight: bold'}, 'Narrative of Site Activities:');
    } else {
	print $cgi->span({-style=>'font-weight: bold'}, 'Narrative:');
    }

    print $cgi->br, $narrative, $cgi->p, $cgi->br;

    if( $fieldnote->{course_program} eq 'PSM' ) {
	print $cgi->span({-style=>'font-weight: bold'}, 'Summary of Major Accomplishments and Challenges:');
    } else {
	print $cgi->span({-style=>'font-weight: bold'}, 'Game-task Level Summary:');
    }

    print $cgi->br, $gametask, $cgi->p, $cgi->br;

    if( $fieldnote->{course_program} eq 'PSM' ) {
	print $cgi->span({-style=>'font-weight: bold'}, 'Reflection:');
    } else {
	print $cgi->span({-style=>'font-weight: bold'}, 'Reflection:');
    }


    print $cgi->br, $reflection, $cgi->p;
    print $cgi->br;

    ############################
    ## Print the Attachments. ##
    if( defined $attachments ) {

	my @locals = ();

	########################################
	## Go through and get my attachments. ##
	my @attachments = @$attachments;
	foreach my $attachment ( @attachments ) {
	    if( $attachment->{fieldnote} == $fieldnote->{id} ) {
		push( @locals, $attachment );
	    }
	}

	#####################################
	## Now print only if we have some! ##
	if( scalar( @locals) > 0 ) {

	    print $cgi->hr();
	    print $cgi->b('Attached files:');
	    print $cgi->br;

	    foreach my $local ( @locals ) {
			print $cgi->img({ -src => "$self->{uri_images}/file.jpg", onClick => "listImagesInOverlay();" });

			##  -----START----- Modified 11/10/2008  by Ivan Rosero  ( irosero@ucsd.edu )

			if( $local->{name} =~ m/.(jpg|jpeg|gif|png)$/i ){
				## use Lightbox only for images
				print $cgi->a({ -href => $self->{working_uri_root} . "vftp/functional/download.pl?id=$local->{file}", -rel => "lightbox" }, 
                	          $local->{name} );
			}
			else{
				print $cgi->a({ -href => $self->{working_uri_root} . "vftp/functional/download.pl?id=$local->{file}"}, 
                 		      $local->{name} );
			}

#			print $cgi->img({ -src => "$self->{uri_files}/thumbs/$local->{file}" });
			##  -----END-----

			print $cgi->br;
	    }
	}
    }

    print $cgi->p;

    ## Comments for the fieldnote
#    if($options->{print_comments} == 1 && defined $comments) {
#	foreach my $comment (@comments) {
#	    $self->comment_display($comment, ());
#	    print $cgi->p;
#	}
#    }

    print $cgi->end_div();
    return 1;
}

sub comment_display($$$) {
    my($self, $comment, $attachments, $options) = @_;
    my $cgi    = $self->{var_cgi};
    my $db     = $self->{var_db};

    ## Prepare some data and links
    my $subject =  $comment->{subject};
    my $body    =  $comment->{body};
    $body       =~ s/\n/<br>/g;

    ## Change the color
    my $color = 'red';
    if(defined $options->{type} && $options->{type} eq 'comment') {
	$color = '#FFFFA9';
    } else {
	$color = '#FFA9A9';
    }

    # Various links
    my $course_link     = ("$self->{uri_course}?course=$comment->{course_id}");
    my $conference_link = ("$self->{uri_course}?course=$comment->{course_id}" .
                           "&conference=$comment->{conference_id}");

    my $style = "padding: 5px; background: $color;
	         border: 1px solid #AAAAAA; margin-bottom: 5px;";
    if(defined $options->{index} && $options->{indent} == 1) {
	$style .= 'margin-left: 50px;';
    }

    ## Now print the comment
    print $cgi->a({-name=>"$comment->{id}"});
    print $cgi->start_div({-style=>$style});

    #############
    ## Comment ##
    print $cgi->span({-style=>'font-weight: bold'}, 'Name: '),
          $cgi->a({-href=>"$self->{uri_person}?id=$comment->{person_id}"}, $comment->{person_name}),
          " &lt;$comment->{person_email}&gt;";
    print $cgi->br;
    print $cgi->span({-style=>'font-weight: bold'}, 'Date: '),
          $cgi->span({-class=>'date'}, $comment->{timestamp});
    print $cgi->br;
    print $cgi->span({-style=>'font-weight: bold'}, 'Subject: ');
    print $subject;
    if(defined $options->{type} && $options->{type} eq 'commentsite') {
	print $cgi->div({-style=>'float: right; clear: both'},
			$cgi->b('Site Comment')); ## Delete link used to go there
    }
    print $cgi->hr({-size=>1});
    print $body;

    ############################
    ## Print the Attachments. ##
    if( defined $attachments ) {

        my @locals = ();

	########################################
        ## Go through and get my attachments. ##
        my @attachments = @$attachments;
        foreach my $attachment ( @attachments ) {
            if( $attachment->{comment} == $comment->{id} ) {
                push( @locals, $attachment );
            }
        }

        #####################################
        ## Now print only if we have some! ##
        if( scalar( @locals) > 0 ) {

            print $cgi->hr();
            print $cgi->b('Attached files:');
            print $cgi->br;

            foreach my $local ( @locals ) {
		print $cgi->img({ -src => "$self->{uri_images}/file.jpg" });
		print $cgi->a({ -href => $self->{working_uri_root} . "vftp/functional/download.pl?id=$local->{file}" },
			      $local->{name} );
		print $cgi->br;
            }
        }
    }

    print $cgi->p;
    print $cgi->end_div();

    return 1;
}

sub js_activity_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $optionsOps) = @_;
    my $cgi = $self->{var_cgi};

    ## Set up some code and buttons
    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('activity', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_add, -name=>'addactivity', -value=>'add activity'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_del, -name=>'deleteactivity', -value=>'X'});

    ## Print the HTML
    print "<input type=hidden value=0 name='activity-counter' id='activity-counter'>";
    print $cgi->div({-class=>'box-title'}, 'Activities', $add_btn);

    print $cgi->start_div({-id=>'box-activity', -style=>'display: none;'});
    print $del_btn;
    print $self->activity_menu($name, $menuOptions, $sqlOptions, $optionsOps);

    if(! defined $menuOptions->{menuOnly} || $menuOptions->{menuOnly} != 1) {
	print ' for ';
	print "<input type='text' name='minutes' size=4 value=0 default=0>";

	print ' minutes ';
	print $cgi->checkbox({-name=>'taskcard', -value=>1, -checked=>0, -label=>'Task Card?'});
    }

    print $cgi->end_div();
    print $cgi->span({-id=>'activity-insert'});
    print $cgi->p;
}

sub js_kid_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $optionsOps) = @_;
    my $cgi = $self->{var_cgi};

    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('kid', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_add, -name=>'addkid', -value=>'add kid'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_del, -name=>'deletekid', -value=>'X'});

    print "<input type=hidden value=0 name='kid-counter' id='kid-counter'>";
    print $cgi->div({-class=>'box-title'}, 'Kids', $add_btn);

    print $cgi->start_div({-id=>'box-kid', -style=>'display: none;'});
    print($del_btn, $self->kid_menu($name, $menuOptions, $sqlOptions, $optionsOps));
    print $cgi->end_div();

    print $cgi->span({-id=>'kid-insert'});
    print $cgi->p;
}


sub js_recent_kid_menu($$$$$$) {
    my($self, $name, $year, $menuOptions, $sqlOptions, $optionsOps) = @_;
    my $cgi = $self->{var_cgi};

    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('kid', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_add, -name=>'addkid', -value=>'add kid'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_del, -name=>'deletekid', -value=>'X'});

    print "<input type=hidden value=0 name='kid-counter' id='kid-counter'>";
    print $cgi->div({-class=>'box-title'}, 'Kids', $add_btn);

    print $cgi->start_div({-id=>'box-kid', -style=>'display: none;'});
    print($del_btn, $self->recent_kid_menu($name, $year, $menuOptions, $sqlOptions, $optionsOps));
    print $cgi->end_div();

    print $cgi->span({-id=>'kid-insert'});
    print $cgi->p;
}



sub js_site_activity_menu($$$$) {
    my($self, $name, $menuOptions, $site) = @_;
    my $cgi = $self->{var_cgi};

    ## Set up some code and buttons
    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('activity', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
                                         'height: 20px; font-size: 14px; font-weight: bold'),
                                -onClick=>$js_add, -name=>'addactivity', -value=>'add activity'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
                                         'height: 20px; font-size: 14px; font-weight: bold'),
                                -onClick=>$js_del, -name=>'deleteactivity', -value=>'X'});

    ## Print the HTML
    print "<input type=hidden value=0 name='activity-counter' id='activity-counter'>";
    print $cgi->div({-class=>'box-title'}, 'Activities', $add_btn);

    print $cgi->start_div({-id=>'box-activity', -style=>'display: none;'});
    print $del_btn;
    print $self->site_activity_menu($name, $menuOptions, $site );

    if(! defined $menuOptions->{menuOnly} || $menuOptions->{menuOnly} != 1) {
        print ' for ';
	print $cgi->textfield({-name=>"minutes", -size=>2, -default=>''});
	print ' minutes ';
        print $cgi->checkbox({-name=>'taskcard', -value=>1, -checked=>0, -label=>'Task Card?'});
    }

    print $cgi->end_div();
    print $cgi->span({-id=>'activity-insert'});
    print $cgi->p;
}

sub Normalize_Delta_YMD
{
    my($date1,$date2) = @_;
    my(@delta);

    @delta = Delta_YMD(@$date1,@$date2);
    while ($delta[1] < 0 or $delta[2] < 0)
    {
	if ($delta[1] < 0) { $delta[0]--; $delta[1] += 12; }
	if ($delta[2] < 0)
	{
	    $delta[1]--;
	    $delta[2] = Delta_Days(Add_Delta_YM(@$date1,@delta[0,1]),@$date2);
	}
    }
    return \@delta;
}


sub js_site_kid_menu($$$$) {
    my($self, $name, $menuOptions, $site) = @_;
    my $cgi = $self->{var_cgi};

    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('kid', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
                                         'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_add, -name=>'addkid', -value=>'add kid'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
                                         'height: 20px; font-size: 14px; font-weight: bold'),
                                -onClick=>$js_del, -name=>'deletekid', -value=>'X'});

    print "<input type=hidden value=0 name='kid-counter' id='kid-counter'>";
    print $cgi->div({-class=>'box-title'}, 'Kids', $add_btn);

    print $cgi->start_div({-id=>'box-kid', -style=>'display: none;'});
    print($del_btn, $self->site_kid_menu($name, $menuOptions, $site));
    print $cgi->end_div();

    print $cgi->span({-id=>'kid-insert'});
    print $cgi->p;
}


sub js_file_upload( $$ ) {
    my( $self, $name, $space, $path ) = @_;
    my  $cgi                          = $self->{var_cgi};

    my $js_del = 'this.parentNode.parentNode.removeChild(this.parentNode)';
    my $js_add = "moreFields('file', 0, 0, 0)";
    my $add_btn = $cgi->button({-style=>('background: #E8E489;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_add, -name=>'addfile', -value=>'add file'});
    my $del_btn = $cgi->button({-style=>('background: #E49475;' .
					 'height: 20px; font-size: 14px; font-weight: bold'),
				-onClick=>$js_del, -name=>'deletefile', -value=>'X'});

#    print $cgi->start_multipart_form({ -name   => 'upload', -method=>'post',
#				       -action => $lchc->{uri_upload},
#				       -style  => 'margin-bottom:0;'     });

    print "<input type = hidden value = 0 name = 'file-counter' id = 'file-counter'>";
    print $cgi->hidden({ -name => 'space', -value => $space}   );
    print $cgi->hidden({ -name => 'path',  -value => '.'      });

    print $cgi->div({-class=>'box-title'}, 'Files:', $add_btn);

    print $cgi->start_div({ -id=>'box-file', -style=>'display: none;'});

    print $del_btn;
    print $cgi->filefield( -style     => 'font-size: 9px;',
			   -name      => 'file',
			   -default   => '',
			   -size      =>  9,
			   -maxlength =>  80 );


    print $cgi->end_div();

#    print $cgi->submit({ -name  => 'submit', 
#			 -value => 'upload',
#			 -style => 'font-size: 9px;' });

    print $cgi->span({ -id => 'file-insert' });
    print $cgi->p;
}

sub update_last_reference( $$$ ) {
    my( $self, $table, $id ) = @_;

    if( $id >= 0 ) {
	$self->{var_db}->do( "update $table set last_referenced = NOW() where id = $id" );
    }

}

return(1);
