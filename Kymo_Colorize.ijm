// Code comes from KymographClear 2.0 toolset by Pierre Mangeol
// https://sites.google.com/site/kymographanalysis/
// KymographClear and KymographDirect: two tools for the automated quantitative analysis of molecular and cellular dynamics using kymographs
// Pierre Mangeol, Bram Prevo and Erwin Peterman. Molecular Biology of the Cell doi:10.1091/mbc.E15-06-0404 (2016).

macro "Kymo Colorize" {
	
	// creation of paved kymograph to reduce edge issues
	
	setBatchMode(true);
	run("Duplicate...", "title=subFourier1");
	run("Duplicate...", "title=subFourier2");
	run("Duplicate...", "title=subFourier3");
	run("Duplicate...", "title=subFourier4");
	
	selectWindow("subFourier2");
	run("Flip Horizontally");
	
	selectWindow("subFourier3");
	run("Flip Horizontally");
	run("Flip Vertically");
	
	selectWindow("subFourier4");
	run("Flip Vertically");
	
	
	setColor(0);
	selectWindow("subFourier1");
	run("Copy");
	getDimensions(width1, height1, channels, slices, frames);
	
	newImage("filter forward", "16-bit Black", 3*width1, 3*height1,1);
	
	 
	makeRectangle(width1, height1, width1, height1); 
	run("Paste"); 
	
	selectWindow("subFourier2");
	run("Copy");
	selectWindow("filter forward");
	makeRectangle(0, height1, width1, height1); 
	run("Paste"); 
	makeRectangle(2*width1, height1, width1, height1); 
	run("Paste");
	
	selectWindow("subFourier3");
	run("Copy");
	selectWindow("filter forward");
	makeRectangle(0, 0, width1, height1); 
	run("Paste"); 
	makeRectangle(2*width1, 0, width1, height1); 
	run("Paste");
	makeRectangle(0, 2*height1, width1, height1); 
	run("Paste"); 
	makeRectangle(2*width1, 2*height1, width1, height1); 
	run("Paste");
	
	selectWindow("subFourier4");
	run("Copy");
	selectWindow("filter forward");
	makeRectangle(width1, 0, width1, height1); 
	run("Paste"); 
	makeRectangle(width1, 2*height1, width1, height1); 
	run("Paste");
	
	selectWindow("subFourier1");
	close();
	selectWindow("subFourier2");
	close();
	selectWindow("subFourier3");
	close();
	selectWindow("subFourier4");
	close();
	
	makeRectangle(0, 0, 3*width1, 3*height1); 
	newImage("filter backward", "16-bit Black", 3*width1, 3*height1,1);
	newImage("static", "16-bit Black", 3*width1, 3*height1,1);
	
	selectWindow("filter forward");
	makeRectangle(0, 0, 3*width1, 3*height1); 
	run("Copy");
	selectWindow("filter backward");
	run("Paste");
	selectWindow("static");
	makeRectangle(width1, height1, 3*width1, 3*height1);
	run("Paste");
	
	selectWindow("filter forward");
	run("FFT");
	getDimensions(width, height, channels, slices, frames);
	fillRect(width/2, height/2-1, width/2, height/2+1);
	fillRect(0, 0, width/2, height/2+1);
	run("Inverse FFT");
	
	makeRectangle(width1, height1, width1, height1);
	run("Crop");
	//saveAs("Tiff", mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " filtered_forward.tif");
	rename("forward filtered");
	getStatistics(area, mean, min_forward, max_forward, std, histogram);
	
	selectWindow("FFT of filter forward");
	close();
	selectWindow("filter forward");
	close();
	
	selectWindow("filter backward");
	makeRectangle(0, 0, 3*width1, 3*height1); 
	run("Flip Horizontally");
	

	run("FFT");
	fillRect(width/2, height/2-1, width/2, height/2+1);
	fillRect(0, 0, width/2, height/2+1);
	run("Inverse FFT");
	run("Flip Horizontally");
	
	
	
	makeRectangle(width1, height1, width1, height1);
	run("Crop");
	//saveAs("Tiff", mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " filtered_backward.tif");
	rename("backward filtered");
	getStatistics(area, mean, min_backward, max_backward, std, histogram);
	
	
	selectWindow("FFT of filter backward");
	close();
	selectWindow("filter backward");
	close();
	
	selectWindow("static");
	makeRectangle(0, 0, 3*width1, 3*height1);
	run("FFT");
	
	run("Rotate... ", "angle=-45 grid=1 interpolation=Bilinear"); 
	fillRect(width/2, height/2-1, width/2, height/2+1);
	fillRect(0, 0, width/2, height/2+1);
	run("Rotate... ", "angle=45 grid=1 interpolation=Bilinear");
	run("Inverse FFT");
	
	makeRectangle(width1, height1, width1, height1);
	run("Crop");
	run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear");
	
	
	//saveAs("Tiff", mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " static.tif");
	rename("static filtered");
	getStatistics(area, mean, min_static, max_static, std, histogram);
	
	selectWindow("FFT of static");
	close();
	selectWindow("static");
	close();
	
	maximum = maxOf(max_backward,max_forward);
	minimum = minOf(min_backward,min_forward);
	
	selectWindow("static filtered");
	setMinAndMax(min_static, max_static);
	selectWindow("forward filtered");
	setMinAndMax(minimum, maximum);
	selectWindow("backward filtered");
	setMinAndMax(minimum, maximum);
	
	run("Merge Channels...", "c1=[forward filtered] c2=[backward filtered] c3=[static filtered] create");
	//saveAs("Tiff", mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " color coded directions.tif");
	
	
	setBatchMode("exit and display");
//	selectImage(seqID);
	run("Select None");
	//open(mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph" + j + ".tif");
	//open(mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " filtered_forward.tif");
	//open(mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " filtered_backward.tif");
	//open(mainfolderpath + File.separator + "kymograph" + File.separator + "kymograph_"+ j + File.separator + "kymograph_" + j + " static.tif");
	
	// setTool("zoom");
	// run("Tile");

}
