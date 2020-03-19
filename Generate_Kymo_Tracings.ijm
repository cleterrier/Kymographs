// Generate_Kymo_Tracings macro by Christophe Leterrier
// 19/11/13

macro "Generate Kymo Tracings" {


//	Get the folder name
	INPUT_DIR = getDirectory("Select the input stacks directory");
	print("\n\n\n*** Generate Kymo Tracings Log ***");
	print("INPUT_DIR :" + INPUT_DIR);

//	Get all file names
	ALL_NAMES = getFileList(INPUT_DIR);
	PARENT_DIR = File.getParent(INPUT_DIR);

//	Create the output folders

	OUTPUT_NAME = File.getName(INPUT_DIR);
	OUTPUT_SHORTA = split(OUTPUT_NAME, " ");
	OUTPUT_SHORT = OUTPUT_SHORTA[0];

	TRACING_DIR = PARENT_DIR + File.separator + OUTPUT_SHORT + " guide" + File.separator;
	if (File.isDirectory(TRACING_DIR) == false) {
		File.makeDirectory(TRACING_DIR);
	}
	print("TRACING_DIR: " + TRACING_DIR);

//	setBatchMode("true");

//	Loop on all .tif extensions
	for (n = 0; n < ALL_NAMES.length; n++) {

		FILE_NAME = ALL_NAMES[n];
		FILE_EXT = substring(FILE_NAME, lastIndexOf(FILE_NAME, "."), lengthOf(FILE_NAME));

		if (FILE_EXT == ".tif") {
//			Get the file path
			FILE_PATH = INPUT_DIR + FILE_NAME;
			// Store file name without extension and extension
			FILE_SHORTNAME = File.nameWithoutExtension;

			print("");
			print("INPUT_PATH:", FILE_PATH);
//			print("FILE_NAME:", FILE_NAME);
//			print("FILE_DIR:", INPUT_DIR);
//			print("FILE_SHORTNAME:", FILE_SHORTNAME);

			open(FILE_PATH);

			STACK_ID = getImageID();
			Stack.getDimensions(IM_W, IM_H, STACK_CH, STACK_SLICES, STACK_FRAMES);
			STACK_TITLE = getTitle();

			selectImage(STACK_ID);

			run("Z Project...", "projection=[Max Intensity]");
			MAX_ID = getImageID();
			selectImage(MAX_ID);
			MAX_TI = getTitle();

			run("8-bit");
			TRACING_PATH = TRACING_DIR + FILE_NAME;

			if (STACK_CH > 1) {
				MAX_TIS = substring(MAX_TI, 0, lastIndexOf(MAX_TI, "."));
				run("Stack to Images");
				for (ch = 0; ch < STACK_CH; ch++) {
					selectWindow(MAX_TIS + "-" + IJ.pad(ch + 1, 4));
					run("Grays");
					TRACING_CH = MAX_TIS + "-C=" + ch + ".tif";
					TRACING_CH = replace(TRACING_CH, "MAX_", "");
					TRACING_PATH = TRACING_DIR + TRACING_CH;
					save(TRACING_PATH);
					close;
					print("TRACING_PATH: " + TRACING_PATH);
				}
			}

			else {
				TRACING_PATH = TRACING_DIR + replace(FILE_NAME, ".tif", "-C=0.tif");
				save(TRACING_PATH);
				close();
				print("TRACING_PATH: " + TRACING_PATH);
			}

			selectImage(STACK_ID);
			close();


		}// end of IF loop on tif extensions
	}// end of FOR loop on all files

	setBatchMode("exit and display");

	print("");
	print("*** Generate Kymo Tracings end ***");
	showStatus("Generate Kymo Tracings finished");
}
