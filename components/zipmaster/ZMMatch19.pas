unit ZMMatch19;

(*
  ZMMatch.pas - Wild filename matching
    Copyright (C) 2009, 2010  by Russell J. Peters, Roger Aelbrecht,
      Eric W. Engler and Chris Vleghert.

	This file is part of TZipMaster Version 1.9.

    TZipMaster is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TZipMaster is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with TZipMaster.  If not, see <http://www.gnu.org/licenses/>.

    contact: problems@delphizip.org (include ZipMaster in the subject).
    updates: http://www.delphizip.org
    DelphiZip maillist subscribe at http://www.freelists.org/list/delphizip

  modified 2010-08-22
---------------------------------------------------------------------------*)

interface

uses
  SysUtils, ZipMstr19;

//type
//{$IFDEF UNICODE}
//  TZMString = UnicodeString;
//  TZMWideString = UnicodeString;
//  TZMRawBytes = RawByteString;
//{$ELSE}
//  TZMString = AnsiString;
//  TZMWideString = WideString;
//  TZMRawBytes = AnsiString;
//{$ENDIF}

{$IFDEF UNICODE}
function FileNameMatch(const UPattern, USpec: TZMString): Boolean;
function FileNameComp(const s1, s2: TZMString): Integer; overload;
function FileNameComp(const s1, s2: TZMRawBytes): Integer; overload;
{$ELSE}
function FileNameMatch(const UPattern, USpec: TZMString; IsUTF8: Boolean): Boolean;
function FileNameComp(const s1, s2: TZMString; IsUTF8: Boolean): Integer;
{$ENDIF}


implementation

uses
  Windows, ZMUTF819;

type
  TBounds = record
    Start:  PWideChar;
    Finish: PWideChar;
  end;

  TParts = record
    Main: TBounds;
    Extn: TBounds;
    MainLen: Integer;
    ExtnLen: Integer;
  end;

// return <0 _ match to *, 0 _ match to end, >0 _ no match
function Wild(var Bp, Bs: TBounds): Integer;
var
  cp: Widechar;
  cs: Widechar;
begin
  Result := -1;// matches so far
  // handle matching characters before wild
  while (Bs.Start <= Bs.Finish) and (Bp.Start <= Bp.Finish) do
  begin
    cp := Bp.Start^;
    cs := Bs.Start^;
    if cp <> cs then
    begin
      if cp = '*' then
        break;     // matched to *
      // would match anything except path sep
      if (cp <> '?') or (cs = '\') then
      begin
        Result := 1;  // no match
        Exit;
      end;
    end;
    // they match
    Inc(Bp.Start);
    Inc(Bs.Start);
  end;
  // we have * or eos
  if Bp.Start > Bp.Finish then
  begin
    if Bs.Start > Bs.Finish then
      Result := 0;   // matched to end
  end;
  if Result < 0 then
  begin
    // handle matching characters from wild to end
    while Bs.Start <= Bs.Finish do
    begin
      cp := Bp.Finish^;
      cs := Bs.Finish^;
      if cp <> cs then
      begin
        if cp = '*' then
          break;
          // must not match path sep
        if (cp <> '?') or (cs = '\') then
        begin
          Result := 1;  // no match
          break;
        end;
      end;
      // they match
      Dec(Bp.Finish);
      Dec(Bs.Finish);
    end;
  end;
end;
function WildCmp(Bp, Bs: TBounds): Integer;
var
  bpt: TBounds;
  bst: TBounds;
  sm:  Integer;
  pidx: PWideChar;
  sidx: PWideChar;
begin
  // quick check for '*'
  if (Bp.Start = Bp.Finish) and (Bp.Start <> nil) and (Bp.Start^ = '*') then
  begin
    Result := 0;  // matches any/none
    exit;
  end;
  // no more Spec?
  if Bs.Finish < Bs.Start then
  begin
    if Bp.Finish < Bp.Start then
      Result := 0   // empty matches empty
    else
      Result := 3;  // no match
    exit;
  end;
  // handle matching characters before wild
  Result := Wild(Bp, Bs);       
  if Result < 0 then
  begin
    pidx := Bp.Start;
    sidx := Bs.Start;
    if Bp.Start > Bp.Finish then
    begin
      if sidx <= Bs.Finish then
        Result := 123
      else
        Result := 0;
      exit;
    end;
    // handle wild
    if (sidx <= Bs.Finish) and (pidx^ = '*') then
    begin
      // skip multiple *
      while (pidx < Bp.Finish) and ((pidx + 1)^ = '*') and (pidx^ = '*') do
        Inc(pidx);
      // end of Pattern?
      if pidx = Bp.Finish then
        Result := 0  // match
      else
      begin
        Inc(pidx);
        bpt.Start  := pidx;
        bpt.Finish := Bp.Finish;
        bst.Start  := sidx;
        bst.Finish := Bs.Finish;
        while (bst.Start <= bst.Finish) do
        begin
          // recursively compare sub patterns
          sm := WildCmp(bpt, bst);
          if sm = 0 then
          begin
            Result := 0;  // match
            break;
          end;
          Inc(bst.Start);
        end;
        if Result <> 0 then
          Result := 1;  // no match
      end;
    end;
    // end of Spec - Pattern must only have *
    if Result < 0 then
    begin
      while (pidx <= Bp.Finish) and (pidx^ = '*') do
        Inc(pidx);
      if pidx > Bp.Finish then
        Result := 0;  // matched
    end;
  end;
end;


// returned bit values
const
  MAIN = $01; // not empty
  MAIN_WILDALL = $02; // is *
  MAIN_HASWILD = $04;
  EXTN         = $10;
  EXTN_WILDALL = $20;
  EXTN_HASWILD = $40;
  HAD_DOT      = $08;

function Decompose(var idx: PWideChar; var parts: TParts): Integer;
var
  c: Widechar;
  ExtnFinish: pwideChar;
  ExtnStart: pwideChar;
  MainFinish: pwideChar;
  MainStart: pwideChar;
  mwildall: Integer;
  tmp: PWideChar;
  xwildall: Integer;
begin
  Result := 0;
  mwildall := 0;
  xwildall := 0;
//  parts.MainLen := 0;
  parts.ExtnLen := 0;
  ExtnStart := nil;
  ExtnFinish := nil;
  // at start of text or spec
  MainStart := idx;     
  MainFinish := nil; // keep compiler happy
  while True do 
  begin
    c := idx^;
    case c of
      '.':
      if idx > MainStart then
      begin
        // we probably have extn
        if ExtnStart <> nil then
          Inc(mwildall, xwildall); // count all * in main
        ExtnStart := idx+ 1;
        xwildall := 0;
      end;
      '\', '/', ':':
      begin             
        if c = '/' then
          idx^ := '\'; // normalise path seps
        if ExtnStart <> nil then
        begin
          // was false start of extn
          ExtnStart := nil;
          Inc(mwildall, xwildall); // count all * in main
          xwildall := 0;
        end;
      end;
      ' ':
      begin
        // space can be embedded but cannot trail
        tmp := idx;                                
        Inc(idx);
        while idx^ = ' ' do
          Inc(idx);
        if idx^ < ' ' then
        begin
          // terminate
          MainFinish := tmp - 1;
          Break;
        end;
        if idx^ = '|' then
        begin
          // terminate
          MainFinish := tmp - 1;
          Inc(idx);
          Break;
        end;
        Continue;
      end;
      #0..#31:
      begin
        // control terminates
        MainFinish := idx - 1;
        Break;
      end;
      '|':
      begin
        // at the end
        MainFinish := idx - 1; 
        Inc(idx);
        break;
      end;
      '*':    
      begin
        if ExtnStart <> nil then
          Inc(xwildall)
        else
          Inc(mwildall);
      end;
    end;
    Inc(idx);
  end;
  // was there an extension?
  if ExtnStart <> nil then
  begin
    Result := Result or HAD_DOT;
    if ExtnStart <= MainFinish then
    begin
      // we have extn
      ExtnFinish := MainFinish;
      MainFinish := ExtnStart - 2;    
      parts.Extnlen := 1 + (ExtnFinish - ExtnStart);
      Result := Result or EXTN;
      if  xwildall <> 0 then
      begin
        if xwildall = parts.Extnlen then
          Result := Result or EXTN_WILDALL;
        Result := Result or EXTN_HASWILD;
      end;
    end
    else
    begin
      // dot but no extn
      ExtnStart := nil;
      Dec(MainFinish); // before dot
    end;
  end;

  parts.Mainlen := 1 + (MainFinish - MainStart);
  if parts.Mainlen > 0 then
  begin
    Result := Result or MAIN;
    if  mwildall <> 0 then
    begin
      if mwildall = parts.Mainlen then
        Result := Result or MAIN_WILDALL;
      Result := Result or MAIN_HASWILD;
    end;
  end;
  // set resulting pointers
  parts.Main.Start := MainStart;
  parts.Main.Finish := MainFinish;
  parts.Extn.Start := ExtnStart;
  parts.Extn.Finish := ExtnFinish;
end;

// only gets called to compare same length names
function FileRCmp(var Bp, Bs: TBounds): Integer;
var
  cp: Widechar;
  cs: Widechar;
begin
  Result := 1;  // no match
  if (Bs.Start > Bs.Finish) then
    exit;
  if (Bp.Start^ <> Bs.Start^) and ((Bp.Start^ = '\') or (Bp.Start^ <> '?')) then
    exit; // cannot match
  Inc(Bs.Start);
  Inc(Bp.Start);
  while (Bs.Start <= Bs.Finish) and (Bp.Start <= Bp.Finish) do
  begin
    cp := Bp.Finish^;
    cs := Bs.Finish^;
    Dec(Bp.Finish);
    Dec(Bs.Finish);
    if cp <> cs then
    begin
      // must not match path sep
      if (cp <> '?') or (cs = '\') then
        Exit;   // no match
    end;
  end;
  Result := 0;  // match
end;

procedure ToUpperCase(var fspec: TZMWideString);
{$IFNDEF UNICODE}
var
  pw: PWideChar;
  wc: WideChar;
{$ENDIF}
begin
{$IFDEF UNICODE}
    CharUpperW(PWideChar(fspec));
{$ELSE}
  pw := PWideChar(fspec);
  if Win32MajorVersion > 4 then
    CharUpperW(pw)   // not implemented for earlier versions
  else
  begin
    wc := pw^;
    while wc <> #0 do
    begin
      if (wc <= 'z') and (wc >= 'a') then
        pw^ := WideChar(Ord(wc) and $DF);
      Inc(pw);
      wc := pw^;
    end;
  end;
{$ENDIF}
end;
(*
function PUTF8ToWideStr(const raw: PAnsiChar; len: integer): TZMWideString;
const
  MB_ERR_INVALID_CHARS = $00000008; // error for invalid chars
var
  len: Integer;
  wcnt: Integer;
  flg: Cardinal;
begin
  Result := '';
  len := Length(ustr);
  if len = 0 then
    exit;
{$IFDEF UNICODE}
    flg := MB_ERR_INVALID_CHARS;
{$ELSE}
  if Win32MajorVersion > 4 then
    flg := MB_ERR_INVALID_CHARS
  else
    flg := 0;
{$ENDIF}
  SetLength(Result, len * 2); // plenty of room
  wcnt := MultiByteToWideChar(CP_UTF8, flg, PAnsiChar(ustr), -1,
            PWideChar(Result), len * 2);
  if wcnt = 0 then    // try again assuming Ansi
    wcnt := MultiByteToWideChar(0, flg, PAnsiChar(ustr), -1,
            PWideChar(Result), len * 2);
  if wcnt > 0 then
    dec(wcnt);  // don't want end null
  SetLength(Result, wcnt);
end;
*)

function UpperFileNameMatch(const Pattern, Spec: TZMWideString): Boolean;
const
  FULL_WILD = MAIN_WILDALL or EXTN_WILDALL;
var
  ch: WideChar;
  pFlag: Integer;
  pidx: PWideChar;
  ptn: TParts;
  sFlag: Integer;
  sidx: PWideChar;
  spc: TParts;
  spc1: TParts;
  SpecStt: PWideChar;
  xres: Integer;
begin
  Result := False;
  // check the spec if has extension
  SpecStt := PWideChar(Spec);
  sidx  := SpecStt;
  while sidx^ <= ' ' do
  begin
    if sidx^ = #0 then
      exit;
    Inc(sidx);
  end;
  sFlag := Decompose(sidx, spc);
  // now start processing each pattern
  pidx := PWideChar(Pattern);
  repeat
    ch := pidx^;
    // skip garbage or separator
    while (ch <= ' ') or (ch = '|') do
    begin
      if ch = #0 then
        exit;
      Inc(pidx);
      ch := pidx^;
    end;     
    pFlag := Decompose(pidx, ptn);
    // work out what we must test
    if ((pFlag and FULL_WILD) = FULL_WILD) or
      ((pFlag and (FULL_WILD or EXTN or HAD_DOT)) = MAIN_WILDALL) then
    begin
      Result := True;
      Break;
    end;
    if ((pFlag and (EXTN_HASWILD or EXTN)) = EXTN) and (spc.ExtnLen <> ptn.ExtnLen) then
        Continue;   // cannot match
    if ((pFlag and MAIN_HASWILD) = 0) and (spc.MainLen <> ptn.MainLen) then
        Continue;   // cannot match
    xres := -1;   // not tried to match
    // make copy of spc
    Move(spc, spc1, SizeOf(TParts));
    if (pFlag and EXTN_WILDALL) <> 0 then
      xres := 0   // ignore extn as matched
    else
    begin
      // if pattern has extn, we must 'split' spec
      if (pFlag and HAD_DOT) <> 0 then
      begin
        // check special cases
        if (pFlag and EXTN) = 0 then
        begin
          // pattern ended in dot - spec must not have extn
          if (sFlag and EXTN) <> 0 then
             Continue;    // spec has extn - cannot match
          xres := 0;  // no extn to check
        end
        else
        begin
          // spec must have extn
          if (sFlag and EXTN) = 0 then
            Continue;   // no spec extn - cannot match
        end;
      end
      else
      begin
        // no Pattern dot _ test full spec
        if ((sFlag and EXTN) <> 0) then
          spc1.Main.Finish := spc.Extn.Finish; // full spec
        xres := 0;  // only test spec
      end;

      // test extn first (if required)
      if xres < 0 then
        xres := WildCmp(ptn.Extn, spc1.Extn);
    end;
    // if extn matched test main part
    if xres = 0 then
    begin
      if (pFlag and MAIN_WILDALL) = 0 then
        begin
          if (pFlag and MAIN_HASWILD) <> 0 then
            xres := WildCmp(ptn.Main, spc1.Main)
          else
            xres := FileRCmp(ptn.Main, spc1.Main);
        end;
    end;
    // equate
    Result := xres = 0;
    // at next pattern
  until Result;
end;

{$IFDEF UNICODE}
function FileNameMatch(const UPattern, USpec: TZMString): Boolean;
var
  Pattern: TZMWideString;
  Spec: TZMWideString;
begin
  Result := False;
  if (UPattern = '') <> (USpec = '') then
    exit;
  Pattern := AnsiUpperCase(UPattern);
  Spec := AnsiUpperCase(USpec);
  Result := UpperFileNameMatch(Pattern, Spec);
end;
{$ELSE}
function FileNameMatch(const UPattern, USpec: TZMString; IsUTF8: Boolean): Boolean;
var
  Pattern: TZMWideString;
  Spec: TZMWideString;
begin
  Result := False;
  if (UPattern = '') <> (USpec = '') then
    exit;
  // convert to wide
  if  IsUTF8 then
  begin
    Pattern := PUTF8ToWideStr(PAnsiChar(UPattern), Length(UPattern));
    Spec := PUTF8ToWideStr(PAnsiChar(USpec), Length(USpec));
  end
  else
  begin
    Pattern := UPattern;
    Spec := USpec;
  end;
  ToUpperCase(Pattern);
  ToUpperCase(Spec);
  Result := UpperFileNameMatch(Pattern, Spec);
end;
{$ENDIF}

function UpperFileNameComp(const ws1, ws2: TZMWideString): Integer;
var
  idx: Integer;
  len: Integer;
  len1: integer;
  len2: integer;
  wc1: WideChar;
  wc2: WideChar;
begin
  Result := 0;
  len1 := Length(ws1);
  len2 := Length(ws2);
  len := len1;
  if Len2 < Len then
    len1 := len2;
  idx := 1;
  // handle matching characters while they do
  while idx <= Len do
  begin
    wc1 := ws1[idx];
    if wc1 = '/' then
      wc1 := '\';
    wc2 := ws2[idx];
    if wc2 = '/' then
      wc2 := '\';
    Result := Ord(wc1) - Ord(wc2);
    if Result <> 0 then
      Break;
    // they match
    Inc(idx);
  end;
  if Result = 0 then
    Result := Len1 - Len2;
end;


{$IFDEF UNICODE}
function FileNameComp(const s1, s2: TZMString): Integer;
var
  ws1: TZMWideString;
  ws2: TZMWideString;
begin
  ws1 := AnsiUpperCase(s1);
  ws2 := AnsiUpperCase(s2);
  Result := UpperFileNameComp(ws1, ws2);
end;

function FileNameComp(const s1, s2: TZMRawBytes): Integer; overload;
var
  ws1: TZMWideString;
  ws2: TZMWideString;
begin
  ws1 := PUTF8ToWideStr(PAnsiChar(s1), Length(s1));
  ws2 := PUTF8ToWideStr(PAnsiChar(s2), Length(s2));
  ToUpperCase(ws1);
  ToUpperCase(ws2);
  Result := UpperFileNameComp(ws1, ws2);
end;
{$ELSE}
function FileNameComp(const s1, s2: TZMString; IsUTF8: Boolean): Integer;
var
  ws1: TZMWideString;
  ws2: TZMWideString;
begin
  // convert to wide
  if  IsUTF8 then
  begin
    ws1 := PUTF8ToWideStr(PAnsiChar(s1), Length(s1));
    ws2 := PUTF8ToWideStr(PAnsiChar(s2), Length(s2));
  end
  else
  begin
    ws1 := s1;
    ws2 := s2;
  end;
  ToUpperCase(ws1);
  ToUpperCase(ws2);
  Result := UpperFileNameComp(ws1, ws2);
end;
{$ENDIF}

end.
