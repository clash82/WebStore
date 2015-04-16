{include for unzip.pas: Inflate deflated file}

{C code by info-zip group, translated to Pascal by Christian Ghisler}
{based on unz51g.zip}

function inflate_codes(tl,td:phuftlist;bl,bd:integer):integer;
var n,d,e1:word;     {length and index for copy}
    t:phuft;         {pointer to table entry}
    ml,md:word;      {masks for bl and bd bits}
    e:byte;          {table entry flag/number of extra bits}

begin
  { inflate the coded data }
  ml:=mask_bits[bl];          {precompute masks for speed}
  md:=mask_bits[bd];
  while not (totalabort or zipeof) do begin
    NEEDBITS(bl);
    t:=@tl^[b and ml];
    e:=t^.e;
    if e>16 then repeat       {then it's a literal}
      if e=99 then begin
        inflate_codes:=unzip_ZipFileErr;
        exit
      end;
      DUMPBITS(t^.b);
      dec(e,16);
      NEEDBITS(e);
      t:=@t^.v_t^[b and mask_bits[e]];
      e:=t^.e;
    until e<=16;
    DUMPBITS(t^.b);
    if e=16 then begin
      slide[w]:=char(t^.v_n);
      inc(w);
      if w=WSIZE then begin
        if not flush(w) then begin
          inflate_codes:=unzip_WriteErr;
          exit;
        end;
        w:=0
      end;
    end else begin                {it's an EOB or a length}
      if e=15 then begin {Ende}   {exit if end of block}
        inflate_codes:=unzip_Ok;
        exit;
      end;
      NEEDBITS(e);                 {get length of block to copy}
      n:=t^.v_n+(b and mask_bits[e]);
      DUMPBITS(e);

      NEEDBITS(bd);                {decode distance of block to copy}
      t:=@td^[b and md];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          inflate_codes:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[b and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);
      NEEDBITS(e);
      d:=w-t^.v_n-b and mask_bits[e];
      DUMPBITS(e);
      {do the copy}
      repeat
        d:=d and (WSIZE-1);
        if d>w then e1:=WSIZE-d
               else e1:=WSIZE-w;
        if e1>n then e1:=n;
        dec(n,e1);
        if (w-d>=e1) then begin
          move(slide[d],slide[w],e1);
          inc(w,e1);
          inc(d,e1);
        end else repeat
          slide[w]:=slide[d];
          inc(w);
          inc(d);
          dec(e1);
        until (e1=0);
        if w=WSIZE then begin
          if not flush(w) then begin
            inflate_codes:=unzip_WriteErr;
            exit;
          end;
          w:=0;
        end;
      until n=0;
    end;
  end;
  if totalabort then
    inflate_codes:=unzip_userabort
  else
    inflate_codes:=unzip_readErr;
end;

{**************************** "decompress" stored block **************************}

function inflate_stored:integer;
var n:word;            {number of bytes in block}

begin
  {go to byte boundary}
  n:=k and 7;
  dumpbits(n);
  {get the length and its complement}
  NEEDBITS(16);
  n:=b and $ffff;
  DUMPBITS(16);
  NEEDBITS(16);
  if (n<>(not b) and $ffff) then begin
    inflate_stored:=unzip_zipFileErr;
    exit
  end;
  DUMPBITS(16);
  while (n>0) and not (totalabort or zipeof) do begin {read and output the compressed data}
    dec(n);
    NEEDBITS(8);
    slide[w]:=char(b);
    inc(w);
    if w=WSIZE then begin
      if not flush(w) then begin
        inflate_stored:=unzip_WriteErr;
        exit
      end;
      w:=0;
    end;
    DUMPBITS(8);
  end;
  if totalabort then inflate_stored:=unzip_UserAbort
    else if zipeof then inflate_stored:=unzip_readErr
      else inflate_stored:=unzip_Ok;
end;

{**************************** decompress fixed block **************************}

function inflate_fixed:integer;
var i:integer;               {temporary variable}
    tl,                      {literal/length code table}
    td:phuftlist;                {distance code table}
    bl,bd:integer;           {lookup bits for tl/bd}
    l:array[0..287] of word; {length list for huft_build}

begin
  {set up literal table}
  for i:=0 to 143 do l[i]:=8;
  for i:=144 to 255 do l[i]:=9;
  for i:=256 to 279 do l[i]:=7;
  for i:=280 to 287 do l[i]:=8; {make a complete, but wrong code set}
  bl:=7;                 
  i:=huft_build(pword(@l),288,257,pushlist(@cplens),pushlist(@cplext),@tl,bl);
  if i<>huft_complete then begin
    inflate_fixed:=i;
    exit
  end;
  for i:=0 to 29 do l[i]:=5;    {make an incomplete code set}
  bd:=5;          
  i:=huft_build(pword(@l),30,0,pushlist(@cpdist),pushlist(@cpdext),@td,bd);
  if i>huft_incomplete then begin
    huft_free(tl);
    inflate_fixed:=unzip_ZipFileErr;
    exit
  end;
  inflate_fixed:=inflate_codes(tl,td,bl,bd);
  huft_free(tl);
  huft_free(td);
end;

{**************************** decompress dynamic block **************************}

function inflate_dynamic:integer;
var i:integer;                      {temporary variables}
    j,
    l,                              {last length}
    m,                              {mask for bit length table}
    n:word;                         {number of lengths to get}
    tl,                             {literal/length code table}
    td:phuftlist;                   {distance code table}
    bl,bd:integer;                  {lookup bits for tl/bd}
    nb,nl,nd:word;                  {number of bit length/literal length/distance codes}
    ll:array[0..288+32-1] of word;  {literal/length and distance code lengths}

begin
  {read in table lengths}
  NEEDBITS(5);
  nl:=257+word(b) and $1f;
  DUMPBITS(5);
  NEEDBITS(5);
  nd:=1+word(b) and $1f;
  DUMPBITS(5);
  NEEDBITS(4);
  nb:=4+word(b) and $f;
  DUMPBITS(4);
  if (nl>288) or (nd>32) then begin
    inflate_dynamic:=1;
    exit
  end;
  fillchar(ll,sizeof(ll),#0);

  {read in bit-length-code lengths}
  for j:=0 to nb-1 do begin
    NEEDBITS(3);
    ll[border[j]]:=b and 7;
    DUMPBITS(3);
  end;
  for j:=nb to 18 do ll[border[j]]:=0;

  {build decoding table for trees--single level, 7 bit lookup}
  bl:=7;
  i:=huft_build(pword(@ll),19,19,nil,nil,@tl,bl);
  if i<>huft_complete then begin
    if i=huft_incomplete then huft_free(tl); {other errors: already freed}
    inflate_dynamic:=unzip_ZipFileErr;
    exit
  end;

  {read in literal and distance code lengths}
  n:=nl+nd;
  m:=mask_bits[bl];
  i:=0; l:=0;
  while word(i)<n do begin
    NEEDBITS(bl);
    td:=@tl^[b and m];
    j:=phuft(td)^.b;
    DUMPBITS(j);
    j:=phuft(td)^.v_n;
    if j<16 then begin            {length of code in bits (0..15)}
      l:=j;                       {ave last length in l}
      ll[i]:=l;
      inc(i)
    end else if j=16 then begin   {repeat last length 3 to 6 times}
      NEEDBITS(2);
      j:=3+b and 3;
      DUMPBITS(2);
      if i+j>n then begin
        inflate_dynamic:=1;
        exit
      end;
      while j>0 do begin
        ll[i]:=l;
        dec(j);
        inc(i);
      end;
    end else if j=17 then begin   {3 to 10 zero length codes}
      NEEDBITS(3);
      j:=3+b and 7;
      DUMPBITS(3);
      if i+j>n then begin
        inflate_dynamic:=1;
        exit
      end;
      while j>0 do begin
        ll[i]:=0;
        inc(i);
        dec(j);
      end;
      l:=0;
    end else begin                {j == 18: 11 to 138 zero length codes}
      NEEDBITS(7);
      j:=11+b and $7f;
      DUMPBITS(7);
      if i+j>n then begin
        inflate_dynamic:=unzip_zipfileErr;
        exit
      end;
      while j>0 do begin
        ll[i]:=0;
        dec(j);
        inc(i);
      end;
      l:=0;
    end;
  end;
  huft_free(tl);        {free decoding table for trees}

  {build the decoding tables for literal/length and distance codes}
  bl:=lbits;
  i:=huft_build(pword(@ll),nl,257,pushlist(@cplens),pushlist(@cplext),@tl,bl);
  if i<>huft_complete then begin
    if i=huft_incomplete then huft_free(tl);
    inflate_dynamic:=unzip_ZipFileErr;
    exit
  end;
  bd:=dbits;
  i:=huft_build(pword(@ll[nl]),nd,0,pushlist(@cpdist),pushlist(@cpdext),@td,bd);
  if i>huft_incomplete then begin {pkzip bug workaround}
    if i=huft_incomplete then huft_free(td);
    huft_free(tl);
    inflate_dynamic:=unzip_ZipFileErr;
    exit
  end;
  {decompress until an end-of-block code}
  inflate_dynamic:=inflate_codes(tl,td,bl,bd);
  huft_free(tl);
  huft_free(td);
end;

{**************************** decompress a block ******************************}

function inflate_block(var e:integer):integer;
var t:word;           {block type}

begin
  NEEDBITS(1);
  e:=b and 1;
  DUMPBITS(1);

  NEEDBITS(2);
  t:=b and 3;
  DUMPBITS(2);

  case t of
    2:inflate_block:=inflate_dynamic;
    0:inflate_block:=inflate_stored;
    1:inflate_block:=inflate_fixed;
  else        
    inflate_block:=unzip_ZipFileErr;  {bad block type}
  end;
end;

{**************************** decompress an inflated entry **************************}

function inflate:integer;
var e,                 {last block flag}
    r:integer;         {result code}

begin
  inpos:=0;            {Input buffer position}
  readpos:=-1;         {Nothing read}

  {initialize window, bit buffer}
  w:=0;
  k:=0;
  b:=0;

  {decompress until the last block}
  repeat
    r:=inflate_block(e);
    if r<>0 then begin
      inflate:=r;
      exit
    end;
  until e<>0;
  {flush out slide}
  if not flush(w) then inflate:=unzip_WriteErr
  else inflate:=unzip_Ok;
end;

