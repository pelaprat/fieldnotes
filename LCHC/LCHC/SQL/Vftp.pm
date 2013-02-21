use DBI;
use LCHC::SQL;
package LCHC::SQL::Vftp;

BEGIN{@ISA = qw ( LCHC::SQL );}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = LCHC::SQL->new();

    bless($self, $class);
    return $self;
}

###################################
## SQL functions for vftp tables ##
sub sql_file($$$) {
    my($self, $options, $optionsOps) = @_;
    my $pn = $self->{var_pn};
    my $tvFile  = $self->{tvFile};
    my $tPerson = $self->{tPerson};
    my ($optionStr, $order);

    my $query   = ("select $tPerson.id     as 'person',  " .
		   "       $tPerson.first  as 'first',   " .
		   "       $tPerson.middle as 'middle',  " .
		   "       $tPerson.last   as 'last',    " .
		   '                                     ' .
		   "       $tvFile.id         as 'id',         " .
		   "       $tvFile.name       as 'name',       " .
		   "       $tvFile.bytes      as 'bytes',      " .
		   "       $tvFile.ext        as 'ext',        " .
		   "       $tvFile.historical as 'historical', " .
		   '                                           ' .
		   "       DATE_FORMAT(timestamp, $pn->{format_date}) as timestamp, " .
		   "       unix_timestamp(timestamp) as 'mtime'                     " .
		   '                                                                ' .
		   " from $tvFile left join $tPerson " .
		   " on $tvFile.author = $tPerson.id ");


    ## Set order/sort
    $order = $self->sql_order_clause($options);
             $self->sql_delete_order_sort($options);

    ## Produce the options
    $optionStr = $self->optionsString($options, $optionsOps);

    ## Add the options to the query
    $query .= " where $optionStr" if $optionStr ne '';
    $query .= " $order"           if $order     ne '';

    return $query;
}

sub sql_space($$$) {
    my($self, $options, $optionsOps) = @_;
    my @data = ('id', 'name', 'parent', 'path', 'server');
    return $self->sql_simple_query($self->{tvSpace}, \@data, $options, $optionsOps);
}

sub sql_course_space($$$) {
    my($self, $options, $optionsOps) = @_;
    my $pn = $self->{var_pn};
    my $tnCourse      = $self->{tnCourse};
    my $tvSpace       = $self->{tvSpace};
    my $tvCourseSpace = $self->{tvCourseSpace};
    my ($optionStr, $order);

    my $query   = ("select $tnCourse.id      as 'course',         " .
		   "       $tnCourse.program as 'program',        " .
		   "       $tnCourse.number  as 'number',         " .
		   "       $tnCourse.name    as 'course_name',    " .
		   "       $tnCourse.quarter as 'quarter',        " .
		   "       $tnCourse.year    as 'year',           " .
		   '                                              ' .
		   "       $tvSpace.id       as 'space',          " .
		   "       $tvSpace.name     as 'space_name'      " .
		   '                                              ' .
		   " from $tvCourseSpace                          " .
		   " left join ($tnCourse, $tvSpace)              " .
		   " on ($tvCourseSpace.course = $tnCourse.id and " .
		   "     $tvCourseSpace.space  = $tvSpace.id)     ");

    ## Set order/sort
    $order = $self->sql_order_clause($options);
             $self->sql_delete_order_sort($options);

    ## Produce the options
    $optionStr = $self->optionsString($options, $optionsOps);

    ## Add the options to the query
    $query .= " where $optionStr" if $optionStr ne '';
    $query .= " $order"           if $order     ne '';

    return $query;
}

####################
## Data functions ##
sub get_file($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_file($options, $optionsOps);
    return $self->get_data($query);
}

sub get_space($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_space($options, $optionsOps);
    return $self->get_data($query);
}

sub get_course_space($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_course_space($options, $optionsOps);
    return $self->get_data($query);
}

return(1);
