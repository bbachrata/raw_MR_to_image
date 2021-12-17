function saveCorrectionValues(output_dir, type2PhaseOffset, type1PixelShift, T1WeightFactor)

%set name of the saved file
fileName='correction_details.txt';

%open file identifier
fid=fopen(fullfile(output_dir,fileName),'w');

stringType2PhaseOffset = '';
for i = 1:length(type2PhaseOffset)
    stringType2PhaseOffset = fullfile(stringType2PhaseOffset,sprintf('%s',type2PhaseOffset(i)));    
end

%print into a file.
fprintf(fid, ['type2PhaseOffset: %s \n', ...
              'type1PixelShift: %s \n', ...
              'T1WeightFactor: %s \n'], stringType2PhaseOffset, type1PixelShift, T1WeightFactor);

%close file indentifier
fclose(fid)

end
