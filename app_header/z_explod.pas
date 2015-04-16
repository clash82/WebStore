{include for unzip.pas: Explode imploded file}

{C code by info-zip group, translated to Pascal by Christian Ghisler}
{based on unz51g.zip}

{************************************* explode ********************************}

{*********************************** read in tree *****************************}
function get_tree(l:pword;n:word):integer;
var i,k,j,b:word;
    bytebuf:byte;

begin
  READBYTE(bytebuf);
  i:=bytebuf;
  inc(i);
  k:=0;
  repeat
    READBYTE(bytebuf);
    j:=bytebuf;  
    b:=(j and $F)+1;
    j:=((j and $F0) shr 4)+1;
    if (k+j)>n then begin
      get_tree:=4;
      exit
    end;
    repeat
      l^:=b;
      inc(longint(l),sizeof(word));
      inc(k);
      dec(j);
    until j=0;
    dec(i);
  until i=0;
  if k<>n then get_tree:=4 else get_tree:=0;
end;

{******************exploding, method: 8k slide, 3 trees ***********************}

function explode_lit8(tb,tl,td:phuftlist;bb,bl,bd:integer):integer;
var s:longint;
    e:word;
    n,d:word;
    w:word;
    t:phuft;
    mb,ml,md:word;
    u:word;

begin
  b:=0; k:=0; w:=0;
  u:=1;
  mb:=mask_bits[bb];
  ml:=mask_bits[bl];
  md:=mask_bits[bd];
  s:=uncompsize;
  while (s>0) and not (totalabort or zipeof) do begin
    NEEDBITS(1);
    if (b and 1)<>0 then begin  {Litteral}
      DUMPBITS(1);
      dec(s);
      NEEDBITS(bb);
      t:=@tb^[(not b) and mb];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit8:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);
      slide[w]:=char(t^.v_n);
      inc(w);
      if w=WSIZE then begin
        if not flush(w) then begin
          explode_lit8:=unzip_WriteErr;
          exit
        end;
        w:=0; u:=0;
      end;
    end else begin
      DUMPBITS(1);
      NEEDBITS(7);
      d:=b and $7F;
      DUMPBITS(7);
      NEEDBITS(bd);
      t:=@td^[(not b) and md];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit8:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);

      d:=w-d-t^.v_n;
      NEEDBITS(bl);
      t:=@tl^[(not b) and ml];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit8:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;

      DUMPBITS(t^.b);

      n:=t^.v_n;
      if e<>0 then begin
        NEEDBITS(8);
        inc(n,byte(b) and $ff);
        DUMPBITS(8);
      end;
      dec(s,n);
      repeat
        d:=d and pred(WSIZE);
        if d>w then e:=WSIZE-d else e:=WSIZE-w;
        if e>n then e:=n;
        dec(n,e);
        if (u<>0) and (w<=d) then begin
          fillchar(slide[w],e,#0);
          inc(w,e);
          inc(d,e);
        end else if (w-d>=e) then begin
          move(slide[d],slide[w],e);
          inc(w,e);
          inc(d,e);
        end else repeat
          slide[w]:=slide[d];
          inc(w);
          inc(d);
          dec(e);
        until e=0;
        if w=WSIZE then begin
          if not flush(w) then begin
            explode_lit8:=unzip_WriteErr;
            exit
          end;
          w:=0; u:=0;
        end;
      until n=0;
    end;
  end;
  if totalabort then explode_lit8:=unzip_userabort
  else
    if not flush(w) then explode_lit8:=unzip_WriteErr
  else
    if zipeof then explode_lit8:=unzip_readErr
  else
    explode_lit8:=unzip_Ok;
end;

{******************exploding, method: 4k slide, 3 trees ***********************}

function explode_lit4(tb,tl,td:phuftlist;bb,bl,bd:integer):integer;
var s:longint;
    e:word;
    n,d:word;
    w:word;
    t:phuft;
    mb,ml,md:word;
    u:word;

begin
  b:=0; k:=0; w:=0;
  u:=1;
  mb:=mask_bits[bb];
  ml:=mask_bits[bl];
  md:=mask_bits[bd];
  s:=uncompsize;
  while (s>0) and not (totalabort or zipeof) do begin
    NEEDBITS(1);
    if (b and 1)<>0 then begin  {Litteral}
      DUMPBITS(1);
      dec(s);
      NEEDBITS(bb);
      t:=@tb^[(not b) and mb];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit4:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);
      slide[w]:=char(t^.v_n);
      inc(w);
      if w=WSIZE then begin
        if not flush(w) then begin
          explode_lit4:=unzip_WriteErr;
          exit
        end;
        w:=0; u:=0;
      end;
    end else begin
      DUMPBITS(1);
      NEEDBITS(6);
      d:=b and $3F;
      DUMPBITS(6);
      NEEDBITS(bd);
      t:=@td^[(not b) and md];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit4:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);
      d:=w-d-t^.v_n;
      NEEDBITS(bl);
      t:=@tl^[(not b) and ml];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_lit4:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;

      DUMPBITS(t^.b);
      n:=t^.v_n;
      if e<>0 then begin
        NEEDBITS(8);
        inc(n,b and $ff);
        DUMPBITS(8);
      end;
      dec(s,n);
      repeat
        d:=d and pred(WSIZE);
        if d>w then e:=WSIZE-d else e:=WSIZE-w;
        if e>n then e:=n;
        dec(n,e);
        if (u<>0) and (w<=d) then begin
          fillchar(slide[w],e,#0);
          inc(w,e);
          inc(d,e);
        end else if (w-d>=e) then begin
          move(slide[d],slide[w],e);
          inc(w,e);
          inc(d,e);
        end else repeat
          slide[w]:=slide[d];
          inc(w);
          inc(d);
          dec(e);
        until e=0;
        if w=WSIZE then begin
          if not flush(w) then begin
            explode_lit4:=unzip_WriteErr;
            exit
          end;
          w:=0; u:=0;
        end;
      until n=0;
    end;
  end;
  if totalabort then explode_lit4:=unzip_userabort
  else
  if not flush(w) then explode_lit4:=unzip_WriteErr
  else
    if zipeof then explode_lit4:=unzip_readErr
  else explode_lit4:=unzip_Ok;
end;

{******************exploding, method: 8k slide, 2 trees ***********************}

function explode_nolit8(tl,td:phuftlist;bl,bd:integer):integer;
var s:longint;
    e:word;
    n,d:word;
    w:word;
    t:phuft;
    ml,md:word;
    u:word;

begin
  b:=0; k:=0; w:=0;
  u:=1;
  ml:=mask_bits[bl];
  md:=mask_bits[bd];
  s:=uncompsize;
  while (s>0) and not (totalabort or zipeof) do begin
    NEEDBITS(1);
    if (b and 1)<>0 then begin  {Litteral}
      DUMPBITS(1);
      dec(s);
      NEEDBITS(8);
      slide[w]:=char(b);
      inc(w);
      if w=WSIZE then begin
        if not flush(w) then begin
          explode_nolit8:=unzip_WriteErr;
          exit
        end;
        w:=0; u:=0;
      end;
      DUMPBITS(8);
    end else begin
      DUMPBITS(1);
      NEEDBITS(7);
      d:=b and $7F;
      DUMPBITS(7);
      NEEDBITS(bd);
      t:=@td^[(not b) and md];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_nolit8:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);

      d:=w-d-t^.v_n;
      NEEDBITS(bl);
      t:=@tl^[(not b) and ml];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_nolit8:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;

      DUMPBITS(t^.b);

      n:=t^.v_n;
      if e<>0 then begin
        NEEDBITS(8);
        inc(n,b and $ff);
        DUMPBITS(8);
      end;
      dec(s,n);
      repeat
        d:=d and pred(WSIZE);
        if d>w then e:=WSIZE-d else e:=WSIZE-w;
        if e>n then e:=n;
        dec(n,e);
        if (u<>0) and (w<=d) then begin
          fillchar(slide[w],e,#0);
          inc(w,e);
          inc(d,e);
        end else if (w-d>=e) then begin
          move(slide[d],slide[w],e);
          inc(w,e);
          inc(d,e);
        end else repeat
          slide[w]:=slide[d];
          inc(w);
          inc(d);
          dec(e);
        until e=0;
        if w=WSIZE then begin
          if not flush(w) then begin
            explode_nolit8:=unzip_WriteErr;
            exit
          end;
          w:=0; u:=0;
        end;
      until n=0;
    end;
  end;
  if totalabort then explode_nolit8:=unzip_userabort
  else
  if not flush(w) then explode_nolit8:=unzip_WriteErr
  else
    if zipeof then explode_nolit8:=unzip_readErr
  else explode_nolit8:=unzip_Ok;
end;

{******************exploding, method: 4k slide, 2 trees ***********************}

function explode_nolit4(tl,td:phuftlist;bl,bd:integer):integer;
var s:longint;
    e:word;
    n,d:word;
    w:word;
    t:phuft;
    ml,md:word;
    u:word;

begin
  b:=0; k:=0; w:=0;
  u:=1;
  ml:=mask_bits[bl];
  md:=mask_bits[bd];
  s:=uncompsize;
  while (s>0) and not (totalabort or zipeof) do begin
    NEEDBITS(1);
    if (b and 1)<>0 then begin  {Litteral}
      DUMPBITS(1);
      dec(s);
      NEEDBITS(8);
      slide[w]:=char(b);
      inc(w);
      if w=WSIZE then begin
        if not flush(w) then begin
          explode_nolit4:=unzip_WriteErr;
          exit
        end;
        w:=0; u:=0;
      end;
      DUMPBITS(8);
    end else begin
      DUMPBITS(1);
      NEEDBITS(6);
      d:=b and $3F;
      DUMPBITS(6);
      NEEDBITS(bd);
      t:=@td^[(not b) and md];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_nolit4:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;
      DUMPBITS(t^.b);
      d:=w-d-t^.v_n;
      NEEDBITS(bl);
      t:=@tl^[(not b) and ml];
      e:=t^.e;
      if e>16 then repeat
        if e=99 then begin
          explode_nolit4:=unzip_ZipFileErr;
          exit
        end;
        DUMPBITS(t^.b);
        dec(e,16);
        NEEDBITS(e);
        t:=@t^.v_t^[(not b) and mask_bits[e]];
        e:=t^.e;
      until e<=16;

      DUMPBITS(t^.b);
      n:=t^.v_n;
      if e<>0 then begin
        NEEDBITS(8);
        inc(n,b and $ff);
        DUMPBITS(8);
      end;
      dec(s,n);
      repeat
        d:=d and pred(WSIZE);
        if d>w then e:=WSIZE-d else e:=WSIZE-w;
        if e>n then e:=n;
        dec(n,e);
        if (u<>0) and (w<=d) then begin
          fillchar(slide[w],e,#0);
          inc(w,e);
          inc(d,e);
        end else if (w-d>=e) then begin
          move(slide[d],slide[w],e);
          inc(w,e);
          inc(d,e);
        end else repeat
          slide[w]:=slide[d];
          inc(w);
          inc(d);
          dec(e);
        until e=0;
        if w=WSIZE then begin
          if not flush(w) then begin
            explode_nolit4:=unzip_WriteErr;
            exit
          end;
          w:=0; u:=0;
        end;
      until n=0;
    end;
  end;
  if totalabort then explode_nolit4:=unzip_userabort
  else
  if not flush(w) then explode_nolit4:=unzip_WriteErr
  else
    if zipeof then explode_nolit4:=unzip_readErr
  else explode_nolit4:=unzip_Ok;
end;

{****************************** explode *********************************}

function explode:integer;
var r:integer;
    tb,tl,td:phuftlist;
    bb,bl,bd:integer;
    l:array[0..255] of word;

begin
  inpos:=0;
  readpos:=-1;  {Nothing read in}
  bl:=7;
  if compsize>200000 then bd:=8 else bd:=7;
  if hufttype and 4<>0 then begin
    bb:=9;
    r:=get_tree(@l[0],256);
    if r<>0 then begin
      explode:=unzip_ZipFileErr;
      exit
    end;
    r:=huft_build(@l,256,256,nil,nil,@tb,bb);
    if r<>0 then begin
      if r=huft_incomplete then huft_free(tb);
      explode:=unzip_ZipFileErr;
      exit
    end;
    r:=get_tree(@l[0],64);
    if r<>0 then begin
      huft_free(tb);
      explode:=unzip_ZipFileErr;
      exit
    end;
    r:=huft_build(@l,64,0,pushlist(@cplen3),pushlist(@extra),@tl,bl);
    if r<>0 then begin
      if r=huft_incomplete then huft_free(tl);
      huft_free(tb);
      explode:=unzip_ZipFileErr;
      exit
    end;
    r:=get_tree(@l[0],64);
    if r<>0 then begin
      huft_free(tb);
      huft_free(tl);
      explode:=unzip_ZipFileErr;
      exit
    end;
    if hufttype and 2<>0 then begin {8k}
      r:=huft_build(@l,64,0,pushlist(@cpdist8),pushlist(@extra),@td,bd);
      if r<>0 then begin
        if r=huft_incomplete then huft_free(td);
        huft_free(tb);
        huft_free(tl);
        explode:=unzip_ZipFileErr;
        exit
      end;
      r:=explode_lit8(tb,tl,td,bb,bl,bd);
    end else begin
      r:=huft_build(@l,64,0,pushlist(@cpdist4),pushlist(@extra),@td,bd);
      if r<>0 then begin
        if r=huft_incomplete then huft_free(td);
        huft_free(tb);
        huft_free(tl);
        explode:=unzip_ZipFileErr;
        exit
      end;
      r:=explode_lit4(tb,tl,td,bb,bl,bd);
    end;
    huft_free(td);
    huft_free(tl);
    huft_free(tb);
  end else begin       {No literal tree}
    r:=get_tree(@l[0],64);
    if r<>0 then begin
      explode:=unzip_ZipFileErr;
      exit
    end;
    r:=huft_build(@l,64,0,pushlist(@cplen2),pushlist(@extra),@tl,bl);
    if r<>0 then begin
      if r=huft_incomplete then huft_free(tl);
      explode:=unzip_ZipFileErr;
      exit
    end;

    r:=get_tree(@l[0],64);
    if r<>0 then begin
      huft_free(tl);
      explode:=unzip_ZipFileErr;
      exit
    end;
    if hufttype and 2<>0 then begin {8k}
      r:=huft_build(@l,64,0,pushlist(@cpdist8),pushlist(@extra),@td,bd);
      if r<>0 then begin
        if r=huft_incomplete then huft_free(td);
        huft_free(tl);
        explode:=unzip_ZipFileErr;
        exit
      end;
      r:=explode_nolit8(tl,td,bl,bd);
    end else begin
      r:=huft_build(@l,64,0,pushlist(@cpdist4),pushlist(@extra),@td,bd);
      if r<>0 then begin
        if r=huft_incomplete then huft_free(td);
        huft_free(tl);
        explode:=unzip_ZipFileErr;
        exit
      end;
      r:=explode_nolit4(tl,td,bl,bd);
    end;
    huft_free(td);
    huft_free(tl);
  end;
  explode:=r;
end;


