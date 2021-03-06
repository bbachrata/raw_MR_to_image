function InData = FFTOfMRIData(InData,ConjFlag,ApplyAlongDims,Ifft_flag)
%
% read_csi_dat Read in csi-data from Siemens raw file format
%
% This function was written by Bernhard Strasser, July 2012.
%
%
% The function can read in MRS(I) data in the Siemens raw file format ".DAT" and performs
% some easy Postprocessing steps like zerofilling, Hadamard decoding, Noise Decorrelation etc.
%
%
% [csi,NoiseCorrMat,Noise_mat,InData] = read_csi_dat(csi_path, zerofill_to_nextpow2_flag, zerofilling_fact, Hadamard_flag, x_shift,y_shift,NoFFT_flag, NoiseCorrMat)
%
% Input: 
% -         csi_path                    ...     Path of MRS(I) file.
% -         zerofill_to_nextpow2_flag   ...     Flag, if the MRSI data should be zerofilled to the next power of 2 in k-space (e.g. 42x42 sampled --> zf to 64x64?)
% -         zerofilling_fact            ...     Factor with which the MRSI data should be zerofilled in k-space for interpolation (e.g. zerofill from 64x64 to 128x128)
% -         Hadamard_flag               ...     If data is multislice hadamard encoded, perform hadamard-decoding function
% -         x_shift                     ...     Shift the MRSI data in the left-right direction ( = row direction of matrix) by x_shift voxels
% -         y_shift                     ...     Shift the MRSI data in anterior-posterior direction ( = column direction of matrix) by y_shift voxels
% -         NoFFT_flag                  ...     If this is true, don't perform any fft.
% -         NoiseCorrMat                ...     If size(NoiseCorrMat) = [cha cha]: the k-space Data gets decorrelated with this matrix. 
%                                               If NoiseCorrMat = 1: the end of the FIDs of the outermost k-space/image points are used for noise decorrelation.
%                                               If NoiseCorrMat = 0, or not existant: No Noise Decorrelation performed
%
% Output:
% -         csi                         ...     Output data in image domain. In case of Single Voxel Spectroscopy, this is the only output
% -         NoiseCorrMat                ...     The Noise Correlation Matrix in order to check if it was properly computed from the csi data. Is 0 if no decorrelation performed.
% -         Noise_mat                   ...     The Noise gathered from the CSI data. Noise_mat = 0, if not gathered.
% -         InData                  ...     Output data in k-space. In case of SVS this is zero. size: channel x ROW x COL x SLC x vecSize x Averages
%
%
% Feel free to change/reuse/copy the function. 
% If you want to create new versions, don't degrade the options of the function, unless you think the kicked out option is totally useless.
% Easier ways to achieve the same result & improvement of the program or the programming style are always welcome!
% File dependancy: memused_linux,Analyze_csi_mdh_1_3, read_ascconv_1_2, hadamard_encoding_7.m

% Further remarks: This function uses FFTs to get from k- to image-space. This is mathematically wrong, but Siemens seems to do the same when
% creating DICOMS. The only difference is that the images are flipped left/right and up/down.





%% 0. Preparations


if(nargin < 1)
	fprintf('\nProblem: Cannot fft non-existant data. Provide some data.')
	InData = 0;
	return;
end
if(nargin < 2)
	ConjFlag = false;
end
if(nargin < 3)
	ApplyAlongDims = [2 3 4];
end
if(nargin < 4)
	Ifft_flag = false;
end


if(size(InData,2) == 1 && size(InData,3) == 1 && size(InData,4) == 1)
	InData = conj(InData);
	fprintf('\nDid only conj, no fft.')
	return;
end




%% 1. Memory Considerations - Find best Looping

size_InData = size(InData);

[dummy, MemFree] = memused_linux(1);
MemNecessary = numel(InData)*8*2*2/2^20;							% every entry of InData is double --> 8 bytes. *2 because complex. *2 as safety measure (so InData fits 2 times in memory,
																	% once it is already there and 2 more times it should fit in). /2^20 to get from bytes to MB.
if(MemNecessary > MemFree)
	LoopOverIndex = MemFree ./ (MemNecessary./size_InData(1:end));	% Because the 1st index is the coil. We can never loop over the coils.
	LoopOverIndex(LoopOverIndex < 1) = NaN;
	LoopOverIndex(ApplyAlongDims) = NaN;
	LoopOverIndex = find(nanmin(LoopOverIndex));
	LoopOverIndex = LoopOverIndex(1);								% Only take the 1st if several are the minimum.
	AccessString = [repmat(':,',[1 LoopOverIndex-1]) 'LoopIndex,' repmat(':,',[1 numel(size_InData)-LoopOverIndex])];
	AccessString(end) = [];
%     LoopOverIndex = 5;								% Only take the 1st if several are the minimum.
% 	AccessString = [repmat(':,',[1 LoopOverIndex-1]) 'LoopIndex,' repmat(':,',[1 numel(size_InData)-LoopOverIndex])];
% 	AccessString(end) = [];
end




%% 2. FFT


tic_overall = tic;		



if(sum(ApplyAlongDims == 2) == 1 && Ifft_flag)	% Only if the second dimension is to be applied
	InData = flipdim(InData,2);		% THIS FLIPS LEFT AND RIGHT IN SPATIAL DOMAIN BECAUSE PHYSICIANS WANT TO SEE IMAGES FLIPPED 
end



% Check if enough memory is available to perform whole process at once instead of looping
if(MemNecessary > MemFree)	
	
	
	for LoopIndex = 1:size(InData,LoopOverIndex)
		tic_loop = tic;
		fprintf('\nFouriertransforming Part %02d\t...\tof %02d', LoopIndex, size(InData,LoopOverIndex))

		TempData = eval(['InData(' AccessString ');']);	
		for Dimli = ApplyAlongDims
            if(Ifft_flag)
                TempData = feval('ifft',ifftshift(TempData,Dimli),[],Dimli);
            else
                TempData = feval('fft',fftshift(TempData,Dimli),[],Dimli);
            end
		end
		if(ConjFlag)
			TempData = conj(TempData);
		end
		for Dimli = ApplyAlongDims
            if(Ifft_flag)
                TempData = fftshift(TempData,Dimli);
            else
                TempData = ifftshift(TempData,Dimli);
            end
		end		
		eval(['InData(' AccessString ') = TempData;']);
		
		fprintf('\ttook\t%10.6f seconds', toc(tic_loop))       
	end
	clear TempData;


% Perform fft at once if enough memory is available
else
	fprintf('\nFouriertransforming Data at Once')
	for Dimli = ApplyAlongDims
        if(Ifft_flag)
            InData = feval('ifft',ifftshift(InData,Dimli),[],Dimli);
        else
            InData = feval('fft',fftshift(InData,Dimli),[],Dimli);
        end
	end
	if(ConjFlag)
		InData = conj(InData);
	end
	for Dimli = ApplyAlongDims
        if(Ifft_flag)
            InData = fftshift(InData,Dimli);
        else
            InData = ifftshift(InData,Dimli);
        end
	end
end
		
	

if(sum(ApplyAlongDims == 2) == 1 && ~Ifft_flag)	% Only if the second dimension is to be applied
	InData = flipdim(InData,2);		% THIS FLIPS LEFT AND RIGHT IN SPATIAL DOMAIN BECAUSE PHYSICIANS WANT TO SEE IMAGES FLIPPED 
end
fprintf('\nOverall FFT Process\t\t...\ttook\t%10.6f seconds', toc(tic_overall))





