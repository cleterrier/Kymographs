// Kymos Colorize Batch macro by Christophe Leterrier

macro "Kymos Colorize Batch" {

//*************** Initialization *************** 

	// Get the folder name 
	INPUT_DIR=getDirectory("Select the input stacks directory");
	
	print("\n\n\n*** Kymos Colorize Batch Log ***");
	print("");
	print("INPUT_DIR :"+INPUT_DIR);
	
	
	// Get all file names
	ALL_NAMES=getFileList(INPUT_DIR);
	ALL_EXT=newArray(ALL_NAMES.length);
	// Create extensions array
	for (i = 0; i < ALL_NAMES.length; i++) {
	//	print(ALL_NAMES[i]);
		ALL_NAMES_PARTS = getFileExtension(ALL_NAMES[i]);
		ALL_EXT[i] = ALL_NAMES_PARTS[1];
	}


//*************** Prepare processing *************** 

	
	// Create the output folder	
	OUTPUT_DIR = File.getParent(INPUT_DIR);
	OUTPUT_NAME = File.getName(INPUT_DIR);
	OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
	OUTPUT_SHORT = OUTPUT_SHORTA[0];
	OUTPUT_DIR = OUTPUT_DIR + File.separator + OUTPUT_SHORT + " kymo colorized" + File.separator;
	if (File.isDirectory(OUTPUT_DIR) == false) {
		File.makeDirectory(OUTPUT_DIR);
	}


	OUTPUT_PARENT_DIR=File.getParent(OUTPUT_DIR);
	
	print("OUTPUT_DIR: " + OUTPUT_DIR);
	print("OUTPUT_PARENT_DIR: " + OUTPUT_PARENT_DIR);
	

//*************** Processing  *************** 	

	// Loop on all .tif extensions
	for (n=0; n<ALL_EXT.length; n++) {
		if (ALL_EXT[n]==".tif") {
		
			// Get the file path
			FILE_PATH=INPUT_DIR+ALL_NAMES[n];
			
			// Store components of the file name
			FILE_NAME=File.getName(FILE_PATH);
			FILE_DIR = File.getParent(FILE_PATH);
			FILE_SEP = getFileExtension(FILE_NAME);
			FILE_SHORTNAME = FILE_SEP[0];
			FILE_EXT = FILE_SEP[1];
		
			print("");	
			print("INPUT_PATH:", FILE_PATH);
	//		print("FILE_NAME:", FILE_NAME);	
	//		print("FILE_DIR:", FILE_DIR);
	//		print("FILE_EXT:", FILE_EXT);
	//		print("FILE_SHORTNAME:", FILE_SHORTNAME);
		
			open(FILE_PATH);
			STACK_ID = getImageID();
			getDimensions(w, h, ch, sl, fr);

			if (ch > 1) {
				run("Split Channels");
				for(j = 0; j < ch; j++) {			
					// Construct window name (from the names created by the "Split Channels" command)
					TEMP_CHANNEL = d2s(j+1,0);
					SOURCE_WINDOW_NAME = "C" + TEMP_CHANNEL +  "-" + FILE_NAME;
					
					//Select source image
					selectWindow(SOURCE_WINDOW_NAME);
					inID = getImageID();
					resetMinAndMax;
	
					run("Kymo Colorize");
					outID = getImageID();
					selectImage(inID);
					close();
					rename(SOURCE_WINDOW_NAME);
				
					// Create output file path and save the output image
					OUTPUT_PATH = OUTPUT_DIR + FILE_SHORTNAME + "-C=" + j + ".tif";
					save(OUTPUT_PATH);
					print("OUTPUT_PATH: " + OUTPUT_PATH);
					close();				
				}
			}
			else {
					run("Kymo Colorize");
					outID = getImageID();
					selectImage(inID);
					close();
					rename(FILE_NAME);

					// Create output file path and save the output image
					OUTPUT_PATH = OUTPUT_DIR + FILE_SHORTNAME + ".tif";
					save(OUTPUT_PATH);
					print("OUTPUT_PATH: " + OUTPUT_PATH);
					close();
			}
			
					
		}// end of IF loop on tif extensions
	}// end of FOR loop on all files


	setBatchMode("exit and display");
	print("");
	print("*** Kymos Colorize Batch end ***");
	showStatus("Kymos Colorize Batch finished");
}


//*************** Functions ***************

function getFileExtension(Name) {
	nameparts = split(Name, ".");
	shortname = nameparts[0];
	if (nameparts.length > 2) {
		for (k = 1; k < nameparts.length - 1; k++) {
			shortname += "." + nameparts[k];
		}
	}
	extname = "." + nameparts[nameparts.length - 1];
	namearray = newArray(shortname, extname);
	return namearray;
}
