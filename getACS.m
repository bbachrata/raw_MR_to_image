function kspace_ACS = getACS(kspace_prescan, params, FOVShifts)
% BB: add explanation

if (params.is2D == 0)
    kspace_prescan = FFTOfMRIData(kspace_prescan,0,[4],1);
end

kspace_ACS = cat(4, kspace_prescan, kspace_prescan);
kspace_ACS = kSpace_FoVShift(kspace_ACS, FOVShifts);

if (params.is2D == 0)
    kspace_ACS = FFTOfMRIData(kspace_ACS,0,[4],0);
end

end
