{*************************** unshrink **********************************}
{Written and NOT copyrighted by Christian Ghisler.
 I have rewritten unshrink because the original
 function was copyrighted by Mr. Smith of Info-zip
 This funtion here is now completely FREE!!!!
 The only right I claim on this code is that
 noone else claims a copyright on it!}


const max_code=8192;
      max_stack=8192;
      initial_code_size=9;
      final_code_size=13;
      write_max=wsize-3*(max_code-256)-max_stack-2;  {Rest of slide=write buffer}
                                                     {=766 bytes}

type prev=array[257..max_code] of smallint;
     pprev=^prev;
     cds=array[257..max_code] of char;
     pcds=^cds;
     stacktype=array[0..max_stack] of char;
     pstacktype=^stacktype;
     writebuftype=array[0..write_max] of char;   {write buffer}
     pwritebuftype=^writebuftype;

var previous_code:pprev;       {previous code trie}
    actual_code:pcds;          {actual code trie}
    stack:pstacktype;          {Stack for output}
    writebuf:pwritebuftype;    {Write buffer}
    next_free,                 {Next free code in trie}
    write_ptr:smallint;        {Pointer to output buffer}

function unshrink_flush:boolean;
begin
  unshrink_flush:=flush(write_ptr);  {Outbuf now starts at slide[0]}
end;

function write_char(c:char):boolean;
begin
  writebuf^[write_ptr]:=c;
  inc(write_ptr);
  if write_ptr>write_max then begin
    write_char:=unshrink_flush;
    write_ptr:=0;
  end else write_char:=true;
end;

procedure ClearLeafNodes;
var pc,                    {previous code}
    i,                     {index}
    act_max_code:smallint; {max code to be searched for leaf nodes}
    previous:pprev;        {previous code trie}

begin
  previous:=previous_code;
  act_max_code:=next_free-1;
  for i:=257 to act_max_code do
    previous^[i]:=previous^[i] or $8000;
  for i:=257 to act_max_code do begin
    pc:=previous^[i] and not $8000;
    if pc>256 then
      previous^[pc]:=previous^[pc] and (not $8000);
  end;
  {Build new free list}
  pc:=-1;
  next_free:=-1;
  for i:=257 to act_max_code do
    if previous^[i] and $C000<>0 then begin {Either free before or marked now}
      if pc<>-1 then previous^[pc]:=-i     {Link last item to this item}
                else next_free:=i;
      pc:=i;
    end;
  if pc<>-1 then
    previous^[pc]:=-act_max_code-1;
end;


function unshrink:smallint;

var incode:smallint;           {code read in}
    lastincode:smallint;       {last code read in}
    lastoutcode:char;          {last code emitted}
    code_size:byte;            {Actual code size}
    stack_ptr,                 {Stackpointer}
    new_code,                  {Save new code read}
    code_mask,                 {mask for coding}
    i:smallint;                {Index}
    bits_to_read:longint;



begin
  if compsize=maxlongint then begin   {Compressed Size was not in header!}
    unshrink:=unzip_NotSupported;
    exit
  end;
  inpos:=0;            {Input buffer position}
  readpos:=-1;         {Nothing read}

  {initialize window, bit buffer}
  w:=0;
  k:=0;
  b:=0;

  {Initialize pointers for various buffers}
  {Re-arranged with writebuf first, for flush from slide[0]}

  writebuf:=@slide[0];
  previous_code:=@slide[sizeof(writebuftype)];
  actual_code:=@slide[sizeof(prev)+sizeof(writebuftype)];
  stack:=@slide[sizeof(prev)+sizeof(cds)+sizeof(writebuftype)];

  fillchar(slide^,wsize,#0);

  {initialize free codes list}
  for i:=257 to max_code do      
    previous_code^[i]:=-(i+1);
  next_free:=257;
  stack_ptr:=max_stack;
  write_ptr:=0;
  code_size:=initial_code_size;
  code_mask:=mask_bits[code_size];

  NEEDBITS(code_size);
  incode:=b and code_mask;
  DUMPBITS(code_size);

  lastincode:=incode;
  lastoutcode:=char(incode);
  if not write_char(lastoutcode) then begin
    unshrink:=unzip_writeErr;
    exit
  end;

  bits_to_read:=8*compsize-code_size;   {Bits to be read}

  while not totalabort and (bits_to_read>=code_size) do begin
    NEEDBITS(code_size);
    incode:=b and code_mask;
    DUMPBITS(code_size);
    dec(bits_to_read,code_size);
    if incode=256 then begin            {Special code}
      NEEDBITS(code_size);
      incode:=b and code_mask;
      DUMPBITS(code_size);
      dec(bits_to_read,code_size);
      case incode of
        1:begin
          inc(code_size);
          if code_size>final_code_size then begin
            unshrink:=unzip_ZipFileErr;
            exit
          end;
          code_mask:=mask_bits[code_size];
        end;
        2:begin
          ClearLeafNodes;
        end;
      else    
        unshrink:=unzip_ZipFileErr;
        exit
      end;
    end else begin
      new_code:=incode;
      if incode<256 then begin          {Simple char}
        lastoutcode:=char(incode);
        if not write_char(lastoutcode) then begin
          unshrink:=unzip_writeErr;
          exit
        end;
      end else begin
        if previous_code^[incode]<0 then begin
          stack^[stack_ptr]:=lastoutcode;
          dec(stack_ptr);
          incode:=lastincode;
        end;
        while incode>256 do begin
          stack^[stack_ptr]:=actual_code^[incode];
          dec(stack_ptr);
          incode:=previous_code^[incode];
        end;
        lastoutcode:=char(incode);
        if not write_char(lastoutcode) then begin
          unshrink:=unzip_writeErr;
          exit
        end;
        for i:=stack_ptr+1 to max_stack do
          if not write_char(stack^[i]) then begin
            unshrink:=unzip_writeErr;
            exit
          end;
        stack_ptr:=max_stack;
      end;
      incode:=next_free;
      if incode<=max_code then begin
        next_free:=-previous_code^[incode];   {Next node in free list}
        previous_code^[incode]:=lastincode;
        actual_code^[incode]:=lastoutcode;
      end;
      lastincode:=new_code;
    end;
  end;
  if totalabort then
    unshrink:=unzip_UserAbort
  else if unshrink_flush then
    unshrink:=unzip_ok
  else
    unshrink:=unzip_WriteErr;
end;

