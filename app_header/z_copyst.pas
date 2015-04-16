{include for unzip.pas: Copy stored file}

{C code by info-zip group, translated to Pascal by Christian Ghisler}
{based on unz51g.zip}

{************************* copy stored file ************************************}
function copystored:integer;
var readin:longint;
    {$ifdef win32}
    outcnt:integer;
    {$else}
    outcnt:word;
    {$endif}
begin
  while (reachedsize<compsize) and not totalabort do begin
    readin:=compsize-reachedsize;
    if readin>wsize then readin:=wsize;
    {$I-}
    blockread(infile,slide[0],readin,outcnt);  {Use slide as buffer}
    {$I+}
    if (outcnt<>readin) or (ioresult<>0) then begin
      copystored:=unzip_ReadErr;
      exit
    end;
    if not flush(outcnt) then begin  {Flushoutput takes care of CRC too}
      copystored:=unzip_WriteErr;
      exit
    end;
    inc(reachedsize,outcnt);
    messageloop;      {Other programs, or in DOS: keypressed?}
    {$ifdef windows}
    showpercent;
    {$endif}
  end;
  if not totalabort then
    copystored:=unzip_Ok
  else
    copystored:=unzip_Userabort;
end;


