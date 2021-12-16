%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata

% This script allows reconstruction of images from the raw data (only without GRAPPA acceleration)
% Image orientation and the path to dat files have to be defined.


%% Housekeeping & Definitions
clear;
close all;

save_uncomb = true; % required for fat-water recombination 


%% Define data paths and acquisition orientation
for scan = 1
   
    orient = 3; % 1-sag, 2-trans, 3-cor
    PE_dir = 3; % 1 = HF, 2 = AP, 3 = RL
    deleteSeparateEchoes = true;
    output_name = 'image.nii';

    switch scan 
        case 1
            output_dir = '/ceph/mri.meduniwien.ac.at/projects/radiology/fmri/data/bbachrata/analysis/SMM/p_bb_20211206_baconDatsToShare/2D_iPat2';
            dat_file = '/ceph/mri.meduniwien.ac.at/projects/radiology/acqdata/data/BB_sorting_spot/p_bb_20211206_baconDatsToShare/dats/meas_MID00083_FID84515_bb_caipigre_2D_Grappa2.dat';

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


