function save_nii_from_kspace_uncomb_separateecho(kspace, dir, name, iEcho, params)

if(~exist('params.remove_phase_oversampling','var'))
	params.remove_phase_oversampling = 0;
end


if (params.is2D == 1)
    ima = FFTOfMRIData_bb(kspace,0,[2 3],1); 
else
    ima = FFTOfMRIData_bb(kspace,0,[2 3 4],1);
end

ima = ima(:,(size(ima,2)*0.25 + 1):(size(ima,2)*0.75),:,:);


if (params.remove_phase_oversampling == 1)
    dim_withOver = size(ima,3);
    dim_noOver = floor(((size(ima,3))/(1+params.phase_oversampling))/4)*4; % is multiple of 4 (for TSE the increment are actually 16 and for GRE 2)
    ima = ima(:,:,(floor(dim_withOver/2) - dim_noOver/2 + 1):(floor(dim_withOver/2) + dim_noOver/2),:);
end


orient = params.orient;
PE_dir = params.PE_dir;
if (orient == 1 && PE_dir == 2)
    ima = permute(ima,[3,2,4,1]);
    ima = flip(ima,2);
elseif (orient == 2 && PE_dir == 2)
    ima = permute(ima,[2,3,4,1]);
    ima = flip(flip(ima,2),3);
elseif (orient == 2 && PE_dir == 3)
   ima = permute(ima,[3,2,4,1]);
elseif (orient == 3 && PE_dir == 3)
    ima = permute(ima,[3,2,4,1]);
else 
    ima = permute(ima,[2,3,4,1]);
    ima = flip(ima,2);
end


if (iEcho == 0)
    save_echo_string = '';
else
    save_echo_string = sprintf('_echo%i',iEcho);
end

save_nii(make_nii(squeeze(abs(ima))),fullfile(dir,sprintf('mag_%s%s.nii',name,save_echo_string)));
save_nii(make_nii(squeeze(angle(ima))),fullfile(dir,sprintf('phase_%s%s.nii',name,save_echo_string)));


end