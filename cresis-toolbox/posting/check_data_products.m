% script check_data_products
%
% Script for checking non-RDS data products (needs to be modified to fully
% support RDS data products).  Lists missing and extra files.
%
% Author: John Paden, Logan Smith

%% User Settings
clear; clc
global gRadar
params = read_param_xls(ct_filename_param('kuband_param_2015_Greenland_LC130.xls'),[],'post');

source_dir = '/scratch/';
backup_dirs = {};
dirs_list = [source_dir backup_dirs];
support_dir = gRadar.support_path;
support_backup_dirs = {'',''};
support_dirs_list = [support_dir support_backup_dirs];

if any(strcmp(params(1).radar_name,{'mcrds','mcords','mcords2','mcords3','mcords4','mcords5'}))
  supports = {'gps','vectors','frames','records'};
  outputs = {'CSARP_qlook','CSARP_standard','CSARP_mvdr','CSARP_layerData','CSARP_out'};
%   outputs = {'CSARP_qlook','CSARP_csarp-combined'};
  outputs_post_dir = '';
  images = {'maps','echo'};
  pdf_en = 1;
  csv_outputs = {'csv','csv_good','kml','kml_good'};
  csv_en = 1;
elseif strcmp(params(1).radar_name,'accum2')
  supports = {'gps', 'vectors','frames','records'};
  outputs = {'CSARP_qlook','CSARP_layerData'};
  outputs_post_dir = 'CSARP_post';
  images = {'maps','echo'};
  pdf_en = 1;
  csv_outputs = {'csv','csv_good','kml','kml_good'};
  csv_en = 0;
elseif any(strcmp(params(1).radar_name,{'kaband3','kuband3','snow3','kuband2','snow2','kuband','snow'}))
  supports = {'gps', 'vectors','frames','records'};
  outputs = {'CSARP_qlook'};
  outputs_post_dir = 'CSARP_post';
  images = {'maps','echo'};
  pdf_en = 0;
  csv_en = 0;
end
% gps_sources = {'ATM-final_20120701'}; % Leave empty/undefined to not check gps_sources
% processing_date_check = datenum(2012,09,01); % Leave empty/undefined to not check porcessing date
gps_sources = {}; % Leave empty/undefined to not check gps_sources
processing_date_check = []; % Leave empty/undefined to not check porcessing date

%% Automated Section

%% Check that only good files are present in each directory

% Get list of all files in vectors directory
for file_type = {'vectors','records','frames'}
  
  vector_fns = get_filenames([ct_filename_support(rmfield(params(1),'day_seg'),'',file_type{1}), filesep],file_type{1},'','.mat');
  vector_fns_mask = zeros(size(vector_fns));
  for param_idx = 1:length(params)
    param = params(param_idx);
    vector_fn = ct_filename_support(param,'',file_type{1});
    match_idx = strmatch(vector_fn,vector_fns);
    if ~isempty(match_idx)
      vector_fns_mask(match_idx) = 1;
    end
  end
  for bad_idx = find(~vector_fns_mask)
    if ~isempty(bad_idx)
      fprintf('BAD FILE !!!!!!!! %s\n', vector_fns{bad_idx});
    end
  end
  
end

%% Check that all outputs are there
for param_idx = 1:length(params)
  if ~isnumeric(params(param_idx).cmd.generic) && ~isnumeric(params(param_idx).cmd.generic)
    continue;
  end
  if params(param_idx).cmd.generic
    for dir_idx = 1:length(dirs_list)
      if ~isempty(dirs_list{dir_idx})
        fprintf('\nChecking %s\n', params(param_idx).day_seg);
        param = params(param_idx);
        if ~isempty(regexpi(param.cmd.notes,'do not process'))
          fprintf('  DO NOT PROCESS !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
        param.out_path = dirs_list{dir_idx};
        param.support_path = support_dirs_list{dir_idx};
        
        % Check for existance of gps file
        if strmatch('gps',supports)
          gps_fn = ct_filename_support(param,param.vectors.gps.fn,'gps',true);
          fprintf('  GPS %s\n', gps_fn);
          if exist(gps_fn,'file')
            try
              gps = load(gps_fn);
              fprintf('    Exists: %s\n', gps.gps_source);
            catch ME
              fprintf('    Error:\n');
              keyboard
            end
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        % Check for existance of vectors file
        clear vectors;
        if length(outputs) >= 1 || length(images) >=1 || strmatch('vectors',supports)
          vectors_fn = ct_filename_support(param,'','vectors');
          fprintf('  Vectors %s\n', vectors_fn);
          if exist(vectors_fn,'file')
            fprintf('    Exists\n');
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        % Check for existance of records file
        if strmatch('records',supports)
          records_fn = ct_filename_support(param,'','records');
          fprintf('  Records %s\n', records_fn);
          if exist(records_fn,'file')
            try
              records = load(records_fn);
              if isfield(records,'records')
                fprintf('    Exists: %s\n', records.records.gps_source);
              else
                fprintf('    Exists: %s\n', records.gps_source);
              end
            catch ME
              fprintf('    Error:\n');
              keyboard
            end
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        % Check for existance of frames file
        if strmatch('frames',supports)
          frames_fn = ct_filename_support(param,'','frames');
          fprintf('  Frames %s\n', frames_fn);
          if exist(frames_fn,'file')
            try
              load(frames_fn);
              fprintf('    Exists\n');
            catch ME
              fprintf('    Error:\n');
              keyboard
            end
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        for output_idx = 1:length(outputs)
          out_dir = fullfile(ct_filename_out(param,'','',1),outputs_post_dir, ...
            outputs{output_idx},param.day_seg);
          fprintf('  Output %s\n', out_dir);
          frms = 1:length(frames.frame_idxs);
          if length(unique(frms)) ~= length(frms)
            fprintf('    VECTORS CONTAINS NONUNIQUE FRAMES !!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
          found_mask = zeros(1,length(frms));
          if exist(out_dir,'dir')
            if strcmp(outputs{output_idx},'CSARP_out')
              fn_param.type = 'd';
              fns = get_filenames(out_dir,'fk_data','','',fn_param);
            else
              fns = get_filenames(out_dir,'Data_','','.mat');
            end
            for fn_idx = 1:length(fns)
              fn = fns{fn_idx};
              [fn_dir fn_name] = fileparts(fn);
              if strcmp(outputs{output_idx},'CSARP_out')
                day_seg = fn_dir(end-10:end);
                frm = str2double(fn_name(end-8:end-6));
              else
                % Determine 3 or 4 number frame number
                if fn_name(end-3) == '_'
                  day_seg = fn_name(end-14:end-4);
                  frm = str2double(fn_name(end-2:end));
                else
                  day_seg = fn_name(end-15:end-5);
                  frm = str2double(fn_name(end-3:end));
                end
              end
              if ~strcmp(day_seg,param.day_seg)
                fprintf('    day_seg mismatch %s\n', fn);
              end
              frm_idx = find(frm==frms);
              if isempty(frm_idx)
                fprintf('    FILE SHOULD NOT BE HERE !!!!!!!!!!!!!!!!!!!!!!!!!\n');
                fprintf('      %s\n', fn);
              else
                if exist('gps_sources','var') && ~isempty(gps_sources) && ~strcmp(outputs{output_idx},'CSARP_layerData')
                  if strcmp(outputs{output_idx},'CSARP_out')
                    fns2 = get_filenames(fn,'','','');
                    fn = fns2{1};
                  end
                  load(fn,'param_records');
                  if isempty(strmatch(param_records.gps_source,gps_sources))
                    fprintf('    %s BAD GPS SOURCE %s\n', fn, param_records.gps_source);
                    no_bad_gps_so_far_flag = false;
                  end
                end
                if exist('processing_date_check','var') && ~isempty(processing_date_check) && ~strcmp(outputs{output_idx},'CSARP_layerData')
                  if strcmp(outputs{output_idx},'CSARP_out')
                    fns2 = get_filenames(fn,'','','');
                    fn = fns2{1};
                  end
                  if strcmp(outputs{output_idx},'CSARP_qlook')
                    load(fn,'param_get_heights');
                    if datenum(param_get_heights.get_heights.sw_version.cur_date_time) < processing_date_check
                      fprintf('    %s IS OLD %s\n', fn, param_get_heights.get_heights.sw_version.cur_date_time);
                    end
                  else
                    load(fn,'param_csarp');
                    if datenum(param_csarp.csarp.sw_version.cur_date_time) < processing_date_check
                      fprintf('    %s IS OLD %s\n', fn, param_csarp.csarp.sw_version.cur_date_time);
                    end
                  end
                end
                found_mask(frm_idx) = 1;
              end
            end
            if any(~found_mask)
              fprintf('    MISSING FRAMES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!:\n');
              fprintf('      %d\n', frms(~found_mask));
            else
              fprintf('    All frames found\n');
            end
            
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        % Check for expected image files
        for image_idx = 1:length(images)
          image_dir = fullfile(ct_filename_out(param, ...
            param.post.out_path, 'CSARP_post', true),'images',param.day_seg);
          fprintf('  Images %s in %s\n', images{image_idx}, image_dir);
          frms = 1:length(frames.frame_idxs);
          if length(unique(frms)) ~= length(frms)
            fprintf('    VECTORS CONTAINS NONUNIQUE FRAMES !!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
          frms = unique(frms); % sorts the frms list too which we need!
          found_mask = zeros(1,length(frms));
          start_frms = frms;
          stop_frms = frms;
          if exist(image_dir,'dir')
            if strmatch(images{image_idx},'maps')
              fns = get_filenames(image_dir,'','0maps','');
            elseif strmatch(images{image_idx},'echo')
              fns = get_filenames(image_dir,'','1echo','');
            end
            for fn_idx = 1:length(fns)
              fn = fns{fn_idx};
              [fn_dir fn_name] = fileparts(fn);
              % Assume YYYYMMDD_SS_FFF filename format and pull FFF frame
              % number
              day_seg = fn_name(1:11);
              start_frm = str2double(fn_name(13:15));
              if fn_name(20) == '_'
                stop_frm = str2double(fn_name(17:19));
              elseif fn_name(21) == '_'
                stop_frm = str2double(fn_name(17:20));
              else
                stop_frm = start_frm;
              end
              if ~strcmp(day_seg,param.day_seg)
                fprintf('    day_seg mismatch %s\n', fn);
              end
              img_frms = start_frm:stop_frm;
              start_frm_idx = find(start_frm==start_frms);
              stop_frm_idx = find(stop_frm==stop_frms);
              if ~isempty(start_frm_idx) && ~isempty(stop_frm_idx) && start_frm_idx == stop_frm_idx
                for img_frm = img_frms
                  found_mask(frms == img_frm) = 1;
                end
              else
                fprintf('    FILE SHOULD NOT BE HERE !!!!!!!!!!!!!!!!!!!!!!!!!\n');
                fprintf('      %s\n', fn);
              end
            end
            if any(~found_mask)
              fprintf('    MISSING FRAMES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!:\n');
              fprintf('      %d\n', frms(~found_mask));
            else
              fprintf('    All frames found\n');
            end
            
          else
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          end
        end
        
        % Check for expected pdf files
        if pdf_en
          pdf_dir = fullfile(ct_filename_out(param, ...
            '', 'CSARP_post', true),'pdf');
          fprintf('  PDF in %s\n', pdf_dir);
          pdf_fn = get_filenames(pdf_dir,'',params(param_idx).day_seg,'.pdf');
          if isempty(pdf_fn)
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          else
            fprintf('    PDF found\n');
          end
        end
        
        % Check for expected csv, csv_good, kml, kml_good files
        if csv_en
          for csv_out_idx = 1:length(csv_outputs)
            csv_dir = fullfile(ct_filename_out(param, ...
              '', 'CSARP_post', true),csv_outputs{csv_out_idx});
            fprintf('  %s in %s\n', csv_outputs{csv_out_idx}, csv_dir);
            if ~isempty(strfind(upper(csv_outputs{csv_out_idx}),'CSV'))
              csv_fn = fullfile(csv_dir,sprintf('Data_%s.csv',params(param_idx).day_seg));
            elseif ~isempty(strfind(upper(csv_outputs{csv_out_idx}),'KML'))
              csv_fn = fullfile(csv_dir,sprintf('Browse_Data_%s.kml',params(param_idx).day_seg));
            else
              error('CSV file type %s not supported',csv_outputs{csv_out_idx});
            end
            if ~exist(csv_fn,'file')
              fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            else
              fprintf('    %s found\n', csv_outputs{csv_out_idx});
            end
          end
        end
      end
    end
  end
end

