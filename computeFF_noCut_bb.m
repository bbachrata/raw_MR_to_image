function FF = computeFF_noCut_bb(kspace_water, kspace_fat, is2D)
%% BB: based on computeFF function by Hernando from water_fat_toolbox   
 
if (is2D)
    water = FFTOfMRIData_bb(kspace_water,0,[2 3],1); 
    fat = FFTOfMRIData_bb(kspace_fat,0,[2 3],1); 
else
    water = FFTOfMRIData_bb(kspace_water,0,[2 3 4],1);
    fat = FFTOfMRIData_bb(kspace_fat,0,[2 3 4],1);
end


water = squeeze(sqrt(sum((abs(water).^2),1)));
fat = squeeze(sqrt(sum((abs(fat).^2),1)));

summed = (abs(fat) + abs(water));
summed(summed==0) = 10e-10; % To avoid divide-by-zero issues
FF = 100*abs(fat)./summed;


% if (smurf_ff_bias_correct)
%     
%     [fat_weight,water_weight] = smurf_ff_bias_correction(is7T,TEs);
%     
%     kspace_fat = kspace_fat/fat_weight;
%     kspace_water = kspace_water/water_weight;
%     
%     if (is2D)
%         water = FFTOfMRIData_bb(kspace_water,0,[2 3],1); 
%         fat = FFTOfMRIData_bb(kspace_fat,0,[2 3],1); 
%     else
%         water = FFTOfMRIData_bb(kspace_water,0,[2 3 4],1);
%         fat = FFTOfMRIData_bb(kspace_fat,0,[2 3 4],1);
%     end
% 
%     water = squeeze(sqrt(sum((abs(water).^2),1)));
%     fat = squeeze(sqrt(sum((abs(fat).^2),1)));
% 
%     summed = (abs(fat) + abs(water));
%     summed(summed==0) = 10e-10; % To avoid divide-by-zero issues
%     FF_corr = 100*abs(fat)./summed;
% 
% end


end
