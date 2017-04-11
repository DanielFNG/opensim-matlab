classdef FrameJacobianSet
    % Class for calculating and storing FrameJacobians. 
    %   Given an OpenSimTrial and a set of contact points for which
    %   FrameJacobians are desired, described by the appropriate
    %   ContactPointSettings xml file, this function computes and stores
    %   these Jacobians.
    %
    %   This class contains functions for returning parameters relating to
    %   a specific contact point given the name. See comments below for
    %   usage guidelines.
    
    properties (SetAccess = private)
        Trial % OpenSimTrial with RRA calculated 
        Names % array of names given to the contact points in the setup file
        JacobianSet % set of FrameJacobian objects
    end
    
    methods
        
        function obj = FrameJacobianSet(OpenSimTrial, ContactPointSettings, dir)
            % OpenSimTrial is the OpenSimTrial for which frame Jacobians
            % are sought. dir is the results directory in which output
            % files are stored. ContactPointSettings is a string describing
            % the ContactPointSettings to use. A corresponding settings
            % file 'ContactPointSettings.xml' (where ContactPointSettings
            % is the string input) should be located in
            % Exopt/Defaults/ContactPointSettings.
            if nargin > 0
                obj.Trial = OpenSimTrial;
                dir = createUniqueDirectory(dir);
                % Do the actual getFrameJacobians call. 
                obj.calculateFrameJacobianSet(ContactPointSettings, dir)
                info = importdata([dir '/info.txt']);
                % Load the info.txt file and get the names etc. 
                obj.Names = cell(size(info.textdata,1),1);
                obj.JacobianSet = cell(size(info.textdata,1),1);
                % Create a FrameJacobian for each name and add it to the
                % FrameJacobianSet. 
                for i=1:size(info.textdata,1)
                    point = [info.data(i,1); info.data(i,2); info.data(i,3)];
                    obj.Names{i} = char(info.textdata(i,1));
                    obj.JacobianSet{i} = FrameJacobian(OpenSimTrial, ...
                        obj.Names{i}, info.textdata(i,2), point, ...
                        getFullPath([dir '/' obj.Names{i} '.txt']));
                end
            end
        end
        
        % Uses the getFrameJacobian file in bin along with the
        % ContactPointSettings file specified to run getFrameJacobians.
        function calculateFrameJacobianSet(obj, ContactPointSettings, dir)
            if isa(obj.Trial.rra, 'char')
                error(['RRA has not yet been calculated '...
                    'for this OpenSimTrial. Value classes!']);
            end
            current_dir = pwd;
            home = getenv('EXOPT_HOME');
            setupfile = [home '\defaults\ContactPointSettings\' ...
                ContactPointSettings '.xml'];
            cd([home '\bin']);
            % Remove headers and labels. 
            states_without_header = obj.removeHeaderFromStatesFile(dir);
            [run_status, cmdout] = system(['getFrameJacobians.exe'...
                ' "' obj.Trial.model_path '" '...
                ' "' states_without_header '" '...
                ' "' setupfile '" '...
                ' "' getFullPath(dir) '" ']);
            if ~(run_status == 0)
                display(cmdout);
                error('Failed to run getFrameJacobians.');
            end
            cd(current_dir);
        end
        
        % Removes header from the OpenSimTrial states file. A new,
        % headerless file is printed. 
        function no_header = removeHeaderFromStatesFile(obj, dir)
            no_header = [dir '\no_header.sto'];
            obj.Trial.rra.states.writeToFile(no_header,0,0);
        end
        
    end
    
end

