# TerryWhiteChemmart

A table in data warehouse will provide the list of all order templates and their assignment to particular stores. The refresh of the dataset will be controlled by ADF which will trigger the need to refresh data in the Integration platform. Once triggered the Integration platform will push down individual store templates for each store to the Store Agent. Store templates will be keyed on the name of the template.
The store agent will then use the MINFOS API to obtain the existing template that matches the name of the master template. If any differences are identified, then the Agent should call the MINFOS API and update the named template.
Each master template will include a status, which may be set to ‘Active’ or ‘Deleted’. If the template is identified as deleted, then the store Agent should simply delete the named Order Template from the store.
