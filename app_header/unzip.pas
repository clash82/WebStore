unit unzip;   {Unzips deflated, imploded and stored files}

{$define windows}
{$A-}
{$O-}

{C code by info-zip group, translated to pascal by Christian Ghisler}
{based on unz51g.zip}
{Special thanks go to Mark Adler,
 who wrote the main inflate and explode code,
 and did NOT copyright it!!!}

interface

{$R-}         {No range checking}

uses windows, messages, sysutils;

type thandle=word;


const   {Error codes returned by unzip}
  unzip_Ok=0;
  unzip_CRCErr=1;
  unzip_WriteErr=2;
  unzip_ReadErr=3;
  unzip_ZipFileErr=4;
  unzip_UserAbort=5;
  unzip_NotSupported=6;
  unzip_Encrypted=7;
  unzip_InUse=-1;

function GetSupportedMethods:longint;
{Checks which pack methods are supported by the dll}
{bit 8=1 -> Format 8 supported, etc.}

function unzipfile(in_name:pchar;out_name:pchar;attr:word;offset:longint;hFileAction:thandle;cm_index:integer):integer;
{usage:
 in_name:      name of zip file with full path
 out_name:     desired name for out file
 offset:       header position of desired file in zipfile
 hFileAction:  handle to dialog box showing advance of decompression (optional)
 cm_index:     notification code sent in a wm_command message to the dialog
               to update percent-bar
 Return value: one of the above unzip_xxx codes

 Example for handling the cm_index message in a progress dialog:

 unzipfile(......,cm_showpercent);

 ...

 procedure TFileActionDialog.wmcommand(var msg:tmessage);
 var ppercent:^word;
 begin
   TDialog.WMCommand(msg);
   if msg.wparam=cm_showpercent then begin
     ppercent:=pointer(lparam);
     if ppercent<>nil then begin
       if (ppercent^>=0) and (ppercent^<=100) then
         SetProgressBar(ppercent^);
       if UserPressedAbort then
         ppercent^:=$ffff
       else
         ppercent^:=0;
       end;
     end;
   end;
 end;
}

function unzipfiletomemory(in_name:pchar;out_buf:pchar;var buf_size:longint;
  offset:longint;hFileAction:thandle;cm_index:integer):integer;
{usage:
 in_name:      name of zip file with full path
 out_buf:      buffer to recieve unpacked file
 buf_size:     size of buffer to recieve unpacked file
 offset:       header position of desired file in zipfile
 hFileAction:  handle to dialog box showing advance of decompression (optional)
 cm_index:     notification code sent in a wm_command message to the dialog
               to update percent-bar
 Return value: one of the above unzip_xxx codes
}

function UnzipTestIntegrity(in_name:pchar;offset:longint;
  hFileAction:thandle;cm_index:integer;var crc:longint):integer;
{usage:
 in_name:      name of zip file with full path
 offset:       header position of desired file in zipfile
 hFileAction:  handle to dialog box showing advance of CRC check (optional)
 cm_index:     notification code sent in a wm_command message to the dialog
               to update percent-bar
 crc:          Returns the CRC of the file, compares itself with CRC stored in header
 Return value: one of the above unzip_xxx codes
}


implementation

{$ifndef win32}
type short=integer;
     smallint=integer;
{$endif}

{*************************************************************************}

{$I z_global.pas}  {global constants, types and variables}
{$I z_tables.pas}  {Tables for bit masking, huffman codes and CRC checking}
{$I z_generl.pas}  {General functions used by both inflate and explode}
{$I z_huft.pas}    {Huffman tree generating and destroying}
{$I z_inflat.pas}  {Inflate deflated file}
{$I z_copyst.pas}  {Copy stored file}
{$I z_explod.pas}  {Explode imploded file}
{$I z_shrunk.pas}  {Unshrink function}
{$I z_expand.pas}  {Expand function}

{***************************************************************************}

function GetSupportedMethods:longint;
begin
  GetSupportedMethods:=1+(1 shl 1)+(1 shl 2)+(1 shl 3)+(1 shl 4)+(1 shl 5)+(1 shl 6)+(1 shl 8);
  {stored, reduced 2-5, shrunk, imploded and deflated}
end;

{******************** main function: unzipfile *****************************}
{written and not copyrighted by Christian Ghisler}

function unzipfile(in_name:pchar;out_name:pchar;attr:word;offset:longint;
  hFileAction:thandle;cm_index:integer):integer;
var err:integer;
    header:plocalheader;
    buf:array[0..259] of char;
    buf0:array[0..3] of char;
    timedate:longint;
    {$ifndef win32}timedate2:longint;{$endif}
    originalcrc:longint;    {crc from zip-header}
    ziptype,iResult:integer;
    p,p1:pchar;
    isadir:boolean;

begin
  totalabort:=false;
  {$ifdef windows}
  if inuse then begin
    {take care of crashed applications!}
    if (lastusedtime<>0) and
      (abs(gettickcount-lastusedtime)>30000) then begin {1/2 minute timeout!!!}
      {do not close files or free slide, they were already freed when application crashed!}
      inuse:=false;
      {memory for huffman trees is lost}
    end else begin
      unzipfile:=unzip_inuse;
      exit
    end;
  end;
  inuse:=true;
  {$endif}
  getmem(slide,wsize);
  fillchar(slide[0],wsize,#0);
  assign(infile,in_name);
  filemode:=0;              {32: SHARE: others may read}
  {$I-} reset(infile,1); {$I+}
  if ioresult<>0 then begin
    freemem(slide,wsize);
    unzipfile:=unzip_ReadErr;
    inuse:=false;
    exit
  end;
  {$I-} seek(infile,offset);       {seek to header position} {$I+}
  if ioresult<>0 then begin
    freemem(slide,wsize);
    {$I-} close(infile); {$I+}
    unzipfile:=unzip_ZipFileErr;
    inuse:=false;
    exit
  end;
  header:=@inbuf;
  {$I-} blockread(infile,header^,sizeof(header^));  {read in local header} {$I+}
  if ioresult<>0 then begin
    freemem(slide,wsize);
    {$I-} close(infile); {$I+}
    unzipfile:=unzip_ZipFileErr;
    inuse:=false;
    exit
  end;

  if strlcomp(header^.signature,'PK'#3#4,4)<>0 then begin
    freemem(slide,wsize);
    {$I-} close(infile); {$I+}
    unzipfile:=unzip_ZipFileErr;
    inuse:=false;
    exit
  end;

  {calculate offset of data}
  offset:=offset+header^.filename_len+header^.extra_field_len+sizeof(tlocalheader);
  timedate:=header^.file_timedate;
  ziptype:=header^.zip_type;     {0=stored, 6=imploded, 8=deflated}
  compsize:=header^.compress_size;
  uncompsize:=header^.uncompress_size;   
  originalcrc:=header^.crc_32;
  hufttype:=header^.bit_flag;
  if ((hufttype and 8)<>0) and (ziptype<>0) and
    (compsize=0) then begin  {Size and crc at the beginning}
    compsize:=maxlongint-100;           {Don't get a sudden zipeof!}
    uncompsize:=maxlongint-100;
    originalcrc:=0
  end;
  if (1 shl ziptype) and GetSupportedMethods=0 then begin  {Not Supported!!!}
    freemem(slide,wsize);
    {$I-} close(infile); {$I+}
    unzipfile:=unzip_NotSupported;
    inuse:=false;
    exit;
  end;
  if (hufttype and 1)<>0 then begin {encrypted}
    freemem(slide,wsize);
    {$I-} close(infile); {$I+}
    unzipfile:=unzip_Encrypted;
    inuse:=false;
    exit;
  end;

  reachedsize:=0;
  {$I-} seek(infile,offset); {$I+}

  if not global_tomemory then begin
    if out_name<>nil then strcopy(buf,out_name);
    if attr and $10<>0 then begin   {faDirectory}
      p:=strend(buf)-1;
      if (buf[0]<>#0) and (p[0]<>'\') then strcat(pchar(@p[1]),'\');
    end;
    assign(outfile,buf);
    {$I-} rewrite(outfile,1);{$I+}
    err:=ioresult;
    {create directories not yet in path}
    isadir:=(buf[strlen(buf)-1]='\');
    if (err=3) or isadir then begin  {path not found}
      p1:=strrscan(buf,'\');
      if p1<>nil then inc(p1);  {pointer to filename}
      p:=strtok(buf,'\');
      if (p<>nil) and (p[1]=':') then begin
        strcopy(buf0,'c:\');    {set drive}
        buf0[0]:=p[0];
        SetTheDir(buf0);
        p:=strtok(nil,'\');
      end;
      while (p<>nil) and (p<>p1) do begin
        err:=SetTheDir(p);
        if err<>0 then begin
          err:=MakeTheDir(p);
          if err=0 then
            err:=SetTheDir(p);
        end;
        if err=0 then p:=strtok(nil,'\')
                 else p:=nil;
      end;
      if isadir then begin
        freemem(slide,wsize);
        unzipfile:=unzip_Ok;    {A directory -> ok}
        {$I-} close(infile); {$I+}
        inuse:=false;
        exit;
      end;
      {$I-} rewrite(outfile,1); {$I+}
      err:=ioresult;
    end;
    if err<>0 then begin
      freemem(slide,wsize);
      unzipfile:=unzip_WriteErr;
      {$I-} close(infile); {$I+}
      inuse:=false;
      exit
    end;
  end;    {if not global_tomemory}

  zipeof:=false;
  dlghandle:=hFileAction;
  dlgnotify:=cm_index;

  messageloop;
  {$ifdef windows}
  oldpercent:=0;
  if dlghandle<>0 then
    sendmessage(dlghandle,wm_command,dlgnotify,longint(@oldpercent));  {0 Percent}
  {$endif}

  crc32val:=$FFFFFFFF;

  {Unzip correct type}
  case ziptype of
    0:iresult:=copystored;
    1:iresult:=unshrink;
    2..5:iresult:=unreduce(ziptype);
    6:iresult:=explode;
    8:iresult:=inflate;
  else
    iresult:=unzip_NotSupported;
  end;
  unzipfile:=iresult;

  if (iresult=unzip_ok) and ((hufttype and 8)<>0) then begin {CRC at the end}
    if ziptype=0 then begin
      inpos:=0;
      readpos:=-1;
      w:=0;
      k:=0;
      b:=0;
    end else
      dumpbits(k and 7);
    needbits(16);     {pk#7#8}
    dumpbits(16);
    needbits(16);
    dumpbits(16);

    needbits(16);
    originalcrc:=b and $FFFF;
    dumpbits(16);
    needbits(16);
    originalcrc:=originalcrc or (b and $FFFF) shl 16;
    dumpbits(16);
  end;
  crc32val:=not(crc32val);  {one's complement}
  {$I-}
  close(infile);
  if not global_tomemory then begin
    setftime(outfile,timedate); {set zipped time and date of oufile}
    close(outfile);
  end;
  {$I+}
  if iresult<>0 then begin
    if not global_tomemory then erase(outfile);
  end else if (originalcrc<>crc32val) then begin
    unzipfile:=unzip_CRCErr;
    {$I-} if not global_tomemory then erase(outfile); {$I+}
  end else begin
    oldpercent:=100;       {100 percent}
    {$ifdef windows}
    if dlghandle<>0 then
      sendmessage(dlghandle,wm_command,dlgnotify,longint(@oldpercent));
    if oldpercent=$FFFF then begin
      iresult:=unzip_userabort;
      unzipfile:=iresult;
      {$I-} if not global_tomemory then erase(outfile); {$I+}
    end;
    {$endif}
    if (iresult=0) and not global_tomemory then begin  {No user abort!}
      {$ifndef win32}
      filemode:=0;
      {$I-} reset(outfile); {$I+}
      if ioresult=0 then begin
        getftime(outfile,timedate2);
        if timedate2<>timedate then
          setftime(outfile,timedate); {old DOS versions: set zipped time and date of oufile}
        {$I-} close(outfile); {$I+}
      end;
      {$endif}
      setfattr(out_name,attr);
    end;
  end;
  freemem(slide,wsize);
  if (global_byteswritten = 0) and global_tomemory then global_byteswritten:=uncompsize;
  inuse:=false;
end;

function unzipfiletomemory(in_name:pchar;out_buf:pchar;var buf_size:longint;offset:longint;
  hFileAction:thandle;cm_index:integer):integer;
var iresult:integer;
begin
  global_byteswritten:=0;
  global_tomemory:=true;
  global_outbuf:=out_buf;
  global_bufsize:=buf_size;
  iresult:=unzipfile(in_name,nil,0,offset,hFileAction,cm_index);
  if (iresult=unzip_writeerr) then iresult:=unzip_ok;  {smaller buffer size than necessary}
  global_tomemory:=false;
  buf_size:=global_byteswritten;
  unzipfiletomemory:=iresult;
end;

function UnzipTestIntegrity(in_name:pchar;offset:longint;
  hFileAction:thandle;cm_index:integer;var crc:longint):integer;
var iResult:integer;
begin
  global_byteswritten:=0;
  global_tomemory:=true;
  global_crconly:=true;
  iResult:=unzipfile(in_name,nil,0,offset,hFileAction,cm_index);
  if (iResult=unzip_writeerr) then iResult:=unzip_ok;  {smaller buffer size than necessary}
  global_crconly:=false;
  global_tomemory:=false;
  crc:=crc32val;
  UnzipTestIntegrity:=iResult;
end;


end.

