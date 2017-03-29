<?php 
	echo nl2br(shell_exec("bash ./data.sh 2>&1"));
	echo "Hello world";
 ?>