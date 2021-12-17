function save_nii_from_kspace_uncomb(kspace, dir, name, params)

if(~isfield(params,'remove_phase_oversampling'))
	params.remove_phase_oversampling = 0;
end


if (params.is2D == 1)
    ima = FFTOfMRIData(kspace,0,[2 3],1); 
else
    ima = FFTOfMRIData(kspace,0,[2 3 4],1);
end

ima = ima(:,(size(ima,2)*0.25 + 1):(size(ima,2)*0.75),:,:,:);


if (params.remove_phase_oversampling == 1 && params.phaseOversampling ~= 0)
    dim_withOver = size(ima,3);
    dim_noOver = floor(((size(ima,3))/(1+params.phaseOversampling))/4)*4; % is multiple of 4 (for TSE the increment are actually 16 and for GRE 2)
    ima = ima(:,:,(floor(dim_withOver/2) - dim_noOver/2 + 1):(floor(dim_withOver/2) + dim_noOver/2),:);
end


orient = params.orient;
PE_dir = params.PE_dir;
if (orient == 1 && PE_dir == 2)
    ima = permute(ima,[3,2,4,1,5]);
    ima = flip(ima,2);
elseif (orient == 2 && PE_dir == 2)
    ima = permute(ima,[2,3,4,1,5]);
    ima = flip(flip(ima,2),3);
elseif (orient == 2 && PE_dir == 3)
   ima = permute(ima,[3,2,4,1,5]);
elseif (orient == 3 && PE_dir == 3)
    ima = permute(ima,[3,2,4,1,5]);
else 
    ima = permute(ima,[2,3,4,1,5]);
    ima = flip(ima,2);
end


save_nii(make_nii(squeeze(abs(ima))),fullfile(dir,sprintf('mag_%s',name)));
save_nii(make_nii(squeeze(angle(ima))),fullfile(dir,sprintf('phase_%s',name)));


end
