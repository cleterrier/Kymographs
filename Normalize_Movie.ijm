// Normalize Movie macro by Christophe Leterrier
// 02/10/2011
// Normalizes the intensity of an image sequence, typically a time-lapse movie
// Corrects for illumination variations and photobleaching
// Beware that intensity values are modified, do not use for intensity measurements
// • detects what is the "object" on the images (based on thresholding the average projection of the movie)
// • normalizes the mean intensity of the "object" across frames to a reference intensity, calculated from an average of the first frames 
// Can be called from another macro as runMacro(path to Normalize_Movie.ijm, args) et args [strings] = [Stack ID, SNR, Initial Average]

macro "Normalize_Movie" {

//	Detect if called from macro
	arg = getArgument();
	if (lengthOf(arg)>0) {
		called = true;
		argarray = split(arg, ",");
		Stack_ID = argarry[0];
		SNR = argarrya[1];
		Initial_Average = argarray[2];
	}
	else {
		called = false;

//		Default values		
		SNR_DEF = 2; //	Threshold for S/N ratio (to select the "object" ROI)
		In_Av_DEF = 3; //	Number of initial slices used to determine the target reference intensity
	
//		Dialog
		Dialog.create("Normalize Movie: options");
		Dialog.addNumber("Threshold SNR", SNR_DEF, 2, 4, "");
		Dialog.addNumber("Initial frames for average", In_Av_DEF, 0, 4, "");
		Dialog.show();
		SNR = Dialog.getNumber();
		In_Av = Dialog.getNumber();
	}

	setBatchMode(true);

//	Retrieve parameters of the input stack
	Stack_Title = getTitle();
	Stack_ID = getImageID();
	Stack.getDimensions(width, height, channels, slices, frames);
	
//	Projects the stack to use as source for object detection
	run("Z Project...", "projection=[Average Intensity]");
	Proj_ID = getImageID();

	for (c = 0; c < channels; c++) {	
//	Threshold the projection to define the "object" ROI
//		Mode of the projected stack = background
		selectImage(Proj_ID);
		if (channels > 1) Stack.setChannel(c + 1);
		Image_Mode = getMode();
//		Defines lower threshold limit as preset S/N ratio * background
		Low_Thresh = SNR * Image_Mode;
//		Defines higher threshold (255 or 65535 depending on bit depth)
		High_Thresh = pow(2, bitDepth()) - 1;
		setThreshold(Low_Thresh, High_Thresh);
		run("Create Selection");

//		Restore object ROI on input stack
		selectImage(Stack_ID);
		if (channels > 1) Stack.setChannel(c + 1);
		Stack.setFrame(1);
		run("Restore Selection");
	
//		Loop through n (specified) first slices to calculate the target reference intensity
		Ref_Intensity = 0;
		for (i = 0; i < In_Av; i++) {
			Stack.setFrame(i + 1);
			getStatistics(area, ROI_Mean, min, max, std, histogram);
			Ref_Intensity = Ref_Intensity + ROI_Mean;
		}
		Ref_Intensity = Ref_Intensity / In_Av;
	
//		Loop through alls slices and multiply each slice to bring the object ROI mean intensity to reference intensity
		for (i = 0; i < frames; i++) {
			Stack.setFrame(i+1);
			run("Restore Selection");
			getStatistics(area, ROI_Mean, min, max, std, histogram);
			Intensity_Correction = Ref_Intensity / ROI_Mean;
			run("Select None");
			run("Multiply...", "slice value=" + Intensity_Correction); 
		}

	}
	
	selectImage(Proj_ID);
	close();
	setBatchMode("exit and display");
	showStatus("Normalize_Movie finished");
}


function getMode() {
	// Return the mode (intensity value taken by the highest number of pixels in the image) 
	getHistogram(Val, Histo, pow(2,bitDepth()));
	// Sort the array by ascending rank of values
	RankHisto = Array.rankPositions(Histo);
	// So the mode is the last value of the sorted array
	Mode=RankHisto[RankHisto.length-1];
	return Mode
}
