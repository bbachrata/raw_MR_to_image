%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata

% This scripts allows correction of the chemical shift displecement and phase discrepancy of fat relative to water and their recombination.
% This script is meant to be run after SlicePIScriptForBeata_bb.m
% Image orientation, field stregth, and the receiver bandwidth have to be defined.


%% Housekeeping & Definitions
clear
close all;

addpath(genpath('/ceph/mri.meduniwien.ac.at/projects/radiology/fmri/data/bbachrata/matlab'))
addpath(genpath('/ceph/mri.meduniwien.ac.at/departments/radiology/neuro/home/bbachrata/data/programs/QSM'))

T2_w = 0;
T2_f = 0;
correctType1 = true;
correctType2 = true;
correctT1 = true;
correctT2 = false;
correctSMURFBias = false;


orient = 3; % 1-sag, 2-trans, 3-cor
is7T = false;
computeFatFraction = false;


%% Define data paths and acquisition orientation
for scan = 1:2
    
    switch scan 
        case 1
            output_dir = '/ceph/mri.meduniwien.ac.at/projects/radiology/fmri/data/bbachrata/analysis/SMM/p_bb_20211206_baconDatsToShare/2D_iPat2/';
            dat_file = '/ceph/mri.meduniwien.ac.at/projects/radiology/acqdata/data/BB_sorting_spot/p_bb_20211206_baconDatsToShare/dats/meas_MID00083_FID84515_bb_caipigre_2D_Grappa2.dat';
            rBW = 230; 
            is7T = false; 
  
    end  
    
    
    %% Initialize variables
    correction_suffix = '';
    fat_weight = 0;
    water_weight = 0;
    
    if (is7T)
        T1_w = 1700;
        T1_f = 550;
    else
        T1_w = 1400;
    	T1_f = 400;
    end
    
    
    %% Get acquisition parameters
    [TEs, is2D, caipiOffsetCorr, T1WeightFactor, T2sWeightFactor, type1PixelShift, type2PhaseOffset, isTurbo] = getAcqParams(dat_file, rBW, T1_w, T1_f, T2_w, T2_f);


    %% Load the water and fat images
    kspace_water = load_nii_uncomb_multiecho(output_dir, 'water', is2D);
    kspace_fat = load_nii_uncomb_multiecho(output_dir, 'fat', is2D);    
    
    % Correct fat for CAIPIRINHA phase shift
    caipiOffsetCorr = 1; % 1 for headneck; 0 for shoulder
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
        kspace_fat = correctChemicalShiftDisplacement(kspace_fat,type1PixelShift);  
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


    %% Correct for SMURF FF bias
    if (correctSMURFBias)
        [fat_weight,water_weight] = smurf_ff_bias_correction(is7T,TEs);
        for iEcho = 1:size(kspace_fat,5)
            kspace_fat(:,:,:,:,iEcho) = kspace_fat(:,:,:,:,iEcho)./(fat_weight(iEcho)/water_weight(iEcho));
        end
        correction_suffix = sprintf('%s_SmurfBiasCorr',correction_suffix);

        % Save images
        saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
    end
    
    
    %% Correct fat for T2* weighting    
    if (correctT2)
        
        if (T2sWeightFactor ~= 0)
            for iEcho = 1:size(kspace_fat,5)
                kspace_fat(:,:,:,:,iEcho) = kspace_fat(:,:,:,:,iEcho)./T2sWeightFactor(iEcho);
            end
            
        elseif (size(kspace_fat,5) < 2)
            error('multiecho acquisition required for T2 correction based on estimated T2* values')
            return;
            
        else
            if (is2D)
                fat = FFTOfMRIData_bb(kspace_fat,0,[2 3],1); 
                water = FFTOfMRIData_bb(kspace_water,0,[2 3],1); 
            else
                fat = FFTOfMRIData_bb(kspace_fat,0,[2 3 4],1);
                water = FFTOfMRIData_bb(kspace_water,0,[2 3 4],1); 
            end
            
            % Calculate T2* maps
            [T2map_f,T2map_w] = T2mapping_fromVlado_func(fat,water,output_dir,TEs,is7T);
            
            % Get rSoS magnitudes of first echo
            water = abs(squeeze(sqrt(sum((abs(water(:,:,:,:,1)).^2),1))));
            fat = abs(squeeze(sqrt(sum((abs(fat(:,:,:,:,1)).^2),1))));
            
            % Get noise estimate
            % we expect that we have 2 big groups of voxels - image(signal) and background(noise) - and we want to get median of the noisy voxels
            median_noise_water = get_noise_median(water);
            median_noise_fat = get_noise_median(fat);
            nVoxelEcho = length(water(:));
            
            % Get fat-fraction map ans threshold it in noisy regions
            % rather stay conservative and care only about the voxels with sufficient signal
            FF = fat./(fat+water);
            for i = 1:nVoxelEcho
                if (water(i) < 15*median_noise_water && fat(i) < 15*median_noise_fat) % noise only
                    FF(i) = -1;
                elseif (water(i) < 15*median_noise_water && fat(i) >= 15*median_noise_fat) % fat only
                    FF(i) = 1;
                elseif (water(i) >= 15*median_noise_water && fat(i) < 15*median_noise_fat) % water only
                    FF(i) = 0;
                end                                             
            end
            save_nii(make_nii(FF),fullfile(output_dir,'FF.nii'));
            clear water fat

            % Calculate the per-pixel ratio of fat and water relaxation
            T2scale_ratio = zeros(size(T2map_w,1),size(T2map_w,2),size(T2map_w,3),length(TEs));         
            for iEcho = 1:length(TEs)
                T2scale_ratio(:,:,:,iEcho) = exp(-TEs(iEcho)./T2map_f)./exp(-TEs(iEcho)./T2map_w);
            end
            
            % Take only the mixed voxels
            FF_masked = FF;
            for iEcho = 1:length(TEs)
                j = 1; 
                for i = 1:nVoxelEcho
                    if(FF(i)>=0.1 && FF(i)<0.8)
                        T2scale_ratio_masked(j,iEcho) = T2scale_ratio(i+nVoxelEcho*(iEcho-1));
                        j = j + 1;
                        FF_masked(i) = 1;
                    else
                        FF_masked(i) = 0;
                    end                                       
                end
            end
            save_nii(make_nii(FF_masked),fullfile(output_dir,'FF_masked.nii'));

            T2map_w_masked = T2map_w(find(FF_masked~=0));
            T2map_f_masked = T2map_f(find(FF_masked~=0));
            
            k = 1;
            for i = 1:length(T2map_w_masked)            
                if ((T2map_w_masked(i) ~= max(T2map_w_masked)) && (T2map_f_masked(i) ~= max(T2map_f_masked)))
                    T2map_w_masked_notMax(k) = T2map_w_masked(i);
                    T2map_f_masked_notMax(k) = T2map_f_masked(i);
                    k = k +1;
                end
            end
                              
            median_w = median(T2map_w_masked_notMax)
            median_f = median(T2map_f_masked_notMax)
            
            clear FF FF_masked T2scale_ratio
            
            % Get median over the mixed voxels 
            T2sWeightFactor = median(T2scale_ratio_masked);            
            clear T2scale_ratio_masked

            % Correct the fat image for T2* differences (in all voxels - in non-mixed voxels won't have effect)
            for iEcho = 1:length(TEs)
                kspace_fat(:,:,:,:,iEcho) = kspace_fat(:,:,:,:,iEcho)./T2sWeightFactor(iEcho);
            end

        end
        
        correction_suffix = sprintf('%s_T2Corr',correction_suffix);
        
        % Save images
        saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
        
    end

    
    %% Calculate fat-fractions
    if (computeFatFraction)
        FF = computeFF_noCut_bb(kspace_water, kspace_fat, is2D);   
        save_nii(make_nii(squeeze(FF)), fullfile(output_dir,sprintf('FF%s',correction_suffix)));
    end

    clear kspace_fat kspace_water 
    
    
    %% Save correction parameters into related text file
    saveCorrectionValues(output_dir, type2PhaseOffset, type1PixelShift, T1WeightFactor, (fat_weight./water_weight), T2sWeightFactor);


end
    
clear
close all;



