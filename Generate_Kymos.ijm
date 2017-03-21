// 13/06/13
// 30/05/16

macro "Generate Kymos" {

	K_WIDTH = 17;
	TRACE_FOLDER_KEY = " guide";
	MOVIES_FOLDER_KEY = " filt";
	OUT_KEY = " kymo";

	// Get the folder name 
	INPUT_DIR = getDirectory("Select the raw movies folder");
	print("\n\n\n*** Generate Kymos Log ***");
	print("INPUT_DIR :" + INPUT_DIR);

	INPUT_DIRNAME = File.getName(INPUT_DIR);
	INPUT_DIRPARENT = File.getParent(INPUT_DIR);
	INPUT_SHORTA = split(INPUT_DIRNAME, " ");
	INPUT_SHORT = INPUT_SHORTA[0];
	print("INPUT_DIRNAME :" + INPUT_DIRNAME);
	print("INPUT_DIRPARENT :" + INPUT_DIRPARENT);

	// Create Output Folder
	OUTPUT_DIRNAME =  INPUT_SHORT + OUT_KEY;
	OUTPUT_DIR = INPUT_DIRPARENT + File.separator + OUTPUT_DIRNAME + File.separator;
	if (File.isDirectory(OUTPUT_DIR) == false) {
		File.makeDirectory(OUTPUT_DIR);
	}
	print("OUTPUT_DIRNAME :" + OUTPUT_DIRNAME);
	
	// Clear Roi Manager
	roiManager("Reset");

	// Run NDF to ROI
	TRACES_DIR = INPUT_DIRPARENT + File.separator + INPUT_SHORT + TRACE_FOLDER_KEY + File.separator;
	run("Convert ndf to ROI", "select=[" + TRACES_DIR+ "] line=5 channel=1 keep=1");

//  for multiCh run("Convert ndf to ROI", "select=[/Users/christo/Travail/Data Live/test/100X trac] line=1 channel=2 single keep=1");

	rename(INPUT_SHORT + " Traces");
	TRACES_STACK = getImageID();

	setBatchMode(true);

	for (r = 0; r < roiManager("count"); r++) {
		selectImage(TRACES_STACK);
		roiManager("deselect");
		roiManager("select", r);
		if (r == 0) rp = 0;
		else rp = r-1;
		
		ROINAME_RP = call("ij.plugin.frame.RoiManager.getName", rp);
		ROINAME_R = call("ij.plugin.frame.RoiManager.getName", r);
		ROINAME_RP_ARRAY = split(ROINAME_RP, "-");
		ROINAME_R_ARRAY = split(ROINAME_R, "-");
		
		if (r == 0 || ROINAME_R_ARRAY[0] != ROINAME_RP_ARRAY[0]) {
			if (r != 0) {
				selectImage(MOV_ID);
				close(); 
			}
			selectImage(TRACES_STACK);
			SLICENAME = getInfo("slice.label");
			MOVNAME = substring(SLICENAME, 0, lengthOf(SLICENAME)-4) + ".tif";
			print("r=" + r + " MOVNAME=" + MOVNAME);
			MOV_DIR = INPUT_DIRPARENT + File.separator + INPUT_SHORT + MOVIES_FOLDER_KEY + File.separator;
			open(MOV_DIR + MOVNAME);
			MOV_ID = getImageID();
		}
		selectImage(MOV_ID);
		roiManager("select", r);
		roiManager("Set Line Width", K_WIDTH);
		// run("Reslice [/]...", "output=1.000 start=Top avoid");
		run("KymoResliceWide ", "intensity=Maximum");
		run("Enhance Contrast...", "saturated=0.05 normalize");
		outName = "Kymo_(" + MOVNAME + ")_roi" + IJ.pad(r,3) + "_[" + ROINAME_R + "]";
		rename(outName);
		save (OUTPUT_DIR + outName + ".tif");
		close();

	}
	selectImage(MOV_ID);
	close(); 
	setBatchMode("exit and display");
	close(); 
	print("\n*** Generate Kymos end ***");
	// run("Images to Stack", "method=[Copy (top-left)] name=[Kymos " + INPUT_DIRNAME + "] title=Kymo use");
	

}