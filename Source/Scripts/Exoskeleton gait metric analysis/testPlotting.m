overall = 1:10
for i=1:10
    diff = metrics{i}.calculateRelativeDifferences();
    ThreeDBarWithErrorBars(diff, zeros(3,5), metrics{i}.name);
    overall(1,i) = metrics{i}.calculateOverall();
end

figure
bar(overall)