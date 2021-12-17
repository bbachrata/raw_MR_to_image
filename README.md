__Version 1.0  ---  16.12.2021  ---  Written by Beata Bachrata__


This repository provides Matlab code for the image reconstruction of raw MR data, acquired on Siemens' scanners.  
To read in the raw data, mapVBVD function by Phillip Ehses is used  
Test data can be dowloaded from https://doi.org/10.7910/DVN/AEMJ2L  
  
  
  
3 main (caller) scripts are provided to do the reconstruction of  
1) raw data acquired without GRAPPA or SMURF (_raw_to_ima_caller.m_)  
2) raw data acquired with GRAPPA acceleration (_raw_to_ima_withGRAPPA_caller.m_)  
3) raw data acquired with SMURF sequence and possibly with GRAPPA accelation (_raw_to_ima_withSMURF_caller.m_)  

The scripts 2) and 3) perform GRAPPA and CAIPIRINHA reconstruction of the undersampled data (coded by Bernhard Strasser)  
They either use the ACS data of GRAPPA acquistion or require separe low-resolution prescan with the same geometry (e.g. size and position of FOV, number of slice and slice thickness)   


The script correct_CSA_recombine_caller.m allows generation of chemical shift artefact and T1 relaxation rate bias-free fat-water images  

Related publications:
1) Bachrata B, Strasser B, Bogner W, Schmid AI, Korinek R, Krššák M, Trattnig S, Robinson SD. Simultaneous Multiple Resonance Frequency imaging (SMURF): Fat-water imaging using multi-band principles. Magn Reson Med. 2021; 85:1379-1396.
2) Bachrata B, Trattnig S, Robinson SD. Quantitative Susceptibility Mapping of the head-and-neck using SMURF fat-water imaging with chemical shift and relaxation rate corrections. Magn Reson Med. 2021.

The reconstruction was tested for various of 2D and 3D, single-echo and multi-echo, GRE and TSE data without and with partial Fourier and parallel imaging acceleration (up to a factor of 3).
