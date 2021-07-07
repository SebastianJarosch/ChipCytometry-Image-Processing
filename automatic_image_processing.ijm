//Run script to enable y-Overlap in the stitching Plug-In
//If you are running the script for the first time, you will be asked to restart imageJ
eval("bsh", "plugin.Stitching_Grid.seperateOverlapY = true;");

//specify input format
Dialog.create("Specify data input");
datatypes=newArray("Chipcytometry","stitched images");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Datatype", datatypes, "Chipcytometry");
Dialog.show();

//Get values from the dialog
datatype=Dialog.getChoice();


//choose the directory where the raw images are stored and try to catch the ChipID
pathraw=getDirectory("Choose the directory for raw data");
ChipID=substring(pathraw, lengthOf(pathraw)-8, lengthOf(pathraw)-1);
if (datatype!="Chipcytometry") {ChipID="ChipID";}

//get the markers which are present in the subfolder of the path with rawdata
folders=getFileList(pathraw);
markernumber=folders.length;
folders_original=Array.copy(folders);
//Check if the chip has already been analyzed by searching for the "Results" folder
for (i = 0; i < markernumber; i++) {
	folders[i]=substring(folders[i], 0, lengthOf(folders[i])-1);
	if (datatype!="Chipcytometry") {
		temp_strings=split(folders[i], ".");
		folders[i]=temp_strings[0];
	}
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
tissues=newArray("cells","colon","spleen/LN","stomach","pancreas","breast");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Organism", organisms, "human");
Dialog.addChoice("Tissue", tissues, "colon");
Dialog.setInsets(10, 0, 0);
if (datatype=="Chipcytometry") {
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
}
Dialog.addHelp("<html><b>Chip & tissue properties</b><br>The selection of the tissue type will affect the default values for some parameters, like the enlargement of ROIs "+
"which is reduced in denser tissues to avoid spillover from neighboring cells.<br><br><b>Size of the tissue section</b><br>The size in tiles can be evaluated from the Cell Explorer App by looking at the overview image. "+
"the y size needs to be specified starting from the first tile.<br><br><b>Clean folder</b><br>Deletes the folders <cite>posref</cite>, <cite>flimages</cite>, as well as the <cite>.blob32, .xml, .png</cite> and <cite>.csv</cite> files. "+
"The only files remaining are the .tiff files in the HDRFL folders for each position.<br><br><b>For additional information, refer to the documentation</b><br><a href>https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/README.md</a></html>");
Dialog.show();

//Get values from the dialog
ChipID=Dialog.getString();
organism=Dialog.getChoice();
tissue=Dialog.getChoice();
clean=false;
if (datatype=="Chipcytometry") {
	xsize=Dialog.getNumber();
	ysize=Dialog.getNumber();
	firsttile=Dialog.getNumber();
	clean=Dialog.getCheckbox();
}
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
	chbxlables[i+2]="FISH";
	defaults[i] = true;
	if(folders[i/3]=='DNA'||folders[i/3]=='Nuclei'||folders[i/3]=='FoxP3'||folders[i/3]=='GATA3'||folders[i/3]=='GATA-3'||folders[i/3]=='Ki67'){
		defaults[i+1] = true;
	}else {
		defaults[i+1] = false;
	}
	if(matches(folders[i/3], "mRNA")){
		defaults[i+2] = true;
	}else {
		defaults[i+2] = false;
	}
}
Dialog.addCheckboxGroup(markernumber, 3, chbxlables, defaults);
Dialog.addHelp("<html><b>Marker checkboxes</b> (left side)<br>Here the markers which should be included in the quantification should be selected. "+
"Please make sure at this point, that all markers have been aquired with a good quality and the backrund subtraction worked properly for all markers.<br><br>"+
"<b>Intranuclear</b> (middle)<br>If the marker is located intranuclear, the checkbox needs to be selected. This selection will change the processing of images before quantification and will decide "+
"if spacial spillover correction is performed on the marker.<br><br><b>FISH</b> (right side)<br>If the channel is derived from RNA in-situ hybridisation, selcet this checkbox. " +
"It will result in an alternative quantification algorithm. <i>Not validated yet and very slow for the moment!</i>"+
"<br><br><b>For additional information, refer to the documentation</b><br><a href>https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/README.md</a></html>");
Dialog.show();

//Get values from the dialog
marker=newArray(markernumber);
intranuclear_0=newArray(markernumber);
fish_0=newArray(markernumber);
markernumber_total=0;
for (i = 0; i < markernumber; i++) {
	marker[i]=Dialog.getCheckbox();
	intranuclear_0[i]=Dialog.getCheckbox();
	fish_0[i]=Dialog.getCheckbox();
	if (marker[i]==true) {
		markernumber_total++;
	}
}
folders_new=newArray(markernumber_total);
intranuclear=newArray(markernumber_total);
fish=newArray(markernumber_total);
j=0;
for (i = 0; i < markernumber; i++) {
	if (marker[i]==true) {
		intranuclear[j]=intranuclear_0[i];
		fish[j]=fish_0[i];
		folders_new[j]=folders[i];
		j++;
	}
}
folders=folders_new;

//Create dialog with options for analysis
Dialog.create("Specify analysis");
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Extract Erys from AF","b"), true);
choices=Array.concat(folders,"*None*");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("BG channel", folders, occurance_in_array(folders, newArray("PerCP_BG","PerCP","BG","Erys","Erys_AF","*None*")));
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Aggregate removal","b"), false);
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Create merge image","b"), true);
Dialog.setInsets(0, 0, 0);
Dialog.addCheckbox(highlight_string("Segmentation","b"), true);
segmentation_methods=newArray("thresholding","pretrained NN");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Segmentation_method", segmentation_methods, "thresholding");
nuclei_names=newArray("Nuclei","DNA","Hoechst");
Dialog.setInsets(0, 0, 0);
Dialog.addChoice("Nuclei staining", folders, occurance_in_array(folders, nuclei_names));
sepepithel=false;

if (tissue=="colon"||tissue=="pancreas"||tissue=="breast"||tissue=="stomach") {
	choices=Array.concat(folders,"No staining");
	epithelial_names=newArray("PAN","Cytokeratin","PAN-Cytokeratin","EpCAM","No staining");
	Dialog.setInsets(0, 0, 0);
	Dialog.addChoice("Epithelial cells", choices, occurance_in_array(folders, epithelial_names));
	sepepithel=true;
}
ensize=3;
if (tissue=="spleen/LN"||tissue=="cells") {
	ensize=2;
	cytokeratin="No staining";
}
Dialog.addNumber("Enlarge ROIs by", ensize,0,4, "pixel");
Dialog.setInsets(15, 0, 0);
Dialog.addCheckbox(highlight_string("FL-Value calculation","b"), true);
Dialog.addCheckbox(highlight_string("Remove outliers","u"), true);
Dialog.addNumber(highlight_string("Radius ","i"), 2,0,4,"pixel");
Dialog.addNumber(highlight_string("Threshold ","i"), 50,0,4,"");
Dialog.addCheckbox(highlight_string("Minimum filter","u"), true);
Dialog.addNumber(highlight_string("Radius ","i"), 0.5,0,4,"pixel");
Dialog.addCheckbox(highlight_string("Subtract background","u"), true);
Dialog.addNumber(highlight_string("Rolling ball radius ","i"), 10,0,4,"pixel");
if (datatype=="Chipcytometry") {
	Dialog.setInsets(15, 0, 0);
	Dialog.addCheckbox(highlight_string("Marker consistancy check","b"), true);
}
if (tissue!="cells"){
	Dialog.setInsets(15, 0, 0);
	Dialog.addCheckbox(highlight_string("Measure tissue size","b"), true);
	Dialog.setInsets(15, 0, 0);
	Dialog.addCheckbox(highlight_string("Spatial spillover correction","b"), true);
	Dialog.addNumber("Threshold", 60, 0, 4, "%");
	Dialog.addNumber("Min intensity", 100, 0, 4, "");
}
fish_marker=Array.sort(fish);
Dialog.setInsets(15, 0, 0);
if (fish_marker[lengthOf(fish)-1]==1){
	Dialog.addNumber(highlight_string("FISH marker threshold ","b"),500,0,4,"");
}
Dialog.addHelp("<html><b>Erythrocyte extraction</b><br>Erythrocytes can be detected from a early PerCP Background channel and will be segmented for quantification as well. "+
"Select the channel from the list of processed channels for erythrocyte detection. This channel will also be used for intensity quantifications later on.<br>"+
"<br><b>Aggregate removal</b><br><cite>Implemented, but not validated yet. This beta version can be tested if markers are prone to have a high number of dye aggregates.<br><br></cite>"+
"<b>Create merge image</b><br>To get an overview about the tissue architechture, up to 7 channels can be merged in this step. You will be asked to select them after the stitching is finished. "+
"By default, Vimentin, SMA, Nuclei and Cytokeratin are selected here. Channels can be weighted by a factor where 1 means a default merge of the full-intensity image.<br><br>"+
"<b>Segmentation</b><br>here you need to choose your segmentationmarker and the marker for epithelial cells, if you have selected a tissue type "+
"containing epithelial cells. In case no epithelial cell staining was performed, you can choose <cite>no staining</cite> and a one marker segmentation will be performed.<br><i>Pretrained NN requires stardist to be installed. "+
"See documenation under the following link: <a href>https://github.com/stardist/stardist-imagej/</a><br><br>"+
"<b>FL-value calculation</b><br>Here specific parameters can be adjusted for preprocessing surface-Marker images. The default values have been tested and titrated, so they "+
"resemble a good starting point.<br><br><b>Marker consistancy check</b><br>This checks, if images are available for all positions in all markers. If this is not the case, you can "+
"choose to delete images, which are only present for some markers but not for others.<br><br><b>Measure tissue size</b><br>Measurement of the tissue size in square mm allows the "+
"relative quantification of gated populations within the tissue in downstream analysis<br><br><b>Spatial spillover correction</b><br>The threshold defines, which percentage of "+
"signal is maximal allowed to be present in only one quater of the cell. The min intensity is the min grayscale value, for which a cell is considered for spacial spillover "+
"correction.<br><i>This option will not appear if 'cells' were selected as tissue type</i><br><br><b>For additional information, refer to the documentation</b><br><a href>https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/README.md</a></html>");
Dialog.show();

//Get values from the dialog
erys=Dialog.getCheckbox();
ery_channel=Dialog.getChoice();
if (erys==false){ery_channel='NoChannelSelected';}
detect_aggregates=Dialog.getCheckbox();
mergeimages=Dialog.getCheckbox();
segmentationstatus=Dialog.getCheckbox();
segmentationmethod=Dialog.getChoice();
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
subtract_BG=Dialog.getCheckbox();
rolling_radius=Dialog.getNumber();
if (datatype=="Chipcytometry") {checkconsistancy=Dialog.getCheckbox();
}

//The following options are only displayed, if the tissue type is not single cells
if (tissue!="cells"){
	tissue_size=Dialog.getCheckbox();
	spillovercorrection=Dialog.getCheckbox();
	distribution_threshold=Dialog.getNumber();
	minCorrInt=Dialog.getNumber();
	distribution_threshold=distribution_threshold/25;
}else {
	tissue_size=false;
	spillovercorrection=false;
}
if (fish_marker[lengthOf(fish)-1]==1){
	minFishInt=Dialog.getNumber();
}
error_cells=newArray();
emptypositions = false;
inconsistant = false;


if (datatype=="Chipcytometry") {
	totalpositions=xsize*ysize+(firsttile-1);
	//Check for conistancy of positions between markers, using the segmentation marker as refference
	segmentationmarkerpositions = getFileList(pathraw+"/"+segmentationmarker);
	for (j = 0; j < segmentationmarkerpositions.length; j++) {
			segmentationmarkerpositions[j]=substring(segmentationmarkerpositions[j], 0, lengthOf(segmentationmarkerpositions[j])-1);
	}
	
	positions = newArray();
	for (i = 0; i < markernumber_total; i++) {
		
		filelist = getFileList(pathraw+folders[i]);
		missing=newArray();
		for (j = 0; j < lengthOf(filelist); j++) {
			subdir=getFileList(pathraw+folders[i]+"/"+filelist[j]);
			if (lengthOf(subdir)!=0){
				subsubdir=getFileList(pathraw+folders[i]+"/"+filelist[j]+subdir[0]);
			}
else{
				subsubdir=newArray();
			}
			if (lengthOf(subsubdir)==0) {
				missing=Array.concat(missing,newArray(substring(filelist[j],0,lengthOf(filelist[j])-1)));
			}
		}
		if (lengthOf(missing)>0) {
			print(folders[i]+" images missing for the following positions:");
			Array.print(missing);
			emptypositions=true;
		}
	}
	if (emptypositions==true && checkconsistancy == true){
		waitForUser("Missing images detected. Please check your input folder according to the log file");
		exit();
	}
	
	for (i = 0; i < markernumber_total; i++) {
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
			for (i = 0; i < markernumber_total; i++) {
				if(folders[i] != segmentationmarker){
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
		for (i = 0; i < markernumber_total; i++) {
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
for (i = 0; i < markernumber_total; i++) {
		print(folders[i]);
}
selectWindow("Log");
saveAs("Text", pathraw+"channels.csv"); 

//Initialize time values
Tempty = 0;
Trenaming = 0;
Tstitching = 0;
Tsegmentation = 0;
Troiprocessing = 0;
Tcalculation = 0;
startTtotal = getTime();
startT = getTime;

if (datatype=="ChipCytometry") {
	//Print initial values to Log
	print("size_x = "+xsize);
	print("size_y = "+ysize);
	print("first tile for stitching = "+firsttile);
	print("Number of positions to be stitched = "+totalpositions);
	print("Segmentation: "+segmentationstatus);
	print("Segmentationmarker: "+segmentationmarker);
	print("FL-calculation: "+valuecalculation);
	Array.print(marker);
	
	
	//generate black images for stitching which cover the whole area
	setBatchMode(true);
	for (i = firsttile; i <= totalpositions; i++) {
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
	for (j = 0; j < markernumber_total; j++) {
		setBatchMode(true);
		print(folders[j]);
		print("");
		for (i = firsttile; i <= totalpositions; i++) {
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
		"regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] "+
		"image_output=[Write to disk]");
		File.makeDirectory(pathraw+"Results");
		open(pathraw+"img_t1_z1_c1");
		saveAs("tiff", pathraw+"Results/"+folders[j]+".tiff");
		close();
		File.delete(pathraw+"img_t1_z1_c1");
		Tstitching = Tstitching+((getTime-startT)/1000);
	}
	
	//delete unstiched images
	for (i = firsttile; i <= totalpositions; i++) {
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
}
else {
	File.makeDirectory(pathraw+"Results");
	for (j = 0; j < markernumber_total; j++) {
		setBatchMode(true);
		open(pathraw+folders_original[j]);
		run("16-bit");
		name=split(folders_original[j], ".");
		saveAs("Tiff", pathraw+"Results/"+name[0]+".tiff");
		close();
	}
}


//Extract erys from autofluorescence
if (erys==true){
	print("Started erythrocyte detection...");
	open(pathraw+"Results/"+ery_channel+".tiff");
	run("Duplicate...", "title=Erymask.tiff");
	run("Threshold...");
	getThreshold(lower,upper);
    setThreshold(15000,upper);
	setOption("BlackBackground", true);
	close("Threshold");
	print("BG channel processed for erythrocyte detection");
	roiManager("reset");
	run("Analyze Particles...", "size=100-infinity pixel clear include add");
	vesselcount=roiManager("count");
	print(vesselcount+" vessels have been detected");
	selectWindow(ery_channel+".tiff");
	if (vesselcount>1) {
		roiManager("Select All");
		roiManager("Combine");
		roiManager("Add");
		roiManager("Select", roiManager("count")-1);	
		run("Make Inverse");
		roiManager("Add");
		roiManager("Select", roiManager("count")-1);
		roiManager("Update");
		run("Clear", "slice");
		save(pathraw+"Results/"+ery_channel+".tiff");
		run("Close All");
		print("Erythrocyte detection finished...");
	}
else {
		print("No vessels detected...");
		erys=false;
	}
}

//get file list for all stiched images
finalimages=pathraw+"Results/";
files=getFileList(finalimages);

//Perform aggregate detection and removal
total_aggregate_count=0;
if (detect_aggregates==true){print("Start aggregate detection...");}
for (i = 0; i < files.length; i++) {
	name=substring(files[i],0,lengthOf(files[i])-5);
	if (name!=segmentationmarker && name!=cytokeratin && name!=ery_channel && intranuclear[i]!=true) {
		if (detect_aggregates==true){
			filepath=finalimages+files[i];
			number_of_aggregates = aggregate_detection(name, filepath);
			print(name+": "+number_of_aggregates+" aggregates have been detected");
			total_aggregate_count=total_aggregate_count+number_of_aggregates;
		}
	}
}
File.makeDirectory(finalimages+"stitching");
for (i = 0; i < markernumber_total; i++) {
	if (detect_aggregates==true) {
		File.makeDirectory(pathraw+"/Results/stitching/Aggregate_removal");
		File.rename(finalimages+folders[i]+"_removed_aggregates.tiff", pathraw+"/Results/stitching/Aggregate_removal/"+folders[i]+"_removed_aggregates.tiff");
		File.rename(finalimages+folders[i]+"_removed_aggregates.zip", pathraw+"/Results/stitching/Aggregate_removal/"+folders[i]+"_removed_aggregates.zip");
	}
}


//Create merge image
if (mergeimages == true){
	colors=newArray("Red","Green","Blue","Gray","Cyan","Magenta","Yellow");
	items=getFileList(pathraw+"Results/");
	items=Array.deleteValue(items, "stitching/");
	for (i = 0; i < items.length; i++) {
		items[i]=substring(items[i], 0, lengthOf(items[i])-5);
	}
	items=Array.concat(items,"*None*");
	Dialog.create("Define channels for merged image");
	default_choices=newArray("Vimentin","*None*","Cytokeratin","Nuclei","*None*","*None*","SMA");
	if (erys==true) {default_choices=newArray("Erys_AF","*None*","Cytokeratin","Nuclei","Vimentin","*None*","SMA");}
	default_weights=newArray(1,1,1,0.5,1,1,1);
	if (erys==true) {default_weights=newArray(1,1,1,0.5,0.7,1,1);}
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
File.makeDirectory(finalimages+"segmentation");

if (segmentationstatus == true) {

	var threshold_values=newArray();
	startT=getTime();
	open(finalimages+segmentationmarker+".tiff");

	//Measure tissue size
	if (tissue_size==true) {
		print("Measuring the size of the tissue section...");
		run("Duplicate...", "title=tissue_size.tiff");
		run("Gaussian Blur...", "sigma=20");
		setAutoThreshold("Mean dark");
		run("Convert to Mask");
		roiManager("reset");
		run("Analyze Particles...", "size=10000-infinity pixel clear include add");
		run("Clear Results");
		roiManager("Measure");
		area=0;
		for (i = 0; i < nResults; i++) {
			area=area+getResult("Area", i);
		}
		File.makeDirectory(finalimages+"segmentation/"+"tissue_size");
		selectWindow("tissue_size.tiff");
		saveAs("tiff", finalimages+"segmentation/tissue_size/tissue_size_mask.tiff");
		roiManager("save", finalimages+"segmentation/tissue_size/area_ROIs.zip");
		roiManager("reset");
		close("Results");
		close("*");
	}

	print("starting segmentation");

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
		if (segmentationmethod == "thresholding"){
			epithelialcellnumber=segmentation(ensize,true,"Epithel",7000,65535,75,2000,0.2);
			LPcellnumber=segmentation(ensize,true,"Lamina_propria",3000,65535,70,400,0.55);
		}
		if (segmentationmethod == "pretrained NN"){
			epithelialcellnumber=segmentation_stardist(ensize,"Epithel");
			LPcellnumber=segmentation_stardist(ensize,"Lamina_propria");
		}
		cellnumber=0;
		
	}else {
	// Generate Mask/ROI
	run("Duplicate...", "title=all.tiff");
	if (tissue=="cells") {run("Subtract Background...", "rolling=10");}
	saveAs("tiff", finalimages+"segmentation/all.tiff");
	run("Close All");
	if (tissue=="cells") {
			if (segmentationmethod == "thresholding"){cellnumber=segmentation(ensize,true,"all",3000,65535,50,2000,0.75);}
			if (segmentationmethod == "pretrained NN"){cellnumber=segmentation_stardist(ensize,"all");}
	}else {
			if (segmentationmethod == "thresholding"){cellnumber=segmentation(ensize,true,"all",3000,65535,70,400,0.55);}
			if (segmentationmethod == "pretrained NN"){cellnumber=segmentation_stardist(ensize,"all");}
	}
	epithelialcellnumber=0;
	LPcellnumber=0;
	}
	if (erys==true) {
		open(finalimages+ery_channel+".tiff");
		saveAs("tiff", finalimages+"segmentation/Erythrocytes.tiff");
		erycellnumber=segmentation(1,false,"Erythrocytes",20000,30000,15,400,0.25);
	}


	
	Tsegmentation = Tsegmentation+((getTime-startT)/1000);
	
	if (valuecalculation == 1) {
		
		//get file list for all stiched images
		files=getFileList(finalimages);
		files=Array.delete(files, "stitching/");
		files=Array.delete(files, "segmentation/");
		
		startT = getTime;
		roiManager("reset");
		if (sepepithel == true){
			roiManager("open", finalimages+"segmentation/Lamina_propria_enlarged_cells.zip")
			roiManager("open", finalimages+"segmentation/Epithel_enlarged_cells.zip")
		}
		if (sepepithel == false){
			roiManager("open", finalimages+"segmentation/all_enlarged_cells.zip")
		}
		if (erys == true){
			roiManager("open", finalimages+"segmentation/Erythrocytes_enlarged_cells.zip")
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
			print("Starting value calculation for "+slicename);
			
			if (fish[i-1]!=true) {
				//Correct the surfacemarkers to get them less blurry
				if(outlier_correction==true){
					print("\\Update: Performing outlier correction...");
					run("Remove Outliers...", "radius="+outlier_radius+" threshold="+outlier_threshold+" which=Bright");
				}
				if(minimum_correction==true && intranuclear[i-1]!=true){
					print("\\Update: Performing minimum correction...");
					run("Minimum...", "radius="+minimum_radius);
				}
				if(subtract_BG==true){
					print("\\Update: Subtracting BG for marker "+i+"/"+slices+" ("+slicename+")...");
					run("Subtract Background...", "rolling="+rolling_radius);
				}
	
				//Perform spillovercorrection for all cells
				if (spillovercorrection==true && intranuclear[i-1]!=true && slicename!=ery_channel){
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
			}else {
				print("\\Update: Subtracting BG for FISH-marker "+i+"/"+slices+" ("+slicename+")...");
				run("Subtract Background...", "rolling=5");
			}


			//Finally get the Mean intensity for all cells and all markers
			print("\\Update: Calculating values for marker "+i+"/"+slices+" ("+slicename+")...");
			if (slicename != "Erythrocytes"){
				roiManager("Select All");
				roiManager("Measure");
				if (fish[i-1]==true) {
					File.makeDirectory(finalimages+"segmentation/FISH/");
					total_cells=roiManager("count");
					resultsarray=newArray(total_cells);
					for (j = 0; j < total_cells; j++) {
						roiManager("select", j);
						run("Duplicate...","ROI");
						kurt=getValue("Kurt");
						if (kurt > 0) {
							if (parseFloat(getValue("Mean")) > minFishInt){
								run("Make Inverse");
								run("Clear", "slice");
								run("Select None");
								mean=getValue("Mean");
								setThreshold(10000, 55000);
								run("Convert to Mask");
								run("Ultimate Points");
								setThreshold(1, 255);
								run("Convert to Mask");
								run("Analyze Particles...", "size=0-1 summarize include");
								resultsarray[j]=(parseInt(Table.getString("Count", 0))-1)*mean;
								if (resultsarray[j]<0) {resultsarray[j]=0;}
								Table.reset("Summary");
							}
						}else {resultsarray[j]=0;}
						close();
						progress=((j+1)/total_cells)*100;
					    print("\\Update: Segmenting mRNA for marker "+i+"/"+slices+" ("+slicename+") "+progress+"% ...");
					}
					for (j = 0; j < total_cells; j++) {
						setResult("Mean", nResults-total_cells+j, resultsarray[j]);
						progress=((j+1)/total_cells)*100;
						print("\\Update: Calculating values for marker "+i+"/"+slices+" ("+slicename+") "+progress+"% ...");
					}
					updateResults();
				}
			}
			run("Next Slice [>]");
		}

		//Save the stitched images with the deleted signals for each marker
		File.makeDirectory(finalimages+"stitching/spacialcorrected/");
		pathspatialcorrected=finalimages+"stitching/spacialcorrected/";
		run("Image Sequence... ", "format=TIFF use save=pathspatialcorrected");
		selectWindow("Results");
		saveAs("Results", finalimages+"segmentation/FL_values.csv");
		run("Close");
		close("Results");
		close("Summary");
		Tcalculation = Tcalculation+((getTime-startT)/1000);
	}
}

//cleanup of files and move to subfolders
run("Close All");
for (i = 0; i < markernumber_total; i++) {
	File.rename(finalimages+folders[i]+".tiff",finalimages+"stitching/"+folders[i]+".tiff");
}
File.rename(finalimages+"Erythrocytes.tiff",finalimages+"stitching/Erythrocytes.tiff");
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
if (tissue_size == true && tissue != "cells" && segmentationstatus == true){print("Area of the tissue: "+area+" pixel --> "+(area/4000000)+" mm2");}
if (inconsistant == true || emptypositions==true){
	print("WARNING: Inconsistancy in markers detected !!!");
}
if (datatype=="Chipcytometry") {
	print("Size of the stiched image: "+xsize+" x "+ysize);
	print("Number of the first image: "+firsttile);
	print("Number of positions to be stitched: "+((xsize*ysize)-(firsttile-1)));
	print("Time for generating empty positions: "+Tempty+" s");
	print("Time for renaming positions: "+Trenaming+" s");
}
print("Markers analyzed: "+markernumber_total);
Ttotal = (getTime-startTtotal)/60000;
print("Total time needed for the automatic processing: "+Ttotal+" min");

if (datatype=="Chipcytometry") {
	print("************************************************************************************");
	print("---------------------------------Stitching----------------------------------------");
	print("Time for stitching: "+Tstitching+" s");

}
if (erys==true) {
	print("Erythrocytes were detected from "+ery_channel);
}

if (mergeimages==true) {
	print("The following channels have been merged to a RGB image:");
	String.resetBuffer;
	for (i = 0; i < imageselection.length; i++) {
		if (imageselection[i]!="*None*.tiff") {
			String.append(substring(imageselection[i],0,lengthOf(imageselection[i])-5)+"("+colors[i]+") ");
		}
	}
	print(String.buffer);
}

if (segmentationstatus == 1) {
	print("************************************************************************************");
	print("------------------------------Segmentation-------------------------------------");
	print("Method used for segmentation: "+segmentationmethod);
	if (sepepithel == true) {print("seperate segmentation of epithelial cells and lamina propria");}
	print("Segmentationmarker: "+segmentationmarker);
	if (sepepithel == true) {print("epithelial cell marker: "+cytokeratin);}
	print("Enlargement of ROIs: "+ensize+" pixel");
	if (segmentationmethod == "thresholding"){
		if (sepepithel == true) {print("Number of epithelial cells: "+epithelialcellnumber+"; Threshold = ("+threshold_values[0]+"/"+threshold_values[1]+")");}
		if (sepepithel == true) {print("Number of lamina propria cells: "+LPcellnumber+"; Threshold = ("+threshold_values[2]+"/"+threshold_values[3]+")");}
	}
	if (segmentationmethod == "pretrained NN"){
		if (sepepithel == true) {print("Number of epithelial cells: "+epithelialcellnumber);}
		if (sepepithel == true) {print("Number of lamina propria cells: "+LPcellnumber);}
	}
	if (erys == true && sepepithel == true) {print("Number of Erythrocytes: "+erycellnumber+"; Threshold = ("+threshold_values[4]+"/"+threshold_values[5]+")");}
	totalcellnumber=epithelialcellnumber+LPcellnumber+cellnumber;
	print("Total cells segmented: "+totalcellnumber);
	if (erys==true) {
		print(erycellnumber+" heve been segmented in "+vesselcount+" vessels");
	}
	if (sepepithel == false && segmentationmethod == "thresholding") {print("Threshold = ("+threshold_values[0]+"/"+threshold_values[1]+")");}
	if (erys == true && sepepithel == false) {print("Number of Erythrocytes: "+erycellnumber+"; Threshold = ("+threshold_values[2]+"/"+threshold_values[3]+")");}
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
	if (detect_aggregates==true) {
		print("Aggregate detection has been performed for all channels");
		print(total_aggregate_count+" aggregates have been detected in total");
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

function index(a, value) {
	for (i=0; i<a.length; i++)
		if (a[i]==value) {return i;}
	return -1;
}

function segmentation(ensize, blur, filename, lower_threshold, upper_threshold, minsize, maxsize, circularitymin) {
	//Let the user adjust the default threshold for the nuclei
	setBatchMode(false);
	open(finalimages+"segmentation/"+filename+".tiff");
	selectWindow(filename+".tiff");
	if (blur==true) {run("Gaussian Blur...", "sigma=1.00");
}
	run("Threshold...");
	setAutoThreshold("Yen dark");
	getThreshold(lower,upper);
    setThreshold(lower_threshold,upper_threshold);
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

function segmentation_stardist(ensize, filename) {
	//Let the user adjust the default threshold for the nuclei
	open(finalimages+"segmentation/"+filename+".tiff");
	selectWindow(filename+".tiff");
	if (datatype=="Chipcytometry") {ntiles=((xsize*ysize)-(firsttile-1));}
	if (datatype=="stitched images") {ntiles=((round(getWidth()/1392)+1)*(round(getHeight()/1040)+1));}
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':"+filename+".tiff, 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.6499999999999999', 'nmsThresh':'0.3', 'outputType':'ROI Manager', 'nTiles':'"+ntiles+"', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'true', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
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
			print("\\Update:Deleting "+total_filelist[i]);
			File.delete(total_filelist[i]);
			if (parent==true) {
				print("\\Update:Deleting "+File.getParent(total_filelist[i]));
				File.delete(File.getParent(total_filelist[i]));
				showProgress(i, total_filelist.length);
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
	run("Measure");
	expression_density=getResult("Mean", 0);
	if (expression_density < 1500){
		run("Clear Results");
		run("Duplicate...", "title="+name+"aggregate_mask.tiff");
		run("Unsharp Mask...", "radius=100 mask=0.5");
		run("Gaussian Blur...", "sigma=4");
		setThreshold(30000, 65535);
		run("Convert to Mask");
		run("Watershed");
		roiManager("reset");
		run("Analyze Particles...", "size=200-infinity pixel circularity=0.00-1.00 clear include add");
		counts=roiManager("count");
		for(i=0; i<counts; i++) {
		    roiManager("Select", i);
		    run("Enlarge...", "enlarge=9 pixel");
		    roiManager("Update");
		}
		run("Clear Results");
		selectWindow(name+".tiff");
		roiManager("deselect");
		roiManager("Measure");
		excluded_aggregates=newArray(0);
		n_aggregates=0;
		for (i = 0; i < nResults; i++) {
			area=getResult("Area", i);
			circ=getResult("Circ.", i);
			mean=getResult("Mean", i);
			kurtosis=getResult("Kurt", i);
			int_den=getResult("IntDen", i);
			if (circ<0.8 || area<400 || mean < 5000 || kurtosis > 0||int_den > 50000000) {
				excluded_aggregates=Array.concat(excluded_aggregates,i);
			}
		}
		if (excluded_aggregates.length>0) {
			roiManager("select", excluded_aggregates);
			roiManager("delete");
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
	}else {
		print("marker is too broadly expressed for aggregate detection");
		n_aggregates=0;
	}
	run("Close All");
	close("Roi Manager");
	close("Results");
	return n_aggregates;
}

//Aggregate removal
function remove_aggregates(name, filepath){
	counts=roiManager("count");
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
	roiManager("save", substring(filepath, 0, lengthOf(filepath)-(lengthOf(name)+5))+name+"_removed_aggregates.zip");
	roiManager("reset");
	run("Clear Results");
	run("Close All");
}
