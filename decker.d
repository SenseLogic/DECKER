// -- IMPORTS

import core.stdc.stdlib : exit;
import etc.c.sqlite3;
import std.conv;
import std.digest.crc;
import std.file : read, readText, rename, write;
import std.json;
import std.stdio : writeln;
import std.string : indexOf, replace, split, startsWith, strip, toStringz;
import std.zip;

// -- TYPES

enum MESSAGE_TYPE
{
    Uint32,
    Uint64,
    Int64,
    Int32,
    Sint32,
    Sint64,
    Bool,
    Enum,
    Fixed64,
    Fixed32,
    Sfixed64,
    Sfixed32,
    Double,
    Float,
    Bytes,
    String,
    Pack,
    Message
}

// ~~

class MESSAGE
{
    // -- ATTRIBUTES

    string
        Name;
    long
        FieldIndex;
    MESSAGE_TYPE
        Type;
    ubyte[]
        ByteArray;
    MESSAGE[]
        SubMessageArray;

    // -- CONSTRUCTORS

    this(
        string name = "",
        long field_index = 0,
        MESSAGE_TYPE message_type = MESSAGE_TYPE.Message,
        ubyte[] byte_array = null
        )
    {
        Name = name;
        FieldIndex = field_index;
        Type = message_type;
        ByteArray = byte_array;
    }

    // -- INQUIRIES

    ubyte[] GetUint64ByteArray(
        long field_index,
        ulong natural
        )
    {
        ubyte[]
            byte_array;
        long
            byte_count;

        byte_array = new ubyte[ 11 ];
        byte_array[ 0 ] = cast( ubyte )( field_index << 3 );
        byte_count = 1;

        do
        {
            byte_array[ byte_count ] = 128 | cast( ubyte )( natural & 127 );
            natural >>= 7;
            ++byte_count;
        }
        while ( natural != 0 );

        byte_array[ byte_count - 1 ] &= 127;

        return byte_array[ 0 .. byte_count ];
    }

    // ~~

    ubyte[] GetUint32ByteArray(
        long field_index,
        uint natural
        )
    {
        return GetUint64ByteArray( field_index, cast( ulong )natural );
    }

    // ~~

    ubyte[] GetInt64ByteArray(
        long field_index,
        long integer
        )
    {
        return GetUint64ByteArray( field_index, cast ( ulong )integer );
    }

    // ~~

    ubyte[] GetInt32ByteArray(
        long field_index,
        int integer
        )
    {
        return GetInt64ByteArray( field_index, cast( long )integer );
    }

    // ~~

    ubyte[] GetSint64ByteArray(
        long field_index,
        long integer
        )
    {
        ulong
            natural;

        natural = cast( ulong )integer;

        return GetUint64ByteArray( field_index, ( natural << 1 ) ^ ( natural >> 63 ) );
    }

    // ~~

    ubyte[] GetSint32ByteArray(
        long field_index,
        int integer
        )
    {
        uint
            natural;

        natural = cast( uint )integer;

        return GetUint32ByteArray( field_index, ( natural << 1 ) ^ ( natural >> 31 ) );
    }


    // ~~

    ubyte[] GetBoolByteArray(
        long field_index,
        bool boolean
        )
    {
        return GetUint64ByteArray( field_index, boolean ? 1 : 0 );
    }

    // ~~

    ubyte[] GetFixed64ByteArray(
        long field_index,
        ulong natural
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 1 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&natural )[ 0 .. 8 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetFixed32ByteArray(
        long field_index,
        uint natural
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 5 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&natural )[ 0 .. 4 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetSfixed64ByteArray(
        long field_index,
        long integer
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 1 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&integer )[ 0 .. 8 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetSfixed32ByteArray(
        long field_index,
        int integer
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 5 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&integer )[ 0 .. 4 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetDoubleByteArray(
        long field_index,
        double real_
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 1 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&real_ )[ 0 .. 8 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetFloatByteArray(
        long field_index,
        float real_
        )
    {
        ubyte[]
            byte_array;

        byte_array = new ubyte[ 1 ];
        byte_array[ 0 ] = cast( ubyte )( 5 | ( field_index << 3 ) );
        byte_array ~= ( cast( ubyte * )&real_ )[ 0 .. 4 ];

        return byte_array;
    }

    // ~~

    ubyte[] GetBytesByteArray(
        long field_index,
        ubyte[] bytes
        )
    {
        ubyte[]
            byte_array;

        byte_array = GetUint64ByteArray( field_index, bytes.length ) ~ bytes;
        byte_array[ 0 ] |= 2;

        return byte_array;
    }

    // ~~

    ubyte[] GetStringByteArray(
        long field_index,
        string text
        )
    {
        return GetBytesByteArray( field_index, cast( ubyte[] )text );
    }

    // ~~

    ulong GetNatural(
        )
    {
        long
            byte_index;
        ulong
            bit_index,
            natural;

        natural = 0;

        for ( byte_index = 1;
              byte_index < ByteArray.length;
              ++byte_index )
        {
            bit_index = ( byte_index - 1 ) * 7;

            natural |= ( cast( ulong )( ByteArray[ byte_index ] & 127 ) ) << bit_index;

            if ( ( ByteArray[ byte_index ] & 128 ) == 0 )
            {
                break;
            }
        }

        return natural;
    }

    // ~~

    string GetValueText(
        )
    {
        if ( Type == MESSAGE_TYPE.Uint64
             || Type == MESSAGE_TYPE.Uint32 )
        {
            return GetNatural().to!string();
        }
        else if ( Type == MESSAGE_TYPE.Int64 )
        {
            return ( cast( long )GetNatural() ).to!string();
        }
        else if ( Type == MESSAGE_TYPE.Int32 )
        {
            return ( cast( int )GetNatural() ).to!string();
        }
        else if ( Type == MESSAGE_TYPE.String )
        {
            return ( cast( char[] )ByteArray[ $ - GetNatural() .. $ ] ).to!string().GetQuotedText();
        }
        else
        {
            return "?";
        }
    }

    // ~~

    string GetText(
        long indentation_count = -1
        )
    {
        long
            indentation_index;
        string
            indentation_text,
            text;

        for ( indentation_index = 0;
              indentation_index < indentation_count;
              ++indentation_index )
        {
            indentation_text ~= "  ";
        }

        if ( indentation_count >= 0 )
        {

            text ~= indentation_text ~ FieldIndex.to!string();

            if ( SubMessageArray.length > 0 )
            {
                text ~= " { (" ~ Name ~ ")\n";
            }
            else
            {
                text ~= ": " ~ GetValueText() ~ " " ~ ByteArray.to!string() ~ " (" ~ Name ~ ")\n";
            }
        }

        foreach ( sub_message; SubMessageArray )
        {
            text ~= sub_message.GetText( indentation_count + 1 );
        }

        if ( indentation_count >= 0
             && SubMessageArray.length > 0 )
        {
            text ~= indentation_text ~ "}\n";
        }

        return text;
    }

    // -- OPERATIONS

    void Pack(
        )
    {
        ubyte[]
            byte_array;

        if ( SubMessageArray.length > 0 )
        {
            foreach ( sub_message; SubMessageArray )
            {
                sub_message.Pack();

                byte_array ~= sub_message.ByteArray;
            }

            if ( FieldIndex == 0 )
            {
                ByteArray = byte_array;
            }
            else
            {
                ByteArray = GetBytesByteArray( FieldIndex, byte_array );
            }
        }
    }

    // ~~

    ubyte[] GetByteArray(
        )
    {
        Pack();

        return ByteArray;
    }

    // ~~

    void AddMessage(
        MESSAGE message
        )
    {
        SubMessageArray ~= message;
    }

    // ~~

    void AddMessage(
        string name,
        long field_index,
        MESSAGE_TYPE message_type,
        ubyte[] byte_array
        )
    {
        AddMessage( new MESSAGE( name, field_index, message_type, byte_array ) );
    }

    // ~~

    void AddUint64(
        string name,
        long field_index,
        ulong natural
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Uint64, GetUint64ByteArray( field_index, natural ) );
    }

    // ~~

    void AddUint32(
        string name,
        long field_index,
        uint natural
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Uint32, GetUint32ByteArray( field_index, natural ) );
    }

    // ~~

    void AddInt64(
        string name,
        long field_index,
        long integer
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Int64, GetInt64ByteArray( field_index, integer ) );
    }

    // ~~

    void AddInt32(
        string name,
        long field_index,
        int integer
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Int32, GetInt32ByteArray( field_index, integer ) );
    }

    // ~~

    void AddSint64(
        string name,
        long field_index,
        long integer
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Sint64, GetSint64ByteArray( field_index, integer ) );
    }

    // ~~

    void AddSint32(
        string name,
        long field_index,
        int integer
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Sint32, GetSint32ByteArray( field_index, integer ) );
    }

    // ~~

    void AddDouble(
        string name,
        long field_index,
        double real_
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Double, GetDoubleByteArray( field_index, real_ ) );
    }

    // ~~

    void AddFloat(
        string name,
        long field_index,
        float real_
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Float, GetFloatByteArray( field_index, real_ ) );
    }

    // ~~

    void AddBytes(
        string name,
        long field_index,
        ubyte[] bytes
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.Bytes, GetBytesByteArray( field_index, bytes ) );
    }

    // ~~

    void AddString(
        string name,
        long field_index,
        string text
        )
    {
        AddMessage( name, field_index, MESSAGE_TYPE.String, GetStringByteArray( field_index, text ) );
    }
}

// ~~

class COLUMN
{
    // -- ATTRIBUTES

    string
        Name,
        Value;

    // -- CONSTRUCTORS

    this(
        string name,
        string value
        )
    {
        Name = name;
        Value = value;
    }
}

// ~~

class ROW
{
    // -- ATTRIBUTES

    COLUMN[ string ]
        ColumnMap;
}

// ~~

class TABLE
{
    // -- ATTRIBUTES

    string
        Name;
    ROW[]
        RowArray;

    // -- CONSTRUCTORS

    this(
        string name
        )
    {
        Name = name;
    }
}

// ~~

class PARAMETER
{
    // -- ATTRIBUTES

    string
        Name,
        Value;

    // -- CONSTRUCTORS

    this(
        string name,
        string value
        )
    {
        Name = name;
        Value = value;
    }
}

// ~~

class CARD
{
    // -- ATTRIBUTES

    PARAMETER[]
        ParameterArray;

    // -- CONSTRUCTORS

    this(
        string field_text
        )
    {
        ParseFieldText( field_text );
    }

    // -- INQUIRIES

    PARAMETER GetParameter(
        string parameter_name
        )
    {
        foreach ( parameter; ParameterArray )
        {
            if ( parameter.Name == parameter_name )
            {
                return parameter;
            }
        }

        return null;
    }

    bool HasParameter(
        string parameter_name
        )
    {
        return GetParameter( parameter_name ) !is null;
    }

    string GetCsvLine(
        )
    {
        string
            csv_line;

        csv_line = CsvLineFormat;

        foreach ( parameter; ParameterArray )
        {
            csv_line = csv_line.replace( parameter.Name, parameter.Value );
        }

        return csv_line;
    }

    // -- OPERATIONS

    void ParseFieldText(
        string field_text
        )
    {
        long
            parameter_suffix_character_index;
        string
            parameter_name,
            parameter_prefix,
            parameter_suffix,
            parameter_value;
        string[]
            part_array;
        PARAMETER
            parameter;

        DumpLine( field_text.GetQuotedText(), true );

        part_array = FieldFilter.replace( "{{", "\x1F" ).replace( "}}", "\x1F" ).split( "\x1F" );

        while ( part_array.length >= 3
                && field_text.startsWith( part_array[ 0 ] ) )
        {
            parameter_prefix = part_array[ 0 ];
            parameter_name = "{{" ~ part_array[ 1 ] ~ "}}";
            parameter_suffix = part_array[ 2 ];

            field_text = field_text[ parameter_prefix.length .. $ ];

            if ( parameter_suffix.length == 0 )
            {
                parameter_value = field_text;
                field_text = "";
            }
            else
            {
                parameter_suffix_character_index = field_text.indexOf( parameter_suffix );

                if ( parameter_suffix_character_index >= 0 )
                {
                    parameter_value = field_text[ 0 .. parameter_suffix_character_index ];
                    field_text = field_text[ parameter_suffix_character_index .. $ ];
                }
                else
                {
                    Abort( "Invalid field text" );
                }
            }

            if ( TrimOptionIsEnabled )
            {
                parameter_value = parameter_value.strip();
            }

            DumpLine( "    " ~ parameter_name ~ " : " ~ parameter_value.GetQuotedText(), true );

            parameter = new PARAMETER( parameter_name, parameter_value );
            ParameterArray ~= parameter;

            part_array = part_array[ 2 .. $ ];
        }
    }
}

// ~~

class COLLECTION
{
    // -- ATTRIBUTES

    TABLE
        CardsTable,
        ColTable,
        GravesTable,
        NotesTable,
        RevlogTable;
    CARD[]
        CardArray;

    // -- INQUIRIES

    void WriteCsvFile(
        )
    {
        string
            csv_file_path,
            csv_file_text;

        csv_file_text = "";

        foreach ( card; Collection.CardArray )
        {
            csv_file_text ~= card.GetCsvLine() ~ "\n";
        }

        csv_file_path = OutputFolderPath ~ "collection.csv";
        writeln( "Writing file : " ~ csv_file_path );

        csv_file_path.write( csv_file_text );
    }

    // ~~

    ubyte[] GetImageByteArray(
        CARD card
        )
    {
        return cast( ubyte[] )"JFIF";
    }

    // ~~

    ubyte[] GetMediaByteArray(
        CARD card
        )
    {
        ubyte[]
            image_byte_array,
            media_byte_array;
        uint
            image_count,
            image_size,
            image_type;

        image_count = 1;
        image_size = 0;
        image_type = 0;
        image_byte_array = GetImageByteArray( card );

        media_byte_array ~= ( cast( ubyte * )&image_count )[ 0 .. 4 ];
        media_byte_array ~= ( cast( ubyte * )&image_size )[ 0 .. 4 ];
        media_byte_array ~= ( cast( ubyte * )&image_type )[ 0 .. 4 ];
        media_byte_array ~= image_byte_array;

        return media_byte_array;
    }
    // ~~

    MESSAGE GetWordMessage(
        string name,
        long field_index,
        CARD card
        )
    {
        MESSAGE
            word_message;

        word_message = new MESSAGE( name, field_index );
        word_message.AddInt64( "id", 1, -1 );
        word_message.AddString( "word", 2, "" );
        word_message.AddString( "transc", 3, "" );
        word_message.AddString( "sample", 4, "" );
        word_message.AddString( "comment", 5, "" );
        word_message.AddString( "gender", 7, "" );

        return word_message;
    }

    // ~~

    MESSAGE GetMediaMessage(
        string name,
        long field_index,
        CARD card
        )
    {
        MESSAGE
            media_message;

        media_message = new MESSAGE( name, field_index );
        media_message.AddInt64( "id", 1, -1 );
        media_message.AddBytes( "values", 2, GetMediaByteArray( card ) );
        media_message.AddString( "types", 3, "0" );

        return media_message;
    }

    // ~~

    MESSAGE GetRecordMessage(
        string name,
        long field_index,
        CARD card
        )
    {
        MESSAGE
            record_message;

        record_message = new MESSAGE( name, field_index );
        record_message.AddInt64( "id", 1, -1 );
        record_message.AddInt64( "creation_date", 2, 1 );
        record_message.AddInt64( "last_update_date", 3, 1 );
        record_message.AddMessage( GetWordMessage( "words_1", 4, card ) );
        record_message.AddMessage( GetWordMessage( "words_2", 5, card ) );

        if ( card.HasParameter( "{{image}}" ) )
        {
            record_message.AddMessage( GetMediaMessage( "media", 8, card ) );
        }

        return record_message;
    }

    // ~~

    MESSAGE GetBaseMessage(
        string name,
        long field_index
        )
    {
        MESSAGE
            base_message;

        base_message = new MESSAGE( name, field_index );
        base_message.AddInt32( "id", 1, -1 );
        base_message.AddInt64( "creation_date", 2, 1 );
        base_message.AddString( "lang_names_1", 3, "" );
        base_message.AddString( "lang_names_2", 4, "" );
        base_message.AddInt32( "lang_ids_1", 5, 1 );
        base_message.AddInt32( "lang_ids_2", 6, 2 );
        base_message.AddString( "progress", 11, "0.0" );
        base_message.AddString( "quality", 12, "0.0" );
        base_message.AddInt64( "last_update_date", 13, 1 );
        base_message.AddInt64( "last_statistic_update_date", 14, 1 );

        foreach ( card; Collection.CardArray )
        {
            base_message.AddMessage( GetRecordMessage( "records", 15, card ) );
        }

        return base_message;
    }

    // ~~

    MESSAGE GetDatabaseMessage(
        )
    {
        MESSAGE
            database_message;

        database_message = new MESSAGE();
        database_message.AddMessage( GetBaseMessage( "bases", 1 ) );
        database_message.AddInt32( "version", 6, 4 );

        return database_message;
    }

    // ~~

    void WriteLxfFile(
        )
    {
        string
            dump_file_path,
            lxf_file_path;
        MESSAGE
            database_message;

        database_message = GetDatabaseMessage();

        lxf_file_path = OutputFolderPath ~ "collection.lxf";
        writeln( "Writing file : " ~ lxf_file_path );

        lxf_file_path.write( database_message.GetByteArray() );

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = OutputFolderPath ~ "collection_lexilize.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( database_message.GetText() );
        }
    }

    // -- OPERATIONS

    void ExtractFiles(
        )
    {
        string
            extracted_file_path;
        ZipArchive
            zip_archive;

        writeln( "Reading file : " ~ ApkgFilePath );

        zip_archive = new ZipArchive( ApkgFilePath.read() );

        foreach ( file_name, archive_member; zip_archive.directory )
        {
            extracted_file_path = OutputFolderPath ~ file_name;
            writeln( "Writing file : " ~ extracted_file_path  );

            assert( archive_member.expandedData.length == 0 );
            zip_archive.expand( archive_member );

            assert( archive_member.expandedData.length == archive_member.expandedSize );
            extracted_file_path.write( archive_member.expandedData );
        }
    }

    // ~~

    void RenameMediaFiles(
        )
    {
        string
            media_file_path,
            media_file_text,
            source_file_path,
            target_file_path;
        string[]
            line_array;
        JSONValue
            json_value;

        media_file_path = OutputFolderPath ~ "media";

        writeln( "Reading file : " ~ media_file_path );

        media_file_text = media_file_path.readText();
        json_value = parseJSON( media_file_text );

        foreach ( string key, value; json_value )
        {
            source_file_path = OutputFolderPath ~ key;
            target_file_path = OutputFolderPath ~ value.str;
            writeln( "Renaming file : " ~ source_file_path ~ " => " ~ target_file_path );

            source_file_path.rename( target_file_path );
        }
    }

    // ~~

    void ParseCollection(
        )
    {
        char *
            msg;
        int
            result;
        string
            field_text;
        sqlite3 *
            database;
        string
            dump_file_path,
            database_file_path;
        CARD
            card;

        database_file_path = OutputFolderPath ~ "collection.anki2";
        writeln( "Reading file : " ~ database_file_path );

        result = sqlite3_open( toStringz( database_file_path ), &database );
        msg = null;

        DumpText = "";

        ColTable = new TABLE( "col" );
        NotesTable = new TABLE( "notes" );
        CardsTable = new TABLE( "cards" );
        RevlogTable = new TABLE( "revlog" );
        GravesTable = new TABLE( "graves" );

        Table = ColTable;
        result = sqlite3_exec( database, "select * from col;", &AddRow, null, &msg );

        Table = NotesTable;
        result = sqlite3_exec( database, "select * from notes;", &AddRow, null, &msg );

        Table = CardsTable;
        result = sqlite3_exec( database, "select * from cards;", &AddRow, null, &msg );

        Table = RevlogTable;
        result = sqlite3_exec( database, "select * from revlog;", &AddRow, null, &msg );

        Table = GravesTable;
        result = sqlite3_exec( database, "select * from graves;", &AddRow, null, &msg );

        sqlite3_close(database);

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = OutputFolderPath ~ "collection_anki_tables.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( DumpText );
        }

        DumpText = "";

        foreach ( row; NotesTable.RowArray )
        {
            field_text = row.ColumnMap[ "flds" ].Value.replace( "\x1F", "§" );

            card = new CARD( field_text );
            CardArray ~= card;
        }

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = OutputFolderPath ~ "collection_anki_cards.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( DumpText );
        }
    }

    // ~~

    void ReadApkgFile(
        )
    {
        ExtractFiles();
        RenameMediaFiles();
        ParseCollection();
    }
}

// -- VARIABLES

bool
    CsvOptionIsEnabled,
    DumpOptionIsEnabled,
    LxfOptionIsEnabled,
    TrimOptionIsEnabled,
    VerboseOptionIsEnabled;
string
    ApkgFilePath,
    CsvLineFormat,
    FieldFilter,
    OutputFolderPath,
    DumpText;
COLLECTION
    Collection;
TABLE
    Table;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

string GetQuotedText(
    string text
    )
{
    return
        "\""
        ~ text.replace( "\\", "\\\\" )
              .replace( "\"", "\\\"" )
              .replace( "\t", "\\t" )
              .replace( "\r", "\\r" )
              .replace( "\n", "\\n" )
              .replace( "\x1F", "§" )
        ~ "\"";
}

// ~~

void DumpLine(
    string line,
    bool line_is_printed = false
    )
{
    DumpText ~= line ~ "\n";

    if ( VerboseOptionIsEnabled
         && line_is_printed )
    {
        writeln( line );
    }
}

// ~~

extern(C)
int AddRow(
    void * ,
    int column_count,
    char ** value_array,
    char ** name_array
    )
{
    int
        column_index;
    string
        name,
        value;
    COLUMN
        column;
    ROW
        row;

    DumpLine( Table.Name ~ "[" ~ Table.RowArray.length.to!string() ~ "]" );

    row = new ROW();

    for ( column_index = 0;
          column_index < column_count;
          ++column_index )
    {
        column = new COLUMN( to!string( *name_array ), to!string( *value_array ) );

        ++name_array;
        ++value_array;

        DumpLine( "    " ~ column.Name ~ " : " ~ column.Value.GetQuotedText() );

        row.ColumnMap[ column.Name ] = column;
    }

    Table.RowArray ~= row;

    return 0;
}

// ~~

void ProcessCollection(
    )
{
    Collection = new COLLECTION();
    Collection.ReadApkgFile();

    if ( CsvOptionIsEnabled )
    {
        Collection.WriteCsvFile();
    }

    if ( LxfOptionIsEnabled )
    {
        Collection.WriteLxfFile();
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        option;

    argument_array = argument_array[ 1 .. $ ];

    ApkgFilePath = "";
    OutputFolderPath = "";
    FieldFilter = "";
    TrimOptionIsEnabled = false;
    CsvOptionIsEnabled = false;
    CsvLineFormat = "";
    LxfOptionIsEnabled = false;
    DumpOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--filter"
             && argument_array.length >= 1 )
        {
            FieldFilter = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--trim" )
        {
            TrimOptionIsEnabled = true;
        }
        else if ( option == "--csv"
                  && argument_array.length >= 1 )
        {
            CsvOptionIsEnabled = true;
            CsvLineFormat = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--lxf" )
        {
            LxfOptionIsEnabled = true;
        }
        else if ( option == "--dump" )
        {
            DumpOptionIsEnabled = true;
        }
        else if ( option == "--verbose" )
        {
            VerboseOptionIsEnabled = true;
        }
        else
        {
            Abort( "Invalid option : " ~ option );
        }
    }

    if ( argument_array.length == 2 )
    {
        ApkgFilePath = argument_array[ 0 ];
        OutputFolderPath = argument_array[ 1 ];

        ProcessCollection();
    }
    else
    {
        writeln( "Usage : decker [options] apkg_file_path OUTPUT_FOLDER/" );
        writeln( "Options :" );
        writeln( "    --filter \"filter\"" );
        writeln( "    --trim" );
        writeln( "    --csv \"format\"" );
        writeln( "    --lxf" );
        writeln( "    --dump" );
        writeln( "    --verbose" );
        writeln( "Example :" );
        writeln( "    decker \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );
        writeln( "    decker --field \"<img src=\\\"{{image}}\\\">§{{spanish}}<br/><i>{{english}}</i>\" --trim \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );
        writeln( "    decker --field \"<img src=\\\"{{image}}\\\">§{{spanish}}<br/><i>{{english}}</i>\" --trim --csv \"{{spanish}}|{{english}}|{{image}}\" \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}

