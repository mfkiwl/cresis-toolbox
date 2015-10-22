function fn = ct_filename_ct_tmp(param,fn,type,filename)
% fn = ct_filename_ct_tmp(param,fn,type,filename)
%
% Returns a standardized filename for temporary files.
% 1. Handles absolute and relative path conversions, default paths, and
%    file separator differences (e.g. windows uses '\' and unix uses '/')
% 2. There are three modes of operation:
%  - base_fn is an absolute path: the param.ct_tmp_path and standardized
%    path are not used (base_fn replaces both)
%  - base_fn is a relative path: the param.ct_tmp_path is used, but the
%    standardized path/directory structure is not used (base_fn is used)
%  - base_fn is empty: the param.ct_tmp_path and standardized path are used
%
% param = control structure to data processor
%  .radar_name (e.g. snow)
%  .season_name (e.g. 2014_Alaska_TOnrl)
%  .day_seg (e.g. 20140315)
% fn = parameter filename provided
% type = type of data (e.g. records, picker)
%
% Examples:
%  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers',[fn_name '.mat']);
%
% Author: John Paden
%
% See also: ct_filename_data, ct_filename_out, ct_filename_support,
%  ct_filename_ct_tmp, ct_filename_gis

global gRadar;
param = merge_structs(gRadar,param);
if ~isfield(param,'ct_tmp_path')
  param.ct_tmp_path = '';
end

if ~isfield(param,'radar_name')
  output_dir = '';
else
  [output_dir,radar_type] = ct_output_dir(param.radar_name);
end

if isempty(fn)
  if ~isfield(param,'day_seg') || isempty(param.day_seg)
    fn = fullfile(param.ct_tmp_path, type, output_dir, ...
      param.season_name, filename);
  else
    % Generate the default filename
    [tmp name ext] = fileparts(filename);
    fn = fullfile(param.ct_tmp_path, type, output_dir, ...
      param.season_name, sprintf('%s_%s%s', name, param.day_seg, ext));
  end
elseif fn(1) == filesep || (ispc && (~isempty(strfind(fn,':\')) || ~isempty(strfind(fn,':/'))))
  % This is already an absolute path
  return
else
  % Append the current path to the support path
  fn = fullfile(param.ct_tmp_path, fn);
end

fn(fn == '/' | fn == '\') = filesep;

return;
