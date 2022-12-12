# Requirement Management Interface Add-On for MATLAB Simulink Requirements
The [documentation](https://codebeamer.com/cb/wiki/985723) and [installation files](https://codebeamer.com/cb/doc/985736/content?raw=true&link_id=8910613) are currently hosted on https://codebeamer.com/cb/project/1005.

# [CMR, Sylvain Sauvage]
Added the ability to have bidirectional links.
Links in codebeamer are now stored in association url and cause MATLAB to highlight briefly the linked component.

# [CMR, Sylvain Sauvage]
Replace the figure based UI with a AppDesigner based UI.
The new UI shos the tracker content in a hierarchy view. The description and rationale are visible in the interface.
Limitation: This is a prototype and not thoroughly tested.
Limitation: It does not read more than 500 items.
Limitation: The UI assumes a fairly default set of fields and may report errors for missing fields. Please customise to your needs.

To use: 
  Setup: Run cbx=CB_SLREQ_GUI; to open the UI first, fill credentials
  Linking: Select a project, tracker and item. In Simulink model right click on component and choose "Requirement" / "Link to Codebeamer Item"
