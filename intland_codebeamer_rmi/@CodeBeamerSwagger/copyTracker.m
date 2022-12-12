function r = copyTracker(this, srcTrackerId, dstTrackerId)

this.selectTracker(srcTrackerId);

this.readItems;
list = arrayfun(@(x) this.readItemDetails(x.id), this.items.itemRefs,'UniformOutput', false);
filter = cellfun(@(x) ~isfield(x, 'parent'), list);
top = list(filter);
for i=numel(top):-1:1
    this.copyItemTree(top{i}, dstTrackerId);
end
r=true;

% 
% 
% details = webread([this.url '/rest/v3/items/' num2str(itemId)], this.jsonOptions);
% data = struct(...
%     'project'    ,  ['/project/' num2str(targetProjectId)], ...
%     'type'       ,  'TrackerReference', ...
%     'name'       ,  'Music Player ProgCopy', ...
%     'keyName'    ,  '', ...
%     'description',  'Testing programmatic copy.', ...
%     'descFormat' ,  'Wiki', ...
%     'workflow'   ,  true);
% r = webwrite([this.url '/rest/tracker/' num2str(trackerId) '/clone'], data, this.jsonOptions);
end