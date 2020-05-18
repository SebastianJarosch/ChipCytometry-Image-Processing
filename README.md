# ChipCytometry Image Processing
Macros and codes from the publication "Publication Jarosch et al..."

![Image of Pipeline](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/image.tiff)

## System reqirements
* ImageJ 1.52e or higher <br>
* Matlab 2018b or higher <br>
* Python3.7+ for clustering and neighborhood analysis

## Third party packages, plugins and scripts
* Scanpy (https://github.com/theislab/scanpy) <br>
* writeFCS (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other)

## Getting started
* Download the scripts from this repository
* 
*

## Workflow
### 1. Image export
a) Adjust Background and contrast value in Zellkraftwerk app in order to get the best snapshot from the HDR image <br>
b) Export images for each channel in the Zellkraftwerk app as 16 bit grayscale tiff images <br>
c) Copy the Scanjob folders for each channel in a new directory named with the chipID <br>
d) Rename the scanjob folders with their channel names <br>

### 2. Data generation in ImageJ
*Dependent on the size of a chip and the number of segmented cells, the spillover-correction can take up to 24 hours, so make sure that all parameters have been adjusted precisely and perform a test run without correction to check the correctness of the input parameters first* <br><br>
a) Run the script automatic_image_processing.ijm in ImageJ <br>
b) Select channels and specify the parameters and press OK <br>
c) Adjust the **lower threshold** when you are asked to, in order to adjust the segmentation to your DNA staining<br>

### 3. Write FCS files in MATLAB
a) Copy the FL_values.csv and channels.csv from the generated Results folder in your MATLAB working directory <br>
b) Run the script FCS_conversion_ChipCytometry.m <br>
c) The .fcs file will be written in your MATLAB working directory and can be analyzed with any FlowCytometry analysis software

## Clustering of cells and neighborhood analysis using scanpy
Scanpy was developed by the Theis Lab for analyzing scRNA sequencing data and is one of the leading packages in this field. Here we feed in a [cells x proteins] matrix instead of the [cells x genes] matrix to use the pipeline for our imaging data. Cells and their fluorescence values can be imported into scanpy as adata object via the FL_values.csv and channels.csv files. An example of how to process data can be found in clustering_chipcytometry_cells.ipynb. For further information on the API of the scanpy package, check the scanpy documentation (https://scanpy.readthedocs.io/en/stable/). <br><br>
Besides this aproach we would also like to mention the cyt3 package as matlab GUI (https://github.com/dpeerlab/cyt3) from the Dana Pe'er Lab which was developed for the analysis of MassCytometry data and allows clustering of cells from the csv generated in matlab before

## Sample data
The folder sample data contains Chipcytometry data from an inflamed human colon biopsy shown in Figure 2 of the paper.

## References
1. Wolf, F., Angerer, P. & Theis, F. SCANPY: large-scale single-cell gene expression data analysis. Genome Biol 19, 15 (2018). https://doi.org/10.1186/s13059-017-1382-0
2. Schindelin, J., Arganda-Carreras, I., Frise, E. et al. Fiji: an open-source platform for biological-image analysis. Nat Methods 9, 676–682 (2012). https://doi.org/10.1038/nmeth.2019
3. Lin J-R, Izar B, Wang S, Yapp C, Mei S, Shah P, Santagata S, Sorger PK. Highly multiplexed immunofluorescence imaging of human tissues and tumors using t-CyCIF and conventional optical microscopes. eLife. 2018 Jul 11;7:e31657. https://doi.org/10.7554/eLife.31657 
4.
