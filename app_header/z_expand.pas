const DLE=144;

type 
  f_array=array[0..255,0..63] of word;        { for followers[256][64] }
  pf_array=^f_array;

procedure LoadFollowers; forward;

{*******************************/
/*  UnReduce Global Variables  */
/*******************************}

var followers:pf_array;
    Slen:array[0..255] of byte;
    factor:integer;

const L_table:array[0..4] of integer=
        (0, $7f, $3f, $1f, $0f);

      D_shift:array[0..4] of integer=
        (0, $07, $06, $05, $04);
      D_mask: array[0..4] of integer=
        (0, $01, $03, $07, $0f);

      B_table:array[0..255] of byte=
(8, 1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5,
 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7,
 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8);





{*************************/
/*  Function unreduce()  */
/*************************}

function unreduce(compression_method:word):integer;   { expand probabilistically reduced data }
var
    lchar,
    nchar,
    ExState,
    v,
    len:integer;
    s:longint;           { number of bytes left to decompress }
    w:word;              { position in output window slide[]  } 
    u:word;              { true if slide[] unflushed          }
    e,n,d,d1:word;
    mask_bits8:word;
    bitsneeded,follower:integer;

begin
  unreduce:=unzip_ok;
  zipeof:=false;

  b:=0; k:=0; w:=0;

  inpos:=0;            {Input buffer position}
  readpos:=-1;         {Nothing read}

  lchar:=0;
  v:=0;
  Len:=0;
  s:=uncompsize;
  u:=1;
  ExState:=0;

  mask_bits8:=mask_bits[8];

  new(followers);{:=pointer(@slide[$4000]);}
  fillchar(followers^,sizeof(followers^),#0);

  factor:=compression_method - 1;
  LoadFollowers;
  while (s > 0) and not zipeof do begin 
    if (Slen[lchar]=0) then begin
      NEEDBITS(8);
      nchar:=b and mask_bits8;
      DUMPBITS(8);
    end else begin
      NEEDBITS(1);
      nchar:=b and 1;
      DUMPBITS(1);
      if (nchar<>0) then begin
        NEEDBITS(8);
        nchar:=b and mask_bits8;
        DUMPBITS(8);
      end else begin
        bitsneeded:=B_table[Slen[lchar]];
        NEEDBITS(bitsneeded);
        follower:=b and mask_bits[bitsneeded];
        DUMPBITS(bitsneeded);
        nchar:=followers^[lchar,follower];
      end;
    end;
    { expand the resulting byte }
    case ExState of
      0:begin
          if (nchar <> DLE) then begin
            dec(s);
            slide[w]:=char(nchar);
            inc(w);
            if (w=$4000) then begin
              flush(w);
              w:=0;
              u:=0;
            end;
          end else
            ExState:=1;
        end;
      1:begin
          if (nchar <> 0) then begin
            V:=nchar;
            Len:= V and L_table[factor];
            if (Len=L_table[factor]) then
              ExState:=2
            else
              ExState:=3;
          end else begin
            dec(s);
            slide[w]:=char(DLE);
            inc(w);
            if (w=$4000) then begin
              flush(w);
              w:=0;
              u:=0;
            end;
            ExState:=0;
          end;
        end;
      2:begin
          inc(Len,nchar);
          ExState:=3;
        end;
      3:begin
          n:=Len+3;                                            {w: Position in slide}
          d:=w-((((V shr D_shift[factor]) and                  {n: zu schreibende Bytes}
                  D_mask[factor]) shl 8) + nchar + 1);         {d: von hier kopieren}
          dec(s,n);                                            {e: zu kopierende Bytes}
          repeat
            d:=d and $3fff;
            if d>w then d1:=d else d1:=w;
            e:=$4000-d1;
            if e>n then e:=n;
            dec(n,e);
            if (u<>0) and (w <= d) then begin
              fillchar(slide[w],e,#0);
              inc(w,e);
              inc(d,e);
            end else
              if (w - d < e)             { (assume unsigned comparison)   }
              then repeat                { slow to avoid memcpy() overlap }
                 slide[w]:=slide[d];
                 inc(w); inc(d); dec(e);
              until e=0
              else begin
                move(slide[d],slide[w],e);
                inc(w,e);
                inc(d,e);
              end;
              if (w=$4000) then begin
                flush(w);
                w:=0;
                u:=0;
              end;
          until n=0;
          ExState:=0;
        end;
    end; {case}

    { store character for next iteration }
    lchar:=nchar;
  end;
  flush(w);
  dispose(followers);
end;





{******************************/
/*  Function LoadFollowers()  */
/******************************}

procedure LoadFollowers;
var
  x,i:integer;

begin
  for x:=255 downto 0 do begin
    NEEDBITS(6);
    Slen[x]:=b and mask_bits[6];
    DUMPBITS(6);
    for i:=0  to Slen[x]-1 do begin
      NEEDBITS(8);
      followers^[x,i]:=b and mask_bits[8];
      DUMPBITS(8);
    end;
  end;
end;

