<?php 
	// echo nl2br(shell_exec("bash ./data.sh 2>&1"));
	$file = $_POST['name'];
	$folder = $_POST['folder'];

	// Extract filename
	$file_name_only = substr($file,0,strrpos($file,"."));

	shell_exec("bash ./data.sh ".$folder.'/'.$file_name_only.' 2>&1');
	echo $folder."/".$file_name_only."_rdp_output"."/".$file_name_only."_otus1_tax_assignments.txt";

 ?>