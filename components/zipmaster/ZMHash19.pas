unit ZMHash19;

(*
  ZMHash19.pas - Hash list for entries
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

  modified 2009-04-21
---------------------------------------------------------------------------*)

interface

uses
  ZipMstr19, ZMIRec19, ZMCore19;

const
  HDEBlockEntries = 511; // number of entries per block

type
  PHashedDirEntry = ^THashedDirEntry;
  THashedDirEntry = record
    Next: PHashedDirEntry;
    ZRec: TZMIRec;
  end;

  // for speed and efficiency allocate blocks of entries
  PHDEBlock = ^THDEBlock;
  THDEBlock = packed record
    Entries: array [0..(HDEBlockEntries -1)] of THashedDirEntry;
    Next: PHDEBlock;
  end;

  TZMDirHashList = class(TObject)
  private
    fLastBlock: PHDEBlock;
    fNextEntry: Cardinal;  
{$IFNDEF UNICODE}
    FWorker: TZMCore;
{$ENDIF}
    function GetEmpty: boolean;
    function GetSize: Cardinal;
    procedure SetEmpty(const Value: boolean);
    procedure SetSize(const Value: Cardinal);
  protected
    Chains: array of PHashedDirEntry;
    fBlocks: Integer;
    //1 chain of removed nodes
    fEmpties: PHashedDirEntry;
    procedure DisposeBlocks;
    function GetEntry: PHashedDirEntry;
    function Same(Entry: PHashedDirEntry; Hash: Cardinal; const Str: String):
        Boolean;
  public
    function Add(const Rec: TZMIRec): TZMIRec;
    procedure AfterConstruction; override;
    procedure AutoSize(Req: Cardinal);
    procedure BeforeDestruction; override;
    procedure Clear;
    function Find(const FileName: String): TZMIRec;
    //1 return true if removed
    function Remove(const ZDir: TZMIRec): boolean;
    property Empty: boolean read GetEmpty write SetEmpty;
    property Size: Cardinal read GetSize write SetSize;
{$IFNDEF UNICODE}
    property Worker: TZMCore read FWorker write FWorker;
{$ENDIF}
  end;

implementation

uses
  SysUtils, Windows, ZMMatch19;

const
  ChainsMax = 65537;
  ChainsMin = 61;
  CapacityMin = 64;

function TZMDirHashList.Add(const Rec: TZMIRec): TZMIRec;
var
  Entry: PHashedDirEntry;
  Hash: Cardinal;
  Idx: Integer;
  Parent: PHashedDirEntry;
  S: String;
begin
  Assert(Rec <> nil, 'nil ZipDirEntry');
  if Chains = nil then
    Size := 1283;
  Result := nil;
  S := Rec.FileName;
  Hash := Rec.Hash;
  Idx := Hash mod Cardinal(Length(Chains));
  Entry := Chains[Idx];
  if Entry = nil then
  begin
    Entry := GetEntry;
    Entry.ZRec := Rec;
    Entry.Next := nil;
    Chains[Idx] := Entry;
  end
  else
  begin
    repeat
      if Same(Entry, Hash, S) then
      begin
        Result := Entry.ZRec;   // duplicate name
        exit;
      end;
      Parent := Entry;
      Entry := Entry.Next;
      if Entry = nil then
      begin
        Entry := GetEntry;
        Entry.ZRec := nil;
        Parent.Next := Entry;
      end;
    until (Entry.ZRec = nil);
    // we have an entry so fill in the details
    Entry.ZRec := Rec;
    Entry.Next := nil;
  end;
end;

procedure TZMDirHashList.AfterConstruction;
begin
  inherited;
  fBlocks := 0;
  fLastBlock := nil;
  fEmpties := nil;
  fNextEntry := HIGH(Cardinal);
end;

// set size to a reasonable prime number
procedure TZMDirHashList.AutoSize(Req: Cardinal);
const
  PrimeSizes: array[0..29] of Cardinal =
  (61, 131, 257, 389, 521, 641, 769, 1031, 1283, 1543, 2053, 2579, 3593,
   4099, 5147, 6151, 7177, 8209, 10243, 12289, 14341, 16411, 18433, 20483,
   22521, 24593, 28687, 32771, 40961, 65537);
var
  i: Integer;
begin
  if Req < 12000 then
  begin
    // use next higher size
    for i := 0 to HIGH(PrimeSizes) do
      if PrimeSizes[i] >= Req then
      begin
        Req := PrimeSizes[i];
        break;
      end;
  end
  else
  begin
    // use highest smaller size
    for i := HIGH(PrimeSizes) downto 0 do
      if PrimeSizes[i] < Req then
      begin
        Req := PrimeSizes[i];
        break;
      end;
  end;
  SetSize(Req);
end;

procedure TZMDirHashList.BeforeDestruction;
begin
  Clear;
  inherited;
end;

procedure TZMDirHashList.Clear;
begin
  DisposeBlocks;
  Chains := nil;  // empty it
end;

procedure TZMDirHashList.DisposeBlocks;
var
  TmpBlock: PHDEBlock;
begin
  while fLastBlock <> nil do
  begin
    TmpBlock := fLastBlock;
    fLastBlock := TmpBlock^.Next;
    Dispose(TmpBlock);
  end;
  fBlocks := 0;
  fLastBlock := nil;
  fEmpties := nil;
  fNextEntry := HIGH(Cardinal);
end;

function TZMDirHashList.Find(const FileName: String): TZMIRec;
var
  Entry: PHashedDirEntry;
  Hash: Cardinal;
  idx:  Cardinal;
begin
  Result := nil;
  if Chains = nil then
    exit;
  Hash := HashFunc(FileName);
  idx  := Hash mod Cardinal(Length(Chains));
  Entry := Chains[idx];
  // check entries in this chain
  while Entry <> nil do
  begin
    if Same(Entry, Hash, FileName) then
    begin
      Result := Entry.ZRec;
      break;
    end
    else
      Entry := Entry.Next;
  end;
end;

function TZMDirHashList.GetEmpty: boolean;
begin
  Result := Chains = nil;
end;

// return address in allocated block
function TZMDirHashList.GetEntry: PHashedDirEntry;
var
  TmpBlock: PHDEBlock;
begin
  if fEmpties <> nil then
  begin
    Result := fEmpties;         // last emptied
    fEmpties := fEmpties.Next;
  end
  else
  begin
    if (fBlocks < 1) or (fNextEntry >= HDEBlockEntries) then
    begin
      // we need a new block
      New(TmpBlock);
      ZeroMemory(TmpBlock, sizeof(THDEBlock));
      TmpBlock^.Next := fLastBlock;
      fLastBlock := TmpBlock;
      Inc(fBlocks);
      fNextEntry := 0;
    end;
    Result := @fLastBlock^.Entries[fNextEntry];
    Inc(fNextEntry);
  end;
end;

function TZMDirHashList.GetSize: Cardinal;
begin
  Result := Length(Chains);
end;

function TZMDirHashList.Remove(const ZDir: TZMIRec): boolean;
var
  Entry: PHashedDirEntry;
  FileName: String;
  Hash: Cardinal;
  idx:  Cardinal;
  Prev: PHashedDirEntry;
begin
  Result := false;
  if (ZDir = nil) or (Chains = nil) then
    exit;
  FileName := ZDir.FileName;
  Hash := ZDir.Hash;
  idx  := Hash mod Cardinal(Length(Chains));
  Entry := Chains[idx];
  Prev := nil;
  while Entry <> nil do
  begin
    if Same(Entry, Hash, FileName) and (Entry.ZRec = ZDir) then
    begin
      // we found it so unlink it
      if Prev = nil then
      begin
        // first in chain
        Chains[idx] := Entry.Next;   // link to next
      end
      else
      begin
        Prev.Next := Entry.Next;   // link to next
      end;
      Entry.Next := fEmpties;    // link to removed
      fEmpties := Entry;
      Entry.ZRec := nil;
      Result := True;
      break;
    end
    else
    begin
      Prev := Entry;
      Entry := Entry.Next;
    end;
  end;
end;

function TZMDirHashList.Same(Entry: PHashedDirEntry; Hash: Cardinal; const Str:
    String): Boolean;
var
  IRec: TZMIRec;
begin
  IRec := Entry^.ZRec;
  Result := (Hash = IRec.Hash) and
{$IFDEF UNICODE}
    (FileNameComp(Str, IRec.FileName) = 0);
{$ELSE}                      
    (FileNameComp(Str, IRec.FileName, Worker.UseUTF8) = 0);
{$ENDIF}
end;

procedure TZMDirHashList.SetEmpty(const Value: boolean);
begin
  if Value then
    Clear;
end;

procedure TZMDirHashList.SetSize(const Value: Cardinal);
var
  TableSize: Integer;
begin
  Clear;
  if Value > 0 then
  begin
    TableSize := Value;
    // keep within reasonable limits
    if TableSize < ChainsMin then
      TableSize := ChainsMin
    else
    if TableSize > ChainsMax then
      TableSize := ChainsMax;
    SetLength(Chains, TableSize);
    ZeroMemory(Chains, Size * sizeof(PHashedDirEntry));
  end;
end;

end.
