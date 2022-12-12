classdef CodeBeamerSwagger < handle


    properties
        url                    % URL of CodeBeamer (for REST API access)
        urlweb                 % URL of CodeBeamer (for Web access)
        username               % User name

        projects               % List of projects.
        activeProject          % ID of currently selected project.
        activeProjectDetails   % Detailed information for active project

        trackers               % List of trackers in active project.
        activeTracker          % ID of currently selected tracker.
        activeTrackerDetails   % Detailed information for active tracker

        items                  % List of items in active tracker.
    end


    properties (Access=public, Hidden)
        password      % Password
        jsonOptions   % webOptions to access the data
        activeItemTypeIds     % List of item types we are interested in.
    end


    methods
        function this = CodeBeamerSwagger()
            p = getpref('codebeamer');
            this.username= p.username;
            this.password = p.password;
            this.url = p.url;
            this.urlweb = p.urlweb;

            this.jsonOptions = weboptions('Username', this.username, ...
                'Password', this.password, ...
                'CharacterEncoding', 'UTF-8', ...
                'MediaType', 'application/json', ...
                'ContentType', 'json');

            this.activeProject = p.project;
            this.activeTracker = p.tracker;

            this.activeItemTypeIds = p.itemTypes;
        end


        % Declare external functions
        r = createProject(this, name, description, category)
        r = cloneProject(this, name, description, idsrc, category)
        r = copyTrackerToProject(this, trackerId, targetProjectId)
        r = copyTracker(this, srcTrackerId, dstTrackerId);
        r = copyItemTree(this, itemId, dstTrackerId);
        r = recursiveCopy(this, item, parent);

        %% Project access functions
        function readProjectList(this)
            % Read the list of projects from the server
            this.projects = webread([this.url '/rest/v3/projects'], this.jsonOptions);
        end

        function selectProject(this, id)
            % Record the id of active project.
            this.activeProject = id;
            % Read the project's details from the server
            this.activeProjectDetails = webread([this.url '/rest/v3/projects/' num2str(id)], this.jsonOptions);
        end

        function r = existsProject(this, id)
            % Checks whether the project exists
            try
                prj = webread([this.url '/rest/v3/projects/' num2str(id)], this.jsonOptions);
                r = ~isempty(prj);
            catch
                r = false;
            end
        end

        function selectProjectByName(this, name)
            % If project list is empty, read it now.
            if isempty(this.projects)
                this.readProjectList;
            end

            % Find by name
            filter = arrayfun(@(x) string(x.name)==name, this.projects);
            if any(filter)
                % Found:
                prj = this.projects(filter);

                % Record the id of active project.
                this.activeProject = prj.id;
                % Read the project's details from the server
                this.activeProjectDetails = webread([this.url '/rest/v3/projects/' num2str(prj.id)], this.jsonOptions);
                this.readTrackerList;
            else
                % Not found:
                warning('Project not found');
            end
        end


        %% Tracker access functions
        function readTrackerList(this)
            % Read the list of trackers from the server
            this.trackers = webread([this.url '/rest/v3/projects/' num2str(this.activeProject) '/trackers?kind=Category,Tracker&type=' CodeBeamerSwagger.getActiveItemTypeNameList(this.activeItemTypeIds)], this.jsonOptions);
        end

        function selectTracker(this, id)
            % Select a tracker
            this.activeTracker = id;
            this.activeTrackerDetails = webread([this.url '/rest/v3/trackers/' num2str(id)], this.jsonOptions);
        end

        function r = existsTracker(this, id)
            % Checks whether the tracker exists
            try
                trk = webread([this.url '/rest/v3/trackers/' num2str(id)], this.jsonOptions);
                r = ~isempty(trk);
            catch
                r = false;
            end
        end

        function selectTrackerByName(this, name)
            % Read the list of projects from the server
            % If project list is empty, read it now.
            if isempty(this.trackers)
                this.readTrackerList;
            end
            % Find by name
            filter = arrayfun(@(x) string(x.name)==name, this.trackers);
            if any(filter)
                % Found:
                trk = this.trackers(filter);

                this.activeTracker = trk.id;
                this.activeTrackerDetails = webread([this.url '/rest/v3/trackers/' num2str(trk.id)], this.jsonOptions);
                this.readItemList;
            else
                % Not found:
                warning('Project not found');
            end
        end

        %% Item access function
        function readItemList(this)
            % Read the list of items from the server
            id = this.activeTracker;
            this.items = webread([this.url '/rest/v3/trackers/' num2str(id) '/items?pageSize=10000'], this.jsonOptions);
        end

        function details = readItemDetails(this, id)
            % Read the item details from the server
            details = webread([this.url '/rest/v3/items/' num2str(id)], this.jsonOptions);
        end

        %% Comparison function for merge
        function [detailsBase, detailsMain, detailsProject, summary] = readItemDetailsLeft(this, id, base, prj)
            % Read the item details from the server
            detailsMain = webread([this.url '/rest/v3/items/' num2str(id)], this.jsonOptions);
            detailsProject = this.readAssociationIn(id, prj);
            detailsBase = this.readItemDetailsAtBaseline(id, base);

            if isempty(detailsBase)
                summary = 'Added in main';
            else
                if isempty(detailsProject)
                    c_main = Change.compareItems(detailsMain, detailsBase);
                    if isempty(c_main)
                        summary = 'Deleted in project';
                    else
                        summary = 'Changed in main';
                    end

                else
                    c_main = Change.compareItems(detailsMain, detailsBase);
                    c_project = Change.compareItems(detailsMain, detailsProject);
                    if ~isempty(c_main)
                        if ~isempty(c_project)
                            summary = 'Both change';
                        else
                            summary = 'Conflict';
                        end
                    else
                        if ~isempty(c_project)
                            summary = 'Changed in project';
                        else
                            summary = '=';
                        end
                    end
                end
            end
        end

        function [detailsMain, detailsProject, summary] = readItemDetailsRight(this, id, prj)
            % Read the item details from the server
            detailsProject = webread([this.url '/rest/v3/items/' num2str(id)], this.jsonOptions);
            detailsMain = this.readAssociationOut(id, prj);

            if isempty(detailsMain)
                summary = 'Added in project';
            else
                c = Change.compareItems(detailsMain, detailsProject);
                if isempty(c)
                    summary = '=';
                else
                    summary = 'ignoreme';
                end
            end
        end

        function d = readAssociationIn(this, id, prj)
            assoc = webread([this.url '/rest/v3/items/' num2str(id) '/relations'], this.jsonOptions);
            for i=1:numel(assoc.incomingAssociations)
                id = assoc.incomingAssociations(i).itemRevision.id;
                details = webread([this.url '/rest/v3/items/' num2str(id)], this.jsonOptions);
                if details.project.id == prj
                    d = details;
                    return;
                end
            end
            d=[];
        end
        function d = readAssociationOut(this, id, prj)
            assoc = webread([this.url '/rest/item/' num2str(id) '/associations'], this.jsonOptions);
            for i=1:numel(assoc)
                id = assoc(i).to.id;
                details = webread([this.url '/rest/v3/items/' num2str(id)], this.jsonOptions);
                if details.project.id == prj
                    d = details;
                    return;
                end
            end
            d = [];
        end

        function details = readItemDetailsV1(this, id)
            % Read the list of items from the server
            details = webread([this.url '/rest/item/' num2str(id)], this.jsonOptions);
        end

        function details = readItemDetailsAtBaseline(this, id, version)
            % Read the list of items from the server
            try
                details = webread([this.url '/rest/v3/items/' num2str(id) '?version=' num2str(version)], this.jsonOptions);
            catch
                % If the request fails, the baseline did not have that item.
                details = [];
            end
        end

        %% Functions to read associations
        % Swagger function to read associations
        function assoc = readAssociation(this, id)
            assoc = webread([this.url '/rest/v3/items/' num2str(id) '/relations'], this.jsonOptions);
        end

        % REST v1 function to read associations
        function assoc = readAssociationV1(this, id)
            assoc = webread([this.url '/rest/item/' num2str(id) '/associations'], this.jsonOptions);
        end

        function id = addAssociation(this, id, url, description)
            data = struct(...
                'from',        ['/item/' num2str(id)],...
                'url',         url, ...
                'type',        struct('uri', '/association.type/4', 'name', 'related'), ...
                'description', description, ...
                'descFormat', 'Plain');
            r = webwrite([this.url '/rest/association'],data, this.jsonOptions);
            id = str2num(strrep(r.uri, '/association/', '')); %#ok<*ST2NM> 
        end

        function deleteAssociation(this, id)
            deleteOption = this.jsonOptions;
            deleteOption.RequestMethod = 'delete';
            webread([this.url '/rest/association/' num2str(id)], deleteOption);
        end

        %% Function to get list of existing baselines
        function r = readBaseline(this)
            r = webread([this.url '/rest/v3/trackers/' num2str(this.activeTracker) '/baselines'], this.jsonOptions);
        end
        function showBaseline(this)
            r = webread([this.url '/rest/v3/trackers/' num2str(this.activeTracker) '/baselines'], this.jsonOptions);
            names = arrayfun(@(x) string(x.name), r.references);
            disp(names);
        end

        function id = findBaselineByName(this, name)
            list = this.readBaseline();
            filter = arrayfun(@(x) string(x.name)==name,list.references);
            if any(filter)
                b = list.references(filter);
                id = b.id;
            else
                warning('Baseline not found');
            end
        end


        %% Get complete list of item types
        function  r = getItemTypes(this)
            r = webread([this.url '/rest/v3/trackers/types'], this.jsonOptions);
        end


        %% Function to save our preferences.
        function SavetoPreference(this)
            setpref('codebeamer', 'url',      this.url);
            setpref('codebeamer', 'urlweb',   this.urlweb);
            setpref('codebeamer', 'username', this.username);
            setpref('codebeamer', 'password', this.password);
            setpref('codebeamer', 'project',  this.activeProject);
            setpref('codebeamer', 'tracker',  this.activeTracker);
        end

    end

    methods (Static)
        function ShowInCodeBeamer(id)
            % Open a web browser with codebeamer pointing on that item.
            web(['https://cmr-surgical.intland.cloud/x/#/issue/' num2str(id)]);
        end

        function txt = getExplanatoryText(details)
            % Explanatory text (if present)
            if isfield(details, 'explanatoryText')
                txt = details.explanatoryText;
            else
                txt = '';
            end
        end


        function  txt = getActiveItemTypeNameList(itemTypeNames)
            txt = strjoin(arrayfun(@(x) num2str(x), itemTypeNames, 'UniformOutput', false),',');
        end
    end

    methods
        function details = createLinkData(this, node)
            % '59817: Sandbox of trackers / RS-00017v18.0 Versius SWRS Part 6 Joint Controller (JC-SWRS)'
            if ~isempty(node)
                details.doc = [num2str(this.activeProjectDetails.id) '/' num2str(this.activeTrackerDetails.id)];

                details.id = [node.name ' #' num2str(node.id)];
                details.linked =  1;

                % 'RS-017-0309↵If the difference between two successive output position readings indicates a motor speed exceeding 108.5 rad/s~, expressed in OPS units~, the Software shall signal a Joint Controller Fault.←↵←↵Additionally~, if the difference between two successive input position readings on the ERC joint indicates a motor speed exceeding 372 rad/s~, expressed in OPS units~, the Software shall signal a Joint Controller Fault.'
                details.description = this.readItemDetails(node.id).description;

                details.keywords = '';
                details.reqsys = 'intland_codebeamer_rmi';
            else
                details = [];
            end
        end
    end


end
