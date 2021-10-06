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
//		NStack_ID = argarray[0];
		SNR = parseFloat(argarray[0]);
		In_Av =  parseFloat(argarray[1]);
	}
	else {
		called = false;

//		Default values		
		SNR_DEF = 12; //	Threshold for signal = % of signal-background (to select the "object" ROI)
		In_Av_DEF = 10; //	Number of initial slices used to determine the target reference intensity
	
//		Dialog
		Dialog.create("Normalize Movie: options");
		Dialog.addNumber("Threshold", SNR_DEF, 0, 4, "%");
		Dialog.addNumber("Initial frames for average", In_Av_DEF, 0, 4, "");
		Dialog.show();
		SNR = Dialog.getNumber();
		In_Av = Dialog.getNumber();
	}

//	setBatchMode(true);

//	Retrieve parameters of the input stack
	NStack_Title = getTitle();
	NStack_ID = getImageID();
	Stack.getDimensions(Nwidth, Nheight, Nchannels, Nslices, Nframes);
	
//	Projects the stack to use as source for object detection
	run("Z Project...", "projection=[Average Intensity]");
	NProj_ID = getImageID();
	run("Despeckle", "stack");
	
	
	for (c = 0; c < Nchannels; c++) {	

		selectImage(NStack_ID);	
		if (Nchannels > 1) Stack.setChannel(c + 1);
		
//		Loop through n (specified) last slices to calculate the max
		Max_Intensity = 0;
		for (i = 0; i < In_Av; i++) {
			Stack.setFrame(Nframes - i - 1);
			getStatistics(area, ROI_Mean, min, max, std, histogram);
			Max_Intensity = Max_Intensity + max;
		}
		Max_Intensity = Max_Intensity / In_Av;
//		print("Max Intensity: " + Max_Intensity);

// 		Loop through n (specified) first slices to calculate the target reference intensity
		Ref_Intensity = 0;
		for (i = 0; i < In_Av; i++) {
			Stack.setFrame(i + 1);
			getStatistics(area, ROI_Mean, min, max, std, histogram);
			Ref_Intensity = Ref_Intensity + ROI_Mean;
		}
		Ref_Intensity = Ref_Intensity / In_Av;
//		print("Ref Intensity: " + Ref_Intensity);
		
//	Threshold the projection to define the "object" ROI
//		Mode of the projected stack = background
		
		selectImage(NProj_ID);
		if (Nchannels > 1) Stack.setChannel(c + 1);
		Image_Mode = getMode();
//		print("Image Mode: " + Image_Mode);
//		Defines lower threshold limit as preset S/N ratio * background
		Above_Thresh = SNR * (Max_Intensity - Image_Mode) /100;
		Low_Thresh = Image_Mode + Above_Thresh;	
//		print("Image_Mode: " + Image_Mode);
//		print("Above_Thresh: " + Above_Thresh);
//		print("Low_Thres: " + Low_Thresh);
//		Defines higher threshold (255 or 65535 depending on bit depth)
		High_Thresh = pow(2, bitDepth()) - 1;
		setThreshold(Low_Thresh, High_Thresh);
//		print("Low Threshold: " + Low_Thresh);
//		print("High Threshold: " + High_Thresh);
		run("Create Selection");

/*		Restore object ROI on input stack
		selectImage(NStack_ID);
		if (Nchannels > 1) Stack.setChannel(c + 1);
		Stack.setFrame(1);
		run("Restore Selection");
*/
	
//		Loop through alls slices and multiply each slice to bring the object ROI mean intensity to reference intensity
		selectImage(NStack_ID);	
		if (Nchannels > 1) Stack.setChannel(c + 1);
		
		for (i = 0; i < Nframes; i++) {
			Stack.setFrame(i+1);
			run("Restore Selection");
			getStatistics(area, ROI_Mean, min, max, std, histogram);
			Intensity_Correction = Ref_Intensity / ROI_Mean;
//			waitForUser("slice#" + i+1));
			run("Select None");
			run("Multiply...", "slice value=" + Intensity_Correction);
			
		}

	}
	
	selectImage(NProj_ID);
	close();
//	setBatchMode("exit and display");
	return "done";
}


function getMode() {
	// use number of values as bins or 16 bit values for 32 bits 
	if (bitDepth() == 32) bins = 8;
	else bins = bitDepth();
	// Return the mode (intensity value taken by the highest number of pixels in the image)
	if (bitDepth() == 32) getHistogram(Val, Histo, 256, 0, 1);
	else getHistogram(Val, Histo, pow(2,bitDepth()));
	// Sort the array by ascending rank of values
	RankHisto = Array.rankPositions(Histo);
	// So the mode is the last value of the sorted array
	Mode = RankHisto[RankHisto.length-1];
	if (bitDepth() == 32) Mode= Mode / 256;
	return Mode; 
}
