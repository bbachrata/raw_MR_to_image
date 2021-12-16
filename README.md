% Version 1.0
% 16.12.2021
% Written by Beata Bachrata


% This repository provides Matlab code for the image reconstruction of raw MR data, acquired on Siemens' scanners.
% To read in the raw data, it uses mapVBVD function by Phillip Ehses

% 3 separate scripts provide reco of
1) raw data acquired without GRAPPA or SMURF
2) raw data acquired with GRAPPA acceleration
3) raw data acquired with SMURF sequence and possibly with GRAPPA accelation

2) + 3) can use either the ACS data of GRAPPA acquistion or require separe low-resolution prescan with the same geometry (e.g. size and position of FOV, number of slice and slice thickness)  


