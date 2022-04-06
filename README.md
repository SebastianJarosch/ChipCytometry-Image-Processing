# ChipCytometry Image Processing
Macros, data and code used in the Cell Reports Methods publication <i>Jarosch, Koehlen et al. Multiplexed imaging and automated signal quantification in formalin-fixed paraffin-embedded tissues by ChipCytometry</i> (https://doi.org/10.1016/j.crmeth.2021.100104). <br>
The analysis pipeline was developed for ChipCytometry data but usage with every other imaging data is implemented as well. (see image requirements for other imaging data at the end of this readme file).

![Image of Pipeline](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/image.jpg)

## System reqirements
* 32 Gb RAM (or more, depending on the size of the tissue sample)
* ImageJ 1.53o or higher <br>
* optional: <br>
  * *Matlab 2018b or higher* <br>
  * *Flow cytometry software for analyzing .fcs files* (e.g. FowJo)
  * *Python 3.7+ for clustering and neighborhood analysis* <br>


## Optional third party packages, plugins and scripts
* Scanpy (https://github.com/theislab/scanpy) <br>
* writeFCS (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other)
* BaSIC (https://github.com/marrlab/BaSiC)
* StarDist (https://github.com/stardist/stardist-imagej/)

## Getting started
* Install Fiji
* Download the scripts from this repository
* Run Plugins --> Install PlugIn... and select the automatic_image_processing.ijm file from this repository
* For segmentation using StarDist, you need to intall the plugin first 
* Transfer the MATLAB script as well as the writeFCS script in your matlab working directory
* For the installation of Scanpy refer to the original documentation (https://scanpy.readthedocs.io)

## Workflow
### 1. Image export
a) Adjust background and contrast value in Zellkraftwerk app in order to get the best snapshot from the HDR image. This step is crucial, the background needs to be as dark as possible. The true staining intensity might seem relativly dim but it will still be quantified as signal. <br>
b) Export images for each channel in the Zellkraftwerk app as 16-bit grayscale tiff images.<br>
c) Copy the Scanjob folders located in *Chipfolder/scanjobs/* for each channel in a new directory named with the chip ID. This directory will be the basis for the imageJ script. <b> The script should not be run on the original imaging files in order to avoid any data loss! </b> <br>
d) Rename the scanjob folders with their corresponding epitope names <br>
e) To save disk space, all files except .tiff and .png files can be deleted from the folder since only the .tiff images are needed for the analysis and .png files can be used for shading correction<br> This cleanup procedure can be automated with the ImageJ plugin as well.

#### Requirements for image data from other platforms
Images need to be stitched together resulting in one **grayscale TIFF-Image** per channel. All of these images need to be stored in the same directory, which is then selected while running the script. Make sure, that you select "stitched images" as input type in the first popup window.

### 2. Data generation in ImageJ
*Depending on the size of a chip and the number of segmented cells, the spillover correction can take up to 24 hours, so make sure that all parameters have been adjusted precisely and perform a test run without correction to check the input parameters first* <br><br>
a) Run the script automatic_image_processing.ijm in ImageJ <br>
b) If shading correction was selected, the single tiles will be corrected based on the FL images (non BG subtracted LDRFL.png). This step has to be monitored carefully in order to avoid any computation-derived artifacts. <br><br>
![Shading correction image](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/shading.jpg) <br><br>
c) Select channels and specify the parameters and press OK. Detailed description of all the different parameters can be found via the help button in the corresponding window. <br><br>
![Options image](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/options.jpg) <br><br>
d) If thresholding was selected as segmentation method: adjust the **lower threshold** when you are asked to, in order to adjust the segmentation to your DNA staining. If 'pretrained NN' was selected, the pretrained model will be applied directly on your nuclei staining channel. *Segmentation via the pretrained NN leads to a better segmentation efficiency but is therefore also more prone to oversegmentation.* <br><br>
![Segmentation image](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/segmentation.jpg) <br>

### 3. Quality control
a) Check the stitched images in Results/stitching to see if they are in a good quality for all sub-positions<br>
b) You can review the segmentation by loading the stitched nuclei image and the saved ROIs from Results/segmentation into imageJ or by simply reviewing the mask image from the segmentation folder. 

### 4. Write FCS files in MATLAB
*Here we provide a script for matlab, but of course, the conversion can also be performed with other method for the converion of .fcs files from a cell x parameter input. A Python alternative for example would be the fcswrite method found in this repository: https://github.com/ZELLMECHANIK-DRESDEN/fcswrite. This function resulted in an identical .fcs file, when we compared it to the matlab script.* <br><br>
a) Copy the FL_values.csv and channels.csv from the generated Results folder in your MATLAB working directory <br>
b) Run the script FCS_conversion_ChipCytometry.m <br>
c) The ChipID.fcs file will be written in your MATLAB working directory and can be analyzed with any flow cytometry analysis software

## Clustering of cells and neighborhood analysis using scanpy
Scanpy was developed by the Theis laboratory for analyzing single cell RNA (scRNA) sequencing data and is one of the leading packages in this field. Here we feed in a [cells x proteins] matrix instead of the [cells x genes] matrix to use the pipeline for our imaging data. Cells and their fluorescence values can be imported into scanpy as adata object via the FL_values.csv and channels.csv files. An example of how to process data can be found in clustering_chipcytometry_cells.ipynb. For further information on the API of the scanpy package, check the scanpy documentation (https://scanpy.readthedocs.io).<br>

## Sample data
The folder sample data contains Chipcytometry data from an inflamed human colon biopsy shown in Figure 2 of the paper.

## Input requirements for other imaging data
* Stitched grayscale images for each channel (.tiff convertable)
* All images need to be present in one folder to run the automatic analysis

## References
1. Wolf, F., Angerer, P. & Theis, F. SCANPY: large-scale single-cell gene expression data analysis. Genome Biol 19, 15 (2018). https://doi.org/10.1186/s13059-017-1382-0
2. Schindelin, J., Arganda-Carreras, I., Frise, E. et al. Fiji: an open-source platform for biological-image analysis. Nat Methods 9, 676–682 (2012). https://doi.org/10.1038/nmeth.2019
2. Schmidt, U., Weigert, M., Broaddus, C., Myers, G. Cell Detection with Star-convex Polygons. MICCAI (2018). https://doi.org/10.1007/978-3-030-00934-2_30
3. Lin J-R, Izar B, Wang S, Yapp C, Mei S, Shah P, Santagata S, Sorger PK. Highly multiplexed immunofluorescence imaging of human tissues and tumors using t-CyCIF and conventional optical microscopes. eLife. 2018 Jul 11;7:e31657. https://doi.org/10.7554/eLife.31657 
4. Jakub Nedbal. writeFCS(fname, DATA, TEXT, OTHER) (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other), MATLAB Central File Exchange. Retrieved June 24, 2020. 
