%% read MAPVBVD demmo
% load dat data
disp('Load .DAT raw data')
[f_name, f_path]=uigetfile('*.dat','select .dat data');
f_raw=strcat(f_path,f_name);
datastruct = mapVBVD(f_raw,'removeOS');  %     'removeOS'
data=datastruct{2}; %
raw = data.image();