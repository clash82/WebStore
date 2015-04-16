unit ZMZipFile19;

(*
  ZMZipFile19.pas - Represents the 'Directory' of a Zip file
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

  modified 2010-06-20
---------------------------------------------------------------------------*)
interface

uses
  Classes, Windows, ZipMstr19, ZMCore19, ZMIRec19, ZMHash19, ZMWorkFile19, ZMCompat19, ZMEOC19;

type
  TZCChanges     = (zccNone, zccBegin, zccCount, zccAdd, zccEdit, zccDelete,
    zccEnd, zccCheckNo);
  TZCChangeEvent = procedure(Sender: TObject; idx: Integer;
    change: TZCChanges) of object;

type
  TVariableData = array of Byte;

type
  TZMCXFields = (zcxUncomp, zcxComp, zcxOffs, zcxStart);



type
  TZMZipFile = class(TZMEOC)
  private
    FAddOptions: TZMAddOpts;
    fCheckNo:     Cardinal;
    FEncodeAs: TZMEncodingOpts;
    fEncoding: TZMEncodingOpts;
    fEncoding_CP: Cardinal;
    fEntries:     TList;
    fEOCFileTime: TFileTime;
    FFirst: Integer;
    FIgnoreDirOnly: boolean;
    fOnChange:    TZCChangeEvent;
    fOpenRet:     Integer;
    FSelCount: integer;
    fSFXOfs:      Cardinal;
    fShowAll:     Boolean;
    fStub:        TMemoryStream;
    fUseSFX:      Boolean;
    FWriteOptions: TZMWriteOpts;
    function GetCount: Integer;
    function GetItems(Idx: Integer): TZMIRec;
    function SelectEntry(t: TZMIRec; How: TZipSelects): Boolean;
    procedure SetCount(const Value: Integer);
    procedure SetEncoding(const Value: TZMEncodingOpts);
    procedure SetEncoding_CP(const Value: Cardinal);
    procedure SetItems(Idx: Integer; const Value: TZMIRec);
    procedure SetShowAll(const Value: Boolean);
    procedure SetStub(const Value: TMemoryStream);
  protected
    fHashList: TZMDirHashList;
    function BeforeCommit: Integer; virtual;
    function CalcSizes(var NoEntries: Integer; var ToProcess: Int64;
      var CenSize: Cardinal): Integer;
    procedure ClearCachedNames;
    procedure ClearEntries;
    function EOCSize(Is64: Boolean): Cardinal;
    procedure InferNumbering;
    function Load: Integer;
    procedure MarkDirty;
    function Open1(EOConly: Boolean): Integer;
    function WriteCentral: Integer;
    property Entries: TList Read fEntries;
  public
    constructor Create(Wrkr: TZMCore); override;
    function Add(rec: TZMIRec): Integer;
    procedure AssignFrom(Src: TZMWorkFile); override;
    procedure AssignStub(from: TZMZipFile);
    procedure BeforeDestruction; override;
    procedure ClearSelection;
    function Commit(MarkLatest: Boolean): Integer;
    function CommitAppend(Last: Integer; MarkLatest: Boolean): Integer;
    procedure Replicate(Src: TZMZipFile; LastEntry: Integer);
    function Entry(Chk: Cardinal; Idx: Integer): TZMIRec;
    function FindName(const pattern: TZMString; var idx: Integer): TZMIRec;
        overload;
    function FindName(const pattern: TZMString; var idx: Integer; const myself:
        TZMIRec): TZMIRec; overload;
    function FindNameEx(const pattern: TZMString; var idx: Integer; IsWild:
        boolean): TZMIRec;
    function HasDupName(const rec: TZMIRec): Integer;
    //1 Returns the number of duplicates
    function HashContents(var HList: TZMDirHashList; what: integer): Integer;
    //1 Mark as Contents Invalid
    procedure Invalidate;
    function Next(Current: Integer): integer;
    function NextSelected(Current: Integer): integer;
    function Open(EOConly, NoLoad: Boolean): Integer;
    function PrepareWrite(typ: TZipWrites): Boolean;
    function Reopen(Mode: Cardinal): integer;
    function Select(const Pattern: TZMString; How: TZipSelects): Integer;
    function Select1(const Pattern, reject: TZMString; How: TZipSelects): Integer;
    function SelectFiles(const want, reject: TStrings; skipped: TStrings): Integer;
    function VerifyOpen: Integer;
    property AddOptions: TZMAddOpts read FAddOptions write FAddOptions;
    property CheckNo: Cardinal Read fCheckNo;
    property Count: Integer Read GetCount Write SetCount;
    // how new/modified entries will be encoded
    property EncodeAs: TZMEncodingOpts read FEncodeAs write FEncodeAs;
    // how to interpret entry strings
    property Encoding: TZMEncodingOpts read fEncoding write SetEncoding;
    property Encoding_CP: Cardinal Read fEncoding_CP Write SetEncoding_CP;
    property EOCFileTime: TFileTime Read fEOCFileTime;
    property First: Integer read FFirst;
    property IgnoreDirOnly: boolean read FIgnoreDirOnly write FIgnoreDirOnly;
    property Items[Idx: Integer]: TZMIRec Read GetItems Write SetItems; default;
    property OpenRet: Integer Read fOpenRet Write fOpenRet;
    property SelCount: integer read FSelCount;
    property SFXOfs: Cardinal Read fSFXOfs Write fSFXOfs;
    property ShowAll: Boolean Read fShowAll Write SetShowAll;
    property Stub: TMemoryStream Read fStub Write SetStub;
    property UseSFX: Boolean Read fUseSFX Write fUseSFX;
    property WriteOptions: TZMWriteOpts read FWriteOptions write FWriteOptions;
    property OnChange: TZCChangeEvent Read fOnChange Write fOnChange;
  end;

type
  TZMCopyRec = class(TZMIRec)
  private
    fLink: TZMIRec;
    procedure SetLink(const Value: TZMIRec);
  public
    constructor Create(theOwner: TZMWorkFile);
    procedure AfterConstruction; override;
    function Process: Int64; override;
    function ProcessSize: Int64; override;
    property Link: TZMIRec Read fLink Write SetLink;
  end;

type
  TZMZipCopy = class(TZMZipFile)
  protected
    function AffixZippedFile(rec: TZMIRec): Integer;
  public
    constructor Create(Wrkr: TZMCore); override;
    function AffixZippedFiles(Src: TZMZipFile; All: Boolean): Integer;
    function WriteFile(InZip: TZMZipFile; All: Boolean): Int64;
  end;

const
  BadIndex = -HIGH(Integer);

const
  zfi_Loaded: cardinal = $1000;     // central loaded
  zfi_DidLoad: cardinal = $2000;    // central loaded
  zfi_Invalid: Cardinal = $8000;    // needs reload

implementation

uses
  SysUtils, ZMMsg19, ZMXcpt19, ZMMsgStr19, ZMStructs19, ZMDelZip19,
  ZMUtils19, ZMMatch19, ZMUTF819;

{$INCLUDE '.\ZipVers19.inc'}

const
  AllSpec: String = '*.*';
  AnySpec: String = '*';

constructor TZMZipFile.Create(Wrkr: TZMCore);
begin
  inherited;
  fEntries  := TList.Create;
  fHashList := TZMDirHashList.Create;
{$IFNDEF UNICODE}
  fHashList.Worker := Worker;
{$ENDIF}
  fEncoding := Wrkr.Encoding;
  fAddOptions := wrkr.AddOptions;
  fEncodeAs := wrkr.EncodeAs;
  fEncoding_CP := wrkr.Encoding_CP;
  fIgnoreDirOnly := Wrkr.IgnoreDirOnly;
  FWriteOptions := Wrkr.WriteOptions;
end;

function TZMZipFile.Add(rec: TZMIRec): Integer;
begin
  Result := fEntries.Add(rec);
  if fHashList.Empty then
    fHashList.Add(rec);
end;

procedure TZMZipFile.AssignFrom(Src: TZMWorkFile);
begin
  inherited;
  if (Src is TZMZipFile) and (Src <> Self) then
  begin
    Replicate(TZMZipFile(Src), -1);  // copy all entries
  end;
end;

procedure TZMZipFile.AssignStub(from: TZMZipFile);
begin
  FreeAndNil(fStub);
  fStub := from.Stub;
  from.fStub := nil;
end;

function TZMZipFile.BeforeCommit: Integer;
begin
  Result := 0;
end;

procedure TZMZipFile.BeforeDestruction;
begin
  ClearEntries;
  FreeAndNil(fEntries);
  FreeAndNil(fStub);
  FreeAndNil(fHashList);
  inherited;
end;

function TZMZipFile.CalcSizes(var NoEntries: Integer; var ToProcess: Int64;
  var CenSize: Cardinal): Integer;
var
  i: Integer;
  rec: TZMIRec;
begin
  Result := 0;
  for i := 0 to Count - 1 do
  begin
    rec := Items[i];
    ToProcess := ToProcess + rec.ProcessSize;
    CenSize := CenSize + rec.CentralSize;
    Inc(NoEntries);
  end;
end;

procedure TZMZipFile.ClearCachedNames;
var
  i: Integer;
  tmp: TObject;
begin
  for i := 0 to Count - 1 do
  begin
    tmp := fEntries[i];
    if tmp is TZMIRec then
      TZMIRec(tmp).ClearCachedName;
  end;
  fHashList.Clear;
end;

procedure TZMZipFile.ClearEntries;
var
  i: Integer;
  tmp: TObject;
begin
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
  fHashList.Clear;
  FFirst := -1;
  fSelCount := 0;
end;

procedure TZMZipFile.ClearSelection;
var
  i: Integer;
  t: TZMIRec;
begin
  FSelCount := 0;
  for i := 0 to fEntries.Count - 1 do
  begin
    t := fEntries[i];
    t.Selected := False;
  end;
end;

function TZMZipFile.Commit(MarkLatest: Boolean): Integer;
var
  i: Integer;
  latest: Cardinal;
  NoEntries: Integer;
  ToDo: Int64;
  r: Integer;
  rec: TZMIRec;
  s: Cardinal;
  ToProcess: Int64;
  TotalProcess: Int64;
  w64: Int64;
  wrote: Int64;
begin
  Diag('Commit file');
  latest := 0;
  wrote  := 0;
  Result := BeforeCommit;
  if Result < 0 then
    exit;
  // calculate sizes
  NoEntries := 0;
  ToProcess := 0;
  for i := 0 to Count - 1 do
  begin
    Boss.CheckCancel;
    rec := TZMIRec(Items[i]);
    Assert(assigned(rec), ' no rec');
    ToProcess := ToProcess + rec.ProcessSize;
    Inc(NoEntries);
    if MarkLatest and (rec.ModifDateTime > Latest) then
        Latest := rec.ModifDateTime;
  end;
  // mostly right ToProcess = total compressed sizes
  TotalProcess := ToProcess;
  if UseSFX and assigned(Stub) and (Stub.size > 0) then
    TotalProcess := TotalProcess + Stub.Size;
  ProgReport(zacCount, PR_Writing, '', NoEntries + 1);
  ProgReport(zacSize, PR_Writing, '', TotalProcess);
  Diag(' to process ' + IntToStr(NoEntries) + ' entries');
  Diag(' size = ' + IntToStr(TotalProcess));
  Result := 0;
  if MarkLatest then
  begin
//    Diag(' latest date = ' + DateTimeToStr(FileDateToLocalDateTime(latest)));
    StampDate := latest;
  end;
  try
    // if out is going to split should write proper signal
    if IsMultiPart then
    begin
      s := ExtLocalSig;
      Result := Write(s, -4);
      if (Result <> 4) and (Result > 0) then
        Result := -DS_NoWrite;
      Sig := zfsMulti;
    end
    else   // write stub if required
    if UseSFX and assigned(Stub) and (Stub.size > 0) then
    begin
      // write the sfx stub
      ProgReport(zacItem, PR_SFX, '', Stub.Size);
      Stub.Position := 0;
      Result := WriteFrom(Stub, Stub.Size);
      if Result > 0 then
      begin
        wrote := Stub.Size;
        ProgReport(zacProgress, PR_SFX, '', Stub.Size);
        if ShowProgress = zspFull then
          Boss.ProgDetail.Written(wrote);
        Sig := zfsDOS; // assume correct
      end;
    end
    else
      Sig := zfsLocal;
    if (Result >= 0) and (ToProcess > 0) then
    begin
      for i := 0 to Count - 1 do
      begin
        Boss.CheckCancel;
        rec := TZMIRec(Items[i]);
        ToDo := rec.ProcessSize;
        if ToDo > 0 then
        begin
          w64 := rec.Process;
          if w64 < 0 then
          begin
            Result := w64;
            Break;
          end;
          wrote := wrote + w64;
          if ShowProgress = zspFull then
            Boss.TotalWritten := wrote;
        end;
      end;
    end;
    // finished locals and data
    if Result >= 0 then
    begin
      // write central
      Boss.ReportMsg(GE_Copying, [Boss.ZipLoadStr(DS_CopyCentral)]);
      r := WriteCentral;  // uses XProgress
      if r >= 0 then
        wrote := wrote + r;
      Diag(' wrote = ' + IntToStr(wrote));
      if r > 0 then
      begin
        Result := FinishWrite;
        if r >= 0 then
        begin
          Result := 0;
          File_Size := wrote;
          Diag('  finished ok');
        end;
      end;
    end;
  finally
    ProgReport(zacEndOfBatch, 7, '', 0);
  end;
end;

function TZMZipFile.CommitAppend(Last: Integer; MarkLatest: Boolean): Integer;
var
  i: Integer;
  latest: Cardinal;
  NoEntries: Integer;
  ToDo: Int64;
  r: Integer;
  rec: TZMIRec;
  ToProcess: Int64;
  TotalProcess: Int64;
  w64: Int64;
  wrote: Int64;
begin
  Diag('CommitAppend file');
  latest := 0;
  wrote := 0;
  // calculate sizes
  NoEntries := 0;
  ToProcess := 0;
  for i := 0 to Count - 1 do
  begin
    Boss.CheckCancel;
    rec := TZMIRec(Items[i]);
    Assert(assigned(rec), ' no rec');
    if i >= Last then
    begin
      ToProcess := ToProcess + rec.ProcessSize;
      Inc(NoEntries);
    end;
    if MarkLatest and (rec.ModifDateTime > latest) then
      latest := rec.ModifDateTime;
  end;
  // mostly right ToProcess = total compressed sizes
  TotalProcess := ToProcess;
  if UseSFX and assigned(Stub) and (Stub.size > 0) and (First < 0) then
    TotalProcess := TotalProcess + Stub.size;
  ProgReport(zacCount, PR_Writing, '', NoEntries + 1);
  ProgReport(zacSize, PR_Writing, '', TotalProcess);
  Diag(' to process ' + IntToStr(NoEntries) + ' entries');
  Diag(' size = ' + IntToStr(TotalProcess));
  Result := 0;
  if MarkLatest then
  begin
    // Diag(' latest date = ' + DateTimeToStr(FileDateToLocalDateTime(latest)));
    StampDate := latest;
  end;
  try
    // write stub if required
    if UseSFX and assigned(Stub) and (Stub.size > 0) and (First < 0) then
    begin
      // write the sfx stub
      ProgReport(zacItem, PR_SFX, '', Stub.size);
      Stub.Position := 0;
      Result := WriteFrom(Stub, Stub.size);
      if Result > 0 then
      begin
        wrote := Stub.size;
        ProgReport(zacProgress, PR_SFX, '', Stub.size);
        if ShowProgress = zspFull then
          Boss.ProgDetail.Written(wrote);
        Sig := zfsDOS; // assume correct
      end;
    end
    else
      Sig := zfsLocal;
    if (Result >= 0) and (ToProcess > 0) then
    begin
      for i := Last to Count - 1 do
      begin
        Boss.CheckCancel;
        rec := TZMIRec(Items[i]);
        ToDo := rec.ProcessSize;
        if ToDo > 0 then
        begin
          w64 := rec.Process;
          if w64 < 0 then
          begin
            Result := w64;
            Break;
          end;
          wrote := wrote + w64;
          if ShowProgress = zspFull then
            Boss.TotalWritten := wrote;
        end;
      end;
    end;
    // finished locals and data
    if Result >= 0 then
    begin
      // write central
      Boss.ReportMsg(GE_Copying, [Boss.ZipLoadStr(DS_CopyCentral)]);
      r := WriteCentral; // uses XProgress
      if r >= 0 then
        wrote := wrote + r;
      Diag(' wrote = ' + IntToStr(wrote));
      if r > 0 then
      begin
        Result := 0;
        File_Size := wrote;
        Diag('  finished ok');
      end;
    end;
  finally
    ProgReport(zacEndOfBatch, 7, '', 0);
  end;
end;

function TZMZipFile.Entry(Chk: Cardinal; Idx: Integer): TZMIRec;
begin
  Result := nil;
  if (Chk = CheckNo) and (Idx >= 0) and (Idx < Count) then
    Result := Items[Idx];
end;

// Zip64 size aproximate only
function TZMZipFile.EOCSize(Is64: Boolean): Cardinal;
begin
  Result := Cardinal(sizeof(TZipEndOfCentral) + Length(ZipComment));
  if Is64 then
    Result := Result + sizeof(TZip64EOCLocator) + sizeof(TZipEOC64) +
      (3 * sizeof(Int64));
end;

function TZMZipFile.FindName(const pattern: TZMString; var idx: Integer):
    TZMIRec;
begin
  Result := FindNameEx(pattern, idx, CanHash(pattern));
end;

function TZMZipFile.FindName(const pattern: TZMString; var idx: Integer; const
    myself: TZMIRec): TZMIRec;
begin
  if myself = nil then
    Result := FindNameEx(pattern, idx, CanHash(pattern))
  else
  begin
    myself.SetStatusBit(zsbIgnore);  // prevent 'finding' myself
    Result := FindNameEx(pattern, idx, CanHash(pattern));
    myself.ClearStatusBit(zsbIgnore);
  end;
end;

function TZMZipFile.FindNameEx(const pattern: TZMString; var idx: Integer;
    IsWild: boolean): TZMIRec;
var
  found: Boolean;
  hash: Cardinal;
begin
  found := False;
  Result := nil;   // keep compiler happy
  hash := 0;       // keep compiler happy
  if (pattern <> '') then
  begin
    // if it wild or multiple we must try to match - else only if same hash
    if (not IsWild) and (idx < 0) and (fHashList.Size > 0) then
      Result := fHashList.Find(pattern)  // do it quick
    else
    Begin
      if not IsWild then
        hash := HashFunc(pattern);
      repeat
        idx := Next(idx);
        if idx < 0 then
          break;
        Result := Entries[idx];
        if IsWild or (Result.Hash = hash) then
        begin
          found := Worker.FNMatch(pattern, Result.Filename);
          if Result.StatusBit[zsbIgnore] <> 0 then
            found := false;
        end;
      until (found);
      if not found then
        Result := nil;
    End;
  end;
  if Result = nil then
    idx := BadIndex;
end;

function TZMZipFile.GetCount: Integer;
begin
  Result := fEntries.Count;
end;

function TZMZipFile.GetItems(Idx: Integer): TZMIRec;
begin
  if Idx >= Count then
    Result := nil
  else
    Result := Entries[Idx];
end;

// searches for record with same name
function TZMZipFile.HasDupName(const rec: TZMIRec): Integer;
var
  nrec: TZMIRec;
begin
  Result := -1;
  if fHashList.Size = 0 then
    HashContents(fHashList, 0);
  nrec := fHashList.Add(rec);
  if nrec <> nil then// exists
  begin
    Diag('Duplicate FileName: ' + rec.FileName);
    for Result := 0 to Count - 1 do
    begin
      if nrec = TZMIRec(Items[Result]) then
        break;
    end;
  end;
end;

//  zsbDirty    = $1;
//  zsbSelected = $2;
//  zsbSkipped  = $4;
//  zsbIgnore   = $8;
//  zsbDirOnly  = $10;
//  zsbInvalid  = $20;
// what = -1 _ all
//  else ignore rubbish
// what = 0 _ any non rubbish
function TZMZipFile.HashContents(var HList: TZMDirHashList; what: integer):
    Integer;
const
  Skip = zsbInvalid or zsbIgnore or zsbSkipped;
var
  I: Integer;
  rec: TZMIRec;
  use: boolean;
begin
  Result := 0;
  HList.AutoSize(Count);   // make required size
  for I := 0 to Count - 1 do
  begin
    rec := Entries[i];
    if rec = nil then
      continue;
    use := what = -1;
    if (not use) then
    begin
      if (rec.StatusBit[Skip] <> 0) then
        continue;
      use := (what = 0) or (rec.StatusBit[what] <> 0);
    end;
    if use then
    begin
      if HList.Add(Entries[I]) <> nil then
        Inc(Result);  // count duplicates
    end;
  end;
end;

// Use after EOC found and FileName is last part
// if removable has proper numbered volume name we assume it is numbered volume
procedure TZMZipFile.InferNumbering;
var
  fname: string;
  num: Integer;
  numStr: string;
begin
  // only if unknown
  if (Numbering = znsNone) and (TotalDisks > 1) then
  begin
    if WorkDrive.DriveIsFloppy and AnsiSameText(WorkDrive.DiskName, VolName(DiskNr)) then
      Numbering := znsVolume
    else
    begin
      numStr := '';
      fname := ExtractNameOfFile(FileName);
      Numbering := znsExt;
      if Length(fname) > 3 then
      begin
        numStr := Copy(fname, length(fname) - 2, 3);
        num := StrToIntDef(numStr, -1);
        if num = (DiskNr + 1) then
        begin
          // ambiguous conflict
          if WorkDrive.DriveIsFixed then
          begin
            if HasSpanSig(ChangeNumberedName(FileName, 1, True)) then
              Numbering := znsName; // unless there is an orphan
          end;
        end;
      end;
    end;
  end;
end;

procedure TZMZipFile.Invalidate;
begin
  info := info or zfi_Invalid;
end;

function TZMZipFile.Load: Integer;
var
  i: Integer;
  LiE: Integer;
  OffsetDiff: Int64;
  r: Integer;
  rec: TZMIRec;
  sgn: Cardinal;
  SOCOfs: Int64;
begin
  if not IsOpen then
  begin
    Result := DS_FileOpen;
    exit;
  end;
  Result := -LI_ErrorUnknown;
  if (info and zfi_EOC) = 0 then
    exit; // should not get here if eoc has not been read
  LiE := 1;
  OffsetDiff := 0;
  ClearEntries;
  fCheckNo := TZMCore(Worker).NextCheckNo;
  if Assigned(OnChange) then
    OnChange(Self, CheckNo, zccBegin);
  SOCOfs := CentralOffset;
  try
    OffsetDiff := CentralOffset;
    // Do we have to request for a previous disk first?
    if DiskNr <> CentralDiskNo then
    begin
      SeekDisk(CentralDiskNo);
      File_Size := Seek(0, 2);
    end
    else
    if not Z64 then
    begin
      // Due to the fact that v1.3 and v1.4x programs do not change the archives
      // EOC and CEH records in case of a SFX conversion (and back) we have to
      // make this extra check.
      OffsetDiff := File_Size - (Integer(CentralSize) +
        SizeOf(TZipEndOfCentral) + ZipCommentLen);
    end;
    SOCOfs := OffsetDiff;
    // save the location of the Start Of Central dir
    SFXOfs := Cardinal(OffsetDiff);
    if SFXOfs <> SOCOfs then
      SFXOfs := 0;
    // initialize this - we will reduce it later
    if File_Size = 22 then
      SFXOfs := 0;

    if CentralOffset <> OffsetDiff then
    begin
      // We need this in the ConvertXxx functions.
      Boss.ShowZipMessage(LI_WrongZipStruct, '');
      CheckSeek(CentralOffset, 0, LI_ReadZipError);
      CheckRead(sgn, 4, DS_CEHBadRead);
      if sgn = CentralFileHeaderSig then
      begin
        SOCOfs := CentralOffset;
        // TODO warn - central size error
      end;
    end;

    // Now we can go to the start of the Central directory.
    CheckSeek(SOCOfs, 0, LI_ReadZipError);
    ProgReport(zacItem, PR_Loading, '', TotalEntries);
    // Read every entry: The central header and save the information.
{$IFDEF DEBUG}
      if Boss.Verbosity >= zvTrace then
        Diag(Format('List - expecting %d files', [TotalEntries]));
{$ENDIF}
    fEntries.Capacity := TotalEntries;
    rec := nil;
    if Assigned(OnChange) then
      OnChange(Self, TotalEntries, zccCount);
    fHashList.AutoSize(TotalEntries);
    for i := 0 to (TotalEntries - 1) do
    begin
      FreeAndNil(rec);
      rec := TZMIRec.Create(Self);
      r := rec.Read(Self);
      if r < 0 then
      begin
        FreeAndNil(rec);
        raise EZipMaster.CreateResDisp(r, True);
      end;
      if r > 0 then
        Z64 := True;
{$IFDEF DEBUG}
        if Boss.Verbosity >= zvTrace then //Trace then
          Diag(Format('List - [%d] "%s"', [i, rec.FileName]));
{$ENDIF}
      fEntries.Add(rec);
      fHashList.Add(rec);
      // Notify user, when needed, of the NextSelected entry in the ZipDir.
      if Assigned(OnChange) then
        OnChange(Self, i, zccAdd);   // change event to give TZipDirEntry

      // Calculate the earliest Local Header start
      if SFXOfs > rec.RelOffLocal then
        SFXOfs := rec.RelOffLocal;
      rec := nil; // used
      ProgReport(zacProgress, PR_Loading, '', 1);
      Boss.CheckCancel;
    end;  // for
    LiE := 0;                             // finished ok
    Result := 0;
    info := (info and not (zfi_MakeMask)) or zfi_Loaded;
  finally
    ProgReport(zacEndOfBatch, PR_Loading, '', 0);
    if LiE = 1 then
    begin
      FileName := '';
      SFXOfs := 0;
      File_Close;
    end
    else
    begin
      CentralOffset := SOCOfs;  // corrected
      // Correct the offset for v1.3 and 1.4x
      SFXOfs := SFXOfs + Cardinal(OffsetDiff - CentralOffset);
    end;

    // Let the user's program know we just refreshed the zip dir contents.
    if Assigned(OnChange) then
      OnChange(Self, Count, zccEnd);
  end;
end;

procedure TZMZipFile.MarkDirty;
begin
  info := info or zfi_Dirty;
end;

// allow current = -1 to get first
// get next index, if IgnoreDirOnly = True skip DirOnly entries
function TZMZipFile.Next(Current: Integer): Integer;
var
  cnt: Integer;
begin
  Result := BadIndex;
  if Current >= -1 then
  begin
    cnt := Entries.Count;
    if IgnoreDirOnly then
    begin
      repeat
        Inc(Current);
      until (Current >= cnt) or ((TZMIRec(Entries[Current]).StatusBits and zsbDirOnly) = 0);
    end
    else
      Inc(Current);
    if Current < cnt then
      Result := Current;
  end;
end;

// return BadIndex when no more
function TZMZipFile.NextSelected(Current: Integer): integer;
var
  k: Cardinal;
  mask: cardinal;
  rec: TZMIRec;
begin
  Result := BadIndex;
  mask := zsbSkipped or zsbSelected;
  if IgnoreDirOnly then
     mask := mask or zsbDirOnly;
  if Current >= -1 then
  begin
    while Current < Entries.Count -1 do
    begin
      inc(Current);
      rec := TZMIRec(Entries[Current]);
      if rec <> nil then
      begin
        k := rec.StatusBit[mask];
        if k = zsbSelected then
        begin
          Result := Current;
          break;
        end;
      end;
    end;
  end;
end;

function TZMZipFile.Open(EOConly, NoLoad: Boolean): Integer;
var
  r: Integer;
begin
  // verify disk loaded
  ClearFileInformation;
  info := (info and zfi_MakeMask) or zfi_Loading;
  if WorkDrive.DriveIsFixed or WorkDrive.HasMedia(False) then
  begin
    Result := Open1(EOConly);
    if (Result >= 0) then
    begin
      LastWriteTime(fEOCFileTime);
      InferNumbering;
      if not (EOConly or NoLoad) then
      begin
        info := info or zfi_EOC;
        if (Result and EOCBadComment) <> 0 then
          Boss.ShowZipMessage(DS_CECommentLen, '');
        if (Result and EOCBadStruct) <> 0 then
          Boss.ShowZipMessage(LI_WrongZipStruct, '');
        r := Load;
        if r <> 0 then
          Result := r
        else
        begin
          info := info or zfi_Loaded or zfi_DidLoad;
          SaveFileInformation;  // get details
        end;
      end;
    end;
  end
  else
    Result := -DS_NoInFile;
  OpenRet := Result;
  if Boss.Verbosity >= zvTrace then
  begin
    if Result < 0 then
      Diag('Open = ' + Boss.ZipLoadStr(-Result))
    else
      Diag('Open = ' + IntToStr(Result));
  end;
end;

function TZMZipFile.Open1(EOConly: Boolean): Integer;
var
  fn: string;
  SfxType: Integer;
  size: Integer;
begin
  SfxType := 0;   // keep compiler happy
  ReqFileName := FileName;
  fn := FileName;
  Result := OpenEOC(EOConly);
  if (Result >= 0) and (Sig = zfsDOS) then
  begin
    stub := nil;
    SfxType := CheckSFXType(handle, fn, size);
    if SfxType >= cstSFX17 then
    begin
      if Seek(0, 0) <> 0 then
        exit;
      stub := TMemoryStream.Create;
      try
        if ReadTo(stub, size) <> size then
        begin
          stub := nil;
        end;
      except
        stub := nil;
      end;
    end;
  end;
  if not (spExactName in SpanOptions) then
  begin
    if (Result >= 0) and (SfxType >= cstDetached) then
    begin    //  it is last part of detached sfx
      File_Close;
      // Get proper path and name
      FileName := IncludeTrailingBackslash(ExtractFilePath(ReqFileName)) + fn;
      // find last part
      Result := -DS_NoInFile;
    end;
    if Result < 0 then
      Result := OpenLast(EOConly, Result);
  end;
end;

function TZMZipFile.PrepareWrite(typ: TZipWrites): Boolean;
begin
  case typ of
    zwSingle:
      Result := false;
    zwMultiple:
      Result := True;
  else
    Result := zwoDiskSpan in WriteOptions;
  end;
  IsMultiPart := Result;
  if Result then
  begin
    DiskNr := 0;
    File_Close;
  end
  else
  begin
    DiskNr := -1;
  end;
end;

function TZMZipFile.Reopen(Mode: Cardinal): integer;
begin
  Result := 0;
  if (not IsOpen) or (OpenMode <> Mode) then
  begin
    File_Close;
    if Boss.Verbosity >= zvTrace then
      Diag('Trace: Reopening ' + RealFileName);
    if not File_Open(Mode) then
    begin
      Diag('Could not reopen: ' + RealFileName);
      Result := -DS_FileOpen;
    end;
  end;
  if (Result = 0) and ((info and zfi_Loaded) <> 0) and
    not VerifyFileInformation then
  begin
    Worker.Diag('File has changed! ' + RealFileName);
    // close it?
    Result := GE_FileChanged; // just complain at moment
  end;
end;

procedure TZMZipFile.Replicate(Src: TZMZipFile; LastEntry: Integer);
var
  I: Integer;
  rec: TZMIRec;
begin
  if (Src <> nil) and (Src <> Self) then
  begin
    inherited AssignFrom(Src);
    fCheckNo := Worker.NextCheckNo;
//    FAddOptions := Src.FAddOptions;
//    FEncodeAs := Src.FEncodeAs;
//    fEncoding := Src.fEncoding;
//    fEncoding_CP := Src.fEncoding_CP;
//    FIgnoreDirOnly := Src.FIgnoreDirOnly;
    fEOCFileTime := Src.fEOCFileTime;
    FFirst := Src.FFirst;
    fOnChange := Src.fOnChange;
    fOpenRet := Src.fOpenRet;
    FSelCount := Src.FSelCount;
    fSFXOfs := Src.fSFXOfs;
    fShowAll := Src.fShowAll;
    fStub := nil;
    fUseSFX := False;
    if Src.UseSFX and Assigned(Src.fStub) then
    begin
      fStub := TMemoryStream.Create;
      Src.fStub.Position := 0;
      if fStub.CopyFrom(Src.fStub, Src.fStub.Size) = Src.fStub.Size then
        fUseSFX := True
      else
        FreeAndNil(fStub);
    end;
    // add records from Src
    if (LastEntry < 0) or (LastEntry > Src.Count) then
      LastEntry := Src.Count - 1;
    for I := 0 to LastEntry do
    begin
      rec := TZMIRec.Create(self);
      rec.AssignFrom(Src[I]);
      Add(rec);
    end;
  end;
end;

// select entries matching external pattern - return number of selected entries
function TZMZipFile.Select(const Pattern: TZMString; How: TZipSelects): Integer;
var
  i: Integer;
  srch: Integer;
  t: TZMIRec;
  wild: Boolean;
begin
  Result := 0;
  // if it wild or multiple we must try to match - else only if same hash
  wild := not CanHash(pattern);
  if (Pattern = '') or (wild and ((Pattern = AllSpec) or (Pattern = AnySpec))) then
  begin
    // do all
    for i := 0 to fEntries.Count - 1 do
    begin
      t := fEntries[i];
      if SelectEntry(t, How) then
        Inc(Result);
    end;
  end
  else
  begin
    // select specific pattern
    i := -1;
    srch := 1;
    while srch <> 0 do
    begin
      t := FindNameEx(Pattern, i, wild);
      if t = nil then
        break;
      if SelectEntry(t, How) then
        Inc(Result);
      if srch > 0 then
      begin
        if wild then
          srch := -1  // search all
        else
          srch := 0;  // done
      end;
    end;
  end;
end;

// Select1 entries matching external pattern
function TZMZipFile.Select1(const Pattern, reject: TZMString;
    How: TZipSelects): Integer;
var
  args: string;
  i: Integer;
  exc: string;
  ptn: string;
  aRec: TZMIRec;
  wild: Boolean;
begin
  Result := 0;
  args := '';     // default args - empty
  exc := reject;  // default excludes
  ptn := Pattern; // need to remove switches
  // split Pattern into pattern and switches
  // if it wild or multiple we must try to match - else only if same hash
  wild := not CanHash(ptn);
  if (ptn = '') or (wild and ((ptn = AllSpec) or (ptn = AnySpec))) then
  begin
    // do all
    for i := 0 to fEntries.Count - 1 do
    begin
      aRec := fEntries[i];
      if (exc <> '') and (Worker.FNMatch(exc, aRec.Filename)) then
        Continue;
      if SelectEntry(aRec, How) then
      begin
        // set SelectArgs
        aRec.SelectArgs := args;
      end;
      Inc(Result);
    end;
  end
  else
  begin
    // Select1 specific pattern
    i := -1;
    while True do
    begin
      aRec := FindNameEx(ptn, i, wild);
      if aRec = nil then
        break;        // no matches
      if (exc = '') or not (Worker.FNMatch(exc, aRec.Filename)) then
      begin
        if SelectEntry(aRec, How) then
        begin
          // set SelectArgs
          aRec.SelectArgs := args;
        end;
        Inc(Result);
      end;
      if not wild then
        Break;    // old find first
    end;
  end;
end;

function TZMZipFile.SelectEntry(t: TZMIRec; How: TZipSelects): Boolean;
begin
  Result := t.Select(How);
  if Result then
    inc(FSelCount)
  else
    dec(FSelCount);
end;

function TZMZipFile.SelectFiles(const want, reject: TStrings; skipped:
    TStrings): Integer;
var
  a:  Integer;
  SelectsCount: Integer;
  exc: string;
  I: Integer;
  NoSelected:  Integer;
  spec: String;
begin
  Result := 0;
  ClearSelection; // clear all
  SelectsCount := want.Count;
  if (SelectsCount < 1) or (Count < 1) then
    exit;
  exc := '';
  // combine rejects into a string
  if (reject <> nil) and (reject.Count > 0) then
  begin
    exc := reject[0];
    for I := 1 to reject.Count - 1 do
      exc := exc + ZSwitchFollows + reject[I];
  end;
  // attempt to select each wanted spec
  for a := 0 to SelectsCount - 1 do
  begin
    spec := want[a];
    NoSelected := Select1(spec, exc, zzsSet);
    if NoSelected < 1 then
    begin
      // none found
      if Boss.Verbosity >= zvVerbose then
        Diag('Skipped filespec ' + spec);
      if assigned(skipped) then
        skipped.Add(spec);
    end;
    if NoSelected > 0 then
      Result := Result + NoSelected;
    if NoSelected >= Count then
      break;  // all have been done
  end;
end;

procedure TZMZipFile.SetCount(const Value: Integer);
begin
  // not allowed
end;

procedure TZMZipFile.SetEncoding(const Value: TZMEncodingOpts);
begin
  if fEncoding <> Value then
  begin
    ClearCachedNames;
    fEncoding := Value;
  end;
end;

procedure TZMZipFile.SetEncoding_CP(const Value: Cardinal);
begin
  if fEncoding_CP <> Value then
  begin
    ClearCachedNames;
    fEncoding_CP := Value;
  end;
end;

procedure TZMZipFile.SetItems(Idx: Integer; const Value: TZMIRec);
var
  tmp: TObject;
begin
  tmp := fEntries[Idx];
  if tmp <> Value then
  begin
    fEntries[Idx] := Value;
    tmp.Free;
  end;
end;

procedure TZMZipFile.SetShowAll(const Value: Boolean);
begin
  fShowAll := Value;
end;

procedure TZMZipFile.SetStub(const Value: TMemoryStream);
begin
  if fStub <> Value then
  begin
    if assigned(fStub) then
      fStub.Free;
    fStub := Value;
  end;
end;

function TZMZipFile.VerifyOpen: Integer;
var
  ft: TFileTime;
begin
  Result := DS_FileOpen;
  if not IsOpen and not File_Open(fmOpenRead or fmShareDenyWrite) then
    exit;
  if LastWriteTime(ft) then
  begin
    Result := 0;

    LastWriteTime(fEOCFileTime);
    if CompareFileTime(EOCFileTime, ft) <> 0 then
      Result := -DS_FileChanged;
  end;
end;

// returns bytes written or <0 _ error
function TZMZipFile.WriteCentral: Integer;
var
  i: Integer;
  rec: TZMIRec;
  wrote: Integer;
begin
  Result := 0;
  wrote  := 0;
  CentralOffset := Position;
  CentralDiskNo := DiskNr;
  TotalEntries := 0;
  CentralEntries := 0;
  CentralSize := 0;
  ProgReport(zacXItem, PR_CentrlDir, '', Count);
  for i := 0 to Count - 1 do
  begin
    rec := TZMIRec(Items[i]);
    if rec.StatusBit[zsbError] = 0 then
    begin
      // no processing error
      if Boss.Verbosity >= zvTrace then
        Diag('Writing central [' + IntToStr(i) + '] ' + rec.FileName);
      // check for deleted?
      Result := rec.Write;
      if Result < 0 then
        break;      // error
      if Position <= Result then    // started new part
        CentralEntries := 0;
      wrote := wrote + Result;
      CentralSize  := CentralSize + Cardinal(Result);
      TotalEntries := TotalEntries + 1;
      CentralEntries := CentralEntries + 1;
      ProgReport(zacXProgress, PR_CentrlDir, '', 1);
    end
    else
      Diag('skipped Writing central ['+ IntToStr(i) + '] ' + rec.FileName);
  end;
  // finished Central
  if Result >= 0 then
  begin
    Result := WriteEOC;
    if Result >= 0 then
    begin
      ProgReport(zacXProgress, PR_CentrlDir, '', 1);
      Result := wrote + Result;
      if Result > 0 then
      begin
        Diag('  finished ok');
      end;
    end;
  end;
end;

constructor TZMCopyRec.Create(theOwner: TZMWorkFile);
begin
  inherited Create(theOwner);
end;

procedure TZMCopyRec.AfterConstruction;
begin
  inherited;
  fLink := nil;
end;

// process record, return bytes written; <0 = -error
function TZMCopyRec.Process: Int64;
var
  did:  Int64;
  InRec: TZMIRec;
  InWorkFile: TZMWorkFile;
  stNr: Integer;
  stt:  Int64;
  ToWrite: Int64;
  wrt:  Int64;
begin
  //  ASSERT(assigned(Owner), 'no owner');
  if Owner.Boss.Verbosity >= zvVerbose then
    Owner.Boss.ReportMsg(GE_Copying, [FileName]);
  InRec := Link;
  InWorkFile := InRec.Owner;
  if Owner.Boss.Verbosity >= zvVerbose then
    Diag('Copying local');
  Result := InRec.SeekLocalData;
  if Result < 0 then
    exit;   // error
  stNr := Owner.DiskNr;
  stt  := Owner.Position;
  Result := WriteAsLocal1(ModifDateTime, CRC32);
  if Result < 0 then
    exit;   // error
  wrt := Result;
  Owner.ProgReport(zacProgress, PR_Copying, '', wrt);
  //  Diag('  finished copy local');
  // ok so update positions
  RelOffLocal := stt;
  DiskStart := stNr;
  ToWrite := CompressedSize;
  //    Diag('copying zipped data');
  Owner.ProgReport(zacItem, zprCompressed, FileName, ToWrite);
  did := Owner.CopyFrom(InWorkFile, ToWrite);
  if did <> ToWrite then
  begin
    if did < 0 then
      Result := did // write error
    else
      Result := -DS_DataCopy;
    exit;
  end;
  wrt := wrt + did;
  if (Flag and 8) <> 0 then
  begin
    did := WriteDataDesc(Owner);
    if did < 0 then
    begin
      Result := did;  // error
      exit;
    end;
    wrt := wrt + did;
    Owner.ProgReport(zacProgress, PR_Copying, '', did);
  end;
  Result := wrt;
end;

// return bytes to be processed
function TZMCopyRec.ProcessSize: Int64;
begin
  Result := CompressedSize + LocalSize;
  if (Flag and 8) <> 0 then
    Result := Result + sizeof(TZipDataDescriptor);
end;

procedure TZMCopyRec.SetLink(const Value: TZMIRec);
begin
  if fLink <> Value then
  begin
    fLink := Value;
  end;
end;

constructor TZMZipCopy.Create(Wrkr: TZMCore);
begin
  inherited Create(Wrkr);
end;

// Add a copy of source record if name is unique
function TZMZipCopy.AffixZippedFile(rec: TZMIRec): Integer;
var
  nrec: TZMCopyRec;
begin
  Result := -1;
  if HasDupName(rec) < 0 then
  begin
    // accept it
    nrec := TZMCopyRec.Create(self); // make a copy
    nrec.AssignFrom(rec);
    // clear unknowns ?
    nrec.Link := rec;  // link to original
    Result := Add(nrec);
  end;
end;

// return >=0 number added <0 error
function TZMZipCopy.AffixZippedFiles(Src: TZMZipFile; All: Boolean): Integer;
var
  i:  Integer;
  r:  Integer;
  rec: TZMIRec;
begin
  Result := 0;
  for i := 0 to Src.Count - 1 do
  begin
    rec := Src[i];
    if not assigned(rec) then
      continue;
    if All or rec.TestStatusBit(zsbSelected) then
    begin
      Diag('including: ' + rec.FileName);
      r := AffixZippedFile(rec);
      if (r >= 0) then
        Inc(Result) // added
      else
      begin
        // error
        if r < 0 then
          Result := r;
      end;
    end
    else
      Diag('ignoring: ' + rec.FileName);
  end;
end;


// copies selected files from InZip
function TZMZipCopy.WriteFile(InZip: TZMZipFile; All: Boolean): Int64;
begin
  ASSERT(assigned(InZip), 'no input');
  Diag('Write file');
  Result := InZip.VerifyOpen;  // verify unchanged and open
  if Result < 0 then
    exit;
  ZipComment := InZip.ZipComment;
  Result := AffixZippedFiles(InZip, All);
  if Result >= 0 then
    Result := Commit(zwoZipTime in {Worker.}WriteOptions);
end;


end.
