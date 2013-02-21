<html>
 <body>
   <center>Hello there <?php echo (null == $_GET['name'] ? "don't know you":$_GET['name'])?>,
 I like your title ("<? echo $_GET['title'] ?>"), 
it is amazing that you are only <?php echo $_GET['age'];?>  years old.i

<a href='mark.php?secret=letmein'>Click here</a>

<?php if($_GET['secret'] != null){ echo 'Ahhh, you\'re secret is ' . $_GET['secret'];} ?>

</body></html>
