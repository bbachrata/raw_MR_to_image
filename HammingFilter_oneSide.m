function [OutArray,HammingFilter] = HammingFilter_oneSide(OutArray,ApplyAlongDims,FilterWidth,InputIskSpace_flag)
%
% HammingFilter Apply an Hamming filter to (k-space) data
%
% This function was written by Bernhard Strasser, July 2012 - July 2014.
%
%
% The function applies a Hamming filter to the input-data. You can specify along which dimensions this should be done (e.g. [2 4 5 6]). You can
% also specify the filter width in %, e.g. a FilterWidth of 70 % leaves the inner 30% of the k-Space untouched and applies the filter only
% along the 70 % of the outer data.If you tell the function that the Input is already in kSpace, no fft is performed before applying
% the filter.
%
%
% [OutArray,HammingFilter] = HammingFilter(InArray,ApplyAlongDims,FilterWidth,RadialOrOuterProduct,InputIskSpace_flag)
%
% Input: 
% -         InArray                    ...    Input array to which the filter should be applied. For memory reasons InArray = OutArray.
% -         ApplyAlongDims             ...    Along these dimensions the filter is applied. If this vector has two elements, a two dimensional 
%                                             Filter is applied. Otherwise, a 3d filter is used.
% -         FilterWidth                ...    Filter Width of 1 (100%) means normal hamming filter,
%                                             filter width of n % means filter is only applied on n % (n % on right) of
%                                             the data, the rest of the data is untouched. 
% Output:
% -         OutArray                   ...    The filtered/masked output array
% -         HammingFilter              ...    The values of the Hamming filter in k-Space.
%
% -         InputIskSpace_flag         ...    If it is 0, the image gets Fourier transformed to k-space before applying the filter, 
%                                             and transformed back to image domain afterwards
%
% Feel free to change/reuse/copy the function. 
% If you want to create new versions, don't degrade the options of the function, unless you think the kicked out option is totally useless.
% Easier ways to achieve the same result & improvement of the program or the programming style are always welcome!
% File dependancy: myrepmat_1_0

% Further remarks: 



%% 0. Declarations, Preparations, Definitions

%OutArray = InArray; 
if(~exist('OutArray','var'))
	fprintf('\nHamming Filtering could not be performed.\nMore input needed.')
	return
end
if(~exist('ApplyAlongDims','var'))
	fprintf('\nWARNING: No dimensions specified along which Hamming Filter should be applied.\nFiltering along dim 1 with size %d',size(OutArray,1))
	ApplyAlongDims = 1;
end
if(~exist('FilterWidth','var'))
	FilterWidth = 1;
end
if(~exist('InputIskSpace_flag','var'))
	InputIskSpace_flag = true;
end

Size_OutArray = size(OutArray);



%% 1. FFT to k-space

if(~InputIskSpace_flag)
    for hamming_dim = ApplyAlongDims
        OutArray = ifftshift(OutArray,hamming_dim);
        OutArray = ifft(OutArray,[],hamming_dim);
        OutArray = fftshift(OutArray,hamming_dim);
    end
end




%% 2. Compute Hamming Filter

HammingFilter = ones(size(OutArray));	
for hamming_dim = ApplyAlongDims                                            % Compute Hamming filter in each dimension seperately


    RepmatToSizeOfMatrixIn = size(OutArray);                                % The Hamming-filter must have the same size as the OutArray
    RepmatToSizeOfMatrixIn(hamming_dim) = 1;                                % Do not repmat in that dimension, in which hamming filtering is performed.

    %calculate Hamming filter
    n = size(OutArray,hamming_dim);
    hamming_1D = hamming(ceil(FilterWidth*n*2));
    hamming_1D = hamming_1D(ceil(length(hamming_1D)/2)+1:end);
    hamming_1D = cat(1, ones([n-numel(hamming_1D) 1]), hamming_1D);


    if(hamming_dim == 1)
        hamming_1D_LeadingOnes = hamming_1D;
    else
        reshape_to = horzcat(ones([1 hamming_dim-1]), numel(hamming_1D));       % This creates e.g. a vector [1 1 1 1 64]
        hamming_1D_LeadingOnes = reshape(hamming_1D,reshape_to);                % Reshapes hamming filter to above size
    end

    HammingFilter = repmat(hamming_1D_LeadingOnes, RepmatToSizeOfMatrixIn) ...  % Replicate 1d-Hamming to the matrix size, 
                    .* HammingFilter;                                           % Multiply this array with the previous calculated array
                                                                                % but now the hamming-variation is in another dimension
end




%% 3. Apply Hamming Filter

OutArray = OutArray .* HammingFilter;




%% 4. FFT to Image Space

if(~InputIskSpace_flag)
    
    for hamming_dim = ApplyAlongDims
        OutArray = ifftshift(OutArray,hamming_dim);
        OutArray = fft(OutArray,[],hamming_dim);
        OutArray = fftshift(OutArray,hamming_dim);
    end
    
end




end

