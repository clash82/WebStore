unit ZMXcpt19;

(*
  ZMXcpt19.pas - Exception class for ZipMaster
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

  modified 2009-11-22
---------------------------------------------------------------------------*)

interface

uses
  SysUtils;
       
{$IFNDEF UNICODE}
type
  TZMXArgs = (zxaNoStr, zxaStr, zxa2Str);
{$ENDIF}

type
  EZMException = class(Exception)
{$IFNDEF UNICODE}
  private
    fArgs: TZMXArgs;
    fStr1: String;
    fStr2: string;
{$ENDIF}
  protected
    // We do not always want to see a message after an exception.
    fDisplayMsg: Boolean; 
    // We also save the Resource ID in case the resource is not linked in the application.
    fResIdent: Integer;
    constructor CreateResFmt(Ident: Integer; const Args: array of const);
  public
    constructor CreateDisp(const Message: String; const Display: Boolean);

    constructor CreateResDisp(Ident: Integer; const Display: Boolean);
    constructor CreateResInt(Ident, anInt: Integer);
    constructor CreateResStr(Ident: Integer; const Str1: String);
    constructor CreateRes2Str(Ident: Integer; const Str1, Str2: String); 
{$IFNDEF UNICODE}
    function TheMessage(AsUTF8: boolean): string;
{$ENDIF}

    property ResId: Integer Read fResIdent write fResIdent;
    property DisplayMsg: boolean Read fDisplayMsg;
  end;

type
  EZipMaster = class(EZMException)

  end;


implementation

uses
  ZMMsg19, ZMMsgStr19 {$IFNDEF UNICODE}, ZMUTF819{$ENDIF};

const
  ERRORMSG: String = 'Failed to Locate string';

// allow direct translation for negative error values
function Id(err: integer): integer;
begin
  Result := err;
  if (Result < 0) and (Result >= -TM_SystemError)
    and (Result <= -DT_Language) then
    Result := -Result;
end;

//constructor EZMException.Create(const msg: String);
//begin
//  inherited Create(msg);
//  fDisplayMsg := True;
//  fResIdent   := DS_UnknownError;
//end;

constructor EZMException.CreateDisp(const Message: String; const Display: Boolean);
begin
  inherited Create(Message);
  fDisplayMsg := Display;
  fResIdent   := DS_UnknownError;
{$IFNDEF UNICODE}
  fArgs := zxaNoStr;
{$ENDIF}
end;

constructor EZMException.CreateResFmt(Ident: Integer; const Args: array of const);
begin
//  CreateFmt(Ident, Args);
  inherited Create(ERRORMSG);
  fResIdent := Id(Ident);
  Message := LoadZipStr(fResIdent);
  Message := Format(Message, Args);
  fDisplayMsg := True;   
{$IFNDEF UNICODE}
  fArgs := zxaNoStr;
{$ENDIF}
end;

constructor EZMException.CreateResDisp(Ident: Integer; const Display: Boolean);
begin
  inherited Create(ERRORMSG);
  fResIdent := Id(Ident);
  Message := LoadZipStr(fResIdent);
  fDisplayMsg := Display;  
{$IFNDEF UNICODE}
  fArgs := zxaNoStr;
{$ENDIF}
end;

constructor EZMException.CreateResInt(Ident, anInt: Integer);
begin
  CreateResFmt(Ident, [anInt]);
end;

constructor EZMException.CreateResStr(Ident: Integer; const Str1: String);
begin
  CreateResFmt(Ident, [Str1]); 
{$IFNDEF UNICODE}
  fArgs := zxaStr;
  fStr1 := Str1;
{$ENDIF}
end;

constructor EZMException.CreateRes2Str(Ident: Integer; const Str1, Str2: String);
begin
  CreateResFmt(Ident, [Str1, Str2]);  
{$IFNDEF UNICODE}
  fArgs := zxa2Str;
  fStr1 := Str1;
  fStr2 := Str2;
{$ENDIF}
end;

{$IFNDEF UNICODE}
function EZMException.TheMessage(AsUTF8: boolean): string;
begin
  if not AsUTF8 then
    Result := Message
  else
  begin
    if fArgs <= zxaNoStr then
      Result := StrToUTF8(Message)
    else
    begin
      Result := LoadZipStr(fResIdent);
      if Result <> '' then
      begin
        // we need the format string as UTF8
        Result := StrToUTF8(Result);
        case fArgs of
          zxaStr:Result := Format(Result, [fStr1]);
          zxa2Str:Result := Format(Result, [fStr1, fStr2]);
        end;
      end;
    end;
  end;
end;
{$ENDIF}

end.
