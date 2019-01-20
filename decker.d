// -- IMPORTS

import core.stdc.stdlib : exit;
import etc.c.sqlite3;
import std.conv;
import std.digest.crc;
import std.file : exists, read, readText, rename, write;
import std.json;
import std.stdio : writeln;
import std.string : endsWith, indexOf, replace, split, startsWith, strip, toLower, toStringz;
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

class IMAGE
{
    string
        ParameterName,
        FileName,
        FilePath;
    ubyte[]
        ByteArray;
}

// ~~

class CARD
{
    // -- ATTRIBUTES

    PARAMETER[]
        ParameterArray;
    long
        OutputFormatIndex;
    IMAGE[]
        ImageArray;

    // -- CONSTRUCTORS

    this(
        string card_text
        )
    {
        ParseText( card_text );
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

    // ~~

    string GetValue(
        string parameter_name,
        string default_value = ""
        )
    {
        foreach ( parameter; ParameterArray )
        {
            if ( parameter.Name == parameter_name )
            {
                return parameter.Value;
            }
        }

        return default_value;
    }

    // ~~

    bool HasParameter(
        string parameter_name
        )
    {
        return GetParameter( parameter_name ) !is null;
    }

    // ~~

    string GetCsvLine(
        )
    {
        string
            csv_line;

        if ( OutputFormatIndex >= OutputFormatArray.length )
        {
            Abort( "Missing output format : " ~ InputFormatArray[ OutputFormatIndex ] );
        }

        csv_line = OutputFormatArray[ OutputFormatIndex ];

        foreach ( parameter; ParameterArray )
        {
            csv_line = csv_line.replace( "{{" ~ parameter.Name ~ "}}", parameter.Value );
        }

        return csv_line;
    }

    // -- OPERATIONS

    void ParseText(
        string card_text
        )
    {
        long
            parameter_suffix_character_index;
        string
            parameter_name,
            parameter_prefix,
            parameter_suffix,
            parameter_value,
            remaining_card_text;
        string[]
            part_array;
        PARAMETER
            parameter;

        DumpLine( card_text.GetQuotedText(), true );

        if ( InputFormatArray.length > 0 )
        {
            foreach ( input_format_index, input_format; InputFormatArray )
            {
                OutputFormatIndex = input_format_index;
                ParameterArray = null;

                remaining_card_text = card_text;
                part_array = input_format.replace( "{{", "\x1F" ).replace( "}}", "\x1F" ).split( "\x1F" );

                while ( part_array.length >= 3
                        && remaining_card_text.startsWith( part_array[ 0 ] ) )
                {
                    parameter_prefix = part_array[ 0 ];
                    parameter_name = part_array[ 1 ];
                    parameter_suffix = part_array[ 2 ];

                    remaining_card_text = remaining_card_text[ parameter_prefix.length .. $ ];

                    if ( parameter_suffix.length == 0 )
                    {
                        parameter_value = remaining_card_text;
                        remaining_card_text = "";
                    }
                    else
                    {
                        parameter_suffix_character_index = remaining_card_text.indexOf( parameter_suffix );

                        if ( parameter_suffix_character_index >= 0 )
                        {
                            parameter_value = remaining_card_text[ 0 .. parameter_suffix_character_index ];
                            remaining_card_text = remaining_card_text[ parameter_suffix_character_index .. $ ];
                        }
                        else
                        {
                            Abort( "Invalid card text : " ~ card_text );
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

                if ( remaining_card_text.length == 0
                     || ( part_array.length == 1
                          && remaining_card_text == part_array[ 0 ] ) )
                {
                    return;
                }
            }

            Abort( "Invalid card text : " ~ card_text );
        }
    }

    // ~~

    void ReadImage(
        string parameter_name
        )
    {
        string
            image_file_name,
            image_file_path;
        IMAGE
            image;

        if ( HasParameter( parameter_name ) )
        {
            image_file_name = GetValue( parameter_name );
            image_file_path = MediaFolderPath ~ image_file_name;
            writeln( "Reading file : " ~ image_file_path );

            if ( image_file_path.exists() )
            {
                image = new IMAGE();
                image.ParameterName = parameter_name;
                image.FileName = image_file_name;
                image.FilePath = image_file_path;
                image.ByteArray = cast( ubyte[] )image_file_path.read();

                ImageArray ~= image;
            }
            else
            {
                PrintError( "Invalid image file path : " ~ image_file_path );
            }
        }
    }

    // ~~

    void ReadImages(
        )
    {
        ImageArray = null;

        ReadImage( "image" );
        ReadImage( "front_image" );
        ReadImage( "back_image" );
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
            csv_file_text;

        csv_file_text = "";

        foreach ( card; Collection.CardArray )
        {
            csv_file_text ~= card.GetCsvLine() ~ "\n";
        }

        writeln( "Writing file : " ~ OutputFilePath );

        OutputFilePath.write( csv_file_text );
    }

    // ~~

    int GetLanguageId(
        string language_name
        )
    {
        if ( language_name == "" )
        {
            return -1;
        }
        else if ( language_name == "english" )
        {
            return 0;
        }
        else if ( language_name == "french" )
        {
            return 1;
        }
        else if ( language_name == "german" )
        {
            return 2;
        }
        else if ( language_name == "italian" )
        {
            return 3;
        }
        else if ( language_name == "dutch" )
        {
            return 4;
        }
        else if ( language_name == "swedish" )
        {
            return 5;
        }
        else if ( language_name == "spanish" )
        {
            return 6;
        }
        else if ( language_name == "danish" )
        {
            return 7;
        }
        else if ( language_name == "portuguese" )
        {
            return 8;
        }
        else if ( language_name == "norwegian" )
        {
            return 9;
        }
        else if ( language_name == "hebrew" )
        {
            return 10;
        }
        else if ( language_name == "japanese-kanji" )
        {
            return 11;
        }
        else if ( language_name == "arabic" )
        {
            return 12;
        }
        else if ( language_name == "finnish" )
        {
            return 13;
        }
        else if ( language_name == "greek" )
        {
            return 14;
        }
        else if ( language_name == "icelandic" )
        {
            return 15;
        }
        else if ( language_name == "maltese" )
        {
            return 16;
        }
        else if ( language_name == "turkish" )
        {
            return 17;
        }
        else if ( language_name == "croatian" )
        {
            return 18;
        }
        else if ( language_name == "chinese-traditional" )
        {
            return 19;
        }
        else if ( language_name == "urdu" )
        {
            return 20;
        }
        else if ( language_name == "hindi" )
        {
            return 21;
        }
        else if ( language_name == "thai" )
        {
            return 22;
        }
        else if ( language_name == "korean" )
        {
            return 23;
        }
        else if ( language_name == "lithuanian" )
        {
            return 24;
        }
        else if ( language_name == "polish" )
        {
            return 25;
        }
        else if ( language_name == "hungarian" )
        {
            return 26;
        }
        else if ( language_name == "estonian" )
        {
            return 27;
        }
        else if ( language_name == "latvian" )
        {
            return 28;
        }
        else if ( language_name == "sami" )
        {
            return 29;
        }
        else if ( language_name == "faroese" )
        {
            return 30;
        }
        else if ( language_name == "farsi" )
        {
            return 31;
        }
        else if ( language_name == "russian" )
        {
            return 32;
        }
        else if ( language_name == "chinese-simplified" )
        {
            return 33;
        }
        else if ( language_name == "flemish" )
        {
            return 34;
        }
        else if ( language_name == "irish-gaelic" )
        {
            return 35;
        }
        else if ( language_name == "albanian" )
        {
            return 36;
        }
        else if ( language_name == "romanian" )
        {
            return 37;
        }
        else if ( language_name == "czech" )
        {
            return 38;
        }
        else if ( language_name == "slovak" )
        {
            return 39;
        }
        else if ( language_name == "slovenian" )
        {
            return 40;
        }
        else if ( language_name == "yiddish" )
        {
            return 41;
        }
        else if ( language_name == "serbian" )
        {
            return 42;
        }
        else if ( language_name == "macedonian" )
        {
            return 43;
        }
        else if ( language_name == "bulgarian" )
        {
            return 44;
        }
        else if ( language_name == "ukrainian" )
        {
            return 45;
        }
        else if ( language_name == "belarusian" )
        {
            return 46;
        }
        else if ( language_name == "uzbek" )
        {
            return 47;
        }
        else if ( language_name == "kazakh" )
        {
            return 48;
        }
        else if ( language_name == "azerbaijani-cyrillic" )
        {
            return 49;
        }
        else if ( language_name == "azerbaijani-arabic" )
        {
            return 50;
        }
        else if ( language_name == "armenian" )
        {
            return 51;
        }
        else if ( language_name == "georgian" )
        {
            return 52;
        }
        else if ( language_name == "moldavian" )
        {
            return 53;
        }
        else if ( language_name == "kyrgyz" )
        {
            return 54;
        }
        else if ( language_name == "tajik" )
        {
            return 55;
        }
        else if ( language_name == "turkmen" )
        {
            return 56;
        }
        else if ( language_name == "mongolian" )
        {
            return 57;
        }
        else if ( language_name == "mongolian-cyrillic" )
        {
            return 58;
        }
        else if ( language_name == "pashto" )
        {
            return 59;
        }
        else if ( language_name == "kurdish" )
        {
            return 60;
        }
        else if ( language_name == "kashmiri" )
        {
            return 61;
        }
        else if ( language_name == "sindhi" )
        {
            return 62;
        }
        else if ( language_name == "tibetan" )
        {
            return 63;
        }
        else if ( language_name == "nepali" )
        {
            return 64;
        }
        else if ( language_name == "sanskrit" )
        {
            return 65;
        }
        else if ( language_name == "marathi" )
        {
            return 66;
        }
        else if ( language_name == "bengali" )
        {
            return 67;
        }
        else if ( language_name == "assamese" )
        {
            return 68;
        }
        else if ( language_name == "gujarati" )
        {
            return 69;
        }
        else if ( language_name == "punjabi" )
        {
            return 70;
        }
        else if ( language_name == "oriya" )
        {
            return 71;
        }
        else if ( language_name == "malayalam" )
        {
            return 72;
        }
        else if ( language_name == "kannada" )
        {
            return 73;
        }
        else if ( language_name == "tamil" )
        {
            return 74;
        }
        else if ( language_name == "telugu" )
        {
            return 75;
        }
        else if ( language_name == "sinhalese" )
        {
            return 76;
        }
        else if ( language_name == "burmese" )
        {
            return 77;
        }
        else if ( language_name == "khmer" )
        {
            return 78;
        }
        else if ( language_name == "lao" )
        {
            return 79;
        }
        else if ( language_name == "vietnamese" )
        {
            return 80;
        }
        else if ( language_name == "indonesian" )
        {
            return 81;
        }
        else if ( language_name == "tagalog" )
        {
            return 82;
        }
        else if ( language_name == "malay-roman" )
        {
            return 83;
        }
        else if ( language_name == "malay-arabic" )
        {
            return 84;
        }
        else if ( language_name == "amharic" )
        {
            return 85;
        }
        else if ( language_name == "tigrinya" )
        {
            return 86;
        }
        else if ( language_name == "galla" )
        {
            return 87;
        }
        else if ( language_name == "somali" )
        {
            return 88;
        }
        else if ( language_name == "swahili" )
        {
            return 89;
        }
        else if ( language_name == "kinyarwanda" )
        {
            return 90;
        }
        else if ( language_name == "rundi" )
        {
            return 91;
        }
        else if ( language_name == "nyanja-chewa" )
        {
            return 92;
        }
        else if ( language_name == "malagasy" )
        {
            return 93;
        }
        else if ( language_name == "esperanto" )
        {
            return 94;
        }
        else if ( language_name == "welsh" )
        {
            return 128;
        }
        else if ( language_name == "basque" )
        {
            return 129;
        }
        else if ( language_name == "catalan" )
        {
            return 130;
        }
        else if ( language_name == "latin" )
        {
            return 131;
        }
        else if ( language_name == "quenchua" )
        {
            return 132;
        }
        else if ( language_name == "guarani" )
        {
            return 133;
        }
        else if ( language_name == "aymara" )
        {
            return 134;
        }
        else if ( language_name == "tatar" )
        {
            return 135;
        }
        else if ( language_name == "uighur" )
        {
            return 136;
        }
        else if ( language_name == "dzongkha" )
        {
            return 137;
        }
        else if ( language_name == "javanese-roman" )
        {
            return 138;
        }
        else if ( language_name == "sundanese-roman" )
        {
            return 139;
        }
        else if ( language_name == "galician" )
        {
            return 140;
        }
        else if ( language_name == "afrikaans" )
        {
            return 141;
        }
        else if ( language_name == "breton" )
        {
            return 142;
        }
        else if ( language_name == "inuktitut" )
        {
            return 143;
        }
        else if ( language_name == "scottish-gaelic" )
        {
            return 144;
        }
        else if ( language_name == "manx-gaelic" )
        {
            return 145;
        }
        else if ( language_name == "irish-gaelic-dot-above" )
        {
            return 146;
        }
        else if ( language_name == "tongan" )
        {
            return 147;
        }
        else if ( language_name == "greek-polytonic" )
        {
            return 148;
        }
        else if ( language_name == "greenlandic" )
        {
            return 149;
        }
        else if ( language_name == "azerbaijani-roman" )
        {
            return 150;
        }
        else if ( language_name == "japanese-kana" )
        {
            return 151;
        }
        else if ( language_name == "bosnian" )
        {
            return 152;
        }
        else if ( language_name == "chess" )
        {
            return 200;
        }
        else if ( language_name == "history" )
        {
            return 201;
        }
        else if ( language_name == "dates" )
        {
            return 202;
        }
        else if ( language_name == "mathematics" )
        {
            return 203;
        }
        else if ( language_name == "music" )
        {
            return 204;
        }
        else if ( language_name == "physics" )
        {
            return 205;
        }
        else if ( language_name == "geography" )
        {
            return 206;
        }
        else if ( language_name == "medicine" )
        {
            return 207;
        }
        else
        {
            Abort( "Invalid language name : " ~ language_name );

            return -1;
        }
    }

    // ~~

    ubyte[] GetMediaByteArray(
        CARD card
        )
    {
        ubyte[]
            media_byte_array;
        uint
            image_count,
            image_size,
            image_type;

        image_count = card.ImageArray.length.to!uint();
        media_byte_array ~= ( cast( ubyte * )&image_count )[ 0 .. 4 ];

        foreach ( image; card.ImageArray )
        {
            image_size = image.ByteArray.length.to!uint();
            media_byte_array ~= ( cast( ubyte * )&image_size )[ 0 .. 4 ];
        }

        image_type = 0;

        foreach ( image; card.ImageArray )
        {
            media_byte_array ~= ( cast( ubyte * )&image_type )[ 0 .. 4 ];
        }

        foreach ( image; card.ImageArray )
        {
            media_byte_array ~= image.ByteArray;
        }

        return media_byte_array;
    }

    // ~~

    MESSAGE GetWordMessage(
        string name,
        long field_index,
        CARD card,
        string prefix
        )
    {
        MESSAGE
            word_message;

        word_message = new MESSAGE( name, field_index );
        word_message.AddInt64( "id", 1, -1 );
        word_message.AddString( "word", 2, card.GetValue( prefix ~ "_word" ) );
        word_message.AddString( "transc", 3, card.GetValue( prefix ~ "_transcription" ) );
        word_message.AddString( "sample", 4, card.GetValue( prefix ~ "_sample" ) );
        word_message.AddString( "comment", 5, card.GetValue( prefix ~ "_comment" ) );
        word_message.AddString( "gender", 7, card.GetValue( prefix ~ "_gender" ) );

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
        record_message.AddMessage( GetWordMessage( "words_1", 4, card, "front" ) );
        record_message.AddMessage( GetWordMessage( "words_2", 5, card, "back" ) );

        card.ReadImages();

        if ( card.ImageArray.length > 0 )
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
        base_message.AddString( "lang_names_1", 3, FrontTitle );
        base_message.AddString( "lang_names_2", 4, FrontTitle );
        base_message.AddInt32( "lang_ids_1", 5, GetLanguageId( FrontLanguageName ) );
        base_message.AddInt32( "lang_ids_2", 6, GetLanguageId( BackLanguageName ) );
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

    MESSAGE GetMessage(
        )
    {
        MESSAGE
            message;

        message = new MESSAGE();
        message.AddMessage( GetBaseMessage( "bases", 1 ) );
        message.AddInt32( "version", 6, 4 );

        return message;
    }

    // ~~

    void WriteLxfFile(
        )
    {
        string
            dump_file_path;
        MESSAGE
            message;

        message = GetMessage();

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = DumpFolderPath ~ "dump_lexilize.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( message.GetText() );
        }

        writeln( "Writing file : " ~ OutputFilePath );

        OutputFilePath.write( message.GetByteArray() );
    }

    // -- OPERATIONS

    void ReadCsvFile(
        )
    {
        string
            dump_file_path;
        string[]
            line_array;
        CARD
            card;

        writeln( "Reading file : " ~ InputFilePath );

        line_array = InputFilePath.readText().replace( "\r", "" ).split( "\n" );

        DumpText = "";

        foreach ( line; line_array )
        {
            if ( line.strip().length > 0 )
            {
                card = new CARD( line );
                CardArray ~= card;
            }
        }

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = DumpFolderPath ~ "dump_csv.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( DumpText );
        }
    }

    // ~~

    void ExtractFiles(
        )
    {
        string
            extracted_file_path;
        ZipArchive
            zip_archive;

        writeln( "Reading file : " ~ InputFilePath );

        zip_archive = new ZipArchive( InputFilePath.read() );

        foreach ( file_name, archive_member; zip_archive.directory )
        {
            extracted_file_path = MediaFolderPath ~ file_name;
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
            front_file_path,
            back_file_path;
        string[]
            line_array;
        JSONValue
            json_value;

        media_file_path = MediaFolderPath ~ "media";

        writeln( "Reading file : " ~ media_file_path );

        media_file_text = media_file_path.readText();
        json_value = parseJSON( media_file_text );

        foreach ( string key, value; json_value )
        {
            front_file_path = MediaFolderPath ~ key;
            back_file_path = MediaFolderPath ~ value.str;
            writeln( "Renaming file : " ~ front_file_path ~ " => " ~ back_file_path );

            front_file_path.rename( back_file_path );
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
            card_text;
        sqlite3 *
            database;
        string
            dump_file_path,
            database_file_path;
        CARD
            card;

        database_file_path = MediaFolderPath ~ "collection.anki2";
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
            dump_file_path = DumpFolderPath ~ "dump_anki_database.txt";
            writeln( "Writing file : " ~ dump_file_path );

            dump_file_path.write( DumpText );
        }

        DumpText = "";

        foreach ( row; NotesTable.RowArray )
        {
            card_text = row.ColumnMap[ "flds" ].Value.replace( "\x1F", "§" );

            card = new CARD( card_text );
            CardArray ~= card;
        }

        if ( DumpOptionIsEnabled )
        {
            dump_file_path = DumpFolderPath ~ "dump_anki.txt";
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
    DumpOptionIsEnabled,
    TrimOptionIsEnabled,
    VerboseOptionIsEnabled;
string
    BackLanguageName,
    BackTitle,
    DumpFolderPath,
    DumpText,
    FrontLanguageName,
    FrontTitle,
    InputFilePath,
    MediaFolderPath,
    OutputFilePath;
string[]
    InputFormatArray,
    OutputFormatArray;
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

    if ( InputFilePath.endsWith( ".csv" ) )
    {
        Collection.ReadCsvFile();
    }
    else if ( InputFilePath.endsWith( ".apkg" ) )
    {
        Collection.ReadApkgFile();
    }

    if ( OutputFilePath.endsWith( ".csv" ) )
    {
        Collection.WriteCsvFile();
    }
    else if ( OutputFilePath.endsWith( ".lxf" ) )
    {
        Collection.WriteLxfFile();
    }
}

// ~~

bool HasValidInputExtension(
    string input_file_path
    )
{
    return
         input_file_path.endsWith( ".csv" )
         || input_file_path.endsWith( ".apkg" );
}

// ~~

bool HasValidOutputExtension(
    string output_file_path
    )
{
    return
         output_file_path.endsWith( ".csv" )
         || output_file_path.endsWith( ".lxf" );
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        option;

    argument_array = argument_array[ 1 .. $ ];

    FrontTitle = "";
    BackTitle = "";
    FrontLanguageName = "";
    BackLanguageName = "";
    InputFormatArray = null;
    OutputFormatArray = null;
    MediaFolderPath = "";
    DumpFolderPath = "";
    TrimOptionIsEnabled = false;
    DumpOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;
    InputFilePath = "";
    OutputFilePath = "";

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--front_title"
                  && argument_array.length >= 1 )
        {
            FrontTitle ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--back_title"
                  && argument_array.length >= 1 )
        {
            BackTitle ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--front_language"
                  && argument_array.length >= 1 )
        {
            FrontLanguageName ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--back_language"
                  && argument_array.length >= 1 )
        {
            BackLanguageName ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--input_format"
                  && argument_array.length >= 1 )
        {
            InputFormatArray ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--output_format"
                  && argument_array.length >= 1 )
        {
            OutputFormatArray ~= argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--media_folder"
                  && argument_array.length >= 1 )
        {
            MediaFolderPath = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--dump_folder"
                  && argument_array.length >= 1 )
        {
            DumpFolderPath = argument_array[ 0 ];
            DumpOptionIsEnabled = true;

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--trim" )
        {
            TrimOptionIsEnabled = true;
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

    if ( argument_array.length == 1
         && argument_array[ 0 ].HasValidInputExtension() )
    {
        InputFilePath = argument_array[ 0 ];

        ProcessCollection();
    }
    else if ( argument_array.length == 2
         && argument_array[ 0 ].HasValidInputExtension()
         && argument_array[ 1 ].HasValidOutputExtension() )
    {
        InputFilePath = argument_array[ 0 ];
        OutputFilePath = argument_array[ 1 ];

        ProcessCollection();
    }
    else
    {
        writeln( "Usage : decker [options] input_file_path output_file_path" );
        writeln( "Options :" );
        writeln( "    --front_title \"title\"" );
        writeln( "    --back_title \"title\"" );
        writeln( "    --front_language \"language\"" );
        writeln( "    --back_language \"language\"" );
        writeln( "    --input_format \"format\"" );
        writeln( "    --output_format \"format\"" );
        writeln( "    --media_folder MEDIA_FOLDER/" );
        writeln( "    --dump_folder DUMP_FOLDER/" );
        writeln( "    --trim" );
        writeln( "    --verbose" );
        writeln( "Examples :" );
        writeln( "    decker --media_folder \"SPANISH_VOCABULARY/\" --dump_folder \"SPANISH_VOCABULARY/\" --verbose \"spanish_vocabulary.apkg\"" );
        writeln( "    decker --input_format \"<img src=\\\"{{front_image}}\\\">§{{front_word}}<br/><i>{{back_word}}</i>\" --media_folder \"SPANISH_VOCABULARY/\" --dump_folder \"SPANISH_VOCABULARY/\" --trim --verbose \"spanish_vocabulary.apkg\"" );
        writeln( "    decker --input_format \"<img src=\\\"{{front_image}}\\\">§{{front_word}}<br/><i>{{back_word}}</i>\" --media_folder \"SPANISH_VOCABULARY/\" --trim \"spanish_vocabulary.apkg\" \"spanish_vocabulary.lxf\"" );
        writeln( "    decker --input_format \"<img src=\\\"{{front_image}}\\\">§{{front_word}}<br/><i>{{back_word}}</i>\" --output_format \"{{front_word}}|{{back_word}}|{{front_image}}\" --trim \"spanish_vocabulary.apkg\" \"spanish_vocabulary.csv\"" );
        writeln( "    decker --input_format \"{{front_word}}|{{back_word}}|{{front_image}}\" --media_folder \"SPANISH_VOCABULARY/\" --trim \"spanish_vocabulary.csv\" \"spanish_vocabulary.lxf\"" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}

