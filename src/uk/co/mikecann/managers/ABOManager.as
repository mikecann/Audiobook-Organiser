package uk.co.mikecann.managers
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import uk.co.mikecann.consts.Consts;
	import uk.co.mikecann.events.SourcesEvent;
	import uk.co.mikecann.models.AudioBookModel;

	public class ABOManager
	{	
		private static const SETTINGS_URL : String = File.applicationStorageDirectory.url+"settings.dat";
		
		// Publics
		[Bindable] public var sources : ArrayCollection;
		[Bindable] public var books : ArrayCollection;	
		[Bindable] public var databaseFileLocation : String;		
		
		// Privates
		private var _dispatcher : IEventDispatcher;
		private var _bookLibrary : Array;
		
		public function ABOManager(d:IEventDispatcher)
		{
			_dispatcher = d;
			sources = new ArrayCollection();
			books = new ArrayCollection();
			loadSettings();
			loadPersistantData();
		}			
		
		public function addSource() : void
		{
			var file:File = new File(); 
			file.addEventListener(Event.SELECT, onDirSelected); 
			file.browseForDirectory("Select a directory"); 					
		}
		
		private function loadSettings() : void
		{
			var s : String = SETTINGS_URL;
			var f : File = new File(s);
			var fileStream:FileStream; 
			var o : Object;
			
			if (f.exists) 
			{
				// Read the object bugger		
				fileStream = new FileStream();
				fileStream.open(f, FileMode.READ); 
				o = fileStream.readObject();
				fileStream.close();
				
				databaseFileLocation = o.databaseFileLocation;
			} 
			else
			{
				var defaultLoc : String = File.applicationStorageDirectory.url+"data.dat";
				
				// Make obj
				o = {databaseFileLocation:defaultLoc};		
				
				// Write to the bugger
				fileStream = new FileStream(); 
				fileStream.open(f, FileMode.WRITE); 
				fileStream.writeObject(o);
				fileStream.close();
				
				databaseFileLocation = defaultLoc;
			}
		}
		
		private function onDirSelected(e:Event) : void
		{
			sources.addItem(File(e.target).nativePath); 
			_dispatcher.dispatchEvent(new SourcesEvent(SourcesEvent.CHANGED));
			saveBooklist();
		}
		
		public function removeSource(src:String) : void
		{
			var indx : int = sources.getItemIndex(src);
			if (indx<0){return;}
			sources.removeItemAt(indx);				
			_dispatcher.dispatchEvent(new SourcesEvent(SourcesEvent.CHANGED));
		}
		
		public function rebuildBookList() : void
		{
			// empty list
			books.removeAll();
			
			// loop through all sources rebuilding list
			for(var i:int=0; i<sources.length; i++)
			{
				var dir:File = new File(sources[i]);
				if (!dir.exists){continue;}			
				dir.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirList); 
				dir.getDirectoryListingAsync(); 				
			}
		}
		
		public function bookBeginDrag(book:AudioBookModel) : void
		{
			trace(book);
			var cp : Clipboard = new Clipboard();
			cp.setData(ClipboardFormats.FILE_LIST_FORMAT, [new File(book.url)], false);
			NativeDragManager.doDrag(null,cp);
		}		
		
		public function browseForNewDatabaseLocation() : void
		{
			var f : Function = function(event:Event) : void
			{
				var file:File = File(event.target);
				databaseFileLocation = file.url;
				saveBooklist();
				saveSettings();
			}
			
			var file:File = new File(databaseFileLocation); 
			file.addEventListener(Event.SELECT, f); 
			file.browseForSave("New location for database file");				
		}
		
		public function importDatabaseFile() : void
		{
			var alertCloseFunc : Function = function(e:CloseEvent) : void
			{	 
				// Jump out now
				if (e.detail==Alert.CANCEL){ return; }
				
				// Else do the import
				var fileBrowseCloseFunc : Function = function(event:Event) : void
				{
					var file:File = File(event.target);
					databaseFileLocation = file.url;
					loadPersistantData();
					saveSettings();
				};		
				
				var file:File = new File(databaseFileLocation); 
				file.addEventListener(Event.SELECT, fileBrowseCloseFunc); 
				file.browseForOpen("Import existing database");					
			}
				
			Alert.show("Warning this will erase all current audiobooks from your library. Are you sure you want to do this?", 
				"Import Warning", 
				Alert.YES | Alert.CANCEL, 
				null, 
				alertCloseFunc);
		}	
		
		private function saveSettings() : void
		{
			var o : Object = {databaseFileLocation:databaseFileLocation};		
			
			// Write to the bugger
			var fileStream : FileStream = new FileStream(); 
			fileStream.open(new File(SETTINGS_URL), FileMode.WRITE); 
			fileStream.writeObject(o);
			fileStream.close();
		}
		
		private function onDirList(event:FileListEvent) : void
		{
			var contents:Array = event.files; 
			for (var i:uint = 0; i < contents.length; i++)  
			{ 
				var f  : File = contents[i];
				if (!f.isDirectory){continue;} // only interested in directories				
				
				var libabm : AudioBookModel = checkLibraryForBook(contents[i].name);
				if (libabm==null)
				{				
					var abm : AudioBookModel = new AudioBookModel();
					abm.name = f.name;
					abm.listened = false;
					abm.rating = 0;
					abm.url = f.url;
					books.addItem(abm);
				}
				else
				{
					libabm.url = f.url;
					books.addItem(libabm);
				}			
			} 
		}
		
		private function checkLibraryForBook(bookName:String) : AudioBookModel
		{
			for(var i:int=0; i<_bookLibrary.length; i++)
			{
				var abm : AudioBookModel = AudioBookModel(_bookLibrary[i]);
				if (abm.name==bookName){ return abm; }
			}
			return null;
		}
		
		public function loadPersistantData() : void
		{
			// First things first
			_bookLibrary = [];			
			
			// Try to get data file
			var data : File = new File(databaseFileLocation);			
			
			// If the file doesnt exist get the hell out
			if (!data.exists){ return; }
			
			// Read the object bugger
			var fileStream:FileStream = new FileStream(); 
			fileStream.open(data, FileMode.READ); 
			var o : Object = fileStream.readObject();
			fileStream.close();			
								
			// for all the books in the saved data
			for(var i:int=0; i<o.books.length; i++)
			{
				var abm : AudioBookModel = new AudioBookModel();
				abm.listened = o.books[i].listened;
				abm.name = o.books[i].name;
				abm.rating = o.books[i].rating;
				abm.url = o.books[i].url;
				_bookLibrary.push(abm);
			}
			
			// grab the sources
			sources = new ArrayCollection(o.sources);
			rebuildBookList();
		}
		
		public function saveBooklist() : void
		{					
			var data : File = new File(databaseFileLocation);
			
			// Remove the file if its there we are gonna fill it
			if (data.exists){ data.deleteFile(); }
			
			// Write data to string
			var o : Object = {};
			o.version = Consts.VERSION;
			o.books = books.toArray();
			o.sources = sources.toArray();			
			
			// Write to the bugger
			var fileStream:FileStream = new FileStream(); 
			fileStream.open(data, FileMode.WRITE); 
			fileStream.writeObject(o);
			fileStream.close();
		}
		
		public function resetAll() : void
		{
			// Delte the data file
			var data : File = new File(databaseFileLocation);		
			if (data.exists){ data.deleteFile(); }
			
			// Empty all lists
			_bookLibrary = [];		
			sources.removeAll();
			books.removeAll();
		}
	}
}