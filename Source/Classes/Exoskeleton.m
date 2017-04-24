classdef Exoskeleton 
    % Class to hold all the files, settings and paramters which are
    % exoskeleton specific. For example, the model file, controller
    % parameters like link lengths. The contact point settings file. 
    
    properties (SetAccess = private)
        Name
        Model % Human/exoskeleton OpenSim model 
        ContactPoints % Contact points settings file (Jacobians). 
        ExternalLoads % External loads settings files (forward simulation).
    end
    
    methods
        
        function obj = Exoskeleton(name, varargin)
            if nargin > 0
                obj.Name = name;
            end
            if size(varargin,2) == 0
                obj = obj.loadDefaults();
            elseif size(varargin,2) ~= 3
                error('Exoskeleton accepts 1 or 4 arguments only.')
            else
                obj.Model = varargin{1,1};
                obj.ContactPoints = varargin{1,2};
                obj.ExternalLoads = varargin{1,3};
            end
        end
        
        function obj = loadDefaults(obj)
            % Search for the appropriate files in the appropriate
            % locations. If they don't exist, throw an error. 
        end
        
        function name = getName(obj)
            name = obj.Name;
        end
        
        function model_path = getModel(obj)
            model_path = obj.Model;
        end
        
        function contact_settings = getContactSettings(obj)
            contact_settings = obj.ContactPoints;
        end
        
        function external_loads = getExternalLoads(obj)
            external_loads = obj.ExternalLoads;
        end
        
    end
    
end

