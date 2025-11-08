//! An attempt at a XML tree interface.
//!
//! Author: rjb @url{http://bobo.fuw.edu.pl/~rjb/@}
//!
//! Pre-alpha, 2003-05-05
//! @fixme
//! Need some clever ways of navigating the tree --
//! check out XPath?

#pragma strict_types

#if !constant(Locale.Charset.Encoder)
#if constant(Locale.Charset.ascii)
constant Encoder = Locale.Charset.ascii;
#else
#error Neither Locale.Charset.Encoder nor Locale.Charset.ascii\
 are known to be defined.
#endif
#else
constant Encoder = Locale.Charset.Encoder;
#endif

//! Virtual base class
class BaseNode
{
    static Element|Doc parent;
    Element|Doc getParent() { return parent; }

    //! @returns
    //! -1 for an unattached node, 0 for root element, etc.
    int getDepth()
    {
        object(Element)|object(Doc) p; // why can't this be written as usual?
        return ( p = this->getParent() ) ?
            ( p->getDepth() + 1 ) :
                -1;
    }

    //! @note
    //! must override in subclasses.
    static void create( mixed...args )
    {
        error( "Cannot create instance of virtual class BaseNode.\n" );
    }

    //! @bugs
    //! If you call this method directly, this node will not be added to
    //! the parent's children.  And you lose.
    this_program setParent( Element|Doc p )
    {
        parent = p; return this;
    }

    //! Render the node and all its subnodes (if applicable) to an
    //! XML string.
    //! @returns
    //! A properly encoded string of XML, suitable for writing to
    //! a file, etc.
    //! @param enc
    //! an encoder object. If none provided, encoding will be to utf-8.
    //! @note
    //! Prototype only.  Implemented in subclasses.
    string toString( void|object enc );

    //! Shift the tree n steps towards the root.
    //! @returns
    //! The n'th ancestor of this node, or @tt{UNDEFINED@}
    //! when attempting to shift the tree beyond its current root.
    static BaseNode `>>( int(0..) n )
    {
        object(BaseNode) p = this;
        while ( n-- && ( p = p->getParent() ) );
        return p;
    }

    //! Get the current root of the tree.
    //! This might be a @[Doc], or an @[Element]
    //! (whatever is currently at the top)
    BaseNode getRoot()
    {
        object(BaseNode) p = this;
        while ( p->getParent() )
            p = p->getParent();
        return p;
    }
} // class BaseNode

//! Stores character data
class Text
{
    inherit BaseNode;
    static string text;

    //! @returns
    //! The raw unencoded text, usually a wide string.
    string getText() { return text; }

    int(0..1) isWhitespace()
    {
        return !sizeof(
            replace( text, ({ " ", "\t", "\n", "\r" }), ({ "" })*4 )
                );
    }

    //! @param t
    //! The character data (a raw unencoded string, might be wide)
    //! @fixme
    //! Check that only valid characters are passed in the string.
    static void create( string t )
    {
        text = t;
    }

    static string encode_replacement_callback( string what )
    {
        string str = "";
        foreach( (array(int))what, int code )
            str += sprintf( "&#%d;", code );
        return str;
    }

    //! @fixme
    //! replacement of unencodable chars by numeric references
    string toString( void|object(Encoder) enc )
    {
        enc = enc || Locale.Charset.encoder( "utf-8" );
        ([function(function(string:string):void)](
        enc->
            set_replacement_callback))( encode_replacement_callback );
        string str = enc->
            feed(
                replace( text,
                    ({ "<", ">", "&" }),
                        ({ "&lt;", "&gt;", "&amp;" })
                             ))->
                                drain();
        ([function(function(string:string):void)](
        enc->set_replacement_callback))(UNDEFINED);
        return str;
    }

    this_program `+( Text|string ... args )
    {
        string str = text;
        foreach ( args, string|object(Text) arg )
        {
            stringp( arg ) ?
                ( str += [string]arg ) :
                    ( str += ([object(Text)]arg)->getText() );
        }
        return this_program( str );
    }

    this_program `+=( Text|string arg )
    {
        stringp( arg ) ?
            ( text += [string]arg ) :
                ( text += ([object(Text)]arg)->getText() );
        return this;
    }

} // class Text

//! Stores @tt{CDATA@} sections.
class Cdata
{
    inherit Text;
    constant isCdata = 1;

    //! @fixme
    //! instead of throwing,
    //! split CDATA if needed to accommodate "]]>"
    string toString( void|object(Encoder) enc )
    {
        enc = enc || Locale.Charset.encoder( "utf-8" );
        if ( search( text, "]]>" ) != -1 )
            error( "illegal \"]]>\" in CDATA content.\n" );
        return enc->feed( "<![CDATA[" )->
                feed( text ) ->feed( "]]>" )->
                    drain();
    }
}


//! Stores XML comments, like @tt{<!-- a comment -->@}
class Comment
{
    inherit Text;
    constant isComment = 1;

    string toString( void|object(Encoder) enc )
    {
        enc = enc || Locale.Charset.encoder( "utf-8" );
        return enc->feed( "<!--" )->
                feed( replace( text, "--", "- -" ) )-> // sigh, what are we to do
                feed( "-->" )->
                drain();
    }
}

//! Stores XML processing instructions,
//! like @tt{<?foo whatever?>@}
//! @fixme
//! check for valid PI name.
class PI
{
    inherit Text;
    constant isPI = 1;

    string toString( void|object(Encoder) enc )
    {
        enc = enc || Locale.Charset.encoder( "utf-8" );
        return enc->feed( "<?" )->
            feed( replace( text, "?>", "? >" ) )-> // sigh, what are we to do
                feed( "?>" )->
                drain();
    }
}

//! A tag
//! @note
//! An empty tag (no children) may be rendered either as
//! @tt{<tag/>@} or as @tt{<tag></tag>@}
//! (both are equivalent as XML). If, for some strange reason,
//! you insist on the latter (non-minimized) syntax,
//! insert a @[Text] child with an empty string as content.
class Element
{
    inherit BaseNode;
    constant isElement = 1;
    static string name;
    static array(Element|Text) children;
    static mapping(string:string) attributes;

    //! @param n
    //! The tag's name.
    //! @param attr
    //! The tag's attributes.
    //! @fixme
    //! Validate the args
    static void create( string n, mapping(string:string)|void attr )
    {
        name = n;
        children = ({});
        attributes = attr + ([]);
    }

    int(0..1) isEmpty()
    {
        return !sizeof( children );
    }

    string getName()
    { return name; }

    array(Element|Text) getChildren( void|string nm )
    {
        if ( !nm )
            return children + ({});
        return filter( children,
            lambda( object(Element)|object(Text) o, string n )
                {
                    return ( o->isElement &&
                            ( ([object(Element)]o)->getName() == n ) );
                },
                    nm );
    }

    string|mapping(string:string) getAttr( void|string nm )
    {
        return nm ?
            attributes[nm]:
                ( attributes + ([]) );
    }

    this_program setParent( Element|Doc p )
    {
        object(Element)|object(Doc) ancestor = p;
        do
            ancestor != this ||
                error( "Cycle of element ancestry detected!\n" );
        while ( ancestor = [object(Element)|object(Doc)](ancestor >> 1) );

        ::setParent( p );
        return this;
    }

    //! @fixme
    //! check for allowed attribute values
    string toString( void|object(Encoder) enc )
    {
        enc = enc || Locale.Charset.encoder( "utf-8" );
        enc->feed( "<" + name );
        if ( attributes )
        {
            foreach ( attributes; string var; string val )
            {
                if ( !has_value( val, '"' ) )
                    val = sprintf( "\"%s\"", val );
                else if ( !has_value( val, '\'' ) )
                    val = sprintf( "'%s'", val );
                else
                    val = sprintf( "\"%s\"", replace( val, "\"", "&quot;" ) );
                enc->feed( sprintf( " %s=%s", var, val ));
            }
        }
        if ( isEmpty() )
            return enc->feed( "/>" )->drain();
        else
        {
            string str = enc->feed( ">" )->drain();
            foreach ( children, object(Element)|object(Text) child )
                str += child->toString( enc );
            return str +
                enc->feed( sprintf( "</%s>", name ) )->drain();
        }
    }

    //! Append one or more child nodes to the content of this Element.
    //! @param childs
    //! Will be appended in the order provided in the call.
    //! If a string, create and append a @[Text] node with the
    //! string as its content.
    //! @returns
    //! A reference to the current node
    //! @throws
    //! You cannot append a node that already has a parent; you must
    //! @[detach] it first if needed.
    static this_program `()( Element|Text|string ... childs )
    {
        foreach ( childs, string|object child )
        {
            stringp( child ) &&
                ( child = Text( [string]child ) );
            ([object(Element)|object(Text)]child)->getParent() &&
                error( "Cannot reparent an already attached node.\n" );
            children = [array(Element|Text)]( ( children || ({}) ) + ({ child }) );
            ([object(Element)|object(Text)]child)->setParent( this );
        }
        return this;
    }

    //! Append a child node to the content of this Element.
    //! @param child
    //! If a string, create and append a @[Text] node with the
    //! string as its content.
    //! @returns
    //! A reference to the just appended child node.
    //! @throws
    //! You cannot append a node that already has a parent.
    static Element|Text `<<( Element|Text|string child )
    {
        stringp( child ) &&
            ( child = Text( [string]child ) );
        ([object(Element)|object(Text)]child)->getParent() &&
            error( "Cannot reparent an already attached node.\n" );
        children = [array(Element|Text)]( ( children || ({}) ) + ({ child }) );
        ([object(Element)|object(Text)]child)->setParent( this );
        return [object(Element)|object(Text)]child;
    }

    //! Detach a child node (and its whole subtree) from this Element.
    //! @param idx
    //! The index of the node to detach.
    //! @returns
    //! The just detached node.
    //! @throws
    //! When @tt{idx@} is out of bounds.
    Element|Text detach( int idx )
    {
        object(Element)|object(Text) node = children[idx];
        children -= node;
        node->setParent( UNDEFINED );
        return node;
    }

} // class Element

//! An XML document instance.
//! @fixme
//! No provision for DTD yet.
class Doc
{
    inherit BaseNode;
    constant isDoc = 1;
    static array(Text) head;
    static array(Text) tail;
    static Element root_element;
    constant xmlversion = "1.0";
    string encoding;

    Element|Doc getParent() { return 0; }
    Doc getRoot() { return this; }
    int getDepth() { return -1; }

    //! @returns
    //! An array of all children.
    //!
    //! At toplevel, there might be comments, PIs and whitespace
    //! both before and following the root element, which must be
    //! unique.
    array(Element|Text) getChildren()
    {
        return ( head || ({}) ) +
            ( root_element ? ({ root_element }) : ({}) ) +
                ( tail || ({}) );
    }

    //! Create a Doc instance.
    //! @param root
    //! Either a string (the name of the root Element, which is
    //! created without any content), a pre-fab root Element,
    //! or void (leaving adding the root Element to a later step).
    static void create( string|Element|void root )
    {
        if ( !root ) return;
        if ( stringp( root ) )
            root_element = Element( [string]root );
        else
            root_element = [object(Element)]root;
        root_element->setParent( this );
    }

    //! Add content to the Doc instance.
    //! @param childs
    //! A sequence containing at most one Element (the root
    //! of the element tree), and any number of @[PI],
    //! @[Comment] and @[Text] before and/or after the root Element.
    //! The @[Text] must contain whitespace only.
    //! @note
    //! The `only whitespace in toplevel Text' rule may be foiled by
    //! adding non-whitespace content to the Text children of Doc
    //! in a later step, resulting in non-well-formed XML.  Beware.
    Doc `()( Element|Text|string ... childs )
    {
        foreach ( childs, string|object(Element)|object(Text) child )
        {
            if ( stringp( child ) )
            {
                child = Text( [string]child );
            }
            child = [object(Element)|object(Text)]child;
            if ( Program.implements( [program]object_program( child ), Element ) )
            {
                !root_element ||
                    error( "Can't add another root Element to a Doc.\n" );
                root_element = [object(Element)]child;
            }
            else if ( Program.implements( [program]object_program( child ), Text ) )
            {
                child->isComment ||
                    child->isPI ||
                        ( [object(Text)]child )->isWhitespace() ||
                            error( "Non-whitespace text disallowed at XML toplevel.\n" );
                root_element ?
                    ( tail = ( tail || ({}) ) + ({ [object(Text)]child }) ):
                        ( head = ( head || ({}) ) + ({ [object(Text)]child }) );
            }
            else error( "Incorrect type of child.\n" );
        }
        return this;
    }

    //! Render the document to an XML string
    //! @param enc
    //! the character encoding, defaults to utf-8 if not given.
    //! @note
    //! It is up to the caller to ensure a root element is actually
    //! present; if there is none, the call will succeed but the
    //! result won't be well-formed XML.
    string toString( void|string|object(Encoder) enc )
    {
        Encoder encoder;
        string str;
        if ( objectp( enc ) )
        {
            encoding = 0; // unknown
            encoder = [object(Encoder)]enc;
            str = sprintf( "<?xml version=\"%s\"?>", xmlversion );
        }
        else
        {
            encoding = [string]( enc || encoding || "utf-8" );
            encoder = Locale.Charset.encoder( encoding );
            str = sprintf( "<?xml version=\"%s\" encoding=\"%s\"?>",
                        xmlversion, encoding );
        }
        str = encoder->feed( str )->drain();
        foreach ( getChildren(), object(Element)|object(Text) child )
            str += child->toString( encoder );
        return str;
    }

    //! Set the output encoding.
    //! Will be retained by later calls to @[toString()]
    //! unless overridden by its argument.
    //! @returns
    //! this object.
    Doc setEncoding( string enc )
    {
        encoding = enc; return this;
    }

    Doc setParent( Element|Doc p )
    {
        error( "setParent: a Doc cannot have a parent.\n" );
    }

} // class Doc

import .PiXPull;

//! Extract an @[Element] from the content of an XML datastream.
//! @param xpp
//! A @[PiXPull.Parser] that must be positioned at @tt{START_TAG@}
//! @returns
//! An @[Element] representing the content of the XML stream from the
//! current start tag up to the matching end tag.
//! @note
//! Upon return from this method, the Parser will be positioned
//! at @tt{END_TAG@}.
Element pullElement( Parser xpp )
{
    xpp->getEventType() == START_TAG ||
        error( "pullElement: Parser not at START_TAG.\n" );
    Element elem = Element( xpp->getName(), xpp->getAllAttributes() );
    int depth = xpp->getDepth();
    while ( xpp->nextToken() )
    {
        switch ( xpp->getEventType() )
        {
        case TEXT: case ENTITY_REF:
            elem( xpp->getText() );
            break;
        case CDSECT:
            elem( Cdata( xpp->getText() ) );
            break;
        case COMMENT:
            elem( Comment( xpp->getText() ) );
            break;
        case PROCESSING_INSTRUCTION:
            elem( PI( xpp->getText() ) );
            break;
        case START_TAG:
            elem( pullElement( xpp ) );
            break;
        case END_TAG:
            if ( xpp->getDepth() == depth )
                return elem;
        case END_DOCUMENT: case START_DOCUMENT:
        case DOCDECL: case PARSE_ERROR: case UNDEFINED:
            error( "pullElement: this can't happen!\n" ); // yeah, the parser should throw
        }
    }
        error( "pullElement: this can't happen!\n" );
}

//! Parse an XML stream into a @[Doc].
//! @param xpp
//! A @[PiXPull.Parser] that must be positioned at @tt{START_DOCUMENT@}.
//! @returns
//! A @[Doc] representing the content of the XML stream.
//! @note
//! Upon return from this method, the Parser will be positioned
//! at @tt{END_DOCUMENT@}.
//! @fixme
//! @tt{DOCTYPE@} sections are ignored (skipped).
Doc pullDoc( Parser xpp )
{
    xpp->getEventType() == START_DOCUMENT ||
        error( "pullDoc: Parser not at START_DOCUMENT.\n" );
    Doc doc = Doc();
    while ( xpp->nextToken() > 0 )
    {
        switch  ( xpp->getEventType() )
        {
        case START_TAG:
            doc( pullElement( xpp ) );
            break;
        case IGNORABLE_WHITESPACE:
            doc( xpp->getText() );
            break;
        case COMMENT:
            doc( Comment( xpp->getText() ) );
            break;
        case PROCESSING_INSTRUCTION:
            doc( PI( xpp->getText() ) );
            break;
        case DOCDECL: // ignore for now
            break;
        default:
            error( "pullDoc: event is %s (can't happen).\n",
                TYPES[xpp->getEventType()] );
        }
    }
    xpp->getEventType() == END_DOCUMENT ||
        error( "pullDoc: event is %s, expected END_DOCUMENT.\n",
            TYPES[xpp->getEventType()] );
    return doc;
}
