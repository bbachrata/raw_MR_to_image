function kspace = collapseKSpaceByIPat(kspace, undersamplingPattern, params)
% The kspace lines, which were not measured because of GRAPPA are being
% skipped and therefore the final kspace size is decreased by the iPat factor

    iPat = params.iPat;   
    for i = 1:iPat
        if (undersamplingPattern(i) == 1)
            iAcq = i;
            break
        end
    end
    
    kspace = kspace(:,:,iAcq:iPat:end,:);
   
end