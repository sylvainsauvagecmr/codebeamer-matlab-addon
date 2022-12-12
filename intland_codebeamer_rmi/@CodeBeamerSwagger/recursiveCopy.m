function r = recursiveCopy(this, item, parent)

% Copy all children
list = arrayfun(@(x) this.readItemDetails(x.id), item.children, 'UniformOutput',false);

for idx = 1:numel(list)
    c = list{idx};
    fields = {'name', 'description', 'priority', 'status',  'comments', 'icon', 'priority' 'comments', 'iconColor', 'typeName'};
    data = struct;
    for i=1:numel(fields)
        if isfield(c, fields{i})
            data.(fields{i}) = c.(fields{i});
        end
    end
    data.type = data.typeName;
    newItem = webwrite([this.url '/rest/v3/trackers/' num2str(parent.tracker.id) '/items' ], data, this.jsonOptions);
    webwrite([this.url '/rest/v3/items/' num2str(parent.id) '/children' ], struct('id', newItem.id), this.jsonOptions);

    this.recursiveCopy(c, newItem);
end

r = true;
end