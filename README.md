# README for MEG Retinotopy code

(Last update by EK: Sep 20, 2018)

This repository is an archived version of the MEG Retinotopy code, how Barrie Klein left it. Before Eline Kupers and Akhil Edadan added significant changes.

## DESCRIPTION
This project is an MEG retinotopy project, as a collaboration between 
NYU (Noah Benson, Eline Kupers and Jon Winawer) and the Amsterdam Spinoza Center 
(Akhil Edadan, Wietske Zuiderbaan, Serge Dumoulin).

(Historically, this project was initiated by Barrie Klein, Serge Dumoulin, and Jon Winawer).

## GOAL
The aim of this project is to see if we can fit a population receptive field (pRF) 
template of the visual cortex to MEG data. In order to achieve this we derive predicted 
MEG time course by multiplying a pRF model template with a stimulus sequence and computing 
the expected MEG response by multiplying it with a forward/head model computed by 
Brainstorm. In order to do this we have to export the pRF model from mrVista and import 
it into the Brainstorm surface space. As Brainstorm works with Freesurfer surfaces, we 
export the data first to the Freesurfer surface space and then to the Brainstorm surface 
space. We can do the same transformation for ROIs defined either using mrVista 
(i.e. drawn on a mesh) or using Noah Benson’s cortical templates.

## FOLDER STRUCTURE
This code repository contains 5 subfolders specific for this project:
	1. Devel 		(old versions of Barrie's code, should not be used)
	2. MEG_analysis		(preprocessing scripts for MEG data)
	3. mprfSession		(scripts to compare preprocessed MEG and MRI data)
	4. MRI_analysis		(preprocessing scripts for MRI data)
	5. Stimuli 		(used stimulus files for fMRI and MEG sessions)

## DATA 
Raw and derivatives of MRI and MEG data are on the Winawerlab server Acadia 
server > Projects > MEG > Retinotopy.

## PIPELINE
This code is Matlab based, and has the following depencies:
- FreeSurfer (v??)
- Vistasoft (v??)
- ToolboxToolbox (v??)
- Fieldtrip (v??)
- Brainstorm (v??)
- meg_utils (v??)

Get started:
1. Pull code directory from GitHub with the ToolboxToolbox and add to paths
`tbUse('regMeg')`


**[ EVERYTHING FROM HERE NEEDS TO BE CHECKED AND/OR UPDATED ]**


2. To start a new session type ‘mprfSessionInit(true)’ in your Matlab command window
	The input argument “true” tells mprfSessionInit that you want to use Ernie’s example 
	data. In that case, it will attempt to download Ernie’s example data fMRI and 
	anatomical data using mrtInstallSampleData. In order to run, this needs the Remote 
	Data Toolbox (RDT) as well. If you already have Ernie’s example data in the expected 
	directories it will not download them. 

	Eventually, this function will open a GUI that asks you for the location of several 
	files and folders:
	a. The mrVista folder of the subject whose MEG data you want to analyze.
		If you have requested to use Ernie’s example data, this field will display the 
		path to Ernie’s directory
	b. The mrVista anatomy of the same subject
	c. The mrVista classification file of the same subject
	d. The retinotopic model of this subject you want to export
	e. The brainstorm anatomy directory of the subject. 
		When importing an MRI anatomy into Brainstorm, brainstorm creates an anatomy 
		directory for this subject. Importantly, this directory should be related to the 
		MEG data you want to fit. Brainstorm adjusts the position and orientation of the 
		anatomical MRI according to the position of the subject’s head in the MEG dewar. 
		This information is stored together with the anatomical MRI imported by Brainstorm.
		This directory is located in Brainstorm’s data base (i.e. when installing 
		brainstorm, you were asked to select a directory that would serve as a database). 
	f. Brain storm head model file
		This is the file created by Brainstorm when you have generated a head model for 
		the subject via Brainstorm’s GUI. This file is also located in Brainstorm’s 
		data base (see e.)
	g. Freesurfer directory
		The subject’s free surfer directory. If you have asked for Ernie’s example data, 
		this field wil display the path to Ernie’s freesurfer directory.

Possibly more fields will be added coming weeks as we like to know where the MEG data 
that we want to fit is located.


Once this is done, press 'Done'.
mprfSession will now try to import all the data into the current session directory. This 
will create a new folder, called 'source', together with several subdirectories.

PRF PARAMETERS:

Once this is completed, the next step is to export the pRF parameters from the selected 
retinotopic model. In order to do this run 'mprfSessionSmoothExportPRFParams' from the 
session directory. This function takes no inputs. 

This function will smooth the pRF data and export both the smoothed and unsmoothed pRF 
parameters in two different ways:
1. As nifti files
2. As a .mat file called 'exported_prf_params.mat'

This process may take a while. Once done, it adds the 'pRF_data' folder to your session
directory. At this stage, this folder contains two subfolders: 'nifit' with all the prf
niftis and 'data_dir' with the 'exported_prf_params.mat'. 
Note that in order for this function to run, it needs to navigate to the mrVista subject 
directory (it needs the gray graph in order to smooth the parameters and uses several
functions that require a volume view).

The nifti files are really just for visual inspection of the pRF parameters. Although the 
code checks for a correct alignment of the parameter nifti with the subject's T1, it may 
prove useful to check the parameters visually as well.

Once this is done, the next step is to transform the pRF parameters to the Freesurfer 
surface space. Run the function 'mprfSessionExportPRFDataToFreeSurferSurface' from the 
subject directory to start this. It is important to note that this function only considers
Freesurfer's lh.white and rh.white surfaces and mrVista's first layer of gray nodes. 
This function creates a new subdirectory in the pRF data folder: 'surface/freesurfer'.
This subdirectory contains the surface data for all pRF parameters.

Once this is done, you can visualize the pRF parameters on a mesh using 
'mprfSessionRenderDataOnFreesurferSurface'. This will open up a gui, asking for the surface
to render. This can be both the white and pial surface. Note, that as both freesurfer 
surfaces have the same amount of vertices the surface data files created in the step above
will work on both surfaces. Next, it will ask you for the data to display (can be both 
pRF data or ROIs) and the colormap you want to use.


ROIs
You can export ROIs from either mrVista or from the Wang atlas created by Noah Benson's 
docker. To export ROIs from mrVista run 'mprfSessionExportVistaROIToFreesurferSurface'. 
This opens up a GUI that asks you for the ROIs you want to export. As Freesurfer produces
surfaces for the left and right hemispheres separately, this function needs the ROIs to be
defined for the left and right hemisphere separately. 
To export ROIs from the Wang atlas, simply run 'mprfSessionImportWangAtlas', navigate to
the folder where the atlas files are located (by default the surface directory in the 
subject's freesurfer directory) and select all the files you want to export.


Finally, you can transform the freesurfer surface data into the Brainstorm surface space.
Use 'mprfSessionFreesurferSurfaceToBrainstorm' to do this. This function has input argument
that tells it if you want to transform pRF parameters ('prf') or ROIs ('rois') to the Brainstorm
surface space. This will create a new subdirectory: 'surface/brainstorm' in either the 
'pRF_data' or 'roi' directory that has all the surface data for the Brainstorm surfaces. 
At this point, only the pial surface is used, as Brainstorm's head model uses this surface
by default. In order for this function to run, you need to export the data first to the
freesurfer surface space.

Again, the data can be visualised on a mesh. To do this, type 
'mprfSessionRenderDataOnBrainstormSurface' in Matlab's command window from the session 
directory. Select the data you want to display (either pRF data or ROIs). 

Also, the predicted pRF responses to a certain stimulus can be visualized for every bar 
position using a GUI. In order to do this, run mprfSessionRenderpRFActivityOnBrainstormSurface.
This script will ask you which stimulus to use. If none is present in the Subject's directory
(prediction/stimulus folder), the script will ask you if you want to use the fMRI retinotopic stimulus
or another stimulus. Preferably this is the MEG stimulus used to collect the MEG data. In the
latter case, you will be asked to select the stimulus file and a Grid file and the stimulus
will be prepared and stored under prediction/stimulus and is accessible later. Ones the predictions
have been made, you can view them on the brainstorm pial surface via a GUI


To make stimuli:
- mprfCreate.. … … 


