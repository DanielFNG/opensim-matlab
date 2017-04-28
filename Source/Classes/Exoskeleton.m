classdef Exoskeleton 
    % Class to hold all the files, settings and paramters which are
    % exoskeleton specific. For example, the model file, controller
    % parameters like link lengths. The contact point settings file. 
    
    properties (SetAccess = private)
        Name
        Model % Human/exoskeleton OpenSim model 
        ContactPoints % Contact points settings file (Jacobians). 
        ExternalLoads % External loads settings files (forward simulation).
        Exo_dofs = 2; 
        Human_dofs = 23; 
        % Want to change ContactPointSettings to be an Exoskeleton
        % description file including the number of actuated degrees of
        % freedom, joint limits etc. Then Exo_dofs and the joint limits can
        % be read in from this. Also, human_dofs should be read in from the
        % model file. But I'll implement this in a bit. Hard-coding it for
        % now to avoid breaking the current ContactPointSettings
        % implementation. 
    end
    
    methods
        
        function obj = Exoskeleton(name, varargin)
            if nargin > 0
                obj.Name = name;
            end
            if size(varargin,2) == 0
                obj = obj.loadDefaults();
            elseif size(varargin,2) ~= 3
                error('Exoskeleton class accepts 1 or 4 arguments only.')
            else
                obj.Model = varargin{1,1};
                obj.ContactPoints = varargin{1,2};
                obj.ExternalLoads = varargin{1,3};
            end
        end
        
        function model = constructExoskeletonForceModel(obj, rra, dir, desc)
            % Desc is a description of the force model to be calculated.
            % E.g. 'linear', for the linearAPOForceModel.
            if strcmp(obj.Name, 'APO')
                if strcmp(desc, 'old_linear')
                    model = obj.constructOldLinearAPOForceModel(rra, dir);
                elseif strcmp(desc, 'linear')
                    model = obj.constructLinearAPOForceModel(rra, dir);
                else 
                    error('Force model not recognised.');
                end
            else
                error('Exoskeleton has no force models!')
            end
        end
        
        function obj = loadDefaults(obj)
            % Search for the appropriate files in the default folder(s). 
            obj.Model = [getenv('EXOPT_HOME') '/Defaults/Model/' ...
                obj.Name '.osim'];
            obj.ContactPoints = [getenv('EXOPT_HOME') ...
                '/Defaults/ContactPointSettings/' obj.Name '.xml'];
            obj.ExternalLoads = [getenv('EXOPT_HOME') ...
                '/Defaults/ExternalLoads/' obj.Name '.xml'];
            
            % If these files don't exist, throw an error. 
            if exist(obj.Model, 'file') ~= 2 
                error('Could not find default model for given exoskeleton.');
            elseif exist(obj.ContactPoints, 'file') ~= 2
                error('Could not find default contacts for given exoskeleton.');
            elseif exist(obj.ExternalLoads, 'file') ~= 2
                error('Could not find default ext. for given exoskeleton.');
            end
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
    
    methods (Access = private)
        
        % Private since only want constructExoskeletonFroceModel to be able
        % to use this.
        function APO_model = constructOldLinearAPOForceModel(obj, rra, dir)
            % Inputs are states & a directory for results to be stored. 
            states = rra.states;
            % Hard coded APO link length for now. But in the future this
            % should be interpreted from the ContactPointSettings file.
            d = 0.23;
            
            Jacobians = FrameJacobianSet(obj.Model, states, ...
                obj.getContactSettings(), dir);
            
            nTimesteps = size(states.Timesteps,1);
            Q{nTimesteps} = 0; % pre allocation for speed 
            P{nTimesteps} = 0;
            
            % Get the left & right hip flexion joint angles in vector form.
            right_hip_flexion = states.getDataCorrespondingToLabel(...
                'hip_flexion_r');
            left_hip_flexion = states.getDataCorrespondingToLabel(...
                'hip_flexion_l');
            
            for i=1:nTimesteps
                Q{i} = zeros(obj.Human_dofs,1);
                unit_right_force = [0;0;0; ...
                    cos(right_hip_flexion(i,1));sin(right_hip_flexion(i,1));0];
                unit_left_force = [0;0;0; ...
                    cos(left_hip_flexion(i,1));sin(left_hip_flexion(i,1));0];
                right_jacobian = Jacobians.JacobianSet{1}.Jacobian.Values{i};
                left_jacobian = Jacobians.JacobianSet{2}.Jacobian.Values{i};
                P{i} = 1/d*[right_jacobian.' * unit_right_force ...
                    , left_jacobian.' * unit_left_force];
            end
            APO_model = LinearExoskeletonForceModel(obj, rra, P, Q);
            
        end
        
        % This will be for the new APO model with 2 additional contact
        % points. But first I want to compare that I get the same results
        % as last time using the old model as a validation step. 
        function APO_model = constructLinearAPOForceModel(obj, rra, dir)
            
            states = rra.states;
            
            d_link = 0.23; % from torque generation to leg attachment
            d_weld = 0.183145; % from torque generation to backpack weld 
            
            Jacobians = FrameJacobianSet(obj.Model, states, ...,
                obj.getContactSettings(), dir);
            
            nTimesteps = size(states.Timesteps,1);
            Q{nTimesteps} = 0;
            P{nTimesteps} = 0; 
            
            % Get the left & right hip flexion joint angles in vector form.
            right_hip_flexion = states.getDataCorrespondingToLabel(...
                'hip_flexion_r');
            left_hip_flexion = states.getDataCorrespondingToLabel(...
                'hip_flexion_l');
            
            % And store the constant angle vs the horizontal for the left &
            % right groups. 
            group_angle = deg2rad(33.08);
            
            % Making a ContactForceSet.
            ContactSet{nTimesteps,4} = 0;
            
            for i=1:nTimesteps
                Q{i} = zeros(obj.Human_dofs,1);
                % Links
                right_force = 1/d_link*[0;0;0; ...
                    cos(right_hip_flexion(i,1));sin(right_hip_flexion(i,1));0];
                ContactSet{i,1} = right_force;
                left_force = 1/d_link*[0;0;0; ...
                    cos(left_hip_flexion(i,1));sin(left_hip_flexion(i,1));0];
                ContactSet{i,2} = left_force;
                right_jacobian = Jacobians.JacobianSet{1}.Jacobian.Values{i};
                left_jacobian = Jacobians.JacobianSet{2}.Jacobian.Values{i};
                % Groups
                right_group_force = -1/d_weld*[0;0;0; ...
                    sin(group_angle);cos(group_angle);0];
                ContactSet{i,3} = right_group_force;
                left_group_force = -1/d_weld*[0;0;0; ...
                    sin(group_angle);cos(group_angle);0];
                ContactSet{i,4} = left_group_force;
                right_group_jacobian = ...
                    Jacobians.JacobianSet{3}.Jacobian.Values{i};
                left_group_jacobian = ...
                    Jacobians.JacobianSet{4}.Jacobian.Values{i};
                % Adding it all together 
                P{i} = [right_jacobian.' * right_force ... 
                    + right_group_jacobian.' * right_group_force, ...
                    left_jacobian.' * left_force ...
                    + left_group_jacobian.' * left_group_force];
            end
            % Construct the full ContactForceSet.
            % These particular forces are UNIT spatial forces meaning the
            % arise from a motor value of 1. 
            forces = ContactForceSet(Jacobians, ContactSet);
            APO_model = LinearExoskeletonForceModel(obj, rra, ...
                P, Q, Jacobians, forces);
        end
        
    end
    
end

