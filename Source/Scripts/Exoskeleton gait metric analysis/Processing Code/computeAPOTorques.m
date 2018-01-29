%% Compute APO torques. 

n_timeskips = 5;
lookahead_window = 600;

for subject=[1:4,6:8]
    result  = readAPOData(['S' num2str(subject) '_EA.bin']);
    
    %% Segment the data according to timeskips.
    timediffs = result.Time(2:end) - result.Time(1:end-1);
    segs = zeros(1,n_timeskips);
    for i=1:n_timeskips
        [~, maxloc] = max(timediffs);
        segs(1,i) = maxloc + 1;
        timediffs(maxloc) = 1; % Set this to 1 so it will no longer be a maximum.
    end
    
    %% Use autocorrelation to detect the first 3 cycles for each context.
    for i=1:5
        x = result.H_RightActualTorque(segs(1,i):segs(1,i)+lookahead_window);
        ac = xcorr(x, x);
        [~, locs] = findpeaks(ac);
    end
    
    
    %% Save in a single struct. 
    APO.(['subject' num2str(subject)]) = result;
end