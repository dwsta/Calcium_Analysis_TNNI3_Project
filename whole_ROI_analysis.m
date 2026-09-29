function whole_ROI_analysis(rootdir,alias,cfg_data,output_file_connection,IMAGES)

analysisdir = fullfile(rootdir,'output',alias,'whole-ROI_analysis');
mkdir(analysisdir)
fnameout = fullfile(analysisdir,[alias,'_raw.pdf']);
fnameout2 = fullfile(analysisdir,[alias,'_peaks.pdf']);

raw_trace = squeeze(mean(IMAGES,[1 2]))';
frames = 1:size(IMAGES,3);

tvec= (frames-min(frames)) / cfg_data.OtherParameters.FrameRate;

save_traces(raw_trace,[],tvec,fnameout,cfg_data)
[peakIDs,time_interp,signal_interp] = split_peaks(tvec,raw_trace);
save_traces(signal_interp,peakIDs,time_interp,fnameout2,cfg_data)

metrics = measure_peaks(peakIDs,time_interp,signal_interp);
t = struct2table(metrics);
means = varfun(@nanmean, t(:,2:end), 'InputVariables', @isnumeric);
sds = varfun(@nanstd, t(:,2:end), 'InputVariables', @isnumeric);

t.alias=repmat(alias,[height(t),1]);
t = [t(:,end) t(:,1:end-1)];
signal_str = ['{', sprintf('%f;',signal_interp) ,'}'];
time_str   = ['{', sprintf('%f;',time_interp)   ,'}'];
peakID_str = ['{', sprintf('%d;',peakIDs)   ,'}'];
peaksfilename = fullfile(analysisdir,[alias,'_peak_metrics.csv']);
writetable(t,peaksfilename)
means_str = arrayfun(@num2str,means{1,:},'UniformOutput',false);
sds_str  = arrayfun(@num2str,sds{1,:},'UniformOutput',false);
stringout = strjoin([alias , signal_str , time_str , peakID_str, means_str,sds_str],',');
fprintf(output_file_connection,'\n%s',stringout);
