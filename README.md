# ChipCytometry Image Processing
Macros, data and code used in the publication <i>Jarosch, Koehlen et al. Automated in-situ cell neighborhood analysis by highly multiplexed ChipCytometry</i>

![Image of Pipeline](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/image.jpg)

## System reqirements
* 32 Gb RAM (or more, depending on the size of the tissue sample)
* ImageJ 1.53c or higher <br>
* Matlab 2018b or higher <br>
* Python 3.7+ for clustering and neighborhood analysis <br>
* Flow cytometry software for analyzing .fcs files (e.g. FowJo)

## Third party packages, plugins and scripts
* Scanpy (https://github.com/theislab/scanpy) <br>
* writeFCS (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other)

## Getting started
* Install Fiji
* Download the scripts from this repository
* Run Plugins --> Install PlugIn... and select the automatic_image_processing.ijm file from this repository
* Transfer the MATLAB script as well as the writeFCS script in your matlab working directory
* For the installation of Scanpy refer to the original documentation (https://scanpy.readthedocs.io)

## Workflow
### 1. Image export
a) Adjust background and contrast value in Zellkraftwerk app in order to get the best snapshot from the HDR image <br>
b) Export images for each channel in the Zellkraftwerk app as 16-bit grayscale tiff images.<br>
c) Copy the Scanjob folders located in *Chipfolder/scanjobs/* for each channel in a new directory named with the chip ID. This directory will be the basis for the imageJ script. <b> The script should not be run on the original imaging files in order to avoid any data loss! </b> <br>
d) Rename the scanjob folders with their corresponding epitope names <br>
e) To save disk space, all "flimages" and "posref" folders can be deleted as well as all .xml, .blob32 and .png files from the folder since only the .tiff images are needed for the analysis <br> This cleanup procedure can be automated with the ImageJ plugin as well.

### 2. Data generation in ImageJ
*Depending on the size of a chip and the number of segmented cells, the spillover correction can take up to 24 hours, so make sure that all parameters have been adjusted precisely and perform a test run without correction to check the input parameters first* <br><br>
a) Run the script automatic_image_processing.ijm in ImageJ <br>
b) Select channels and specify the parameters and press OK <br>
c) Adjust the **lower threshold** when you are asked to, in order to adjust the segmentation to your DNA staining<br>

### 3. Quality control
a) Check the stitched images in Results/stitching to see if they are in a good quality for all sub-positions<br>
b) You can review the segmentation by loading the stitched nuclei image and the saved ROIs from Results/segmentation into imageJ or by simply reviewing the mask image from the segmentation folder. 

### 4. Write FCS files in MATLAB
a) Copy the FL_values.csv and channels.csv from the generated Results folder in your MATLAB working directory <br>
b) Run the script FCS_conversion_ChipCytometry.m <br>
c) The ChipID.fcs file will be written in your MATLAB working directory and can be analyzed with any flow cytometry analysis software

## Clustering of cells and neighborhood analysis using scanpy
Scanpy was developed by the Theis laboratory for analyzing single cell RNA (scRNA) sequencing data and is one of the leading packages in this field. Here we feed in a [cells x proteins] matrix instead of the [cells x genes] matrix to use the pipeline for our imaging data. Cells and their fluorescence values can be imported into scanpy as adata object via the FL_values.csv and channels.csv files. An example of how to process data can be found in clustering_chipcytometry_cells.ipynb. For further information on the API of the scanpy package, check the scanpy documentation (https://scanpy.readthedocs.io).<br>

## Sample data
The folder sample data contains Chipcytometry data from an inflamed human colon biopsy shown in Figure 2 of the paper.

## References
1. Wolf, F., Angerer, P. & Theis, F. SCANPY: large-scale single-cell gene expression data analysis. Genome Biol 19, 15 (2018). https://doi.org/10.1186/s13059-017-1382-0
2. Schindelin, J., Arganda-Carreras, I., Frise, E. et al. Fiji: an open-source platform for biological-image analysis. Nat Methods 9, 676–682 (2012). https://doi.org/10.1038/nmeth.2019
3. Lin J-R, Izar B, Wang S, Yapp C, Mei S, Shah P, Santagata S, Sorger PK. Highly multiplexed immunofluorescence imaging of human tissues and tumors using t-CyCIF and conventional optical microscopes. eLife. 2018 Jul 11;7:e31657. https://doi.org/10.7554/eLife.31657 
4. Jakub Nedbal. writeFCS(fname, DATA, TEXT, OTHER) (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other), MATLAB Central File Exchange. Retrieved June 24, 2020. 
