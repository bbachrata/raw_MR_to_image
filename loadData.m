function [kspace_aliased, params, kspace_prescan] = loadData(kspace_aliased_path, kspace_prescan_path, useGrappaPrescan) 
% BB: Load the main scan, reference scan and get the acquisition parameters.         
    
    % Get the main image
    kspaceStruct_aliased = mapVBVD(kspace_aliased_path);
    if (iscell(kspaceStruct_aliased))
        kspaceStruct_aliased = kspaceStruct_aliased{1,end};
    end
    kspaceStruct_aliased.image.flagIgnoreSeg = true;
    kspace_aliased = single(kspaceStruct_aliased.image{''});
    kspace_aliased = permute(kspace_aliased,[2,1,3,4,5]);      


    % Get the configuration file
    config = kspaceStruct_aliased.hdr.Config;
    
    % Check if TSE sequence
    if strfind(config.SequenceFileName, 'tse')
        isTurbo = true;
    else
        isTurbo = false;
    end
    
    % Get parallel imaging acceleration
    iPat = kspaceStruct_aliased.hdr.Phoenix.sPat.lAccelFactPE;
    
    % Get the number of image lines
    nLines = kspaceStruct_aliased.hdr.Dicom.lBaseResolution;
    if (iPat == 3 && (mod(nLines,iPat) == 0))
        nLines = nLines - 2;
        isGrappaCutFOV = true;
    else
        isGrappaCutFOV = false;
    end

    % Get phase FOV fraction
%     if(isfield(config,'ReadoutOversamplingFactor'))
%         PE_FOV_fraction = 1/config.ReadoutOversamplingFactor;    
%     else
%         PE_FOV_fraction = 0;
%     end
    PE_FOV_fraction = config.PeFOV/config.RoFOV;
    if (PE_FOV_fraction ~= 1)
        nLines = config.NImageLins;
    end
    
    % Get phase oversampling
    if(isfield(config,'phaseOversampling') && (~isempty(config.phaseOversampling)))
        phaseOversampling = config.phaseOversampling;    
%         nLines = config.PhaseEncodingLines;
    else
        phaseOversampling = 0;
    end
    
    % Get excitation mode
    if (config.Is3D)
        is2D = false;
    else
        is2D = true;   
    end 
    
    % Get partial Fourier factors and the number of image slices
    isPhasePF = false;
    isSlicePF = false;
    nSlices = 0;
    if (config.PhasePartialFourierFactor~=16)
        isPhasePF = true;
    end
    if (~is2D && (config.NoOfFourierPartitions ~= config.NoImagesPerSlab))
        isSlicePF = true;
        nSlices = config.NoImagesPerSlab;
    end
    
    % Get slice acquisition order
    if (is2D && (abs(config.chronSliceIndices(2)-config.chronSliceIndices(1)) ~= 1))
        isInterleaved = true;
    else 
        isInterleaved = false;
    end

  
    % Should we load reference scan
    if((~exist('kspace_prescan_path','var')) && (~exist('useGrappaPrescan','var')))
        loadRefScan = false;    
    else
        loadRefScan = true;
    end

    % Do we load separate prescan or ACS lines acquired with parallel
    % imaging acceleration
    if(~exist('useGrappaPrescan','var'))
        useGrappaPrescan = false;    
    end
 
    % Get the reference image
    if (loadRefScan)
        if (~useGrappaPrescan) 
            % use separately acquired prescan
            kspaceStruct_prescan = mapVBVD(kspace_prescan_path);
            if (iscell(kspaceStruct_prescan))
                kspaceStruct_prescan = kspaceStruct_prescan{1,end};
            end
            kspace_prescan = single(kspaceStruct_prescan.image{''});
        else
            % use GRAPPA refscan
            kspace_prescan = single(kspaceStruct_aliased.refscan{''});
        end    
        
        % Resample the reference image
        kspace_prescan = permute(kspace_prescan,[2,1,3,4,5]);    
    end
    
    
    % Save the parameters required for further processing
    params.isTurbo = isTurbo;
    params.PE_FOV_fraction = PE_FOV_fraction;
    params.phaseOversampling = phaseOversampling;
    params.isPhasePF = isPhasePF;
    params.isSlicePF = isSlicePF;
    params.is2D = is2D;
    params.nSlices = nSlices;
    params.isInterleaved = isInterleaved;
    params.nLines = nLines;
    params.iPat = iPat;
    params.isGrappaCutFOV = isGrappaCutFOV;

end