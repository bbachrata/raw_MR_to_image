function FF = computeFF_noCut(kspace_water, kspace_fat, is2D)
%% BB: based on computeFF function by Hernando from water_fat_toolbox   
 
if (is2D)
    water = FFTOfMRIData(kspace_water,0,[2 3],1); 
    fat = FFTOfMRIData(kspace_fat,0,[2 3],1); 
else
    water = FFTOfMRIData(kspace_water,0,[2 3 4],1);
    fat = FFTOfMRIData(kspace_fat,0,[2 3 4],1);
end


water = squeeze(sqrt(sum((abs(water).^2),1)));
fat = squeeze(sqrt(sum((abs(fat).^2),1)));

summed = (abs(fat) + abs(water));
summed(summed==0) = 10e-10; % To avoid divide-by-zero issues
FF = 100*abs(fat)./summed;


end
