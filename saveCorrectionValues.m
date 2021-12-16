function saveCorrectionValues(output_dir, type2PhaseOffset, type1PixelShift, T1WeightFactor, SmurfBiasCorr, T2sWeightFactor)

%set name of the saved file
fileName='correction_details.txt';

%open file identifier
fid=fopen(fullfile(output_dir,fileName),'w');

stringType2PhaseOffset = '';
for i = 1:length(type2PhaseOffset)
    stringType2PhaseOffset = fullfile(stringType2PhaseOffset,sprintf('%s',type2PhaseOffset(i)));    
end

stringSmurfBiasCorr = '';
for i = 1:length(SmurfBiasCorr)
    stringSmurfBiasCorr = fullfile(stringSmurfBiasCorr,sprintf('%s',SmurfBiasCorr(i)));    
end

stringT2sWeightFactor = '';
for i = 1:length(T2sWeightFactor)
    stringT2sWeightFactor = fullfile(stringT2sWeightFactor,sprintf('%s',T2sWeightFactor(i)));    
end

%print into a file.
fprintf(fid, ['type2PhaseOffset: %s \n', ...
              'type1PixelShift: %s \n', ...
              'T1WeightFactor: %s \n', ...
              'smurfFFBiasCorr: %s \n', ...
              'T2WeightFactor: %s \n'], stringType2PhaseOffset, type1PixelShift, T1WeightFactor, stringSmurfBiasCorr, stringT2sWeightFactor);

%close file indentifier
fclose(fid)

end
