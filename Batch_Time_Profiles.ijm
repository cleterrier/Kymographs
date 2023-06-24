// Batch_Time_Profiles macro by Christophe Leterrier

macro "Batch Time Profiles" {

//	Save Settings
	saveSettings();

//	Default values for the Options Panel
	
	TINT_DEF = 1;
	FNUMBER_DEF = 200;
	ROIS_EXT = "_ROIs.zip";
	BL_FRAMES_DEF = 0;
	ALL_CHANNELS_DEF = false;
	RATIO_A_DEF = newArray("none", "first/second", "second/first");
	RATIO_DEF = "none";
	
/*
	SUBTRACT_DEF = false;
	BG_DEF = false;
	UM_DEF = false;
	NORM_DEF = false;
	NORM_SNR_DEF = 2; // SNR for the Normalize_Movie macro
	STABILIZE_DEF = true;
	FTIM_DEF = false;
	FINT_DEF = 1;
*/

//*************** Dialog 1 : get the input images folder path ***************

//	Get the folder name
	INPUT_DIR = getDirectory("Select the input stacks directory");
	print("\n\n\n*** Filter Timelapse Log ***");
	print("INPUT_DIR :" + INPUT_DIR);

//*************** Dialog 2 : options ***************

//	Creation of the dialog box
	
  	Dialog.create("Time Profiles Options");
	Dialog.addNumber("Frame interval:", TINT_DEF, 3, 5, "seconds");
	Dialog.addNumber("Total number of frames:", FNUMBER_DEF, 0, 3, "frames");
	Dialog.addNumber("Baseline over (0 for none):", BL_FRAMES_DEF, 0, 3, "first frames");
	Dialog.addCheckbox("Process both channels", ALL_CHANNELS_DEF);
	Dialog.addChoice("Calculate ratio", RATIO_A_DEF, RATIO_DEF);
	Dialog.show();

//	Feeding variables from dialog choices
	TINT = Dialog.getNumber();
	FNUMBER = Dialog.getNumber();
	BL_FRAMES = Dialog.getNumber();
	ALL_CHANNELS = Dialog.getCheckbox();
	RATIO = Dialog.getChoice();

//*********************************************

//	Get all file names
	ALL_NAMES = getFileList(INPUT_DIR);
	Array.sort(ALL_NAMES);
	PARENT_DIR = File.getParent(INPUT_DIR);

	// Prepare the Results table
	TAB_TITLE = "Profiles";
	//if (isOpen(TAB_TITLE)) Table.reset(TAB_TITLE);
	Table.create(TAB_TITLE);

	// Print X column
	for (k = 0; k < FNUMBER; k++) {
		Table.set("Time", k, k*TINT);
	}
	Table.update;


//	Loop on all .tif extensions
	for (n = 0; n < ALL_NAMES.length; n++) {

		FILE_NAME = ALL_NAMES[n];
		FILE_EXT = substring(FILE_NAME, lastIndexOf(FILE_NAME, "."), lengthOf(FILE_NAME));
		

		if (FILE_EXT == ".tif") {
//			Get the file path
			FILE_PATH = INPUT_DIR + FILE_NAME;

			print("");
			print("INPUT_PATH:", FILE_PATH);
//			print("FILE_NAME:", FILE_NAME);
//			print("FILE_DIR:", INPUT_DIR);
//			print("FILE_SHORTNAME:", FILE_SHORTNAME);

			open(FILE_PATH);
			// Store file name without extension and extension
			FILE_SHORTNAME = File.nameWithoutExtension;

			STACK_ID = getImageID();
			Stack.getDimensions(IM_W, IM_H, STACK_CH, STACK_SLICES, STACK_FRAMES);
			getPixelSize(pixelUnit, pixelWidth, pixelHeight);
			TIME_INT = Stack.getFrameInterval();
			Stack.getUnits(X, Y, Z, timeUnit, Value);
			STACK_TITLE = getTitle();

			// Open ROIset for this movie
			ROIS_NAME = FILE_SHORTNAME + ROIS_EXT;
			ROIS_PATH = INPUT_DIR + ROIS_NAME;
			print("ROIs_path: " + ROIS_PATH);
			ROINUMBER = roiManager("count");
			if (ROINUMBER >0) {
				roiManager("Deselect");
				roiManager("Delete");
			}
			roiManager("Open", ROIS_PATH);
			ROINUMBER = roiManager("count");

			for (i = 0; i < ROINUMBER; i++) {
				selectImage(STACK_ID);
				roiManager("select", i);
				imTitle = getTitle();		
				roiTitle = getInfo("selection.name");


				// Channels
				if (ALL_CHANNELS == true) {
					start = 1;
					stop = 2;
				}
				else {
					Stack.getPosition(start, slice, frame);
					stop = start;
				}
	
				for (ch = start; ch < stop + 1; ch++) {
					selectImage(STACK_ID);
					Stack.setChannel(ch);
					run("Plot Z-axis Profile");
					Plot.getValues(xpoints, ypoints);
					ProfileName = imTitle + "-" + roiTitle + "-ch" + ch;
					rename(ProfileName);
	
					if (BL_FRAMES > 0) {
						BL_SUM = 0;
						for (f = 0; f < BL_FRAMES; f++) {
							BL_SUM += ypoints[f];
						}
						BL_AV = BL_SUM / BL_FRAMES;
						for (f = 0; f < ypoints.length; f++) {
							ypoints[f] = ypoints[f] - BL_AV;
						}
					}
	
					for (t = 0; t < minOf(FNUMBER, ypoints.length); t++) {
						Table.set(ProfileName, t, ypoints[t]);
					}
					if (ypoints.length < FNUMBER) {
						for (t = ypoints.length; t < FNUMBER; t++) {
							Table.set(ProfileName, t, NaN);
						}				
					}
				}
				
				if (RATIO != "none") {
					for (t = 0; t < minOf(FNUMBER, ypoints.length); t++) {
						ch1Name = imTitle + "-" + roiTitle + "-ch1";
						ch2Name = imTitle + "-" + roiTitle + "-ch2";
						val1 = Table.get(ch1Name, t);
						val2 = Table.get(ch2Name, t);
						if (RATIO == "first/second") valr = val1/val2;
						else valr = val2/val1;
						colName = imTitle + "-" + roiTitle + "-ratio";					
						Table.set(colName, t, valr);
					}
					if (ypoints.length < FNUMBER) {
						for (t = ypoints.length; t < FNUMBER; t++) {
							Table.set(colName, t, NaN);
						}				
					}
						
				}
				
			}
			Table.update;		
			
			selectImage(STACK_ID);
			close();
			
		}// end of IF loop on tif extensions
	}// end of FOR loop on all files

	run("Images to Stack", "name=[Profiles Stack] use");
	rename("Profiles");

	if (ROINUMBER >0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
	
	print("");
	print("*** Time Profiles end ***");
	showStatus("Time Profiles finished");
}
