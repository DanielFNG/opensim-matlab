function ThreeDBarWithErrorBars(PeakVals, ErrorBarSizes, metric)

%{
%to test the function run the following code at the matlab prompt:
cols = 5;       %columns in the matrix
rows = 4;       %rows in the matrix
PeakVals = rand(rows,cols);  % matrix of peak heights
Peak_Stdevs = ones(rows,cols)*0.15; % matrix of standard deviations
ThreeDBarWithErrorBars(PeakVals, Peak_Stdevs)
%}

if size(PeakVals) == size(ErrorBarSizes)

    [rows , cols] = size(PeakVals);
    
    % Plot the 3D bar graph
    b = figure;
    axes1 = axes('Parent',b);
    b = bar3(PeakVals) ; 
    
    colormap('parula');
    colorbar
    
    for k = 1:length(b)
        zdata = b(k).ZData;
        b(k).CData = zdata;
        b(k).FaceColor = 'interp';
    end

    %Now plot the standard deviations on top of the bars
    hold on;
    for row = 1:rows,
        for col = 1:cols,
            z = PeakVals(row,col) : (ErrorBarSizes(row,col) / 50) : (PeakVals(row,col) + ErrorBarSizes(row,col));
            x(1:length(z)) = row;
            y(1:length(z)) = col;
            if rows >= cols
                plot3(x, y, z,'r-')
            end
            if rows < cols
                plot3(y, x, z,'r-','linewidth', 1)
            end
            clear x; clear y; clear z;
        end
    end
    hold off
    %disp('done');
else
    disp('error, matrices not the same size');
end

% Now add the axis labels


% Create xlabel
xlabel({'Walking context'});

% Create zlabel
zlabel({metric});

% Create ylabel
ylabel({'Assistance scenario'});

% Set tick labels
set(axes1,'XTick',[1 2 3 4 5],...
    'XTickLabel',{'BW','IW','DW','FW','SW'},'YTick',[1 2 3],'YTickLabel',...
    {'NE','ET','EA'});


