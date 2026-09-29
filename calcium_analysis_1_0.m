% Copyright (c) 2022, Ricardo Serrano
% All rights reserved.

function calcium_analysis_1_0(app)

rootdir = app.OutputDirectoryEditField.Value;
app.UITableStatus.Data.Status(:) = {'Queued'};
drawnow;
figure(app.UIFigure);
cfg_data = app.Config;

% Make results csv
output_file_connections = create_csv(cfg_data,rootdir);
csv_whole_ROI = output_file_connections(1);
if cfg_data.SingleCell.UseCellpose
    csv_CBC = output_file_connections(2);
end

%
%
%                         Main Loop
%
%
for iexp = 1:height( app.UITableStatus.Data)
    try
        close all
        % Define some variables for shorthand
        alias =  app.UITableStatus.Data.Alias{iexp};
        imgpath =  app.UITableStatus.Data.Location{iexp};
        ext = 'tif'; % For now we only work with .tif files

        % Make Output Folder for each Well
        aliasdir = fullfile(rootdir,'output',alias);
        if ~exist(aliasdir,'dir'); mkdir(aliasdir); end

        %
        %   Load images
        %
        updateStatus(app,iexp,{'Loading Images'});
        writeToLog(app.Logfile,[alias,' Loading Images']);
        [IMAGES, IMAGE_NAMES] = imageLoader(imgpath,ext);
        IMAGES = double(IMAGES);
        if app.QuitSignal
            break
        end

        
        %
        %   Data output (whole ROI)
        %
        whole_ROI_analysis(rootdir,alias,cfg_data,csv_whole_ROI,IMAGES)

        %
        %   Cell segmentation with Cellpose
        %
        if cfg_data.SingleCell.UseCellpose
            updateStatus(app,iexp,{'Segmenting Cells'})
            writeToLog(app.Logfile,[alias,' Cell Segmentation']);
            % Move the image to a new folder called 'mask'. Each alias has its own
            imdir = fullfile(rootdir,'output',alias,'mask');
            mkdir(imdir);
            CP_imnames = dir(fullfile(imgpath,cfg_data.SingleCell.Directory,'*.tif'));
            src = fullfile(CP_imnames(1).folder,CP_imnames(1).name);
            dst = fullfile(imdir,['cp_input_',CP_imnames(1).name]);
            copyfile(src,dst);
            % Main function of the segmentation
            singleCellSegmentation(imdir,cfg_data)
            %
            %   Data output (cell by cell)
            %
            cell_by_cell_analysis(rootdir,alias,cfg_data,csv_CBC,IMAGES)
        end

        if app.QuitSignal
            break
        end

        
        %
        %   Finished analysis of this video
        %
        updateStatus(app,iexp,{sprintf('COMPLETED %s',datestr(now))});
        writeToLog(app.Logfile,[alias,' COMPLETED']);

    catch ME
        updateStatus(app,iexp, {sprintf('ERROR %s',datestr(now))});
        writeToLog(app.Logfile,[alias,' ERROR']);

        fid = fopen(fullfile(rootdir,'crashes.log'),'a');
        fprintf(fid,'%s %s \n',alias,datestr(now));

        msgText = getReport(ME,'extended','hyperlinks','off');

        fprintf(fid,'%s',msgText);

        fprintf(fid,'\n\n\n\n');

        fclose(fid);
        close all
    end
end
if app.QuitSignal
    app.UITableStatus.Data.Status(strcmp(app.UITableStatus.Data.Status,{'Queued'})) = {'Stopped'};
    fclose all;
    return;
end
fclose all;
end
function output_file_connections = create_csv(cfg_data,rootdir)
% Helper function to create the csv output files and remove clutter from the main loop
% For whole ROI
outcsv = fullfile(rootdir,'calcium_whole_roi.csv');
output_file_connections(1) = fopen(outcsv,'w');
headers = {'alias','signal','time','peak_ID',...
    'mean_amplitude','mean_peak_duration', 'mean_rise_time', 'mean_fall_time', 'mean_pw90', 'mean_pw50', 'mean_pw30',...
    'mean_peak_value', 'mean_baseline', 'mean_valley',...
    'sd_amplitude','sd_peak_duration', 'sd_rise_time', 'sd_fall_time', 'sd_pw90', 'sd_pw50', 'sd_pw30', ...
    'sd_peak_value', 'sd_baseline', 'sd_valley'};
fprintf(output_file_connections(1),'%s',strjoin(headers,','));
% For cell by cell
if cfg_data.SingleCell.UseCellpose

    outcsv2 = fullfile(rootdir,'calcium_cell-by-cell.csv');
    headers = {'alias','cellID','area','centroid_x','centroid_y',
    'majoraxisLength','minoraxisLength','orientation','circularity','perimeter',...
        'signal','time','peak_ID','mean_amplitude','mean_peak_duration', 'mean_rise_time', 'mean_fall_time',... 
        'mean_pw90', 'mean_pw50', 'mean_pw30', 'mean_peak_value', 'mean_baseline', 'mean_valley',...
        'sd_amplitude','sd_peak_duration', 'sd_rise_time', 'sd_fall_time',...
        'sd_pw90', 'sd_pw50', 'sd_pw30', 'sd_peak_value', 'sd_baseline', 'sd_valley'};
    output_file_connections(2) = fopen(outcsv2,'w');
    fprintf(output_file_connections(2),'%s',strjoin(headers,','));
end
end
