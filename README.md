# VistALink Native Multi-threaded Support for GT.M

Created by Sam Habiel, who wants a rich wife, on January 18th 2015.

This KID build allows you to initiate a multi-threaded listener for GT.M
like you can do in VistALink on Cache.

The install is just a regular KIDS build install.

Here's an example of how to invoke the listener:

	GTM>D ^XUP

	Setting up programmer environment
	This is a TEST account.

	Terminal Type set to: C-VT320

	Select OPTION NAME: XOBU SITE SETUP MENU

	Foundations Manager :: Main   Jan 18, 2015@23:41:32          Page:    0 of    0 
						<<<      VistALink Parameters     >>>

		VistALink Version: 1.6    Heartbeat Rate: 180    Latency Delta: 180

						<<< VistALink Listener Status Log >>>
	  ID  Box-Volume        Port   Status       Status Date/Time    Configuration   












			  Enter ?? for more actions                                             
	SP  Site Parameters                                          SL  Start Listener
	CFG Manage Configurations                                    STP Stop Listener
	CP  Enter/Edit Connector Proxy User                          SB  Start Box
	RE  Refresh                                                  CU  Clean Up Log
	CM  Connection Manager
	Select Action:Quit// SL Start Listener
	
	ENTER PORT: 8000// 8022
	
    ...snip...

	                    <<<      VistALink Parameters     >>>

    VistALink Version: 1.6    Heartbeat Rate: 180    Latency Delta: 180

                    <<< VistALink Listener Status Log >>>
    ID  Box-Volume        Port   Status       Status Date/Time    Configuration   
    1   ICARUS:icarus     8022   STARTING     JAN 18, 2015@23:45                                                                        
	...snip...

	Select Action:Quit// RE Refresh

	...snip...

	                    <<<      VistALink Parameters     >>>

    VistALink Version: 1.6    Heartbeat Rate: 180    Latency Delta: 180

                    <<< VistALink Listener Status Log >>>
    ID  Box-Volume        Port   Status       Status Date/Time    Configuration   
    1   ICARUS:icarus     8022   RUNNING      JAN 18, 2015@23:45                                                                        
## Acknowledgements
I would like to especially thank Lloyd Milligan who wrote the original 
iteration of this code for VistALink 1.5. Besides porting his changes to 1.6,
I added support for the Listman XOBU Starter, and used the new GT.M socket
passage between jobs.

## License
Placed into the public domain (see LICENSE for more details.)
