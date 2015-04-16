{include for unzip.pas: Huffman tree generating and destroying}

{C code by info-zip group, translated to Pascal by Christian Ghisler}
{based on unz51g.zip}

{*************** free huffman tables starting with table where t points to ************}

procedure huft_free(t:phuftlist);

var p,q:phuftlist;
    z:word;

begin
  p:=t;
  while p<>nil do begin
    dec(longint(p),sizeof(huft));
    q:=p^[0].v_t;
    z:=p^[0].v_n;   {Size in Bytes, required by TP ***}
    freemem(p,(z+1)*sizeof(huft));
    p:=q
  end;
end;

{*********** build huffman table from code lengths given by array b^ *******************}    

function huft_build(b:pword;n:word;s:word;d,e:pushlist;t:pphuft;var m:integer):integer;
var a:word;                        {counter for codes of length k}
    c:array[0..b_max+1] of word;   {bit length count table}
    f:word;                        {i repeats in table every f entries}
    g,                             {max. code length}
    h:integer;                     {table level}
    i,                             {counter, current code}
    j:word;                        {counter}
    k:integer;                     {number of bits in current code}
    p:pword;                       {pointer into c, b and v}
    q:phuftlist;                   {points to current table}
    r:huft;                        {table entry for structure assignment}
    u:array[0..b_max] of phuftlist;{table stack}
    v:array[0..n_max] of word;     {values in order of bit length}
    w:integer;                     {bits before this table}
    x:array[0..b_max+1] of word;   {bit offsets, then code stack} 
    l:array[-1..b_max+1] of word;  {l[h] bits in table of level h}
    xp:^word;                      {pointer into x}
    y:integer;                     {number of dummy codes added}
    z:word;                        {number of entries in current table}
    tryagain:boolean;              {bool for loop}
    pt:phuft;                      {for test against bad input}
    el:word;                       {length of eob code=code 256}

begin
  if n>256 then el:=pword(longint(b)+256*sizeof(word))^
           else el:=BMAX;
  {generate counts for each bit length}
  fillchar(c,sizeof(c),#0);
  p:=b; i:=n;                      {p points to array of word}
  repeat
    if p^>b_max then begin
      t^:=nil;
      m:=0;
      huft_build:=huft_error;
      exit
    end;
    inc(c[p^]);
    inc(longint(p),sizeof(word));   {point to next item}
    dec(i);
  until i=0;
  if c[0]=n then begin
    t^:=nil;
    m:=0;
    huft_build:=huft_complete;
    exit
  end;

  {find minimum and maximum length, bound m by those} 
  j:=1;
  while (j<=b_max) and (c[j]=0) do inc(j);
  k:=j;
  if m<j then m:=j;
  i:=b_max;
  while (i>0) and (c[i]=0) do dec(i);
  g:=i;
  if m>i then m:=i;

  {adjust last length count to fill out codes, if needed}
  y:=1 shl j;
  while j<i do begin
    y:=y-c[j];
    if y<0 then begin
      huft_build:=huft_error;
      exit
    end;
    y:=y shl 1;
    inc(j);
  end;
  dec(y,c[i]);
  if y<0 then begin
    huft_build:=huft_error;
    exit
  end;
  inc(c[i],y);

  {generate starting offsets into the value table for each length}
  x[1]:=0;
  j:=0;
  p:=@c; inc(longint(p),sizeof(word));
  xp:=@x;inc(longint(xp),2*sizeof(word));
  dec(i);
  while i<>0 do begin
    inc(j,p^);
    xp^:=j;
    inc(longint(p),2);
    inc(longint(xp),2);
    dec(i);
  end;

  {make table of values in order of bit length}
  p:=b; i:=0;
  repeat
    j:=p^;
    inc(longint(p),sizeof(word));
    if j<>0 then begin
      v[x[j]]:=i;
      inc(x[j]);
    end;
    inc(i);
  until i>=n;

  {generate huffman codes and for each, make the table entries}
  x[0]:=0; i:=0;
  p:=@v;
  h:=-1;
  l[-1]:=0;
  w:=0;
  u[0]:=nil;
  q:=nil;
  z:=0;

  {go through the bit lengths (k already is bits in shortest code)}
  for k:=k to g do begin
    for a:=c[k] downto 1 do begin
      {here i is the huffman code of length k bits for value p^}
      while k>w+l[h] do begin
        inc(w,l[h]); {Length of tables to this position}
        inc(h);
        z:=g-w;
        if z>m then z:=m;
        j:=k-w;
        f:=1 shl j;
        if f>a+1 then begin
          dec(f,a+1);
          xp:=@c[k];
          inc(j);
          tryagain:=true;
          while (j<z) and tryagain do begin
            f:=f shl 1;
            inc(longint(xp),sizeof(word));
            if f<=xp^ then tryagain:=false
                      else begin
                        dec(f,xp^);
                        inc(j);
                      end;
          end;
        end;
        if (w+j>el) and (w<el) then
          j:=el-w;       {Make eob code end at table}
        if w=0 then begin
          j:=m;  {*** Fix: main table always m bits!}
        end;
        z:=1 shl j;
        l[h]:=j;

        {allocate and link new table}
        getmem(q,(z+1)*sizeof(huft));
        if q=nil then begin
          if h<>0 then huft_free(pointer(u[0]));
          huft_build:=huft_outofmem;
          exit
        end;
        fillchar(q^,(z+1)*sizeof(huft),#0);
        q^[0].v_n:=z;  {Size of table, needed in freemem ***}
        t^:=@q^[1];     {first item starts at 1}
        t:=@q^[0].v_t;
        t^:=nil;
        q:=@q^[1];   {pointer(longint(q)+sizeof(huft));} {???}
        u[h]:=q;
        {connect to last table, if there is one}
        if h<>0 then begin  
          x[h]:=i;
          r.b:=l[h-1];         
          r.e:=16+j;
          r.v_t:=q;
          j:=(i and ((1 shl w)-1)) shr (w-l[h-1]);

          {test against bad input!}
          pt:=phuft(longint(u[h-1])-sizeof(huft));
          if j>pt^.v_n then begin
            huft_free(pointer(u[0]));
            huft_build:=huft_error;
            exit
          end;

          pt:=@u[h-1]^[j];  
          pt^:=r;
        end;
      end;

      {set up table entry in r}
      r.b:=word(k-w);
      r.v_t:=nil;   {Unused}   {***********}
      if longint(p)>=longint(@v[n]) then r.e:=99
      else if p^<s then begin
        if p^<256 then r.e:=16 else r.e:=15;
        r.v_n:=p^;
        inc(longint(p),sizeof(word));
      end else begin
        if (d=nil) or (e=nil) then begin
          huft_free(pointer(u[0]));
          huft_build:=huft_error;
          exit
        end;
        r.e:=word(e^[p^-s]);
        r.v_n:=d^[p^-s];
        inc(longint(p),sizeof(word));
      end;

      {fill code like entries with r}
      f:=1 shl (k-w);
      j:=i shr w;
      while j<z do begin
        q^[j]:=r;
        inc(j,f);
      end;

      {backwards increment the k-bit code i}
      j:=1 shl (k-1);
      while (i and j)<>0 do begin
        {i:=i^j;}
        i:=i xor j;
        j:=j shr 1;
      end;
      i:=i xor j;

      {backup over finished tables}
      while ((i and ((1 shl w)-1))<>x[h]) do begin
        dec(h);
        dec(w,l[h]); {Size of previous table!}
      end;
    end;
  end;
  if (y<>0) and (g<>1) then huft_build:=huft_incomplete
                       else huft_build:=huft_complete;
end;
