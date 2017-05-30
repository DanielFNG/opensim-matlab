classdef RRAResiduals 
    % Class for holding the results of a residuals analysis on an
    % RRAResult.
    %
    % Computes the (threshold good/okay/bad):
    % Max Residual Force (0-10/10-25/>25)
    % RMS Residual Force (0-5/5-10/>10)
    % Max Residual Moment (0-50/50-75/>75)
    % RMS Residual Moment (0-30/30-50/>50)
    % Max pErr translational (0-2/2-5/>5)
    % RMS pErr translational (0-2/2-4/>4)
    % Max pErr rotational (0-2/2-5/>5)
    % RMS pErr rotational (0-2/2-5/>5)
    
    properties (SetAccess = private)
        MAX_Force % 3D vector, FX/FY/FZ.
        RMS_Force 
        MAX_Moment % 3D vector, MX/MY/MZ.  
        RMS_Moment  
        MAX_pErr_T  % 3D vector, X/Y/Z.
        RMS_pErr_T
        MAX_pErr_R % (n-3)D vector. n = DOF of model. 
        RMS_pErr_R
        
        Grades 
    end
    
    methods
        
        % Construct RRAResiduals object by analysing a given RRAResult.
        function obj = RRAResiduals(RRAResult)
            if nargin > 0
                % Initialise cell array for grades.
                obj.Grades{8} = {};
                
                % Calculate residual metrics.
                obj.MAX_Force = [...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('FX'))), ...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('FY'))), ...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('FZ')))];
                obj.RMS_Force = [...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('FX')), ...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('FY')), ...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('FZ'))];
                obj.MAX_Moment = [...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('MX'))), ...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('MY'))), ...
                    max(abs(RRAResult.forces.getDataCorrespondingToLabel('MZ')))];
                obj.RMS_Moment = [...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('MX')), ...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('MY')), ...
                    rms(RRAResult.forces.getDataCorrespondingToLabel('Mz'))];
                obj.MAX_pErr_T = [...
                    max(abs(RRAResult.errors.getDataCorrespondingToLabel('pelvis_tx'))), ...
                    max(abs(RRAResult.errors.getDataCorrespondingToLabel('pelvis_ty'))), ...
                    max(abs(RRAResult.errors.getDataCorrespondingToLabel('pelvis_tz')))];
                obj.RMS_pErr_T = [...
                    rms(RRAResult.errors.getDataCorrespondingToLabel('pelvis_tx')), ...
                    rms(RRAResult.errors.getDataCorrespondingToLabel('pelvis_ty')), ...
                    rms(RRAResult.errors.getDataCorrespondingToLabel('pelvis_tz'))];
                [obj, n] = obj.calculateRotational(RRAResult);
                obj = obj.gradeResiduals(n);
            end
        end
        
        function [obj, n] = calculateRotational(obj,RRAResult)
            % Initialise arrays -> n - 3 (for translation) - 1 (for time) - 4
            % (for MTP and Subtalar coordinates). Here we're making the
            % assumption that we've constrained the MTP and Subtalar joints
            % to 0 during RRA - this is the default.
            n = size(RRAResult.errors.Labels,2) - 8;
            obj.MAX_pErr_R = zeros(1,n);
            obj.RMS_pErr_R = zeros(1,n);
            
            % Create a copy of the error values. 
            values = RRAResult.errors.Values;
            
            % Obtain the indices we don't want to consider - time,
            % translations, and MTP/Subtalar rotations. 
            time = RRAResult.errors.getIndexCorrespondingToLabel('time');
            px = RRAResult.errors.getIndexCorrespondingToLabel('pelvis_tx');
            py = RRAResult.errors.getIndexCorrespondingToLabel('pelvis_ty');
            pz = RRAResult.errors.getIndexCorrespondingToLabel('pelvis_tz');
            mr = RRAResult.errors.getIndexCorrespondingToLabel('mtp_angle_r');
            ml = RRAResult.errors.getIndexCorrespondingToLabel('mtp_angle_l');
            sr = RRAResult.errors.getIndexCorrespondingToLabel('subtalar_angle_r');
            sl = RRAResult.errors.getIndexCorrespondingToLabel('subtalar_angle_l');
            
            % Sort these indices in ascending order.
            indices_to_remove = sort([time,px,py,pz,mr,ml,sr,sl],'descend');
            
            % Remove these entries from values.
            for i=1:8
                values(:,indices_to_remove(i)) = [];
            end
            
            % Calculate the MAX and RMS errors for the relevant values. 
            obj.MAX_pErr_R(1:end) = rad2deg(max(abs(values(:,1:end))));
            obj.RMS_pErr_R(1:end) = rad2deg(rms(values(:,1:end)));
        end
        
        function obj = gradeResiduals(obj, n)
            % 3D metrics. 
            for i=1:3
                % Classify metrics as 'bad' or 'okay'. 
                if obj.MAX_Force(i) > 25
                    obj.Grades{1} = 'bad';
                elseif isempty(obj.Grades{1}) && obj.MAX_Force(i) > 10
                    obj.Grades{1} = 'okay';
                end
                
                if obj.RMS_Force(i) > 10
                    obj.Grades{2} = 'bad';
                elseif isempty(obj.Grades{2}) && obj.RMS_Force(i) > 5
                    obj.Grades{2} = 'okay';
                end
                
                if obj.MAX_Moment(i) > 75
                    obj.Grades{3} = 'bad';
                elseif isempty(obj.Grades{3}) && obj.MAX_Moment(i) > 50
                    obj.Grades{3} = 'okay';
                end
                
                if obj.RMS_Moment(i) > 75
                    obj.Grades{4} = 'bad';
                elseif isempty(obj.Grades{4}) && obj.RMS_Moment(i) > 30
                    obj.Grades{4} = 'okay';
                end
                
                if obj.MAX_pErr_T(i) > 0.05
                    obj.Grades{5} = 'bad';
                elseif isempty(obj.Grades{4}) && obj.MAX_pErr_T(i) > 0.02
                    obj.Grades{5} = 'okay';
                end
                
                if obj.RMS_pErr_T(i) > 0.05
                    obj.Grades{6} = 'bad';
                elseif isempty(obj.Grades{6}) && obj.RMS_pErr_T(i) > 0.02
                    obj.Grades{6} = 'okay';
                end
                
                % If a metric is unclassified by the end then classify it
                % as 'good'.
                if i == 3
                    for j=1:6
                        if isempty(obj.Grades{j})
                            obj.Grades{j} = 'good';
                        end
                    end
                end
                
            end
            
            % Rotational errors. 
            for i=1:n
                if obj.MAX_pErr_R(i) > 5
                    obj.Grades{7} = 'bad';
                elseif isempty(obj.Grades{7}) && obj.MAX_pErr_R(i) > 2
                    obj.Grades{7} = 'okay';
                end
                
                if obj.RMS_pErr_R(i) > 5
                    obj.Grades{8} = 'bad';
                elseif isempty(obj.Grades{8}) && obj.RMS_pErr_R(i) > 2
                    obj.Grades{8} = 'okay';
                end
                
                if i == n
                    for j=7:8
                        if isempty(obj.Grades{j})
                            obj.Grades{j} = 'good';
                        end
                    end
                end
            end
        end
        
        function grade = getTotalGrade(obj)
            % If any grade is bad, set overall grade to bad.
            for i=1:8
                if strcmp(obj.Grades{i}, 'bad')
                    grade = 'bad';
                    return;
                end
            end
            
            % Otherwise, if any grade is okay, set overall grade to okay.
            for i=1:8
                if strcmp(obj.Grades{i}, 'okay')
                    grade = 'okay';
                    return;
                end
            end
            
            % Otherwise, set the grade to good.
            grade = 'good';
        end
        
    end
    
end

