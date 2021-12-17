function kspace = load_nii_uncomb_multiecho(dir, name, is2D)
% BB: load mag and phase images and convert to complex k-space

    % Create file names
    mag_file = sprintf('mag_%s_uncomb.nii',name);
    phase_file = sprintf('phase_%s_uncomb.nii',name);
    
    % Load images
    mag_nii = load_nii(fullfile(dir,mag_file));
    phase_nii = load_nii(fullfile(dir,phase_file));
    mag = single(mag_nii.img);
    phase = single(phase_nii.img);
    clear mag_nii phase_nii

    % Convert to complex
    cx = mag.*exp(1i*phase);
    clear mag phase

    cx = permute(cx,[4,1,2,3,5]);

    % Get k-space
    if (is2D)
%         for 2D data with odd number of slices the FFTs (I guess when applied odd number of times) result in shifted slices (first slice at the position of last one) - needs to be corrected
        if (mod(size(cx,3),2) == 1)  
            cx = cx(:,:,[end,(1:end-1)],:,:); 
        end
        kspace = FFTOfMRIData(cx,0,[2 3],0);

    else
        kspace = FFTOfMRIData(cx,0,[2 3 4],0); 
    end
    
    

end
