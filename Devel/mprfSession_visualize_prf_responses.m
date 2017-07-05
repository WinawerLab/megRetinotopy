


global mprfSESSION
if isempty(mprfSESSION)
    load('mprfSESSION.mat')
end


main_dir = mprf__get_directory('main_dir');
anat_dir = mprf__get_directory('bs_anat');

pred = mprf__load_model_predictions;
[~,tmp] = fileparts(pred.bs.model_file);

surf_file = [tmp(strfind(tmp,'tess'):end) '.mat'];
surf_path = fullfile(main_dir, anat_dir, surf_file);


bs_msh = mprfMeshFromBrainstorm(surf_path);
bs_msh = meshVisualize(bs_msh);




















