$(document).ready(function() {
	
	// Makes sure the dataTransfer information is sent when we
	// Drop the item in the drop box.
	// jQuery.event.props.push('dataTransfer');
	
	var z = -40;
	// The number of images to display
	var maxFiles = 5;
	var errMessage = 0;
	
	// Get all of the data URIs and put them in an array
	var dataArray = [];
	var uploadedArray = [];
	var toArchiveList = {};
	
	// Bind the drop event to the dropzone.
	$('#drop-files').bind('drop', function(e) {
			
		// Stop the default action, which is to redirect the page
		// To the dropped file
		e.preventDefault();
		
		// var files = e.dataTransfer.files;
		var files = e.originalEvent.dataTransfer.files;
		
		// Show the upload holder
		$('#uploaded-holder').show();
		
		// For each file
		$.each(files, function(index, file) {
			$('#upload-button').css({'display' : 'block'});
			
			// Start a new instance of FileReader
			var fileReader = new FileReader();
				
			// When the filereader loads initiate a function
			fileReader.onload = (function(file) {
				
				return function(e) { 
					
					// Push the data URI into an array
					dataArray.push({name : file.name, value : this.result});
					
					// Just some grammatical adjustments
					if(dataArray.length == 1) {
						$('#upload-button span').html("1 file to be uploaded");
					} else {
						$('#upload-button span').html(dataArray.length+" files to be uploaded");
					}
				}; 
			})(files[index]);
			
			// For data URI purposes
			fileReader.readAsDataURL(file);

		});
	});

	// Reset Forms
	function restartFiles() {
	
		// This is to set the loading bar back to its default state
		$('#loading-bar .loading-color').css({'width' : '0%'});
		$('#loading').css({'display' : 'none'});
		$('#loading-content').html(' ');
		// --------------------------------------------------------
		
		// We need to remove all the images and li elements as
		// appropriate. We'll also make the upload button disappear
		
		$('#upload-button').hide();
		$('#extra-files #file-list li').remove();
		$('#extra-files').hide();
		$('#uploaded-holder').hide();
	
		// And finally, empty the array/set z to -40
		dataArray.length = 0;
		uploadedArray.length = 0;
		toArchiveList = {};
		z = -40;
		
		return false;
	}

	// Run shellscript
	function makeTaxAssign() {

		var totalPercent = 100 / uploadedArray.length;
		var x = 0;
		var y = 0;

		$('#loading-bar .loading-color').css({'width' : 0 +'%'});

		// Exception Handling
		if (dataArray.length != uploadedArray.length)
		{
			$('#loading-content').html('upload failed!');
			setTimeout(restartFiles, 500);
		}

		$('#loading-content').html('Assigning taxonomy of '+ uploadedArray[0].name);
		$.each(uploadedArray, function(index, value) {	
			$.post('DNA/shell.php', uploadedArray[index], function(data) {
				
				var fileName = uploadedArray[index].name;
				++x;

				// Change the bar to represent how much has loaded
				$('#loading-bar .loading-color').css({'width' : totalPercent*(x)+'%'});
				
				// TODO: Add toArchiveList
				toArchiveList[(x-1).toString()] = data;


				if(totalPercent*(x) == 100) {
					// Show the upload is complete
					$('#loading-content').html('Assigning taxonomy Complete!');
					
					// Reset everything when the loading is completed
					// setTimeout(makeTaxAssign, 500);
					// TODO: archive this
					toArchiveList["count"] = x;
					console.log(toArchiveList);
					setTimeout(archive, 500);

				} else if(totalPercent*(x) < 100) {
				
					// Show that the files are uploading
					$('#loading-content').html('Assigning taxonomy of '+ fileName);
				}

				
			});
		});

	}

	function archive() {

		$('#loading-bar .loading-color').css({'width' : 0 +'%'});

		// Exception Handling
		if (Object.keys(toArchiveList).length != (uploadedArray.length + 1))
		{
			$('#loading-content').html('Assigning taxonomies failed!');
			setTimeout(restartFiles, 500);
		}

		$('#loading-content').html('zipping taxonomy assign files');
		$.post('DNA/archive.php', toArchiveList)
		  .done(function(data) {
			$('#loading-content').html('zipping succeeded');
			$('#result-link span').html('the link is <a href=./DNA/'+data+'>'+data+'</a>');
			setTimeout(restartFiles, 500);
		})
		.fail(function() {
			$('#loading-content').html('zipping failed');
			setTimeout(restartFiles, 500);
		});

	}
	
	// Upload
	$('#upload-button .upload').click(function() {
		
		$("#loading").show();
		$('#uploaded-holder').hide();
		$('#upload-button').hide();
		$('#result-link span').html("");

		var totalPercent = 100 / dataArray.length;
		var x = 0;
		var y = 0;
		
		$('#loading-content').html('Uploading '+dataArray[0].name);
		
		$.each(dataArray, function(index, file) {	
			
			$.post('upload.php', dataArray[index], function(data) {
			
				var fileName = dataArray[index].name;
				++x;
				
				// Change the bar to represent how much has loaded
				$('#loading-bar .loading-color').css({'width' : totalPercent*(x)+'%'});
				
				if(totalPercent*(x) == 100) {
					// Show the upload is complete
					$('#loading-content').html('Uploading Complete!');
					
					// Reset everything when the loading is completed
					setTimeout(makeTaxAssign, 500);
					
				} else if(totalPercent*(x) < 100) {
				
					// Show that the files are uploading
					$('#loading-content').html('Uploading '+fileName);
				
				}
				
				// Show a message showing the file URL.
				var dataSplit = data.split(':');
				if(dataSplit[1] == 'uploaded successfully') {
					var realData = '<li><a href="images/'+dataSplit[0]+'">'+fileName+'</a> '+dataSplit[1]+'</li>';
					
					$('#uploaded-files').append('<li><a href="images/'+dataSplit[0]+'">'+fileName+'</a> '+dataSplit[1]+'</li>');
				
					// Add things to local storage 
					if(window.localStorage.length == 0) {
						y = 0;
					} else {
						y = window.localStorage.length;
					}
					
					window.localStorage.setItem(y, realData);
					uploadedArray.push({name : dataSplit[0].split('/')[1], folder : dataSplit[0].split('/')[0]});
				
				} else {
					$('#uploaded-files').append('<li><a href="images/'+data+'. File Name: '+dataArray[index].name+'</li>');
				}
				
			});
		});
		
		return false;
	});
	
	// Just some styling for the drop file container.
	$('#drop-files').bind('dragenter', function() {
		$(this).css({'box-shadow' : 'inset 0px 0px 20px rgba(0, 0, 0, 0.1)', 'border' : '4px dashed #bb2b2b'});
		return false;
	});
	
	$('#drop-files').bind('drop', function() {
		$(this).css({'box-shadow' : 'none', 'border' : '4px dashed rgba(0,0,0,0.2)'});
		return false;
	});
	
	// For the file list
	$('#extra-files .number').toggle(function() {
		$('#file-list').show();
	}, function() {
		$('#file-list').hide();
	});
	
	$('#dropped-files #upload-button .delete').click(restartFiles);
	
	// Append the localstorage the the uploaded files section
	if(window.localStorage.length > 0) {
		$('#uploaded-files').show();
		for (var t = 0; t < window.localStorage.length; t++) {
			var key = window.localStorage.key(t);
			var value = window.localStorage[key];
			// Append the list items
			if(value != undefined || value != '') {
				$('#uploaded-files').append(value);
			}
		}
	} else {
		$('#uploaded-files').hide();
	}
});