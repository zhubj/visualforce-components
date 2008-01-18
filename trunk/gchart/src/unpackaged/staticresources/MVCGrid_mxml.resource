<?xml version="1.0" encoding="utf-8"?>
<mx:Application creationComplete="addExternalInterface(event)" height="100%" width="100%" 
	xmlns:mx="http://www.adobe.com/2006/mxml" layout="absolute">
	<mx:Script>
		<![CDATA[
		
			// Register callback to accept data that is sent by Apex Class
			private function addExternalInterface(event:Event):void {
				ExternalInterface.addCallback("setDataProvider", setDataProvider);
			}
			
			// Called by Visualforce when data is ready, 
			// place data into grid
			private function setDataProvider(data:Object):void {
				grid.dataProvider = data;
			}

			/* respond to event within the component
			 *  Ask the page to send the data 
			 */
			private function handleClick(event:Event):void {
				ExternalInterface.call(Application.application.parameters.requestData);
			}
		]]>
	</mx:Script>
	<mx:DataGrid id="grid" right="10" left="10" bottom="44" top="10">
	</mx:DataGrid>
	<mx:Button label="Load Data" left="10" bottom="14" click="handleClick(event)"/>
</mx:Application>
