function automatedInverseModel(description, varargin)
    % A function to calculate the APO motor torques which best achieve a
    % supplied desired human torque contribution, given input of experimentally
    % obtained kinematic and kinetic data. 
    %
    %   description = A description of the current experiment being run. This
    %                 is for naming the directories produced by this function.
    %   overwrite* = True or false depending on whether you want to overwrite a
    %                run with the same description, if it exists. 
    %   grfData* = A string giving the path of the data file to be used for the
    %              ground reaction forces. This should be in the form of the grf
    %              files used by OpenSim. If no path is given this variable
    %              defaults to 'grf.mot' in the current directory. 
    %   kinematicData* = Same as above but for the kinematic data. Default is
    %                    'ik.mot'.
    %   
    %   * denotes that a variable should be given as a name-value pair. 
    %
    % Author: Daniel Gordon
    
    % EVENTUALLY I SHOULD HAVE AN INSTALL PROCEDURE WHICH SETS UP THE FILE 
    % STRUCTURE IN AN APPROPRIATE WAY. THIS IS WHY I'M ADDING IN THE
    % RESULTS PATH COMMAND LINE ARGUMENT TO GETJOINTSPACEFORCES!!!!!
    
    % GUI vs text-based interface for selecting files, both? 

    %% Input parsing.
    % Parse the input parameters provided to the function, assigning defaults
    % if necessary. 

    p = inputParser;
    addRequired(p, 'description', @ischar);
    addParameter(p, 'overwrite', 0, @(x) x == 1 || x == 0);
    addParameter(p, 'grfData', 'grf.mot' ,@ischar);
    addParameter(p, 'kinematicData', 'ik.mot', @ischar);

    parse(p,description,varargin{:});

    %% Some setup.
    % Could depend on inputs maybe i.e. only need to load OpenSim API if
    % we're actually going to be doing OpenSim stuff. 
    
    import org.opensim.modeling.*
    
    %% File management. 
    % Creates the directories required by the inverse model, copying required
    % files from a designated (currently hard-coded) directory. Logic to handle
    % whether or not user wants to overwrite existing data. 

    CURRENT_DIRECTORY = pwd;
    REQUIRED_FILES_DIRECTORY = ['C:/Users/Daniel/Desktop/'...
                                'Automating Inverse Model/Required files'];
    DEFAULT_MAIN_DIRECTORY = ['C:/Users/Daniel/Desktop/'...
                              'Automating Inverse Model/Results/'];
    TARGET_DIRECTORY = [DEFAULT_MAIN_DIRECTORY, description];
    BUILD_DIRECTORY = [TARGET_DIRECTORY, '/build']; % for getJSF script
    OSIM_DIRECTORY = [TARGET_DIRECTORY, '/osim']; % for opensim data
    JSF_DIRECTORY = [TARGET_DIRECTORY, '/jsf']; % for joint-space forces results
    OPT_DIRECTORY = [TARGET_DIRECTORY, '/opt']; % for optimisation results
    OSIM_OPT_DIRECTORY = [TARGET_DIRECTORY, '/osim_opt']; % post optimisation

    disp(['Build directory: ', BUILD_DIRECTORY])
    disp(['Opensim results directory: ', OSIM_DIRECTORY])

%     if exist(BUILD_DIRECTORY, 'dir') ...
%                 || exist(OSIM_DIRECTORY, 'dir') ...
%                 || exist(JSF_DIRECTORY, 'dir')
%         if ~p.Results.overwrite
%             error(['One or both of requested directories already exists, '...
%                    'and ''overwrite'' option not supplied. Terminating '...
%                    'incase of user error.'])
%         else
%             disp('Deleting existing directories...')
%             rmdir(BUILD_DIRECTORY, 's')
%             rmdir(OSIM_DIRECTORY, 's')
%             rmdir(JSF_DIRECTORY, 's')
%         end
%     end
    
    if ((exist(BUILD_DIRECTORY, 'dir') ...
                || exist(OSIM_DIRECTORY, 'dir') ...
                || exist(JSF_DIRECTORY, 'dir') ...
                || exist(OPT_DIRECTORY, 'dir') ...
                || exist(OSIM_OPT_DIRECTORY, 'dir')) ...
                && ~p.Results.overwrite)
        error(['One or both of requested directories already exists, '...
                   'and ''overwrite'' option not supplied. Terminating '...
                   'incase of user error.'])
    elseif (p.Results.overwrite)
        if exist(BUILD_DIRECTORY, 'dir')
            disp('Deleting pre-existing build directory.')
            rmdir(BUILD_DIRECTORY, 's')
        end
        if exist(OSIM_DIRECTORY, 'dir')
            disp('Deleting pre-existing OpenSim results directory.')
            rmdir(OSIM_DIRECTORY, 's')
        end
        if exist(JSF_DIRECTORY, 'dir')
            disp('Deleting pre-existing joint-space forces directory.')
            rmdir(JSF_DIRECTORY, 's')
        end
        if exist(OPT_DIRECTORY, 'dir')
            disp('Deleting pre-existing optimisation results directory.')
            rmdir(OPT_DIRECTORY, 's')
        end
        if exist(OSIM_OPT_DIRECTORY, 'dir')
            disp('Deleting pre-existing post-optimisation results directory.')
            rmdir(OSIM_OPT_DIRECTORY, 's')
        end
    end
    
    disp('Creating new directories...')
    mkdir(BUILD_DIRECTORY);
    mkdir(OSIM_DIRECTORY);
    mkdir(JSF_DIRECTORY);
    mkdir(OPT_DIRECTORY);
    mkdir(OSIM_OPT_DIRECTORY);

    copyfile(REQUIRED_FILES_DIRECTORY, TARGET_DIRECTORY)

    %% Data analysis 
    % Load data files and align the data in preparation for RRA. 

    kinematics = Data(p.Results.kinematicData);
    grfs = Data(p.Results.grfData);
    [grfs, kinematics, startTime, endTime] = alignData(grfs, kinematics);
    grfs = grfs.updateHeader(); 
    kinematics = kinematics.updateHeader(); 
    % updateHeader really be called within the alignData function? Bit low
    % level for here? 
    
    % TEMP FOR TESTING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % startTime = 0.05;
    % endTime = 0.10;

    %% Performing RRA using OpenSim. 

    % Dedicated directory for calculating the RRA results.

    RUBBISH_DIRECTORY = ['C:/Users/Daniel/Desktop/Automating Inverse Model/'...
                         'Rubbish/'];
    RRA_DIRECTORY = [RUBBISH_DIRECTORY 'RRA'];

    % The updated grf and kinematic data objects are written to files within
    % the rubbish directory. They are named such that the RRA settings file in
    % the rubbish directory will find them. 

    grfs.writeToFile([RRA_DIRECTORY '/grf.mot'], 1, 1);
    kinematics.writeToFile([RRA_DIRECTORY '/ik.mot'], 1, 1);

    % I had wanted to use startTime and endTime as inputs to API functions.
    % However, this doesn't seem to be possible for the RRA tool in Matlab.
    % Instead I'm going to have to change the xml file.

    rraSettings = xmlread([RRA_DIRECTORY, '/rubbishRRA.xml']);
    rraSettings.getElementsByTagName('initial_time').item(0).getFirstChild. ...
            setNodeValue([num2str(startTime)]);
    rraSettings.getElementsByTagName('final_time').item(0).getFirstChild. ...
            setNodeValue([num2str(endTime)]);
    xmlwrite([RRA_DIRECTORY, '/temporaryRRA.xml'], rraSettings);

    % Create an RRA tool from the temp settings file and run RRA. 

    rraTool = RRATool([RRA_DIRECTORY '/temporaryRRA.xml']);
    rraTool.run();

    %Initially I wanted to delete the temporary directory after I was done with
    %it but for some reason the RRA states file can never be deleted, even if
    %I try to close it beforehand. Overwriting the files still works so I'm
    %just going to do that, and so there is a dedicated 'Rubbish' directory in
    %which the RRA results are obtained, before being copied elsewhere as
    %needed. 
    %fclose('all') % This doesn't work. 
    %rmdir(TEMPORARY_WORKING_DIRECTORY, 's') % This doesn't work. 

    % This is working now that I'm using the better Tasks and Actuators files
    % from Graham. Residuals are within +-30, not perfect for Fy, but good
    % enough for now. Haven't even made the recommended mass adjustments or 
    % chance the torso COM location, will automate these steps later to 
    % reduce residuals further. Can always come back and optimise this later. 
    % Also wanted to test how including the APO forces changes things at the
    % same time. For now this will do.

    %% Process resulting RRA data.

    RRA_KINEMATICS = [RRA_DIRECTORY ['/ResultsRRA/inverse_temp_RRA_'...
                                     'Kinematics_q.sto']];
    RRA_ACCELERATIONS = [RRA_DIRECTORY ['/ResultsRRA/inverse_temp_RRA_'...
                                        'Kinematics_dudt.sto']];
    RRA_STATES = [RRA_DIRECTORY '/ResultsRRA/inverse_temp_RRA_states.sto'];

    RRA_kinematics = RRAData(Data(RRA_KINEMATICS));
    RRA_accelerations = RRAData(Data(RRA_ACCELERATIONS));
    RRA_states = RRAData(Data(RRA_STATES));

    %% Performing inverse dynamics using OpenSim. 

    % Similar to RRA section.

    ID_DIRECTORY = [RUBBISH_DIRECTORY 'ID'];
    RRA_kinematics.writeToFile([ID_DIRECTORY '/RRA_kinematics_q.sto'], 1, 1);
    grfs.writeToFile([ID_DIRECTORY '/grf.mot'], 1, 1);

    idSettings = xmlread([ID_DIRECTORY, '/rubbishID.xml']);
    idSettings.getElementsByTagName('time_range').item(0).getFirstChild. ...
            setNodeValue([' ' num2str(startTime) ' ' num2str(endTime)]);
    xmlwrite([ID_DIRECTORY, '/temporaryID.xml'], idSettings);

    idTool = InverseDynamicsTool([ID_DIRECTORY '/temporaryID.xml']);
    idTool.run();
    
    %% Process resulting ID data. 
    
    ID_DYNAMICS = [ID_DIRECTORY '/ResultsID/id.sto'];

    ID_dynamics = Data(ID_DYNAMICS);
    
    %% Subsample RRA/ID data and save. 
    % For some reason RRA data ends up being one timestep shorter than the
    % grf data, even though it looks like it should fit in. Shave off end
    % of grf data.
    %
    % Found reason for this, look in RRAData. 
    % 
    
    grfs.Values(end,:) = [];
    grfs.Timesteps(end) = [];
    grfs.Frames = size(grfs.Timesteps,1);
    grfs = grfs.updateHeader();
    
    % Need to subsample the RRA/ID/grf data to a common frequency before
    % saving for use in getJointSpaceForces.
    
    commonFrequency = findCommonFrequency(RRA_accelerations,grfs);
    grfs = grfs.subsample(commonFrequency);
    RRA_accelerations = RRA_accelerations.subsample(commonFrequency);
    RRA_states = RRA_states.subsample(commonFrequency);
    ID_dynamics = ID_dynamics.subsample(commonFrequency);
    
    grfs = grfs.updateHeader();
    RRA_accelerations = RRA_accelerations.updateHeader();
    RRA_states = RRA_states.updateHeader();
    ID_dynamics = ID_dynamics.updateHeader();
    
    % Check that the subsampling has actually resulted in datasets with the
    % same number of frames. 
    dataFrames = [grfs.Frames, RRA_accelerations.Frames, RRA_states.Frames, ...
                  ID_dynamics.Frames];
    if ~(max(dataFrames) == min(dataFrames))
        %Remove for testing with manual times for small data sets. 
        error('After subsampling data still has unequal numbers of frames.')
    end
    
    grfs.writeToFile([OSIM_DIRECTORY '/grf.mot'], 0, 0);
    RRA_accelerations.writeToFile([OSIM_DIRECTORY '/RRA_accelerations.sto'], ...
                                  0, 0);
    RRA_states.writeToFile([OSIM_DIRECTORY '/RRA_states.sto'], 0, 0);
    ID_dynamics.writeToFile([OSIM_DIRECTORY '/ID_dynamics.sto'], 0, 0);

    %% Running getJointSpaceForces using the OpenSim C++ API.

    cd(BUILD_DIRECTORY);
    
    [cmake_status, cmdout] = system(['cmake -G "Visual Studio 14 2015 Win64'...
                                    '" ../']);
    if ~(cmake_status == 0)
        display(cmdout);
        error('Failed to generate build files for getJointSpaceForces.')
    end
    display('Build files for getJointSpaceForces generated successfully.');
    
    [build_status, cmdout] = system(['MSBuild getJointSpaceForces.vcxproj ' ...
                           '/p:Configuration=Release']);
    if ~(build_status == 0)
        display(cmdout);
        error('Failed to compile getJointSpaceForces.')
    end
    display('Successfully compiled getJointSpaceForces.')
    
    RELEASE_DIRECTORY = [BUILD_DIRECTORY '/Release'];
    cd(RELEASE_DIRECTORY);
    
    test = ['getJointSpaceForces.exe ' OSIM_DIRECTORY];
    display(test);
    
    [run_status, cmdout] = system(['getJointSpaceForces.exe'...
                                   ' "' OSIM_DIRECTORY '"']);
    if ~(run_status == 0)
        display(cmdout);
        error('Failed to run getJointSpaceForces.')
    end
    display(cmdout);
    display('Successfully ran getJointSpaceForces.');
    
    cd(CURRENT_DIRECTORY);

    %% Checking that getJointSpaceForces worked properly.
    % Check that the residual forces are low enough. Note that for a reason
    % that I don't understand the first frame of getJointSpaceForces data
    % is always innaccurate. So, we toss this frame away here, also.
    %
    % Also I did a test and an analysis on the RRA_q results in the same
    % RRA_states file as the normal RRA process. 
    %
    % I'll do this later. For now more important to move on to
    % incorporating the optimisation step.
    
    %% Perform optimisation. 
    % I'm going to, for now, do each optimisation and save the results in
    % their own folder, since I've made a script for each optimisation
    % problem. These scripts share a huge amount of code so eventually I
    % should make it in to one script, and just modularise the part that is
    % different for each method.
    
    % The getJointSpaceForces script throws away the first timestep. Need
    % to do the same with the RRA_states file now before copying it over to
    % be used in the optimisation.
    RRA_states.Values(1,:) = [];
    RRA_states.Timesteps(1) = [];
    RRA_states.Frames = size(RRA_states.Timesteps,1);
    RRA_states = RRA_states.updateHeader();
    
    % Also, need to create a new, timeless RRA_states file.
    timeless_RRA_states = RRA_states;
    timeless_RRA_states.Values(:,1) = [];
    
    LLS_DIRECTORY = [OPT_DIRECTORY, '/LLS'];
    LLSE_DIRECTORY = [OPT_DIRECTORY, '/LLSE'];
    LLSEE_DIRECTORY = [OPT_DIRECTORY, '/LLSEE'];
    HQP_DIRECTORY = [OPT_DIRECTORY, '/HQP'];
    
    optimisationDirectories = cell(4,1);
    optimisationDirectories{1} = LLS_DIRECTORY; 
    optimisationDirectories{2} = LLSE_DIRECTORY; 
    optimisationDirectories{3} = LLSEE_DIRECTORY;
    optimisationDirectories{4} = HQP_DIRECTORY;
    
    mkdir(LLS_DIRECTORY);
    mkdir(LLSE_DIRECTORY);
    mkdir(LLSEE_DIRECTORY);
    mkdir(HQP_DIRECTORY);
    
    for i=1:size(optimisationDirectories,1)
        copyfile(JSF_DIRECTORY, optimisationDirectories{i});
        timeless_RRA_states. ...
            writeToFile( ...
                [optimisationDirectories{i} '/subsampled_states.txt'], 0, 0);
    end
    
    % Current implementation of inverse models only supports scaling of
    % individual joint efforts by some multiplier. I should definitely fix
    % this and make it more general, but in the interests of getting
    % results for my talk on Wednesday I will wait 'til after then. I will
    % likely hard code temporary changes to LLSEE and HQP methods to do
    % 'APO-like desired' and a desired matching other data, and that should
    % be enough to get a good range of results (for now). The desired
    % matching other data will probably come after I've done the actual
    % presentation as well... 
    
    % Then it's just how I analyse this data afterwards which will be a
    % separate plotting thing. 
    multiplier = 0.5;
    inverseModelNoSlack0Eq(LLS_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack1Eq(LLSE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack2Eq(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP(HQP_DIRECTORY, RRA_states.Frames, multiplier);
    multiplier = 0.7;
    inverseModelNoSlack0Eq(LLS_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack1Eq(LLSE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack2Eq(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP(HQP_DIRECTORY, RRA_states.Frames, multiplier);
    multiplier = 0.9;
    inverseModelNoSlack0Eq(LLS_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack1Eq(LLSE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack2Eq(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP(HQP_DIRECTORY, RRA_states.Frames, multiplier);
    multiplier = 1.1; 
    inverseModelNoSlack0Eq(LLS_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack1Eq(LLSE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack2Eq(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP(HQP_DIRECTORY, RRA_states.Frames, multiplier);
    multiplier = 1.3;
    inverseModelNoSlack0Eq(LLS_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack1Eq(LLSE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelNoSlack2Eq(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP(HQP_DIRECTORY, RRA_states.Frames, multiplier);

    multiplier = 10.0;
    inverseModelNoSlack2Eq_hardcodedAPOdesired(LLSEE_DIRECTORY, RRA_states.Frames, multiplier);
    inverseModelCascadingQP_hardcodedAPOdesired(HQP_DIRECTORY, RRA_states.Frames, multiplier);
    
    %% Build new GRF files from the optimisation output. . 
    % Need to build the new GRF file, (i.e. 4 contact points rather than 2)
    
    % The getJointSpaceForces script throws away the first timestep. Need
    % to do the same with the RRA_states file now before copying it over to
    % be used in the optimisation.
    grfs.Values(1,:) = [];
    grfs.Timesteps(1) = [];
    grfs.Frames = size(grfs.Timesteps,1);
    grfs = grfs.updateHeader();
    
    % THIS IS VERY HARD CODED AND, FOR EXAMPLE, WOULD NEED TO CHANGE IF ANY
    % OF THE MULTIPLIERS ABOVE WERE CHANGED!
    
    OPT_LLS_DIRECTORY = [OSIM_OPT_DIRECTORY, '/LLS'];
    OPT_LLSE_DIRECTORY = [OSIM_OPT_DIRECTORY, '/LLSE'];
    OPT_LLSEE_DIRECTORY = [OSIM_OPT_DIRECTORY, '/LLSEE'];
    OPT_HQP_DIRECTORY = [OSIM_OPT_DIRECTORY, '/HQP'];
    
    mkdir(OPT_LLS_DIRECTORY);
    mkdir(OPT_LLSE_DIRECTORY);
    mkdir(OPT_LLSEE_DIRECTORY);
    mkdir(OPT_HQP_DIRECTORY);
    
    postOptimisationDirectories = cell(4,1);
    postOptimisationDirectories{1} = OPT_LLS_DIRECTORY; 
    postOptimisationDirectories{2} = OPT_LLSE_DIRECTORY; 
    postOptimisationDirectories{3} = OPT_LLSEE_DIRECTORY;
    postOptimisationDirectories{4} = OPT_HQP_DIRECTORY;
    
    GRF_APO_FILES = cell(4,6);
    GRF_APO_OUTPUT = cell(4,6);
    SAVE_DIRECTORIES = cell(4,6);

    for i = 1:size(optimisationDirectories,1)
        count = 1;
        for mult_index = 5:2:13
            GRF_APO_FILES{i,count} = [optimisationDirectories{i}, '/multiplier=', num2str(round(mult_index/10,1)), '/grf_apo.mot'];
            GRF_APO_OUTPUT{i,count} = [postOptimisationDirectories{i}, '/multiplier=', num2str(round(mult_index/10,1)), '/grf_apo.mot'];
            mkdir([postOptimisationDirectories{i}, '/multiplier=', num2str(round(mult_index/10,1))]);
            SAVE_DIRECTORIES{i,count} = [postOptimisationDirectories{i}, '/multiplier=', num2str(round(mult_index/10,1))];
            count = count + 1;
        end
        if i > 2
            GRF_APO_FILES{i,count} = [optimisationDirectories{i}, '/apo_multiplier=10', '/grf_apo.mot'];
            GRF_APO_OUTPUT{i,count} = [postOptimisationDirectories{i}, '/apo_multiplier=10', '/grf_apo.mot'];
            mkdir([postOptimisationDirectories{i}, '/apo_multiplier=10']);
            SAVE_DIRECTORIES{i,count} = [postOptimisationDirectories{i}, '/apo_multiplier=10'];
        end
    end
    
    for i = 1:size(GRF_APO_FILES,1)
        for j = 1:size(GRF_APO_FILES,2)
            if j < 6 || i > 2 
                if ~isempty(GRF_APO_FILES{i,j}) 
                    % What follows is just terrible. But I'm only doing it to get
                    % some quick results. Sorry to my future self. 
                    optGRF = Data(GRF_APO_FILES{i,j});
                    optGRF.Values = [grfs.Values, optGRF.Values];
                    optGRF.Labels = [grfs.Labels, optGRF.Labels];
                    optGRF.Timesteps = optGRF.Values(1:end,1);
                    optGRF.Header = grfs.Header;
                    optGRF.hasHeader = 1;
                    optGRF.isTimeSeries = 1;
                    optGRF.Frequency = grfs.Frequency; 
                    optGRF = optGRF.updateHeader();
                    % FOR IMPROVING: NEED A GENERAL UPDATE_DATA METHOD!
                    % CALLED AFTER EVERY OPERATION ON THE DATASET TO KEEP
                    % ACCURATE HEADER/LABELS/isTIMESERIES ETC!
                    optGRF.writeToFile(GRF_APO_OUTPUT{i,j},1,1);
                end
            end
        end
    end
    
    %% Perform RRA and with the new GRF file and settings. 
    
    RRA_APO_DIRECTORY = [RUBBISH_DIRECTORY 'RRA_apo'];
    
    for i=1:size(GRF_APO_OUTPUT,1)
        for j=1:size(GRF_APO_OUTPUT,2)
            if ~isempty(GRF_APO_OUTPUT{i,j})
                rubbishGRFAPO = Data(GRF_APO_OUTPUT{i,j});

                [rubbishGRFAPO, kinematics, startTime, endTime] = alignData(rubbishGRFAPO, kinematics);
                rubbishGRFAPO = rubbishGRFAPO.updateHeader();
                kinematics = kinematics.updateHeader();

                rubbishGRFAPO.writeToFile([RRA_APO_DIRECTORY, '/grf_apo.mot'], 1, 1);
                kinematics.writeToFile([RRA_APO_DIRECTORY, '/ik.mot'], 1, 1);

                rraSettings = xmlread([RRA_APO_DIRECTORY, '/rubbishRRA.xml']);
                rraSettings.getElementsByTagName('initial_time').item(0).getFirstChild. ...
                        setNodeValue([num2str(startTime)]);
                rraSettings.getElementsByTagName('final_time').item(0).getFirstChild. ...
                        setNodeValue([num2str(endTime)]);
                xmlwrite([RRA_APO_DIRECTORY, '/temporaryRRA.xml'], rraSettings);

                rraTool = RRATool([RRA_APO_DIRECTORY '/temporaryRRA.xml']);
                rraTool.run();

                RRA_APO_KINEMATICS = [RRA_APO_DIRECTORY ['/ResultsRRA/inverse_temp_RRA_'...
                                                 'Kinematics_q.sto']];
                RRA_APO_ACCELERATIONS = [RRA_APO_DIRECTORY ['/ResultsRRA/inverse_temp_RRA_'...
                                                    'Kinematics_dudt.sto']];
                RRA_APO_STATES = [RRA_APO_DIRECTORY '/ResultsRRA/inverse_temp_RRA_states.sto'];

                RRA_APO_kinematics = RRAData(Data(RRA_APO_KINEMATICS));
                RRA_APO_accelerations = RRAData(Data(RRA_APO_ACCELERATIONS));
                RRA_APO_states = RRAData(Data(RRA_APO_STATES));

                %% Perform ID on new RRA data with new grf file and settings. 

                ID_APO_DIRECTORY = [RUBBISH_DIRECTORY 'ID_apo'];

                RRA_APO_kinematics.writeToFile([ID_APO_DIRECTORY '/RRA_kinematics_q.sto'], 1, 1);
                rubbishGRFAPO.writeToFile([ID_APO_DIRECTORY '/grf_apo.mot'], 1, 1);

                idSettings = xmlread([ID_APO_DIRECTORY, '/rubbishID.xml']);
                idSettings.getElementsByTagName('time_range').item(0).getFirstChild. ...
                        setNodeValue([' ' num2str(startTime) ' ' num2str(endTime)]);
                xmlwrite([ID_APO_DIRECTORY, '/temporaryID.xml'], idSettings);

                idTool = InverseDynamicsTool([ID_APO_DIRECTORY '/temporaryID.xml']);
                idTool.run();

                %% Process resulting ID data. 

                ID_DYNAMICS = [ID_APO_DIRECTORY '/ResultsID/id.sto'];

                ID_dynamics = Data(ID_DYNAMICS);

                %% Copy both RRA and ID files in to save directory.
                
                RRA_APO_kinematics.writeToFile([SAVE_DIRECTORIES{i,j} '/RRA_kinematics_q.sto'], 1, 1);
                RRA_APO_accelerations.writeToFile([SAVE_DIRECTORIES{i,j} '/RRA_accelerations.sto'], 1, 1);
                RRA_APO_states.writeToFile([SAVE_DIRECTORIES{i,j} '/RRA_states.sto'], 1, 1);
                ID_dynamics.writeToFile([SAVE_DIRECTORIES{i,j} '/id.sto'], 1, 1);
            end
        end
    end
end
