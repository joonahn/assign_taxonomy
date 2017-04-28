<?php

// We're putting all our files in a directory called images.
$uploaddir = 'DNA/';

// The posted data, for reference
$file = $_POST['value'];
$name = $_POST['name'];

// Get the mime
$getMime = explode('.', $name);
$mime = end($getMime);

// Separate out the data
$data = explode(',', $file);

// Encode it correctly
$encodedData = str_replace(' ','+',$data[1]);
$decodedData = base64_decode($encodedData);

// You can use the name given, or create a random name.
// We will create a random name!

// $randomName = substr_replace(sha1(microtime(true)), '', 12).'.'.$mime;
$randomFolder = substr_replace(sha1(microtime(true)), '', 12);


if (preg_match("/IonXpress_[\d]{3}/", $name, $matches))
{
	$new_name = $matches[0].'.'.$mime;

	shell_exec("mkdir DNA/".$randomFolder);


	if(file_put_contents($uploaddir.$randomFolder.'/'.$new_name, $decodedData)) {
	    echo $randomFolder.'/'.$new_name.":uploaded successfully";
	}
	else {
	    // Show an error message should something go wrong.
	    echo $name.":uploading failed";
	}
	
}
else
{
	echo $name.":uploading failed";
}



?>