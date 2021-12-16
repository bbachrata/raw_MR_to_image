function saveFatAndRecombined(kspace_fat, kspace_water, output_dir, is2D, correction_suffix) 
% BB: Save intermediate fat and recombined images
 
    % Recombine water and fat
    kspace_recombined = kspace_water + kspace_fat;
    clear kspace_water
    
    % Save recombined images
    save_nii_from_kspace_noCut_multiecho(kspace_recombined, output_dir, sprintf('recombined%s',correction_suffix), is2D);   
    save_nii_from_kspace_uncomb_noCut_multiecho(kspace_recombined, output_dir, sprintf('recombined%s_uncomb',correction_suffix), is2D);

    % Save fat images
    if (~(isempty(correction_suffix)))
        save_nii_from_kspace_noCut_multiecho(kspace_fat, output_dir, sprintf('fat%s',correction_suffix), is2D);   
        save_nii_from_kspace_uncomb_noCut_multiecho(kspace_fat, output_dir, sprintf('fat%s_uncomb',correction_suffix), is2D);
    end
end