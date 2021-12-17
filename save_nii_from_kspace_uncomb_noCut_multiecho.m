function save_nii_from_kspace_uncomb_noCut_multiecho(kspace, dir, name, is2D)

    if (is2D)
        ima = FFTOfMRIData(kspace,0,[2 3],1); 
    else
        ima = FFTOfMRIData(kspace,0,[2 3 4],1);
    end

    ima = permute(ima,[2,3,4,1,5]);
    save_nii(make_nii(squeeze(abs(ima))),fullfile(dir,sprintf('mag_%s.nii',name)));
    save_nii(make_nii(squeeze(angle(ima))),fullfile(dir,sprintf('phase_%s.nii',name)));

end
