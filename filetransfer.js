$(document).ready(function() {
	
	// Makes sure the dataTransfer information is sent when we
	// Drop the item in the drop box.
	// jQuery.event.props.push('dataTransfer');
	
	// The number of images to display
	var maxFiles = 5;
	var errMessage = 0;
	
	// Get all of the data URIs and put them in an array
	var dataArray = [];
	var taxAssignOption = {};

	var ProgressBar = {
		setPercent : function(val) {
			$('#loading-bar .loading-color').css({'width' : val +'%'});
		},
		setHTML : function(htmltext) {
			$('#loading-content').html(htmltext);
		},
		concatHTML : function(htmltext) {
			$('#loading-content').html($('#loading-content').html() + htmltext);
		},
		hide: function() {
			$('#loading').css({'display' : 'none'});
		},
		show: function() {
			$("#loading").show();
		}
	};

	$('#checkFwd').prop('checked', true);
	
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
		
		return false;
	}

	function uploadFiles(toBeUploadedArray, taxAssignOptions) {

		// Set UI
		$("#loading").show();
		$('#uploaded-holder').hide();
		$('#upload-button').hide();
		$('#result-link').hide();
		$('#result-link span').html("");
		ProgressBar.setHTML('Uploading '+toBeUploadedArray[0].name);
		ProgressBar.setPercent(0);

		var totalPercent = 100 / toBeUploadedArray.length;
		var x = 0;
		var y = 0;
		var uploadFinishedArray = [];
		
		
		$.each(toBeUploadedArray, function(index, item) {	
			
			$.post('upload.php', item, function(data) {
			
				var fileName = item.name;
				++x;
				
				// Change the bar to represent how much has loaded
				ProgressBar.setPercent(totalPercent*(x));
				
				if((x) == toBeUploadedArray.length) {
					// Show the upload is complete
					ProgressBar.setHTML('Uploading Complete!');

					// CALL
					setTimeout(function() {makeOTUTable(uploadFinishedArray, taxAssignOptions);}, 500);
					
				} else if((x) < toBeUploadedArray.length) {
				
					// Show that the files are uploading
					ProgressBar.setHTML('Uploading '+fileName);
					
				}
				
				// Show a message showing the file URL.
				var dataSplit = data.split(':');
				if(dataSplit[1] == 'uploaded successfully') {
					// Upload succeeded
					uploadFinishedArray.push({name : dataSplit[0].split('/')[1], folder : dataSplit[0].split('/')[0]});
				} else {
					// Upload failed
					printMSG("ERROR: file " + fileName + " upload failed");
				}
				
			});
		});
		return false;
	}

	function makeOTUTable(uploadFinishedArray, taxAssignOptions) {

		ProgressBar.setPercent(0);
		ProgressBar.setHTML('Making OTU Table is on going');
		var OTUTbl = ""

		if (0 == uploadFinishedArray.length)
		{
			ProgressBar.setHTML('upload failed!');
			setTimeout(restartFiles(), 500);
		}

		$.post('DNA/makeotu.php', 
			combineJSON(makeOTUTarget(uploadFinishedArray),taxAssignOptions), 
			function(data) {
			
			// Change the bar to represent how much has loaded
			ProgressBar.setPercent(100);
			
			// Set OTUTable
			OTUTbl = data;

			// Show the upload is complete
			ProgressBar.setHTML('Making OTU Table Complete!');

			// CALL
			setTimeout(function() {makeTaxAssign(OTUTbl, taxAssignOptions);}, 500);
		});
	}

	function makeTaxAssign(OTUTbl, taxAssignOptions) {

		var toBeArchivedArray = {};
		var x = 0;

		ProgressBar.setPercent(0);

		// Exception Handling
		if (OTUTbl == "")
		{
			ProgressBar.setHTML('upload failed!');
			setTimeout(restartFiles(), 500);
			return;
		}

		taxAssignOptions['OTUTbl'] = OTUTbl;
		ProgressBar.setHTML('Assigning taxonomy');


		$.post('DNA/taxassn.php', taxAssignOptions, 
			function(data) {
			
			// TODO: Add toArchiveList
			if (data == "ERROR")
			{
				printMSG("ERROR: assigning taxonomy failed");
				setTimeout(restartFiles(), 500);
			}
			else
			{
				ProgressBar.setPercent(100);
				toBeArchivedArray['0'] = OTUTbl + '/otus1.txt';
				// TODO: EDIT BELOW!!!!!!!!!!!!!
				toBeArchivedArray['1'] = OTUTbl + '/tax_assign_result_here.txt';
				toBeArchivedArray["count"] = 2;
				// Show the upload is complete
				ProgressBar.setHTML('Assigning taxonomy Complete!');
				console.log(toBeArchivedArray);
				setTimeout(function() {archive(toBeArchivedArray);}, 500);
			}
			
		});
		
	}

	function archive(toBeArchivedArray) {

		ProgressBar.setPercent(0);	

		// Exception Handling
		if (Object.keys(toBeArchivedArray).length < 2)
		{
			ProgressBar.setHTML('Assigning taxonomies failed!');
			setTimeout(restartFiles(), 500);
		}

		ProgressBar.setHTML('zipping taxonomy assign files');
		$.post('DNA/archive.php', toBeArchivedArray)
		  .done(function(data) {

		  	ProgressBar.setPercent(100);
			ProgressBar.setHTML('zipping succeeded');

			printMSG('RESULT: <a href=./DNA/'+data+'>'+data+'</a>');

			// Fill uploaded data form 
			var realData = '<li><a href=./DNA/'+data+'>'+data+'</a> uploaded successfully </li>';
			$('#uploaded-files').append('<li><a href="images/'+dataSplit[0]+'">'+fileName+'</a> '+dataSplit[1]+'</li>');
			window.localStorage.setItem(window.localStorage.length, realData);

		})
		.fail(function() {
			ProgressBar.setHTML('zipping failed');
			setTimeout(restartFiles(), 500);
		});
	}

	function validateForm() {
		var taxAssignOptions = {};
		if ((!($('#checkFwd').is(":checked")))
			 && (!($('#checkRev').is(":checked"))))
		{
			alert('One of Fwd seq, Rev seq check boxes should be checked.');
			return {};
		}

	    var x = $("#optionForm").serializeArray();
	    $.each(x, function(i, field){
	        taxAssignOptions[field.name]=field.value;
	    });
		return taxAssignOptions;
	}

	function combineJSON(obj1, obj2) {
		var result = {};
		for(var key in obj1) result[key] = obj1[key];
		for(var key in obj2) result[key] = obj2[key];	
		return result;	
	}

	function makeOTUTarget(filelist) {
		var OTUTarget = {};
		$.each(filelist, function(index, value) {
			OTUTarget[index.toString()] = value.folder + "/" + value.name;
		});
		OTUTarget["count"] = filelist.length;
		return OTUTarget;
	}

	function printMSG(str) {
		var innerHTMLtext = $('#result-link span').html();
			$('#result-link').show();
			if (innerHTMLtext != "")
			{
				$('#result-link span').html(innerHTMLtext + '<br>' + str);
			} else
			{
				$('#result-link span').html(str);
			}
	}
	
	// Upload
	$('#upload-button .upload').click(function() {
		$('#result-link span').html("");
		var taxAssignOptions = validateForm();
		if (Object.keys(taxAssignOptions).length == 0)
		{
			printMSG("You choose wrong options");
			return restartFiles();
		}
		else
		{
			return uploadFiles(dataArray, taxAssignOptions);
		}
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