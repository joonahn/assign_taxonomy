<?php 
	// echo nl2br(shell_exec("bash ./data.sh 2>&1"));
	$file = $_POST['name'];
	$folder = $_POST['folder'];

	// Argument filling
	$a2 = $_POST['primerseq'];
	$a3 = "";
	if(isset($_POST['checkFwd']))
		$a3 = $a3."fwd";
	if(isset($_POST['checkRev']))
		$a3 = $a3."rev";
	if(isset($_POST['checkFull']))
		$a3 = $a3."full";
	if ($a3 === "")
		$a3 = "empty";
	$a4 = $_POST['taxalg'];
	$a5 = $_POST['rdpdb'];
	$a6 = $_POST['conflevel'];
	$a7 = $_POST['taxlevel'];


	$count = intval($_POST['count']);
	$randomFolder = substr_replace(sha1(microtime(true)), '', 12);
	$filenames = array();
	$otutargets = "";

	for ($i = 0; $i < $count; $i++) {
		array_push($filenames, strval($_POST[$i]));
	}

	foreach ($filenames as $filename) {
		$otutargets .= " \"{$filename}\"";
	}


	// Extract filename
	$file_name_only = substr($file,0,strrpos($file,"."));

	// Make shell arguments
	$shellarg = "\"{$folder}/{$file_name_only}\" {$a2} {$a3} {$a4} {$a5} {$a6} {$a7} {$randomFolder} {$otutargets}";

	// echo nl2br(shell_exec("bash ./data.sh ".$shellarg." 2>&1"));
	shell_exec("bash ./makeotu.sh ".$shellarg." 2>&1");
	echo $randomFolder;

 ?>