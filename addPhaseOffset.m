function kspace = addPhaseOffset(kspace, phase)

    re = abs(kspace) .* cos(angle(kspace) + phase*pi);
    im = abs(kspace) .* sin(angle(kspace) + phase*pi);
    kspace = complex(re,im);

end