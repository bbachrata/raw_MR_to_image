function save_nii_from_kspace_noCut_multiecho(kspace, dir, name, is2D)

    if (is2D)
        ima = FFTOfMRIData_bb(kspace,0,[2 3],1); 
    else
        ima = FFTOfMRIData_bb(kspace,0,[2 3 4],1);
    end

    ima_SoS = squeeze(sqrt(sum((abs(ima).^2),1)));
    ima_SoS_nii = make_nii(squeeze(ima_SoS));
    save_nii(ima_SoS_nii,fullfile(dir,sprintf('%s.nii',name)));

end