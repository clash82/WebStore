unit ZipRead;         {Warning, new Structure tPackRec, the same for all packers!}

{$R-}   {no range checking!}

interface
uses packdefs, messages, sysutils;

type pHeaderInfo = ^tHeaderInfo;    {EXE-Header}
     tHeaderInfo = packed Record
                    ExeId : Array[0..1] Of Char;
                    Remainder,
                    size : Word
                  End;

type buftype=array[0..65000] of char;
type {$ifdef win32}
     TDirtype=array[0..259] of char;
     {$else}
     TDirtype=array[0..79] of char;
     {$endif}
     TPackRec=packed record
       buf:^buftype;          {please}         {buffer containing central dir}
       bufsize,       {do not}         {size of buffer}
       localstart,       {change these!}  {start pos in buffer}
       globalpos:longint;                      {Position in packed file}

       Time,                                   {From here: user data!}
       Size,
       CompressSize,
       headeroffset,
       CRC: Longint;
       FileName: tdirtype;
       PackMethod,
       Attr,
       flags: word;
     end;

const zip_ok=0;
      zip_FileError=-1;        {Accessing file}
      zip_InternalError=-2;    {Error in zip format}
      zip_NoMoreItems=1;
      zip_inuse=-10;

function GetFirstInZip(zipfilename:pchar;startoffset:integer;var zprec:tPackRec):integer;
function GetNextInZip(var Zprec:tPackRec):integer;
function isZip(filename:pchar):boolean;
procedure CloseZipFile(var Zprec:tPackRec);  {Only free buffer, file only open in Getfirstinzi}

implementation

const mainheader:pchar='PK'#5#6;
      maxbufsize=64000;  {Can be as low as 500 Bytes; however, }
                         {this would lead to extensive disk reading!}
                         {If one entry (including Extra field) is bigger}
                         {than maxbufsize, you cannot read it :-( }

type
  pheader=^theader;
  pmainheader=^tmainheader;
  tmainheader=packed record
    signature:array[0..3] of char;  {'PK'#5#6}
    thisdisk,
    centralstartdisk,
    entries_this_disk,
    entries_central_dir:word;
    headsize,
    headstart:longint;
    comment_len:longint;
    unknown:word;
  end;
  theader=packed record
    signature:array[0..3] of char;  {'PK'#1#2}
    OSversion,      {Operating system version}
    OSmadeby:byte;  {MSDOS (FAT): 0}
    extract_ver,
    bit_flag,
    zip_type:word;
    file_timedate:longint;
    crc_32,
    compress_size,
    uncompress_size:longint;
    filename_len,
    extra_field_len,
    file_comment_len,
    disk_number_start,
    internal_attr:word;
    external_attr:array[0..3] of byte;
    offset_local_header:longint;
  end;
var
  ZIPOffset: integer;

{*********** Fill out tZipRec structure with next entry *************}

function filloutRec(var zprec:tPackRec):integer;
var p:pchar;
    incr:longint;
    header:pheader;
    offs:word;
    old:char;
    f:file;
    extra:word;
    {$ifdef win32}
    err:integer;
    {$else}
    err:word;
    {$endif}

begin
 with zprec do begin
  header:=pheader(@buf^[localstart]);
  if (bufsize=maxbufsize) then begin       {Caution: header bigger than 64k!}
    extra:=sizeof(file);
    if ((localstart+sizeof(theader))>bufsize) or
      (localstart+header^.filename_len+header^.extra_field_len+sizeof(theader)>bufsize)
      then begin     {Read over end of header}
        move(buf^[bufsize+1],f,extra);   {Restore file}
        move(buf^[localstart],buf^[0],bufsize-localstart);  {Move end to beginning in buffer}
        {$I-}
        blockread(f,buf^[bufsize-localstart],localstart,err);  {Read in full central dir, up to maxbufsize Bytes}
        {$I+}
        if (ioresult<>0) or (err+localstart<sizeof(theader)) then begin
          filloutrec:=zip_nomoreitems;
          exit
        end;
        move(f,buf^[bufsize+1],extra);  {Save changed file info!}
        localstart:=0;
        header:=pheader(@buf^[localstart]);
      end;
  end;
  if (localstart+4<=bufsize) and   {Here is the ONLY correct finish!}
    (strlcomp(header^.signature,mainheader,4)=0) then begin  {Main header}
    filloutrec:=zip_nomoreitems;
    exit
  end;
  if (localstart+sizeof(header)>bufsize) or
    (localstart+header^.filename_len+header^.extra_field_len+
      sizeof(theader)>bufsize) or
    (strlcomp(header^.signature,'PK'#1#2,4)<>0) then begin
    filloutrec:=zip_nomoreitems;
    exit
  end;
  size:=header^.uncompress_size;
  compressSize:=header^.compress_size;
  if header^.osmadeby=0 then
    attr:=header^.external_attr[0]
  else
    attr:=0;
  time:=header^.file_timedate;
  crc:=header^.crc_32;
  flags:=header^.bit_flag;
  headeroffset:=header^.offset_local_header+ZIPOffset; {Other header size}
  Packmethod:=header^.zip_type;
  offs:=localstart+header^.filename_len+sizeof(header^);
  old:=buf^[offs];
  buf^[offs]:=#0;  {Repair signature of next block!}
  strlcopy(filename,pchar(@buf^[localstart+sizeof(header^)]),sizeof(filename)-1);
  buf^[offs]:=old;
  repeat           {Convert slash to backslash!}
    p:=strscan(filename,'/');
    if p<>nil then p[0]:='\';
  until p=nil;
  {$ifdef windows}
  oemtoansi(filename,filename);
  {$endif}

  incr:=header^.filename_len+header^.extra_field_len+sizeof(header^);
  if incr<=0 then begin
    filloutrec:=zip_InternalError;
    exit
  end;
  localstart:=localstart+incr;
  filloutrec:=zip_ok;
 end;
end;

{**************** Get first entry from ZIP file ********************}

function GetFirstInZip(zipfilename:pchar;startoffset:integer;var zprec:tPackRec):integer;
var bufstart,headerstart,start:longint;
    err,i:integer;
    mainh:pmainheader;
    f:file;
    extra:word;   {Extra bytes for saving File!}

begin
 ZIPOffset:=startoffset;
 with zprec do begin
  assign(f,zipfilename);
  filemode:=0;  {Others may read or write};
  {$I-}
  reset(f,1);
  {$I+}
  if ioresult<>0 then begin
    GetFirstInZip:=zip_FileError;
    exit
  end;
  size:=filesize(f);
  if size=0 then begin
    GetFirstInZip:=zip_FileError;
    {$I-}
    close(f);
    {$I+}
    exit
  end;
  bufsize:=4096;     {in 4k-blocks}
  if size>bufsize then begin
    bufstart:=size-bufsize;
  end else begin
    bufstart:=0;
    bufsize:=size;
  end;
  getmem(buf,bufsize+1);     {#0 at the end of filemname}

  {Search from back of file to central directory start}
  start:=-1;    {Nothing found}
  repeat
    {$I-}
    seek(f,bufstart);
    {$I+}
    if ioresult<>0 then begin
      GetFirstInZip:=zip_FileError;
      freeMem(buf,bufsize+1);
      buf:=nil;
      {$I-}
      close(f);
      {$I+}
      exit
    end;
    {$I-}
    blockread(f,buf^,bufsize,err);
    {$I+}
    if (ioresult<>0) or (err<>bufsize) then begin
      GetFirstInZip:=zip_FileError;
      freeMem(buf,bufsize+1);
      buf:=nil;
      {$I-}
      close(f);
      {$I+}
      exit
    end;
    if bufstart=0 then start:=maxlongint;{Break}
    for i:=bufsize-22 downto 0 do        {Search buffer backwards}
      if (buf^[i]='P') and (buf^[i+1]='K') and (buf^[i+2]=#5) and (buf^[i+3]=#6)
      then begin                         {Header found!!!}
        start:=bufstart+i;
        {$ifdef win32}
        break;
        {$else}
        i:=0;
        {$endif}
      end;
    if start=-1 then begin               {Nothing found yet}
      dec(bufstart,bufsize-22);          {Full header in buffer!}
      if bufstart<0 then bufstart:=0;
    end;
  until start>=0;
  if (start=maxlongint) then begin       {Nothing found}
    GetFirstInZip:=zip_FileError;
    freeMem(buf,bufsize+1);
    buf:=nil;
    {$I-}
    close(f);
    {$I+}
    exit
  end;
  mainh:=pmainheader(@buf^[start-bufstart]);
  headerstart:=mainh^.headstart;
  localstart:=0;
  freeMem(buf,bufsize+1);
  if (localstart+sizeof(theader)>start) then begin
    buf:=nil;
    GetFirstInZip:=zip_InternalError;
    {$I-}close(f);{$I+}
    exit
  end;
  bufstart:=headerstart;
  bufsize:=start-headerstart+4; {size for central dir,Including main header signature}
  if bufsize>=maxbufsize then begin
    bufsize:=maxbufsize; {Max buffer size, limit of around 1000 items!}
    extra:=sizeof(file); {Save file information for later reading!}
  end else extra:=0;
  getmem(buf,bufsize+1+extra);
  {$I-}
  seek(f,bufstart+ZIPOffset);
  {$I+}
  if ioresult<>0 then begin
    GetFirstInZip:=zip_FileError;
    freeMem(buf,bufsize+1+extra);
    buf:=nil;
    exit
  end;
  {$I-}
  blockread(f,buf^,bufsize,err);  {Read in full central dir, up to maxbufsize Bytes}
  {$I+}
  if ioresult<>0 then begin
    GetFirstInZip:=zip_FileError;
    freeMem(buf,bufsize+1+extra);
    buf:=nil;
    {$I-}
    close(f);
    {$I+}
    exit
  end;
  if extra=0 then
  {$I-} close(f) {$I+}
    else move(f,buf^[bufsize+1],extra);  {Save file info!}
  err:=filloutRec(zprec);
  if err<>zip_ok then CloseZipFile(zprec);
  GetFirstInZip:=err;
 end;
end;

{**************** Get next entry from ZIP file ********************}

function GetNextInZip(var Zprec:tPackrec):integer;
var err:integer;
begin
 with zprec do begin
  if (buf<>nil) then begin  {Main Header at the end}
    err:=filloutRec(zprec);
    if err<>zip_ok then begin
      CloseZipFile(ZPRec);
    end;
    GetNextInZip:=err;
  end else GetNextInZip:=zip_InternalError;
 end
end;

function SetTheDir(thedir:pchar):integer;
begin
  {$ifdef win32}
  {$i-}chdir(strpas(thedir));{$i+}
  SetTheDir:=ioresult;
  {$else}
  {$ifdef windows}
  {$ifdef ver80}
  {$i-}chdir(strpas(thedir));{$i+}
  SetTheDir:=ioresult;
  {$else}
  setcurdir(thedir);
  SetTheDir:=doserror;
  {$endif}
  {$else}
  {$i-}chdir(strpas(thedir));{$i+}
  SetTheDir:=ioresult;
  {$endif}
  {$endif}
end;

{**************** VERY simple test for zip file ********************}

function isZip(filename:pchar):boolean;
type buftype=array[0..9] of char;
     sfxheader=packed record
                 HeadID,Sig1:word;
               end;
     psfxheader=^sfxheader;

var myname:tdirtype;
    l,err:integer;
    f:file;
    buf:buftype;

  function CheckifSFX(var buf:buftype;var f:file):boolean;
  var ph:psfxheader;
      {$ifdef win32}
      rd:integer;
      {$else}
      rd:word;
      {$endif}
      AOffset:longint;

  begin
    CheckifSfx:=false;
    AOffset := LongInt(PHeaderInfo(@buf)^.size-1)*512+PHeaderInfo(@Buf)^.Remainder;
    if PHeaderInfo(@Buf)^.Remainder=0 then inc(AOffset,512); {Special case!}
    {$I-}
    Seek(f, AOffset);
    {$I+}
    If IoResult > 0 Then Exit;
    {$I-}
    BlockRead(f,buf,SizeOf(buf),rd);
    {$I+}
    if (IoResult > 0) Or (rd < SizeOf(sfxheader)) then exit;
    ph:=@buf;
    if (AOffset>0) then begin
      if (ph^.HeadId=$4B50) and (ph^.Sig1=$0403) or
      (psfxheader(@buf[1])^.HeadId=$4B50) and (psfxheader(@buf[1])^.Sig1=$0403)
      then CheckIfSfx:=true;
    end;
  end;

begin
  filemode:=0;
  isZip:=false;
  if (strscan(filename,'.')<>nil) then begin
    strcopy(myname,filename);
    l:=strlen(myname);
    if myname[l-1]='\' then myname[l-1]:=#0;
    err:=setthedir(myname);
    if err<>0 then begin   {no directory}
      assign(f,myname);
      filemode:=0;  {Others may read or write};
      {$I-}
      reset(f,1);
      {$I+}
      if ioresult=0 then begin
        {$I-}
        blockread(f,buf,10,err);
        {$I+}
        if (ioresult=0) then begin
          if (err=10) and (buf[0]='P') and (buf[1]='K')
            and (buf[2]=#3) and (buf[3]=#4) then isZip:=true
          else if (err>2) and (buf[0]='M') and (buf[1]='Z') then
            isZip:=CheckifSFX(buf,f); {Verändert buf!}
        end;
        {$I-}
        close(f);
        {$I+}
        err:=ioresult;  {only clears ioresult variable}
      end;
    end;
  end;
end;

procedure CloseZipFile(var Zprec:tPackRec);  {Only free buffer, file only open in Getfirstinzi}
var f:file;
    extra:word;
begin
 with zprec do begin
  if buf<>nil then begin
    if (bufsize=maxbufsize) then begin       {Caution: header bigger than 64k!}
      extra:=sizeof(file);
      move(buf^[bufsize+1],f,extra);   {Restore file}
      {$I-}
      close(f);
      {$I+}
      if ioresult<>0 then ;
    end else extra:=0;
    freemem(buf,bufsize+1+extra);
    buf:=nil
  end;
 end
end;

end.