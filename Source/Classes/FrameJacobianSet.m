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
    
    properties
        Trial % OpenSimTrial with RRA calculated 
        Names % array of names given to the contact points in the setup file
        Jacobians % map from names to FrameJacobian objects 
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
                obj.calculateFrameJacobianSet(ContactPointSettings, dir)
            end
        end
        
        function calculateFrameJacobianSet(obj, ContactPointSettings, dir)
            current_dir = pwd;
            home = getenv('EXOPT_HOME');
            setupfile = [home '\defaults\ContactPointsSettings\' ...
                ContactPointSettings '.xml'];
            cd([home '\bin']);
            % I NEED TO REMOVE HEADERS!
            [run_status, cmdout] = system(['getFrameJacobians.exe'...
                ' "' obj.Trial.model_path '" '...
                ' "' obj.Trial.rra.states_path '" '...
                ' "' setupfile '" '...
                ' "' getFullPath(dir) '" ']);
            if ~(run_status == 0)
                display(cmdout);
                error('Failed to run getFrameJacobians.');
            end
            cd(current_dir);
        end
        
    end
    
end

