function APO = computeAPOTorques(path, subject)

    n_timeskips = 5;
    lookahead_window = 700;
    n_cycles = 2;
    vector_size = 1000;

    result  = readAPOData([path filesep 'S' num2str(subject) '_EA.bin']);
    
    % Segment the data according to timeskips.
    timediffs = result.Time(2:end) - result.Time(1:end-1);
    segs = zeros(1,n_timeskips);
    for i=1:n_timeskips
        [~, maxloc] = max(timediffs);
        segs(1,i) = maxloc + 1;
        timediffs(maxloc) = 1; % Set this to 1 so it will no longer be a maximum.
    end
    
    % Sort the segs array.
    segs = sort(segs);
    
    % Detect cycles and form average.
    names = fieldnames(result);
    for i=1:n_timeskips
        y = result.H_RightJointAngle(segs(1,i):segs(1,i)+lookahead_window);
        ac = xcorr(y, y);
        [~, locs] = findpeaks(ac);
        for j=1:length(names)-1
            x = result.(names{j})(segs(1,i):segs(1,i)+lookahead_window);
            cycles = cell(1,n_cycles);
            for k=1:n_cycles
                if subject == 6 && i == 3
                    cycles{k} = ...
                        stretchVector(x(locs(k+4):locs(k+5)), vector_size);
                else
                    cycles{k} = ...
                        stretchVector(x(locs(k+1):locs(k+2)), vector_size);
                end
            end
            cycle = [];
            for k=1:n_cycles
                cycle = [cycle cycles{k}];
            end
            result.(['Avg' names{j}]).(['Context' num2str(i*2)]) = cycle;
        end
    end
    
    APO = result;

end