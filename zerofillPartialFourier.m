function kspace = zerofillPartialFourier(kspace,params) 
% BB: Zerofill data with partial Fourier. Before the zerofilling,
% pre-filtering of the data is applied to remove artefacts
% caused by sharp edge in the k-space. 

    dims = size(kspace);
    dims_new = dims;

    if (params.isPhasePF)

        % apply Hamming filtering to suppress sort of ringing artefact
        kspace = HammingFilter_oneSide(kspace,[3],0.1,1); 

        % get zerofilled full-sized k-space 
        dims_new(3) = params.nLines;
        temp = zeros(dims_new);
        temp(:,:,1:dims(3),:,:) = kspace;
        kspace = temp;
    end   
    if (params.isSlicePF)

        % apply Hamming filtering to suppress sort of ringing artefact
        kspace = HammingFilter_oneSide(kspace,[4],0.1,1); 

        % get zerofilled full-sized k-space 
        dims_new(4) = params.nSlices;
        temp = zeros(dims_new);
        temp(:,:,:,1:dims(4),:) = kspace;
        kspace = temp;
    end
        
end

