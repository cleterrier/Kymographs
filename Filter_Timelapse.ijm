// Filter_Timelapse macro by Christophe Leterrier
// 27/05/13
// 30/05/16
// 14/10/16 calls the Normalize_Movie.ijm macro
// 28/11/16 added options dialog

macro "Filter Timelapse" {

//	Save Settings
	saveSettings();

//	Default values for the Options Panel	

	SUBTRACT_DEF = false;
	BG_DEF = false;
	UM_DEF = false;
	NORM_DEF = false;
	NORM_SNR_DEF = 3; // SNR for the Normalize_Movie macro
	STABILIZE_DEF = true;

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
	Dialog.show();
	
//	Feeding variables from dialog choices
	SUBTRACT = Dialog.getCheckbox();
	BG = Dialog.getCheckbox();
	UM = Dialog.getCheckbox();
	NORM = Dialog.getCheckbox();
	NORM_SNR = Dialog.getNumber();
	STABILIZE = Dialog.getCheckbox();

//*********************************************		

//	Get all file names
	ALL_NAMES = getFileList(INPUT_DIR);
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
				
				/* 
				// Second method: Image Stabilizer
				run("Image Stabilizer", "transformation=Translation maximum_pyramid_levels=1 template_update_coefficient=0.90 maximum_iterations=200 error_tolerance=0.0000001");
				*/
				
				//Third method: SRRF
				Stack.setDisplayMode("composite");
				for (ch = 0; ch < STACK_CH; ch++) {
					resetMinAndMax;
				}	
				run("Stack to RGB", "frames");
				RGB_ID = getImageID();
				OUT_DRIFT = OUT_DIR + FILE_SHORTNAME + "_.njt";
				print(OUT_DRIFT);
				run("Estimate Drift", "time=5 max=10 apply choose=[" + OUT_DRIFT + "]");	
				run("Make Composite");
				selectImage(RGB_ID);
				close();
				Stack.setChannel(3);
				run("Delete Slice", "delete=channel");		

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