function save_nii_from_kspace_separateecho(kspace, dir, name, iEcho, params)
% BB: covert the k-space data to image space, remove oversampling, reorient based on acquistion orientation and save as NIFTI file 

    % Fourier transform the data from k-space to image
    if (params.is2D)
        ima = FFTOfMRIData(kspace,0,[2 3],1); 
    else
        ima = FFTOfMRIData(kspace,0,[2 3 4],1);
    end

    % Do root sum-of-squares coild combination
    ima_SoS = squeeze(sqrt(sum((abs(ima).^2),1)));

    % Remove the readout oversampling
    ima_SoS = ima_SoS((size(ima_SoS,1)*0.25 + 1):(size(ima_SoS,1)*0.75),:,:,:);

    % Remove the phase oversampling
    if(~isfield(params,'remove_phase_oversampling'))
        params.remove_phase_oversampling = 0;
    end
    if (params.remove_phase_oversampling == 1 && params.phaseOversampling ~= 0)
        dim_withOver = size(ima_SoS,2);
        dim_noOver = floor(((size(ima_SoS,2))/(1+phaseOversampling))/4)*4; % is multiple of 4 (for TSE the increment are actually 16 and for GRE 2)
        ima_SoS = ima_SoS(:,(floor(dim_withOver/2) - dim_noOver/2 + 1):(floor(dim_withOver/2) + dim_noOver/2),:,:);
    end

    % Reorient the data
    orient = params.orient;
    PE_dir = params.PE_dir;
    if (orient == 1 && (PE_dir == 2 || PE_dir == 3))
        ima_SoS = permute(ima_SoS,[2,1,3,4]);
        ima_SoS = flip(ima_SoS,2);
    elseif (orient == 2 && PE_dir == 2)
        ima_SoS = flip(flip(ima_SoS,2),3);
    elseif (orient == 2 && PE_dir == 3)
        ima_SoS = permute(ima_SoS,[2,1,3,4]);
    elseif (orient == 3 && PE_dir == 3)
        ima_SoS = permute(ima_SoS,[2,1,3,4]);
    end

    % Get echo name for saving
    if (iEcho == 0)
        save_echo_string = '';
    else
        save_echo_string = sprintf('_echo%i',iEcho);
    end

    % Save image as NIFTI
    ima_SoS_nii = make_nii(squeeze(ima_SoS));
    save_nii(ima_SoS_nii,fullfile(dir,sprintf('%s%s.nii',name,save_echo_string)));
    
end
