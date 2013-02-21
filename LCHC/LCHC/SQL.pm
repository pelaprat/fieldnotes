package LCHC::SQL;

use DBI;
use strict;

use vars qw($VERSION @ISA);

require Exporter;
require AutoLoader;

$VERSION = '0.023';
@ISA     = qw(Exporter AutoLoader);

#######################
# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
        db_user       => 'fieldnote',
        db_pass       => 'DkKDxkJw',
	db_name       => 'fieldnote',
        db_host       => 'localhost',
        db            =>  undef,

	## System wide tables; fieldnotes too
	tPerson             => 't_person',

	## Fieldnotes Tables
	tnActivity            => 't_activity',
	tnComment             => 'tn_comment',
	tnCommentSite         => 'tn_comment_site',
	tnConference          => 'tn_conference',
	tnCourse              => 'tn_course',
	tnCourseActivity      => 'tnCourseActivity',
	tnCourseKid           => 'tnCourseKid',
	tnCourseSpace         => 't_course_space',
	tnFieldnote           => 'tn_fieldnote',
	tnFieldnoteActivity   => 't_fieldnote_activity',
	tnFieldnoteKid        => 't_fieldnote_kid',
	tnKid                 => 't_kid',
	tnPersonCourse        => 'tn_person_course',
	tnSite                => 't_site',
	tnSiteActivity        => 'tnSiteActivity',
	tnSiteKid             => 'tnSiteKid',
	tnQuarterOrder        => 'quarter_order',
	tnFieldnoteAttachment => 'tn_fieldnote_attachment',
	tnCommentAttachment   => 'tn_comment_attachment',

	## Vftp Tables
	tvFile        => 'tv_file',
	tvSpace       => 'tv_space',
	tvCourseSpace => 't_course_space'
    };

    ## Bless the object, creates it                                                                    
    bless($self, $class);

    ## Connect to the database                                                                         
    $self->connect() || die "Error connecting to the database\n\n";

    ## Return the ptr to object                                                                        
    return $self;
}

# destructor
sub DESTROY($) {
    my $self = shift;
    $self->{db}->disconnect if defined $self->{db};

} 

sub connect($) {
    my($self) = @_;
    $self->{db} = DBI->connect("DBI:mysql:database=$self->{db_name};host=$self->{db_host};",
                               $self->{db_user}, $self->{db_pass}, {RaiseError => 1, AutoCommit => 1});

    return 1;
}

sub print($) {
    my($self) = @_;

    printf("ladida\n");
}

####
## Set functions
sub set_pn($$) {
    my($self, $pn) = @_;
    $self->{var_pn} = $pn;
    return 1;
}

################################
###### GENERAL FUNCTIONS #######
sub do($$) {
    my($self, $sql) = @_;
    return $self->{db}->do($sql);

}

sub simple_add($$@) {
    my($self, $table, @values) = @_;
    my $values = join(',', @values);
    my $sql = "insert into $table values($values)";

    my $sth = $self->{db}->prepare($sql);
    $sth->execute;
    my $id = $sth->{mysql_insertid};
    $sth->finish;

    return $id;
}

sub simple_one_field_results($$) {
   my($self, $sql) = @_;
    my($sth, @row, @results);
    @results = ();

    $sth = $self->{db}->prepare($sql);
    $sth->execute;
    while(@row = $sth->fetchrow_array) {
	push(@results, $row[0]);
    }
    $sth->finish;

    return @results;
}

sub complex_results($$) {
    my($self, $sql) = @_;
    my($sth, $row_num, @results);
    @results = ();
    $row_num = 0;

    $sth = $self->{db}->prepare($sql);
    $sth->execute;
    while(my $row = $sth->fetchrow_hashref) {
	$results[$row_num] = {};

	foreach my $key (keys(%$row)) {
	    $results[$row_num]{$key} = $row->{$key};
	}

	$row_num++;
    }
    $sth->finish;

    return @results;
}

####                                                                                                   
## Login / Logout                                                                                      
sub login($$$) {
    my($self, $user, $pass) = @_;

    my $sql = "select id from $self->{pPerson} where id=$user and pass=md5('$pass')";
    my @res = $self->simple_one_field_results($sql);
    if(scalar(@res) >= 1) {
        return pop(@res);
    } else {
        return -1;
    }
}

############################
## General Query Function ##
sub sql_order_clause($$) {
    my($self, $options) = @_;
    my $order = '';

    ## Order then sort
    if(exists $options->{order} && $options->{order} ne '') {
	$order .= " order by $options->{order}";
	if(defined $options->{sort} && $options->{sort} ne '') {
	    $order .= " $options->{sort}";
	}
    }

    return $order;
}

sub sql_delete_order_sort($$) {
    my($self, $options) = @_;

    ## Order then sort
    if(exists $options->{order} && $options->{order} ne '') {
	delete($options->{order});
	if(defined $options->{sort} && $options->{sort} ne '') {
	    delete($options->{sort});
	}
    }

    return 1;
}

sub sql_simple_query($$$$$) {
    my($self, $table, $data, $options, $optionsOps) = @_;
    my @data    = @$data;
    my %options = %$options;
    my @options = ();
    my $select  = '';
    my $where   = '';
    my $order   = '';

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    $order = $self->sql_order_clause($options);
             $self->sql_delete_order_sort($options);

    ## Select clause
    if(scalar @data <= 0) {
        $select = "select * from $table";
    } else {
        my $dataJoin = join(',', @data);
        $select .= "select $dataJoin from $table ";
    }

    ## Where clause
    $where = $self->optionsString($options, $optionsOps);
    $where = " where $where" if $where ne '';

    return "$select $where $order";
}

sub sql_person($$$) {
    my($self, $options, $optionsOps) = @_;
    my @data = ('*', "CONCAT($self->{tPerson}.first, ' ', $self->{tPerson}.last) as fullname");
    return $self->sql_simple_query($self->{tPerson}, \@data, $options, $optionsOps);
}

######################
## Helper Functions ##
sub exists($$) {
    my($self, $query) = @_;
    my $db = $self->{db};
    my($numrows, $sth) = (0, undef);

    $sth = $db->prepare($query);
    $sth->execute;
    if($sth->rows() > 0) {
	$numrows = $sth->rows();
    }
    $sth->finish;

    return $numrows;
}

####################
## Data Functions ##
sub get_data($$) {
    my($self, $query) = @_;
    my %data  = ();

    my $sql = $self->{db};
    my $row = $sql->selectrow_hashref($query);

    foreach my $key (keys(%$row)) {
        $data{$key} = $row->{$key};
    }

    if(scalar(keys(%data)) > 0) {
        return \%data;
    } else {
        return undef;
    }
}

sub get_person($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_person($options, $optionsOps);
    return $self->get_data($query);
}

#####################
## Helper function ##
sub optionsString($$$) {
    my($self, $options, $optionsOps) = @_;
    my @options = ();
    my $string  = '';

    if(exists $options->{order2}) {
	print  "SHIT<br>";
    }

    ## Setup the options as an array                                                                
    foreach my $key (keys(%$options)) {
        my $operator = '=';
        ## If there is an operate, we get that                                                      
        if(defined $optionsOps->{$key}) {
            $operator = $optionsOps->{$key};
        }

        ## Push the option on the stack                                                             
        push(@options, "$key $operator $options->{$key}");
    }

    ## Add the options if there are some                                                            
    if(scalar(@options) > 0) {
        $string = join(' and ', @options);
    }

    return $string;
}


sub sql_course_space($%) {
    my($self, %options) = @_;
    my $tnCourseSpace = $self->{tnCourseSpace};
    my $tnCourse      = $self->{tnCourse};
    my $tvSpace       = $self->{tvSpace};

    my $sql = ('select *,       ' .
	       " $tvSpace.id as 'space_id', $tvSpace.name as 'space_name', $tvSpace.parent,       " .
	       " $tvSpace.path, $tvSpace.server,                                                   " .
	       " $tnCourse.instructor, $tnCourse.program, $tnCourse.number, $tnCourse.quarter,   " .
	       " $tnCourse.year, $tnCourse.current, $tnCourse.name as 'course_name',              " .
	       " $tnCourse.id as 'course_id'                                                        " .
	       " from $tnCourseSpace, $tnCourse, $tvSpace where                                   " .
	       " $tnCourseSpace.course = $tnCourse.id and $tnCourseSpace.space = $tvSpace.id     ");


    ## Course
    if(defined $options{course} && $options{course} > 0) {
	$sql .= " and course = $options{course}";
    }

    ## Space
    if(defined $options{space} && $options{space} > 0) {
	$sql .= " and space = $options{space}";
    }

    ## Type
    if(defined $options{type} && $options{type} > 0) {
        $sql .= " and type = $options{type}";
    }

    return $sql;
}



return(1);
