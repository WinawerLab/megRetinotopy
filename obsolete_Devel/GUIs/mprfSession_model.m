function varargout = mprfSession_model(varargin)
% MPRFSESSION_MODEL MATLAB code for mprfSession_model.fig
%      MPRFSESSION_MODEL, by itself, creates a new MPRFSESSION_MODEL or raises the existing
%      singleton*.
%
%      H = MPRFSESSION_MODEL returns the handle to a new MPRFSESSION_MODEL or the handle to
%      the existing singleton*.
%
%      MPRFSESSION_MODEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MPRFSESSION_MODEL.M with the given input arguments.
%
%      MPRFSESSION_MODEL('Property','Value',...) creates a new MPRFSESSION_MODEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mprfSession_model_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mprfSession_model_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mprfSession_model

% Last Modified by GUIDE v2.5 24-May-2017 10:44:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mprfSession_model_OpeningFcn, ...
    'gui_OutputFcn',  @mprfSession_model_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before mprfSession_model is made visible.
function mprfSession_model_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mprfSession_model (see VARARGIN)

global mprfSESSION

do_update_rm = false;
do_update_meg = false;

if exist(fullfile(pwd,'mprfSESSION.mat'),'file')
    tmp = load('mprfSESSION.mat');
    
    mprfSESSION = tmp.mprfSESSION;
    handles.mprfSESSION = mprfSESSION;
    handles.main_dir = mprf__get_directory('main_dir');
else
    error('Could not find mprfSESSION file. Please run from session folder')
end

main_dir = handles.main_dir;

if handles.mprfSESSION.has.rm_stim_imported
    rm_stims = dir(fullfile(main_dir, mprf__get_directory('rm_stimulus'),'*.mat'));
    if ~isempty(rm_stims)
        set(handles.txt_rm_stim,'String',rm_stims(1).name)
        do_update_rm = true;
    else
        fprintf('Error, no valid RM stimulus found, please import one')
        
    end
else
    fprintf('Error, no valid RM stimulus found, please import one')
end


if handles.mprfSESSION.has.meg_stim_imported
    pred_stims = dir(fullfile(main_dir, mprf__get_directory('meg_imported_stim'),'*.mat'));
    if ~isempty(pred_stims)
        set(handles.txt_pred_stim,'String',pred_stims(1).name)
        do_update_meg = true;
    else
        fprintf('Error, no valid prediction stimulus found, please import one')
        
    end
else
    fprintf('Error, no valid prediction stimulus found, please import one')
end

handles.stimuli.show_n_rm_stim = 1;
handles.stimuli.show_n_meg_stim = 1;

handles.stimuli.stim_type = '';
handles.stimuli.cur_images = [];

axes(handles.axes1)
colormap('gray')

if do_update_meg && do_update_rm
    handles.stimuli.rm_files = rm_stims;
    handles.stimuli.meg_files = pred_stims;
    
end

% Choose default command line output for mprfSession_model
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if do_update_meg && do_update_rm
    pu_model_type_Callback(handles.pu_model_type, [], guidata(hObject));
    pb_display_pred_stim_Callback(handles.pb_display_pred_stim, eventdata, guidata(hObject));
    
end


% UIWAIT makes mprfSession_model wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mprfSession_model_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_select_stim.
function pb_select_stim_Callback(hObject, eventdata, handles, stim_type) %#ok<*DEFNU>
% hObject    handle to pb_select_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


[stim_path, stim_file, stim_ext] = mprf__select_model_stimulus(stim_type);

if isempty(stim_path) || isempty(stim_file)
    
else
    
    new_file = dir(fullfile(stim_path, [stim_file stim_ext]));
    
    if strcmpi(stim_type, 'meg_imported_stim')
        file_idx = find(~cellfun(@isempty, strfind({handles.stimuli.meg_files.name}, stim_file))); %#ok<*EFIND>
        
        if  ~isempty(file_idx)
            
        else
            handles.stimuli.meg_files = cat(1,handles.stimuli.meg_files, new_file);
            file_idx = length(handles.stimuli.meg_files);
            
        end
        handles.stimuli.show_n_meg_stim = file_idx;
        set(handles.txt_pred_stim,'String',handles.stimuli.meg_files(file_idx).name)
        
        guidata(hObject, handles);
        
        pb_display_pred_stim_Callback(hObject, [], handles);
    end
    
    if strcmpi(stim_type, 'rm_stimulus')
        file_idx = find(~cellfun(@isempty, strfind({handles.stimuli.rm_files.name}, stim_file)));
        
        if ~isempty(file_idx)
            
        else
            handles.stimuli.rm_files = cat(1,handles.stimuli.rm_files, new_file);
            file_idx = length(handles.stimuli.rm_files);
        end
        
        handles.stimuli.show_n_rm_stim = file_idx;
        set(handles.txt_rm_stim,'String',handles.stimuli.rm_files(file_idx).name)
        
        guidata(hObject, handles);
        
        pb_disp_rm_stim_Callback(hObject, [], handles);
    end
    
end

% --- Executes on button press in pb_select_stim.
function pb_pred_stim_Callback(hObject, eventdata, handles)
% hObject    handle to pb_select_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_disp_rm_stim.
function pb_disp_rm_stim_Callback(hObject, eventdata, handles)
% hObject    handle to pb_disp_rm_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles.stimuli,'rm_files')
    rm_file = fullfile(handles.main_dir, mprf__get_directory('rm_stimulus'),...
        handles.stimuli.rm_files(handles.stimuli.show_n_rm_stim).name);
    if exist(rm_file,'file')
        rm_stim = load(rm_file);
    else
        fprintf('Error, selected rm file does not exist')
        
    end
    
    
else
    fprintf('Error, no RM stimulus file selected')
end

fnames = fieldnames(rm_stim);
handles.stimuli.cur_stim = rm_stim.(fnames{1});
handles.stimuli.stim_type = 'rm';

guidata(hObject, handles);
update_stim_image(guidata(hObject));




% --- Executes on button press in pb_display_pred_stim.
function pb_display_pred_stim_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_pred_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles.stimuli,'meg_files')
    pred_file = fullfile(handles.main_dir, mprf__get_directory('meg_imported_stim'),...
        handles.stimuli.meg_files(handles.stimuli.show_n_meg_stim).name);
    if exist(pred_file,'file')
        pred_stim = load(pred_file);
    else
        fprintf('Error, selected prediction file does not exist')
        
    end
    
    
else
    fprintf('Error, no prediction stimulus file selected')
end

fnames = fieldnames(pred_stim);
handles.stimuli.cur_stim = pred_stim.(fnames{1});
handles.stimuli.stim_type = 'pred';

guidata(hObject, handles);

update_stim_image(guidata(hObject));


% --- Executes on slider movement.
function stim_disp_slider_Callback(hObject, eventdata, handles)
% hObject    handle to stim_disp_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
if isempty(handles.stimuli.cur_images)
    fprintf('Error, no image to display\n')
else
    cur_idx = round(get(handles.stim_disp_slider,'Value'));
    imagesc(handles.stimuli.cur_images(:,:,cur_idx), [0 1])
    set(handles.axes1,'YTick',[]);
    set(handles.axes1,'XTick',[]);
    set(handles.n_im_min,'String',num2str(get(handles.stim_disp_slider,'Min')))
    set(handles.n_im_max,'String',num2str(get(handles.stim_disp_slider,'Max')))
    set(handles.cur_im,'String',num2str(cur_idx));
    
    
end


% --- Executes during object creation, after setting all properties.
function stim_disp_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_disp_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes during object creation, after setting all properties.
function txt_rm_stim_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to txt_rm_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function update_stim_image(handles)

if strcmpi(handles.stimuli.stim_type,'rm')
    handles.stimuli.cur_images = double(handles.stimuli.cur_stim.full_im);
    
elseif strcmpi(handles.stimuli.stim_type,'pred')
    handles.stimuli.cur_images = double(handles.stimuli.cur_stim.full_im);
    handles.stimuli.cur_images = handles.stimuli.cur_images ./ max(handles.stimuli.cur_images(:));
    
end


cur_range = [1 size(handles.stimuli.cur_images,3)];

set(handles.stim_disp_slider,...
    'Min',cur_range(1),'Max',cur_range(2),...
    'SliderStep', [(1/(cur_range(2) - cur_range(1))) (10/(cur_range(2) - cur_range(1)))] ,...
    'Value',cur_range(1))

set(handles.n_im_min,'String',num2str(get(handles.stim_disp_slider,'Min')))
set(handles.n_im_max,'String',num2str(get(handles.stim_disp_slider,'Max')))
set(handles.cur_im ,'String',num2str(round(get(handles.stim_disp_slider,'Value'))))

handles.stimuli.cur_stim.radius = (max(handles.stimuli.cur_stim.full_x(:)) - ...
    min(handles.stimuli.cur_stim.full_x(:))) ./ 2 .* ...
    max(max([squeeze(mean(handles.stimuli.cur_images,1)) ...
    squeeze(mean(handles.stimuli.cur_images,2))]));

set(handles.txt_stim_rad,'String',num2str(handles.stimuli.cur_stim.radius))

pp_row = max(squeeze(mean(handles.stimuli.cur_images)));
pp_col = max(squeeze(mean(handles.stimuli.cur_images,2)));

un_row = unique(pp_row(pp_row~=0));
un_col = unique(pp_col(pp_col~=0));

sum_row = nan(length(un_row));
sum_col = nan(length(un_col));

for n = 1:max(length(un_row), length(un_col))
    
    if n <= length(un_row)
        sum_row(n) = sum(pp_row == un_row(n));
        
    end
    
    
    if n <= length(un_col)
        sum_col(n) = sum(pp_col == un_col(n));
        
    end
    
    
end

[~, rmi] = max(sum_row);
[~, cmi] = max(sum_col);

r_width = un_row(rmi).* handles.stimuli.cur_stim.radius .*2;
c_width = un_col(cmi).* handles.stimuli.cur_stim.radius .*2;
handles.stimuli.cur_stim.bar_width = mean([r_width c_width]);

set(handles.txt_bar_width,'String',num2str(handles.stimuli.cur_stim.bar_width))


guidata(handles.figure1, handles);
stim_disp_slider_Callback(handles.figure1, [], handles);



function cur_im_Callback(hObject, eventdata, handles)
% hObject    handle to cur_im (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cur_val = round(str2double(get(handles.cur_im,'String')));
if cur_val > get(handles.stim_disp_slider,'Max')
    cur_val = get(handles.stim_disp_slider,'Max');
    set(handles.cur_im,'String',num2str(cur_val));
    
elseif cur_val < get(handles.stim_disp_slider,'Min')
    
    
    cur_val = get(handles.stim_disp_slider,'Min');
    set(handles.cur_im,'String',num2str(cur_val));
    
end

set(handles.stim_disp_slider,'Value',cur_val);
stim_disp_slider_Callback(handles.figure1,[],handles);

% Hints: get(hObject,'String') returns contents of cur_im as text
%        str2double(get(hObject,'String')) returns contents of cur_im as a double


% --- Executes during object creation, after setting all properties.
function cur_im_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cur_im (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function axes1_CreateFcn(hObject, eventdata, handles)


% --- Executes on selection change in pu_model_type.
function pu_model_type_Callback(hObject, eventdata, handles)
% hObject    handle to pu_model_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};

handles.model.type = selected;
handles.model.cur_comment = mprf__get_modeling_comments(selected);
set(handles.model_comment,'String',handles.model.cur_comment);

guidata(hObject, handles)




% --- Executes during object creation, after setting all properties.
function pu_model_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pu_model_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_run.
function pb_run_Callback(hObject, eventdata, handles)
% hObject    handle to pb_run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb_set_parameters.
function pb_set_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to pb_set_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
argout = set_parameters_gui({handles.model.type});
fprintf('On line 459: %s\n', argout);

% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cb_syn_ds.
function cb_syn_ds_Callback(hObject, eventdata, handles)
% hObject    handle to cb_syn_ds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_syn_ds