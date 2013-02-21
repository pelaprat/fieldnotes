use DBI;
use LCHC::SQL;

package LCHC::SQL::Notes;

BEGIN{@ISA = qw ( LCHC::SQL );}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = LCHC::SQL->new();

    bless($self, $class);
    return $self;
}

########################################
## SQL functions for fieldnote tables ##
sub sql_activity($$$) {
    my($self, $options, $optionsOps) = @_;
    my @data = ('*');
    return $self->sql_simple_query($self->{tnActivity}, \@data, $options, $optionsOps);
}

sub sql_comment($$$) {
    my($self, $options, $optionsOps) = @_;
    my $lchc  = $self->{var_pn};

    my $tnComment    = $self->{tnComment};
    my $tnConference = $self->{tnConference};
    my $tnCourse     = $self->{tnCourse};
    my $tPerson      = $self->{tPerson};

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    my $order = $self->sql_order_clause($optionsOps);
                $self->sql_delete_order_sort($optionsOps);

    my $query = ("select                                                                    " .

		 "$tnConference.id                                    as 'conference_id',   " .
		 "$tnConference.name                                  as 'conference_name', " .

		 "$tnCourse.id                                        as 'course_id',       " .
		 "$tnCourse.name                                      as 'course_name',     " .
		 "$tnCourse.quarter                                   as 'course_quarter',  " .
		 "$tnCourse.year                                      as 'course_year',     " .
		 "$tnCourse.number                                    as 'course_number',   " .
		 "$tnCourse.program                                   as 'course_program',  " .

		 "$tPerson.id                                         as 'person_id',       " .
		 "$tPerson.email                                      as 'person_email',    " .
		 "CONCAT_WS(' ', first, middle, last)                 as 'person_name',     " .

		 "$tnComment.id                                            as 'id',          " .
		 "$tnComment.fieldnote                                     as 'fieldnote',   " .
		 "$tnComment.subject                                       as 'subject',     " .
		 "$tnComment.timestamp                                     as 'rtimestamp',  " .
		 "DATE_FORMAT($tnComment.timestamp, $lchc->{format_date})  as 'timestamp',   " .
		 "$tnComment.body                                          as 'body'         " .

		 "from $tnComment                                                     " .
		 "left join $tnConference on $tnComment.conference = $tnConference.id " .
		 "left join $tnCourse     on $tnComment.course     = $tnCourse.id     " .
		 "left join $tPerson      on $tnComment.person     = $tPerson.id      ");

    ## Check the options if they are specified
    if(defined $options->{course} && $options->{course} ne '') {
	$options->{"$tnComment.course"} = $options->{course};
	delete($options->{course});

	## Make sure op is changed too
	if(defined $optionsOps->{course} && $optionsOps->{course} ne '') {
	    $optionsOps->{"$tnComment.course"} = $optionsOps->{course};
	    delete($optionsOps->{course});
	}
    }

    if(defined $options->{conference} && $options->{conference} ne '') {
	$options->{"$tnComment.conference"} = $options->{conference};
	delete($options->{conference});

	## Make sure op is changed too
	if(defined $optionsOps->{conference} && $optionsOps->{conference} ne '') {
	    $optionsOps->{"$tnComment.conference"} = $optionsOps->{conference};
	    delete($optionsOps->{conference});
	}
    }

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    $query .= $order;

    return $query;
}

sub sql_comment_site($$$) {
    my($self, $options, $optionsOps) = @_;
    my $lchc  = $self->{var_pn};

    my $tnCommentSite = $self->{tnCommentSite};
    my $tnConference  = $self->{tnConference};
    my $tnCourse      = $self->{tnCourse};
    my $tPerson       = $self->{tPerson};

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    my $order = $self->sql_order_clause($optionsOps);
                $self->sql_delete_order_sort($optionsOps);

    my $query = ("select                                                                    " .

		 "$tnConference.id                                    as 'conference_id',   " .
		 "$tnConference.name                                  as 'conference_name', " .

		 "$tnCourse.id                                        as 'course_id',       " .
		 "$tnCourse.name                                      as 'course_name',     " .
		 "$tnCourse.quarter                                   as 'course_quarter',  " .
		 "$tnCourse.year                                      as 'course_year',     " .
		 "$tnCourse.number                                    as 'course_number',   " .
		 "$tnCourse.program                                   as 'course_program',  " .

		 "$tPerson.id                                         as 'person_id',       " .
		 "$tPerson.email                                      as 'person_email',    " .
		 "CONCAT_WS(' ', first, middle, last)                 as 'person_name',     " .

		 "$tnCommentSite.id                                            as 'id',          " .
		 "$tnCommentSite.fieldnote                                     as 'fieldnote',   " .
		 "$tnCommentSite.subject                                       as 'subject',     " .
		 "$tnCommentSite.timestamp                                     as 'rtimestamp',  " .
		 "DATE_FORMAT($tnCommentSite.timestamp, $lchc->{format_date})  as 'timestamp',   " .
		 "$tnCommentSite.body                                          as 'body'         " .

		 "from $tnCommentSite                                                     " .
		 "left join $tnConference on $tnCommentSite.conference = $tnConference.id " .
		 "left join $tnCourse     on $tnCommentSite.course     = $tnCourse.id     " .
		 "left join $tPerson      on $tnCommentSite.person     = $tPerson.id      ");

    ## Check the options if they are specified
    if(defined $options->{course} && $options->{course} ne '') {
	$options->{"$tnCommentSite.course"} = $options->{course};
	delete($options->{course});

	## Make sure op is changed too
	if(defined $optionsOps->{course} && $optionsOps->{course} ne '') {
	    $optionsOps->{"$tnCommentSite.course"} = $optionsOps->{course};
	    delete($optionsOps->{course});
	}
    }

    if(defined $options->{conference} && $options->{conference} ne '') {
	$options->{"$tnCommentSite.conference"} = $options->{conference};
	delete($options->{conference});

	## Make sure op is changed too
	if(defined $optionsOps->{conference} && $optionsOps->{conference} ne '') {
	    $optionsOps->{"$tnCommentSite.conference"} = $optionsOps->{conference};
	    delete($optionsOps->{conference});
	}
    }

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    $query .= $order;

    return $query;
}

sub sql_conference($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnConference = $self->{tnConference};
    my $tnCourse     = $self->{tnCourse};

    my $query = ("select $tnConference.id,        " .
		 "       $tnConference.course,    " .
		 "       $tnConference.name,      " .
		 "       $tnConference.fieldnote, " .
		 "       $tnConference.items      ");

    ## Is a course specified?
    if(defined $options->{course} && $options->{course} > 0) {
	$query .= (", $tnCourse.program as 'course_program'  " .
		   ", $tnCourse.number  as 'course_number'   " .
		   ", $tnCourse.name    as 'course_name'     " .
		   ", $tnCourse.quarter as 'course_quarter'  " .
		   ", $tnCourse.year    as 'course_year'     " .
		   "from  $tnConference                      " .
		   "left join $tnCourse                      " .
		   "on $tnConference.course = $tnCourse.id   ");
    } else {
	$query .= (" from $tnConference ");
    }

    ## Produce the options                                                                             
    my $optionStr = $self->optionsString($options, $optionsOps);

    ## Add the options to the query
    if($optionStr ne '') {
	$query .= " where $optionStr";
    }

    return $query;
}

sub sql_course($$$) {
    my($self, $options, $optionsOps) = @_;

    my $tnFieldnote          = $self->{tnFieldnote};
    my $tnConference         = $self->{tnConference};
    my $tnCourse             = $self->{tnCourse};
    my $tPerson              = $self->{tPerson};
    my $tnQuarterOrder       = $self->{tnQuarterOrder};

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    $order = $self->sql_order_clause($options);
    $self->sql_delete_order_sort($options);

    my $query = ("select  " .

                 "$tnCourse.id        as 'id',         " .
                 "$tnCourse.name      as 'name',       " .
                 "$tnCourse.quarter   as 'quarter',    " .
                 "$tnCourse.year      as 'year',       " .
                 "$tnCourse.number    as 'number',     " .
                 "$tnCourse.program   as 'program',    " .
		 "$tnCourse.current   as 'current',    " .
		 "CONCAT(program, ' ', number, ' - ',       " .
		 " $tnCourse.name, ' [', quarter, ' ',      " .
		 " number, ']')                             " .
		 "   as 'fullname'                          " .
		 '                                          ' .
		 " from $tnCourse                           " .
		 '                                          ' .
		 " left join $tnQuarterOrder on $tnQuarterOrder.name=$tnCourse.quarter ");

    ## Check the options if they are specified
    if(defined $options->{id} && $options->{id} ne '') {
	$options->{"$tnFieldnote.id"} = $options->{id};
	delete($options->{id});

	## Make sure op is changed too
	if(defined $optionsOps->{id} && $optionsOps->{id} ne '') {
	    $optionsOps->{"$tnFieldnote.id"} = $optionsOps->{id};
	    delete($optionsOps->{id});
	}
    }

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

#    $query .= $order;
    $query .= "order by year desc, $tnQuarterOrder.id desc, $tnCourse.program desc ,$tnCourse.name asc";

    return $query;
}

sub sql_fieldnote($$$) {
    my($self, $options, $optionsOps) = @_;
    my $lchc  = $self->{var_pn};

    my $tnFieldnote          = $self->{tnFieldnote};
    my $tnConference         = $self->{tnConference};
    my $tnCourse             = $self->{tnCourse};
    my $tPerson              = $self->{tPerson};
    my $tSite                = $self->{tnSite};

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    my $order = $self->sql_order_clause($optionsOps);
                $self->sql_delete_order_sort($optionsOps);

    my $query = ("select  " .

		 "$tnConference.id                                    as 'conference_id',   " .
		 "$tnConference.name                                  as 'conference_name', " .

		 "$tnCourse.id                                        as 'course_id',       " .
		 "$tnCourse.name                                      as 'course_name',     " .
		 "$tnCourse.quarter                                   as 'course_quarter',  " .
		 "$tnCourse.year                                      as 'course_year',     " .
		 "$tnCourse.number                                    as 'course_number',   " .
		 "$tnCourse.program                                   as 'course_program',  " .

		 "$tPerson.id                                         as 'person_id',       " .
		 "$tPerson.email                                      as 'person_email',    " .
		 "CONCAT_WS(' ', first, middle, last)                 as 'person_name',     " .

		 "$tSite.name                                         as 'site_name',       " .

		 "$tnFieldnote.id                                              as 'id',          " .
		 "$tnFieldnote.timestamp                                       as 'rtimestamp',  " .
		 "DATE_FORMAT($tnFieldnote.dateofvisit, $lchc->{format_date})  as 'dateofvisit', " .
		 "DATE_FORMAT($tnFieldnote.timestamp,   $lchc->{format_date})  as 'timestamp',   " .
		 " date($tnFieldnote.dateofvisit) as 'date_dateofvisit',                         " .
		 "$tnFieldnote.general                                         as 'general',     " .
		 "$tnFieldnote.narrative                                       as 'narrative',   " .
		 "$tnFieldnote.gametask                                        as 'gametask',    " .
		 "$tnFieldnote.reflection                                      as 'reflection'   " .

		 "from $tnFieldnote                                     " .
		 "left join $tnConference on $tnFieldnote.conference = $tnConference.id " .
		 "left join $tnCourse     on $tnFieldnote.course     = $tnCourse.id     " .
		 "left join $tPerson      on $tnFieldnote.person     = $tPerson.id      " .
		 "left join $tSite        on $tnFieldnote.site       = $tSite.id        ");

    ## Check the options if they are specified
    if(defined $options->{id} && $options->{id} ne '') {
	$options->{"$tnFieldnote.id"} = $options->{id};
	delete($options->{id});

	## Make sure op is changed too
	if(defined $optionsOps->{id} && $optionsOps->{id} ne '') {
	    $optionsOps->{"$tnFieldnote.id"} = $optionsOps->{id};
	    delete($optionsOps->{id});
	}
    }

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    $query .= $order;

    return $query;
}

sub sql_kid($$$) {
    my($self, $options, $optionsOps) = @_;
    my @data = ('*', "CONCAT($self->{tnKid}.first, ' ', $self->{tnKid}.last) as fullname");

    #########################################
    ## Set the order/sort clause first;    ##
    ##  and delete order/sort from options ##
    my $order = $self->sql_order_clause($options);
                $self->sql_delete_order_sort($options);

    ################
    ## The query. ##
    my $query = ("select *,CONCAT(t_kid.first, ' ', t_kid.last) as fullname " .
		 " from t_kid                                  ");

    #########################
    ## Produce the options ##
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    $query .= $order;

    return $query;
}

sub sql_recent_kid( $$$$ ) {

    my($self, $year, $options, $optionsOps) = @_;

    #########################################
    ## Set the order/sort clause first;    ##
    ##  and delete order/sort from options ##
    my $order = $self->sql_order_clause($options);
                $self->sql_delete_order_sort($options);

    ################
    ## The query. ##
    $query = ( " select k.*,                                                         " .
	       "  CONCAT(k.first, ' ', k.last) as fullname " .
	       "  from t_fieldnote_kid fk                                            " .
	       "  left join tn_fieldnote f on f.id = fk.fieldnote                    " .
	       "  left join t_kid k on        k.id = fk.kid                          " .
	       " where dateofvisit between '$year-01-01 00:00:00' and NOW()          " .
	       " group by fk.kid                                                     ");

    ##################
    ## Order stuff. ##
    $query .= $order;

    return $query;

}

sub sql_site($$$) {
    my($self, $options, $optionsOps) = @_;
    my @data = ('*');
    return $self->sql_simple_query($self->{tnSite}, \@data, $options, $optionsOps);
}

####################
## Data functions ##
sub get_activity($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_activity($options, $optionsOps);
    return $self->get_data($query);
}

sub get_comment($$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_comment($options, $optionsOps);
    return $self->get_data($query);
}

sub get_conference($$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_conference($options, $optionsOps);
    return $self->get_data($query);
}

sub get_course($$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_course($options, $optionsOps);
    return $self->get_data($query);
}

sub get_fieldnote($$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_fieldnote($options, $optionsOps);
    return $self->get_data($query);
}

sub get_kid($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_kid($options, $optionsOps);
    return $self->get_data($query);
}

sub get_site($$$) {
    my($self, $options, $optionsOps) = @_;
    my $query = $self->sql_site($options, $optionsOps);
    return $self->get_data($query);
}



#########################
## Joint Table Queries ##
sub sql_course_activity($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnCourse         = $self->{tnCourse};
    my $tnActivity       = $self->{tnActivity};
    my $tnCourseActivity = $self->{tnCourseActivity};

    my $query = ("select $tnCourseActivity.*,                " .
		 "                                           " .
		 "  $tnActivity.name as 'name'               " .
		 "                                           " .
		 "from $tnCourseActivity                     " .
		 "left join $tnCourse   on $tnCourseActivity.course   = $tnCourse.id   " .
		 "left join $tnActivity on $tnCourseActivity.activity = $tnActivity.id ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}

sub sql_course_kid($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnCourse    = $self->{tnCourse};
    my $tnKid       = $self->{tnKid};
    my $tnCourseKid = $self->{tnCourseKid};

    my $query = ("select $tnCourseKid.*,                " .
		 "        $tnCourse.*,                  " .
		 "        $tnKid.*                      " .
		 "                                      " .
		 "                                      " .
		 "from $tnCourseKid                     " .
		 "left join $tnCourse on $tnCourseKid.course = $tnCourse.id " .
		 "left join $tnKid    on $tnCourseKid.kid    = $tnKid.id    ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}

sub sql_comment_attachment($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnComment           = $self->{tnComment};
    my $tvFile              = $self->{tvFile};
    my $tnCommentAttachment = $self->{tnCommentAttachment};

    my $query = ("select $tnCommentAttachment.*,          " .
                 "                                        " .
                 "  $tvFile.name as 'name'                " .
                 "                                        " .
                 "from $tnCommentAttachment               " .
                 "left join ($tnComment, $tvFile)         " .
                 "on ($tnCommentAttachment.comment = $tnComment.id and " .
                 "    $tnCommentAttachment.file      = $tvFile.id)         ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}

sub sql_fieldnote_attachment($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnFieldnote           = $self->{tnFieldnote};
    my $tvFile                = $self->{tvFile};
    my $tnFieldnoteAttachment = $self->{tnFieldnoteAttachment};

    my $query = ("select $tnFieldnoteAttachment.*,          " .
                 "                                          " .
                 "  $tvFile.name as 'name'                  " .
                 "                                          " .
                 "from $tnFieldnoteAttachment               " .
                 "left join ($tnFieldnote, $tvFile)         " .
                 "on ($tnFieldnoteAttachment.fieldnote = $tnFieldnote.id and " .
		 "    $tnFieldnoteAttachment.file      = $tvFile.id)         ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}


sub sql_fieldnote_activity($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnFieldnote         = $self->{tnFieldnote};
    my $tnActivity          = $self->{tnActivity};
    my $tnFieldnoteActivity = $self->{tnFieldnoteActivity};

    my $query = ("select $tnFieldnoteActivity.*,                " .
		 "                                              " .
		 "  $tnActivity.name as 'name'                  " .
		 "                                              " .
		 "from $tnFieldnoteActivity                     " .
		 "left join ($tnFieldnote, $tnActivity)         " .
		 "on ($tnFieldnoteActivity.fieldnote = $tnFieldnote.id and " .
		 "    $tnFieldnoteActivity.activity  = $tnActivity.id)     ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}

sub sql_fieldnote_kid($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnFieldnote    = $self->{tnFieldnote};
    my $tnKid          = $self->{tnKid};
    my $tnFieldnoteKid = $self->{tnFieldnoteKid};

    my $query = ("select $tnFieldnoteKid.*,                " .
		 "       $tnKid.*,                         " .
		 "       $tnFieldnote.*                    " .
		 "                                         " .
		 "from $tnFieldnoteKid                     " .
		 "left join $tnFieldnote on $tnFieldnoteKid.fieldnote = $tnFieldnote.id " .
		 "left join $tnKid       on $tnFieldnoteKid.kid       = $tnKid.id       ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    return $query;
}

sub sql_person_course($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tPerson        = $self->{tPerson};
    my $tnCourse       = $self->{tnCourse};
    my $tnPersonCourse = $self->{tnPersonCourse};

    ## Set the order/sort clause first;
    ##  and delete order/sort from options
    my $order = $self->sql_order_clause($optionsOps);
                $self->sql_delete_order_sort($optionsOps);

    my $query = ("select $tnPersonCourse.*,             " .
		 "                                      " .
		 " $tPerson.id  as 'person_id',         " .
		 " $tnCourse.instructor,                " .
		 " $tnCourse.program, $tnCourse.number, " .
		 " $tnCourse.name, $tnCourse.quarter,   " .
		 " $tnCourse.year, $tnCourse.current,   " .
		 "                                      " .
		 " $tPerson.first, $tPerson.middle,     " .
		 " $tPerson.last,  $tPerson.email       " .
		 "                                      " .
		 "from $tnPersonCourse                  " .
		 "left join ($tnCourse, $tPerson)       " .
		 "on ($tnPersonCourse.person = $tPerson.id and " .
		 "    $tnPersonCourse.course = $tnCourse.id)   ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
        $query .= " where $optionStr ";
    }

    $query .= $order;

    return $query;
}

sub sql_site_activity($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnSite         = $self->{tnSite};
    my $tnActivity     = $self->{tnActivity};
    my $tnSiteActivity = $self->{tnSiteActivity};

    my $query = ("select $tnSiteActivity.*,                  " .
                 "                                           " .
                 "  $tnActivity.name as 'name'               " .
                 "                                           " .
                 "from $tnSiteActivity                       " .
                 "left join $tnSite     on $tnSiteActivity.site     = $tnSite.id     " .
                 "left join $tnActivity on $tnSiteActivity.activity = $tnActivity.id ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
	$query .= " where $optionStr ";
    }

    return $query;
}


sub sql_site_kid($$$) {
    my($self, $options, $optionsOps) = @_;
    my $tnSite    = $self->{tnSite};
    my $tnKid     = $self->{tnKid};
    my $tnSiteKid = $self->{tnSiteKid};

    my $query = ("select $tnSiteKid.*,$tnKid.first,       " .
		 "  $tnKid.last, $tnKid.id                " .
                 "                                        " .
                 "from $tnSiteKid                         " .
                 "left join $tnSite on $tnSiteKid.site = $tnSite.id " .
                 "left join $tnKid  on $tnSiteKid.kid  = $tnKid.id  ");

    ## Produce the options
    my $optionStr = $self->optionsString($options, $optionsOps);
    if($optionStr ne '') {
	$query .= " where $optionStr ";
    }

    return $query;
}




#######################################
## Joint table functions and queries ##
sub course_exists($$) {
    my($self, $course) = @_;
    my %sqlOptions = (id => $course);
    my $query      = $self->sql_course(\%sqlOptions, {});
    return $self->exists($query);
}

sub course_activity_exists($$$) {
    my($self, $course, $activity) = @_;
    my %sqlOptions = (course => $course, activity => $activity);
    my $query      = $self->sql_course_activity(\%sqlOptions, {});
    return $self->exists($query);
}

sub course_kid_exists($$$) {
    my($self, $course, $kid) = @_;
    my %sqlOptions = (course => $course, kid => $kid);
    my $query      = $self->sql_course_kid(\%sqlOptions, {});
    return $self->exists($query);
}

sub fieldnote_exists($$) {
    my($self, $fieldnote) = @_;
    my %sqlOptions = (id => $fieldnote);
    my $query      = $self->sql_fieldnote(\%sqlOptions, {});
    return $self->exists($query);
}

sub fieldnote_activity_exists($$$) {
    my($self, $fieldnote, $activity) = @_;
    my %sqlOptions = (fieldnote => $fieldnote, activity => $activity);
    my $query      = $self->sql_fieldnote_activity(\%sqlOptions, {});
    return $self->exists($query);
}

sub fieldnote_kid_exists($$$) {
    my($self, $fieldnote, $kid) = @_;
    my %sqlOptions = (fieldnote => $fieldnote, kid => $kid);
    my $query      = $self->sql_fieldnote_kid(\%sqlOptions, {});
    return $self->exists($query);
}

sub person_course_exists($$$) {
    my($self, $person, $course) = @_;
    my %sqlOptions = (person => $person, course => $course);
    my $query      = $self->sql_person_course(\%sqlOptions, {});
    return $self->exists($query);
}


sub site_kid_exists($$$) {
    my($self, $site, $kid) = @_;
    my %sqlOptions = (site => $site, kid => $kid);
    my $query      = $self->sql_site_kid(\%sqlOptions, {});
    return $self->exists($query);
}

sub site_activity_exists($$$) {
    my($self, $site, $activity) = @_;
    my %sqlOptions = (site => $site, activity => $activity);
    my $query      = $self->sql_site_activity(\%sqlOptions, {});
    return $self->exists($query);
}



sub fieldnote_activity_data($%) {
    my($self, %options) = @_;
    my %activity = ();

    my $query      = $self->sql_fieldnote_activity(%options);
    my @activity = $self->complex_results($query);

    foreach my $activity (@activity) {
        my $lid = $activity->{f_id};
        if(! defined $activity{$lid}) {
            my @a = ($activity);
            $activity{$lid} = \@a;
        } else {
            my $a = $activity{$lid};
            my @a = @$a;
            push(@a, $activity);
            $activity{$lid} = \@a;
        }
    }

    return %activity;
}

sub fieldnote_kid_data($%) {
    my($self, %options) = @_;
    my %kid = ();

    $query = $self->sql_fieldnote_kid(%options);
    @kid = $self->complex_results($query);

    foreach my $kid (@kid) {
        my $lid = $kid->{f_id};
        if(! defined $kid{$lid}) {
            my @a = ($kid);
            $kid{$lid} = \@a;
        } else {
            my $a = $kid{$lid};
            my @a = @$a;
            push(@a, $kid);
            $kid{$lid} = \@a;
        }
    }

    return %kid;
}

sub conference_comment_data($%) {
    my($self, %options) = @_;
    my %comment = ();

    my $query     = $self->sql_comment(%options);
    my @comment = $self->complex_results($query);

    foreach my $comment (@comment) {
	my $lid;

	## Depends on our type of conference
	if($options{type} eq 'fieldnote') {
	    $lid = $comment->{fieldnote_id};
	} elsif($options{type} eq 'comment') {
	    $lid = $comment->{id};
	} else {
	    print 'error';
	}

        if(! defined $comment{$lid}) {
            my @a = ($comment);
            $comment{$lid} = \@a;
        } else {
            my $a = $comment{$lid};
            my @a = @$a;
            push(@a, $comment);
            $comment{$lid} = \@a;
        }
    }

    return %comment;
}

return(1);

#  LocalWords:  tnCourse
