function [undersampling_cell,FOVShifts] = getUndersamplingPattern(kspace,params) 
% BB: Read over data and get the iPat factor, undersampling pattern and define
% how is the off resonance image shifted relative to the on resonance one

    FOVShift_OnReson = zeros(size(kspace,4),2); 
    FOVShift_OffReson = zeros(size(kspace,4),2);
    kspace_PE = kspace(1,1,1:4,1);

    % iPat = 1
    if (kspace_PE(1) ~= 0 && kspace_PE(2) ~= 0 && kspace_PE(3) ~= 0 && kspace_PE(4) ~= 0)
        undersampling_cell = [1]; 
        FOVShift_OffReson(:,2)=0.5;

    % iPat = 2
    elseif (kspace_PE(1) ~= 0 && kspace_PE(2) == 0 && kspace_PE(3) ~= 0 && kspace_PE(4) == 0)
        undersampling_cell = [1,0];
       if (params.is2D)
           FOVShift_OffReson(:,2)=1/3;
       else
            FOVShift_OffReson(:,2)=2/3;
       end
    elseif (kspace_PE(1) == 0 && kspace_PE(2) ~= 0 && kspace_PE(3) == 0 && kspace_PE(4) ~= 0)
        undersampling_cell = [0,1]; 
       if (params.is2D)
           FOVShift_OffReson(:,2)=1/3;
       else
            FOVShift_OffReson(:,2)=2/3;
       end
        
    % iPat = 3
    elseif (kspace_PE(1) ~= 0 && kspace_PE(2) == 0 && kspace_PE(3) == 0 && kspace_PE(4) ~= 0)
        undersampling_cell = [1,0,0];
        FOVShift_OffReson(:,2)=0.5;
    elseif (kspace_PE(1) == 0 && kspace_PE(2) ~= 0 && kspace_PE(3) == 0 && kspace_PE(4) == 0)
        undersampling_cell = [0,1,0]; 
        FOVShift_OffReson(:,2)=0.5;
    elseif (kspace_PE(1) == 0 && kspace_PE(2) == 0 && kspace_PE(3) ~= 0 && kspace_PE(4) == 0)
        undersampling_cell = [0,0,1]; 
        FOVShift_OffReson(:,2)=0.5;
        
    else    
        error('Unknown iPat and undersampling cell - check your data');
    end
        
    FOVShifts = cat(1, FOVShift_OnReson, FOVShift_OffReson);

end