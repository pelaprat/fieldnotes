<?php
	mysql_connect("localhost", "lchc", "zvYsdYOL") or die(mysql_error());
	mysql_select_db("fieldnote") or die(mysql_error());
	
	function getFieldNotes(){
		/*
		$sql = "select f.*, k.*, a.* 
				from   tn_fieldnote f
                       left join t_fieldnote_activity fa on f.id = fa.fieldnote
                       left join t_activity a on fa.activity = a.id
                       left join t_fieldnote_kid fk on f.id = fk.fieldnote
                       left join t_kid k on fk.kid = k.id
				where f.course in ( 114, 118, 115)";
				*/
		$sql = "select * from tn_fieldnote where course in ( 114, 118, 115)";
		
		$result = mysql_query($sql) or die(mysql_error());
		return $result;
	}

	$result = getFieldNotes();
	
	$fields = Array();
	$num_fields = mysql_num_fields($result);
	$i = 0;
	for(; $i < $num_fields; $i += 1)
		$fields[] = mysql_field_name($result, $i);
	
	header("Content-type: text/x-csv");
	header("Content-Disposition: attachment; filename=dump.csv");
	header("Pragma: no-cache");
	header("Expires: 0");
	
	echo implode(",", $fields) . "\n";
	while( $row = mysql_fetch_row( $result ) ){
		$line = '';
		foreach( $row as $value ){                                            
			if ( ( !isset( $value ) ) || ( $value == "" ) ){
				$value = ",";
			}
			else{
				$value = str_replace( '"' , '""' , $value );
				$value = '"' . $value . '"' . ",";
			}
			$line .= $value;
		}
		echo str_replace( "\r" , "", trim( $line ) . "\n");
	}

?>







