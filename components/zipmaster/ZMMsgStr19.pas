unit ZMMsgStr19;

(*
  ZMMsgStr19.pas - message string handler
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

  modified 2010-03-15
  --------------------------------------------------------------------------- *)

interface

uses
  Classes, ZipMstr19, ZMCompat19;


var
  OnZMStr: TZMLoadStrEvent;

function LoadZipStr(id: Integer): String;

// '*' = Auto, '' = default US,  language  (number = language id)
function SetZipMsgLanguage(const zl: String): String;
// get language at index (<0 - default, 0 - current)
function GetZipMsgLanguage(idx: Integer): String;
// info (-1) = language id, 0 = name, other values as per windows LOCALE_
function GetZipMsgLanguageInfo(idx: Integer; info: Cardinal): String;

function LanguageIdent(const seg: Ansistring): Ansistring;
function LocaleInfo(loc: Integer; info: Cardinal): String;

implementation

uses
  Windows, SysUtils,
{$IFDEF UNICODE}
  AnsiStrings,
{$ELSE}
  ZMUTF819,
{$ENDIF}
  ZMUtils19, ZMMsg19, ZMDefMsgs19, ZMExtrLZ7719;

{$I '.\ZMConfig19.inc'}

{$IFNDEF VERD6up}
type
  PCardinal = ^Cardinal;
{$ENDIF}

const
  SResourceMissingFor = 'Resource missing for ';
  SUSDefault = 'US: default';
  lchars = ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_'];
  Uchars = ['a' .. 'z'];
  Digits = ['0' .. '9'];

var
{$IFDEF USE_COMPRESSED_STRINGS}
  DefRes: TZMRawBytes; // default strings
{$ENDIF}
  SelRes: TZMRawBytes; // selected strings
  SelId: Cardinal;
  SelName: Ansistring;
  Setting: bool;

function LanguageIdent(const seg: Ansistring): Ansistring;
var
  c: AnsiChar;
  i: Integer;
begin
  Result := '';
  for i := 1 to length(seg) do
  begin
    c := seg[i];
    if not(c in lchars) then
    begin
      if (Result <> '') or (c <> ' ') then
        break;
    end
    else
    begin
      if (Result = '') and (c in Digits) then
        break; // must not start with digit
      if c in Uchars then
        c := AnsiChar(Ord(c) - $20); // convert to upper
      Result := Result + c;
    end;
  end;
  // Result := Uppercase(Result);
end;

// format is
// id: word, data_size: word, label_size: word, label: char[], data: byte[];... ;0
// stream at id
// returns id
function LoadFromStream(var blk: TZMRawBytes; src: TStream): Cardinal;
var
  r: Integer;
  so: TMemoryStream;
  sz: array [0 .. 2] of Word;
  szw: Integer;
begin
  blk := ''; // empty it
  Result := 0;
  if src.Read(sz[0], 3 * sizeof(Word)) <> (3 * sizeof(Word)) then
    exit;
  if src.Size < (sz[1] + sz[2] + (3 * sizeof(Word))) then
    exit;
  src.Position := src.Position + sz[2]; // skip name
  try
    so := TMemoryStream.Create;
    r := LZ77Extract(so, src, sz[1]);
    // Assert(r = 0, 'error extracting strings');
    if (r = 0) and (so.Size < 50000) then
    begin
      szw := (Integer(so.Size) + (sizeof(Word) - 1));
      SetLength(blk, szw + sizeof(Word));
      so.Position := 0;
      if so.Read(blk[1], so.Size) = so.Size then
      begin
        blk[szw + 1] := #255;
        blk[szw + 2] := #255;
        Result := sz[0];
      end
      else
        blk := '';
    end;
  finally
    FreeAndNil(so);
  end;
end;

// format is
// id: word, data_size: word, label_size: word, label: char[], data: byte[];... ;0
// positions stream to point to id
// SegName has identifier terminated by ':'
function FindInStream(src: TStream; var SegName: Ansistring; var LangId: Word)
  : Boolean;
var
  c: AnsiChar;
  i: Word;
  p: Int64;
  s: Ansistring;
  seg: Ansistring;
  ss: Int64;
  uname: Ansistring;
  w: Word;
  w3: array [0 .. 2] of Word;
begin
  Result := False;
  if not assigned(src) then
    exit;
  seg := LanguageIdent(SegName);
  if (length(seg) < 2) and (LangId = 0) then
    exit;
  uname := '';
  for i := 1 to length(SegName) do
  begin
    c := SegName[i];
    if c in Uchars then
      c := AnsiChar(Ord(c) - $20);
    uname := uname + c;
  end;
  p := src.Position;
  ss := src.Size - ((3 * sizeof(Word)) + 2); // id + dlen + nlen + min 2 chars
  while (not Result) and (p < ss) do
  begin
    src.Position := p;
    src.ReadBuffer(w3[0], 3 * sizeof(Word)); // id, dsize, nsize
    w := w3[2]; // name size
    if w > 0 then
    begin
      SetLength(s, w);
      src.ReadBuffer(s[1], w); // read name
    end;
    if LangId = 0 then
    begin
      // find by name
      Result := False;
      for i := 1 to w do
      begin
        c := s[i];
        if not(c in lchars) then
          break;
        if i > length(uname) then
        begin
          Result := False;
          break;
        end;
        if c in Uchars then
          c := AnsiChar(Ord(c) - $20);
        Result := c = uname[i];
        if not Result then
          break;
      end;
    end
    else // find by language ID
      Result := (LangId = w3[0]) or
        ((LangId < $400) and ((w3[0] and $3FF) = LangId));
    if not Result then
      p := src.Position + w3[1]; // skip data to next entry
  end;
  if Result then
  begin
    SegName := s;
    LangId := w3[0];
    src.Position := p;
  end;
end;

// format is
// id: word, data_size: word, label_size: word, label: char[], data: byte[];... ;0
// positions stream to point to id
// segname has identifier terminated by ':'
function IdInStream(src: TStream; var idx: Cardinal; var lang: String): Boolean;
var
  p: Int64;
  s: Ansistring;
  ss: Int64;
  w3: array [0 .. 2] of Word;
begin
  Result := False;
  if (idx < 1) or not assigned(src) then
    exit;
  p := src.Position;
  ss := src.Size - ((3 * sizeof(Word)) + 20); // id + dlen + nlen + 20 bytes
  if p > ss then
    exit;
  repeat
    src.ReadBuffer(w3[0], 3 * sizeof(Word)); // id, dsize, nsize
    if idx <= 1 then
      break;
    Dec(idx);
    p := src.Position + w3[1] + w3[2]; // after name + data
    if p < ss then
      src.Position := p
    else
      exit;
  until False;
  SetLength(s, w3[2]);
  src.ReadBuffer(s[1], w3[2]); // read name
  lang := String(s);
  idx := w3[0];
  src.Position := p;
  Result := True;
end;

{$IFNDEF VERD6up}
function TryStrToInt(const s: String; var v: Integer): Boolean;
begin
  if (s = '') or not CharInSet(s[1], ['0' .. '9', '$']) then
    Result := False
  else
  begin
    Result := True;
    try
      v := StrToInt(s);
    except
      on EConvertError do
        Result := False;
    end;
  end;
end;
{$ENDIF}

function SetZipMsgLanguage(const zl: String): String;
var
  i: Integer;
  id: Word;
  len: Integer;
  LangName: Ansistring;
  newBlock: TZMRawBytes;
  newId: Cardinal;
  newres: TZMRawBytes;
  res: TResourceStream;
begin
  if (zl = '') or Setting then
    exit;
  res := nil;
  try
    Setting := True;
    SelRes := ''; // reset to default
    SelId := 0;
    SelName := '';
    Result := '';
    id := 0;
    LangName := LanguageIdent(Ansistring(zl));
    if (length(LangName) < 2) then
    begin
      if zl = '*' then
        id := GetUserDefaultLCID
      else
      begin
        if (not TryStrToInt(zl, i)) or (i <= 0) or (i > $0FFFF) then
          exit;
        id := Cardinal(i);
      end;
    end;
    if (LangName <> 'US') and (id <> $0409) then // use default US
    begin
      res := OpenResStream(DZRES_Str, RT_RCData);
      if assigned(res) and FindInStream(res, LangName, id) then
      begin
        newId := LoadFromStream(newBlock, res);
        if newId > 0 then
        begin
          len := length(newBlock);
          SetLength(newres, len);
          Move(newBlock[1], PAnsiChar(newres)^, len);
          Result := String(LangName);
          SelRes := newres;
          SelName := LangName;
          SelId := newId;
        end;
      end;
    end;
  finally
    Setting := False;
    FreeAndNil(res);
  end;
end;

function LocaleInfo(loc: Integer; info: Cardinal): String;
var
  s: String;
begin
  if (loc <= 0) or (loc = $400) then
    loc := LOCALE_USER_DEFAULT;
  SetLength(s, 1024);
  GetLocaleInfo(loc and $FFFF, info, PChar(s), 1023);
  Result := PChar(s); // remove any trailing #0
end;

// get language at Idx (<0 - default, 0 - current)
// info (-1) = language id, 0 = name, other values as per windows LOCALE_
function GetZipMsgLanguageInfo(idx: Integer; info: Cardinal): String;
var
  id: Cardinal;
  res: TResourceStream;
  s: String;
begin
  id := $0409;
  Result := SUSDefault; // default US English
  if (idx = 0) and (SelRes <> '') then
  begin
    Result := String(SelName);
    id := SelId;
  end;
  if idx > 0 then
  begin
    res := nil;
    Result := '><';
    id := idx and $FF;
    try
      res := OpenResStream(DZRES_Str, RT_RCData);
      if assigned(res) and IdInStream(res, id, s) then
        Result := s;
    finally
      FreeAndNil(res);
    end;
  end;
  if Result <> '><' then
  begin
    if info = 0 then
      Result := '$' + IntToHex(id, 4)
    else if info <> Cardinal(-1) then
      Result := LocaleInfo(id, info);
  end;
end;

// get language at index (<0 - current, 0 - default, >0 - index)
function GetZipMsgLanguage(idx: Integer): String;
begin
  Result := GetZipMsgLanguageInfo(idx, Cardinal(-1));
end;

// Delphi does not like adding offset
function _ofsp(blk: PWord; ofs: Integer): PWord;
begin
  Result := blk;
  inc(Result, ofs);
end;

// returns String
function FindRes1(blkstr: TZMRawBytes; id: Integer): String;
var
  blkP: PWord;
  bp: Integer;
  DatSiz: Cardinal;
  fid: Integer;
  HedSiz: Cardinal;
  hp: Integer;
  l: Cardinal;
  mx: Integer;
  rid: Integer;
  sz: Cardinal;
  ws: WideString;
begin
  Result := '';
  if blkstr = '' then
    exit;
  fid := id div 16;
  try
    blkP := PWord(PAnsiChar(blkstr));
    bp := 0;
    mx := length(blkstr) div sizeof(Word);
    while (bp + 9) < mx do
    begin
      bp := (bp + 1) and $7FFFE; // dword align
      DatSiz := pCardinal(_ofsp(blkP, bp))^;
      HedSiz := pCardinal(_ofsp(blkP, bp + 2))^;
      if (HedSiz + DatSiz) < 8 then
        break;
      // Assert((HedSiz + DatSiz) >= 8, 'header error');
      sz := (HedSiz + DatSiz) - 8;
      hp := bp + 4;
      inc(bp, 4 + (sz div 2));
      if _ofsp(blkP, hp)^ <> $FFFF then
        continue; // bad res type
      if _ofsp(blkP, hp + 1)^ <> 6 then
        continue; // not string table
      if _ofsp(blkP, hp + 2)^ <> $FFFF then
        continue;
      rid := pred(_ofsp(blkP, hp + 3)^);
      if fid <> rid then
        continue;
      rid := rid * 16;
      inc(hp, (HedSiz - 8) div 2);
      ws := '';
      while rid < id do
      begin
        l := _ofsp(blkP, hp)^;
        inc(hp, l + 1);
        inc(rid);
      end;
      l := _ofsp(blkP, hp)^;
      if l <> 0 then
      begin
        SetLength(ws, l);
        Move(_ofsp(blkP, hp + 1)^, ws[1], l * sizeof(Widechar));
        Result := ws;
        Result := StringReplace(Result, #10, #13#10, [rfReplaceAll]);
        break;
      end;
      break;
    end;
  except
    Result := '';
  end;
end;
{$IFNDEF USE_COMPRESSED_STRINGS}

function FindConst(id: Integer): String;
var
  p: pResStringRec;

  function Find(idx: Integer): pResStringRec;
  var
    wi: Word;
    i: Integer;
  begin
    Result := nil;
    wi := Word(idx);
    for i := 0 to high(ResTable) do
      if ResTable[i].i = wi then
      begin
        Result := ResTable[i].s;
        break;
      end;
  end;

begin { FindConst }
  Result := '';
  if id < 10000 then
    exit;
  p := Find(id);
  if p <> nil then
    Result := LoadResString(p);
end;
{$ELSE}

// format is
// id: word, data_size: word, label_size: word, label: char[], data: byte[];... ;0
function LoadCompressedDef(const src): Integer;
var
  ms: TMemoryStream;
  w: Word;
  pw: PWord;
begin
  Result := -1;
  pw := @src;
  if pw^ = $0409 then
  begin
    inc(pw);
    w := pw^;
    inc(pw);
    inc(w, pw^);
    inc(w, (3 * sizeof(Word)));
    try
      ms := TMemoryStream.Create;
      ms.Write(src, w);
      ms.Position := 0;
      Result := LoadFromStream(DefRes, ms);
    finally
      FreeAndNil(ms);
    end;
  end;
end;
{$ENDIF}

// returns String
function LoadZipStr(id: Integer): String;
var
  d: String;
  blk: TZMRawBytes;
  tmpOnZipStr: TZMLoadStrEvent;
begin
  Result := '';
  blk := SelRes;
  Result := FindRes1(blk, id);
{$IFDEF USE_COMPRESSED_STRINGS}
  if Result = '' then
  begin
    if DefRes = '' then
      LoadCompressedDef(CompBlok);
    blk := DefRes;
    Result := FindRes1(blk, id);
  end;
{$ELSE}
  if Result = '' then
    Result := FindConst(id);
{$ENDIF}
  tmpOnZipStr := OnZMStr;
  if assigned(tmpOnZipStr) then
  begin
    d := Result;
    tmpOnZipStr(id, d);
    if d <> '' then
      Result := d;
  end;
  if Result = '' then
    Result := SResourceMissingFor + IntToStr(id);
end;

initialization
  OnZMStr := nil;
  Setting := False;
{$IFDEF USE_COMPRESSED_STRINGS}
  DefRes := '';
{$ENDIF}
  SelRes := '';

finalization
{$IFDEF USE_COMPRESSED_STRINGS}
  DefRes := ''; // force destruction
{$ENDIF}
  SelRes := '';

end.
