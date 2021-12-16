%% Version 1.0
% 16.12.2021
% Written by Beata Bachrata, with usage of parallel imaging reconstruction written by Bernhard Strasser

% This scripts allow reconstruction of unaliased images, from the raw data acquired with GRAPPA undersampling.
% Image orientation and the path to dat files have to be defined.
% Instead of separate prescan, ACS data of GRAPPA acquisition can be used (if the number of slices is equal) slices 


%% Housekeeping & Definitions
clear
close all;

save_steps = true;
save_uncomb = false; 

addpath(genpath('/ceph/mri.meduniwien.ac.at/projects/radiology/fmri/data/bbachrata/matlab'))


%% Define data paths and acquisition orientation
for scan = 1
           
    orient = 3; % 1-sag, 2-trans, 3-cor
    PE_dir = 3; % 1 = HF, 2 = AP, 3 = RL
    deleteSeparateEchoes = true;
    useGrappaPrescan = false;
    
    switch scan             
        case 1
            output_dir = '/ceph/mri.meduniwien.ac.at/projects/radiology/fmri/data/bbachrata/analysis/QSM_SMM/p_bb_20210107_phase/grappa/192/iPat3_nopf';
            kspace_aliased_path = '/ceph/mri.meduniwien.ac.at/projects/radiology/acqdata/data/BB_sorting_spot/p_bb_20210107_phase/dats/meas_MID00299_FID31532_gre_iPat3_noPF_192.dat';
            kspace_prescan_path = '/ceph/mri.meduniwien.ac.at/projects/radiology/acqdata/data/BB_sorting_spot/p_bb_20210107_phase/dats/meas_MID00332_FID31565_gre_noPat_noPF_112.dat';
            orient = 2; 
            PE_dir = 3;                
    end  
    
    
    %% Create output directory
    [s,mess] = mkdir(output_dir);
    fprintf('Writing results to %s\n', output_dir);
    if s == 0
        error('No permission to make directory %s/', output_dir);
    end
    
    
    %% Load and reshape data
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

        
        if (iEcho == 1)
            
            % Use only given echo  
            kspace_aliased = squeeze(kspace_aliased(:,:,:,:,iEcho));
            kspace_prescan = squeeze(kspace_prescan(:,:,:,:,1));


            %% Preparation steps  
            kspace_aliased = flip(flip(flip(kspace_aliased,1),2),3);
            kspace_prescan = flip(flip(flip(kspace_prescan,1),2),3);
            
            kspace_aliased = zerofillPartialFourier(kspace_aliased,params); 
            [undersamplingPattern, FOVShifts] = getUndersamplingPattern(kspace_aliased);
            sliceOrder = getSliceAcquisitionOrder(kspace_aliased,params);
            
            kspace_aliased = kspace_aliased(:,:,:,sliceOrder.'); 
            kspace_prescan = kspace_prescan(:,:,:,sliceOrder.'); 

            if (~params.is2D)
                kspace_aliased = flip(kspace_aliased,4);
                kspace_prescan = flip(kspace_prescan,4);
            end

            
            %% Remove zero-lines with iPat
            kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
            [kspace_aliased, expandPattern] = expandKSpaceByIPat(kspace_aliased, params);

            
            %% Save the aliased image and prescan
            if (save_steps)
                save_nii_from_kspace_separateecho(kspace_prescan, output_dir, 'ACS_grappa', 0, params);
                save_nii_from_kspace_separateecho(kspace_aliased, output_dir, 'Aliased', saveEcho, params);
            end

            
            %% GRAPPA unaliasing
            [kspace_unaliased,weights_grappa,kernelsize,SrcRelativeTarg] = opencaipirinha_MRSI_bb(kspace_aliased, kspace_prescan, params.is2D, expandPattern);
            clear kspace_prescan
            
            % Save unaliased image
            save_nii_from_kspace_separateecho(kspace_unaliased, output_dir, 'unaliased', saveEcho, params);
            if (save_uncomb)
                save_nii_from_kspace_uncomb_separateecho(kspace_unaliased, output_dir, 'unaliased_uncomb', saveEcho, params);
            end
            clear kspace_unaliased
        
            
        else
            
            %% Reload data (for memory purposes deleted while processing the first echo)
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
 
            
            %% Remove zero-lines with iPat
            kspace_aliased = collapseKSpaceByIPat(kspace_aliased, undersamplingPattern, params);
            kspace_aliased = expandKSpaceByIPat(kspace_aliased, params, expandPattern);


            %% GRAPPA unaliasing
            kspace_unaliased = opencaipirinha_MRSI_bb(kspace_aliased, weights_grappa, params.is2D, expandPattern, kernelsize, SrcRelativeTarg);
            
            % Save unaliased image
            save_nii_from_kspace_separateecho(kspace_unaliased, output_dir, 'unaliased', saveEcho, params);
            if (save_uncomb)
                save_nii_from_kspace_uncomb_separateecho(kspace_unaliased, output_dir, 'unaliased_uncomb', saveEcho, params);
            end
            clear kspace_unaliased
            
        end
        
    end
    
    
%     %% Merge echoes and delete the individual echo images if desired
%     mergeEchoesOfNifti(output_dir, 'unaliased', iEcho, deleteSeparateEchoes);
    
end


