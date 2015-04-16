unit ZMCenDir19;

(*
  ZMCenDir19.pas - handles external interface to directory entries
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

  modified 2010-06-20
---------------------------------------------------------------------------*)

interface

uses
  Classes, ZipMstr19, ZMStructs19, ZMCompat19,
  ZMZipFile19, ZMIRec19, ZMCore19;

type
  TZCentralValues = (zcvDirty, zcvEmpty, zcvError, zcvBadStruct, zcvBusy);
  TZCentralStatus = set of TZCentralValues;

type
  TZMCenDir = class;

  // class to handle external directory access requests
  TZMCentralEntry = class(TZMDirEntry)
  private
    fCheck: Cardinal;
    fDir:   TZMCenDir;
    fIdx:   Cardinal;
  protected
    function Fetch(var rec: TZMIRec): Boolean;
    function GetCompressedSize: Int64; override;
    function GetCompressionMethod: Word; override;
    function GetCRC32: Cardinal; override;
    function GetDateTime: Cardinal; override;
    function GetEncoded: TZMEncodingOpts; override;
    function GetEncrypted: Boolean; override;
    function GetExtFileAttrib: Longword; override;
    function GetExtraData(Tag: Word): TZMRawBytes; override;
    function GetExtraField: TZMRawBytes; override;
    function GetExtraFieldLength: Word; override;
    function GetFileComment: TZMString; override;
    function GetFileCommentLen: Word; override;
    function GetFileName: TZMString; override;
    function GetFileNameLength: Word; override;
    function GetFlag: Word; override;
    function GetHeaderName: TZMRawBytes; override;
    function GetIntFileAttrib: Word; override;
    function GetRelOffLocalHdr: Int64; override;
    function GetStartOnDisk: Word; override;
    function GetStatusBits: Cardinal; override;
    function GetUncompressedSize: Int64; override;
    function GetVersionMadeBy: Word; override;
    function GetVersionNeeded: Word; override;
    property Check: Cardinal Read fCheck Write fCheck;
    property Idx: Cardinal Read fIdx Write fIdx;
  public
    constructor Create(Dir: TZMCenDir; idx: Integer; Check: Cardinal);
  end;

  TZMCenDir = class
  private
    fCount:         Integer;
    fCurrent:       TZMZipFile;
    fDirOnlyCount:  Integer;
    fEntries:       TList;
    fIgnoreDirOnly: Boolean;
    fLoadNo:        Integer;
    fStatus:        TZCentralStatus;
    fVerbose:       Boolean;
    fWorker:        TZMCore;
    procedure ClearEntries; //virtual;
    function GetCurrent: TZMZipFile;
    function GetEOCOffset: Int64;
    function GetMultiDisk: Boolean;
    function GetSFXOffset: Cardinal;
    function GetSOCOffset: Int64;
    function GetTotalDisks: Integer;
    function GetZipComment: Ansistring;
    function GetZipFileSize: Int64;
    procedure SetCurrent(const Value: TZMZipFile);
    procedure SetIgnoreDirOnly(Value: Boolean);
    procedure SetStatus(const Value: TZCentralStatus);
    procedure SetZipComment(const Value: Ansistring);
  protected
    function AddRecord(idx: Integer): Boolean;
    function GetDirEntry(Idx: Integer): TZMCentralEntry;
    procedure Invalidate;
    function Map: Integer;
    procedure SetCapacity(MaxEntries: Integer);
    property Worker: TZMCore Read fWorker;
  public
    constructor Create(Core: TZMCore);
    destructor Destroy; override;
    procedure Clear;
    // returns pointer to internal record
    function Entry(chk, idx: Cardinal): TZMIRec;
    function Find(const fspec: TZMString; var idx: Integer): TZMCentralEntry;
    function IndexOf(const FName: TZMString): Integer;
    function ReleaseZip: TZMZipFile;
    procedure ZipChange(Sender: TObject; idx: Integer; chng: TZCChanges);
    property Count: Integer Read fCount Write fCount;
    property Current: TZMZipFile Read GetCurrent Write SetCurrent;
    // DirEntry uses 'external' filtered index
    property DirEntry[Idx: Integer]: TZMCentralEntry read GetDirEntry; default;
    property DirOnlyCount: Integer Read fDirOnlyCount Write fDirOnlyCount;
    property EOCOffset: Int64 Read GetEOCOffset;
    property IgnoreDirOnly: Boolean Read fIgnoreDirOnly Write SetIgnoreDirOnly;
    property LoadNo: Integer Read fLoadNo Write fLoadNo;
    property MultiDisk: Boolean Read GetMultiDisk;
    property SFXOffset: Cardinal Read GetSFXOffset;
    property SOCOffset: Int64 Read GetSOCOffset;
    property Status: TZCentralStatus Read fStatus Write SetStatus;
    property TotalDisks: Integer Read GetTotalDisks;
    property Verbose: Boolean Read fVerbose Write fVerbose;
    property ZipComment: Ansistring Read GetZipComment Write SetZipComment;
    property ZipFileSize: Int64 Read GetZipFileSize;
  end;

implementation

uses SysUtils, ZMMatch19;

 {
type
  TZCChanges = (zccNone, zccBegin, zccCount, zccAdd, zccEdit, zccDelete, zccEnd);
  TZCChangeEvent = procedure(Sender: TObject; idx: integer; change: TZCChanges) of object;
  }
{TZMCenDir}
constructor TZMCenDir.Create(Core: TZMCore);
begin
  inherited Create;
  fWorker := Core;
  fEntries := TList.Create;
  fCount  := 0;
  fLoadNo := 0;
  fDirOnlyCount := 0;
end;

destructor TZMCenDir.Destroy;
begin
  ClearEntries;
  FreeAndNil(fEntries);
  FreeAndNil(fCurrent);
  inherited Destroy;
end;

function TZMCenDir.AddRecord(idx: Integer): Boolean;
var
  rec: TZMIRec;
  x: TZMCentralEntry;
begin
  Result := False;
  rec := fCurrent.Items[idx];
  if IgnoreDirOnly and rec.TestStatusBit(zsbDirOnly) then
    Inc(fDirOnlyCount)
  else
  begin
    x := fEntries.Items[fCount];
    x.Idx := idx;
    x.Check := fCurrent.CheckNo;
    Inc(fCount);
    Result := True;
  end;
end;

procedure TZMCenDir.Clear;
begin
  ClearEntries;
  FreeAndNil(fCurrent);
end;

procedure TZMCenDir.ClearEntries;
var
  i: Integer;
  tmp: TObject;
begin
  fCount := 0;
  fDirOnlyCount := 0;
  for i := 0 to pred(fEntries.Count) do
  begin
    tmp := fEntries.Items[i];
    if tmp <> nil then
    begin
      fEntries.Items[i] := nil;
      tmp.Free;
    end;
  end;
  fEntries.Clear;
end;

// return a pointer to an internal Entry
function TZMCenDir.Entry(chk, idx: Cardinal): TZMIRec;
begin
  if assigned(Current) then
    Result := fCurrent.Entry(chk, idx)
  else
    Result := nil;
end;

(*? TZMCentralDir.Find
 Find specified external filespec after idx (<0 - from beginning)
 returns pointer to Directory entry (nil - not found)
 sets idx to index of found entry (-1 not found)
*)
function TZMCenDir.Find(const fspec: TZMString; var idx: Integer): TZMCentralEntry;
var
  c: Integer;
begin
  if idx < 0 then
    idx := -1;
  c := pred(Count);
  while idx < c do
  begin
    Inc(idx);
    Result := DirEntry[idx];
    if Worker.FNMatch(fspec, Result.FileName) then
      exit;
  end;
  idx := -1;
  Result := nil;
end;

function TZMCenDir.GetCurrent: TZMZipFile;
begin
  if assigned(fCurrent) then
  begin
    if (fCurrent.info and zfi_Invalid) <> 0 then
      Current := TZMZipFile.Create(Worker); // force reload
  end
  else
    Current := TZMZipFile.Create(Worker);
  Result := fCurrent;
end;

function TZMCenDir.GetDirEntry(Idx: Integer): TZMCentralEntry;
begin
  if (Idx >= 0) and (Idx < Count) then
    Result := TZMCentralEntry(fEntries.Items[Idx])
  else
    Result := nil;
end;

function TZMCenDir.GetEOCOffset: Int64;
begin
  if assigned(Current) then
    Result := fCurrent.EOCOffset
  else
    Result := 0;
end;

function TZMCenDir.GetMultiDisk: Boolean;
begin
  if assigned(Current) then
    Result := fCurrent.MultiDisk
  else
    Result := False;
end;

function TZMCenDir.GetSFXOffset: Cardinal;
begin
  if assigned(Current) then
    Result := fCurrent.SFXOfs
  else
    Result := 0;
end;

function TZMCenDir.GetSOCOffset: Int64;
begin
  if assigned(Current) then
    Result := fCurrent.CentralOffset
  else
    Result := 0;
end;

function TZMCenDir.GetTotalDisks: Integer;
begin
  Result := 0;
  if assigned(Current) then
    Result := Current.TotalDisks;
end;

function TZMCenDir.GetZipComment: Ansistring;
begin
  if assigned(Current) then
    Result := fCurrent.ZipComment
  else
    Result := '';
end;

function TZMCenDir.GetZipFileSize: Int64;
begin
  Result := 0;
  if assigned(Current) then
    Result := Current.File_Size;
end;

(*? TZMCentralDir.IndexOf
 Find specified external filespec
  returns index of Directory entry (-1 - not found)
 Only checks unfiltered entries
*)
function TZMCenDir.IndexOf(const FName: TZMString): Integer;
begin
  for Result := 0 to pred(Count) do
    if Worker.FNMatch(FName, DirEntry[Result].FileName) then
      exit;
  Result := -1;
end;

procedure TZMCenDir.Invalidate;
var
  i: Integer;
  x: TZMCentralEntry;
begin
  fLoadNo := Worker.NextCheckNo;
  for i := 0 to fEntries.Count - 1 do
  begin
    x := fEntries.Items[i];
    x.Idx := i;
    x.Check := fLoadNo;
  end;
  fCount := 0;
end;

function TZMCenDir.Map: Integer;
var
  i:  Integer;
  x:  TZMCentralEntry;
  zc: Integer;
begin
  fDirOnlyCount := 0;
  if assigned(fCurrent) then
    zc := Current.Count
  else
    zc := 0;
  SetCapacity(zc);
  fCount := 0;
  if IgnoreDirOnly then
  begin
    for i := 0 to pred(zc) do
      AddRecord(i);
  end
  else
  begin
    for i := 0 to pred(zc) do
    begin
      x := fEntries.Items[i];
      x.Idx := i;
      x.Check := fLoadNo;
    end;
    fCount := zc;
  end;
  Result := 0;
end;

function TZMCenDir.ReleaseZip: TZMZipFile;
begin
  Result := fCurrent;
  fCurrent := nil;
  Worker.OnDirUpdate;
end;

procedure TZMCenDir.SetCapacity(MaxEntries: Integer);
var
  i: Integer;
begin
  if MaxEntries > fEntries.Count then
  begin
    fEntries.Capacity := MaxEntries;
    // populate the list
    for i := fEntries.Count to MaxEntries - 1 do
      fEntries.Add(TZMCentralEntry.Create(self, i, fLoadNo));
  end;
  Invalidate;
end;

procedure TZMCenDir.SetCurrent(const Value: TZMZipFile);
var
  cnt: Integer;
  i: Integer;
begin
  if fCurrent <> Value then
  begin
    Invalidate;       // don't free old - just mark useless
    FreeAndNil(fCurrent);
    fCurrent := Value;
    if assigned(Value) then
    begin
      fCurrent.OnChange := ZipChange;
      fLoadNo := fCurrent.CheckNo;
      cnt := fCurrent.Count;
      if cnt > 0 then
      begin
        // load entries
        SetCapacity(cnt);  // will set remap
        fCount := 0;
        for i := 0 to cnt - 1 do
          if AddRecord(i) then
            Worker.OnNewName(pred(fCount));
      end;
    end;
    Worker.OnDirUpdate;
  end;
end;

procedure TZMCenDir.SetIgnoreDirOnly(Value: Boolean);
begin
  if Value <> IgnoreDirOnly then
  begin
    fIgnoreDirOnly := Value;
    Map;
  end;
end;

procedure TZMCenDir.SetStatus(const Value: TZCentralStatus);
begin
  fStatus := Value;
end;

procedure TZMCenDir.SetZipComment(const Value: Ansistring);
begin
  //
end;

procedure TZMCenDir.ZipChange(Sender: TObject; idx: Integer; chng: TZCChanges);
begin
  case chng of
    //    zccNone: ;
    zccBegin:
      ClearEntries;
    zccCount:
      SetCapacity(idx);
    zccAdd:
      if AddRecord(idx) then
        Worker.OnNewName(pred(fCount));
//    zccEdit: ;
//    zccDelete: ;
    zccEnd:
      Worker.OnDirUpdate;
    zccCheckNo: // CheckNo changed because entries changed
      Invalidate;
  end;
end;

{ TZMCentralEntry }

constructor TZMCentralEntry.Create(Dir: TZMCenDir; idx: Integer; Check: Cardinal);
begin
  inherited Create;
  fDir := Dir;
  fIdx := idx;
  fCheck := Check;
end;

// return pointer to internal data
function TZMCentralEntry.Fetch(var rec: TZMIRec): Boolean;
begin
  Result := False;
  if assigned(fDir) then
  begin
    rec := fDir.Entry(Check, Idx);
    Result := assigned(rec);
  end;
end;

function TZMCentralEntry.GetCompressedSize: Int64;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.CompressedSize;
end;

function TZMCentralEntry.GetCompressionMethod: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.ComprMethod;
end;

function TZMCentralEntry.GetCRC32: Cardinal;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.CRC32;
end;

function TZMCentralEntry.GetDateTime: Cardinal;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.ModifDateTime;
end;

function TZMCentralEntry.GetEncoded: TZMEncodingOpts;
var
  r: TZMIRec;
begin
  Result := zeoOEM;
  if Fetch(r) then
    Result := r.IsEncoded;
end;

function TZMCentralEntry.GetEncrypted: Boolean;
var
  r: TZMIRec;
begin
  Result := False;
  if Fetch(r) then
    Result := r.Encrypted;
end;

function TZMCentralEntry.GetExtFileAttrib: Longword;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.ExtFileAttrib;
end;

function TZMCentralEntry.GetExtraData(Tag: Word): TZMRawBytes;
var
  r: TZMIRec;
begin
  Result := '';
  if Fetch(r) then
    Result := r.ExtraData[Tag];
end;

function TZMCentralEntry.GetExtraField: TZMRawBytes;
var
  r: TZMIRec;
begin
  Result := '';
  if Fetch(r) then
    Result := r.ExtraField;
end;

function TZMCentralEntry.GetExtraFieldLength: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.ExtraFieldLength;
end;

function TZMCentralEntry.GetFileComment: TZMString;
var
  r: TZMIRec;
begin
  Result := '';
  if Fetch(r) then
    Result := r.FileComment;
end;

function TZMCentralEntry.GetFileCommentLen: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.FileCommentLen;
end;

function TZMCentralEntry.GetFileName: TZMString;
var
  r: TZMIRec;
begin
  Result := '';
  if Fetch(r) then
    Result := r.FileName;
end;

function TZMCentralEntry.GetFileNameLength: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.FileNameLength;
end;

function TZMCentralEntry.GetFlag: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.Flag;
end;

function TZMCentralEntry.GetHeaderName: TZMRawBytes;
var
  r: TZMIRec;
begin
  Result := '';
  if Fetch(r) then
    Result := r.HeaderName;
end;

function TZMCentralEntry.GetIntFileAttrib: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.IntFileAttrib;
end;

function TZMCentralEntry.GetRelOffLocalHdr: Int64;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.RelOffLocal;
end;

function TZMCentralEntry.GetStartOnDisk: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.DiskStart;
end;

function TZMCentralEntry.GetStatusBits: Cardinal;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.StatusBits;
end;

function TZMCentralEntry.GetUncompressedSize: Int64;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.UncompressedSize;
end;

function TZMCentralEntry.GetVersionMadeBy: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.VersionMadeBy;
end;

function TZMCentralEntry.GetVersionNeeded: Word;
var
  r: TZMIRec;
begin
  Result := 0;
  if Fetch(r) then
    Result := r.VersionNeeded;
end;

end.

