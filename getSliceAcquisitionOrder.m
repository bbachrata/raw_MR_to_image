function slcOrder = getSliceAcquisitionOrder(kspace, params) 
% BB: Depending on the number of acquired slices, the slice order for interleaved acquisition varries 

    nSlc = size(kspace,4);
    slcOrder = zeros(1,nSlc);
    
    if (params.is2D && params.isInterleaved) %% 2D data
        if (mod(nSlc,2) == 0)
            slcOrder(1:2:nSlc) = ((nSlc/2+1):nSlc);
            slcOrder(2:2:nSlc) = (1:nSlc/2);
        else 
            slcOrder(1:2:nSlc) = (1:ceil(nSlc/2));
            slcOrder(2:2:nSlc) = ((ceil(nSlc/2)+1):nSlc);
        end
    else %% 3D data
        slcOrder = 1:nSlc;
    end
        
end