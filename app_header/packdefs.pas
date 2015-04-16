unit packdefs;       {Structures and headers for unzip, unarj and unlzh} 

interface

type {$ifdef win32}
     TDirtype=array[0..259] of char;
     {$else}
     TDirtype=array[0..79] of char;
     {$endif}
     TPackRec=packed record
       internal:array[0..11] of byte;  {Used internally by the dll}
       Time,                     {file time}
       Size,                     {file size}
       CompressSize,             {size in zipfile}
       headeroffset,             {file offset in zip: needed in unzipfile}
       CRC: Longint;             {CRC, sort of checksum}
       FileName: tdirtype;       {file name}
       PackMethod,               {pack method, see below}
       Attr,                     {file attribute}
       Flags:word;               {lo byte: arj_flags; hi byte: file_type}
     end;

const zip_ok=0;
      zip_FileError=-1;        {Error reading zip file}
      zip_InternalError=-2;    {Error in zip file format}
      zip_NoMoreItems=1;       {Everything read}

const   {Error codes, delivered by unarjfile}
  unzip_Ok=0;               {Unpacked ok}
  unzip_CRCErr=1;           {CRC error}
  unzip_WriteErr=2;         {Error writing out file: maybe disk full} 
  unzip_ReadErr=3;          {Error reading zip file}
  unzip_ZipFileErr=4;       {Error in zip structure}  
  unzip_UserAbort=5;        {Aborted by user}
  unzip_NotSupported=6;     {ZIP Method not supported!}
  unzip_Encrypted=7;        {Zipfile encrypted}
  unzip_InUse=-1;           {DLL in use by other program!}
  unzip_DLLNotFound=-2;     {DLL not loaded!}

implementation

end.