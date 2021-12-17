function [TE, is2D, CaipiOffsetCorr, T1WeightFactor, type1PixelShift, type2PhaseOffset, isTurbo] = getAcqParams(path, rBW, T1_w, T1_f)
% BB: Get the acquistion parameters and correction factors required for further processing
        
    % Load data
    struct = mapVBVD(path);
    if (iscell(struct))
        struct = struct{1,end};
    end
    
    % Get acquisiton paramteres
    if (struct.hdr.Config.Is3D==1)
        is2D = 0;
    else 
        is2D = 1;
    end
    
    if strcmp(struct.hdr.Config.SequenceFileName, '%CustomerSeq%\bb_caipitse')
        isTurbo = true;
    else
        isTurbo = false;    
    end  
    
    iPat = struct.hdr.Dicom.lAccelFactPE;
    for i = 1:struct.hdr.MeasYaps.lContrasts
        TE(i) = struct.hdr.MeasYaps.alTE{i}/1000;
    end
    
    adWIPs = struct.hdr.Phoenix.sWipMemBlock.adFree;
    if (isTurbo) % TSE data
        CaipiOffsetCorr = 1; %% TODO: is this true
        FA_f = adWIPs{8};
    else % GRE data
        CaipiOffsetCorr = 0;
        FA_f = adWIPs{10};   
    end
    
    
    %% Get T1 Corr factor    
    TR = struct.hdr.MeasYaps.alTR{1}/1000;
    FA_w = struct.hdr.Dicom.adFlipAngleDegree;
    
    FAr_w = (FA_w/180)*pi;
    FAr_f = (FA_f/180)*pi;

    M_w = (sin(FAr_w)*(1-exp(-TR/T1_w)))/(1-cos(FAr_w)*exp(-TR/T1_w));
    M_f = (sin(FAr_f)*(1-exp(-TR/T1_f)))/(1-cos(FAr_f)*exp(-TR/T1_f));

    T1WeightFactor = M_f/M_w;
    
    
    %% Get Type 1 chemical shift displacement correction
    freqDiff = -3.4*struct.hdr.Dicom.lFrequency/1000000;
    type1PixelShift = freqDiff/rBW;

    
    %% Get Type 2 chemical shift correction phase (TE-dependant fat phase offset)
    T2Pi = 1000/freqDiff;  
    type2PhaseOffset = mod(TE,T2Pi)/T2Pi*2;  
    

end
