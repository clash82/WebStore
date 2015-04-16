{include for unzip.pas: General functions used by both inflate and explode}

{C code by info-zip group, translated to Pascal by Christian Ghisler}
{based on unz51g.zip}

{*********************************** CRC Checking ********************************}

function StrScan(Str: PChar; Chr: Char): PChar; assembler;
asm
        PUSH    EDI
        PUSH    EAX
        MOV     EDI,Str
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        POP     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        DEC     EAX
@@1:    POP     EDI
end;

procedure UpdateCRC(var s:iobuf;len:integer);
{$ifndef assembler}
var i:integer;
{$endif}
begin
{$ifndef assembler}
 for i:=0 to len-1 do begin
    { update running CRC calculation with contents of a buffer }
    crc32val:=crc_32_tab[(byte(crc32val) xor s[i]) and $ff] xor (crc32val shr 8);
  end;
{$else}
  asm
{$ifdef win32}
    push edi
    push esi
    push ebx
    mov edi,s
    mov eax,crc32val
    lea esi,[crc_32_tab]
    mov ecx,len
    or ecx,ecx
    jz @finished
@again:
    xor ebx,ebx
    mov bl,al           {byte(crcval)}
    shr eax,8

    xor bl,[edi]  {xor s^}
    inc edi
    shl ebx,2            {Offset: Index*4}
    xor eax,[esi+ebx]
    dec ecx
    jnz @again
@finished:
    mov crc32val,eax
    pop ebx
    pop esi
    pop edi
{$else}
    les di,s
    mov ax,li.lo(crc32val)
    mov dx,li.hi(crc32val)
    mov si,offset crc_32_tab      {Segment remains DS!!!}
    mov cx,len
    or cx,cx
    jz @finished
@again:
    mov bl,al           {byte(crcval)}
    mov al,ah           {shift DX:AX by 8 bits to the right}
    mov ah,dl
    mov dl,dh
    xor dh,dh

    xor bh,bh
    xor bl,es:[di]  {xor s^}
    inc di
    shl bx,1            {Offset: Index*4}
    shl bx,1
    xor ax,[si+bx]
    xor dx,[si+bx+2]
    dec cx
    jnz @again
@finished:
    mov li.lo(crc32val),ax
    mov li.hi(crc32val),dx
{$endif}
  end;
{$endif}
end;

{************************ keep other programs running ***************************}

procedure messageloop;
{$ifdef windows}
var msg:tmsg;
begin
  lastusedtime:=gettickcount;
  while PeekMessage(Msg,0,0,0,PM_Remove) do
    if (dlghandle=0) or not IsDialogMessage(dlghandle,msg) then begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
end;
{$else}
var ch:word;
begin
  if keypressed then begin
    ch:=byte(readkey);
    if ch=0 then ch:=256+byte(readkey);  {Extended code}
    if ch=dlgnotify then totalabort:=true;
  end
end;
{$endif}

{************************* tell dialog to show % ******************************}

{$ifdef windows}
procedure showpercent;
var percent:word;
begin
  if compsize<>0 then begin
    if reachedsize>1000000 then
      percent:=trunc(100.0*reachedsize/compsize)
    else
      percent:=reachedsize*100 div compsize;
    if percent>100 then percent:=100;
    if (percent<>oldpercent) then begin
      oldpercent:=percent;
      if dlghandle<>0 then begin     {Use dialog box for aborting}
        {Sendmessage returns directly -> ppercent contains result}
        sendmessage(dlghandle,wm_command,dlgnotify,longint(@percent));
        totalabort:=(percent=$FFFF);   {Abort pressed!}
      end else
        if dlgnotify<>0 then
          totalabort:=getasynckeystate(dlgnotify)<0;  {break Key pressed!}
    end;
  end;
end;
{$endif}

{************************** fill inbuf from infile *********************}

procedure readbuf;
begin
  if reachedsize>compsize+2 then begin {+2: last code is smaller than requested!}
    readpos:=sizeof(inbuf); {Simulates reading -> no blocking}
    zipeof:=true
  end else begin
    messageloop;      {Other programs, or in DOS: keypressed?}
    {$ifdef windows}
    showpercent;      {Before, because it shows the data processed, not read!}
    {$endif}
    {$I-}
    blockread(infile,inbuf,sizeof(inbuf),readpos);
    {$I+}
    if (ioresult<>0) or (readpos=0) then begin  {readpos=0: kein Fehler gemeldet!!!}
      readpos:=sizeof(inbuf); {Simulates reading -> CRC error}
      zipeof:=true;
    end;
    inc(reachedsize,readpos);
    dec(readpos);    {Reason: index of inbuf starts at 0}
  end;
  inpos:=0;
end;

{**** read byte, only used by explode ****}

procedure READBYTE(var bt:byte);
begin
  if inpos>readpos then readbuf;
  bt:=inbuf[inpos];
  inc(inpos);
end;

{*********** read at least n bits into the global variable b *************}

procedure NEEDBITS(n:byte);
var nb:longint;
begin
{$ifndef assembler}
  while k<n do begin
    if inpos>readpos then readbuf;
    nb:=inbuf[inpos];
    inc(inpos);
    b:=b or nb shl k;
    inc(k,8);
  end;   
{$else}
{$ifdef win32}
  while k<n do begin
    if inpos>readpos then readbuf;
    nb:=inbuf[inpos];
    inc(inpos);
    b:=b or nb shl k;
    inc(k,8);
  end;
{$else}
  asm
    mov si,offset inbuf
    mov ch,n
    mov cl,k
    mov bx,inpos    {bx=inpos}
@again:
    cmp cl,ch
    JAE @finished   {k>=n -> finished}
    cmp bx,readpos
    jg @readbuf     
@fullbuf:
    mov al,[si+bx]  {dx:ax=nb}
    xor ah,ah
    xor dx,dx
    cmp cl,8      {cl>=8 -> shift into DX or directly by 1 byte}
    JAE @bigger8
    shl ax,cl     {Normal shifting!}
    jmp @continue
@bigger8:
    mov di,cx     {save cx}
    mov ah,al     {shift by 8}
    xor al,al
    sub cl,8      {8 bits shifted}
@rotate:
    or cl,cl
    jz @continue1 {all shifted -> finished}
    shl ah,1      {al ist empty!}
    rcl dx,1
    dec cl
    jmp @rotate
@continue1:
    mov cx,di
@continue:
    or li.hi(b),dx {b=b or nb shl k}
    or li.lo(b),ax
    inc bx         {inpos}
    add cl,8       {inc k by 8 Bits}
    jmp @again

@readbuf:
    push si
    push cx
    call readbuf   {readbuf not critical, called only every 2000 bytes}
    pop cx
    pop si
    mov bx,inpos   {New inpos}
    jmp @fullbuf

@finished:
    mov k,cl
    mov inpos,bx
  end;
{$endif}
{$endif}
end;

{***************** dump n bits no longer needed from global variable b *************}

procedure DUMPBITS(n:byte);
begin
{$ifndef assembler}
  b:=b shr n;
  k:=k-n;
{$else}
{$ifdef win32}
  asm
    mov cl,n
    mov eax,b
    or cl,cl
    jz @finished
    shr eax,cl           {Lower Bit in Carry}
@finished:
    mov b,eax
    sub k,cl
  end;
{$else}
  asm
    mov cl,n
    mov ax,li.lo(b)
    mov dx,li.hi(b)

    mov ch,cl
    or ch,ch
    jz @finished
@rotate:
    shr dx,1           {Lower Bit in Carry}
    rcr ax,1
    dec ch
    jnz @rotate
@finished:
    mov li.lo(b),ax
    mov li.hi(b),dx
    sub k,cl
  end;
{$endif}
{$endif}
end;

{$ifdef windows}
{$ifndef win32}
procedure AHIncr; far; external 'KERNEL' index 114;
{$endif}
{$endif}

{********************* Flush w bytes directly from slide to file ******************}
function flush(w:word):boolean;
var {$ifdef win32}
    n:integer;
    {$else}
    n:word;          {True wenn OK}
    ahinc:integer;
    out_ofs:longint;
    {$endif}
    wrbytes:longint;

begin
  if not global_crconly then begin
    if not global_tomemory then begin   {Write to disk}
      {$I-}
      blockwrite(outfile,slide[0],w,n);
      {$I+}
      flush:=(n=w) and (ioresult=0);  {True-> alles ok}
    end else begin   {To memory}
      flush:=true;
      wrbytes:=w;
      if global_byteswritten+w>global_bufsize
        then begin
          wrbytes:=global_bufsize-global_byteswritten;
          flush:=false;       {Buffer is full}
        end;
      {$ifndef win32}
      {$ifdef windows}
      ahinc:=ofs(ahincr);
      {$else}
      ahinc:=$1000;
      {$endif}
      out_ofs:=li(global_outbuf).lo;
      if longint(out_ofs)+wrbytes>$10000 then begin  {Cross segment bounds}
        move(slide[0],global_outbuf^,$FFFF-out_ofs+1);
        inc(li(global_outbuf).hi,ahinc);
        li(global_outbuf).lo:=0;
        move(slide[$FFFF-out_ofs+1],global_outbuf^,longint(out_ofs)+wrbytes-$FFFF-1);
        inc(li(global_outbuf).lo,longint(out_ofs)+wrbytes-$FFFF-1);
      end else begin
        move(slide[0],global_outbuf^,wrbytes);
        inc(li(global_outbuf).lo,wrbytes);
        if li(global_outbuf).lo=0 then inc(li(global_outbuf).hi,ahinc);
      end;
      {$else}   {Win32}
      move(slide[0],global_outbuf^,wrbytes); {No segments in Win32!}
      inc(longint(global_outbuf),wrbytes);
      {$endif}
      inc(global_byteswritten,wrbytes);
    end;
  end else flush:=true;
  UpdateCRC(iobuf(pointer(@slide[0])^),w);
end;

{******************************* Break string into tokens ****************************}

VAR
  _Token: PChar;

FUNCTION StrTok(Source: PChar; Token: CHAR): PChar;
  VAR P: PChar;
BEGIN
  IF Source <> Nil THEN _Token := Source;
  IF _Token = Nil THEN begin
    strTok:=nil;
    exit
  end;
  P := StrScan(_Token, Token);
  StrTok := _Token;
  IF P <> Nil THEN BEGIN
    P^ := #0;
    Inc(longint(P));
  END;
  _Token := P;
END;

{$ifdef win32}
type
  TDateTime1 = record
    Year, Month, Day, Hour, Min, Sec: Word;
  end;

procedure UnpackTime(P: Longint; var T: TDateTime1); assembler; pascal;
asm
  PUSH  EDI
  MOV   EDI,T
  CLD
  MOV   AX,P.Word[2]
  MOV	CL,9
  SHR	AX,CL
  ADD	AX,1980
  STOSW
  MOV	AX,P.Word[2]
  MOV	CL,5
  SHR	AX,CL
  AND	AX,15
  STOSW
  MOV	AX,P.Word[2]
  AND	AX,31
  STOSW
  MOV	AX,P.Word[0]
  MOV	CL,11
  SHR	AX,CL
  STOSW
  MOV	AX,P.Word[0]
  MOV	CL,5
  SHR	AX,CL
  AND	AX,63
  STOSW
  MOV	AX,P.Word[0]
  AND	AX,31
  SHL	AX,1
  STOSW
  POP    EDI
end;

var doserror:integer;

procedure setftime(var outfile:file;datetime:longint);
var localfiletime,filetime:tFILETIME;
    st:tsystemtime;
    tdt:tdatetime1;
begin
  unpacktime(datetime,tdt);
  fillchar(st,sizeof(st),#0);
  st.wYear:=tdt.year;
  st.wMonth:=tdt.month;
  st.wDay:=tdt.day;
  st.wHour:=tdt.hour;
  st.wMinute:=tdt.min;
  st.wSecond:=tdt.sec;
  SystemTimeToFileTime(st,localfiletime);
  LocalFileTimeToFileTime(localfiletime,filetime);
  if SetFileTime(tfilerec(outfile).handle,nil,nil,@filetime)
  then doserror:=0
  else doserror:=GetLastError;
end;

procedure SetFAttr(filename:pchar;attr:word);
begin
  if SetFileAttributes(filename,attr) then
    doserror:=0
  else
    doserror:=GetLastError;
end;
{$endif}

{$ifdef ver80}
procedure SetFTime(var thefile:file;age:longint);
begin
  FileSetDate(tfilerec(thefile).Handle,Age);
end;

procedure getftime(var thefile:file;var thedate:longint);
begin
  thedate:=FileGetDate(tfilerec(thefile).Handle);
end;

procedure SetFattr(filename:pchar;Attr:integer);
begin
  FileSetAttr(strpas(FileName),Attr);
end;
{$endif}

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
(*  {$i-}chdir(strpas(thedir));{$i+}*)
  SetTheDir:=ioresult;
  {$endif}
  {$endif}
end;

function MakeTheDir(thedir:pchar):integer;
begin
  {$ifdef win32}
  {$I-} mkdir(strpas(thedir));{$I+}
  MakeTheDir:=ioresult;
  {$else}
  {$ifdef windows}
  {$ifdef ver80}
  {$I-} mkdir(strpas(thedir));{$I+}
  MakeTheDir:=ioresult;
  {$else}
  createdir(thedir);
  MakeTheDir:=doserror;
  {$endif}
  {$else}
(*  {$I-} mkdir(strpas(thedir));{$I+}*)
  MakeTheDir:=ioresult;
  {$endif}
  {$endif}
end;

