unit ZMWUtils19;

(*
  ZMWUtils19.pas - Windows file functions supporting Unicode names
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

  modified 2008-08-28
---------------------------------------------------------------------------*)
interface
uses
  Windows, SysUtils;
            
function FindLastW(const ws: widestring; const wc: widechar): integer;   
function FindFirstW(const ws: widestring; const wc: widechar): integer; 
function ExtractFilePathW(const path: widestring): widestring;    
function DelimitPathW(const Path: widestring; Sep: Boolean): widestring;
function DirExistsW(const Fname: WideString): boolean;  
function ForceDirectoryW(const Dir: widestring): boolean;  
function FileCreateW(const fname: widestring): cardinal;

implementation
uses
  ZMStructs19;

function FindLastW(const ws: widestring; const wc: widechar): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 1 to Length(ws) - 1 do
    if ws[i] = wc then
    begin
      Result := i;
    end;
end;

function FindFirstW(const ws: widestring; const wc: widechar): integer;
begin
  for Result := 1 to Length(ws) - 1 do
    if ws[Result] = wc then
      Exit;
  Result := -1;
end;

function ExtractFilePathW(const path: widestring): widestring;
var
  d, c: integer;
begin
  Result := '';
  c := FindFirstW(path, ':');
  d := FindLastW(path, PathDelim);
  if (d > c) and (d >= 1) then
    Result := Copy(path, 1, pred(d));
end;

function DelimitPathW(const Path: widestring; Sep: Boolean): widestring;
begin
  Result := Path;
  if Length(Path) = 0 then
  begin
    if Sep then
      Result := PathDelim{'\'};
    exit;
  end;
//  if (AnsiLastChar(Path)^ = PathDelim) <> Sep then
  if (Path[Length(Path)] = PathDelim) <> Sep then
  begin
    if Sep then
      Result := Path + PathDelim
    else
      Result := Copy(Path, 1, pred(Length(Path)));
  end;
end;

function DirExistsW(const Fname: WideString): boolean;
var
  Code: DWORD;
begin
  Result := True;                           // current directory exists

  if Fname <> '' then
  begin
    Code   := GetFileAttributesW(PWideChar(Fname));
    Result := (Code <> MAX_UNSIGNED) and
      ((FILE_ATTRIBUTE_DIRECTORY and Code) <> 0);
  end;
end;

function ForceDirectoryW(const Dir: widestring): boolean;
var
  sDir: widestring;
begin
  Result := True;
  if Dir <> '' then
  begin
    sDir := DelimitPathW(Dir, False);
    if DirExistsW(sDir) or (ExtractFilePathW(sDir) = sDir) then
      exit;                                 // avoid 'c:\xyz:\' problem.

    if ForceDirectoryW(ExtractFilePathW(sDir)) then
      Result := CreateDirectoryW(PWideChar(sDir), nil)
    else
      Result := False;
  end;
end;

function FileCreateW(const fname: widestring): cardinal;
begin
  Result := CreateFileW(pWideChar(fname), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL, 0);
end;

end.
