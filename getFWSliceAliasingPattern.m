function slcAlias = getFWSliceAliasingPattern(kspace,params) 
% BB: The fat and water (FW) are shifted relative by CAIPIRINHA to allow their
% separation. In case of 3D imaging this shift is applied along both
% phase-encoding directions. Here we assess which slices of fat and water
% do overlap in the acquired image.

    nDims = ndims(kspace);
    nSlc = size(kspace,nDims);
    slcAlias = zeros(nSlc,2);
    iPat = params.iPat;
    
    % 2D data - the aliasing fat and water signals origin from the same slice
    if (params.is2D) 
        for iSlc = 1 : (2 * nSlc)
            slcAlias(iSlc) = iSlc;
        end
        
    % 3D data - due to the phase encoding in the slice direction, the aliasing fat and water signals origin from different slice 
    % (with the pattern depending on the iPat)
    else 
        
        if (iPat == 1 || iPat == 3)
            slcAlias = zeros(nSlc,2);
            for lSlc=1:nSlc
                slcAlias(lSlc)=lSlc;
            end
            for lSlc=(nSlc+1):(nSlc+nSlc/2+1)
                slcAlias(lSlc)=nSlc/2+lSlc;
            end
            for lSlc=(nSlc+nSlc/2+1):(2*nSlc)
                slcAlias(lSlc)=lSlc-nSlc/2;
            end   
            
        elseif (iPat == 2)
            slcAlias = zeros(nSlc,2);
            for lSlc=1:nSlc
                slcAlias(lSlc)=lSlc;
            end
            for lSlc=(nSlc+1):(nSlc+2*round(nSlc/3))
                slcAlias(lSlc)=lSlc+floor(nSlc/3);
            end
            for lSlc=(nSlc+2*round(nSlc/3)+1):(2*nSlc)
                slcAlias(lSlc)=lSlc-2*floor(nSlc/3);
            end
                        
        end   
        
    end 
    
    slcAlias = [slcAlias; slcAlias];

end