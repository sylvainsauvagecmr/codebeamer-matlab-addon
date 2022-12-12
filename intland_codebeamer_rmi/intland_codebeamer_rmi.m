% BSD 3-Clause License
%
% Copyright 2020 Intland Software GmbH
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.

% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function linktype = intland_codebeamer_rmi
% Create a default (blank) requirements target
linktype = ReqMgr.LinkType;
linktype.Registration = mfilename;

% Label describing this link type
linktype.Label = 'CodeBeamer Item';
linktype.SelectionLinkLabel = 'Link to CodeBeamer Item';

% File information.
linktype.IsFile = 0;
linktype.Extensions = {};

% Location Delimiters
linktype.LocDelimiters = '#';
linktype.Version = '';             % not needed

% Implemented callback functions.
linktype.BrowseFcn        = @selectTracker;          % choose a tracker
linktype.IsValidDocFcn    = @checkTrackerURI;        % for consistency checking
linktype.IsValidIdFcn     = @checkLinkURI;           % for consistency checking
linktype.IsValidDescFcn   = @checkLinkDescription;   % for consistency checking
linktype.ContentsFcn      = @showTrackerOutline;     % for document index
linktype.CreateURLFcn     = @getItemURL;
linktype.NavigateFcn      = @showTrackerItem;
linktype.DetailsFcn       = @showTrackerItemOutline; % for detailed report
linktype.SelectionLinkFcn = @linkTrackerItem;        % create link to item
% linktype.UrlLabelFcn      = @getLinkLabel;
end


function trackerURI = getTrackerURI(tracker)
if isempty(tracker)
    trackerURI = [];
else
    trackerURI = [tracker.uri ': ' tracker.project.name ' / ' tracker.name];
end
end

function cbTrackerURI = getCodeBeamerTrackerURI(trackerURI)
cbTrackerURI = trackerURI;

if ~isempty(trackerURI)
    index = strfind(trackerURI, ': ');
    if ~isempty(index)
        cbTrackerURI = trackerURI(1:index - 1);
    end
end
end

function [projectId, trackerId] = loc_extractP_T_ids(trackerURI)
match = regexp(trackerURI, '(?<projectId>[0-9]*)/(?<trackerId>[0-9]*)', 'names');
projectId = str2double(match.projectId);
trackerId = str2double(match.trackerId);
end

function [itemId, txt] = loc_extractItem_id(itemURI)
match = regexp(itemURI, '(?<txt>.*?) #(?<id>[0-9]*$)', 'names', 'once');
itemId = str2double(match.id);
txt = match.txt;
end

function trackerURI = selectTracker()
% Allows users to select a CodeBeamer Tracker via Browse button of Link Editor dialog.
cbx = evalin('base', 'cbx');
trackerURI = cbx.getActiveProjectURL(cbx.getActiveProject);
end

function valid = checkTrackerURI(trackerURI, ~)
% Used for requirements consistency checking.
% Returns true if trackerURI identifies a valid tracker otherwise false
cbx = evalin('base', 'cbx');

[projectId, trackerId] = loc_extractP_T_ids(trackerURI);
valid = cbx.access.existsProject(projectId) && cbx.access.existsTracker(trackerId);
end

function [itemLabel, itemDepth, itemURI] = showTrackerOutline(trackerURI)
% Used to display the document index tab of Link Editor dialog.
cbURI = getCodeBeamerTrackerURI(trackerURI);
cb = intland.CodeBeamer;
[itemLabel, itemDepth, itemURI] = cb.getTrackerOutline(cbURI);
end

%TESTME
function cbURI = getCodeBeamerURI(trackerURI, itemURI, itemBase)
cbURI = [];

if isempty(itemURI)
    cbURI = getCodeBeamerTrackerURI(trackerURI);
else
    uriType = itemURI(1);
    itemURI = itemURI(2:end);

    switch uriType
        case '#'
            cbURI = [itemBase itemURI];
            %           case '@'
            %               if itemURI(1) == '['
            %                   index = strfind(itemURI, '] ');
            %                   if ~isempty(index)
            %                       cbURI = [itemBase itemURI(2:index(0) - 1)];
            %                   end
            %               elseif strncmp(itemURI, '/item/', 6)
            %                    cbURI = [itemBase itemURI(7:end)];
            %               end
        otherwise
            warning('SLVNV:reqmgt:customType:unsupportedLocationType', ['Unsupported location type: ' uriType]);
    end
end
end

%TESTME
function url = getItemURL(trackerURI, trackerURL, itemURI)
if isempty(itemURI) && ~isempty(trackerURL)
    url = trackerURL;
else
    cbURI = getCodeBeamerURI(trackerURI, itemURI, '/issue/');
    if isempty(cbURI)
        url = cbURI;
    else
        cb = intland.CodeBeamer;
        url = [cb.server.url cbURI];
    end
end
end

%TESTME
function valid = checkLinkURI(trackerURI, itemURI)
% Used for requirements consistency checking.
% Returns true if LOCATION can be found in DOCUMENT.
% Returns false if LOCATION is not found.
% Should generate an error if DOCUMENT not found or fails to open.
cbx = evalin('base', 'cbx');
[projectId, trackerId] = loc_extractP_T_ids(trackerURI);
if cbx.access.existsProject(projectId) && cbx.access.existsTracker(trackerId)
    [itemId, txt] = loc_extractItem_id(itemURI);
    item = cbx.access.readItemDetails(itemId);
    valid = (item.tracker.id == trackerId) && strcmp(txt, item.name);
else
    valid = false;
end
end

%TESTME
function [valid, name] = checkLinkDescription(~, itemURI, description)
% valid is true if description is the name of the linked tracker item
% name is empty if description is valid, otherwise the name of the linked tracker item.
cbx = evalin('base', 'cbx');
[itemId, ~] = loc_extractItem_id(itemURI);
item = cbx.access.readItemDetails(itemId);
if strcmp(item.description, description)
    valid = true;
    name = [];
else
    valid = false;
    name = item.description;
end

end

function showTrackerItem(~, itemURI)
cbx = evalin('base', 'cbx');
idstr = regexp(itemURI, '#(?<id>[0-9]*$)', 'tokens', 'once');
id = str2double(idstr{1});
cbx.showItemInBrowser(id);
end

function result = linkTrackerItem(object, bidirect)

try
    cbx = evalin('base', 'cbx');
catch
    errordlg(['UI window must be open first' newline 'opening now!'],'Requirement linking');
    evalin('base', 'cbx=CB_SLREQ_GUI;');
    result = [];
    return;
end
linkdata = cbx.getLinkData;%(cbx.activeItem);
if isempty(linkdata)
    errordlg('No requirement selected','Requirement linking');
    result = [];
    return;
end
result = rmi('createempty');
result.reqsys = linkdata.reqsys;
result.doc = linkdata.doc;
result.id = linkdata.id;
result.description = linkdata.description;

if bidirect
    [objName, ~] = rmi.objname(object);
    url = rmi.getURL(object);
    cbx.access.addAssociation(cbx.getActiveItem.id, url,['ModelLink:' objName]);
end
end


function [depths, paragraphs] = showTrackerItemOutline(trackerURI, itemURI, level)
% Return related contents from the linked tracker item.
% For example, the item name and the item description
% If level > 0 and the item has children, also list the descendants
% up to the specified level
% LOCATION points to a section header, this function should try to
% return the entire header and body text of the subsection.
% ITEMS is a cell array of formatted fragments (tables, paragraphs,
% etc.)  DEPTHS is the corresponding numeric array that describes
% hierarchical relationship among items.
% LEVEL is meant for "details level", not currently used.
% Invoked when generating report.
depths = [];
paragraphs = {};

cbURI = getCodeBeamerURI(trackerURI, itemURI, '/item/');
if ~isempty(cbURI)
    cb = intland.CodeBeamer;

    if strncmp(cbURI, '/item/', 6)
        item = cb.getTrackerItem(cbURI);
        if ~isempty(item)
            itemDesc = cb.getDescription(item);
            if ~isempty(itemDesc) && ~strcmp(itemDesc, '--')
                depths(1) = 0;
                paragraphs{1} = itemDesc;
            end

            if level > 0
                [childLabel, childDepth, childURI] = cb.getTrackerOutline(item.uri, level - 1);
                if ~isempty(childLabel)
                    nextIdx = 1 + length(depths);

                    for index = 1:length(childURI)
                        child = cb.getTrackerItem(getCodeBeamerURI(trackerURI, childURI{index}, '/item/'));
                        if ~isempty(child)
                            depths(nextIdx) = childDepth(index) + 1;                       %#ok<AGROW>
                            paragraphs{nextIdx} = [childURI{index}(2:end) ' ' child.name]; %#ok<AGROW>
                            nextIdx = nextIdx + 1;

                            childDesc = cb.getDescription(child);
                            if ~isempty(childDesc) && ~strcmp(childDesc, '--')
                                depths(nextIdx) = 0;             %#ok<AGROW>
                                paragraphs{nextIdx} = childDesc; %#ok<AGROW>
                                nextIdx = nextIdx + 1;
                            end
                        end
                    end
                end
            end
        end
    else
        tracker = cb.getTracker(cbURI);
        if ~isempty(tracker)
            depths = [0, 1];
            paragraphs = { tracker.project.name, tracker.name };
        end
    end
end
end


