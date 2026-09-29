function p = plot_multicolor_rik(x,y,group,varargin)
group_keys = unique(group);
nGroups = length(group_keys);
hold on
for iGroup = 1:nGroups
    group_elements = find(group==group_keys(iGroup));
    if iGroup<nGroups
        group_elements(end) = group_elements(end)+1; % This adds overlap between a group and the next one
    end
    colorgroup = lines(nGroups);
    p = plot(x(group_elements),y(group_elements),varargin{:});
    p.Color = colorgroup(iGroup,:);
end
hold off
% drawnow
% 
% nGroups = length(unique(group));
% colorgroup = [uint8(lines(nGroups)*255) uint8(ones(nGroups,1))].';
% colorpoint = colorgroup(:,group);
% set(p.Edge,'ColorBinding','interpolated', 'ColorData',colorpoint)

