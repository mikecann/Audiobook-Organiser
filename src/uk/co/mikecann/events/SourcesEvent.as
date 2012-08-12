package uk.co.mikecann.events
{
	import flash.events.Event;
	
	public class SourcesEvent extends Event
	{
		public static const ADD : String = "addSource";
		public static const REMOVE : String = "removeSource";
		public static const CHANGED : String = "sourcesChanged";
		
		public var sourceFolder : String;
				
		public function SourcesEvent(type:String, sourceFolderStr:String="", bubbles:Boolean=true, cancelable:Boolean=false)
		{			
			sourceFolder = sourceFolderStr;			
			super(type, bubbles, cancelable);
		}
	}
}