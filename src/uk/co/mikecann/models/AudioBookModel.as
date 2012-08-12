package uk.co.mikecann.models
{
	public class AudioBookModel
	{		
		[Bindable] public var name : String;
		[Bindable] public var listened : Boolean;
		[Bindable] public var rating : int;		
		[Bindable] public var url : String;		
	}
}