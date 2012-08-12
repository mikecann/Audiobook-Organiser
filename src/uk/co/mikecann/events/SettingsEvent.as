package uk.co.mikecann.events
{
	import flash.events.Event;
	
	public class SettingsEvent extends Event
	{
		public static const CLEAR_DATA : String = "clearAllSettingsData";
		public static const BROWSE_FOR_DATABASE_LOCATION : String = "BROWSE_FOR_DATABASE_LOCATION";
		public static const IMPORT_DATABASE_FILE : String = "IMPORT_DATABASE_FILE";		
		
		public function SettingsEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}