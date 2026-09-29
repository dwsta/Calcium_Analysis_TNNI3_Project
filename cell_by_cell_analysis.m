function cell_by_cell_analysis(rootdir,alias,cfg_data,output_file_connection,IMAGES)

analysisdir = fullfile(rootdir,'output',alias,'cell-by-cell_analysis');
mkdir(analysisdir)

% Load cell segmentation
maskdir = fullfile(rootdir,'output',alias,'mask');
filmask= dir([maskdir,filesep,'*_cp_masks.png']);
mask = imread(fullfile(filmask.folder,filmask.name));
props = regionprops(mask,'Area','Centroid','Orientation','Circularity','MajoraxisLength','MinoraxisLength','Perimeter');
Tprops = struct2table(props);

% Compute traces cell-by-cell
Ncells = max(mask(:));
[NX,NY,NZ] = size(IMAGES);
raw_signal_r = reshape(IMAGES,[NX*NY],NZ);
for icell = 1:Ncells
    m = mask==icell;
    trace_matrix(icell,:) = squeeze(mean(raw_signal_r(m(:),:),1,'omitnan'));
end
frames = 1:NZ;

fnameout = fullfile(analysisdir,[alias,'_raw.pdf']);
fnameout2 = fullfile(analysisdir,[alias,'_peaks.pdf']);

tvec= (frames-min(frames)) / cfg_data.OtherParameters.FrameRate;
save_traces(trace_matrix,[],tvec,fnameout,cfg_data)
Ntraces = size(trace_matrix,1);

for itrace = 1 : Ntraces
[peakIDs,time,signal] = split_peaks(tvec,trace_matrix(itrace,:));
trace_matrix_interp(itrace,:) = signal;
peakIDs_matrix_interp(itrace,:) = peakIDs;
metrics = measure_peaks(peakIDs,time,signal);
t = struct2table(metrics);

means = varfun(@mean, t(:,2:end), 'InputVariables', @isnumeric);
sds = varfun(@std, t(:,2:end), 'InputVariables', @isnumeric);

t.alias = repmat(alias,[height(t),1]);
t.cellID = repmat(itrace,[height(t),1]);
t = [t(:,end-1:end) t(:,1:end-2)];
if itrace == 1 
    bigT = t;
else
    bigT = [bigT;t];
end
signal_str = ['{', sprintf('%f;',signal) ,'}'];
time_str   = ['{', sprintf('%f;',time)   ,'}'];
peakID_str = ['{', sprintf('%d;',peakIDs)   ,'}'];
props_str = arrayfun(@num2str,Tprops{itrace,:},'UniformOutput',false);
means_str = arrayfun(@num2str,means{1,:},'UniformOutput',false);
sds_str  = arrayfun(@num2str,sds{1,:},'UniformOutput',false);
stringout = strjoin([alias, num2str(itrace) , props_str ,signal_str , time_str , peakID_str, means_str,sds_str],',');
fprintf(output_file_connection,'\n%s',stringout);

end
save_traces(trace_matrix_interp,peakIDs_matrix_interp,time,fnameout2,cfg_data)

peaksfilename = fullfile(analysisdir,[alias,'_peak_metrics.csv']);
writetable(bigT,peaksfilename)
