function [kspace_big,expandPattern] = expandKSpaceByIPat(kspace, params, expandPattern)
% BB: The kspace lines, which were not measured because of GRAPPA are being artifically
% added and therefore the final kspace size is increased by the iPat factor

    dims = size(kspace);
    iPat = params.iPat;
    kspace_big = zeros(dims(1), dims(2), params.nLines, dims(4));

    if (params.isPhasePF == true && ((dims(3)*iPat-1) > params.nLines))
        kspace = kspace(:,:,1:end-1,:);
    end

    if(~exist('expandPattern','var'))
        if (iPat == 2)
            expandPattern = [0,1];
        elseif (iPat == 3)
            if (mod(params.nLines,iPat) == 1)
                expandPattern = [0,1,0];
            elseif (mod(params.nLines,iPat) == 2)
                expandPattern = [1,0,0];
            else 
                expandPattern = [0,0,1];
            end
        end

    end
    
    for i = 1:iPat
        if (expandPattern(i) == 1)
            iAcq = i;
            break
        end
    end
    
    last = size(kspace,3)*iPat;
    kspace_big(:,:,iAcq:iPat:last,:) = kspace;
%     kspace_big(:,:,iAcq:iPat:end,:) = kspace;

    
end