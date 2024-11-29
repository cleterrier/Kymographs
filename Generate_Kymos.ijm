// 13/06/13
// 30/05/16
// You will need the KymoResliceWide plugin from Eugene Katrukha
// https://github.com/ekatrukha/KymoResliceWide

macro "Generate Kymos" {

	K_WIDTH_DEF = 17;
	ENH_DEF = 0.001;
	TRACE_FOLDER_KEY = " guide";
	MOVIES_FOLDER_KEY = " filt";
	OUT_KEY = " kymo";
	NCH_DEF = 2;

	// Get the folder name 
	INPUT_DIR = getDirectory("Select the movies folder");
	print("\n\n\n*** Generate Kymos Log ***");
	print("INPUT_DIR :" + INPUT_DIR);

	INPUT_DIRNAME = File.getName(INPUT_DIR);
	INPUT_DIRPARENT = File.getParent(INPUT_DIR);
	INPUT_SHORTA = split(INPUT_DIRNAME, " ");
	INPUT_SHORT = INPUT_SHORTA[0];
	print("INPUT_DIRNAME :" + INPUT_DIRNAME);
	print("INPUT_DIRPARENT :" + INPUT_DIRPARENT);

	// Get Options
	
	Dialog.create("Generate Kymos Options");
	Dialog.addNumber("Number of Channels", NCH_DEF);
	Dialog.addNumber("Tracing width for kymograph", K_WIDTH_DEF);
	Dialog.addNumber("Enhance Contrast (0 for none)", ENH_DEF);
	Dialog.show();
	
	NCH = Dialog.getNumber();
	K_WIDTH = Dialog.getNumber();
	ENH = Dialog.getNumber();

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

	if (NCH== 1) run("Convert ndf to ROI", "select=[" + TRACES_DIR+ "] line=5 channel=1 keep=1");
	else run("Convert ndf to ROI", "select=[" + TRACES_DIR + "] line=5 channel=" + NCH + " single keep=1");

	rename(INPUT_SHORT + " Traces");
	TRACES_STACK = getImageID();

//	setBatchMode(true);

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
			MOVNAME = replace(SLICENAME, "-C=.", "");
			if (indexOf(MOVNAME, ".tif")<0) MOVNAME = MOVNAME + ".tif";
			print("r=" + r + " MOVNAME=" + MOVNAME);
			MOV_DIR = INPUT_DIRPARENT + File.separator + INPUT_SHORT + MOVIES_FOLDER_KEY + File.separator;
			open(MOV_DIR + MOVNAME);
			MOV_ID = getImageID();
			// Store movie scale
			
			getPixelSize(mun, mpw, mph);
			if (mun == "microns") mun = "um";
			mfi = Stack.getFrameInterval();
			// Remove scale from movie (for KymoResliceWide to work correctly)
			run("Set Scale...", "distance=0 known=0 unit=pixels");
			
			Stack.getDimensions(mwi, mhe, mch, msl, mfr);
			if (mch > 1) {
				for (c= 0; c < mch; c++) {
					Stack.setChannel(c+1);
					resetMinAndMax();
				}
			}
			else {
				resetMinAndMax();
			}
		}
		selectImage(MOV_ID);
		roiManager("select", r);
		roiManager("Set Line Width", K_WIDTH);
		// run("Reslice [/]...", "output=1.000 start=Top avoid");
		run("KymoResliceWide ", "intensity=Maximum");
		Stack.getDimensions(kwi, khe, kch, ksl, kfr); 
		
		if (ENH > 0) {
			if (kch > 1) {
				for (c= 0; c < kch; c++) {
					Stack.setChannel(c+1);
					resetMinAndMax();
					run("Enhance Contrast...", "saturated=" + ENH);
					run("Apply LUT");
				}
			}
			else {
				resetMinAndMax();
				run("Enhance Contrast...", "saturated=" + ENH);
				run("Apply LUT");
			}
		}
		
		outName = "Kymo_(" + MOVNAME + ")_roi" + IJ.pad(r+1,3) + "_[" + ROINAME_R + "]_" + mpw + mun + "," + mfi + "s";
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