macro "Measure Kymos" {
	// Define threshold speed for static
	staticThreshold = 0.02;
	
	// Get stack title, scale and ROI number
	stackTitle = getTitle();
	getVoxelSize(pX, pY, pZ, pUnit);
	nROI = roiManager("count");
		
	// Prepare the Results table
	title1 = "" + stackTitle + " results";
	title2 = "[" + title1 + "]";
	f = title2;
	if (isOpen(title1))
		print(f, "\\Clear");
	else
	run("New... ", "name=" + title2 + " type=Table");
	Headings = "\\Headings:n\tCh\tSlice\tLabel\tROI#\tROI\ttype#\ttype\tSegment\tendX\tendY\tLength\tTime\tSpeed\tCategory";
	print(f, Headings);
	resultsLine = 0;
	
	for (r = 0; r < nROI; r++) {

		// Select ROI
		roiManager("select", r);

		// Get slice label and position
		imTitle = getInfo("slice.label");
		Stack.getPosition(imChannel, imSlice, imFrame);

		// Get ROI name, properties and number
		roiTitle = getInfo("selection.name");
		roiType = Roi.getProperty("TracingType");
		roiTypeName = Roi.getProperty("TypeName");
		roiNumber = r + 1;
				
		// get ROI coordinates
		Roi.getCoordinates(xpoints, ypoints);
		L = xpoints.length;
		// Array.print(xpoints);
		// Array.print(ypoints);
		
		// Scaled coordinates
		xS = newArray(L);
		yS = newArray(L);
		for (i = 0; i < L; i++) {
			xS[i] = xpoints[i] * pX;
			yS[i] = ypoints[i] * pY;
		}
		
		// Coordinates differences
		dx = newArray(L);
		dy = newArray(L);
		// Using index=0 to store global difference between extremities
		dx[0] = xpoints[L-1] - xpoints[0];
		dy[0] = ypoints[L-1] - ypoints[0];
		// 1 to L for single-step differences
		for (i = 1; i < L; i++) {
			dx[i] = xpoints[i] - xpoints[i - 1];
			dy[i] = ypoints[i] - ypoints[i - 1];
		}
		
		// Scaled differences (0 is global, 1-L for each step)
		dxS = newArray(L);
		dyS = newArray(L);
		for (i = 0; i < L; i++) {
			dxS[i] = dx[i] * pX;
			dyS[i] = dy[i] * pY;
		}
		
		// Speeds (O is global, 1-L for each step)
		V = newArray(L);
		for (i = 0; i < L; i++) {
			V[i] = dxS[i] / dyS[i];
		}
		
		// Category (anterograde = +1, retrograde = -1, static = 0);
		Cat = newArray(L);
		for (i = 0; i < L; i++) {
			if (V[i] > staticThreshold) Cat[i] = 1;
			else if (V[i] < -staticThreshold) Cat[i] = -1;
			else Cat[i] = 0;		
		}
		
		for (i = 0; i < L; i++) {
			resultsLine++;
			// Build the Results table line
			ResultsLine = d2s(resultsLine, 0) + "\t" + imChannel + "\t" + imSlice + "\t" + imTitle + "\t" + roiNumber + "\t" + roiTitle + "\t" + roiType + "\t" + roiTypeName + "\t" + i + "\t" + xS[i] + "\t" + yS[i] + "\t" + dxS[i] + "\t" + dyS[i] + "\t" + V[i] + "\t" + Cat[i];
			print(f, ResultsLine);
		}
	
	}

}
