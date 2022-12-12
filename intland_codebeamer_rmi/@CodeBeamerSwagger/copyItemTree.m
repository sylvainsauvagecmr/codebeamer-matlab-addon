function r = copyItemTree(this, item, dstTrackerId)

% Copy the root
fields = {'name', 'description', 'priority', 'comments', 'icon', 'comments', 'iconColor', 'typeName'};
data = struct;
for i=1:numel(fields)
    if isfield(item, fields{i})
        data.(fields{i}) = item.(fields{i});
    end
end
root = webwrite([this.url '/rest/v3/trackers/' num2str(dstTrackerId) '/items' ], data, this.jsonOptions);


% Copy all children
r = this.recursiveCopy(item, root);


end

