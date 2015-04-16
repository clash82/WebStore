unit ZMCompat19;
         
(*
  ZMCompat19.pas - Types and utility functions required for some compilers
  TZipMaster19 VCL by Chris Vleghert and Eric W. Engler
  v1.9
  Copyright (C) 2009  Russell Peters


  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License (licence.txt) for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  contact: problems AT delphizip DOT org
  updates: http://www.delphizip.org

  modified 2009-12-26
---------------------------------------------------------------------------*)

interface

{$I '.\ZipVers19.inc'}

{$ifndef UNICODE}
type
  TCharSet = set of AnsiChar;
{$IFDEF VERpre6}
//type
//  UTF8String    = type String;
  PCardinal = ^Cardinal;

procedure FreeAndNil(var obj);
procedure RaiseLastOSError;
function ExcludeTrailingBackslash(const fn: string): string;
function IncludeTrailingBackslash(const fn: string): string;
function AnsiSameText(const s1, s2: string): boolean;
{$ENDIF}

function CharInSet(C: AnsiChar; const CharSet: TCharSet): Boolean;


{$ENDIF}


function MakeStrP(const str: String): PAnsiChar;

implementation

uses
  SysUtils;

{$ifndef UNICODE}
function CharInSet(C: AnsiChar; const CharSet: TCharSet): Boolean;// overload;
begin
  Result := c in CharSet;
end;

{$IFDEF VERpre6}
procedure FreeAndNil(var obj);
var
  o: TObject;
begin
  o := TObject(obj);
  TObject(obj) := NIL;
  if assigned(o) then
    o.Free;
end;
{$ENDIF}

{$IFDEF VERpre6}
procedure RaiseLastOSError;
begin
  RaiseLastWin32Error;
end;
{$ENDIF}

{$IFDEF VERpre6}
function ExcludeTrailingBackslash(const fn: string): string;
begin
  if fn[Length(fn)] = '\' then
     Result := Copy(fn, 1, Length(fn) - 1)
  else
    Result := fn;
end;
{$ENDIF}

{$IFDEF VERpre6}
function IncludeTrailingBackslash(const fn: string): string;
begin       
  if fn[Length(fn)] <> '\' then
     Result := fn + '\'
  else
    Result := fn;
end;
{$ENDIF}
        

{$IFDEF VERpre6}
function AnsiSameText(const s1, s2: string): boolean;
begin
  Result := CompareText(s1, s2) = 0;
end;
{$ENDIF}

{$endif}

function MakeStrP(const str: String): PAnsiChar;
{$ifdef UNICODE}
var
  StrA: AnsiString;
{$endif}
begin
{$ifdef UNICODE}
  StrA := AnsiString(str);
  Result := AnsiStrAlloc(Length(StrA) + 1);
  StrPLCopy(Result, StrA, Length(StrA) + 1);
{$else}
  Result := StrAlloc(Length(Str) + 1);
  StrPLCopy(Result, Str, Length(Str) + 1);
{$endif}
end;

end.
