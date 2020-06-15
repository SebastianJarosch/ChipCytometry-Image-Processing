//Run script to enable y-Overlap in the stitching Plug-In
//If you are running the script for the first time, you will be asked to restart imageJ
eval("bsh", "plugin.Stitching_Grid.seperateOverlapY = true;");
 
//choose the directory where the raw images are stored and try to catch the ChipID
pathraw=getDirectory("Choose the directory for raw data");
ChipID=substring(pathraw, lengthOf(pathraw)-8, lengthOf(pathraw)-1);

//get the markers which are present in the subfolder of the path with rawdata
folders=getFileList(pathraw);
markernumber=folders.length;

//Check if the chip has already been analyzed by searching for the "Results" folder
for (i = 0; i < markernumber; i++) {
	folders[i]=substring(folders[i], 0, lengthOf(folders[i])-1);
	if (folders[i]=="Results") {
		print("Chip has already been analyzed");
		exit("Chip already analyzed. Please delete results folder and start macro again")
	}
}

//Start the analysis
print("Number of markers found: "+markernumber);

//get type of tissue to adjust default parameters for analysis
Dialog.create("Tissue properties");
Dialog.addString('ChipID', ChipID)
organisms=newArray("human","mouse");
tissues=newArray("colon","spleen/LN","stomach","pancreas","breast");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Organism", organisms, "human");
Dialog.addChoice("Tissue", tissues, "colon");
Dialog.setInsets(10, 0, 0);
highlight_message("Size of the tissue section", "b");
Dialog.addNumber("grid size x", 6);
Dialog.addNumber("grid size y", 4);
Dialog.addNumber("first tile", 1);
Dialog.setInsets(10, 0, 0);
Dialog.addCheckbox("Clean folder", false)
Dialog.setInsets(0, 0, 0);
highlight_message("This will delete all files except","i");
Dialog.setInsets(0, 0, 0);
highlight_message("of the .tiff files needed for the","i");
Dialog.setInsets(0, 0, 0);
highlight_message("analysis to save disk space.","i");
Dialog.show();

//Get values from the dialog
ChipID=Dialog.getString();
organism=Dialog.getChoice();
tissue=Dialog.getChoice();
xsize=Dialog.getNumber();
ysize=Dialog.getNumber();
firsttile=Dialog.getNumber();
clean=Dialog.getCheckbox();
print("Chip "+ChipID+" contains "+organism+" "+tissue+" tissue");

if (clean==true) {
	var total_filelist=newArray();
	pattern_ending = ".tiff";
	deleteFiles(pathraw, pattern_ending, true); 
}

//Dialog for selection of markers to be analyzed
Dialog.create("Select markers for analysis");
n=3*markernumber;
chbxlables = newArray(n);
defaults = newArray(n);
for (i = 0; i < markernumber*3; i=i+3) {
	chbxlables[i]="Process "+folders[i/3];
	chbxlables[i+1]="Intranuclear";
	chbxlables[i+2]="Detect aggregates";
	defaults[i] = true;
	if(folders[i/3]=='DNA'||folders[i/3]=='Nuclei'||folders[i/3]=='FoxP3'||folders[i/3]=='GATA3'||folders[i/3]=='Ki67'){
		defaults[i+1] = true;
	}else {
		defaults[i+1] = false;
	}
	if(folders[i/3]=='DNA'||folders[i/3]=='Nuclei'||folders[i/3]=='Vimentin'||folders[i/3]=='SMA'||folders[i/3]=='Cytokeratin'||folders[i/3]=='PAN'||folders[i/3]=='EpCAM'){
		defaults[i+2] = false;
	}else {
		defaults[i+2] = true;
	}
}
Dialog.addCheckboxGroup(markernumber, 3, chbxlables, defaults);
Dialog.show();

//Get values from the dialog
marker=newArray(markernumber);
intranuclear_0=newArray(markernumber);
aggregateremoval_0=newArray(markernumber);
markernumber_total=0;
for (i = 0; i < markernumber; i++) {
	marker[i]=Dialog.getCheckbox();
	intranuclear_0[i]=Dialog.getCheckbox();
	aggregateremoval_0[i]=Dialog.getCheckbox();
	if (marker[i]==true) {
		markernumber_total++;
	}
}
intranuclear=newArray(markernumber_total);
aggregateremoval=newArray(markernumber_total);
j=0;
for (i = 0; i < markernumber; i++) {
	if (marker[i]==true) {
		intranuclear[j]=intranuclear_0[i];
		aggregateremoval[j]=aggregateremoval_0[i];
		j++;
	}
}

//Create dialog with options for analysis
Dialog.create("Specify analysis");
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Create merge image","b"), true);
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Segmentation","b"), true);
nuclei_names=newArray("Nuclei","DNA","Hoechst");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Nuclei staining", folders, occurance_in_array(folders, nuclei_names));
sepepithel=false;

if (tissue=="colon"||tissue=="pancreas"||tissue=="breast"||tissue=="stomach") {
	choices=Array.concat(folders,"No staining");
	epithelial_names=newArray("PAN","Cytokeratin","PAN-Cytokeratin","EpCAM");
	Dialog.setInsets(0, 0, 0);
	Dialog.addChoice("Epithelial cells", choices, occurance_in_array(folders, epithelial_names));
	sepepithel=true;
}
ensize=3;
if (tissue=="spleen/LN") {
	ensize=2;
}
Dialog.addNumber("Enlarge ROIs by", ensize,0,1, "pixel");
Dialog.setInsets(15, 0, 0);
Dialog.addCheckbox(highlight_string("FL-Value calculation","b"), true);
Dialog.addCheckbox(highlight_string("Remove outliers","u"), true);
Dialog.addNumber(highlight_string("Radius ","i"), 2);
Dialog.addNumber(highlight_string("Threshold ","i"), 50);
Dialog.addCheckbox(highlight_string("Minimum filter","u"), true);
Dialog.addNumber(highlight_string("Radius ","i"), 0.5);
Dialog.setInsets(15, 0, 0);
Dialog.addCheckbox(highlight_string("Marker consistancy check","b"), true);
Dialog.setInsets(15, 0, 0);
Dialog.addCheckbox(highlight_string("Spatial spillover correction","b"), true);
Dialog.addNumber("Threshold", 60, 0, 4, "%");
Dialog.addNumber("Min intensity", 100, 0, 4, "");
Dialog.addHelp("<html><b>Segmentation</b><br>here you need to choose your segmentationmarker and the marker for epithelial cells, if you have selected a tissue type "+
"containing epithelial cells. if no epithelial cell staining was performed, you can choose <cite>no staining</cite> and a one marker segmentation will be performed.<br><br>"+
"<b>FL-value calculation</b><br>Here specific parameters can be adjusted for preprocessing surface-Marker images. The default values have been tested and titrated, so they "+
"resemble a good starting point.<br><br><b>Marker consistancy check</b>This checks, if images are available for all positions in all markers. If this is not the case, you can "+
"choose to delete images, which are only present for some markers but not for others.<br><br><b>Spatial spillover correction</b><br>The threshold defines, which percentage of"+
"signal is maximal allowed to be present in only one quater of the cell. The min intensity is the min grayscale value, for which a cell is considered for spacial spillover "+
"correction<br><br><b>For additional information, refer to the documentation</b><br><a href>https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/README.md</a></html>");
Dialog.show();

//Get values from the dialog
mergeimages=Dialog.getCheckbox();
segmentationstatus=Dialog.getCheckbox();
segmentationmarker=Dialog.getChoice();
if (tissue=="colon"||tissue=="pancreas"||tissue=="breast"||tissue=="stomach") {
	cytokeratin=Dialog.getChoice();
}
if (cytokeratin=="No staining") {
	sepepithel=false;
}
ensize=Dialog.getNumber();
valuecalculation=Dialog.getCheckbox();
outlier_correction=Dialog.getCheckbox();
outlier_radius=Dialog.getNumber();
outlier_threshold=Dialog.getNumber();
minimum_correction=Dialog.getCheckbox();
minimum_radius=Dialog.getNumber();
checkconsistancy=Dialog.getCheckbox();
spillovercorrection=Dialog.getCheckbox();
totalpositions=xsize*ysize+(firsttile-1);
distribution_threshold=Dialog.getNumber();
minCorrInt=Dialog.getNumber();
distribution_threshold=distribution_threshold/25;
error_cells=newArray();

//Check for conistancy of positions between markers, using the segmentation marker as refference
segmentationmarkerpositions = getFileList(pathraw+"/"+segmentationmarker);
for (j = 0; j < segmentationmarkerpositions.length; j++) {
		segmentationmarkerpositions[j]=substring(segmentationmarkerpositions[j], 0, lengthOf(segmentationmarkerpositions[j])-1);
}

positions = newArray();
inconsistant = false;
for (i = 0; i < markernumber; i++) {
	if(marker[i] == true){
		next = getFileList(pathraw+folders[i]);
		for (k = 0; k < next.length; k++) {
			next[k]=substring(next[k], 0, lengthOf(next[k])-1);
		}
		if (next.length > segmentationmarkerpositions.length){
			n = next.length - segmentationmarkerpositions.length;
			errors = ArrayDifference(segmentationmarkerpositions, next);
			Array.sort(errors);
			print(n+" additional positions detected in "+folders[i]+":");
			Array.print(errors);
			inconsistant = true;
		}
		if (next.length < segmentationmarkerpositions.length){
			n = segmentationmarkerpositions.length-next.length;
			errors = ArrayDifference(segmentationmarkerpositions, next);
			Array.sort(errors);
			print(n+" positions are missing in "+folders[i]+":");
			Array.print(errors);
			inconsistant = true;
		}
		if (next.length == segmentationmarkerpositions.length && folders[i] != segmentationmarker){
			print("Check OK for "+folders[i]);
		}
	}
}

//delete folders not present in all markers
if (checkconsistancy == true && inconsistant == true) {
	choices = newArray("delete additional positions","exit");
	Dialog.create("Inconsistancy detected");
	Dialog.addChoice("How would you like to proceed?", choices);
	Dialog.show();
	decision=Dialog.getChoice();
	if (decision=="exit") {
		exit();
	}
	if (decision=="delete additional positions") {
		for (i = 0; i < markernumber; i++) {
			if(marker[i] == true && folders[i] != segmentationmarker){
				next = getFileList(pathraw+folders[i]);
				for (k = 0; k < next.length; k++) {
					next[k]=substring(next[k], 0, lengthOf(next[k])-1);
				}
				if (next.length > segmentationmarkerpositions.length){
					errors = ArrayDifference(segmentationmarkerpositions, next);
					for (l = 0; l < errors.length; l++) {
						File.delete(pathraw+folders[i]+"/"+errors[l]+"/hdr/HDRFL.tiff");
						File.delete(pathraw+folders[i]+"/"+errors[l]+"/hdr");
						File.delete(pathraw+folders[i]+"/"+errors[l]);
					}
				}
				if (next.length < segmentationmarkerpositions.length){
					errors = ArrayDifference(segmentationmarkerpositions, next);
					for (l = 0; l < errors.length; l++) {
						for (m = 0; m < marker.length; m++) {
							File.delete(pathraw+folders[m]+"/"+errors[l]+"/hdr/HDRFL.tiff");
							File.delete(pathraw+folders[m]+"/"+errors[l]+"/hdr");
							File.delete(pathraw+folders[m]+"/"+errors[l]);
						}
					}
				}
				if (next.length == segmentationmarkerpositions.length && folders[i] != segmentationmarker){
					print("Check OK for "+folders[i]);
				}
			}
		}
	}

	//check again for consistancy
	segmentationmarkerpositions = getFileList(pathraw+"/"+segmentationmarker);
	for (j = 0; j < segmentationmarkerpositions.length; j++) {
			segmentationmarkerpositions[j]=substring(segmentationmarkerpositions[j], 0, lengthOf(segmentationmarkerpositions[j])-1);
	}
	for (i = 0; i < markernumber; i++) {
		if(marker[i] == true){
			next = getFileList(pathraw+folders[i]);
			for (k = 0; k < next.length; k++) {
				next[k]=substring(next[k], 0, lengthOf(next[k])-1);
			}
			if (next.length == segmentationmarkerpositions.length && folders[i] != segmentationmarker){
				print("Check OK for "+folders[i]);
				inconsistant=false;
			}
			if (next.length != segmentationmarkerpositions.length) {
				print("Check failed for "+folders[i]);
				exit("data is still inconsistant!");
			}
		}
	}
}


//clear the Log save sheet for Channel renaming
print("\\Clear");
print(ChipID);
for (i = 0; i < markernumber; i++) {
	if (marker[i] == 1) {
		print(folders[i]);
	}
}
selectWindow("Log");
saveAs("Text", pathraw+"channels.csv"); 

//Print initial values to Log
print("size_x = "+xsize);
print("size_y = "+ysize);
print("first tile for stitching = "+firsttile);
print("Number of positions to be stitched = "+totalpositions);
print("Segmentation: "+segmentationstatus);
print("Segmentationmarker: "+segmentationmarker);
print("FL-calculation: "+valuecalculation);
Array.print(marker);

//Initialize time values
Tempty = 0;
Trenaming = 0;
Tstitching = 0;
Tsegmentation = 0;
Troiprocessing = 0;
Tcalculation = 0;
startTtotal = getTime();
startT = getTime;

//generate black images for stitching which cover the whole area
setBatchMode(true);
for (i = 1; i <= totalpositions; i++) {
	if (i<10) {
		newImage(i, "16-bit black", 1392, 1040, 1);
		run("16-bit");
		saveAs("Tiff", pathraw+"00"+i);
		close();
	}		
	if (i<100 && i>9 ){
		newImage(i, "16-bit black", 1392, 1040, 1);
		run("16-bit");
		saveAs("Tiff", pathraw+"0"+i);
		close();
	}
	if (i<1000 && i>99 ){
		newImage(i, "16-bit black", 1392, 1040, 1);
		run("16-bit");
		saveAs("Tiff", pathraw+i);
		close();
	}
	print("\\Update: Framework images generated successfully: "+i);
}
print ("processing time empty positions ="+(getTime-startT)/1000+"s");
Tempty = Tempty+((getTime-startT)/1000);
startT = getTime;

//get files from folder and rename according to their directory
for (j = 0; j < markernumber; j++) {
	setBatchMode(true);
	if(marker[j] == 1){
		print(folders[j]);
		print("");
		for (i = 1; i <= totalpositions; i++) {
			if (i<10 && File.exists(pathraw+folders[j]+"/pos0"+i+"/hdr/HDRFL.tiff")) {
				open(pathraw+folders[j]+"/pos0"+i+"/hdr/HDRFL.tiff");
				run("16-bit");
				saveAs("Tiff", pathraw+"00"+i);
				close();
				print("\\Update: Image renamed successfully: "+i);
			}
			if (i<100 && i>9 && File.exists(pathraw+folders[j]+"/pos"+i+"/hdr/HDRFL.tiff")) {
				open(pathraw+folders[j]+"/pos"+i+"/hdr/HDRFL.tiff");
				run("16-bit");
				saveAs("Tiff", pathraw+"0"+i);
				close();
				print("\\Update: Image renamed successfully: "+i);
			}
			if (i<1000 && i>99 && File.exists(pathraw+folders[j]+"/pos"+i+"/hdr/HDRFL.tiff")) {
				open(pathraw+folders[j]+"/pos"+i+"/hdr/HDRFL.tiff");
				run("16-bit");
				saveAs("Tiff", pathraw+i);
				close();
				print("\\Update: Image renamed successfully: "+i);
			}						
		}
		print ("processing time renaming ="+(getTime-startT)/1000+"s");
		
		//Save image sequence to the stiching folder and overwrite corresponding black tiles
		run("Image Sequence...", "open=pathraw");
		stackname=getTitle();
		windowname=stackname;
		selectWindow(windowname);
		run("Image Sequence... ", "format=TIFF use save=pathraw");
		close();
		print("Images saved");
		Trenaming = Trenaming+((getTime-startT)/1000);
		startT = getTime;
		
		//Run stitching Plugin from ImageJ with files generated in the folder
		run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Left & Down] grid_size_x=xsize grid_size_y=ysize tile_overlap_x=3 tile_overlap_y=0 "+
		"first_file_index_i=firsttile directory=&pathraw file_names={iii}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] "+
		"regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save memory (but be slower)] "+
		"image_output=[Fuse and display]");
		File.makeDirectory(pathraw+"Results");
		saveAs("tiff", pathraw+"Results/"+folders[j]+".tiff");
		close();
		Tstitching = Tstitching+((getTime-startT)/1000);
	}
}

//delete unstiched images
for (i = 1; i <= totalpositions; i++) {
	if (i<10) {
		File.delete(pathraw+"00"+i+".tif");
		print("\\Update:Image 00"+i+" deleted");
	}		
	if (i<100 && i>9 ){
		File.delete(pathraw+"0"+i+".tif");
		print("\\Update:Image 0"+i+" deleted");
	}
	if (i<1000 && i>99 ){
		File.delete(pathraw+i+".tif");
		print("\\Update:Image "+i+" deleted");
	}
}

//Create merge image
if (mergeimages == true){
	colors=newArray("Red","Green","Blue","Gray","Cyan","Magenta","Yellow");
	items=getFileList(pathraw+"Results/");
	for (i = 0; i < items.length; i++) {
		items[i]=substring(items[i], 0, lengthOf(items[i])-5);
	}
	items=Array.concat(items,"*None*");
	Dialog.create("Define channels for merged image");
	default_choices=newArray("Vimentin","*None*","Cytokeratin","Nuclei","*None*","*None*","SMA");
	default_weights=newArray(1,1,1,0.5,1,1,1);
	for (i = 0; i < 7; i++) {
		label="C"+(i+1)+" "+colors[i];
		Dialog.addChoice(label, items,default_choices[i]);
		Dialog.addToSameRow();
		Dialog.addNumber("weight", default_weights[i],1,3,"");
	}
	Dialog.show();
	imageselection=newArray(7);
	weights=newArray(7);
	String.resetBuffer;
	for (i = 0; i < 7; i++) {
		imageselection[i]=Dialog.getChoice()+".tiff";
		weights[i]=Dialog.getNumber();
		if (imageselection[i]!="*None*.tiff") {
			print("Processing "+substring(imageselection[i],0,lengthOf(imageselection[i])-5)+" for merge...");
			open(pathraw+"Results/"+imageselection[i]);
			run("Multiply...", "value="+weights[i]);
			String.append("c"+(i+1)+"="+imageselection[i]+" ");
		}
	}
	print("Merging images...");
	String.append("create");
	run("Merge Channels...", String.buffer);
	run("Stack to RGB");
	saveAs("tiff", pathraw+"/merge.tiff");
	run("Close All");	
}

//Continue with segmentation
roiManager("reset");
finalimages=pathraw+"Results/";
File.makeDirectory(finalimages+"segmentation");
File.makeDirectory(finalimages+"stitching");

if (segmentationstatus == true) {

	var threshold_values=newArray();
	startT=getTime();
	open(finalimages+segmentationmarker+".tiff");

	if (sepepithel == true){

		//Run segmentation for Crypts to subtract them from the total nuclei
		open(finalimages+cytokeratin+".tiff");
		run("Unsharp Mask...", "radius=5000 mask=0.9");
		run("Gaussian Blur...", "sigma=3");
		setAutoThreshold("Yen dark");
		run("Convert to Mask");
		run("Watershed");
		run("Analyze Particles...", "size=1000-infinity pixel clear include add");
		
		//Enlarge crypts by 5 pixel and combine to one ROI
		counts=roiManager("count");
		print(counts);
		print("");
		if (counts<=1){
			exit("No crypts detected, please check your cytokeratine channel");
		}
		for(i=0; i<counts; i++) {
		    roiManager("Select", i);
		    run("Enlarge...", "enlarge=5 pixel");
		    roiManager("Update");
		    progress = ((i+1)/counts)*100;
		    print("\\Update: Crypt ROIs updated: "+progress+" %");
		}
		roiManager("Select All");
		roiManager("Combine");
		roiManager("Add");
		print("Crypts segmented");

		//Generate the LP cells by subtracting the combined crypt ROI
		selectWindow(segmentationmarker+".tiff");
		run("Duplicate...", "title=Lamina_propria.tiff");
		selectWindow("Lamina_propria.tiff");
		roiManager("Select", roiManager("count")-1);
		roiManager("Update");
		run("Clear", "slice");
		roiManager("delete");
		crypt_ROIs=roiManager("count");

		//Subtract LP cell from all cells to only get epithelial nuclei
		roiManager("reset");
		selectWindow(segmentationmarker+".tiff");
		run("Duplicate...", "title=Epithel.tiff");
		imageCalculator("Subtract", "Epithel.tiff","Lamina_propria.tiff");
		print(crypt_ROIs+" crypts have been detected");

		//save the Images for segmentations
		selectWindow("Epithel.tiff");
		saveAs("tiff", finalimages+"segmentation/Epithel.tiff");
		selectWindow("Lamina_propria.tiff");
		saveAs("tiff", finalimages+"segmentation/Lamina_propria.tiff");
		run("Close All");

		//actually perform the segmentation (function returns the cellnumber)
		epithelialcellnumber=segmentation("Epithel",7000,75,2000,0.2);
		LPcellnumber=segmentation("Lamina_propria",3000,70,400,0.55);
		cellnumber=0;
		
	}else {
	// Generate Mask/ROI
	run("Duplicate...", "title=all.tiff");
	saveAs("tiff", finalimages+"segmentation/all.tiff");
	run("Close All");
	cellnumber=segmentation("all",3000,70,400,0.55);
	epithelialcellnumber=0;
	LPcellnumber=0;
	}
	Tsegmentation = Tsegmentation+((getTime-startT)/1000);
	
	if (valuecalculation == 1) {
		
		//get file list for all stiched images
		files=getFileList(finalimages);
		files=Array.delete(files, "stitching/");
		files=Array.delete(files, "segmentation/");

		
		//Perform aggregate detection and removal
		print("Start aggregate detection...");
		for (i = 0; i < files.length; i++) {
			name=substring(files[i],0,lengthOf(files[i])-5);
			if (name!=segmentationmarker && name!=cytokeratin) {
				if (aggregateremoval[i]==true){
					filepath=finalimages+files[i];
					number_of_aggregates = aggregate_detection(name, filepath);
					print(name+": "+number_of_aggregates+" aggregates have been detected");
				}
			}
		}
		
		startT = getTime;
		roiManager("reset");
		if (sepepithel == true){
			roiManager("open", finalimages+"segmentation/Lamina_propria_enlarged_cells.zip")
			roiManager("open", finalimages+"segmentation/Epithel_enlarged_cells.zip")
		}
		if (sepepithel == false){
			roiManager("open", finalimages+"segmentation/all_enlarged_cells.zip")
		}

		//Image sequence would change the order of the channels, therefore each channel needs to be opened idividually first.
		for(i=0; i<files.length; i++) {
			open(finalimages+files[i]);
		}
		run("Images to Stack", "name=Stack title=[] use");
		run("Clear Results");
		run("Set Measurements...", "area mean standard min centroid center perimeter bounding fit shape feret's integrated median "+
		"skewness kurtosis area_fraction stack display invert add redirect=None decimal=3");
		setSlice(1);
		Stack.getDimensions(width, height, channels, slices, frames);
		print("Number of images opened for measurement: "+slices);
		
		if (spillovercorrection==true){
			File.makeDirectory(finalimages+"segmentation/"+"spatial_spillover_correction");
		}

		//Cycle through all channels for the following block of commands
		for (i=1;i<=slices;i++) {
			slicename=substring(getInfo("slice.label"),0,lengthOf(getInfo("slice.label"))-5);
			
			//Correct the surfacemarkers to get them less blurry
			if (intranuclear[i-1]!=true){
				if(outlier_correction==true){
					run("Remove Outliers...", "radius="+outlier_radius+" threshold="+outlier_threshold+" which=Bright");
				}
				run("Median...", "radius=1");
				if(minimum_correction==true){
					run("Minimum...", "radius="+minimum_radius);
				}
			}

			//Perform spillovercorrection for all cells 
			if (spillovercorrection==true && intranuclear[i-1]!=true){
				File.makeDirectory(finalimages+"segmentation/spatial_spillover_correction/"+slicename+"_excluded");
				setBatchMode(true);
				total_rois=roiManager("count");
				error_cells=newArray();
				for (k = 0; k < total_rois; k++) {	
					total_cells=roiManager("count");
					cell=k;
					roiManager("select", cell);
					if(selectionType() != -1) {
						List.setMeasurements;
						if (parseFloat(List.get("Mean")) > minCorrInt){
							percentages=newArray(0);
							spilloverresults=newArray(5);
							
							//Subsegmentation into 4 Sub-ROIs bei overlaying rectangles and merging them with
							//the inital ROI to get one sub-ROI l = x-axis, m = y-axis
							z=0;
							roiManager("select",cell);
							getSelectionBounds(x, y, width, height);
							error_roi=false;
							for (m=0; m<2; m++) {
								for (l=0; l<2; l++) {
									makeRectangle (x+(l*width / 2), y+(m*height/2), width/2, height/2);
									roiManager("Add");
									roiManager("select", newArray(cell, total_cells+z));
									roiManager("and");
									if (selectionType()!=-1) {
										roiManager("Add");
										roiManager("deselect");
										roiManager("select", total_cells+z);
										roiManager("delete");
									} else {
										error_roi=true;
										error_cells=Array.concat(error_cells,k);
									}
									z=z+1;
								} 
							}

							//Get the mean intensity for the whole cell and the sub-ROIs
							roiManager("select", cell);
							List.setMeasurements;
							spilloverresults[0]=List.getValue("Mean");
							for (l = 1; l < 5; l++) {
								roiManager("select", total_cells+(l-1));
								List.setMeasurements;
								spilloverresults[l]=List.getValue("Mean");
							}

							//delete the sub-ROIs to come back to the initial number of ROIs, only containing the cells
							roiManager("select", newArray(total_cells,total_cells+1,total_cells+2,total_cells+3));
							roiManager("delete");


							//Calculate the percentages of Signal for each sub-ROI by deviding the mean of the su
							if(parseFloat(spilloverresults[0])!=0 && error_roi!=true){
								for (l = 1; l < 5; l++) {
									nextvalue=parseFloat(spilloverresults[l])/parseFloat(spilloverresults[0]);
									percentages=Array.concat(percentages,nextvalue);
								}
								Array.getStatistics(percentages, min, max, mean, stdDev);

								//if the percentage of signal coming from one sub-ROI gets higher than the threshold,
								//The original ROI is saved (as Image and ROI) and the signal is deleted for this marker
								for (l = 0; l < 4; l++) {
									if(parseFloat(percentages[l])>distribution_threshold){
										roiManager("select",cell);
										run("Copy");
										run("Internal Clipboard");
										selectWindow("Clipboard");
										saveAs("Tiff", finalimages+"segmentation/spatial_spillover_correction/"+slicename+"_excluded/"+(k+1)+"-excluded.tiff");
										close();
										setBackgroundColor(0, 0, 0);
										run("Clear", "slice");
										roiManager("Save", finalimages+"segmentation/spatial_spillover_correction/"+slicename+"_excluded/"+(k+1)+"-excluded.roi");
									}
								}
							}
						}
					}
					progress=((k+1)/(total_cells)*100);
					print("\\Update: Spillover correction for marker "+i+"/"+slices+" ("+slicename+"): "+progress+" %");
				}
			}

			//Finally get the Mean intensity for all cells and all markers
			roiManager("Select All");
			roiManager("Measure");
			run("Next Slice [>]");
			print("\\Update:"+i+" of "+slices+" markers measured");
		}

		//Save the stitched images with the deleted signals for each marker
		File.makeDirectory(finalimages+"stitching/spacialcorrected/");
		pathspatialcorrected=finalimages+"stitching/spacialcorrected/";
		run("Image Sequence... ", "format=TIFF use save=pathspatialcorrected");
				
		saveAs("Results", finalimages+"segmentation/FL_values.csv");
		run("Close");
		Tcalculation = Tcalculation+((getTime-startT)/1000);
	}
}

//cleanup of files and move to subfolders
run("Close All");
File.makeDirectory(pathraw+"/Results/stitching/Aggregate_removal");
for (i = 0; i < markernumber; i++) {
	File.rename(finalimages+folders[i]+".tiff",finalimages+"stitching/"+folders[i]+".tiff");
	if (aggregateremoval[i]==true) {
		File.rename(finalimages+folders[i]+"_removed_aggregates.tiff", pathraw+"/Results/stitching/Aggregate_removal/"+folders[i]+"._removed_aggregatestiff");
	}
}
File.rename(pathraw+"merge.tiff",finalimages+"stitching/merge.tiff");
File.rename(pathraw+"TileConfiguration.txt", pathraw+"/Results/stitching/TileConfiguration.txt");
File.rename(pathraw+"channels.csv", pathraw+"/Results/segmentation/channels.csv");


//Save error generating cells if the appear
if(spillovercorrection==true && error_cells.length>0){
	print("\\Clear");
	for (i = 0; i < error_cells.length; i++) {
		print(error_cells[i]);
	}
	selectWindow("Log");
	saveAs("Text", finalimages+"error_cells.txt");
}

//Generate summary file and save Log to Results folder
print("\\Clear");
print("************************************************************************************");
print("Summary of automatic image processing");
print("************************************************************************************");
print("-----------------------general project information---------------------------");
print("Tissue type on Chip "+ChipID+": "+organism+" "+tissue);
if (inconsistant == true){
	print("WARNING: Inconsistancy in markers detected !!!");
}
print("Size of the stiched image: "+xsize+" x "+ysize);
print("Number of the first image: "+firsttile);
print("Number of positions to be stitched: "+(xsize*ysize));
for (i = 0; i < markernumber; i++) {
	if (marker[i] == 1) {
		numberM = numberM+1;
	}
}
print("markers analyzed: "+numberM);
print("Time for generating empty positions: "+Tempty+" s");
print("Time for renaming positions: "+Trenaming+" s");
Ttotal = (getTime-startTtotal)/60000;
print("Total time needed for the automatic processing: "+Ttotal+" min");

print("************************************************************************************");
print("--------------------------------Stitching----------------------------------------");
print("Time for stitching: "+Tstitching+" s");
if (segmentationstatus == 1) {
	print("************************************************************************************");
	print("------------------------------Segmentation-------------------------------------");
	if (sepepithel == true) {print("seperate segmentation of epithelial cells and lamina propria");}
	print("Segmentationmarker: "+segmentationmarker);
	if (sepepithel == true) {print("epithelial cell marker: "+cytokeratin);}
	print("Enlargement of ROIs: "+ensize+" pixel");
	if (sepepithel == true) {print("Number of epithelial cells: "+epithelialcellnumber+" Threshold = ("+threshold_values[0]+"/"+threshold_values[1]+")");}
	if (sepepithel == true) {print("Number of lamina propria cells: "+LPcellnumber+" Threshold = ("+threshold_values[2]+"/"+threshold_values[3]+")");}
	totalcellnumber=epithelialcellnumber+LPcellnumber+cellnumber;
	print("Total cells segmented: "+totalcellnumber);
	if (sepepithel == false) {print("Threshold = ("+threshold_values[0]+"/"+threshold_values[1]+")");}
	print("Time for cell recognition: "+Tsegmentation+" s");
}
if (valuecalculation == 1) {
	print("************************************************************************************");
	print("----------------------------FL-calculation--------------------------------------");
	print("Time for FL-value calculation: "+Tcalculation+" s");
	if(outlier_correction==true){
		print("Outlier correction was performed with radius = "+outlier_radius+" and threshold = "+outlier_threshold);
	}
	if(minimum_correction==true){
		print("Minimum filter was applied with radius = "+minimum_radius);
	}
	if (spillovercorrection == 1) {
		print("spatial spillover corrected for cells with more than "+(distribution_threshold*25)+" % signal per quadrant");
		print("corrected were cells with a grayscale value higher than "+minCorrInt);
		if(error_cells.length > 0){
			print(error_cells.length+" cells yielded an error due to their shape");
		}
	}
}
selectWindow("Log");
saveAs("Text", finalimages+"summary.txt"); 


//FUNCTIONS......................................................................................
function ArrayDifference(array1, array2) {
	diff_Array = newArray();
	union_Array = newArray();	
	for (i=0; i<array1.length; i++) {
		for (j=0; j<array2.length; j++) {
			if (array1[i] == array2[j]){
				union_Array = Array.concat(union_Array, array1[i]);
			}
		}
	}
	x = 0;
	for (i=0; i<array1.length; i++) {
		for (j=0; j<union_Array.length; j++) {
			if (array1[i] == union_Array[j]){
				x++;
			}
		}
		if (x == 0) {
			diff_Array = Array.concat(diff_Array, array1[i]);
		}
		x = 0;
	}
	for (i=0; i<array2.length; i++) {
		for (j=0; j<union_Array.length; j++) {
			if (array2[i] == union_Array[j]){
				x++;
			}
		}
		if (x == 0) {
			diff_Array = Array.concat(diff_Array, array2[i]);
		}
		x = 0;
	}	
	return diff_Array;
}

function occurance_in_array(array, search){
	occurance = array[0];
	for (i = 0; i < array.length; i++) {
		for (j = 0; j < search.length; j++) {
			if(array[i]==search[j]){
				occurance = search[j];
			}
		}
	}
	return occurance;
}

function segmentation(filename, lower_threshold, minsize, maxsize, circularitymin) {
	//Let the user adjust the default threshold for the nuclei
	setBatchMode(false);
	open(finalimages+"segmentation/"+filename+".tiff");
	selectWindow(filename+".tiff");
	run("Gaussian Blur...", "sigma=1.00");
	run("Threshold...");
	setAutoThreshold("Yen dark");
	getThreshold(lower,upper);
    setThreshold(lower_threshold,upper);
	setOption("BlackBackground", true);
	waitForUser("Please adjust the threshold for the "+filename+" nuclei and press OK");
	close("Threshold");
	getThreshold(lower,upper);
	print("lower threshold: "+lower);
	print("upper threshold: "+upper);
	run("Close All");
	setBatchMode(true);
	
	// Generate Mask/ROIs
	setBatchMode(true);
	open(finalimages+"segmentation/"+filename+".tiff");
	selectWindow(filename+".tiff");
	run("Gaussian Blur...", "sigma=1.00");
	run("Threshold...");
    setThreshold(lower,upper);
    threshold_values=Array.concat(threshold_values,lower);
    threshold_values=Array.concat(threshold_values,upper);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Close");
	print("Threshold adjusted for "+filename);
	run("Watershed");
	print("Watershed finished for "+filename);
	roiManager("Deselect");
	selectWindow(filename+".tiff");
	run("Analyze Particles...", "size="+minsize+"-"+maxsize+" pixel circularity="+circularitymin+"-1.00 exclude clear include add");
	print("Particles analyzed for "+filename);
	print ("Time for cell recognition ="+(getTime-startT)/1000+"s");
	
	if (roiManager("count")>0){
		roiManager("save", finalimages+"segmentation/"+filename+".zip");
		// enlarge ROIs 
		selectWindow(filename+".tiff");
		run("Out [-]");
		run("Out [-]");

		counts=roiManager("count");
		for(i=0; i<counts; i++) {
		    roiManager("Select", i);
		    run("Enlarge...", "enlarge="+ensize+" pixel");
		    roiManager("Update");
		    progress = ((i+1)/counts)*100;
		    print("\\Update: ROIs updated: "+progress+" %");
		    
		}
		
		print ("Time for enlarged ROI generation ="+(getTime-startT)/1000+"s");
		print (counts+" cells have been detected for "+filename);
		roiManager("Deselect");
		roiManager("save", finalimages+"segmentation/"+filename+"_enlarged_cells.zip");
		selectWindow(filename+".tiff");
		saveAs("tiff", finalimages+"segmentation/"+filename+"_mask.tiff");
		close();	
	}else {
		exit("No cells detected for "+filename+"\n"+"check your segmentation channel!");
	}
	return counts;
}

function listFiles(dir) {
	list = getFileList(dir);
	allfiles = newArray();
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")){
			listFiles(""+dir+list[i]);
		}else{
			path=dir+list[i];
			total_filelist=Array.concat(total_filelist, path);
		}
	}
}

function deleteFiles(dir, ending, parent){
	listFiles(dir);
	for (i = 0; i < total_filelist.length; i++) {
		if (!endsWith(total_filelist[i],".tiff")) {
			print("\\Update:Deleting "+File.getParent(total_filelist[i]));
			File.delete(total_filelist[i]);
			if (parent==true) {
				print("\\Update:Deleting "+File.getParent(total_filelist[i]));
				File.delete(File.getParent(total_filelist[i]));
			}
		}
	}
}

function highlight_string(string, how){
	if (getInfo("os.name")=="Mac OS X"){
		String.resetBuffer;
		String.append("<html><"+how+">");
		String.append(string);
		String.append("</"+how+"></html>");
	}else {
		String.resetBuffer;
		String.append(string);
	}
	return String.buffer;
}

function highlight_message(string,how){
	if (getInfo("os.name")=="Mac OS X"){
		String.resetBuffer;
		String.append("<html><"+how+">");
		String.append(string);
		String.append("</"+how+"></html>");
		Dialog.addMessage(String.buffer);
	}else {
		size=10;
		if (how=="b"){size=15;}
		if (how=="i"){size=10;}
		Dialog.addMessage(string, size, "black");
	}
}

function aggregate_detection(name, filepath){
	setBatchMode(false);
	roiManager("deselect");
	setBatchMode(true);
	open(filepath);
	run("Duplicate...", "title="+name+"aggregate_mask.tiff");
	run("Unsharp Mask...", "radius=100 mask=0.5");
	run("Gaussian Blur...", "sigma=4");
	setAutoThreshold("Intermodes dark");
	run("Convert to Mask");
	run("Watershed");
	roiManager("reset");
	run("Analyze Particles...", "size=400-infinity pixel circularity=0.80-1.00 clear include add");
	run("Clear Results");
	roiManager("Measure");
	areas=newArray(nResults);
	excluded_aggregates=newArray(0);
	n_aggregates=0;
	for (i = 0; i < nResults; i++) {
		area=getResult("Area", i);
		if (area<1000) {
			Array.concat(excluded_aggregates,i);
		}
		if (excluded_aggregates.length>0) {
			roiManager("select", excluded_aggregates);
			roiManager("delete");
		}
	}
	n_aggregates=roiManager("count");
	run("Close All");
	
	if (n_aggregates>0) {
		setBatchMode(false);
		open(filepath);
		roiManager("show all with labels");
		choices = newArray("remove aggregates","don't remove aggregates");
		Dialog.create(n_aggregates+" Aggregates detected for "+name);
		Dialog.addChoice("How would you like to proceed?", choices);
		Dialog.show();
		run("Close All");
		setBatchMode(true);
		open(filepath);
		decision=Dialog.getChoice();
		if (decision=="remove aggregates") {
			remove_aggregates(name, filepath);
		}
	}
	run("Close All");
	close("Roi Manager");
	close("Results");
	return n_aggregates;
}

//Aggregate removal
function remove_aggregates(name, filepath){
	counts=roiManager("count");
	for(i=0; i<counts; i++) {
	    roiManager("Select", i);
	    run("Enlarge...", "enlarge=8 pixel");
	    roiManager("Update");
	}
	selectWindow(name+".tiff");
	run("Select None");
	run("Duplicate...", "title="+name+"_deleted.tiff");
	selectWindow(name+".tiff");
	if (counts>1) {
		roiManager("Select All");
		roiManager("Combine");
		roiManager("Add");
	}
	roiManager("Select", roiManager("count")-1);
	roiManager("Update");
	run("Clear", "slice");
	selectWindow(name+"_deleted.tiff");
	roiManager("Select", roiManager("count")-1);
	run("Make Inverse");
	roiManager("Add");
	roiManager("Select", roiManager("count")-1);
	roiManager("Update");
	run("Clear", "slice");
	selectWindow(name+".tiff");
	save(filepath);
	selectWindow(name+"_deleted.tiff");
	roiManager("deselect");
	save(substring(filepath, 0, lengthOf(filepath)-(lengthOf(name)+5))+name+"_removed_aggregates.tiff");
	run("Close All");
}
