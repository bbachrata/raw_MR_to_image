function kspace = correctChemicalShiftDisplacement(kspace,shift)
% Correct for chemical shift artefct in k-space

FoVChemShift = zeros(size(kspace,4),2);
kspace = permute(kspace, [1,3,2,4,5]);
FoVChemShift(:,1) = shift/size(kspace,2);
kspace = kSpace_FoVShift(kspace, FoVChemShift);
kspace = permute(kspace, [1,3,2,4,5]);

end