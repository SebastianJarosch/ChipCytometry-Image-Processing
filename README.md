# Zellkraftwerk-Image-Processing
Macros and codes from the publication "Publication"

## System reqirements
* 32GB RAM or more
* ImageJ 1.49j ? or higher <br>
* Matlab 2018b ? or higher <br>
* Python3.7

## Third party packages, plugins and scripts
* Scanpy (https://github.com/theislab/scanpy) <br>
* writeFCS (https://www.mathworks.com/matlabcentral/fileexchange/42603-writefcs-fname-data-text-other)

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
b) Run the script ...

