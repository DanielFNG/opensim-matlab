
function [c,d] =  ANOVA_two_way(A)


%% Average over steady state gait cycles and subjects

Observation_array = zeros(210,5);

 b = [];
% % Loop over the assistance levels.
for assistance_level=1:3
            
    % Loop over the five steady state contexts. 
    for i=[2 4 6 8 10]      
        for subject = [1:4 6:8]
            for j = 1:4
                b = [b A{subject,assistance_level,1,i}{j}];
                b = [b A{subject,assistance_level,2,i}{j}];
            end
        end
        
        Observation_array(((assistance_level)*70)-69:(assistance_level)*70,...
            i/2) = b;
        b = [];
    end
end
   

nmbob = 70; % Number of replications for each assistance level/context

[~,~,stats] = anova2(Observation_array,nmbob)

figure();
c = multcompare(stats)
figure();
d = multcompare(stats,'Estimate','row')

