function result = initialiseSubjectData(subject)

leg_lengths = [0.93 0.93 0.91 0.9 0.97 0.97 0.94 0.95 0.92];
walking_speeds = [0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    1.14 1.14 1.13 1.13 1.18 1.18 1.15 1.16;...
    0.76 0.76 0.75 0.75 0.78 0.78 0.77 0.78];

result.Name = ['subject' num2str(subject)];
result.Properties.LegLength = leg_lengths(subject);
result.Properties.WalkingSpeed = walking_speeds(1:end,subject);
end

