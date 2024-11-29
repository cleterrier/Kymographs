macro "Stack_Kymos" {

//*************** Initialization ***************

	// Get the folder name
	INPUT_DIR=getDirectory("Select the input stacks directory");

	INPUT_NAME = File.getName(INPUT_DIR);
	PARENT_DIR = File.getParent(INPUT_DIR);
	PARENT_NAME = File.getName(INPUT_DIR);

	print("\n\n\n*** Stack Kymos Log ***");
	print("");
	print("INPUT_DIR: " + INPUT_DIR);
	print("INPUT_NAME: " + INPUT_NAME);
	print("PARENT_DIR: " + PARENT_DIR);
	print("PARENT_NAME: " + PARENT_NAME);

	// Get all file names
	ALL_NAMES=getFileList(INPUT_DIR);
	N_LENGTH = ALL_NAMES.length;
	ALL_EXT=newArray(N_LENGTH);
	// Create extensions array
	for (i = 0; i < N_LENGTH; i++) {
	//	print(ALL_NAMES[i]);
		ALL_NAMES_PARTS = getFileExtension(ALL_NAMES[i]);
		ALL_EXT[i] = ALL_NAMES_PARTS[1];
	}


	setBatchMode(true);
	IMcount = 0;
	IMlast = 0;

//*************** Processing  ***************

	// Loop on all .tif extensions
	for (n=0; n<N_LENGTH; n++) {
		if (ALL_EXT[n]==".tif") {

			// Increment image counter
			IMcount++;

			// Get the file path
			FILE_PATH = INPUT_DIR + ALL_NAMES[n];

			// Store components of the file name
			FILE_NAME = File.getName(FILE_PATH);
			FILE_DIR = File.getParent(FILE_PATH);
			FILE_SEP = getFileExtension(FILE_NAME);
			FILE_SHORTNAME = FILE_SEP[0];
			FILE_EXT = FILE_SEP[1];

			print("");
			print("INPUT_PATH: " + FILE_PATH);
			print("FILE_NAME: " + FILE_NAME);
			print("FILE_DIR: " + FILE_DIR);
			print("FILE_EXT: " + FILE_EXT);
			print("FILE_SHORTNAME: " + FILE_SHORTNAME);

			open(FILE_PATH);
			inID = getImageID();
			label = getTitle();

			// create hyperstack
			if (IMcount == 1) {
				Stack.getDimensions(inW, inH, inC, inS, inF);
				getVoxelSize(inPx, inPy, inPz, inPunit);
				inB = bitDepth();
				run("New HyperStack...", "title=" + INPUT_NAME + " type=" + inB + "-bit width=" + inW + " height=" + inH + " channels=" + inC + " slices=" + inS + " frames=" + inF);
				hsID = getImageID();
				Stack.getDimensions(currW, currH, currC, currS, currF);
				setVoxelSize(inPx, inPy, inPz, inPunit);
			}

			// get new image, turn it to hyperstack
			selectImage(inID);
			run("Stack to Hyperstack...", "order=xyczt(default) display=Composite");
			inID = getImageID();
			Stack.getDimensions(newW, newH, newC, newS, newF);
			getPixelSize(newPunit, newPx, newPy);
			if (newPy != inPy) {
				scaleY = newPy/inPy;
				print(scaleY);
				scaleH = round(newH * scaleY);
				run("Scale...", "x=1.0 y=" + scaleY + " z=1.0 width=" + newW + " height=" + scaleH + " depth=2 interpolation=Bicubic average create");
				run("Unsharp Mask...", "radius=1 mask=0.30");
				Stack.getDimensions(newW, newH, newC, newS, newF);
				selectImage(inID);
				close();
				inID = getImageID();
			}
			if (IMcount >1) {

				// resize hyperstack if new image is bigger
				selectImage(hsID);
				Stack.getDimensions(currW, currH, currC, currS, currF);
				if (newW > currW || newH > currH) {
					run("Canvas Size...", "width=" + maxOf(newW, currW) + " height=" + maxOf(newH, currH) + " position=Top-Left zero");
				}

				// add one slice to hyperstack
				selectImage(hsID);
				run("Add Slice", "add=slice");
				currS = currS + 1;
			}

			// copy each channel in new slice
			for (c = 0; c < newC; c++) {

				selectImage(inID);
				Stack.setPosition(c + 1, newS, newF);
				run("Select All");
				run("Copy");

				selectImage(hsID);
				Stack.setPosition(c + 1, currS, currF);
				setMetadata("Label", label + "-C=" + c);
				makeRectangle(0, 0, newW, newH);
				run("Paste");
				resetMinAndMax();
				run("Select None");
			}

			// close image
			selectImage(inID);
			close();

		}// end of IF loop on tif extensions
	}// end of FOR loop on all files

	Stack.setDisplayMode("composite");

	// Create output file path and save the output hyperstack
	OUTPUT_PATH = PARENT_DIR + File.separator + INPUT_NAME + ".tif";
	save(OUTPUT_PATH);
	print("OUTPUT_PATH: " + OUTPUT_PATH);


	setBatchMode("exit and display");

	print("");
	print("*** Stack_Kymos end ***");
	showStatus("Stack Kymos finished");
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
