macro "Straight Correlation" {
	
	MACRO_NAME = "Make Staight Correlations";
	FOLDER_NAME = "straight";
	
	WIDTH_DEF = 30; // width of line profile in pixels
	CHAN_DEF = 0;
	
	setFont("Arial", 12, "regular, antialised, black");

	// Parameters of the correlation plugin
	LOCAL = 3 // local region for correlation in pixels	
	CURVE_TITLE = "Correlation curve";
	TABLE_TITLE = "Increasing interval.Image correlation. Local region size = " + LOCAL + " pixels";
	print("***** " + MACRO_NAME + " started *****");
	
	
	// Get input stack title and ID
	STACK_TITLE = getTitle();
	STACK_ID = getImageID();

	// Get the timelapse files folder
	TL_DIR = getDir("Please select the timelapse files folder");
	print("Timelapse files folder: " + TL_DIR);

	// Dialog for measurements option
	Dialog.create(MACRO_NAME + " Options");
	Dialog.addNumber("Line width (0 for keeping line ROI width)", WIDTH_DEF, 0, 4, "px");
	Dialog.addNumber("Channel to process", CHAN_DEF, 0, 4, "");
	Dialog.show();
	WIDTH = Dialog.getNumber();
	CHAN = Dialog.getNumber();
	
	// Get the ROI number in the ROI manager
	ROI_NUMBER = roiManager("count");
	
	// Make stack for correlation curves
	newImage(STACK_TITLE + "--Correlation curves", "8-bit black", 483, 357, ROI_NUMBER);
	CURVESTACK_TITLE = getTitle();
	CURVESTACK_ID = getImageID();	
	
	// Create summary table for correlation values
	SUMTABLE_TITLE = STACK_TITLE + "--Correlations"
	Table.create(SUMTABLE_TITLE);
	
	// Generate the output folder to save straightened timelapses
	PARENT_DIR = File.getParent(TL_DIR);
	OUTPUT_NAME = File.getName(TL_DIR);
	// OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
	// OUTPUT_SHORT = OUTPUT_SHORTA[0];
	OUTPUT_DIR = PARENT_DIR + File.separator + OUTPUT_NAME + " " + FOLDER_NAME + " W" + WIDTH+ File.separator;
	if (File.isDirectory(OUTPUT_DIR) == false) {
		File.makeDirectory(OUTPUT_DIR);
	}
	print("Output folder for straightened timelapses: " + OUTPUT_DIR);
	print("");
	
	
	// Loop on ROIs in the ROI manager
	for (i = 0; i < ROI_NUMBER; i++) {
		
		print("   processing ROI #" + (i+1) + "/" + ROI_NUMBER);
		selectImage(STACK_ID);
		
		// Select the ROI in the ROI manager
		roiManager("select", i);
		
		// Get image title, slice number and ROI name
		IM_TITLE = getInfo("slice.label");
		IM_TITLE = replace(IM_TITLE, "-C=.", "");
		if (indexOf(IM_TITLE, ".tif")<0) IM_TITLE = IM_TITLE + ".tif";
		
		IM_NUMBER = getSliceNumber();		
		ROI_TITLE = getInfo("selection.name");
		
		print("      ROI name: " + ROI_TITLE);
		print("      image name: " + IM_TITLE);	
		
		// Get ROI stroke width or use the the dialog width for all ROIs
		if (WIDTH == 0) ROI_WIDTH = Roi.getStrokeWidth();
		else ROI_WIDTH = WIDTH;	
		
		// Build timelapse file name
		TL_PATH = TL_DIR + IM_TITLE;
		
		// Open timelapse file, if it's not the same as the previous one
		if (isOpen(IM_TITLE) == false && i>0) {
			print("      opening timelapse file: " + TL_PATH);	
			selectImage(TL_ID);
			close();
			open(TL_PATH);
			IN_ID = getImageID();
			Stack.getDimensions(width, height, channels, slices, frames);
			if (channels > 1){
				run("Duplicate...", "duplicate channels=" + (CHAN+1));
				selectImage(IN_ID);
				close();
			}
			TL_ID = getImageID();
		}
		
		else if (i>0) {
			selectImage(TL_ID);
			print("      re-using timelapse file: " + TL_PATH);
		}
		
		else {
			print("      opening timelapse file: " + TL_PATH);
			open(TL_PATH);
			IN_ID = getImageID();
			Stack.getDimensions(width, height, channels, slices, frames);
			if (channels > 1){
				run("Duplicate...", "duplicate channels=" + (CHAN+1));
				selectImage(IN_ID);
				close();
			}
			TL_ID = getImageID();
		}
		
		// Restore ROI on the timelapse first frame
		run("Restore Selection");
		
		// Build straightened timelapse title
		STRAIGHT_TITLE = IM_TITLE + "--" + ROI_TITLE;
		
		// Generate straightened timelapse
		run("Fit Spline");
		run("Straighten...", "title=" + STRAIGHT_TITLE + " line=" + ROI_WIDTH + " process");
		STRAIGHT_ID = getImageID();
		
		// Save straightened timelpase
		STRAIGHT_PATH = OUTPUT_DIR + STRAIGHT_TITLE + "-C=" + CHAN + ".tif";
		save(STRAIGHT_PATH);
		print("      saved straightened timelapse: " + STRAIGHT_PATH);
		
		// calculate correlation
		print("      calculating correlation curve..");
		run("Image CorrelationJ 1o", "target=" + STRAIGHT_TITLE + " source=" + STRAIGHT_TITLE + " correlation=[Increasing sequence] statistic=Average markers=Circle local=" + LOCAL + " decimal=4");
		
		selectImage(STRAIGHT_ID);
		close();
		
		selectWindow(CURVE_TITLE);
		run("Select All");
		run("Copy");
		close();
		
		selectImage(CURVESTACK_ID);
		setSlice(i+1);
		run("Paste");
		
		drawString("image: " + IM_TITLE, 75, 40);
		drawString("ROI: " + ROI_TITLE, 75, 60);
		Property.setSliceLabel(STRAIGHT_TITLE);
		
		
		// Copy correlation values into summary table
		
		
		// Workaround so that the output of the correlation plugin is recognized as a Table
		// (save it, colse it and re-open it as a table)
		selectWindow(TABLE_TITLE);
		SAVE_PATH = PARENT_DIR + File.separator + "corrtable.txt";
		save(SAVE_PATH);
		run("Close");
		Table.open(SAVE_PATH);
		
		// Copy intervals to summary table only for first ROI
		if (i == 0) {
			selectWindow("corrtable.txt");
			icol = Table.getColumn("Intervals");
			selectWindow(SUMTABLE_TITLE);
			Table.setColumn("Intervals", icol) 
		}
		
		// Copy correlation values
		selectWindow("corrtable.txt");
		col = Table.getColumn("Average");
		selectWindow(SUMTABLE_TITLE);
		Table.setColumn(STRAIGHT_TITLE, col);

		// Close single correlation table
		selectWindow("corrtable.txt");
		run("Close");			
	}
	
	print("");
	
	// close last timelapse
	selectImage(TL_ID);
	close();
	
	// Save correlation curves stack
	selectImage(CURVESTACK_ID);
	run("Select None");
	save(PARENT_DIR + File.separator + STACK_TITLE + "--Correlation curves.tif");
	print("      saved stack of correlation curves: " + PARENT_DIR + File.separator + STACK_TITLE + "--Correlation curves.tif");
	
	
	// Save summary table of correlation values
	selectWindow(SUMTABLE_TITLE);
	Table.save(PARENT_DIR + File.separator + SUMTABLE_TITLE + ".xls");
	print("      saved summary table of correlation values: " + PARENT_DIR + File.separator + STACK_TITLE + "--Correlation curves.tif");
	print("");
	print("***** " + MACRO_NAME + " finished *****");

}



