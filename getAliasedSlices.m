function aliasingPattern = getFatWaterAliasingPattern(kspace,params) 
% BB: add explanation

    nDims = ndims(kspace);
    nSlc = size(kspace,nDims);
    aliasingPattern = zeros(nSlc,2);
    iPat = params.iPat;
    
    if params.is2D == 1 %% 2D data
        for iSlc = 1 : (2 * nSlc)
            aliasingPattern(iSlc) = iSlc;
        end
        
    else %% 3D data
        
        if (iPat == 1 || iPat == 3)
            aliasingPattern = zeros(nSlc,2);
            for lSlc=1:nSlc
                aliasingPattern(lSlc)=lSlc;
            end
            for lSlc=(nSlc+1):(nSlc+nSlc/2+1)
                aliasingPattern(lSlc)=nSlc/2+lSlc;
            end
            for lSlc=(nSlc+nSlc/2+1):(2*nSlc)
                aliasingPattern(lSlc)=lSlc-nSlc/2;
            end   
            
        elseif (iPat == 2)
            aliasingPattern = zeros(nSlc,2);
            for lSlc=1:nSlc
                aliasingPattern(lSlc)=lSlc;
            end
            for lSlc=(nSlc+1):(nSlc+2*round(nSlc/3))
                aliasingPattern(lSlc)=lSlc+floor(nSlc/3);
            end
            for lSlc=(nSlc+2*round(nSlc/3)+1):(2*nSlc)
                aliasingPattern(lSlc)=lSlc-2*floor(nSlc/3);
            end
            
%             for lSlc=(nSlc+1):(nSlc+round(nSlc/3))
%                 sliceAliasingPattern(lSlc)=lSlc+2*round(nSlc/3);
%             end
%             for lSlc=(nSlc+round(nSlc/3)+1):(2*nSlc)
%                 sliceAliasingPattern(lSlc)=lSlc-round(nSlc/3);
%             end
            
        end   
        
    end 
    
    aliasingPattern = [aliasingPattern; aliasingPattern];

end