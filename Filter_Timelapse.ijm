// Filter_Timelapse macro by Christophe Leterrier
// 27/05/13
// 30/05/16
// 14/10/16 calls the Normalize_Movie.ijm macro
// 28/11/16 added options dialog
// 06/06/18 revert to Stabilizer

macro "Filter Timelapse" {

//	Save Settings
	saveSettings();

//	Default values for the Options Panel

	SUBTRACT_DEF = false;
	BG_DEF = false;
	UM_DEF = false;
	NORM_DEF = false;
	NORM_SNR_DEF = 2; // SNR for the Normalize_Movie macro
	STABILIZE_DEF = true;
	FTIM_DEF = false;
	FINT_DEF = 1;

//*************** Dialog 1 : get the input images folder path ***************

//	Get the folder name
	INPUT_DIR = getDirectory("Select the input stacks directory");
	print("\n\n\n*** Filter Timelapse Log ***");
	print("INPUT_DIR :" + INPUT_DIR);

//*************** Dialog 2 : options ***************

//	Creation of the dialog box
	Dialog.create("Filter Timelapse Options");
	Dialog.addCheckbox("Running subtraction", SUBTRACT_DEF);
	Dialog.addCheckbox("Subtract background", BG_DEF);
	Dialog.addCheckbox("Unsharp Mask", UM_DEF);
	Dialog.addCheckbox("Normalize Intensity", NORM_DEF);
	Dialog.addNumber("Normalize SNR", NORM_SNR_DEF);
	Dialog.addCheckbox("Stabilize", STABILIZE_DEF);
	Dialog.addCheckbox("Force time interval", FTIM_DEF);
	Dialog.addNumber("Interval", FINT_DEF, 5, 3, "sec");
	Dialog.show();

//	Feeding variables from dialog choices
	SUBTRACT = Dialog.getCheckbox();
	BG = Dialog.getCheckbox();
	UM = Dialog.getCheckbox();
	NORM = Dialog.getCheckbox();
	NORM_SNR = Dialog.getNumber();
	STABILIZE = Dialog.getCheckbox();
	FTIM = Dialog.getCheckbox();
	FINT = Dialog.getNumber();

//*********************************************

//	Get all file names
	ALL_NAMES = getFileList(INPUT_DIR);
	Array.sort(ALL_NAMES);
	PARENT_DIR = File.getParent(INPUT_DIR);

	if (STABILIZE == false) setBatchMode(true);

//	Create the output folders
	OUTPUT_NAME = File.getName(INPUT_DIR);
	OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
	OUTPUT_SHORT = OUTPUT_SHORTA[0];

	OUT_KEY = " filt";
	if (SUBTRACT == true) OUT_KEY += " sub";

	OUT_DIR = PARENT_DIR + File.separator + OUTPUT_SHORT + OUT_KEY + File.separator;
		if (File.isDirectory(OUT_DIR) == false) {
			File.makeDirectory(OUT_DIR);
			}
	print("OUT_DIR: " + OUT_DIR);

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

			if (SUBTRACT == true) {
				selectImage(STACK_ID);
				run("Z Project...", "projection=[Average Intensity]");
				AV_ID = getImageID();
				AV_TI = getTitle();

				AVS_ID = Pad_Stack(AV_ID, STACK_FRAMES);
				imageCalculator("Subtract stack", STACK_TITLE, "Padded");
				run("Enhance Contrast...", "saturated=0.01 normalize process_all");

				selectImage(AVS_ID);
//				rename(STACK_TITLE + "_Padded");
				close();

				selectImage(AV_ID);
				close();

			}

			if (BG == true) {
				selectImage(STACK_ID);
				run("Subtract Background...", "rolling=" + floor(IM_W / 10) + " sliding stack");
			}

			if (UM == true) {
				selectImage(STACK_ID);
				run("Unsharp Mask...", "radius=1 mask=0.30 stack");
			}

			if (NORM == true) {
				for (ch = 0; ch < STACK_CH; ch++) {
					if (STACK_CH > 1) Stack.setChannel(ch + 1);
					run("Enhance Contrast...", "saturated=0.001");
				}
				run("Normalize Movie", "threshold=" + NORM_SNR + " initial=10");
				resetMinAndMax;

				rename(STACK_TITLE);
				STACK_ID = getImageID();
				
			}

			if (STABILIZE == true) {
				selectImage(STACK_ID);

				/*
				//First method: Stack Reg
				Stack.setDisplayMode("composite");
				for (ch = 0; ch < STACK_CH; ch++) {
					resetMinAndMax;
				}
				run("Stack to RGB", "frames");
				run("StackReg", "transformation=Translation");
				run("Make Composite");
				Stack.setChannel(3);
				run("Delete Slice", "delete=channel");
				*/

				//Second method: SRRF
				/*
				for (ch = 0; ch < STACK_CH; ch++) {
					setMinAndMax(0, 65535);
				}
				if (STACK_CH > 1) {
					Stack.setDisplayMode("composite");
					run("Stack to RGB", "frames");
					RGB_ID = getImageID();
					OUT_DRIFT = OUT_DIR + FILE_SHORTNAME + "_.njt";
					//print(OUT_DRIFT);
					run("Estimate Drift", "time=10 max=10 apply choose=[" + OUT_DRIFT + "]");
					run("Make Composite");
					selectImage(RGB_ID);
					close();
					Stack.setChannel(3);
					run("Delete Slice", "delete=channel");
					Stack.getDimensions(currW, currH, currC, currS, currF);
					run("Stack to Hyperstack...", "order=xyczt(default) channels=" + currC + " slices=" + currF + " frames=" + currS + " display=Composite");
				}
				else {
					OUT_DRIFT = OUT_DIR + FILE_SHORTNAME + "_.njt";
					//print(OUT_DRIFT);
					run("Estimate Drift", "time=10 max=10 apply choose=[" + OUT_DRIFT + "]");
					//selectImage(STACK_ID);
					close();
				}
				*/
				

				// Third method: Image Stabilizer
				
				// reset contrast to project alll channels together for better drift correction
				for (ch = 0; ch < STACK_CH; ch++) {
					setMinAndMax(0, 65535);
				}

				// IN the case of multi-channel
				if (STACK_CH > 1) {

					// duplicate input stack
					run("Duplicate...", "duplicate");		
					DUP_TITLE = getTitle();
					DUP_ID = getImageID();

					// switch channels into Z slices to project channels
					Stack.setDisplayMode("grayscale");
					run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
					DUP_ID = getImageID();
					run("Z Project...", "projection=[Max Intensity] all");
					resetMinAndMax();
					PROJ_ID = getImageID();
					PROJ_TITLE = getTitle();

					//Run Image Stabilizer on the projected channels, logging the coeeficients 
					run("Image Stabilizer", "transformation=Translation maximum_pyramid_levels=1 template_update_coefficient=0.90 maximum_iterations=200 error_tolerance=0.0000001 log_transformation_coefficients");
					// Build the log window title
					LOG_TITLE = replace(PROJ_TITLE, ".tif", ".log");
					if (LOG_TITLE == PROJ_TITLE) LOG_TITLE = PROJ_TITLE + ".log";


					// Close switched stack
					selectImage(DUP_ID);
					close();

					// Close projected channels (we only need the logged drift coefficients)
					selectImage(PROJ_ID);
					close();

					// Go back to input stack
					selectImage(STACK_ID);

					// SPlit channels
					run("Split Channels");

					// Loop on channels to apply drift coefficients 
					CH_TITLES = newArray(STACK_CH);
					CH_STRING = "";
					for (chan = 0; chan < STACK_CH; chan++) {
						// Build the split channel window title
						CH_TITLES[chan] = "C" + (chan + 1) + "-" + STACK_TITLE;
						// Build the string that will be used to merge back the channels afterwards
						CH_STRING = CH_STRING + "c" + (chan + 1) + "=" + CH_TITLES[chan] + " ";

						// Stabilize the channel using the logged drift coefficients
						selectWindow (CH_TITLES[chan]);					
						run("Image Stabilizer Log Applier", " ");
						resetMinAndMax();
					}
					
					// Merge back the channels into the source hyperstack, update title and ID
					run("Merge Channels...", CH_STRING + "create ignore");
					rename(STACK_TITLE);
					STACK_ID = getImageID();
					
					// Close the drfit coefficients log window
					selectWindow(LOG_TITLE);
					run("Close");			
				}
				else {
					run("Image Stabilizer", "transformation=Translation maximum_pyramid_levels=1 template_update_coefficient=0.90 maximum_iterations=200 error_tolerance=0.0000001");
				}

			if (FTIM == true){
				setVoxelSize(pixelWidth, pixelHeight, FINT, pixelUnit);
				Stack.setFrameInterval(FINT);
				Stack.setTUnit(timeUnit);
			}
			else {
				setVoxelSize(pixelWidth, pixelHeight, TIME_INT, pixelUnit);
				Stack.setFrameInterval(TIME_INT);
				Stack.setTUnit(timeUnit);
			}


			OUT_PATH = OUT_DIR + FILE_NAME;
			save(OUT_PATH);
			close();
			print("OUT_PATH: " + OUT_PATH);

		}// end of IF loop on tif extensions
	}// end of FOR loop on all files

	print("");
	print("*** Filter Timelapse end ***");
	showStatus("Filter Timelapse finished");
}

function Pad_Stack(ID, n) {

	selectImage(ID);
	// Retrieves parameters of the input image
	Image_Title=getTitle();
	Image_Bit=bitDepth();
	getDimensions(Image_Width, Image_Height, channels, slices, frames);

	// Creates the output stack
	newImage("Padded", Image_Bit, Image_Width, Image_Height, channels, slices, n);
	AvStack_ID=getImageID();


	for (c = 0; c < channels; c++) {

		// Select inpput images and channel
		selectImage(ID);
		if (channels > 1) Stack.setChannel(c + 1);

		// Copy input slice
		run("Select All");
		run("Select None");
		run("Copy");

		// Select output stack
		selectImage(AvStack_ID);
		if (channels > 1) Stack.setChannel(c + 1);

		// Loops on all output stack slices and paste the input image on each slice
		for (i = 0; i < n; i++) {
			selectImage(AvStack_ID);
			if (channels > 1) Stack.setChannel(c + 1);
			Stack.setFrame(i + 1);
			run("Paste");
		}

		run("Select None");
		// Set the display contrast
		resetMinAndMax;

	}

	return AvStack_ID;

}
