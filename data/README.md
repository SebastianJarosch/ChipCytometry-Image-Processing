# Data
Data for the inflamed colon tissue shown in Figure 2 of the paper provided for reproduction of the quantification data and testing the analysis pipeline

![Image of Biopsy](https://github.com/SebastianJarosch/ChipCytometry-Image-Processing/blob/master/img/Biopsy_1.png)

# Instructions
In order to reproduce the quantification data of this sample you need to:
* Run the imageJ script "automatic_image_processing.ijm" on the Chip folder 'M733847'
* Convert the files "FL_values.csv" and "channels.csv" to an .fcs file via the MATLAB script "FCS_conversion_ChipCytometry.m"
* Import the file in the notebook file "ChipCytometry_Analysis.ipynb" for scanpy analysis (Optional) 
