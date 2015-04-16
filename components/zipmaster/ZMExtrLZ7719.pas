unit ZMExtrLZ7719;

(*
  ZMExtrLZ7719.pas - LZ77 stream expander
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

  modified 2007-11-05
---------------------------------------------------------------------------*)

interface

uses
  Classes;

// expects src at orig_size (integer), data (bytes)
function LZ77Extract(dst, src: TStream; size: integer): integer;

implementation
   
const
  N = 4096;
  NMask = $FFF; //(N-1)
  F = 16;
                 
function GetByte(var bytes: Integer; Src: TStream): Integer;
var
  cb: Byte;
begin
  Result := -1;
  if (bytes > 4) and (Src.Size > Src.Position) then
  begin
    dec(bytes);
    if Src.Read(cb, 1) = 1 then
      Result := Integer(cb)
    else
      bytes := 0;
  end;
end;

function LZ77Extract(dst, src: TStream; size: integer): integer;
var
  bits: Integer;
  Buffer: array of Byte;
  bytes: integer;
  ch: Integer;
  File_Size: integer;
  i: Integer;
  j: Integer;
  len: Integer;
  mask: Integer;
  written: integer;
begin
  bytes := size;
  if bytes < 0 then
    bytes := HIGH(Integer); 
  src.ReadBuffer(File_Size, sizeof(integer));
  written := 0;

  SetLength(Buffer, N);
  i := N - F;
  while True do
  begin
    bits := GetByte(bytes, src);
    if (bits < 0) then
      break;

    mask := 1;
    while mask < 256 do
    begin
      if (bits and mask) = 0 then
      begin
        j := GetByte(bytes, src);
        if j < 0 then
          break;
        len := GetByte(bytes, src);
        inc(j, (len and $F0) shl 4);
        len := (len and 15) + 3;
        while len > 0 do
        begin
          Buffer[i] := Buffer[j];
          dst.WriteBuffer(Buffer[i], 1);
          inc(written);
          j := succ(j) and NMask;
          i := succ(i) and NMask;
          dec(len);
        end;
      end
      else
      begin
        ch := GetByte(bytes, src);
        if ch < 0 then
          break;
        Buffer[i] := Byte(ch {and 255});
        dst.WriteBuffer(ch, 1);
        inc(written);
        i := succ(i) and NMask;
      end;
      inc(mask, mask);
    end;
  end;
  if (File_Size = written) and (bytes = 4) then
    Result := 0   // good
  else
    if bytes = 4 then
      Result := -2   // wrong length
    else
      Result := -1; // invalid data 
  Buffer := nil;
end;

end.
