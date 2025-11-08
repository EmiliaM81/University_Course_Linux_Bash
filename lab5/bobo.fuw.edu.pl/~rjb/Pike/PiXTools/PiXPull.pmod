//! A streaming XML parser that implements an API not unlike that described
//! at @url{http://xmlpull.org/@}.
//!
//! Author: rjb @url{http://bobo.fuw.edu.pl/~rjb/@}
//!
//! Pre-alpha, 2003-05-26

//! @ignore
#pragma strict_types
#undef assert
#ifdef NDEBUG
#define assert(X) 1
#else
#define static
#define assert(X) ((X) ? 1 : (error( "Assertion failed: " #X "\n" ), 0) )
#endif
#define XPerror(S, X ...) error( (S) + sprintf( "at offset %d\n", offset ), X )

#if !constant(Locale.Charset.Encoder)
#if constant(Locale.Charset.encoder)
//constant Encoder = Locale.Charset.ascii;
class Encoder
{
    this_program feed( string );
    string drain();
    this_program clear();
    void set_replacement_callback( function(string:string) );
}
#else
#error Neither Locale.Charset.Encoder nor Locale.Charset.encoder\
 are known to be defined.
#endif
#else
constant Encoder = Locale.Charset.Encoder;
#endif

#if __VERSION__ < 7.4
#define this this_object()
#endif

// '&' is '\x26', '<' is '\x3c'
#define CHAR_F "\x9""\xa""\xd""\x20-\xd7ff""\xe000-\xfffd""\x10000-\x10ffff"
#define TEXT_F "\x9""\xa""\xd""\x20-\x25""\x27-\x3b""\x3d-\xd7ff""\xe000-\xfffd""\x10000-\x10ffff"

// FIXME: offset tracking is WRONG!! .. No more?

//! Used to describe a XML syntactic unit detected by the Parser.
//! @constant START_DOCUMENT
//! setInput was called successfully, but no input has yet been read.
//! @constant START_TAG
//! A start tag, or a minimized empty tag, like <tag/>.
//! @constant END_TAG
//! A close tag was read (</tag>), or the Parser was advanced a step
//! after reading a minimized empty tag (<tag/>).
//! This behavior is such that reading <tag/> and <tag><tag/>
//! results in the same sequence of parsing events.
//! @constant TEXT
//! A section of character data.
//! @constant ENTITY_REF
//! An entity reference, or numeric character reference.
//! @constant CDSECT
//! A CDATA section.
//! @constant COMMENT
//! A comment.
//! @constant DOCDECL
//! A DOCTYPE declaration.
//! @constant IGNORABLE_WHITESPACE
//! Whitespace that is outside the root element tag.
//! @constant PROCESSING_INSTRUCTION
//! A processing instruction: <?...?>.
//! @constant END_DOCUMENT
//! End of the datastream was reached (with no errors).
//! @constant PARSE_ERROR
//! The Parser is in this state after encountering a non-recoverable
//! error. This event type can only be returned from getEventType
//! if the original error was caught by the caller.
enum Event
{
    PARSE_ERROR = -8,
    END_DOCUMENT = -1,  // seen by next()
    START_DOCUMENT = 1,
    START_TAG, // seen by next()
    END_TAG, // seen by next()
    TEXT,  // seen by next()
    ENTITY_REF, // merged into TEXT and resolved by next()
    CDSECT,  // merged into TEXT by next()
    COMMENT,
    DOCDECL,
    IGNORABLE_WHITESPACE,
    PROCESSING_INSTRUCTION
}
//! @endignore

//! Maps the Event constants back into their symbolic names.
constant TYPES =
([
    START_DOCUMENT : "START_DOCUMENT",
    DOCDECL : "DOCDECL",
    START_TAG : "START_TAG",
    TEXT : "TEXT",
    END_TAG : "END_TAG",
    CDSECT : "CDSECT",
    COMMENT : "COMMENT",
    ENTITY_REF : "ENTITY_REF",
    IGNORABLE_WHITESPACE : "IGNORABLE_WHITESPACE",
    PROCESSING_INSTRUCTION : "PROCESSING_INSTRUCTION",
    END_DOCUMENT : "END_DOCUMENT",
    PARSE_ERROR : "PARSE_ERROR"  // not used yet
]);

//! A mapping of the predefined XML entity names to their character equivalents.
constant standard_entities = ([ "gt":">", "lt":"<", "amp":"&", "apos":"'", "quot":"\"" ]);

//! A Lexer object transforms the input bytestream into
//! a sequence of "coarse syntactic units"
//! of XML (tag, comment, text section, PI, CDATA section, entity reference, DOCTYPE
//! section) but does not scan the content of those units any more than
//! needed to identify them, and perhaps check some well-formedness constraints
//! (proper characters in content).
class Lexer
{
    static
    {
        Stdio.Stream stream;
        constant CHUNK = 512;
        int chunk = 1;
        int offset;
        string buffer;
        string current;
        string encoding;
        Locale.Charset.ascii decoder;
        function(string:string) decode;
        int(0..1) at_eof;

        function(int:int(0..1)) isFirstNameChar =
            [function(int:int(0..1))]spider.isfirstnamechar;
        function(int:int(0..1)) isNameChar =
            [function(int:int(0..1))]spider.isnamechar;
    }

//! Set the size of the read buffer.
//! @param size
//! The desired size, in characters.
//! If void (or zero), will be set to a reasonable default.
    void set_buffer( int|void size )
    {
        chunk = (int)size || CHUNK;
        ( chunk < 1 ) && ( chunk = 1 );
    }

//! Add more data from the input stream to the read buffer.
//! @returns
//! 1 if successful, 0 if there is no data left to read.
    static int(0..1) feed_buffer()
    {
        if ( at_eof ) return 0;
        string s = stream->read( chunk );
        if ( s && sizeof( s ) ) // workaround a bug (?) in Stdio.FakeFile
            buffer += decode( s );
        else
        {
            at_eof = 1;
            return 0; // no more to read
        }
        return 1;
    }

//! Fetch some data from the read buffer, without removing it.
//! @param len
//! Number of characters to fetch.
//! If void or zero, will default to one character.
//! @returns
//! For nonzero @tt{len@}: a string of at most len characters;
//! for @tt{len@} zero or void: an int
//! (character code), or -1 if the buffer is empty and no data
//! is left to read.
    string|int peek( void|int(0..) len )
    {
        //if ( !len )
        //    return sizeof( buffer ) ? buffer[0] : -1;
        while( ( sizeof( buffer ) < ( len || 1 ) ) &&
                        feed_buffer() );
        return
            len ?
                buffer[..len-1] :
                    ( sizeof( buffer ) ? buffer[0] : -1 );
    }

//! Get the next XML syntactic unit.
//! @returns
//! A string of data forming said unit, or UNDEFINED
//! in case the input has been exhausted and the read buffer is empty.
//! @throws
//! In case of unrecoverable parse error (illegal characters,
//! unexpected end of input in the middle of a token, etc.).
    string next()
    {
        current = UNDEFINED;
        if ( !sizeof( buffer ) && !feed_buffer() )
            return current;
        string rest;
        if ( buffer[0] == '&' )
        {
            while ( !sscanf( buffer, "%s;%s", current, rest ) && feed_buffer() );
            rest ||
                XPerror( "next: unexpected end of input following '&'.\n" );
            current += ";";
        }
        else if ( buffer[0] == '<' )
        {
            while ( search( buffer, '>' ) == -1 )
                feed_buffer() ||
                    XPerror( "next: unexpected end of input following '<'.\n" );
            if ( isFirstNameChar( buffer[1] ) || buffer[1] == '/' )
            {
                sscanf( buffer, "%s>%s", current, rest ); // the '>' was found already
                current += ">";
            }
            else if ( buffer[1] == '?' )
            {
                //int pos;
                //while ( ( pos = search( buffer, "?>" ) ) == -1 )
                //    feed_buffer() ||
                //        XPerror( "next: unexpected end of input following \"<?\".\n" );
                //current = buffer[..pos+1];
                //rest = buffer[pos+2..];
                while ( !sscanf( buffer, "%s?>%s", current, rest ) && feed_buffer() );
                rest ||
                    XPerror( "next: unexpected end of input following \"<?\".\n" );
                sscanf( current, "%*["CHAR_F"]%s", string junk );
                sizeof( junk ) &&
                    XPerror( "next: illegal non-character 0x%x following \"<?\" "
                             "at offset %d.",
                             junk[0], offset + sizeof( current ) - sizeof( junk ) );
                current += "?>";
            }
            else if ( buffer[1] == '!' )
            {
                if ( buffer[..3] == "<!--" )
                {
                    //int pos;
                    //while ( ( pos = search( buffer, "--", 4 ) ) == -1 )
                    //    feed_buffer() ||
                    //        XPerror( "next: unexpected end of input following \"<!--\".\n" );
                    //current = buffer[..pos+2];
                    //rest = buffer[pos+3..];
                    while ( !sscanf( buffer, "<!--%s-->%s", current, rest ) && feed_buffer() );
                    current ||
                        XPerror( "next: unexpected end of input following \"<!--\".\n" );
                    //( search( current[4..], "--" ) == -1 ) ||
                    //    XPerror( "next: improper termination following \"<!--\": %O.\n",
                    //                 "--" + ( current[4..]/"--" )[1][..3] );
                    current = sprintf( "<!--%s-->", current );
                }
                else if ( buffer[..8] == "<!DOCTYPE" )
                {
                    // FIXME: this is _not_ correct, even if it works most of the time...
                    int nesting = 1;
                    current = "<";
                    //rest = buffer;
                    string tmp;
                    while ( nesting )
                    {
                        sscanf( buffer[sizeof(current)..], "%[^<>'\"]%s", tmp, rest );
                        if( !sizeof( rest ) )
                        {
                            feed_buffer() ||
                                XPerror( "next: unexpected end of input following \"<!DOCTYPE\".\n" );
                            continue;
                        }
                        current += tmp + rest[0..0];
                        switch ( rest[0] )
                        {
                        case '<': ++nesting; break;
                        case '>': --nesting; break;
                        case '\'':
                            tmp = rest = "";
                            do
                                sscanf( buffer[sizeof(current)..], "%[^']%s", tmp, rest );
                            while ( !sizeof( rest ) && feed_buffer() );
                            sizeof( rest ) ||
                                XPerror( "next: unexpected end of input reading DOCTYPE.\n" );
                            current += tmp + rest[0..0];
                            break;
                        case '"':
                            tmp = rest = "";
                            do
                                sscanf( buffer[sizeof(current)..], "%[^\"]%s", tmp, rest );
                            while ( !sizeof( rest ) && feed_buffer() );
                            sizeof( rest ) ||
                                XPerror( "next: unexpected end of input reading DOCTYPE.\n" );
                            current += tmp + rest[0..0];
                            break;
                        default: XPerror( "next: internal error parsing DOCTYPE!\n" );
                        }
                        //current += tmp + rest[0..0];
                    }
                    rest = buffer[sizeof(current)..];
                }
                else if ( buffer[..8] == "<![CDATA[" )
                {
                    while( !sscanf( buffer, "%s]]>%s", current, rest ) &&
                                feed_buffer() );
                    rest ||
                        XPerror( "next: unexpected end of input following \"<![CDATA[\".\n" );
                    current += "]]>";
                }
                else
                {
                    XPerror( "next: illegal content following \"<!\": %O.\n", buffer[2..8] );
                }
            }
            else
            {
                XPerror( "next: illegal character following '<': 0x%x.\n", buffer[1] );
            }
        }
        else // character data
        {
            do
                sscanf( buffer,
                        "%["TEXT_F"]%s",
                        current, rest );
            while ( !sizeof( rest ) && feed_buffer() );
            sizeof( rest ) &&
                rest[0] != '<' &&
                    rest[0] != '&' &&
                        XPerror( "next: illegal non-character 0x%x in character data "
                                 "at offset %d.\n", rest[0], offset + sizeof( current ) );
        }

        offset += sizeof( current );
        buffer = rest;
        // werror( "offset: %d; buffer: %O...\n", offset, buffer[..63] );  // DEBUG

        return current;
    }

//! Create a Lexer instance.
//! @param _stream
//! The input stream. Should be open for reading.
//! @param _enc
//! The input encoding.
//! @note
//! If no input encoding is provided, the input bytestream
//! will not be decoded, @i{and the input buffer size will be
//! set to 1@}. This is typically useful when attempting to
//! guess the encoding on the basis of the first few bytes of data.
//!
//! Conversely, if an encoding is provided, input will be decoded,
//! and the buffer and strings returned by next() should be
//! expected to be wide strings.
//! @throws
//! An error will be thrown if the encoding name is not recognized
//! by Pike.
    static void create( Stdio.Stream _stream, void|string _enc )
    {
        stream = _stream;
        if ( !_enc )
        {
            //decoder = Locale.Charset.decoder( "utf8" );
            set_buffer(1);
        }
        else
        {
            encoding = _enc;
            decoder = Locale.Charset.decoder( encoding );
            set_buffer();
        }
        if ( decoder )
        {
            decode = [function(string:string)]lambda( string s )
                        {  return decoder->feed(s)->drain(); };
        }
        else
        {
            decode = lambda( string s ) { return s; };
        }
        buffer = "";
        offset = 0;
    }

//! Set the input encoding.
//! @note
//! The input buffer will be erased.
    static void setEncoding( string _enc )
    {
        buffer = ""; // enforce emptying buffer before setEncoding()
        encoding = _enc;
        decoder = Locale.Charset.decoder( _enc );
        decode = [function(string:string)]lambda( string s )
                        {  return decoder->feed(s)->drain(); };
    }

} // class Lexer

#define XPPerror( X... ) ( ( current_event = PARSE_ERROR ), XPerror( X ) )

//! The basic (non-validating, non-namespace-enabled) XML pull parser.
class Parser
{
    inherit Lexer : lexer;
    //static string encoding;
    static Event current_event;
    static string root_tag_name;
    static ADT.Stack tagstack;
    static array(array(string)) current_attributes;
    static mapping(string:string) entities =
        [mapping(string:string)]standard_entities; // TEMPORARY!!!

//! Must be called before the Parser can be used.
//! Also resets the Parser state so that it can begin reading a new input stream.
//! @param _stream
//! The input stream. Must be open for reading, and positioned at the start
//! of XML data.
//! @param _encoding
//! The input encoding. If void (not given), the Parser will attempt to guess.
//! If given, it will be honored and any encoding declaration present in the
//! xml header will be ignored.
//!
//! Guessing currently won't work for UCS-4 and related (4 byte wide) encodings.
//! @note
//! The Parser will only read() from the input stream; it is the caller's responsibility
//! to close and/or destruct this stream after parsing is complete.
    this_program setInput( Stdio.Stream _stream, void|string _encoding )
    {
        //depth = 0;
        tagstack = ADT.Stack();
        root_tag_name && ( root_tag_name = UNDEFINED ); // if set, reset
        //encoding && ( encoding = UNDEFINED ); // if set, reset
        //_encoding && ( encoding = _encoding ); // if given, must be honored
        lexer::create( _stream, _encoding );
        current_event = START_DOCUMENT;
        return this;
    }

    string getInputEncoding()
    {
        return lexer::encoding;
    }

    static Event init_parse()
    // parse and skip xmldecl, if any
    // return first event (whitespace, start tag, doctype, comment, PI)
    // try to detect encoding if not set at setInput()
    {
        if ( lexer::encoding )
        {
            mixed err = catch { lexer::next(); };
            if ( err )
            {
                current_event = PARSE_ERROR;
                throw( @(array)err );
            }
            lexer::current ||
                XPPerror( "init_parse: failed to read any input!\n" );
            //werror( "In init_parse: Lexer returned: %O.\n", lexer::current ); // DEBUG
            //werror( "lexer::buffer : %O.\n", lexer::buffer ); // DEBUG
            switch ( lexer::current[0] )
            {
            case '\xfeff': case '\xfffe': // Byte-Order Mark... can it appear here? discard and carry on...
                lexer::current = lexer::current[1..];
                isWhitespace() ||
                    XPPerror( "init_parse: disallowed content at toplevel: %O...\n", lexer::current[..8] );
                return init_parse();
            case '<':       // <?xml, <?whatever, <!--, <!DOCTYPE, <tag
                switch ( lexer::current[1] )
                {
                case '?':
                    if ( ( lexer::current[..4] == "<?xml" ) &&
                            (< ' ', '\t', '\n', '\r', '?' >)[lexer::current[5]] )
                    { // FIXME: do more checks?
                        return init_parse(); // skip and carry on
                    }
                    else
                    {
                        return current_event = PROCESSING_INSTRUCTION;
                    }
                case '!':
                    switch ( lexer::current[2] )
                    {
                    case '-':
                        return current_event = COMMENT;
                    case 'D':
                        return current_event = DOCDECL;
                    case '[':
                        XPPerror( "init_parse: disallowed content at toplevel (CDATA?): %O...\n",
                                    lexer::current[..8] );
                    default:
                        XPPerror( "init_parse: ooops, Lexer failure: %O...\n", lexer::current[..8] );
                    }
                default:
                    ( lexer::current[1] == '/' ) &&
                        XPPerror( "init_parse: end tag before first start tag.\n" );
                    assert( !getDepth() );
                    assert( !root_tag_name );
                    current_event = START_TAG;
                    tagstack->push( root_tag_name = getName() );
                    return current_event;
                }
                break;
            default:        // only whitespace allowed
                current_event = TEXT;   // kludge
                isWhitespace() ||
                    XPPerror( "init_parse: disallowed (non-whitespace) character data outside tags: %O...\n",
                                lexer::current[..8]  );
                return current_event = IGNORABLE_WHITESPACE;
            }
        }
        else // autodetect and maybe read from xmldecl
        {
            string head = [string]lexer::peek( 4 );
            // werror( "init_parse: head: %O\n", head );   // DEBUG
            if ( head[..2] == "\xef\xbb\xbf" ) // utf8 BOM
                lexer::setEncoding( "utf-8" );
            else if ( head[..1] == "\xff\xfe" || head[..1] == "<\0" )
                lexer::setEncoding( "utf16-le" );
            else if ( head[..1] == "\xfe\xff" || head[..1] == "\0<" )
                lexer::setEncoding( "utf16" ); // FIXME: support more encodings
            //werror( "init_parse: 1st stage detection: encoding: %s\n", lexer::encoding ); // DEBUG
            lexer::encoding &&
                ( lexer::buffer = lexer::decode( head ) );
            mixed err = catch { head = lexer::next(); };
            if ( err )
            {
                current_event = PARSE_ERROR;
                throw( @(array)err );
            }

            string enc;
            sscanf( head, "<?xml%*sencoding%*[ \t\r\n]=%*[ \t\r\n]%s", enc );
            // FIXME: the above doesn't work !!!
            // well.. it does, somewhat -- but needs fixing anyway
            //werror("**parsed from xmldecl: enc: " + (string)enc + "\n"); // DEBUG
            if ( enc )
            {
                switch( enc[0] )
                {
                case '"':
                    sscanf( enc, "\"%[^\"]", enc );
                    break;
                case '\'':
                    sscanf( enc, "'%[^']", enc );
                    break;
                default:
                    XPPerror( "init_parse: malformed input encoding declaration.\n" );
                }
            }
            else if ( !lexer::encoding ) //fallback
                enc = "utf-8";
            head += lexer::buffer; // get the rest of buffer, preventing overrun (hopefully)
            enc && lexer::setEncoding( enc ); // THIS ERASES THE BUFFER
            //werror( "init_parse: encoding: "+ (string)(lexer::encoding)+"\n" );    // DEBUG
            lexer::offset = 0;
            lexer::buffer = head; // restore the buffer
            lexer::set_buffer();    // set buffer size to default
            return init_parse();
        }

        // not reached (HAHA famous last words ;-)
        XPPerror( "init_parse: internal error.\n" );
    }

//! Parse the next syntactic unit (token), and return its type.
//! @returns
//! The event type.
//! @throws
//! Errors are thrown for unrecoverable parse errors, and in several instances,
//! on method calls invoked in a wrong context. The former type of errors will set
//! the Parser's state flag to PARSE_ERROR, and prevent further parsing; the latter
//! are recoverable (if caught) -- but you would probably rather fix your code.
    Event nextToken()
    {
        switch ( current_event ) // event-specific actions to take...
        {
        case UNDEFINED:
            XPerror( "nextToken: setInput() not called yet.\n" );
        case START_DOCUMENT:
            return init_parse();
        case END_DOCUMENT:
            XPerror( "nextToken: cannot parse past END_DOCUMENT.\n" );
        case PARSE_ERROR:
            XPerror( "nextToken: cannot parse past PARSE_ERROR.\n" );
        case END_TAG:
            tagstack->pop();
            break;
        case START_TAG:
            if ( isEmptyElementTag() )
                return current_event = END_TAG;
        }

        mixed err = catch { lexer::next(); }; // <--- pulled token from lexer !

        if ( err ) // Lexer exceptions are always fatal
        {
            current_event = PARSE_ERROR;
            throw( @(array)err );
        }

        if ( !lexer::current )
        {
            getDepth() &&
                XPPerror( "nextToken: unexpected end of data, unclosed tags remain.\n" );
            root_tag_name ||
                XPPerror( "nextToken: unexpected end of data, no root element found.\n" );
            return current_event = END_DOCUMENT;
        }

        //werror( "In nextToken: lexer::current: %O.\n", lexer::current ); // DEBUG
        switch ( lexer::current[0] )
        {
        case '&':
            assert( lexer::current[-1] == ';' );
            return current_event = ENTITY_REF;
        case '<':
            assert( lexer::current[-1] == '>' );
            switch ( lexer::current[1] )
            {
            case '/':   // END_TAG
                getDepth() ||
                    XPPerror( "nextToken: improper tag nesting detected.\n" );
                current_event = END_TAG;
                ( getName() == tagstack->top() ) ||
                    XPPerror( "nextToken: end tag not matching start tag.\n" );
                return current_event;
            case '?':   // PI
                assert( lexer::current[-2] == '?' );
                ( lower_case( lexer::current[2..4] ) == "xml" ) &&
                    ( sizeof( lexer::current ) > 6 ) &&  // avoid spurious indexing exceptions
                        ( (< ' ', '\t', '\n', '\r' >)[lexer::current[5]] ||
                            sizeof( lexer::current ) == 7 ) &&
                                XPPerror( "nextToken: \"xml\" is not a valid PI name.\n" );
                return current_event = PROCESSING_INSTRUCTION;
            case '!':   // COMMENT or DOCDECL or CDSECT
                switch ( lexer::current[2] )
                {
                case '-':
                    assert( lexer::current[3] == '-' );
                    assert( has_suffix( lexer::current, "-->" ) );
                    return current_event = COMMENT;
                case '[':
                    assert( lexer::current[..8] == "<![CDATA[" );
                    assert( has_suffix( lexer::current, "]]>" ) );
                    getDepth() ||
                        XPPerror( "nextToken: CDATA found outside root element.\n" );
                    return current_event = CDSECT;
                case 'D':
                    assert( lexer::current[..8] == "<!DOCTYPE" );
                    root_tag_name &&
                        XPPerror( "nextToken: DOCTYPE found not before root element.\n" );
                    return current_event = DOCDECL;
                default:
                    XPPerror( "nextToken: unrecognized markup starting with %O..\n",
                                lexer::current[..8] );
                }
            default:
                current_event = START_TAG;
                string name = getName();
                // the test below is SLOW :-( can it be done faster?
                //string tmp;
                //has_value( tmp = map( name, isNameChar ), 0 ) &&
                //    XPPerror( "nextToken: illegal character 0x%x in start tag name "
                //              "at offset %d.",
                //              name[search( tmp, 0 )],
                //              offset - sizeof( lexer::current ) + 1 + search( tmp, 0 ) );
                //getDepth() ||
                //    root_tag_name ||
                //        ( root_tag_name = name );
                if( !getDepth() )
                    if ( root_tag_name )
                        XPPerror( "nextToken: second START_TAG found at depth 0.\n" );
                    else root_tag_name = name;
                tagstack->push( name );
                current_attributes = UNDEFINED; // clear attribute cache
                return current_event;
            }
        default:    // character data
            if ( !getDepth() )  // recognize pure whitespace as ignorable
            {
                sscanf( lexer::current, "%*[ \t\n\r]%s", string nspc );
                sizeof( nspc ) &&
                    XPPerror( "nextToken: character data found outside root element.\n" );
                return current_event = IGNORABLE_WHITESPACE;
            }
            return current_event = TEXT;
        }
    } // nextToken()

//! Parse the next syntactic unit, and return its type. A more user-friendly
//! variant of @[nextToken] that suffices for many purposes. The difference
//! is that this method skips (does not report) comments, DOCTYPE declaration,
//! ignorable whitespace, and PI's, and does not distinguish TEXT from CDATA
//! and entity references, merging adjacent events of those types into
//! single TEXT events.
//! @returns
//! One of START_DOCUMENT, START_TAG, TEXT, END_TAG, END_DOCUMENT.
//! @throws
//! Other than parse errors, errors are thrown when attempting to continue
//! past a (caught) parse error, or past an END_DOCUMENT.
    Event next()
    {
        if ( current_event != PARSE_ERROR )
            if ( !getDepth() || ( getDepth() == 1 && current_event == END_TAG ) )
            {
                while ( !(< START_TAG, END_DOCUMENT >)[nextToken()] );
                return current_event;
            }

        switch ( current_event )
        {
        case PARSE_ERROR:
            XPPerror( "next: cannot parse past PARSE_ERROR.\n" );
        case END_DOCUMENT:
            XPerror( "next: cannot parse past END_DOCUMENT.\n" );
        case START_TAG:
            if ( isEmptyElementTag() )
                return current_event = END_TAG;
        }

        string _data;
        switch ( nextToken() )
        {
        case START_TAG: case END_TAG:
            return current_event;
        case COMMENT: case DOCDECL:
        case IGNORABLE_WHITESPACE: case PROCESSING_INSTRUCTION:
            return next();
        case ENTITY_REF:
            _data = unentity( getTextRaw() );
            _data ||
                XPPerror( "next: failed to resolve entity reference: %O.\n", lexer::current );
            break;
        case TEXT: case CDSECT:
            _data = getTextRaw();
        }

        loop:
        while ( 1 )
        {
            switch ( lexer::peek() )
            {
            case '&':
                nextToken();
                assert( current_event == ENTITY_REF );
                string _s = unentity( getTextRaw() );
                _s ||
                    XPPerror( "next: failed to resolve entity reference: %O.\n", lexer::current );
                _data += _s;
                continue;
            case '<':
                switch ( lexer::peek(2) )
                {
                case "<?":
                    nextToken();
                    continue;
                case "<!":
                    if ( nextToken() == COMMENT )
                        continue;
                    if ( current_event == CDSECT )
                    {
                        _data += getTextRaw();
                        continue;
                    }
                    XPPerror( "next: unrecognized markup after \"<!\".\n" );
                default: // a tag
                    break loop;
                }
            default:
                nextToken();
                assert( current_event == TEXT );
                _data += getTextRaw();
            }
        }
        lexer::current = _data;
        return current_event = TEXT;

    }

//! Set the replacement text of an internal named entity.
//! @param ename
//! The entity name
//! @param text
//! The replacement text. Will not be subject to further expansion
//! (either of entity or character references), scanned for markup,
//! or even decoded (so it must be provided as unencoded Unicode).
//! @throws
//! It is an error to redefine standard XML entity names
//! ( @tt{lt, gt, amp, quot, apos@} )
//! @note
//! This does not, and is not meant to, implement a general standards-compliant
//! mechanism of resolving entity references.  It's only a stopgap solution
//! for the most common use-cases.  The most serious limitation is that
//! the replacement text is reported to the application as-is (as character data),
//! and is not scanned for markup.  Entities that dereference to anything but
//! plain character data are therefore NOT supported by this method.
    void defineEntityReplacementText( string ename, string text )
    {
        standard_entities[ename] &&
            XPerror( "defineEntityReplacementText: standard entities cannot be redefined.\n" );
        entities[ename] = text;
    }


//! BROKEN.(?)
    static string unentity( string what )
    {
        if ( entities[what] )
            return entities[what];
        if ( what[0] == '#' )
        {
            int code; string tmp;
            if ( what[1] == 'x' )
                sscanf( what, "#x%x%s", code, tmp );
            else
                sscanf( what, "#x%d%s", code, tmp );
            !code ||
                sizeof( tmp ) ||
                    XPPerror( "unentity: malformed character reference: &#%s;.\n", what );
            return sprintf( "%c", code );
        }
        else
            //XPPerror( "unentity: failed to resolve entity reference &%s;.\n", what );
            return UNDEFINED;
    }

//! Get the type of the last encountered event (token).
    Event getEventType()
    {
        return current_event;
    }

//! Get the current tag depth.
//!
//! This is 0 outside the root element,
//! incremented by 1 when any start tag is read,
//! and decremented by 1 @i{after@} an end tag.
    int getDepth()
    {
        return tagstack ? sizeof( tagstack ) : 0;
    }

//! @returns
//! For tags, the tag name; for entity references, the entity name.
//! The latter may be a string like @tt{#666@} or @tt{#xdef@} if
//! the entity is actually a numeric character reference.
//! Otherwise, returns UNDEFINED.
    string getName()
    {
        string name;
        switch ( current_event )
        {
        case START_TAG: case END_TAG:
            sscanf( lexer::current, "<%*[/]%[^ \t\n\r/>]", name );
            break;
        case ENTITY_REF:
            name = lexer::current[1..sizeof(lexer::current)-2];
        }
        return name;
    }

//! Determines whether the current start tag is a minimized
//! empty tag i.e. like @tt{<tag/>@}
//! @throws
//! It is an error to call this method if the Parser's state flag
//! is other than START_TAG.
    int(0..1) isEmptyElementTag()
    {
        ( current_event == START_TAG ) ||
            XPerror( "isEmptyElementTag: not at START_TAG.\n" );
        assert( lexer::current[0] == '<' );
        assert( lexer::current[-1] == '>' );
        return lexer::current[-2] == '/';
    }

//! Determines whether the text content (if applicable)
//! of the current parsing event consists of whitespace characters
//! only.
//! @throws
//! It is an error to call this method if the Parser's state flag
//! is other than IGNORABLE_WHITESPACE, TEXT, CDSECT or COMMENT.
    int(0..1) isWhitespace()
    {
        switch ( current_event )
        {
        case IGNORABLE_WHITESPACE:
            return 1;
        case TEXT: case CDSECT: case COMMENT:
            //string nwspc;
            //sscanf( getTextRaw(), "%*[ \t\n\r]%s", nwspc );
            //return !sizeof( nwspc );
            return !sizeof( String.trim_all_whites( getTextRaw() ) );
        default:
            XPerror( "isWhitespace: called in wrong context.\n" );
        }
    }

//! Replaces getTextCharacters() from the original XMLPull
//! spec, that API doesn't seem to make much sense for Pike.
//! @returns
//! For TEXT and IGNORABLE_WHITESPACE events, the text content
//! is returned; similarly for CDATA sections, comments,
//! processing instructions and DOCTYPE sections
//! (the delimiters: @tt{<!--, <![CDATA[@} etc. are omitted);
//! for ENTITY_REF events, the starting @tt{&@} and trailing
//! semicolon are stripped.  In the case of tag events,
//! START_DOCUMENT and END_DOCUMENT, UNDEFINED is returned.
//! End-of-line normalization is NOT applied.
    string getTextRaw()
    {
        string current_data = lexer::current;
        switch ( current_event )
        {
        case TEXT: case IGNORABLE_WHITESPACE:
            return current_data;
        case CDSECT:
            return current_data[9..sizeof(current_data)-4];
        case COMMENT:
            return current_data[4..sizeof(current_data)-4];
        case PROCESSING_INSTRUCTION:
            return current_data[2..sizeof(current_data)-3];
        case ENTITY_REF:
            return current_data[1..sizeof(current_data)-2];
        case DOCDECL:
            return current_data[9..sizeof(current_data)-2];
        default:
            return UNDEFINED;
        }
    }

    static string eol_normalize( string what )
    {
        return replace( what, ({ "\r\n", "\r" }), ({ "\n", "\n" }) );
    }

//! Just like @[getTextRaw], except at ENTITY_REF, where it's
//! supposed to resolve the entity reference if possible.
//! Also, end-of-line normalization is applied.
    string getText()
    {
        string s = getTextRaw();
        if ( current_event == ENTITY_REF )
            return unentity( s );
        return s &&
            eol_normalize( s );
    }

    static array(array(string)) parse_attributes( string input )
    {
    // parse a string like " foo='bar' bumble = \"blah\""
    // with *obligatory* leading whitespace and whitespace between
    // name=value pairs, *optional* trailing whitespace and whitespace
    // around the '='.
    // Return an array of two equal-size arrays: names and (unquoted) values.
    // Sorted by the order they are found in the input.
    // Throw if the input is malformed.
        string rest;
        sscanf( reverse( input ), "%*[ \t\n\r]%s", rest );
        rest = reverse( rest ); // removed any trailing whitespace
        array(array(string)) result = ({ ({}), ({}) });

        while( sizeof( rest ) )  // if input had only whitespace, OK, we'll return an empty attr. list
        {
            string sp, aname, aval;
            sscanf( rest, "%[ \t\n\r]%[^ \t\n\r='\"]%*[ \t\n\r]=%*[ \t\n\r]%s", sp, aname, rest );
            if ( sizeof( sp ) && sizeof( aname ) )
            {
                switch ( rest[0] )
                {
                case '"':
                    sscanf( rest, "\"%[^\"]\"%s", aval, rest );break;
                case '\'':
                    sscanf( rest, "'%[^']'%s", aval, rest );break;
                default:
                    XPerror( "parse_attributes: malformed input: %O\n", input );
                }

                result[0] += ({ aname });
                aval = replace( eol_normalize( aval ),
                             ({ "\t", "\n" }),
                             ({ " ", " " }) ); // FIXME: resolve entity and char refs
                // *sigh*... the weird rules for attribute value normalization
                string tok, remainder = aval;
                aval = "";
                while ( sizeof( remainder ) )
                {
                    sscanf( remainder, "%[^&]%s", tok, remainder );
                    aval += tok;
                    if ( !sizeof( remainder ) )
                        break;
                    sscanf( remainder, "&%[^;]%s", tok, remainder );
                    aval += unentity( tok );
                    sizeof( remainder ) && ( remainder = remainder[1..] );
                }

                result[1] += ({ aval });
                continue;
            }
            XPerror( "parse_attributes: malformed input: %O\n", input );
        }

        // TODO: lots, like validity of attribute name (the least)

        return result;
    }

//! Get the number of attribute-value pairs attached to the current
//! START_TAG.
//! @returns
//! The number of attributes, or -1 if not at START_TAG.
    int getAttributeCount()
    {
        if ( current_event != START_TAG )
            return -1;
        if ( !current_attributes )
        {
            string data;
            sscanf( lexer::current, "<%*[^ \t\n\r/>]%[^>]", data );
            sizeof(data) && data[-1] == '/' && ( data = data[..sizeof(data)-2] );
            current_attributes = parse_attributes( data );
        }
        assert( sizeof( current_attributes ) == 2 );
        assert( sizeof( current_attributes[0] ) == sizeof( current_attributes[1] ) );
        return sizeof( current_attributes[0] );
    }

//! Get the name of an attribute attached to the current START_TAG.
//! @param index
//! The index of the desired attribute, in the order they appear in the tag.
//! @throws
//! It is an error if the index is out of bounds, or the Parser
//! is not at START_TAG.
    string getAttributeName( int index )
    {
        if ( current_event == START_TAG )
        {
            if ( !current_attributes )
            {
                string data;
                sscanf( lexer::current, "<%*[^ \t\n\r/>]%[^>]", data );
                sizeof(data) && data[-1] == '/' && ( data = data[..sizeof(data)-2] );
                current_attributes = parse_attributes( data );
            }
            assert( sizeof( current_attributes ) == 2 );
            assert( sizeof( current_attributes[0] ) == sizeof( current_attributes[1] ) );
            return current_attributes[0][index];
        }
        XPerror( "getAttributeName: not at START_TAG.\n" );
    }

//! Get the value of an attribute attached to the current START_TAG.
//! @param index
//! The index of the desired attribute, in the order they appear in the tag.
//! @throws
//! It is an error if the index is out of bounds, or the Parser
//! is not at START_TAG.
//! @fixme
//! attribute value normalization, as per XML 1.0 spec (ugh)
    string getAttributeValue( int|string index )
    {
        if ( current_event == START_TAG )
        {
            if ( !current_attributes )
            {
                string data;
                sscanf( lexer::current, "<%*[^ \t\n\r/>]%[^>]", data );
                sizeof(data) && data[-1] == '/' && ( data = data[..sizeof(data)-2] );
                current_attributes = parse_attributes( data );
            }
            assert( sizeof( current_attributes ) == 2 );
            assert( sizeof( current_attributes[0] ) == sizeof( current_attributes[1] ) );
            if ( stringp( index ) )
                return mkmapping( @current_attributes )[index];
            return current_attributes[1][index];
        }
        XPerror( "getAttributeValue: not at START_TAG.\n" );
    }

//! the API @[getAttributeCount], @[getAttributeName], @[getAttributeValue]
//! is included for correspondence with the Java XMLPull spec,
//! but it's sickeningly cumbersome to a Pike programmer. So, we provide an alternative
//! (though one that is slightly lacking, due to losing the original order of the attributes)
//! @returns
//! A mapping containing attribute name:value pairs.
//! @throws
//! It is an error if the Parser is not at START_TAG.
    mapping(string:string) getAllAttributes()
    {
        if ( current_event != START_TAG )
            XPerror( "getAllAttributes: not at START_TAG.\n" );
        if ( !current_attributes )
        {
            string data;
            sscanf( lexer::current, "<%*[^ \t\n\r/>]%[^>]", data );
            sizeof(data) && data[-1] == '/' && ( data = data[..sizeof(data)-2] );
            current_attributes = parse_attributes( data );
        }
        assert( sizeof( current_attributes ) == 2 );
        assert( sizeof( current_attributes[0] ) == sizeof( current_attributes[1] ) );
        return mkmapping( @current_attributes );
    }

    int nextTag()
    {
        next() == TEXT && isWhitespace() && next();
        (< START_TAG, END_TAG >)[current_event] ||
            XPerror( "nextTag: expected start tag or end tag, got %s.\n",
                        TYPES[current_event] );
        return current_event;
    }

    string nextText()
    {
        current_event == START_TAG ||
            XPerror( "nextText: not at start tag.\n" );
        switch ( next() )
        {
        case TEXT:
            string result = getText();
            next() == END_TAG ||
                XPerror( "nextText: text not followed by end tag.\n" );
            return result;
        case END_TAG:
            return "";
        default:
            XPerror( "nextText: expected text or end tag, got %s.\n",
                        TYPES[current_event] );
        }
    }

//! Provides a single line describing the current event, including
//! event type, tag (if applicable, attributes omitted), a snippet
//! of the text content's head (if applicable), and the character offset
//! (corresponding to the position in the input stream where
//! the current event ends).
    string getPositionDescription()
    {
        string desc, txt;

        switch ( current_event )
        {
        case START_DOCUMENT: case END_DOCUMENT:
            desc = "(none)";
            break;
        case START_TAG:
            desc = "<" + getName() + ">";
            break;
        case END_TAG:
            desc = "</" + getName() + ">";
            break;
        case TEXT: case COMMENT: case CDSECT: case IGNORABLE_WHITESPACE:
            if ( isWhitespace() )
            {
                desc = "(whitespace)";
            }
            else
            {
                txt = getTextRaw();
                txt = ( sizeof( txt ) > 60 ) ? ( txt[..57]+".." ) : txt;
                desc = sprintf( "%O", txt );
            }
            break;
        case PROCESSING_INSTRUCTION: case DOCDECL:
        case ENTITY_REF:
            txt = getTextRaw();
            txt = ( sizeof( txt ) > 60 ) ? ( txt[..57]+".." ) : txt;
            desc = sprintf( "%O", txt );
        }
        return sprintf( "%s %s @%d\n", TYPES[current_event], desc, offset );
    }

    // stubs for XML-namespace related methods

    int getNamespaceCount( int depth )
    {
        return 0;
    }

    string getNamespacePrefix( int pos )
    {
        return UNDEFINED;
    }

    string getNamespaceUri( int pos )
    {
        return UNDEFINED;
    }

    string getNamespace( void|string prefix )
    {
        if ( (< START_TAG, END_TAG >)[current_event] )
            if ( !prefix )
                return "";
        return UNDEFINED;
    }

    string getPrefix()
    {
        return UNDEFINED;
    }

    string getAttributeNamespace( int index )
    {
        if ( current_event == START_TAG )
            return "";
        XPerror( "getAttributeNamespace: not at START_TAG.\n" );
    }

    string getAttributePrefix( int index )
    {
        if ( current_event == START_TAG )
            return UNDEFINED;
        XPerror( "getAttributePrefix: not at START_TAG.\n" );
    }


    // override lexer::create
    static void create()
    {}


} // class Parser


//! A simple, streaming XML writer.  Its purpose is to make it hard to
//! write non-well-formed XML without throwing an error, and to manage
//! output buffering rather transparently for the user.  No special
//! facilities for handling XML namespaces yet.
//! @note
//! The @tt{XmlSerializer@} will only @tt{write()@} to the output stream,
//! it is the caller's responsibility to close and/or destruct the
//! stream object when done.
class XmlSerializer
{
    static
    {
        Stdio.Stream stream;
        string encoding;
        Encoder encoder;
        ADT.Stack tagstack;
        string root_tag_name;
        Event last_event;
        int buffered;
        int bufsize = 512;
    }

    static void bwrite( string what, mixed ... extras )
    {
        what = sprintf( what, @extras );
        if ( ( buffered + sizeof(what) ) > bufsize )
        {
            stream->write( encoder->drain() );
            buffered = 0;
        }
        encoder->feed( what );
        buffered += sizeof( what );
    }

    static string encode_numeric( string what )
    {
        return sprintf( "%{&#%d;%}", (array(int))what );
    }

    //! Set to use the output stream with the given encoding.
    //! The encoding, if omitted, defaults to UTF-8.
    //! A @tt{XmlSerializer@} object may be reused, as
    //! this method resets its state and makes it ready to
    //! output another document.
    //! @throws
    //! It is an error if a previous document hasn't yet
    //! been finished by calling @[endDocument()].
    void setOutput( Stdio.Stream str, void|string enc )
    {
        last_event == END_DOCUMENT ||
            error( "setOutput: wrong state for call.\n" );
        enc ? ( encoding = enc ) :
            ( encoding = encoding || "utf-8" );
        encoder = Locale.Charset.encoder( encoding );
        ([function(function(string:string):void)]
            encoder->set_replacement_callback)( encode_numeric );
        tagstack = ADT.Stack();
        root_tag_name = UNDEFINED;
        stream = str;
        buffered = 0;
        last_event = UNDEFINED;
    }

    //! Write the XML declaration with the given encoding.
    //! @note
    //! The encoding overrides that given at @[setOutput()],
    //! so there is no need to provide it at both calls.
    void startDocument( void|string enc )
    {
        !last_event ||
            error( "startDocument: wrong state for call.\n" );
        if ( enc )
        {
            encoding = enc;
            encoder = Locale.Charset.encoder( encoding );
            ([function(function(string:string):void)]
            encoder->set_replacement_callback)( encode_numeric );
        }
        bwrite( "<?xml version=\"1.0\" encoding=\"%s\"?>", encoding );
        last_event = START_DOCUMENT;
    }

//! @ignore
#define DOC_STARTED ( last_event > 0 )
//! @endignore

    //! Write a start tag with the given name.
    //! @fixme
    //! Validate the name.
    this_program startTag( string name )
    {
        DOC_STARTED ||
            error( "startTag: doc not started.\n" );
        last_event == START_TAG &&
            bwrite( ">" );
        getDepth() ||
            ( root_tag_name ?
                ( error( "startTag: cannot insert another root element.\n" ), 0 ) :
                    ( root_tag_name = name ) );
        tagstack->push( name );
        bwrite( "<%s", name );
        last_event = START_TAG;
        return this;
    }

    //! Write the text, where special XML chars are escaped automatically.
    this_program text( string txt )
    {
        getDepth() || error( "text: disallowed at depth 0.\n" );
        last_event == START_TAG &&
            bwrite( ">" );
        txt = replace( txt, ([array(string)]values( standard_entities )),
                sprintf( "%{&%s;\1%}", ([array(string)]indices( standard_entities )) ) / "\1" - ({""}) );
        bwrite( txt );
        last_event = TEXT;
        return this;
    }

    //! Write an end tag with the given name.
    //! @throws
    //! It is an error if @tt{name@} is other than that of the most
    //! recently written start tag.
    this_program endTag( string name )
    {
        ( getDepth() && tagstack->top() == name ) ||
            error( "endTags: wrong name or no tags open.\n" );
        last_event == START_TAG ?
            bwrite( "/>" ):
                bwrite( "</%s>", name );
        tagstack->pop();
        last_event = END_TAG;
        return this;
    }

    //! Write an attribute to the most recently written start tag.
    //! @throws
    //! It is an error if anything other than attributes was written
    //! to the output after the most recent start tag before this method is
    //! is called.
    //! @fixme
    //! Check that the name is valid
    this_program attribute( string name, string value )
    {
        last_event == START_TAG ||
            error( "attribute: not at START_TAG.\n" );
        value = replace( value, [array(string)]values( standard_entities ),
                    sprintf( "%{&%s;\1%}", ([array(string)]indices( standard_entities )) ) / "\1" - ({""}) );
        bwrite( " %s=\"%s\"", name, value );
        return this;
    }

    //! Write a @tt{DOCTYPE@} declaration.
    //! @throws
    //! It is an error when a @tt{DOCTYPE@} declaration is not
    //! allowed at the current position in the document.
    //! @note
    //! The caller is fully responsible for the inserted text, it is not
    //! validated or scanned at all (and it had better start with at least
    //! one character of whitespace).
    void docdecl( string txt )
    {
        DOC_STARTED ||
            error( "docdecl: doc not started.\n" );
        getDepth() &&
            error( "docdecl: disallowed at nonzero depth.\n" );
        root_tag_name &&
            error( "docdecl: disallowed after root element.\n" );
        bwrite( "<!DOCTYPE%s>", txt );
        last_event = DOCDECL;
    }

    //! Write an XML comment.
    //! @param txt
    //! The text of the comment.
    //! @throws
    //! It is an error for the comment text to contain the string @tt{"--"@}
    void comment( string txt )
    {
        DOC_STARTED ||
            error( "comment: doc not started.\n" );
        ( has_value( txt, "--" ) || txt[-1] == '-' ) &&
            error( "comment: illegal \"--\" in comment text.\n" );
        last_event == START_TAG &&
            bwrite( ">" );
        bwrite( "<!--%s-->", txt );
        last_event = COMMENT;
    }

    //! Write a @tt{CDATA@} section.
    //! @throws
    //! It is an error when a @tt{CDATA@} section is not
    //! allowed at the current position in the document.
    //! @note
    //! The content may actually be written as several consecutive
    //! @tt{CDATA@} sections, in the case that it contains a substring
    //! @tt{"]]>"@}.
    void cdsect( string txt )
    {
        getDepth() ||
            error( "cdsect: disallowed at zero depth.\n" );
        last_event == START_TAG &&
            bwrite( ">" );
        array(string) tmp = txt / "]]>";
        bwrite( "<![CDATA[%s]]>", tmp * "]]]><![CDATA[]>" );
        last_event = CDSECT;
    }

    //! Write a processing instruction.
    //! @throws
    //! It is an error for the text to contain the string @tt{"?>"@}.
    void processingInstruction( string txt )
    {
        DOC_STARTED ||
            error( "processingInstruction: doc not started.\n" );
        has_value( txt, "?>" ) &&
            error( "processingInstruction: illegal \"?>\" in PI text.\n" );
        sscanf( txt, "%[^ \t\n\r]", string name );
        lower_case( name ) != "xml" ||
            error( "processingInstruction: \"xml\" is a reserved name.\n" );
        last_event == START_TAG &&
            bwrite( ">" );
        bwrite( "<?%s?>", txt );
        last_event = PROCESSING_INSTRUCTION;
    }

    //! Write some whitespace outside any tags.
    //! @param txt
    //! Must be all whitespace, i.e. only the characters
    //! @tt{' ', '\t', '\n', '\r'@} are allowed.
    //! @throws
    //! It is an error for the text to contain non-whitespace
    //! characters, or to call this method when not at document
    //! toplevel.
    void ignorableWhitespace( string txt )
    {
        DOC_STARTED ||
            error( "ignorableWhitespace: doc not started.\n" );
        getDepth() &&
            error( "ignorableWhitespace: disallowed at nonzero depth.\n" );
        sscanf( txt, "%*[ \t\n\r]%s", string nwsp );
        sizeof( nwsp ) &&
            error( "ignorableWhitespace: called with non-whitespace.\n" );
        bwrite( txt );
        last_event = IGNORABLE_WHITESPACE;
    }

    //! Write a reference to the general entity with the given name.
    //! Legal only where text content is allowed.
    //! @note
    //! Avoid this method.  Unless you know what you're doing.  This
    //! method does nothing to prevent you from violating well-formedness
    //! by referencing undeclared entities.
    void entityRef( string name )
    {
        last_event == START_TAG &&
            bwrite( ">" );
        getDepth() ||
            error( "entityRef: disallowed at zero depth.\n" );
        bwrite( "&%s;", name );
        last_event = ENTITY_REF;
    }

    //! Finish writing. All unclosed start tags will be closed and output will be flushed.
    //! After calling this method no more output can be serialized until next call
    //! to @[setOutput()].
    void endDocument()
    {
        root_tag_name ||
            error( "endDocument: root element not written yet.\n" );
        while ( sizeof( tagstack ) )
            endTag( [string](tagstack->top()) );
        stream->write( encoder->drain() );
        encoder->clear();
        buffered = 0;
        last_event = END_DOCUMENT;
    }

    //! @returns
    //! The current depth of the element. Depth is 0 outside the root tag,
    //! incremented by 1 with every @[startTag()], and decremented by 1
    //! after every @[endTag()].
    int getDepth()
    {
        return sizeof( tagstack );
    }

    //! Write all pending output to the stream.
    //! If a start tag was currently being written (most recent output
    //! call was @[startTag()] or @[attribute()]), the start tag is completed.
    void flush()
    {
        last_event == START_TAG &&
            encoder->feed( ">" );
        stream->write( encoder->drain() );
        buffered = 0;
        last_event = getDepth() ? TEXT : IGNORABLE_WHITESPACE; // kludgy
    }

    //! Returns the name of the current element as set by @[startTag()].
    //! It can only be null before first call to @[startTag()] or when
    //! last @[endTag()] is called to close first @[startTag()].
    string getName()
    {
        if ( !getDepth() )
            return UNDEFINED;
        return [string]tagstack->top();
    }

    static void create()
    {
        encoding = "utf-8";
        last_event = END_DOCUMENT; // kludge?
    }

} // class XmlSerializer
