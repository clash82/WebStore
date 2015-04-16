{Include file for unzip.pas: global constants, types and variables}

{C code by info-zip group, translated to pascal by Christian Ghisler}
{based on unz51g.zip}

//const   {Variables for output directly to memory}
var
  global_byteswritten:longint=0;
  global_tomemory:boolean=false;
  global_crconly:boolean=false;
  global_outbuf:pointer=nil;
  global_bufsize:longint=0;

const   {Error codes returned by huft_build}
  huft_complete=0;     {Complete tree}
  huft_incomplete=1;   {Incomplete tree <- sufficient in some cases!}
  huft_error=2;        {bad tree constructed}
  huft_outofmem=3;     {not enough memory}

const wsize=$8000;          {Size of sliding dictionary}
      INBUFSIZ=2048;        {Size of input buffer}

const lbits:shortint=9;
      dbits:shortint=6;

const b_max=16;
      n_max=288;
      BMAX=16;

type push=^ush;
     ush=word;
     pbyte=^byte;
     pushlist=^ushlist;
     ushlist=array[0..32767-1] of ush;  {only pseudo-size!!}
     pword=^word;
     pwordarr=^twordarr;
     twordarr=array[0..32767-1] of word;
     iobuf=array[0..inbufsiz-1] of byte;
type pphuft=^phuft;
     phuft=^huft;
     phuftlist=^huftlist;
     huft=packed record
       e,             {# of extra bits}
       b:byte;        {# of bits in code}
       v_n:ush;
       v_t:phuftlist; {Linked List}
     end;
     huftlist=array[0..8190] of huft;
type li=record
       lo,hi:word;
     end;

{pkzip header in front of every file in archive}
type
  plocalheader=^tlocalheader;
  tlocalheader=record
    signature:array[0..3] of char;  {'PK'#1#2}
    extract_ver,
    bit_flag,
    zip_type:word;
    file_timedate:longint;
    crc_32,
    compress_size,
    uncompress_size:longint;
    filename_len,
    extra_field_len:word;
  end;

var slide:pchar=nil;      {Sliding dictionary for unzipping} 

var inbuf:iobuf;            {input buffer}
    inpos:short;            {position in input buffer}
    readpos:integer;        {position read from file}
    dlghandle:thandle;      {optional: handle of a cancel and "%-done"-dialog}
    dlgnotify:short;        {notification code to tell dialog how far the decompression is}

var w:word;                 {Current Position in slide}
    b:longint;              {Bit Buffer}
    k:byte;                 {Bits in bit buffer}
    infile,                 {handle to zipfile}
    outfile:file;           {handle to extracted file}
    compsize,               {comressed size of file}
    reachedsize,            {number of bytes read from zipfile}
    uncompsize:longint;     {uncompressed size of file}
    oldpercent:short;       {last percent value shown}
    crc32val:longint;       {crc calculated from data}
    hufttype:word;          {coding type=bit_flag from header}
    totalabort,             {User pressed abort button, set in showpercent!}
    zipeof:boolean;         {read over end of zip section for this file}

    lastusedtime:longint=0; {Time of last usage in timer ticks for timeout!}
    inuse:boolean=false;    {is unit already in use -> don't call it again!!!}
//      lastusedtime:longint=0; {Time of last usage in timer ticks for timeout!}
