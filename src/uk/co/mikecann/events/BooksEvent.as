package uk.co.mikecann.events
{
	import flash.events.Event;
	
	import uk.co.mikecann.models.AudioBookModel;
	
	public class BooksEvent extends Event
	{
		public static const PROPERTY_CHANGED : String = "PROPERTY_CHANGED";
		public static const BOOK_BEGIN_DRAG : String = "BOOK_BEGIN_DRAG";
		
		public var book : AudioBookModel;
		
		public function BooksEvent(type:String, book:AudioBookModel=null, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.book = book;
		}
	}
}