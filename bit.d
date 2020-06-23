/*
    This file is part of the Bit distribution.

    https://github.com/senselogic/BIT

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Bit is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Bit is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Bit.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import core.time : msecs, Duration;
import std.conv : to;
import std.datetime : SysTime;
import std.file : dirEntries, exists, getAttributes, getTimes, mkdir, mkdirRecurse, read, readText, remove, rmdir, setAttributes, setTimes, write, PreserveAttributes, SpanMode;
import std.path : baseName, dirName;
import std.stdio : writeln, File;
import std.string : endsWith, indexOf, join, lastIndexOf, replace, split, startsWith, stripRight, toLower;

// -- TYPES

class FILE
{
    // -- ATTRIBUTES

    string
        Path,
        RelativePath;
    SysTime
        ModificationTime;
    long
        ByteCount;
    bool
        IsFragment;

    // -- INQUIRIES

    void Dump(
        )
    {
        writeln(
            Path,
            ", ",
            RelativePath,
            ", ",
            ModificationTime,
            ", ",
            ByteCount
            );
    }

    // ~~

    string GetBaseRelativePath(
        )
    {
        if ( IsFragment )
        {
            return RelativePath[ 0 .. RelativePath.lastIndexOf( '.' ) ];
        }
        else
        {
            return RelativePath;
        }
    }

    // ~~

    string GetFragmentFilePath(
        long fragment_file_index
        )
    {
        return FragmentFolderPath ~ GetBaseRelativePath() ~ "." ~ fragment_file_index.to!string();
    }

    // ~~

    string GetSourceFilePath(
        )
    {
        return SourceFolderPath ~ GetBaseRelativePath();
    }

    // ~~

    bool IsBaseFragment(
        )
    {
        return IsFragment && Path.endsWith( ".0" );
    }

    // -- OPERATIONS

    void Remove(
        )
    {
        Path.RemoveFile();

        if ( Path.GetFolderPath().IsEmptyFolder() )
        {
            RemoveFolder( Path.GetFolderPath() );
        }
    }

    // ~~

    void Split(
        )
    {
        long
            fragment_index;
        string
            fragment_file_path,
            source_file_path;
        File
            source_file;

        try
        {
            source_file_path = Path;
            writeln( "Reading file : ", source_file_path );

            source_file = File( source_file_path, "r" );
            fragment_index = 0;

            foreach ( fragment_byte_array; source_file.byChunk( FragmentByteCount ) )
            {
                fragment_file_path = GetFragmentFilePath( fragment_index );
                fragment_file_path.WriteByteArray( fragment_byte_array );

                ++fragment_index;
            }

            source_file.close();
        }
        catch ( Exception exception )
        {
            Abort( "Can't split source file : " ~ source_file_path, exception );
        }
    }

    // ~~

    void Join(
        )
    {
        long
            fragment_index;
        string
            fragment_file_path,
            source_file_path;
        ubyte[]
            fragment_byte_array;
        File
            source_file;

        try
        {
            source_file_path = GetSourceFilePath();
            writeln( "Writing file : ", source_file_path );

            source_file = File( source_file_path, "w" );
            for ( fragment_index = 0; true; ++fragment_index )
            {
                fragment_file_path = GetFragmentFilePath( fragment_index );

                if ( fragment_file_path.exists() )
                {
                    fragment_byte_array = fragment_file_path.ReadByteArray();
                    source_file.rawWrite( fragment_byte_array );
                }
                else
                {
                    break;
                }
            }

            source_file.close();
        }
        catch ( Exception exception )
        {
            Abort( "Can't join source file : " ~ source_file_path, exception );
        }
    }
}

// -- VARIABLES

long
    FragmentByteCount;
string
    GitFileComment,
    GitFilePath,
    FragmentFolderPath,
    SourceFolderPath;
FILE[]
    FragmentFileArray,
    SourceFileArray;

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

void Abort(
    string message,
    Exception exception
    )
{
    PrintError( message );
    PrintError( exception.msg );

    exit( -1 );
}

// ~~

long GetByteCount(
    string argument
    )
{
    long
        byte_count,
        unit_byte_count;

    argument = argument.toLower();

    if ( argument == "all" )
    {
        byte_count = long.max;
    }
    else
    {
        if ( argument.endsWith( 'b' ) )
        {
            unit_byte_count = 1;

            argument = argument[ 0 .. $ - 1 ];
        }
        else if ( argument.endsWith( 'k' ) )
        {
            unit_byte_count = 1024;

            argument = argument[ 0 .. $ - 1 ];
        }
        else if ( argument.endsWith( 'm' ) )
        {
            unit_byte_count = 1024 * 1024;

            argument = argument[ 0 .. $ - 1 ];
        }
        else if ( argument.endsWith( 'g' ) )
        {
            unit_byte_count = 1024 * 1024 * 1024;

            argument = argument[ 0 .. $ - 1 ];
        }
        else
        {
            unit_byte_count = 1;
        }

        byte_count = argument.to!long() * unit_byte_count;
    }

    return byte_count;
}

// ~~

string GetLogicalPath(
    string path
    )
{
    return path.replace( "\\", "/" );
}

// ~~

string GetFolderPath(
    string file_path
    )
{
    string
        folder_path;

    folder_path = file_path.dirName();

    if ( folder_path != "" )
    {
        folder_path ~= '/';
    }

    if ( folder_path == "./" )
    {
        folder_path = "";
    }

    return folder_path;
}

// ~~

bool IsEmptyFolder(
    string folder_path
    )
{
    bool
        it_is_empty_folder;

    try
    {
        it_is_empty_folder = true;

        foreach ( folder_entry; dirEntries( folder_path, SpanMode.shallow ) )
        {
            it_is_empty_folder = false;

            break;
        }
    }
    catch ( Exception exception )
    {
        Abort( "Can't read folder : " ~ folder_path, exception );
    }

    return it_is_empty_folder;
}

// ~~

void CreateFolder(
    string folder_path
    )
{
    try
    {
        if ( folder_path != ""
             && folder_path != "/"
             && !folder_path.exists() )
        {
            writeln( "Creating folder : ", folder_path );

            folder_path.mkdirRecurse();
        }
    }
    catch ( Exception exception )
    {
        Abort( "Can't create folder : " ~ folder_path, exception );
    }
}

// ~~

void RemoveFolder(
    string folder_path
    )
{
    writeln( "Removing folder : ", folder_path );

    try
    {
        folder_path.rmdir();
    }
    catch ( Exception exception )
    {
        Abort( "Can't create folder : " ~ folder_path, exception );
    }
}

// ~~

void RemoveFile(
    string file_path
    )
{
    writeln( "Removing file : ", file_path );

    try
    {
        file_path.remove();
    }
    catch ( Exception exception )
    {
        Abort( "Can't remove file : " ~ file_path, exception );
    }
}

// ~~

ubyte[] ReadByteArray(
    string file_path
    )
{
    ubyte[]
        file_byte_array;

    writeln( "Reading file : ", file_path );

    try
    {
        file_byte_array = cast( ubyte[] )file_path.read();
    }
    catch ( Exception exception )
    {
        Abort( "Can't read file : " ~ file_path, exception );
    }

    return file_byte_array;
}

// ~~

void WriteByteArray(
    string file_path,
    ubyte[] file_byte_array
    )
{
    CreateFolder( file_path.GetFolderPath() );

    writeln( "Writing file : ", file_path );

    try
    {
        file_path.write( file_byte_array );
    }
    catch ( Exception exception )
    {
        Abort( "Can't write file : " ~ file_path, exception );
    }
}

// ~~

string ReadText(
    string file_path
    )
{
    string
        file_text;

    writeln( "Reading file : ", file_path );

    try
    {
        file_text = file_path.readText();
    }
    catch ( Exception exception )
    {
        Abort( "Can't read file : " ~ file_path, exception );
    }

    return file_text;
}

// ~~

void WriteText(
    string file_path,
    string file_text
    )
{
    CreateFolder( file_path.GetFolderPath() );

    writeln( "Writing file : ", file_path );

    try
    {
        file_path.write( file_text );
    }
    catch ( Exception exception )
    {
        Abort( "Can't write file : " ~ file_path, exception );
    }
}

// ~~

FILE[] GetFileArray(
    string folder_path,
    bool file_is_fragment,
    string excluded_folder_path = "",
    long minimum_byte_count = 0
    )
{
    string
        file_path;
    FILE
        file;
    FILE[]
        file_array;

    writeln( "Reading folder : ", folder_path );

    try
    {
        foreach ( folder_entry; dirEntries( folder_path, SpanMode.depth ) )
        {
            if ( folder_entry.isFile
                 && !folder_entry.isSymlink
                 && folder_entry.size >= minimum_byte_count )
            {
                file_path = folder_entry.name;

                if ( excluded_folder_path == ""
                     || !file_path.startsWith( excluded_folder_path ) )
                {
                    file = new FILE();
                    file.Path = file_path;
                    file.RelativePath = file_path[ folder_path.length .. $ ];
                    file.ModificationTime = folder_entry.timeLastModified;
                    file.ByteCount = folder_entry.size;
                    file.IsFragment = file_is_fragment;
                    file_array ~= file;
                }
            }
        }
    }
    catch ( Exception exception )
    {
        Abort( "Can't read folder : " ~ folder_path );
    }

    return file_array;
}

// ~~

void ReadFragmentFiles(
    )
{
    CreateFolder( FragmentFolderPath );
    FragmentFileArray = GetFileArray( FragmentFolderPath, true );
}

// ~~

void ReadSourceFiles(
    )
{
    SourceFileArray = GetFileArray( SourceFolderPath, false, FragmentFolderPath, FragmentByteCount + 1 );
}

// ~~

void RemoveFragmentFiles(
    )
{
    ReadFragmentFiles();
    ReadSourceFiles();

    foreach ( fragment_file; FragmentFileArray )
    {
        fragment_file.Remove();
    }
}

// ~~

void WriteGitFile(
    )
{
    string
        git_file_text;

    if ( GitFilePath.exists() )
    {
        git_file_text = GitFilePath.ReadText();
    }

    if ( git_file_text.indexOf( GitFileComment ) >= 0 )
    {
        git_file_text = git_file_text.split( GitFileComment )[ 0 ];
    }

    git_file_text = git_file_text.stripRight();

    if ( git_file_text != "" )
    {
        git_file_text ~= "\n";
    }

    git_file_text ~= GitFileComment ~ "\n";

    foreach ( fragment_file; FragmentFileArray )
    {
        if ( fragment_file.IsBaseFragment() )
        {
            git_file_text ~= fragment_file.GetBaseRelativePath() ~ "\n";
        }
    }

    GitFilePath.WriteText( git_file_text );
}

// ~~

void SplitSourceFiles(
    )
{
    RemoveFragmentFiles();

    foreach ( source_file; SourceFileArray )
    {
        source_file.Split();
    }

    WriteGitFile();
}

// ~~

void JoinFragmentFiles(
    )
{
    ReadFragmentFiles();

    foreach ( fragment_file; FragmentFileArray )
    {
        if ( fragment_file.IsBaseFragment() )
        {
            fragment_file.Join();
        }
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

    SourceFolderPath = "./";
    FragmentFolderPath = SourceFolderPath ~ ".bit/";
    GitFilePath = SourceFolderPath ~ ".gitignore";
    GitFileComment = "# large files";

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--split"
             && argument_array.length >= 1 )
        {
            FragmentByteCount = GetByteCount( argument_array[ 0 ] );
            SplitSourceFiles();

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--join" )
        {
            JoinFragmentFiles();
        }
        else
        {
            Abort( "Invalid option : " ~ option );
        }
    }

    if ( argument_array.length > 0 )
    {
        writeln( "Usage :" );
        writeln( "    bit [options]" );
        writeln( "Options :" );
        writeln( "    --split <size> : find all files larger than `size` in the current folder, split them into fragments inside the `.bit/` folder, and update the `.gitignore` file" );
        writeln( "    --join : rebuild all large files from the fragments stored inside the `.bit/` folder" );
        writeln( "Examples :" );
        writeln( "    bit --split 20m" );
        writeln( "    bit --join" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}