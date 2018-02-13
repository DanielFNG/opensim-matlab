classdef RRAData < Data 
    %Class for storing and working with data obtained using OpenSim's RRA
    %tool.
    
    properties (SetAccess = private)
        defaultTimestep = 0.001;
    end
    
    methods
        % Initialise RRAData as an empty data object, then copy properties from 
        % a provided Data object, or create a Data object from a provided
        % filename and then copy properties over.
        function obj = RRAData(input)
            obj@Data();
            if isa(input,'char')
                input = Data(input);
            end
            obj.Values = input.Values; 
            obj.Labels = input.Labels;
            obj.Header = input.Header;
            obj.Frames = input.Frames;
            obj.Timesteps = input.Timesteps;
            obj.hasHeader = input.hasHeader;
            obj.isLabelled = input.isLabelled; 
            obj.isTimeSeries = input.isTimeSeries;
            
            % Set the RRAData specific information. 
            % RRAData is by default of consistent frequency, and is at
            % 1000HZ, once you have stripped the intermediate timesteps.
            obj.isConsistentFrequency = 1;
            obj.Frequency = 1/obj.defaultTimestep;
            obj = obj.stripIntermediateTimesteps();
            obj = obj.updateHeader();
        end
        
        % Modifies an RRAData object to remove intermediate
        % timesteps from the final results.
        function obj = stripIntermediateTimesteps(obj)
        % RRA files typically have a frequency of 1000Hz, so timesteps are
        % in 0.001s. However, if during the simulation RRA needs to take a
        % shorter timestep in order to increase accuracy it will do so. So
        % you can get files like...
        %     0.001
        %     0.002
        %     0.002018678
        %     0.003
        % and so on. These intermediate timesteps are undesirable when
        % using the RRA data so this function removes them. 
            timeColumn = obj.getTimeColumn();
            indicesToDelete = [];
            for i=1:size(timeColumn,1)
                if rem(round(timeColumn(i),5),0.001) > 0.00001
                    indicesToDelete = [indicesToDelete, i];
                end
            end
            obj.Values(indicesToDelete,:) = [];
            % For some reason the last row of RRA data is always a duplicate
            % of the previous row (including the timestep - i.e. it goes 
            % 1.498 1.499 1.499 instead of 1.500 for the last one. Not sure 
            % if it's to tell OpenSim that the RRA has finished or what. I 
            % previously deleted this row, but this is undesirable because you 
            % end up getting ID's and RRA's with different numbers of frames, 
            % even if they were run on the same number of timesteps. Instead, I 
            % will keep the rows duplicated values, but set the value of
            % the time column to be incremented by 0.001.
            obj.Values(end,1) = obj.Values(end-1,1) + 0.001;
            obj.Timesteps = obj.getTimeColumn();
            obj.Frames = size(obj.Values,1);
            
            % Remove duplicates. Sometimes if the extra values taken by RRA
            % were very small they may sneak by ie. (real example)
            % 3.919998 3.92 results in 2x 3.92.
            % Removing the second duped frame just by convention, although
            % this could be done better by looking at the non-rounded
            % values and choosing which is closer.
            % This could really be it's own function. RRAData specific
            % since it uses knowledge of RRA data (round,3).
            indicesToDelete = [];
            for i=2:obj.Frames
                if round(obj.Timesteps(i),3) == round(obj.Timesteps(i-1),3)
                    indicesToDelete = [indicesToDelete, i];
                end
            end
            obj.Values(indicesToDelete,:) = [];
            obj.Timesteps = obj.getTimeColumn();
            obj.Frames = size(obj.Values,1);
            
            % Implement a sanity check: the (number of frames - 1) * the RRA
            % timestep (0.001s) should be equal to the final timestep minus
            % the initial timestep.
            if abs((obj.Frames - 1)*obj.defaultTimestep - (obj.Timesteps(end)...
                        - obj.Timesteps(1))) > 0.00001
                error('Could not strip intermediate RRA timesteps.')
            end
            display('Intermediate timesteps correctly removed from RRA data.')
        end
        
    end
    
end

