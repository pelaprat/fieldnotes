package LCHC;

use strict;
use CGI;
use DBI;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use vars qw($VERSION @ISA);

require Exporter;
require AutoLoader;

$VERSION = '0.93';
@ISA     = qw(Exporter AutoLoader);

####
## Constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $root = shift;
    if( ! defined $root ) {
	$root = 'http://fieldnotes.ucsd.edu';
    }

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time);

    my $self = {
	cookieName        => 'lchcuser',

	dir_backup        => '/Users/lchc/backup',
	dir_backup_db     => '/Users/lchc/backup/databases/fieldnote',

	format_date       => '\'%d %M %Y\'',
        home_directory    => '/Users/lchc',
        pacakge_directory => '/Users/lchc',

        uri_root          => $root,

        user_admin        => 0,
	user_name         => 'no name',
	user_email        => 'no email',

	var_db            => undef,
	var_cgi           => undef,
        var_starttime     => undef,
	var_user          => -1,

        _year_current     => (1900 + $year),
        _year_interval    => 3

    };

    $self->{_year_base} = $self->{_year_current} - $self->{_year_interval} + 1;

    bless($self, $class);
    return $self;
}

####
## Set Functions
sub set_db($$) {
    my($self, $db) = @_;
    $self->{var_db} = $db;
    return 1;
}

sub set_user($$) {
    my($self, $user) = @_;
    my $db            = $self->{var_db};
    my $t_person      = $db->{t_person};
    $self->{var_user} = $user;

    if(defined $self->{var_db} && defined $user && $user > 0) {
	my %options = ('id' => $user);
	my $person  = $db->get_person(\%options, {});
	$self->{user_name}  = "$person->{first} $person->{last}";
	$self->{user_email} =  $person->{email};
	$self->{user_admin} =  $person->{admin};
	$self->{user_instr} =  $person->{instructor};
    } else {
	$self->{user_name}  = 'no name';
	$self->{user_email} = 'no email';
	$self->{user_admin} =  0;
    }

    return 1;
}

sub set_cgi($$) {
    my($self, $cgi) = @_;
    $self->{var_cgi} = $cgi;
    return 1;
}

####
## Access Control & Header
##
sub control_access($) {
    my ($self) = @_;

    ## Let children override
    $self->http_header();
    return 1;
}

sub http_header($) {
    my($self) = @_;
    my($cgi)  = $self->{var_cgi};
    print $cgi->header(-type=>'text/html',
		       -expires=>0,
		       -pragma=>'no-cache',
		       -Cache_Control=>'no-store, no-cache, must-revalidate, post-check=0, pre-check=0');
    return 1;
}

##################
## Format stuff ##
sub safe_single_quotes($$) {
    my($self, $text) = @_;

    $text =~ s/\xD0/\:/g;
    $text =~ s/\xD2/\"/g;
    $text =~ s/\xD3/\"/g;
    $text =~ s/\xD5/\'/g;

    $text =~ s/\\\\/\\/g;
    $text =~ s/\\\'/\'/g;
    $text =~ s/\\/\\\\/g;
    $text =~ s/\'/\\\'/g;

    return $text;
}

####################
## Login / Logout ##
sub login($$$) {
    my($self, $user, $pass) = @_;
    my $db      = $self->{var_db};
    my $tPerson = $db->{tPerson};

    my $sql = "select id from $tPerson where id=$user and pass = md5('$pass')";
    my @results = $self->{var_db}->simple_one_field_results($sql);
    if(scalar(@results) >= 1) {
        return pop(@results);
    } else {
        return -1;
    }
}

###################
## User Activity ##
sub log_user_activity( $$$ ) {
    my( $self, $user, $activity ) = @_;
    my $db      = $self->{var_db};
    my $tPerson = $db->{tPerson};

    if( defined $user && $user > 0 ) {
	$db->{db}->do( "update $tPerson set last_activity = NOW() where id = $user" );
    }

    return 1;
}

##################
## Build a menu ##
sub menu($$$$$) {
    my($self, $name, $values, $labels, $menuOptions) = @_;
    my @values   = @$values;
    my $selected = '';
    my $style    = '';

    ## Is there a style?
    if(defined $menuOptions->{style}) {
	$style = " style='$menuOptions->{style}'";
    }

    ## Start the menu
    my $menu = "<select name='$name' $style>";

    ## Empty value
    if(defined $menuOptions->{empty}) {
	unshift(@values, -1);
	$labels->{'-1'} = '--';
    }

    ## Go through each menu item
    foreach my $value (@values) {
#	print "$menuOptions->{selected} $menuOptions->{selectedOp}<br>";
	if(defined $menuOptions->{selected} && defined $menuOptions->{selectedOp}) {
	    if($menuOptions->{selectedOp} eq 'eq') {
		$selected = 'selected' if $value eq $menuOptions->{selected};
	    } elsif($menuOptions->{selectedOp} eq '==') {
		$selected = 'selected' if $value == $menuOptions->{selected};
	    }
	}

	if(defined $labels->{$value}) {
	    $menu .= "<option value='$value' $selected>$labels->{$value}</option>";
	} else {
	    $menu .= "<option value='$value' $selected>$value</option>";
	}

	$selected = '';
    }

    $menu .= '</select>';
    return $menu;
}

sub quarter_menu($$$) {
    my($self, $name, $menuOptions) = @_;

    my %labels = ();
    my @values = qw/fall winter spring summer/;
    foreach my $value (@values) {
	$labels{$value} = $value;
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub day_menu($$$) {
    my($self, $name, $menuOptions) = @_;

    my %labels = ();
    my @values = (1 .. 31);
    foreach my $value (@values) {
	$labels{$value} = $value;
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub month_menu($$$) {
    my($self, $name, $menuOptions) = @_;

    ## The labels and values
    my %labels = (1  => 'January',  2 => 'February',  3 => 'March',
		  4  => 'April',    5 => 'May',       6 => 'June',
		  7  => 'July',     8 => 'August',    9 => 'September',
		  10 => 'October', 11 => 'November', 12 => 'December');

    ## Set the values
    my @values = sort {$a <=> $b} keys(%labels);

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub year_menu($$$) {
    my($self, $name, $menuOptions) = @_;

    ## Get the current year
    my $now  = `date "+%Y"`;
    chomp($now);

    my %labels = ();

    my @values = (1989 .. $now);
    if( $menuOptions->{_year_base} == 1 ) {
	@values = ( $self->{_year_base} .. $now );
    }

    foreach my $value (@values) {
        $labels{$value} = $value;
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

sub gender_menu($$$) {
    my($self, $name, $selected) = @_;

    my @v = ('m', 'f');
    my %l = (m => 'm',f => 'f');

    my %menuOptions = (selected => $selected, selectedOp => 'eq');
    return $self->menu($name, \@v, \%l, \%menuOptions);
}

sub person_menu($$$$$) {
    my($self, $name, $menuOptions, $options, $optionsOps) = @_;
    my $db = $self->{var_db};
    my @values = ();
    my %labels = ();

    ## Create the person menu
    my $sql = $db->sql_person($options, $optionsOps);
    my @res = $db->complex_results($sql);
    foreach my $row (@res) {
        push(@values, $row->{id});
        $labels{$row->{id}} = "$row->{last}, $row->{first}";
    }

    return $self->menu($name, \@values, \%labels, $menuOptions);
}

###########################
## Size & Icon Functions ##
sub size($$) {
    my($self, $bytes) = @_;

    my $k = sprintf("%.1f", $bytes/1024);
    my $m = sprintf("%.1f", $bytes/1048576);
    my $g = sprintf("%.1f", $bytes/1073741824);

    if($g >= 1) {
        return "$g GB";
    } elsif($m >= 1) {
        return "$m MB";
    } elsif($k >= 1) {
        return "${k}k";
    } else {
        return "$bytes bytes";
    }
}

sub icon($$) {
    my($self, $type) = @_;
    my $icon = '';

    ## First do it based on mime-type
    if($type eq 'application/msword') {
        $icon = 'word.gif';
    } elsif($type eq 'application/pdf') {
        $icon = 'pdf.gif';
    } elsif($type eq 'application/vnd.ms-excel') {
        $icon = 'excel.gif';
    } elsif($type eq 'application/powerpoint') {
        $icon = 'powerpoint.gif';
    }

    ## Now based on name
    elsif($type eq 'directory') {
        $icon = 'directory.gif';
    }

    ## Now based on extension
    elsif($type eq 'doc') {
	$icon = 'word.gif';
    } elsif($type eq 'xls') {
	$icon = 'excel.gif';
    } elsif($type eq 'pdf') {
	$icon = 'pdf.gif';
    } elsif($type eq 'jpg') {
	$icon = 'text.gif';
    } elsif($type eq 'gif') {
	$icon = 'text.gif';
    } else {
	$icon = 'generic.gif';
    }

    return "$self->{uri_images}/$icon";
}

sub in($@) {
    my( $self, $key, @list ) = @_;
    foreach my $v ( @list ) {
        if( $v == $key ) {
            return 1;
        }
    }

    return 0;
}


return(1);
