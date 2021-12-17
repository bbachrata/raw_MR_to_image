%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata, with usage of parallel imaging reconstruction written by Bernhard Strasser

% This script allows reconstruction of separate images of fat and water, from the raw data acquired with SMURF seuqence.
% Image orientation and the path to dat files have to be defined.
% Instead of separate prescan, ACS data of GRAPPA acquisition can be used (if the number of slices is equal) slices 

% For generation of chemical shift artefacts-free fat-water images, please
% run correct_CSA_recombine_caller.m afterwards


%% Housekeeping & Definitions
clear;
close all;


%%%%%  Set your path to the files %%%%%%
your_reco_path = '';


% Optional outputs
save_steps = true;
save_uncomb = true; % required for fat-water recombination 

% Initiliaze
kspace_prescan_path = '';


%% Define data paths and acquisition orientation
for scan = 1
            
    orient = 3; % 1-sag, 2-trans, 3-cor
    PE_dir = 3; % 1 = HF, 2 = AP, 3 = RL
    useGrappaPrescan = false;
   
    switch scan  
        case 1
            output_dir = fullfile(your_reco_path,'SMURF/reco/test_data_output/SMURF_2D_iPat2/');
            kspace_aliased_path = fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_2D_iPat2/meas_MID00083_FID84515_bb_smurfgre_2D_iPat2.dat');
            kspace_prescan_path = fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_2D_iPat2/meas_MID00084_FID84516_2D_prescan.dat');
        case 2
            output_dir = fullfile(your_reco_path,'SMURF/reco/test_data_output/SMURF_nonSel3D_iPat3/');
            kspace_aliased_path = fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_nonSel3D_iPat3/meas_MID00088_FID84520_bb_smurfgre_3D_iPat3.dat');
            kspace_prescan_path = fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_nonSel3D_iPat3/meas_MID00089_FID84521_3D_prescan.dat');
        case 3
            output_dir = fullfile(your_reco_path,'SMURF/reco/test_data_output/SMURF_2D_iPat2_ACS/');
            kspace_aliased_path = fullfile(your_reco_path,'SMURF/reco/test_data/SMURF_2D_iPat2/meas_MID00083_FID84515_bb_smurfgre_2D_iPat2.dat');
            useGrappaPrescan = true;

    end     
    
    
    %% Create output directory
    [s,mess] = mkdir(output_dir);
    fprintf('Writing results to %s\n', output_dir);
    if s == 0
        error('No permission to make directory %s/', output_dir);
    end
    
    
    %% Load and reshape data to [coil, y(2n), x(n), slc, echo] 
    % Load data and get acquisition parameters
    [kspace_aliased, params, kspace_prescan] = loadData(kspace_aliased_path, kspace_prescan_path, useGrappaPrescan);  
    params.orient = orient; clear orient    
    params.PE_dir = PE_dir; clear PE_dir    

    % Get the number of echoes to process
    nEchoes = size(kspace_aliased,5);
    
    
    %% Process echo by echo for memory purposes
    for iEcho = 1:nEchoes
        
        % Name of echo for saving 
        if (nEchoes == 1)
            saveEcho = 0;
        else
            saveEcho = iEcho;
        end
        
        % The processing of first echoes requires additional steps (e.g. generation of ACS data for GRAPPA and SMURF unaliasing and estimation of the weights) 
        if (iEcho == 1)
                      
            % Use only given echo  
            kspace_aliased = squeeze(kspace_aliased(:,:,:,:,iEcho));
            kspace_prescan = squeeze(kspace_prescan(:,:,:,:,1));            

            %% Preparation steps            
            kspace_aliased = flip(flip(flip(kspace_aliased,1),2),3);
            kspace_prescan = flip(flip(flip(kspace_prescan,1),2),3);

            kspace_aliased = zerofillPartialFourier(kspace_aliased,params);             

            [undersamplingPattern, FOVShifts] = getUndersamplingPattern(kspace_aliased,params);
            FWSliceAliasingPattern = getFWSliceAliasingPattern(kspace_aliased,params);
            sliceOrder = getSliceAcquisitionOrder(kspace_aliased,params);
            
            kspace_aliased = kspace_aliased(:,:,:,sliceOrder.'); 
            kspace_prescan = kspace_prescan(:,:,:,sliceOrder.'); 

            if (~params.is2D)
                kspace_aliased = flip(kspace_aliased,4);
                kspace_prescan = flip(kspace_prescan,4);
            end
            
            %% Combine and shift prescan to generate "fat-water" ACS data for GRAPPA and CAIPIRINHA reconstructions
            kspace_prescan = getACS(kspace_prescan, params, FOVShifts);
            dims = size(kspace_prescan);
            
            % The ACS data for CAIPIRINHA fat-water separation, with not-overlaping fat and water  
            kspace_ACS_caipi= kspace_prescan;

            % Get the ACS data for GRAPPA unaliasing - the fat and water are overlapping, but shifted relative to each other by CAIPIRINHA 
            if (params.iPat ~= 1)
                if (~params.is2D)
                    kspace_prescan = FFTOfMRIData(kspace_prescan,0,[4],1);
                end
                kspace_ACS_grappa = zeros(dims(1),dims(2),dims(3),dims(4)/2);
                for iSlice = 1:(dims(4)/2)
                    iAliased = FWSliceAliasingPattern(iSlice,2);
                    kspace_ACS_grappa(:,:,:,iSlice) = kspace_prescan(:,:,:,iSlice) + kspace_prescan(:,:,:,iAliased);
                end
                if (~params.is2D)
                    kspace_ACS_grappa = FFTOfMRIData(kspace_ACS_grappa,0,[4],0);
                end
            end
            clear kspace_prescan
            
            
            %% Collapse and expand to get rid of phase gradient
            if (params.iPat == 3)
                kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
                [kspace_aliased,expandPattern] = expandKSpaceByIPat(kspace_aliased, params);
            elseif (params.iPat == 2)
                kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
                [kspace_aliased,expandPattern] = expandKSpaceByIPat(kspace_aliased, params);
            end          
            
            
            %% Save the aliased image and prescans
            if (save_steps)
                save_nii_from_kspace_separateecho(kspace_aliased, output_dir, 'Aliased', saveEcho, params);
                save_nii_from_kspace_separateecho(kspace_ACS_caipi, output_dir, 'ACS_caipi', 0, params);
                if (params.iPat ~= 1)
                    save_nii_from_kspace_separateecho(kspace_ACS_grappa, output_dir, 'ACS_grappa', 0, params);
                end
            end
                        
            
            %% GRAPPA unaliasing 
            if (params.iPat ~= 1)
                [kspace_aliased,weights_grappa,kernelsize,SrcRelativeTarg] = opencaipirinha_MRSI(kspace_aliased, kspace_ACS_grappa, params.is2D, expandPattern);      
                clear kspace_ACS_grappa
            
                % Save grappa unaliased image
                if (save_steps)
                    save_nii_from_kspace_separateecho(kspace_aliased, output_dir, 'unaliased', saveEcho, params);
                end
            end
            
            
            %% Water-fat CAIPIRINHA unaliasing 
            [kspace_water, kspace_fat, weights_caipi] = openslicecaipirinha_MRSI(kspace_aliased, kspace_ACS_caipi, params.is2D, FWSliceAliasingPattern);             
            clear kspace_aliased
            
            % Reverse CAIPI shift of fat
            kspace_fat = kSpace_FoVShift(kspace_fat, -1*FOVShifts((size(FOVShifts,1)/2+1):end,:));
            
            % Save unaliased images
            save_nii_from_kspace_separateecho(kspace_water, output_dir, 'water', saveEcho, params);
            save_nii_from_kspace_separateecho(kspace_fat, output_dir, 'fat', saveEcho, params);           
            if (save_uncomb)            
                save_nii_from_kspace_uncomb_separateecho(kspace_water, output_dir, 'water_uncomb', saveEcho, params);
                save_nii_from_kspace_uncomb_separateecho(kspace_fat, output_dir, 'fat_uncomb', saveEcho, params);           
            end
            
            clear kspace_fat kspace_water

    
        elseif (iEcho > 1)
                
            % Reload data (for memory purposes deleted while processing the first echo)
            kspace_aliased = loadData(kspace_aliased_path);  
            
            % Use only given echo  
            kspace_aliased = squeeze(kspace_aliased(:,:,:,:,iEcho));


            %% Preparation steps  
            kspace_aliased = flip(flip(flip(kspace_aliased,1),2),3);
            kspace_aliased = zerofillPartialFourier(kspace_aliased,params); 
            kspace_aliased = kspace_aliased(:,:,:,sliceOrder.'); 
            if (~params.is2D)
                kspace_aliased = flip(kspace_aliased,4);
            end
                        
            %% Collapse and expand to get rid of phase gradient
            if (params.iPat == 3)
                kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
                [kspace_aliased,expandPattern] = expandKSpaceByIPat(kspace_aliased, params);
            elseif (params.iPat == 2)
                kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
                [kspace_aliased,expandPattern] = expandKSpaceByIPat(kspace_aliased, params);
            end
            
            %% Save the aliased image
            if (save_steps)
                save_nii_from_kspace_separateecho(kspace_aliased, output_dir, 'Aliased', saveEcho, params);
            end

            %% GRAPPA unaliasing
            if (params.iPat ~= 1)
                kspace_aliased = opencaipirinha_MRSI(kspace_aliased, weights_grappa, params.is2D, expandPattern, kernelsize, SrcRelativeTarg);
                
                % Save grappa unaliased image
                if (save_steps)
                    save_nii_from_kspace_separateecho(kspace_aliased, output_dir, 'unaliased', saveEcho, params);
                end
            end
            
            
            %% Water-fat CAIPIRINHA unaliasing
            [kspace_water, kspace_fat] = openslicecaipirinha_MRSI(kspace_aliased, weights_caipi, params.is2D, FWSliceAliasingPattern); 
            clear kspace_aliased
            
            % Reverse CAIPI shift of fat
            kspace_fat = kSpace_FoVShift(kspace_fat, -1*FOVShifts((size(FOVShifts,1)/2+1):end,:));
            
            % Save unaliased water and image
            save_nii_from_kspace_separateecho(kspace_water, output_dir, 'water', saveEcho, params);
            save_nii_from_kspace_separateecho(kspace_fat, output_dir, 'fat', saveEcho, params);
            if (save_uncomb)            
                save_nii_from_kspace_uncomb_separateecho(kspace_water, output_dir, 'water_uncomb', saveEcho, params);
                save_nii_from_kspace_uncomb_separateecho(kspace_fat, output_dir, 'fat_uncomb', saveEcho, params);           
            end

            clear kspace_water kspace_fat

        end
    
    end
     
end


