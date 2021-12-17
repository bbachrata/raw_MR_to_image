%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata

% This script allows reconstruction of images from the raw data (only without GRAPPA acceleration)
% Image orientation and the path to dat files have to be defined.


%% Housekeeping & Definitions
clear;
close all;


%%%%%  Set your path to the files %%%%%%
your_reco_path = '';


% Optional outputs
save_uncomb = false;  

% Set output image name
output_name = 'image.nii';


%% Define data paths and acquisition orientation
for scan = 1
   
    orient = 2; % 1-sag, 2-trans, 3-cor
    PE_dir = 2; % 1 = HF, 2 = AP, 3 = RL

    switch scan 
        case 1
            output_dir = fullfile(your_reco_path,'SMURF/reco/test_data_output/conventional_2D');
            dat_file = fullfile(your_reco_path,'SMURF/reco/test_data/conventional_2D/meas_MID00723_FID59155_bb_smurftse_inPha_2D.dat');

    end
    
    
    %% Create output directory
    [s,mess] = mkdir(output_dir);
    fprintf('Writing results to %s\n', output_dir);
    if s == 0
        error('No permission to make directory %s/m', output_dir);
    end
    
    
    %% Load data (for memory purposes deleted while processing the first echo)
    [kspace, params] = loadData(dat_file);  
    params.orient = orient; clear orient
    params.PE_dir = PE_dir; clear PE_dir
    

    %% Preparation steps
    kspace = flip(flip(flip(kspace,1),2),3);
    kspace = zerofillPartialFourier(kspace,params); 
    sliceOrder = getSliceAcquisitionOrder(kspace,params);
    kspace = kspace(:,:,:,sliceOrder.'); 

    if (~params.is2D)
        kspace = flip(kspace,4);
    end
     
    
    %% Save images
    save_nii_from_kspace(kspace, output_dir, output_name, params);
    if (save_uncomb)
        save_nii_from_kspace_uncomb(kspace, output_dir, output_name, params);    
    end
    
end


