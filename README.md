# Zellkraftwerk-Image-Processing
Macros and codes from the publication "Publication"

## System reqirements
* 32GB RAM or more
* ImageJ 1.52e ? or higher <br>
* Matlab 2018b or higher <br>
* Python3.7

## Third party packages, plugins and scripts
* Scanpy (https://github.com/theislab/scanpy) <br>
* writeFCS (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other)

## Getting started
*
*
*

## Workflow
### 1. Image export
a) Export images for each channel in the Zellkraftwerk app as 16 bit grayscale tiff images <br>
b) Copy the Scanjob folders for each channel in a new directory named with the chipID <br>
c) Rename the scanjob folders with their channel names <br>

### 2. Data generation in ImageJ
*Dependent on the size of a chip and the number of segmented cells, the spillover-correction can take up to 24 hours, so make sure that all parameters have been adjusted precisely and perform a test run without correction to check the results first* <br><br>
a) Run the script automatic_image_processing.ijm in ImageJ <br>
b) specify the parameters and press OK <br>
c) Adjust the lower threshold when you are asked to <br>

### 3. Write FCS files in MATLAB
a) Copy the FL_values.csv and channels.csv from the generated Results folder in your MATLAB working directory <br>
b) Run the script FCS_conversion_ChipCytometry.m

## Clustering of cells and neighborhood analysis using scanpy
Scanpy was developed by the Theis Lab for analyzing scRNA sequencing data and is one of the leading packages in this field. Here we feed in a [cells x proteins] matrix instead of the [cells x genes] matrix to use the pipeline for our imaging data. Cells and their fluorescence values can be imported into scanpy as adata object via the FL_values.csv and channels.csv files. An example of how to process data can be found in clustering_chipcytometry_cells.ipynb. See also the scanpy documentation (https://scanpy.readthedocs.io/en/stable/). <br><br>
Besides this aproach we would also like to mention the cyt3 package as matlab GUI (https://github.com/dpeerlab/cyt3) from the Dana Pe'er Lab which was developed for the analysis of MassCytometry data and allows clustering of cells from the csv generated in matlab before
