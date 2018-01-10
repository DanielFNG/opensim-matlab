function [ ] = plotSigDiff( col_sigdiff, row_sigdiff , Average_array )
%PLOTSIGDIFF Plot the significant differences


j = 0.1;

for i = 1:size(col_sigdiff,1)
    if col_sigdiff(i,end) > 0.05
    Mx = max(Average_array(:))+ max(Average_array(:))*j;
    j = j+0.1;
    x = [col_sigdiff(i,1);col_sigdiff(i,2)];
    y = zeros(2);
    z = ones(1,2)*Mx;
     plot3(x,y,z,'-k*','linewidth',1);
    end
end

j = 0.1;

for i = 1:size(row_sigdiff,1)
    if row_sigdiff(i,end) > 0.05
    Mx = max(Average_array(:))+ max(Average_array(:))*j;
    j = j+0.1;
    x = ones(1,2)*5.4;
    y = [row_sigdiff(i,1);row_sigdiff(i,2)];
    z = ones(1,2)*Mx;
     plot3(x,y,z,'-k*','linewidth',1);
    end
end


end

