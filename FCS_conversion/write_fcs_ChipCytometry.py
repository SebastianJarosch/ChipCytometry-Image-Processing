#!/usr/bin/python
import pandas as pd
import numpy as np
import fcswrite
import sys
import argparse

def write_fcs_ChipCytometry(FL_values_path="FL_values.csv", channels_path="channels.csv", additional_channels=['X','Y','Circ.','Area'], output_dir='./'):
    """Write ChipCytometry data to an .fcs file using fcswrite (FCS3.0 file format)
    Parameters
    ----------
    FL_values_path: str
        Path to the FL_values.csv file generated in ImageJ
    channels_path: str 
        Path to the channels.csv file generated in ImageJ
    additional_channels: list of str
        Additional channels that should be included from the data
        file. Default: ['X','Y','Circ.','Area']
    output_dir: str
        Output directory the fcs file should be written to.
        Default: current directory"""

    data=pd.read_csv(FL_values_path, index_col=0)
    channels=pd.read_csv(channels_path)
    data.Label=[x[-1][:-5] for x in data.Label.str.split(':')]
    additional_channels=additional_channels
    format_data=pd.DataFrame()
    for channel in data.Label.unique():
        format_data[channel]=data.Mean[data.Label==channel].tolist()
    format_data[additional_channels]=data[additional_channels][:format_data.shape[0]]
    fcswrite.write_fcs(output_dir+channels.columns.tolist()[0]+'.fcs', chn_names=format_data.columns.tolist(), data=format_data)
    
parser = argparse.ArgumentParser()
parser.add_argument("-f", "--FL_values_path", help="Path to the FL_values.csv file generated in ImageJ", default="FL_values.csv")
parser.add_argument("-c", "--channels_path", help="Path to the channels.csv file generated in ImageJ", default="channels.csv")
parser.add_argument("-a", "--additional_channels", help="Additional channels that should be included from the data", default=['X','Y','Circ.','Area'])
parser.add_argument("-o", "--output_dir", help="Output directory the fcs file should be written to", default="./")
args=parser.parse_args()

if __name__ == "__main__":
    write_fcs_ChipCytometry(args.FL_values_path, args.channels_path, args.additional_channels, args.output_dir)