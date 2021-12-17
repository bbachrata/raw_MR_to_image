%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata

% This scripts allows correction of the chemical shift displecement and phase discrepancy of fat relative to water and their recombination.
% This script is meant to be run after raw_to_ima_withSMURF_caller.m
% Image orientation, field stregth, and the receiver bandwidth have to be defined.

 
%% Housekeeping & Definitions
clear;
close all;


%%%%%  Set your path to the files %%%%%%
your_reco_path = '';


%% Set corrections to be perfromed
correctType1 = true;
correctType2 = true;
computeFatFraction = false;
correctT1 = true;


%% Define data paths and acquisition orientation
for scan = 1
    
    switch scan 
        case 1
            output_dir = fullfile(your_reco_path,'SMURF/reco/test_data_output/SMURF_2D_iPat2/');
            dat_file =  fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_2D_iPat2/meas_MID00083_FID84515_bb_smurfgre_2D_iPat2.dat');
            rBW = 230; 
            is7T = false; 
  	    orient = 3; % 1-sag, 2-trans, 3-cor
    end  
    
    
    %% Initialize the name suffix
    correction_suffix = '';
    
    if (is7T)
        T1_w = 1700;
        T1_f = 550;
    else
        T1_w = 1400;
    	T1_f = 400;
    end
    
    
    %% Get acquisition parameters
    [TEs, is2D, caipiOffsetCorr, T1WeightFactor, type1PixelShift, type2PhaseOffset, isTurbo] = getAcqParams(dat_file, rBW, T1_w, T1_f);


    %% Load the water and fat images
    kspace_water = load_nii_uncomb_multiecho(output_dir, 'water', is2D);
    kspace_fat = load_nii_uncomb_multiecho(output_dir, 'fat', is2D);    
    

    % Correct fat for CAIPIRINHA phase shift
    % caipiOffsetCorr might, in some cases, have to be changed manually from 0 to 1 or from 1 to 0 (if the Type2Corr image is opposed-phase instead of in-phase)
    if (caipiOffsetCorr ~= 0)
        for iEcho = 1:size(kspace_fat,5)
            kspace_fat(:,:,:,:,iEcho) = kspace_fat(:,:,:,:,iEcho).*exp(1i*caipiOffsetCorr*pi);
        end
    end
        
    % Save images
    saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
    
    
    %% Correct fat for Type 2 chemical shift (not in-phase TE)
    if (correctType2)
        for iEcho = 1:size(kspace_fat,5)
            kspace_fat(:,:,:,:,iEcho) = kspace_fat(:,:,:,:,iEcho).*exp(-1i*type2PhaseOffset(iEcho)*pi);
        end
        correction_suffix = fullfile(correction_suffix,'_type2Corr');
        
        % Save images
        saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
    end
        
    
    %% Correct fat for Type 1 chemical shift (chemical shift displacement)
    if (correctType1)
        type1PixelShift = -type1PixelShift;
        kspace_fat = shiftImage(kspace_fat,type1PixelShift);  
        correction_suffix = sprintf('%s_type1Corr',correction_suffix);
        
        % Save images
        saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
    end
    

    %% Correct fat for T1 weighting    
    if (correctT1)
        kspace_fat = kspace_fat./T1WeightFactor;         
        correction_suffix = sprintf('%s_T1Corr',correction_suffix);
        
        % Save images
        saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
    end

    
    %% Calculate fat-fractions
    if (computeFatFraction)
        FF = computeFF_noCut(kspace_water, kspace_fat, is2D);   
        save_nii(make_nii(squeeze(FF)), fullfile(output_dir,sprintf('FF%s',correction_suffix)));
    end

    clear kspace_fat kspace_water 
    
    
    %% Save correction parameters into related text file
    saveCorrectionValues(output_dir, type2PhaseOffset, type1PixelShift, T1WeightFactor);


end
    

