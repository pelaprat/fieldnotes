<?php
	mysql_connect("localhost", "fieldnote", "b2nXtULC") or die(mysql_error());
	mysql_select_db("fieldnote") or die(mysql_error());
	
	function getAllKids($courseId){
		$sql = "select *, if(course = $courseId, 'checked', '') as checked from t_kid left join tnCourseKid on t_kid.id = tnCourseKid.kid order by checked desc, first, last asc";
		$result = mysql_query($sql) or die(mysql_error());
		return $result;
	}
	function getAllActivities($courseId){
		$sql = "select *, if(course = $courseId, 'checked', '') as checked from t_activity left join tnCourseActivity on t_activity.id = tnCourseActivity.activity order by checked desc, name asc";
		$result = mysql_query($sql) or die(mysql_error());
		return $result;
	}
	function getCourseInfo($id){
		$sql = "select * from tn_course where id = $id";
		$result = mysql_query($sql) or die(mysql_error());
		return $result;
	}
	function getActivityMapIDs($courseID){
		$sql = "select activity as id from tnCourseActivity where course = $courseID";
		$result = mysql_query($sql) or die(mysql_error());
		$ret = Array();
		while($row = mysql_fetch_assoc($result)){
			$ret[] = $row['id'];
		}
		return $ret;
	}
	function getKidMapIDs($courseID){
		$sql = "select kid as id from tnCourseKid where course = $courseID";
		$result = mysql_query($sql) or die(mysql_error());
		$ret = Array();
		while($row = mysql_fetch_assoc($result)){
			$ret[] = $row['id'];
		}
		return $ret;
	}
	function echoMultiSelectKids($courseId){
		$kids = getAllKids($courseId);
		echo "<div style='width:300px;height:400px;overflow:auto;'>";
		$id_array = array();
		while($row = mysql_fetch_assoc($kids)){
			if(in_array($row['id'], $id_array)){
				continue;
			}
			else{
				$id_array[] = $row['id'];
			}
			echo "<input name='kids[]' type='checkbox' VALUE='" . $row['id'] . "' " . $row['checked'] . ">" . $row['first'] . " " . $row['last']  . "<br>\n";
		}
		echo "</div>";
	}
	function echoMultiSelectActivities($courseId){
		$kids = getAllActivities($courseId);
		echo "<div style='width:300px;height:400px;overflow:auto;'>";
		$id_array = array();
		while($row = mysql_fetch_assoc($kids)){
			if(in_array($row['id'], $id_array)){
				continue;
			}
			else{
				$id_array[] = $row['id'];
			}
			echo "<input name='activities[]' type='checkbox' VALUE='" . $row['id'] . "' " . $row['checked'] . ">" . $row['name'] . "<br>\n";
		}
		echo "</div>";
	}
	function createItem($key, $val){
		$sql = "select * from lchc_simple_map where item_key = '$key'";
		if(0 == mysql_num_rows(mysql_query($sql))){
			$sql = "insert into lchc_simple_map(item_key, item_content) values('$key', '$val')";
		}
		else{
			$sql = "update lchc_simple_map set item_content = '$val' where item_key = '$key'";
		}
		mysql_query($sql) or die(mysql_error());
	}
	
	
	if(null == $_GET['course']){
		echo "<html><body>No can do!</body></html>";
		return;
	}
	
	$course = getCourseInfo($_GET['course']);
	
	if(0 == mysql_num_rows($course)){
		echo "<html><body>No can do!</body></html>";
		return;
	}
	$course = mysql_fetch_assoc($course);
	
	$update_message = "";
	
	if(null != $_GET['step'] && $_GET['step'] === "updatemap"){
		$course_id = $course['id'];
		
		$_POST['kids'] = (null == $_POST['kids'] ? Array():$_POST['kids']);
		$_POST['activities'] = (null == $_POST['activities'] ? Array():$_POST['activities']);
		
		///Delete all course -> kid mappings which are not found in the submitted POST['kids'].
		///This indicates unchecked kids
		$prev_ids = getKidMapIDs($course_id);
		$diff = array_diff($prev_ids, $_POST['kids']);
		if(count($diff) > 0){
			$sql = "delete from tnCourseKid where course = $course_id and kid in (";
			foreach($diff as $activity){
				$sql .= "$activity,";
			}
			$sql = substr($sql, 0, -1);
			$sql .= ")";
			mysql_query($sql) or die(mysql_error());
		}
		
		
		if(count($_POST['kids']) > 0){
			$sql = "replace into tnCourseKid(course, kid) values ";
			foreach($_POST['kids'] as $kid){
				$sql .= "($course_id,$kid),";
			}
			$sql = substr($sql, 0, -1);
			mysql_query($sql) or die(mysql_error());
		}
		
		///Delete all course -> activity mappings which are not found in the submitted POST['activities'].
		///This indicates unchecked activities
		$prev_ids = getActivityMapIDs($course_id);
		$diff = array_diff($prev_ids, $_POST['activities']);
		if(count($diff) > 0){
			$sql = "delete from tnCourseActivity where course = $course_id and activity in (";
			foreach($diff as $activity){
				$sql .= "$activity,";
			}
			$sql = substr($sql, 0, -1);
			$sql .= ")";
			mysql_query($sql) or die(mysql_error());
		}
		
		///Add all newly checked activities.
		if(count($_POST['activities']) > 0){
			$sql = "replace into tnCourseActivity(course, activity) values ";
			foreach($_POST['activities'] as $activity){
				$sql .= "($course_id,$activity),";
			}
			$sql = substr($sql, 0, -1);
			mysql_query($sql) or die(mysql_error());
		}
		$update_message = "<font size='+2' color='blue'>Kids/Activites successfully update.</font>";
	}
	
?>

<html><body><center>
	<form method='post' action='course_activity_kids_map.php?step=updatemap&course=<?php echo $_GET['course']; ?>'>

	<?php 
		echo "<h2>" . $course['name'] . "</h2>";
		echo $update_message;
	?>
	
	<table width='600'>
	<tr><td colspan='2'>
	Choose the kids and activities for this course and click --&gt;<input type='submit' value='update'>&lt;-- when you're done.
	Note: all currently selected kids and activities appear first (and checked).  Uncheck kids/activites you want 
	removed, and check new kids/activities you want to add.
	</td></tr>
	<tr>
		<td><center><h3>Kids</h3></center>
		<?php
			echoMultiSelectKids($_GET['course']);
		?>
		</td>
		<td><center><h3>Activities</h3></center>
		<?php
			echoMultiSelectActivities($_GET['course']);
		?>
		</td>
	</tr></table>
	</form>
</center></body></html>
