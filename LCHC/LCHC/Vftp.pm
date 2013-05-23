package LCHC::Vftp;

use strict;
use LCHC;
use DBI;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use vars qw($VERSION @ISA);

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

    $self->{format_date}  = '\'%d %M %Y @ %l:%i %p\'';
    $self->{dir_files}    = '/Users/web/Sites/edu.ucsd.fieldnotes/vftp/files';

    $self->{admin_index}  = $self->{admin_root} . '/index.pl';

    $self->{uri_css}      = $self->{working_uri_root} . '/display/lchc.css';
    $self->{uri_index}    = $self->{working_uri_root} . '/index.pl';
    $self->{uri_login}    = $self->{working_uri_root} . 'functional/login.pl';
    $self->{uri_logout}   = $self->{working_uri_root} . '/functional/logout.pl';

    $self->{uri_browse}   = $self->{working_uri_root} . '/vftp/browse.pl';
    $self->{uri_create}   = $self->{working_uri_root} . '/vftp/functional/create.pl';
    $self->{uri_download} = $self->{working_uri_root} . '/vftp/functional/download.pl';
    $self->{uri_images}   = $self->{working_uri_root} . '/vftp/images';
    $self->{uri_jump}     = $self->{working_uri_root} . '/vftp/functional/jump.pl';
    $self->{uri_upload}   = $self->{working_uri_root} . '/vftp/functional/upload.pl';

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
    $admin = ($cgi->a({-href=>$self->{admin_index}}, 'Administration') . ' | ') if $self->{user_admin} == 1;

    print $cgi->start_div({-class=>'toolbar'});
    print $cgi->a({-href=>$self->{uri_index}},  'Home'), ' | ';
    print $admin;
    print "Logged in as: $self->{user_name}";
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
		    "&copy; 1989-2005 LCHC | $elapsed seconds");

    return 1;
}

####
## Various HTML items
sub spaces_menu($$$$$) {
    my($self, $name, $menuOptions, $sqlOptions, $sqlOptionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the spaces menu
    my $sql = $db->sql_space($sqlOptions, $sqlOptionsOps);
    my @res = $db->complex_results($sql);
    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = $row->{name};
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

return(1);
