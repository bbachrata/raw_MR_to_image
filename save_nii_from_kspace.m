function save_nii_from_kspace(kspace, dir, name, params)

if(~exist('params.remove_phase_oversampling','var'))
	params.remove_phase_oversampling = 0;
end


if (params.is2D == 1)
    ima = FFTOfMRIData(kspace,0,[2 3],1); 
else
    ima = FFTOfMRIData(kspace,0,[2 3 4],1);
end

ima_SoS = squeeze(sqrt(sum((abs(ima).^2),1)));
ima_SoS = ima_SoS((size(ima_SoS,1)*0.25 + 1):(size(ima_SoS,1)*0.75),:,:,:);


if (params.remove_phase_oversampling == 1 && params.phase_oversampling ~= 0)
    dim_withOver = size(ima_SoS,2);
    dim_noOver = floor(((size(ima_SoS,2))/(1+phase_oversampling))/4)*4; % is multiple of 4 (for TSE the increment are actually 16 and for GRE 2)
    ima_SoS = ima_SoS(:,(floor(dim_withOver/2) - dim_noOver/2 + 1):(floor(dim_withOver/2) + dim_noOver/2),:,:);
end

orient = params.orient;
PE_dir = params.PE_dir;
if (orient == 1 && PE_dir == 2)
    ima_SoS = permute(ima_SoS,[2,1,3,4]);
    ima_SoS = flip(ima_SoS,2);
elseif (orient == 2 && PE_dir == 2)
    ima_SoS = flip(flip(ima_SoS,2),3);
elseif (orient == 2 && PE_dir == 3)
    ima_SoS = permute(ima_SoS,[2,1,3,4]);
elseif (orient == 3 && PE_dir == 3)
    ima_SoS = permute(ima_SoS,[2,1,3,4]);
end
    

ima_SoS_nii = make_nii(squeeze(ima_SoS));
save_nii(ima_SoS_nii,fullfile(dir,name));
    

end
