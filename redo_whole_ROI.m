rootdir = 'D:\2022-11-10\kinetical_run_20221219_121054';
jobname = 'jobfile.csv';
cfg_data = loadJsonConfig(fullfile(rootdir,'config.json'));
% cfg_data.TFM.DoTFM = 0;
output_filename= fullfile(rootdir,'calcium_whole_roi.csv');
headers = {'alias','signal','time','peak_ID',...
    'mean_amplitude','mean_peak_duration', 'mean_rise_time', 'mean_fall_time', 'mean_pw90', 'mean_pw50', 'mean_pw30',...
    'mean_peak_value', 'mean_baseline', 'mean_valley',...
    'sd_amplitude','sd_peak_duration', 'sd_rise_time', 'sd_fall_time', 'sd_pw90', 'sd_pw50', 'sd_pw30', ...
    'sd_peak_value', 'sd_baseline', 'sd_valley'};
output_file_connection = fopen(output_filename,'w');
fprintf(output_file_connection,'%s',strjoin(headers,','));
t = readJobFile2(jobname, rootdir);
for iexp = 1:height(t)
    try
        iexp
    location = t(iexp,:).Location{1};
    alias = t(iexp,:).Alias{1};
    whole_ROI_analysis(rootdir,alias,cfg_data,output_file_connection);
    catch ME
        display('Skipping: ');
        t(iexp,:);
    end
end
fclose(output_file_connection)