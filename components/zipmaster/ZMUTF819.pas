unit ZMUTF819;

(*
  ZMUTF19.pas - Some UTF8/16 utility functions
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

  modified 2009-06-25
---------------------------------------------------------------------------*)

{$INCLUDE '.\ZipVers19.inc'}

{$IFDEF VERD6up}
{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

interface

uses
  SysUtils, Windows, Classes, ZipMstr19;

// convert to/from UTF8 characters
function UTF8ToStr(const astr: UTF8String): String;
function StrToUTF8(const ustr: string): UTF8String;
function StrToUTFEx(const astr: AnsiString; cp: cardinal = 0; len: integer =
    -1): TZMString;
function UTF8ToWide(const astr: UTF8String; len: integer = -1): TZMWideString;
function PWideToUTF8(const pwstr: PWideChar; len: integer = -1): UTF8String;
function WideToUTF8(const astr: TZMWideString; len: integer = -1): UTF8String;

// test for valid UTF8 character(s)  > 0 _ some, 0 _ none, < 0 _ invalid
function ValidUTF8(pstr: PAnsiChar; len: integer): integer; overload;
function ValidUTF8(const str: AnsiString; len: integer = -1): integer; overload;
{$IFDEF UNICODE}
//overload;
function ValidUTF8(const str: UTF8String; len: integer = -1): integer; overload;
{$ENDIF}

// convert to UTF8 (if needed)
function AsUTF8Str(const zstr: TZMString): UTF8String;

function UTF8SeqLen(c: AnsiChar): integer;
function IsUTF8Trail(c: AnsiChar): boolean;

function PUTF8ToStr(const raw: PAnsiChar; len: integer): string;
function PUTF8ToWideStr(const raw: PAnsiChar; len: integer): TZMWideString;

function StrToWideEx(const astr: AnsiString; cp: cardinal; len: integer):
    TZMWideString;

// convert to Ansi/OEM escaping unsupported characters
function WideToSafe(const wstr: TZMWideString; ToOEM: boolean): AnsiString;

// test all characters are supported
function WideIsSafe(const wstr: TZMWideString; ToOEM: boolean): Boolean;
{$IFNDEF UNICODE}
function UTF8ToSafe(const ustr: AnsiString; ToOEM: boolean): AnsiString;
function PUTF8ToSafe(const raw: PAnsiChar; len: integer): AnsiString;
function UTF8IsSafe(const ustr: AnsiString; ToOEM: boolean): Boolean;
// only applicable when converting to OEM
function AnsiIsSafe(const ustr: AnsiString; ToOEM: boolean): Boolean;
{$ENDIF}
// -------------------------- ------------ -------------------------
implementation

uses ZMCompat19, ZMUtils19;


function PUTF8ToWideStr(const raw: PAnsiChar; len: integer): TZMWideString;
const
  MB_ERR_INVALID_CHARS = $00000008; // error for invalid chars
var
  wcnt:  integer;
  flg: cardinal;
  p: pAnsiChar;
  rlen: Integer;
begin
  Result := '';
  if (raw = nil) or (len = 0) then
    exit;
  rlen := Len;
  if len < 0 then
  begin
    len := -1;
    p := raw;
    rlen := 0;
    while p^ <> #0 do
    begin
      inc(p);
      Inc(rlen);
    end;
  end;
  rlen := rlen * 2;
{$IFDEF UNICODE}
  flg := MB_ERR_INVALID_CHARS;
{$ELSE}
  if Win32MajorVersion > 4 then
    flg := MB_ERR_INVALID_CHARS
  else
    flg := 0;
{$ENDIF}
  SetLength(Result, rlen); // plenty of room
  wcnt := MultiByteToWideChar(CP_UTF8, flg, raw, len,
            PWideChar(Result), rlen);
  if wcnt = 0 then    // try again assuming Ansi
    wcnt := MultiByteToWideChar(0, flg, raw, len,
            PWideChar(Result), rlen);
  if (wcnt > 0) and (len = -1) then
    dec(wcnt);  // don't want end null
  SetLength(Result, wcnt);
end;

function PUTF8ToStr(const raw: PAnsiChar; len: integer): string;
begin
  Result := PUTF8ToWideStr(raw, len);
end;

function PWideToUTF8(const pwstr: PWideChar; len: integer = -1): UTF8String;
var
  cnt:   integer;
begin
  Result := '';
  if len < 0 then
    len := -1;
  if len = 0 then
    exit;
  cnt := WideCharToMultiByte(CP_UTF8, 0, pwstr, len, nil, 0, nil, nil);
  if cnt > 0 then
  begin
    SetLength(Result, cnt);
    cnt := WideCharToMultiByte(CP_UTF8, 0, pwstr, len,
      PAnsiChar(Result), cnt, nil, nil);
    if cnt < 1 then
      Result := '';  // oops - something went wrong
    if (len = -1) and (Result[cnt] = #0) then
      SetLength(Result, cnt - 1); // remove trailing nul
  end//;
  else
    RaiseLastOSError;
end;

function WideToUTF8(const astr: TZMWideString; len: integer = -1): UTF8String;
begin
  if len < 0 then
    len := Length(astr);
  Result := PWideToUTF8(@astr[1], len);
end;

function UTF8ToWide(const astr: UTF8String; len: integer = -1): TZMWideString;
begin
  Result := '';
  if len < 0 then
    len := Length(astr);
  Result := PUTF8ToWideStr(PAnsiChar(astr), len);
end;

function UTF8ToStr(const astr: UTF8String): String;
begin
  Result := PUTF8ToStr(PAnsiChar(astr), Length(astr));
end;
                                                 
function StrToUTF8(const ustr: string): UTF8String;   
var
  wtemp: TZMWideString;
begin
  wtemp := ustr;
  Result := WideToUTF8(wtemp, -1);
end;

function StrToUTFEx(const astr: AnsiString; cp: cardinal = 0; len: integer =
    -1): TZMString;
var
  ws: TZMWideString;
begin
  ws := StrToWideEx(astr, cp, len);
{$IFDEF UNICODE}
  Result := ws;
{$ELSE}
  Result := StrToUTF8(ws);
{$ENDIF}
end;

function IsUTF8Trail(c: AnsiChar): boolean;
begin
  Result := (Ord(c) and $C0) = $80;
end;

function UTF8SeqLen(c: AnsiChar): integer;
var
  u8: cardinal;
begin
  Result := 1;
  u8 := ord(c);
  if u8 >= $80 then
  begin
    if (u8 and $FE) = $FC then
      Result := 6
    else
    if (u8 and $FC) = $F8 then
      Result := 5
    else
    if (u8 and $F8) = $F0 then
      Result := 4
    else
    if (u8 and $F0) = $E0 then
      Result := 3
    else
    if (u8 and $E0) = $C0 then
      Result := 2
    else
      Result := -1;  // trailing byte - invalid
  end;
end;

// test for valid UTF8 character(s)  > 0 _ some, 0 _ none, < 0 _ invalid
function ValidUTF8(const str: AnsiString; len: integer): integer;
var
  i, j, ul: integer;
begin
  if len < 0 then
    len := Length(str);
  Result := 0;
  i := 1;
  while (i <= len) do
  begin
    ul := UTF8SeqLen(str[i]);
    inc(i);
    if ul <> 1 then
    begin
      if (ul < 1) or ((i + ul -2) > len) then
      begin
        Result := -1;  // invalid
        break;
      end;
      // first in seq
      for j := 0 to ul -2  do
      begin
        if (ord(str[i]) and $C0) <> $80 then
        begin
          result := -1;
          break;
        end;
        inc(i);
      end;
      if Result >= 0 then
        inc(Result)   // was valid so count it
      else
        break;
    end;
  end;
end;

// test for valid UTF8 character(s)  > 0 _ some, 0 _ none, < 0 _ invalid
function ValidUTF8(pstr: PAnsiChar; len: integer): integer;
var
//  i,
  j, ul: integer;
begin
//  if len < 0 then
//    len := Length(str);
  Result := 0;
//  i := 1;
  while (len > 0) do
  begin
    ul := UTF8SeqLen(pstr^);
    inc(pstr);
    Dec(len);
    if ul <> 1 then
    begin
//      if (ul < 1) or ((i + ul -2) > len) then
      if (ul < 1) or (( ul -1) > len) then
      begin
        Result := -1;  // invalid
        break;
      end;
      // first in seq
      for j := 0 to ul -2  do
      begin
        if (ord(pstr^) and $C0) <> $80 then
        begin
          result := -1;
          break;
        end;
        inc(pstr);
        Dec(len);
      end;
      if Result >= 0 then
        inc(Result)   // was valid so count it
      else
        break;
    end;
  end;
end;

{$IFDEF UNICODE}
function ValidUTF8(const str: UTF8String; len: integer = -1): integer;
var
  i, j, ul: integer;
begin
  if len < 0 then
    len := Length(str);
  Result := 0;
  i := 1;
  while (i <= len) do
  begin
    ul := UTF8SeqLen(str[i]);
    inc(i);
    if ul <> 1 then
    begin
      if (ul < 1) or ((i + ul -2) > len) then
      begin
        Result := -1;  // invalid
        break;
      end;
      // first in seq
      for j := 0 to ul -2  do
      begin
        if (ord(str[i]) and $C0) <> $80 then
        begin
          result := -1;
          break;
        end;
        inc(i);
      end;
      if Result >= 0 then
        inc(Result)   // was valid so count it
      else
        break;
    end;
  end;
end;
{$ENDIF}


function AsUTF8Str(const zstr: TZMString): UTF8String;
begin
{$IFDEF UNICODE}
    Result := UTF8String(zstr);
{$ELSE}
  if ValidUTF8(zstr, -1) < 0 then
    Result := StrToUTF8(zstr)
  else
    Result := zstr;
{$ENDIF}
end;


function StrToWideEx(const astr: AnsiString; cp: cardinal; len: integer):
    TZMWideString;
var
  cnt: integer;
  s: AnsiString;
  wcnt: integer;
begin
  Result := '';
  if len < 0 then
    len := Length(astr);
  if len = 0 then
    exit;
  wcnt := MultiByteToWideChar(cp, 0, PAnsiChar(astr), len, nil, 0);
  if wcnt > 0 then
  begin
    SetLength(Result, wcnt);
    cnt := MultiByteToWideChar(cp, 0, PAnsiChar(astr), len,
      pWideChar(Result), wcnt);
    if cnt < 1 then
      Result := '';  // oops - something went wrong
  end
  else
//    RaiseLastOSError;
  begin
    s := astr;   // assume it is Ansi
    if (len > 0) and (len < length(astr)) then
      SetLength(s, len);
    Result := String(s);
  end;
end;

// convert to MultiByte escaping unsupported characters
function WideToSafe(const wstr: TZMWideString; ToOEM: boolean): AnsiString;
{$IFNDEF UNICODE}
 const WC_NO_BEST_FIT_CHARS = $00000400;
{$endif}

var
  Bad: Bool;
  c: AnsiChar;
  cnt: Integer;
  i: Integer;
  pa: PAnsiChar;
  tmp: AnsiString;
  subst: array [0..1] of AnsiChar;
  toCP: cardinal;
  wc: WideChar;
  wlen: Integer;
begin
  Result := '';
  if wstr <> '' then
  begin
    if ToOEM then
      toCP := CP_OEMCP
    else
      toCP := CP_ACP;
    subst[0] := #$1B;   // substitute char - escape
    subst[1] := #0;
    cnt := WideCharToMultiByte(ToCP, WC_NO_BEST_FIT_CHARS, PWideChar(wstr),
              Length(wstr), nil, 0, PAnsiChar(@subst), @Bad);
    if cnt > 0 then
    begin
      SetLength(Result, cnt);
      cnt := WideCharToMultiByte(ToCP, WC_NO_BEST_FIT_CHARS, PWideChar(wstr),
        Length(wstr), PAnsiChar(Result), cnt, PAnsiChar(@subst), @Bad);
      if cnt < 1 then
        Result := '';  // oops - something went wrong
    end;
    if Bad then
    begin
      tmp := Result;
      Result := '';
      pa := PAnsiChar(tmp);
      i := 1;
      wc := #0;
      wlen := Length(wstr);
      while (pa^ <> #0) do
      begin
        c := pa^;
        if i < wlen then
        begin
          wc := wstr[i];
          inc(i);
        end;
        if c = #$1B then
          Result := Result + '#$' + AnsiString(IntToHex(Ord(wc), 4))
        else
          Result := Result + c;
        pa := CharNextExA(toCP, pa, 0);
      end;
    end;
  end;
end;

{$IFNDEF UNICODE}
function UTF8ToSafe(const ustr: AnsiString; ToOEM: boolean): AnsiString;
begin
  Result := WideToSafe(UTF8ToWide(ustr), ToOEM);
end;
{$ENDIF}

{$IFNDEF UNICODE}
function PUTF8ToSafe(const raw: PAnsiChar; len: integer): AnsiString;
begin
  Result := WideToSafe(PUTF8ToWideStr(raw, len), false);
end;
{$ENDIF}

// test all characters are supported
function WideIsSafe(const wstr: TZMWideString; ToOEM: boolean): Boolean;
var
  Bad: Bool;
  cnt: Integer;
  toCP: cardinal;
begin
  Result := true;
  if ToOEM then
    toCP := CP_OEMCP
  else
    toCP := CP_ACP;
  if wstr <> '' then
  begin
    cnt := WideCharToMultiByte(toCP, 0, PWideChar(wstr), Length(wstr),
              nil, 0, nil, @Bad);
    Result := (not Bad) and (cnt > 0);
  end;
end;

{$IFNDEF UNICODE}
function UTF8IsSafe(const ustr: AnsiString; ToOEM: boolean): Boolean;
begin
  Result := WideIsSafe(UTF8ToWide(ustr), ToOEM);
end;
{$ENDIF}

{$IFNDEF UNICODE}
// only applicable when converting to OEM
function AnsiIsSafe(const ustr: AnsiString; ToOEM: boolean): Boolean;
begin
  Result := True;
  if ToOEM then
    Result := WideIsSafe(WideString(ustr), ToOEM);
end;
{$ENDIF}


end.

