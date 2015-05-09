import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.array;

void main( string[] args ){
	/// <uml.activity>

	// one argument is required
	if( args.length < 2 ){
		writeln("Usage parameters: <filename>");
		return;
	}

	// initialise
	char[] fileContent = null;

	/// <uml.action text="Read the content of file"/>
	try{
		// read the file content
		fileContent = cast(char[])std.file.read( args[1] );
	}
	catch( Exception ex ){
		// failed
		writeln("Cannot read the file `", args[1], "`");
		return;
	}

	/// <uml.action text="Split the content of file into lines"/>
	// split the file content into lines
	auto fileLines = std.string.splitLines( fileContent );

	// xml content
	auto xmlContent = std.array.appender!string();

	// one file can have multiple UMLs. xml should have a complete body
	xmlContent.put("<uml.container>");

	/// <uml.action text="Collect the UML lines of file content"/>
	// get xml lines
	foreach(fileLine; fileLines){
		// trim the line in case it starts with tabs or spaces
		fileLine = std.string.strip( fileLine );

		// line should start with "///"
		if( fileLine.length < 3 ) continue;
		if( (fileLine[0] != '/') || (fileLine[1] != '/') || (fileLine[2] != '/') ) continue;

		// skip the first three bytes
		fileLine = fileLine[3 .. $];

		// trim left side in case there were spaces after "///"
		fileLine = std.string.stripLeft( fileLine );

		// lower case conversion
		auto fileLineLower = std.uni.toLower( fileLine );

		// line should start with either "<uml" or "</uml" to be an xml line
		if( std.algorithm.startsWith( fileLineLower, "<uml" ) || std.algorithm.startsWith( fileLineLower, "</uml" ) )
			xmlContent.put( fileLine );
	}

	// finalise xml container
	xmlContent.put("</uml.container>");

	/// <uml.action text="Create an XML document in memory with collected UML lines"/>
	// create an xml file. this object is the container
	auto xml = new std.xml.Document( xmlContent.data );

	/// <uml.action text="Process elements of XML to generate UML diagrams in HTML format"/>
	// check each element
	foreach(element; xml.elements){
		// get the tag name lower case
		auto tagNameLower = std.uni.toLower( element.tag.name );

		// switch with name
		switch( tagNameLower ){
			case "uml.activity": umlActivity( element ); break;
			default: writeln("[Warning] Unknown tag `", element.tag.name, "`");
		}
	}

	/// </uml.activity>
}

void umlActivity( std.xml.Element containerElement ){
	// create file content
	auto fileContent = std.array.appender!string();

	// initialise HTML5
	fileContent.put("<!doctype html>");
	fileContent.put("<html>");

	// head content
	fileContent.put("<head>");
	fileContent.put("<meta charset=\"utf-8\"/>");
	fileContent.put("<title>Activity Diagram</title>");
	fileContent.put("</head>");

	// styling
	fileContent.put("<style>");
	fileContent.put(".pane{ width: 320px; float: left; text-align: center }");
	fileContent.put(".activity.start{ display: inline-block; width: 48px; height: 48px; border-radius: 50%; background: black; line-height: 0px }");	
	fileContent.put(".activity.stop{ display: inline-block; width: 46px; height: 46px; border-radius: 50%; background: black; border: solid 2px white; box-shadow: 0px 0px 0px 2px black; }");	
	fileContent.put(".activity.action{ display: inline-block; border: solid 1px black; border-radius: 15px; padding: 15px; cursor: default }");	
	fileContent.put(".activity.vline{ display: inline-block; background: black; width: 3px; height: 30px; margin: 0px; padding: 0px }");
	fileContent.put(".activity.downarrow{ display: inline-block; line-height: 0px; width: 0; height: 0; border-left: 8px solid transparent; border-right: 8px solid transparent; border-top: 16px solid black; }");
	fileContent.put("</style>");

	// body starts here
	fileContent.put("<body>");

	// panes for structure
	fileContent.put("<div class=\"pane\">");

	// start item
	fileContent.put("<div class=\"activity start\" data-element=\"start\">&nbsp;</div>");

	// add vertical line and down arrow
	fileContent.put("<div style=\"line-height: 0px\"><div class=\"activity vline\">&nbsp;</div></div>");
	fileContent.put("<div style=\"line-height: 0px\"><div class=\"activity downarrow\">&nbsp;</div></div>");

	// check each element
	foreach(element; containerElement.elements){
		// get the tag name lower case
		auto tagNameLower = std.uni.toLower( element.tag.name );

		// switch with name
		switch( tagNameLower ){
			case "uml.activity": umlActivity( element ); break;
			case "uml.state": umlActivityState( &fileContent, element ); break;
			case "uml.action": umlActivityAction( &fileContent, element ); break;
			default: writeln("[Warning] Unknown tag `", element.tag.name, "`");
		}
	}

	// stop item
	fileContent.put("<div class=\"activity stop\" data-element=\"stop\">&nbsp;</div>");

	// end of pane
	fileContent.put("</div>");

	// finalise HTML5
	fileContent.put("</body>");
	fileContent.put("</html>");

	// save to file
	try{ std.file.mkdir("output"); } catch( Exception ex ){}
	std.file.write( "output/activity.html", fileContent.data );
}

void umlActivityState( std.array.Appender!(string)* fileContent, std.xml.Element containerElement ){
}

void umlActivityAction( std.array.Appender!(string)* fileContent, std.xml.Element containerElement ){
	// get id and text
	auto id = ("id" in containerElement.tag.attr) ? containerElement.tag.attr["id"] : null;
	auto text = ("text" in containerElement.tag.attr) ? containerElement.tag.attr["text"] : null;

	// text must be found
	if( text is null ){
		writeln("[Warning] `text` attribute is not found on action element");
		return;
	}

	// start the item
	fileContent.put("<div><div class=\"activity action\" data-element=\"action\"");

	// if id is available, append it
	if( id !is null ){
		fileContent.put(" data-element-id=\"");
		fileContent.put( id );
		fileContent.put("\"");
	}

	// put the text
	fileContent.put(">");
	fileContent.put( text );
	fileContent.put("</div></div>");

	// add vertical line and down arrow
	fileContent.put("<div style=\"line-height: 0px\"><div class=\"activity vline\">&nbsp;</div></div>");
	fileContent.put("<div style=\"line-height: 0px\"><div class=\"activity downarrow\">&nbsp;</div></div>");
}
