// -- IMPORTS

import core.stdc.stdlib : exit;
import etc.c.sqlite3;
import std.conv;
import std.digest.crc;
import std.file : read, readText, rename, write;
import std.json;
import std.stdio : writefln, writeln;
import std.string : indexOf, replace, split, startsWith, strip, toStringz;
import std.zip;

// -- TYPES

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

        LogLine( field_text.GetQuotedText(), true );

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

            LogLine( "    " ~ parameter_name ~ " : " ~ parameter_value.GetQuotedText(), true );

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
            log_file_path,
            database_file_path;
        CARD
            card;

        database_file_path = OutputFolderPath ~ "collection.anki2";
        writeln( "Reading file : " ~ database_file_path );

        result = sqlite3_open( toStringz( database_file_path ), &database );
        msg = null;

        LogText = "";

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

        foreach ( row; NotesTable.RowArray )
        {
            field_text = row.ColumnMap[ "flds" ].Value.replace( "\x1F", "§" );

            card = new CARD( field_text );
            CardArray ~= card;
        }

        log_file_path = OutputFolderPath ~ "collection.log";
        writeln( "Writing file : " ~ log_file_path );

        log_file_path.write( LogText );
    }

    // ~~

    void ReadApkgFile(
        )
    {
        ExtractFiles();
        RenameMediaFiles();
        ParseCollection();
    }

    // ~~

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
}

// -- VARIABLES

bool
    CsvOptionIsEnabled,
    TrimOptionIsEnabled;
string
    ApkgFilePath,
    CsvLineFormat,
    FieldFilter,
    OutputFolderPath,
    LogText;
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

void LogLine(
    string line,
    bool line_is_printed = false
    )
{
    LogText ~= line ~ "\n";

    if ( line_is_printed )
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

    LogLine( Table.Name ~ "[" ~ Table.RowArray.length.to!string() ~ "]" );

    row = new ROW();

    for ( column_index = 0;
          column_index < column_count;
          ++column_index )
    {
        column = new COLUMN( to!string( *name_array ), to!string( *value_array ) );

        ++name_array;
        ++value_array;

        LogLine( "    " ~ column.Name ~ " : " ~ column.Value.GetQuotedText() );

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
        writeln( "Example :" );
        writeln( "    decker \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );
        writeln( "    decker --field \"<img src=\\\"{{image}}\\\">§{{spanish}}<br/><i>{{english}}</i>\" --trim \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );
        writeln( "    decker --field \"<img src=\\\"{{image}}\\\">§{{spanish}}<br/><i>{{english}}</i>\" --trim --csv \"{{spanish}}|{{english}}|{{image}}\" \"spanish_vocabulary.apkg\" \"SPANISH_VOCABULARY/\"" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}

