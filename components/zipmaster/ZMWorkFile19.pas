unit ZMWorkFile19;

(*
  ZMWorkFile19.pas - basic in/out for zip files
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
  --------------------------------------------------------------------------- *)
(*
  if Len < 0 then must process on this segment
  ????Full - gives error if not processed non-split
  ????Check - gives error if not all done
  // Len = int64
  function Seek(offset: Int64; From: integer): Int64; virtual;
  procedure CopyTo(var dest: TZMWorkFile; Len: Int64; ErrId: Integer); virtual;
  // only operate on < 2G at a time
  procedure CopyToFull(var dest: TZMWorkFile; Len, ErrId: Integer); virtual;
  function Read(var Buffer; ReadLen: Integer): Integer; virtual;
  procedure ReadCheck(var Buffer; Len, ErrId: Integer); virtual;
  procedure ReadFull(var Buffer; ReadLen, DSErrIdent: Integer); virtual;
  function Write(const Buffer; Len: Integer): Integer; virtual;
  function WriteCheck(const Buffer; Len, ErrId: Integer): Integer; virtual;
  procedure WriteFull(const Buffer; Len, ErrIdent: Integer); virtual;
*)
interface

uses
  Classes, Windows, SysUtils, ZipMstr19, ZMDelZip19, ZMCore19, ZMDrv19;

// file signitures read by OpenEOC
type
  TZipFileSigs = (zfsNone, zfsLocal, zfsMulti, zfsDOS);

type
  TZipNumberScheme = (znsNone, znsVolume, znsName, znsExt);

type
  TZipWrites = (zwDefault, zwSingle, zwMultiple);

const
  ProgressActions: array [TZipShowProgress] of TActionCodes =
    (zacTick, zacProgress, zacXProgress);
  MustFitError = -10999;
  MustFitFlag = $20000; // much bigger than any 'fixed' field
  MustFitMask = $1FFFF; // removes flag limits 'fixed' length

type
//  TBytArray = array of Byte;
  TByteBuffer = array of Byte;

type
  TZMWorkFile = class(TObject)
  private
    fAllowedSize: Int64;
    FBoss: TZMCore;
    fBytesRead: Int64;
    fBytesWritten: Int64;
    fDiskNr: Integer;
    fFileName: String;
    fFile_Size: Int64;
    fHandle: Integer;
    fInfo: Cardinal;
//    fIsMultiDisk: Boolean;
    fIsOpen: Boolean;
    fIsTemp: Boolean;
    fLastWrite: TFileTime;
    fOpenMode: Cardinal;
    fRealFileName: String;
    fRealFileSize: Int64;
    FReqFileName: String;
    fShowProgress: TZipShowProgress;
    fSig: TZipFileSigs;
    fStampDate: Cardinal;
    fTotalDisks: Integer;
    fWorkDrive: TZMWorkDrive;
    fWorker: TZMCore;
    FZipDiskAction: TZMDiskAction;
    FZipDiskStatus: TZMZipDiskStatus;
    WBuf: array of Byte;
    function GetConfirmErase: Boolean;
    function GetExists: Boolean;
    function GetKeepFreeOnAllDisks: Cardinal;
    function GetKeepFreeOnDisk1: Cardinal;
    function GetLastWritten: Cardinal;
    function GetMaxVolumeSize: Int64;
    function GetMinFreeVolumeSize: Cardinal;
    function GetPosition_F: Int64;
    function GetSpanOptions: TZMSpanOpts;
    procedure SetBoss(const Value: TZMCore);
    procedure SetFileName(const Value: String);
    procedure SetHandle(const Value: Integer);
    procedure SetKeepFreeOnAllDisks(const Value: Cardinal);
    procedure SetKeepFreeOnDisk1(const Value: Cardinal);
    procedure SetMaxVolumeSize(const Value: Int64);
    procedure SetMinFreeVolumeSize(const Value: Cardinal);
    procedure SetPosition(const Value: Int64);
    procedure SetSpanOptions(const Value: TZMSpanOpts);
    procedure SetWorkDrive(const Value: TZMWorkDrive);
  protected
    fBufferPosition: Integer;
    fConfirmErase: Boolean;
    fDiskBuffer: TByteBuffer;
    FDiskWritten: Cardinal;
    fSavedFileInfo: _BY_HANDLE_FILE_INFORMATION;
    fIsMultiPart: Boolean;
    FNewDisk: Boolean;
    FNumbering: TZipNumberScheme;
    function ChangeNumberedName(const FName: String; NewNbr: Cardinal; Remove:
        boolean): string;
    procedure CheckForDisk(writing, UnformOk: Boolean);
    procedure ClearFloppy(const dir: String);
    function Copy_File(Source: TZMWorkFile): Integer;
    procedure Diag(const msg: String);
    function EOS: Boolean;
    procedure FlushDiskBuffer;
    function GetFileInformation(var FileInfo: _BY_HANDLE_FILE_INFORMATION): Boolean;
    function GetPosition: Int64;
    function HasSpanSig(const FName: String): boolean;
    function IsRightDisk: Boolean;
    procedure NewFlushDisk;
    function NewSegment: Boolean;
    function VolName(Part: Integer): String;
    function OldVolName(Part: Integer): String;
    function WriteSplit(const Buffer; ToWrite: Integer): Integer;
    function ZipFormat(const NewName: String): Integer;
    property AllowedSize: Int64 Read fAllowedSize Write fAllowedSize;
    property LastWrite: TFileTime read fLastWrite write fLastWrite;
    property OpenMode: Cardinal read fOpenMode;
  public
    constructor Create(wrkr: TZMCore); virtual;
    procedure AfterConstruction; override;
    function AskAnotherDisk(const DiskFile: String): Integer;
    function AskOverwriteSegment(const DiskFile: String; DiskSeq: Integer): Integer;
    procedure AssignFrom(Src: TZMWorkFile); virtual;
    procedure BeforeDestruction; override;
    function CheckRead(var Buffer; Len: Integer): Boolean; overload;
    procedure CheckRead(var Buffer; Len, ErrId: Integer); overload;
    function CheckReads(var Buffer; const Lens: array of Integer): Boolean;
      overload;
    procedure CheckReads(var Buffer; const Lens: array of Integer;
      ErrId: Integer); overload;
    function CheckSeek(offset: Int64; from, ErrId: Integer): Int64;
    function CheckWrite(const Buffer; Len: Integer): Boolean; overload;
    procedure CheckWrite(const Buffer; Len, ErrId: Integer); overload;
    function CheckWrites(const Buffer; const Lens: array of Integer): Boolean;
      overload;
    procedure CheckWrites(const Buffer; const Lens: array of Integer;
      ErrId: Integer); overload;
    procedure ClearFileInformation;
    function CopyFrom(Source: TZMWorkFile; Len: Int64): Int64;
    function CreateMVFileNameEx(const FileName: String;
      StripPartNbr, Compat: Boolean): String;
    function DoFileWrite(const Buffer; Len: Integer): Integer;
    function FileDate: Cardinal;
    procedure File_Close;
    procedure File_Close_F;
    function File_Create(const theName: String): Boolean;
    function File_CreateTemp(const Prefix, Where: String): Boolean;
    function File_Open(Mode: Cardinal): Boolean;
    function File_Rename(const NewName: string; const Safe: Boolean = false)
      : Boolean;
    function FinishWrite: Integer;
    procedure GetNewDisk(DiskSeq: Integer; AllowEmpty: Boolean);
    function LastWriteTime(var last_write: TFileTime): Boolean;
    function MapNumbering(Opts: TZMSpanOpts): TZMSpanOpts;
    procedure ProgReport(prog: TActionCodes; xprog: Integer; const Name: String;
        size: Int64);
    function Read(var Buffer; Len: Integer): Integer;
    function ReadFromFile(var Buffer; Len: Integer): Integer;
    function Reads(var Buffer; const Lens: array of Integer): Integer;
    function Reads_F(var Buffer; const Lens: array of Integer): Integer;
    function ReadTo(strm: TStream; Count: Integer): Integer;
    function Read_F(var Buffer; Len: Integer): Integer;
    function SaveFileInformation: Boolean;
    function Seek(offset: Int64; from: Integer): Int64;
    function SeekDisk(Nr: Integer): Integer;
    function SetEndOfFile: Boolean;
    function VerifyFileInformation: Boolean;
    function WBuffer(size: Integer): pByte;
    function Write(const Buffer; Len: Integer): Integer;
    function WriteFrom(strm: TStream; Count: Integer): Int64;
    function Writes(const Buffer; const Lens: array of Integer): Integer;
    function Writes_F(const Buffer; const Lens: array of Integer): Integer;
    function WriteToFile(const Buffer; Len: Integer): Integer;
    function Write_F(const Buffer; Len: Integer): Integer;
    property Boss: TZMCore read FBoss write SetBoss;
    property BytesRead: Int64 read fBytesRead write fBytesRead;
    property BytesWritten: Int64 read fBytesWritten write fBytesWritten;
    property ConfirmErase: Boolean read GetConfirmErase write fConfirmErase;
    property DiskNr: Integer read fDiskNr write fDiskNr;
    property Exists: Boolean read GetExists;
    property FileName: String read fFileName write SetFileName;
    property File_Size: Int64 read fFile_Size write fFile_Size;
    property Handle: Integer read fHandle write SetHandle;
    property info: Cardinal read fInfo write fInfo;
    property IsMultiPart: Boolean read fIsMultiPart write fIsMultiPart;
    property IsOpen: Boolean read fIsOpen;
    property IsTemp: Boolean read fIsTemp write fIsTemp;
    property KeepFreeOnAllDisks: Cardinal read GetKeepFreeOnAllDisks write
      SetKeepFreeOnAllDisks;
    property KeepFreeOnDisk1: Cardinal read GetKeepFreeOnDisk1 write
      SetKeepFreeOnDisk1;
    property LastWritten: Cardinal read GetLastWritten;
    property MaxVolumeSize: Int64 read GetMaxVolumeSize write SetMaxVolumeSize;
    property MinFreeVolumeSize: Cardinal read GetMinFreeVolumeSize write
      SetMinFreeVolumeSize;
    property NewDisk: Boolean Read FNewDisk Write FNewDisk;
    property Numbering: TZipNumberScheme Read FNumbering Write FNumbering;
    property Position: Int64 read GetPosition write SetPosition;
    property RealFileName: String read fRealFileName;
    property RealFileSize: Int64 read fRealFileSize write fRealFileSize;
    property ReqFileName: String Read FReqFileName Write FReqFileName;
    property ShowProgress
      : TZipShowProgress read fShowProgress write fShowProgress;
    property Sig: TZipFileSigs read fSig write fSig;
    property SpanOptions: TZMSpanOpts read GetSpanOptions write SetSpanOptions;
    // if non-zero set fileDate
    property StampDate: Cardinal read fStampDate write fStampDate;
    property TotalDisks: Integer read fTotalDisks write fTotalDisks;
    property WorkDrive: TZMWorkDrive read fWorkDrive write SetWorkDrive;
    property Worker: TZMCore read fWorker write fWorker;
  end;

const
//  zfi_None: Cardinal = 0;
//  zfi_Open: Cardinal = 1;
//  zfi_Create: Cardinal = 2;
  zfi_Dirty: Cardinal = 4;
  zfi_MakeMask: Cardinal = $07;
  zfi_Error: Cardinal = 8;
//  zfi_NotFound: cardinal = $10;     // named file not found
//  zfi_NoLast: cardinal = $20;       // last file not found
  zfi_Loading: cardinal = $40;
  zfi_Cancelled: cardinal = $80;    // loading was cancelled
//  zfi_FileMask: cardinal = $F0;

function FileTimeToLocalDOSTime(const ft: TFileTime): Cardinal;

implementation

uses
  Forms, Controls, Dialogs, ZMMsgStr19, ZMCtx19, ZMCompat19, ZMDlg19,
  ZMStructs19, ZMUtils19, ZMMsg19, ZMXcpt19;
{$I '.\ZipVers19.inc'}
{$IFDEF VER180}
 {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}

const
  MAX_PARTS = 999;
  MaxDiskBufferSize = (4 * 1024 * 1024); // floppies only

const
  SZipSet = 'ZipSet_';
  SPKBACK = 'PKBACK#';

  (* ? FormatFloppy
    *)
function FormatFloppy(WND: HWND; const Drive: String): Integer;
const
  SHFMT_ID_DEFAULT = $FFFF;
  { options }
  SHFMT_OPT_FULL = $0001;
  // SHFMT_OPT_SYSONLY = $0002;
  { return values }
  // SHFMT_ERROR = $FFFFFFFF;
  // -1 Error on last format, drive may be formatable
  // SHFMT_CANCEL = $FFFFFFFE;    // -2 last format cancelled
  // SHFMT_NOFORMAT = $FFFFFFFD;    // -3 drive is not formatable
type
  TSHFormatDrive = function(WND: HWND; Drive, fmtID, Options: DWORD): DWORD;
    stdcall;
var
  SHFormatDrive: TSHFormatDrive;
var
  drv: Integer;
  hLib: THandle;
  OldErrMode: Integer;
begin
  Result := -3; // error
  if not((Length(Drive) > 1) and (Drive[2] = ':') and CharInSet
      (Drive[1], ['A' .. 'Z', 'a' .. 'z'])) then
    exit;
  if GetDriveType(PChar(Drive)) <> DRIVE_REMOVABLE then
    exit;
  drv := Ord(Upcase(Drive[1])) - Ord('A');
  OldErrMode := SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOGPFAULTERRORBOX);
  hLib := LoadLibrary('Shell32');
  if hLib <> 0 then
  begin
    @SHFormatDrive := GetProcAddress(hLib, 'SHFormatDrive');
    if @SHFormatDrive <> nil then
      try
        Result := SHFormatDrive(WND, drv, SHFMT_ID_DEFAULT, SHFMT_OPT_FULL);
      finally
        FreeLibrary(hLib);
      end;
    SetErrorMode(OldErrMode);
  end;
end;

function FileTimeToLocalDOSTime(const ft: TFileTime): Cardinal;
var
  lf: TFileTime;
  wd: Word;
  wt: Word;
begin
  Result := 0;
  if FileTimeToLocalFileTime(ft, lf) and FileTimeToDosDateTime(lf, wd, wt) then
    Result := (wd shl 16) or wt;
end;

{ TZMWorkFile }

constructor TZMWorkFile.Create(wrkr: TZMCore);
begin
  inherited Create;
  fWorker := wrkr;
  fBoss := wrkr;
end;

procedure TZMWorkFile.AfterConstruction;
begin
  inherited;
  fDiskBuffer := nil;
  fBufferPosition := -1;
  fInfo := 0;
  fHandle := -1;
  fIsMultiPart := false;
  fBytesWritten := 0;
  fBytesRead := 0;
  fOpenMode := 0;
  fNumbering := znsNone;
  fWorkDrive := TZMWorkDrive.Create;
  ClearFileInformation;
end;

function TZMWorkFile.AskAnotherDisk(const DiskFile: String): Integer;
var
  MsgQ: String;
  tmpStatusDisk: TZMStatusDiskEvent;
begin
  MsgQ := Boss.ZipLoadStr(DS_AnotherDisk);
  FZipDiskStatus := FZipDiskStatus + [zdsSameFileName];
  tmpStatusDisk := worker.Master.OnStatusDisk;
  if Assigned(tmpStatusDisk) and not(zaaYesOvrwrt in Worker.AnswerAll) then
  begin
    FZipDiskAction := zdaOk; // The default action
    tmpStatusDisk(Boss.Master, 0, DiskFile, FZipDiskStatus, FZipDiskAction);
    case FZipDiskAction of
      zdaCancel:
        Result := idCancel;
      zdaReject:
        Result := idNo;
      zdaErase:
        Result := idOk;
      zdaYesToAll:
        begin
          Result := idOk;
//          Worker.AnswerAll := Worker.AnswerAll + [zaaYesOvrwrt];
        end;
      zdaOk:
        Result := idOk;
    else
      Result := idOk;
    end;
  end
  else
    Result := Boss.ZipMessageDlgEx(Boss.ZipLoadStr(FM_Confirm), MsgQ,
      zmtWarning + DHC_SpanOvr, [mbOk, mbCancel]);
end;

function TZMWorkFile.AskOverwriteSegment(const DiskFile: String; DiskSeq:
    Integer): Integer;
var
  MsgQ: String;
  tmpStatusDisk: TZMStatusDiskEvent;
begin
  // Do we want to overwrite an existing file?
  if FileExists(DiskFile) then
    if (File_Age(DiskFile) = StampDate) and (Pred(DiskSeq) < DiskNr)
      then
    begin
      MsgQ := Boss.ZipFmtLoadStr(DS_AskPrevFile, [DiskSeq]);
      FZipDiskStatus := FZipDiskStatus + [zdsPreviousDisk];
    end
    else
    begin
      MsgQ := Boss.ZipFmtLoadStr(DS_AskDeleteFile, [DiskFile]);
      FZipDiskStatus := FZipDiskStatus + [zdsSameFileName];
    end
    else if not WorkDrive.DriveIsFixed then
      if (WorkDrive.VolumeSize <> WorkDrive.VolumeSpace) then
        FZipDiskStatus := FZipDiskStatus + [zdsHasFiles]
        // But not the same name
      else
        FZipDiskStatus := FZipDiskStatus + [zdsEmpty];
  tmpStatusDisk := worker.Master.OnStatusDisk;
  if Assigned(tmpStatusDisk) and not(zaaYesOvrwrt in Worker.AnswerAll) then
  begin
    FZipDiskAction := zdaOk; // The default action
    tmpStatusDisk(Boss.Master, DiskSeq, DiskFile, FZipDiskStatus,
      FZipDiskAction);
    case FZipDiskAction of
      zdaCancel:
        Result := idCancel;
      zdaReject:
        Result := idNo;
      zdaErase:
        Result := idOk;
      zdaYesToAll:
        begin
          Result := idOk;
          Worker.AnswerAll := Worker.AnswerAll + [zaaYesOvrwrt];
        end;
      zdaOk:
        Result := idOk;
    else
      Result := idOk;
    end;
  end
  else if ((FZipDiskStatus * [zdsPreviousDisk, zdsSameFileName]) <> []) and not
    ((zaaYesOvrwrt in Worker.AnswerAll) or Worker.Unattended) then
  begin
    Result := Boss.ZipMessageDlgEx(Boss.ZipLoadStr(FM_Confirm), MsgQ,
      zmtWarning + DHC_SpanOvr, [mbYes, mbNo, mbCancel, mbYesToAll]);
    if Result = mrYesToAll then
    begin
      Worker.AnswerAll := Worker.AnswerAll + [zaaYesOvrwrt];
      Result := idOk;
    end;
  end
  else
    Result := idOk;
end;

// Src should not be open but not enforced
procedure TZMWorkFile.AssignFrom(Src: TZMWorkFile);
begin
  if (Src <> Self) and (Src <> nil) then
  begin
    fDiskBuffer := nil;
    fBufferPosition := -1;
    Move(Src.fSavedFileInfo, fSavedFileInfo, SizeOf(fSavedFileInfo));
    fAllowedSize := Src.fAllowedSize;
    fBytesRead := Src.fBytesRead;
    fBytesWritten := Src.fBytesWritten;
    fDiskNr := Src.fDiskNr;
    fFile_Size := Src.fFile_Size;
    fFileName := Src.fFileName;
    fHandle := -1;  // don't acquire handle
    fInfo := Src.fInfo;
//    fIsMultiDisk := Src.fIsMultiDisk;
    fIsOpen := False;
    fIsTemp := Src.fIsTemp;
    fLastWrite := Src.fLastWrite;
    fNumbering := Src.fNumbering;
    fOpenMode := Src.fOpenMode;
    fRealFileName := Src.fRealFileName;
    fReqFileName := Src.FReqFileName;
    fShowProgress := Src.fShowProgress;
    fSig := Src.fSig;
    fStampDate := Src.fStampDate;
    fTotalDisks := Src.fTotalDisks;
    fWorkDrive.AssignFrom(Src.WorkDrive);
    FZipDiskAction := Src.FZipDiskAction;
    FZipDiskStatus := Src.FZipDiskStatus;
  end;
end;

procedure TZMWorkFile.BeforeDestruction;
begin
  File_Close;
  if IsTemp and FileExists(fRealFileName) then
  begin
    if Boss.Verbosity >= zvTrace then
      Diag('Trace: Deleting ' + fRealFileName);
    SysUtils.DeleteFile(fFileName);
  end;
  FreeAndNil(fWorkDrive);
  fDiskBuffer := nil; // ++ discard contents
  WBuf := nil;
  inherited;
end;

// uses 'real' number
function TZMWorkFile.ChangeNumberedName(const FName: String; NewNbr: Cardinal;
    Remove: boolean): string;
var
  ext: string;
  StripLen: Integer;
begin
  if DiskNr > 999 then
    raise EZipMaster.CreateResDisp(DS_TooManyParts, True);
  ext := ExtractFileExt(FName);
  StripLen := 0;
  if Remove then
    StripLen := 3;
  Result := Copy(FName, 1, Length(FName) - Length(ext) - StripLen)
    + Copy(IntToStr(1000 + NewNbr), 2, 3) + ext;
end;

procedure TZMWorkFile.CheckForDisk(writing, UnformOk: Boolean);
var
  OnGetNextDisktmp: TZMGetNextDiskEvent;
  AbortAction: Boolean;
  MsgFlag: Integer;
  MsgStr: String;
  Res: Integer;
  SizeOfDisk: Int64;
  totDisks: Integer;
begin
  if TotalDisks <> 1 then // check
    IsMultiPart := True;
  if WorkDrive.DriveIsFixed then
  begin
    // If it is a fixed disk we don't want a new one.
    NewDisk := false;
    Boss.CheckCancel;
    exit;
  end;
  Boss.KeepAlive;       // just ProcessMessages
  // First check if we want a new one or if there is a disk (still) present.
  while (NewDisk or (not WorkDrive.HasMedia(UnformOk))) do
  begin
    if Boss.Unattended then
      raise EZipMaster.CreateResDisp(DS_NoUnattSpan, True);

    MsgFlag := zmtWarning + DHC_SpanNxtW; // or error?
    if DiskNr < 0 then // want last disk
    begin
      MsgStr := Boss.ZipLoadStr(DS_InsertDisk);
      MsgFlag := zmtError + DHC_SpanNxtR;
    end
    else if writing then
    begin
      // This is an estimate, we can't know if every future disk has the same space available and
      // if there is no disk present we can't determine the size unless it's set by MaxVolumeSize.
      SizeOfDisk := WorkDrive.VolumeSize - KeepFreeOnAllDisks;
      if (MaxVolumeSize <> 0) and (MaxVolumeSize < WorkDrive.VolumeSize) then
        SizeOfDisk := MaxVolumeSize;

      TotalDisks := DiskNr + 1;
      if TotalDisks > MAX_PARTS then
        raise EZipMaster.CreateResDisp(DS_TooManyParts, True);
      if SizeOfDisk > 0 then
      begin
        totDisks := Trunc((File_Size + 4 + KeepFreeOnDisk1) / SizeOfDisk);
        if TotalDisks < totDisks then
          TotalDisks := totDisks;
        MsgStr := Boss.ZipFmtLoadStr
          (DS_InsertVolume, [DiskNr + 1, TotalDisks]);
      end
      else
        MsgStr := Boss.ZipFmtLoadStr(DS_InsertAVolume, [DiskNr + 1]);
    end
    else
    begin // reading - want specific disk
      if TotalDisks = 0 then
        MsgStr := Boss.ZipFmtLoadStr(DS_InsertAVolume, [DiskNr + 1])
      else
        MsgStr := Boss.ZipFmtLoadStr(DS_InsertVolume, [DiskNr + 1, TotalDisks]);
    end;

    MsgStr := MsgStr + Boss.ZipFmtLoadStr(DS_InDrive, [WorkDrive.DriveStr]);
    OnGetNextDisktmp := Worker.Master.OnGetNextDisk;
    if Assigned(OnGetNextDisktmp) then
    begin
      AbortAction := false;
      OnGetNextDisktmp(Boss.Master, DiskNr + 1, TotalDisks, Copy
          (WorkDrive.DriveStr, 1, 1), AbortAction);
      if AbortAction then
        Res := idAbort
      else
        Res := idOk;
    end
    else
      Res := Boss.ZipMessageDlgEx('', MsgStr, MsgFlag, mbOkCancel);

    // Check if user pressed Cancel or memory is running out.
    if Res = 0 then
      raise EZipMaster.CreateResDisp(DS_NoMem, True);
    if Res <> idOk then
    begin
      Boss.Cancel := GE_Abort;
      info := info or zfi_Cancelled;
      raise EZipMaster.CreateResDisp(DS_Canceled, false);
    end;
    NewDisk := false;
    Boss.KeepAlive;
  end;
end;

function TZMWorkFile.CheckRead(var Buffer; Len: Integer): Boolean;
begin
  if Len < 0 then
    Len := -Len;
  Result := Read(Buffer, Len) = Len;
end;

procedure TZMWorkFile.CheckRead(var Buffer; Len, ErrId: Integer);
begin
  if Len < 0 then
    Len := -Len;
  if not CheckRead(Buffer, Len) then
  begin
    if ErrId = 0 then
      ErrId := DS_ReadError;
    raise EZipMaster.CreateResDisp(ErrId, True);
  end;
end;

function TZMWorkFile.CheckReads(var Buffer; const Lens: array of Integer)
  : Boolean;
var
  c: Integer;
  i: Integer;
begin
  c := 0;
  for i := Low(Lens) to High(Lens) do
    c := c + Lens[i];
  Result := Reads(Buffer, Lens) = c;
end;

procedure TZMWorkFile.CheckReads(var Buffer; const Lens: array of Integer;
  ErrId: Integer);
begin
  if not CheckReads(Buffer, Lens) then
  begin
    if ErrId = 0 then
      ErrId := DS_ReadError;
    raise EZipMaster.CreateResDisp(ErrId, True);
  end;
end;

function TZMWorkFile.CheckSeek(offset: Int64; from, ErrId: Integer): Int64;
begin
  Result := Seek(offset, from);
  if Result < 0 then
  begin
    if ErrId = 0 then
      raise EZipMaster.CreateResDisp(DS_SeekError, True);
    if ErrId = -1 then
      ErrId := DS_FailedSeek;
    raise EZipMaster.CreateResDisp(ErrId, True);
  end;
end;

function TZMWorkFile.CheckWrite(const Buffer; Len: Integer): Boolean;
begin
  if Len < 0 then
    Len := -Len;
  Result := Write(Buffer, Len) = Len;
end;

procedure TZMWorkFile.CheckWrite(const Buffer; Len, ErrId: Integer);
begin
  if not CheckWrite(Buffer, Len) then
  begin
    if ErrId = 0 then
      ErrId := DS_WriteError;
    raise EZipMaster.CreateResDisp(ErrId, True);
  end;
end;

function TZMWorkFile.CheckWrites(const Buffer; const Lens: array of Integer)
  : Boolean;
var
  c: Integer;
  i: Integer;
begin
  c := 0;
  for i := Low(Lens) to High(Lens) do
    c := c + Lens[i];
  Result := Writes(Buffer, Lens) = c;
end;

// must read from current part
procedure TZMWorkFile.CheckWrites(const Buffer; const Lens: array of Integer;
  ErrId: Integer);
begin
  if not CheckWrites(Buffer, Lens) then
  begin
    if ErrId = 0 then
      ErrId := DS_WriteError;
    raise EZipMaster.CreateResDisp(ErrId, True);
  end;
end;

procedure TZMWorkFile.ClearFileInformation;
begin
  ZeroMemory(@fSavedFileInfo, sizeof(_BY_HANDLE_FILE_INFORMATION));
end;

procedure TZMWorkFile.ClearFloppy(const dir: String);
var
  Fname: String;
  SRec: TSearchRec;
begin
  if FindFirst(dir + WILD_ALL, faAnyFile, SRec) = 0 then
    repeat
      Fname := dir + SRec.Name;
      if ((SRec.Attr and faDirectory) <> 0) and (SRec.Name <> DIR_THIS) and
        (SRec.Name <> DIR_PARENT) then
      begin
        Fname := Fname + PathDelim;
        ClearFloppy(Fname);
        if Boss.Verbosity >= zvTrace then
          Boss.ReportMsg(TM_Erasing, [Fname])
        else
          Boss.KeepAlive;
        // allow time for OS to delete last file
        RemoveDir(Fname);
      end
      else
      begin
        if Boss.Verbosity >= zvTrace then
          Boss.ReportMsg(TM_Deleting, [Fname])
        else
          Boss.KeepAlive;
        SysUtils.DeleteFile(Fname);
      end;
    until FindNext(SRec) <> 0;
    SysUtils.FindClose(SRec);
end;

function TZMWorkFile.CopyFrom(Source: TZMWorkFile; Len: Int64): Int64;
var
  BufSize: Cardinal;
  SizeR: Integer;
  ToRead: Integer;
  wb: pByte;
begin
  BufSize := 10 * 1024; // constant is somewhere
  wb := WBuffer(BufSize);
  Result := 0;

  while Len > 0 do
  begin
    ToRead := BufSize;
    if Len < BufSize then
      ToRead := Len;
    SizeR := Source.Read(wb^, ToRead);
    if SizeR <> ToRead then
    begin
      if SizeR < 0 then
        Result := SizeR
      else
        Result := -DS_ReadError;
      exit;
    end;
    if SizeR > 0 then
    begin
      ToRead := Write(wb^, SizeR);
      if SizeR <> ToRead then
      begin
        if ToRead < 0 then
          Result := ToRead
        else
          Result := -DS_WriteError;
        exit;
      end;
      Len := Len - SizeR;
      Result := Result + SizeR;
      ProgReport(zacProgress, PR_Copying, Source.FileName, SizeR);
    end;
  end;
end;

function TZMWorkFile.Copy_File(Source: TZMWorkFile): Integer;
var
  fsize: Int64;
  r: Int64;
begin
  try
    if not Source.IsOpen then
      Source.File_Open(fmOpenRead);
    Result := 0;
    fsize := Source.Seek(0, 2);
    Source.Seek(0, 0);
    ProgReport(zacXItem, PR_Copying, Source.FileName, fsize);
    r := self.CopyFrom(Source, fsize);
    if r < 0 then
      Result := Integer(r);
  except
    Result := -9; // general error
  end;
end;

function TZMWorkFile.CreateMVFileNameEx(const FileName: String;
  StripPartNbr, Compat: Boolean): String;
var
  ext: String;
begin // changes FileName into multi volume FileName
  if Compat then
  begin
    if DiskNr <> (TotalDisks - 1) then
    begin
      if DiskNr < 9 then
        ext := '.z0'
      else
        ext := '.z';
      ext := ext + IntToStr(succ(DiskNr));
    end
    else
      ext := EXT_ZIP;
    Result := ChangeFileExt(FileName, ext);
  end
  else
    Result := ChangeNumberedName(FileName, DiskNr + 1, StripPartNbr);
end;

procedure TZMWorkFile.Diag(const msg: String);
begin
  if Boss.Verbosity >= zvTrace then
    Boss.ReportMessage(0, msg);
end;

function TZMWorkFile.DoFileWrite(const Buffer; Len: Integer): Integer;
begin
  Result := FileWrite(fHandle, Buffer, Len);
end;

// return true if end of segment
// WARNING - repositions to end of segment
function TZMWorkFile.EOS: Boolean;
begin
  Result := FileSeek64(Handle, 0, soFromCurrent) = FileSeek64
    (Handle, 0, soFromEnd);
end;

function TZMWorkFile.FileDate: Cardinal;
begin
  Result := FileGetDate(fHandle);
end;

procedure TZMWorkFile.File_Close;
begin
  if fDiskBuffer <> nil then
    FlushDiskBuffer;
  File_Close_F;
//  inherited;
end;

procedure TZMWorkFile.File_Close_F;
var
  th: Integer;
begin
  if fHandle <> -1 then
  begin
    th := fHandle;
    fHandle := -1;
    // if open for writing set date
    if (StampDate <> 0) and
       ((OpenMode and (SysUtils.fmOpenReadWrite or SysUtils.fmOpenWrite)) <> 0) then
    begin
      FileSetDate(th, StampDate);
      if Boss.Verbosity >= zvTrace then
        Diag('Trace: Set file Date ' + fRealFileName + ' to ' + DateTimeToStr
            (FileDateToLocalDateTime(StampDate)));
    end;
    FileClose(th);
    if Boss.Verbosity >= zvTrace then
      Diag('Trace: Closed ' + fRealFileName);
  end;
  fIsOpen := false;
end;

function TZMWorkFile.File_Create(const theName: String): Boolean;
var
  n: String;
begin
  File_Close;
  Result := false;
  if theName <> '' then
  begin
    if FileName = '' then
      FileName := theName;
    n := theName;
  end
  else
    n := FileName;
  if n = '' then
    exit;
  if Boss.Verbosity >= zvTrace then
    Diag('Trace: Creating ' + n);
  fRealFileName := n;
  fHandle := FileCreate(n);
  if fHandle <> -1 then
    TZMCore(Worker).AddCleanupFile(n);
  fBytesWritten := 0;
  fBytesRead := 0;
  Result := fHandle <> -1;
  fIsOpen := Result;
  fOpenMode := SysUtils.fmOpenWrite;
end;

function TZMWorkFile.File_CreateTemp(const Prefix, Where: String): Boolean;
var
  Buf: String;
  Len: DWORD;
  tmpDir: String;
begin
  Result := false;
  if Length(Boss.TempDir) = 0 then
  begin
    if Length(Where) <> 0 then
    begin
      tmpDir := ExtractFilePath(Where);
      tmpDir := ExpandFileName(tmpDir);
    end;
//  if Length(Worker.TempDir) = 0 then // Get the system temp dir
    if Length(tmpDir) = 0 then // Get the system temp dir
    begin
      // 1. The path specified by the TMP environment variable.
      // 2. The path specified by the TEMP environment variable, if TMP is not defined.
      // 3. The current directory, if both TMP and TEMP are not defined.
      Len := GetTempPath(0, PChar(tmpDir));
      SetLength(tmpDir, Len);
      GetTempPath(Len, PChar(tmpDir));
    end;
  end
  else // Use Temp dir provided by ZipMaster
  begin
    tmpDir := Boss.TempDir;
  end;
  tmpDir := DelimitPath(tmpDir, True);
  SetLength(Buf, MAX_PATH + 12);
  if GetTempFileName(PChar(tmpDir), PChar(Prefix), 0, PChar(Buf)) <> 0 then
  begin
    FileName := PChar(Buf);
    IsTemp := True; // delete when finished
    if Boss.Verbosity >= zvTrace then
      Diag('Trace: Created temporary ' + FileName);
    fRealFileName := FileName;
    fBytesWritten := 0;
    fBytesRead := 0;
    fOpenMode := SysUtils.fmOpenWrite;
    Result := File_Open(fmOpenWrite);
  end;
end;

function TZMWorkFile.File_Open(Mode: Cardinal): Boolean;
begin
  File_Close;
  if Boss.Verbosity >= zvTrace then
    Diag('Trace: Opening ' + fFileName);
  fRealFileName := fFileName;
  fHandle := FileOpen(fFileName, Mode);
  Result := fHandle <> -1;
  fIsOpen := Result;
  fOpenMode := Mode;
end;

function TZMWorkFile.File_Rename(const NewName: string;
  const Safe: Boolean = false): Boolean;
begin
  if Boss.Verbosity >= zvTrace then
    Diag('Trace: Rename ' + RealFileName + ' to ' + NewName);
  IsTemp := false;
  if IsOpen then
    File_Close;
  if FileExists(FileName) then
  begin
    if FileExists(NewName) then
    begin
      if Boss.Verbosity >= zvTrace then
        Diag('Trace: Erasing ' + NewName);
      if (EraseFile(NewName, not Safe) <> 0) and (Boss.Verbosity >= zvTrace)
        then
        Diag('Trace: Erase failed ' + NewName);
    end;
  end;
  Result := RenameFile(FileName, NewName);
  if Result then
  begin
    fFileName := NewName;  // success
    fRealFileName := NewName;
  end;
end;

// rename last part after Write
function TZMWorkFile.FinishWrite: Integer;
var
  fn: String;
  LastName: String;
  MsgStr: String;
  Res: Integer;
  OnStatusDisk: TZMStatusDiskEvent;
begin
  // change extn of last file
  LastName := RealFileName;
  File_Close;
  Result := 0;

  if IsMultiPart then
  begin
    if ((Numbering = znsExt) and not AnsiSameText(ExtractFileExt(LastName), EXT_ZIP)) or
      ((Numbering = znsName) and (DiskNr = 0)) then
    begin
      Result := -1;
      fn := FileName;
      if (FileExists(fn)) then
      begin
        MsgStr := Boss.ZipFmtLoadStr(DS_AskDeleteFile, [fn]);
        FZipDiskStatus := FZipDiskStatus + [zdsSameFileName];
        Res := idYes;
        if not(zaaYesOvrwrt in Worker.AnswerAll) then
        begin
          OnStatusDisk := Worker.Master.OnStatusDisk;
          if Assigned(OnStatusDisk) then // 1.77
          begin
            FZipDiskAction := zdaOk; // The default action
            OnStatusDisk(Boss.Master, DiskNr, fn, FZipDiskStatus,
              FZipDiskAction);
            if FZipDiskAction = zdaYesToAll then
            begin
              Worker.AnswerAll := Worker.AnswerAll + [zaaYesOvrwrt];
              FZipDiskAction := zdaOk;
            end;
            if FZipDiskAction = zdaOk then
              Res := idYes
            else
              Res := idNo;
          end
          else
            Res := Boss.ZipMessageDlgEx(MsgStr, Boss.ZipLoadStr(FM_Confirm)
                , zmtWarning + DHC_WrtSpnDel, [mbYes, mbNo]);
        end;
        if (Res = 0) then
          Boss.ShowZipMessage(DS_NoMem, '');
        if (Res = idNo) then
          Boss.ReportMsg(DS_NoRenamePart, [LastName]);
        if (Res = idYes) then
          SysUtils.DeleteFile(fn); // if it exists delete old one
      end;
      if FileExists(LastName) then // should be there but ...
      begin
        RenameFile(LastName, fn);
        Result := 0;
        if Boss.Verbosity >= zvVerbose then
          Boss.Diag(Format('renamed %s to %s', [LastName, fn]));
      end;
    end;
  end;
end;

procedure TZMWorkFile.FlushDiskBuffer;
var
  did: Integer;
  Len: Integer;
begin
  Len := fBufferPosition;
  fBufferPosition := -1; // stop retrying on error
  if fDiskBuffer <> nil then
  begin
    Boss.KeepAlive;
    Boss.CheckCancel;
    if Len > 0 then
    begin
      repeat
        did := DoFileWrite(fDiskBuffer[0], Len);
        if did <> Len then
        begin
          NewFlushDisk; // abort or try again on new disk
        end;
      until (did = Len);
    end;
    fDiskBuffer := nil;
  end;
end;

function TZMWorkFile.GetConfirmErase: Boolean;
begin
  Result := Worker.ConfirmErase;
end;

function TZMWorkFile.GetExists: Boolean;
begin
  Result := false;
  if FileExists(FileName) then
    Result := True;
end;

function TZMWorkFile.GetFileInformation(var FileInfo:
    _BY_HANDLE_FILE_INFORMATION): Boolean;
begin
  Result := IsOpen;
  if Result then
    Result := GetFileInformationByHandle(Handle, FileInfo);
  if not Result then
    ZeroMemory(@FileInfo, sizeof(_BY_HANDLE_FILE_INFORMATION));
end;

function TZMWorkFile.GetKeepFreeOnAllDisks: Cardinal;
begin
  Result := Worker.KeepFreeOnAllDisks;
end;

function TZMWorkFile.GetKeepFreeOnDisk1: Cardinal;
begin
  Result := Worker.KeepFreeOnDisk1;
end;

function TZMWorkFile.GetLastWritten: Cardinal;
var
  ft: TFileTime;
begin
  Result := 0;
  if IsOpen and LastWriteTime(ft) then
    Result := FileTimeToLocalDOSTime(ft);
end;

function TZMWorkFile.GetMaxVolumeSize: Int64;
begin
  Result := Worker.MaxVolumeSize;
end;

function TZMWorkFile.GetMinFreeVolumeSize: Cardinal;
begin
  Result := Worker.MinFreeVolumeSize;
end;

procedure TZMWorkFile.GetNewDisk(DiskSeq: Integer; AllowEmpty: Boolean);
begin
  File_Close;
  // Close the file on the old disk first.
  if (TotalDisks <> 1) or (DiskSeq <> 0) then
    IsMultiPart := True;
  DiskNr := DiskSeq;
  while True do
  begin
    repeat
      NewDisk := True;
      File_Close;
      CheckForDisk(false, spTryFormat in SpanOptions);
      if AllowEmpty and WorkDrive.HasMedia(spTryFormat in SpanOptions) then
      begin
        if WorkDrive.VolumeSpace = -1 then
          exit; // unformatted
        if WorkDrive.VolumeSpace = WorkDrive.VolumeSize then
          exit; // empty
      end;
    until IsRightDisk;

    if Boss.Verbosity >= zvVerbose then
      Boss.Diag(Boss.ZipFmtLoadStr(TM_GetNewDisk, [FileName]));
    if File_Open(fmShareDenyWrite or fmOpenRead) then
      break; // found
    if WorkDrive.DriveIsFixed then
      raise EZipMaster.CreateResDisp(DS_NoInFile, True)
    else
      Boss.ShowZipMessage(DS_NoInFile, '');
  end;
end;

function TZMWorkFile.GetPosition: Int64;
begin
  if fDiskBuffer <> nil then
    Result := fBufferPosition
  else
    Result := GetPosition_F;
end;

function TZMWorkFile.GetPosition_F: Int64;
begin
  Result := FileSeek64(fHandle, 0, soFromCurrent); // from current
end;

function TZMWorkFile.GetSpanOptions: TZMSpanOpts;
begin
  Result := Worker.SpanOptions;
end;

function TZMWorkFile.HasSpanSig(const FName: String): boolean;
var
  fs: TFileStream;
  Sg: Cardinal;
begin
  Result := False;
  if FileExists(FName) then
  begin
    fs := TFileStream.Create(FName, fmOpenRead);
    try
      if (fs.Size > (sizeof(TZipLocalHeader) + sizeof(Sg))) and
        (fs.Read(Sg, sizeof(Sg)) = sizeof(Sg)) then
        Result :=  (Sg = ExtLocalSig) and (fs.Read(Sg, sizeof(Sg)) = sizeof(Sg)) and
          (Sg = LocalFileHeaderSig);
    finally
      fs.Free;
    end;
  end;
end;

function TZMWorkFile.IsRightDisk: Boolean;
var
  fn: String;
  VName: string;
begin
  Result := True;
  if (Numbering < znsName) and (not WorkDrive.DriveIsFixed) then
  begin
    VName := WorkDrive.DiskName;
    Boss.Diag('Checking disk ' + VName + ' need ' + VolName(DiskNr));
    if (AnsiSameText(VName, VolName(DiskNr)) or AnsiSameText(VName, OldVolName(DiskNr))) and
        FileExists(FileName) then
    begin
      Numbering := znsVolume;
      Boss.Diag('found volume ' + VName);
      exit;
    end;
  end;
  fn := FileName;
  if Numbering = znsNone then // not known yet
  begin
    FileName := CreateMVFileNameEx(FileName, True, True);
    // make compat name
    if FileExists(FileName) then
    begin
      Numbering := znsExt;
      exit;
    end;
    FileName := fn;
    FileName := CreateMVFileNameEx(FileName, True, false);
    // make numbered name
    if FileExists(FileName) then
    begin
      Numbering := znsName;
      exit;
    end;
    if WorkDrive.DriveIsFixed then
      exit; // always true - only needed name
    FileName := fn; // restore
    Result := false;
    exit;
  end;
  // numbering scheme already known
  if Numbering = znsVolume then
  begin
    Result := false;
    exit;
  end;
  FileName := CreateMVFileNameEx(FileName, True, Numbering = znsExt);
  // fixed drive always true only needed new filename
  if (not WorkDrive.DriveIsFixed) and (not FileExists(FileName)) then
  begin
    FileName := fn; // restore
    Result := false;
  end;
end;

function TZMWorkFile.LastWriteTime(var last_write: TFileTime): Boolean;
var
  BHFInfo: TByHandleFileInformation;
begin
  Result := false;
  last_write.dwLowDateTime := 0;
  last_write.dwHighDateTime := 0;
  if IsOpen then
  begin
    Result := GetFileInformationByHandle(fHandle, BHFInfo);
    if Result then
      last_write := BHFInfo.ftLastWriteTime;
  end;
end;

function TZMWorkFile.MapNumbering(Opts: TZMSpanOpts): TZMSpanOpts;
var
  spans: TZMSpanOpts;
begin
  Result := Opts;
  if Numbering <> znsNone then
  begin
    // map numbering type only if known
    spans := Opts - [spCompatName] + [spNoVolumeName];
    case Numbering of
      znsVolume:
        spans := spans - [spNoVolumeName];
      znsExt:
        spans := spans + [spCompatName];
    end;
    Result := spans;
  end;
end;

procedure TZMWorkFile.NewFlushDisk;
begin
  // need to allow another disk, check size, open file, name disk etc
  raise EZipMaster.CreateResDisp(DS_WriteError, True);
end;

function TZMWorkFile.NewSegment: Boolean; // true to 'continue'
var
  DiskFile: String;
  DiskSeq: Integer;
  MsgQ: String;
  Res: Integer;
  SegName: String;
  OnGetNextDisk: TZMGetNextDiskEvent;
  OnStatusDisk: TZMStatusDiskEvent;
begin
  Result := false;
  // If we write on a fixed disk the filename must change.
  // We will get something like: FileNamexxx.zip where xxx is 001,002 etc.
  // if CompatNames are used we get FileName.zxx where xx is 01, 02 etc.. last .zip
  if Numbering = znsNone then
  begin
    if spCompatName in SpanOptions then
      Numbering := znsExt
    else if WorkDrive.DriveIsFixed or (spNoVolumeName in SpanOptions) then
      Numbering := znsName
    else
      Numbering := znsVolume;
  end;
  DiskFile := FileName;
  if Numbering <> znsVolume then
    DiskFile := CreateMVFileNameEx(DiskFile, false, Numbering = znsExt);
  CheckForDisk(True, spWipeFiles in SpanOptions);

  OnGetNextDisk := Worker.Master.OnGetNextDisk;
  // Allow clearing of removeable media even if no volume names
  if (not WorkDrive.DriveIsFixed) and (spWipeFiles in SpanOptions) and
    ((FZipDiskAction = zdaErase) or not Assigned(OnGetNextDisk)) then
  begin
    // Do we want a format first?
    if Numbering = znsVolume then
      SegName := VolName(DiskNr)
      // default name
    else
      SegName := SZipSet + IntToStr(succ(DiskNr));
    // Ok=6 NoFormat=-3, Cancel=-2, Error=-1
    case ZipFormat(SegName) of
      // Start formating and wait until BeforeClose...
      - 1:
        raise EZipMaster.CreateResDisp(DS_Canceled, True);
      -2:
        raise EZipMaster.CreateResDisp(DS_Canceled, false);
    end;
  end;
  if WorkDrive.DriveIsFixed or (Numbering <> znsVolume) then
    DiskSeq := DiskNr + 1
  else
  begin
    DiskSeq := StrToIntDef(Copy(WorkDrive.DiskName, 9, 3), 1);
    if DiskSeq < 0 then
      DiskSeq := 1;
  end;
  FZipDiskStatus := [];
  Res := AskOverwriteSegment(DiskFile, DiskSeq);
  if (Res = idYes) and (WorkDrive.DriveIsFixed) and
    (spCompatName in SpanOptions) and FileExists(ReqFileName) then
  begin
    Res := AskOverwriteSegment(ReqFileName, DiskSeq);
    if (Res = idYes) then
      EraseFile(ReqFileName, Worker.HowToDelete = htdFinal);
  end;
  if (Res = 0) or (Res = idCancel) or ((Res = idNo) and WorkDrive.DriveIsFixed)
    then
    raise EZipMaster.CreateResDisp(DS_Canceled, false);

  if Res = idNo then
  begin // we will try again...
    FDiskWritten := 0;
    NewDisk := True;
    Result := True;
    exit;
  end;
  // Create the output file.
  if not File_Create(DiskFile) then
  begin // change proposed by Pedro Araujo
    MsgQ := Boss.ZipLoadStr(DS_NoOutFile);
    Res := Boss.ZipMessageDlgEx('', MsgQ, zmtError + DHC_SpanNoOut,
      [mbRetry, mbCancel]);
    if Res = 0 then
      raise EZipMaster.CreateResDisp(DS_NoMem, True);
    if Res <> idRetry then
      raise EZipMaster.CreateResDisp(DS_Canceled, false);
    FDiskWritten := 0;
    NewDisk := True;
    Result := True;
    exit;
  end;

  // Get the free space on this disk, correct later if neccessary.
  WorkDrive.VolumeRefresh;

  // Set the maximum number of bytes that can be written to this disk(file).
  // Reserve space on/in all the disk/file.
  if (DiskNr = 0) and (KeepFreeOnDisk1 > 0) or (KeepFreeOnAllDisks > 0) then
  begin
    if (KeepFreeOnDisk1 mod WorkDrive.VolumeSecSize) <> 0 then
      KeepFreeOnDisk1 := succ(KeepFreeOnDisk1 div WorkDrive.VolumeSecSize)
        * WorkDrive.VolumeSecSize;
    if (KeepFreeOnAllDisks mod WorkDrive.VolumeSecSize) <> 0 then
      KeepFreeOnAllDisks := succ
        (KeepFreeOnAllDisks div WorkDrive.VolumeSecSize)
        * WorkDrive.VolumeSecSize;
  end;
  AllowedSize := WorkDrive.VolumeSize - KeepFreeOnAllDisks;
  if (MaxVolumeSize > 0) and (MaxVolumeSize < AllowedSize) then
    AllowedSize := MaxVolumeSize;
  // Reserve space on/in the first disk(file).
  if DiskNr = 0 then
    AllowedSize := AllowedSize - KeepFreeOnDisk1;

  // Do we still have enough free space on this disk.
  if AllowedSize < MinFreeVolumeSize then // No, too bad...
  begin
    OnStatusDisk := Worker.Master.OnStatusDisk;
    File_Close;
    SysUtils.DeleteFile(DiskFile);
    if Assigned(OnStatusDisk) then // v1.60L
    begin
      if Numbering <> znsVolume then
        DiskSeq := DiskNr + 1
      else
      begin
        DiskSeq := StrToIntDef(Copy(WorkDrive.DiskName, 9, 3), 1);
        if DiskSeq < 0 then
          DiskSeq := 1;
      end;
      FZipDiskAction := zdaOk; // The default action
      FZipDiskStatus := [zdsNotEnoughSpace];
      OnStatusDisk(Boss.Master, DiskSeq, DiskFile, FZipDiskStatus,
        FZipDiskAction);
      if FZipDiskAction = zdaCancel then
        Res := idCancel
      else
        Res := idRetry;
    end
    else
    begin
      MsgQ := Boss.ZipLoadStr(DS_NoDiskSpace);
      Res := Boss.ZipMessageDlgEx('', MsgQ, zmtError + DHC_SpanSpace,
        [mbRetry, mbCancel]);
    end;
    if Res = 0 then
      raise EZipMaster.CreateResDisp(DS_NoMem, True);
    if Res <> idRetry then
      raise EZipMaster.CreateResDisp(DS_Canceled, false);
    FDiskWritten := 0;

    NewDisk := True;
    // If all this was on a HD then this wouldn't be useful but...
    Result := True;
  end
  else
  begin
    // ok. it fits and the file is open
    // Set the volume label of this disk if it is not a fixed one.
    if not(WorkDrive.DriveIsFixed or (Numbering <> znsVolume)) then
    begin
      if not WorkDrive.RenameDisk(VolName(DiskNr)) then
        raise EZipMaster.CreateResDisp(DS_NoVolume, True);
    end;
    // if it is a floppy buffer it
    if (not WorkDrive.DriveIsFixed) and (AllowedSize <= MaxDiskBufferSize) then
    begin
      SetLength(fDiskBuffer, AllowedSize);
      fBufferPosition := 0;
    end;
  end;
end;

function TZMWorkFile.OldVolName(Part: Integer): String;
begin
  Result := SPKBACK + ' ' + Copy(IntToStr(1001 + Part), 2, 3);
end;

procedure TZMWorkFile.ProgReport(prog: TActionCodes; xprog: Integer; const
    Name: String; size: Int64);
var
  actn: TActionCodes;
  msg: String;
begin
  actn := prog;
  if (Name = '') and (xprog > PR_Progress) then
    msg := Boss.ZipLoadStr(xprog)
  else
    msg := Name;
  case ShowProgress of
    zspNone:
      case prog of
        zacItem:
          actn := zacNone;
        zacProgress:
          actn := zacTick;
        zacEndOfBatch:
          actn := zacTick;
        zacCount:
          actn := zacNone;
        zacSize:
          actn := zacTick;
        zacXItem:
          actn := zacNone;
        zacXProgress:
          actn := zacTick;
      end;
    zspExtra:
      case prog of
        zacItem:
          actn := zacNone; // do nothing
        zacProgress:
          actn := zacXProgress;
        zacCount:
          actn := zacNone; // do nothing
        zacSize:
          actn := zacXItem;
      end;
  end;
  if actn <> zacNone then
    Boss.ReportProgress(actn, xprog, msg, size);
end;

function TZMWorkFile.Read(var Buffer; Len: Integer): Integer;
var
  bp: PAnsiChar;
  SizeR: Integer;
  ToRead: Integer;
begin
  try
    if IsMultiPart then
    begin
      ToRead := Len;
      if Len < 0 then
        ToRead := -Len;
      bp := @Buffer;
      Result := 0;
      while ToRead > 0 do
      begin
        SizeR := ReadFromFile(bp^, ToRead);
        if SizeR <> ToRead then
        begin
          // Check if we are at the end of a input disk.
          if SizeR < 0 then
          begin
            Result := SizeR;
            exit;
          end;
          // if  error or (len <0 and read some) or (end segment)
          if ((Len < 0) and (SizeR <> 0)) or not EOS then
          begin
            Result := -DS_ReadError;
            exit;
          end;
          // It seems we are at the end, so get a next disk.
          GetNewDisk(DiskNr + 1, false);
        end;
        if SizeR > 0 then
        begin
          Inc(bp, SizeR);
          ToRead := ToRead - SizeR;
          Result := Result + SizeR;
        end;
      end;
    end
    else
      Result := Read_F(Buffer, Len);
  except
    on E: EZipMaster do
      Result := -E.ResId;
    on E: Exception do
      Result := -DS_ReadError;
  end;
end;

function TZMWorkFile.ReadFromFile(var Buffer; Len: Integer): Integer;
begin
  if Len < 0 then
    Len := -Len;
  Result := FileRead(fHandle, Buffer, Len);
  if Result > 0 then
    BytesRead := BytesRead + Len
  else if Result < 0 then
  begin
    Result := -DS_ReadError;
  end;
end;

function TZMWorkFile.Reads(var Buffer; const Lens: array of Integer): Integer;
var
  i: Integer;
  pb: PAnsiChar;
  r: Integer;
begin
  Result := 0;
  if IsMultiPart then
  begin
    pb := @Buffer;
    for i := Low(Lens) to High(Lens) do
    begin
      r := Read(pb^, -Lens[i]);
      if r < 0 then
      begin
        Result := r;
        break;
      end;
      Result := Result + r;
      Inc(pb, r);
    end;
  end
  else
    Result := Reads_F(Buffer, Lens);
end;

function TZMWorkFile.Reads_F(var Buffer; const Lens: array of Integer): Integer;
var
  c: Integer;
  i: Integer;
begin
  c := 0;
  for i := Low(Lens) to High(Lens) do
    c := c + Lens[i];
  Result := ReadFromFile(Buffer, c);
end;

function TZMWorkFile.ReadTo(strm: TStream; Count: Integer): Integer;
const
  bsize = 20 * 1024;
var
  done: Integer;
  sz: Integer;
  wbufr: array of Byte;
begin
  Result := 0;
  SetLength(wbufr, bsize);
  while Count > 0 do
  begin
    sz := bsize;
    if sz > Count then
      sz := Count;
    done := Read(wbufr[0], sz);
    if done > 0 then
    begin
      if strm.write(wbufr[0], done) <> done then
        done := -DS_WriteError;
    end;
    if done <> sz then
    begin
      Result := -DS_FileError;
      if done < 0 then
        Result := done;
      break;
    end;
    Count := Count - sz;
    Result := Result + sz;
  end;
end;

function TZMWorkFile.Read_F(var Buffer; Len: Integer): Integer;
begin
  Result := ReadFromFile(Buffer, Len);
end;

function TZMWorkFile.SaveFileInformation: Boolean;
begin
  Result := GetFileInformation(fSavedFileInfo);
end;

function TZMWorkFile.Seek(offset: Int64; from: Integer): Int64;
begin
  Result := FileSeek64(fHandle, offset, from);
end;

function TZMWorkFile.SeekDisk(Nr: Integer): Integer;
begin
  if DiskNr <> Nr then
    GetNewDisk(Nr, false);
  Result := Nr;
end;

procedure TZMWorkFile.SetBoss(const Value: TZMCore);
begin
  if FBoss <> Value then
  begin
    if Value = nil then
      FBoss := fWorker
    else
      FBoss := Value;
  end;
end;

function TZMWorkFile.SetEndOfFile: Boolean;
begin
  if IsOpen then
    Result := Windows.SetEndOfFile(Handle)
  else
    Result := false;
end;

procedure TZMWorkFile.SetFileName(const Value: String);
begin
  if fFileName <> Value then
  begin
    if IsOpen then
      File_Close;
    fFileName := Value;
    WorkDrive.DriveStr := Value;
  end;
end;

// dangerous - assumes file on same drive
procedure TZMWorkFile.SetHandle(const Value: Integer);
begin
  File_Close;
  fHandle := Value;
  fIsOpen := fHandle <> -1;
end;

procedure TZMWorkFile.SetKeepFreeOnAllDisks(const Value: Cardinal);
begin
  Worker.KeepFreeOnAllDisks := Value;
end;

procedure TZMWorkFile.SetKeepFreeOnDisk1(const Value: Cardinal);
begin
  Worker.KeepFreeOnDisk1 := Value;
end;

procedure TZMWorkFile.SetMaxVolumeSize(const Value: Int64);
begin
  Worker.MaxVolumeSize := Value;
end;

procedure TZMWorkFile.SetMinFreeVolumeSize(const Value: Cardinal);
begin
  Worker.MinFreeVolumeSize := Value;
end;

procedure TZMWorkFile.SetPosition(const Value: Int64);
begin
  Seek(Value, 0);
end;

procedure TZMWorkFile.SetSpanOptions(const Value: TZMSpanOpts);
begin
  Worker.SpanOptions := Value;
end;

procedure TZMWorkFile.SetWorkDrive(const Value: TZMWorkDrive);
begin
  if fWorkDrive <> Value then
  begin
    fWorkDrive := Value;
  end;
end;

function TZMWorkFile.VerifyFileInformation: Boolean;
var
  info: _BY_HANDLE_FILE_INFORMATION;//TWIN32FindData;
begin
  GetFileInformation(info);
  Result := (info.ftLastWriteTime.dwLowDateTime = fSavedFileInfo.ftLastWriteTime.dwLowDateTime) and
      (info.ftLastWriteTime.dwHighDateTime = fSavedFileInfo.ftLastWriteTime.dwHighDateTime) and
      (info.ftCreationTime.dwLowDateTime = fSavedFileInfo.ftCreationTime.dwLowDateTime) and
      (info.ftCreationTime.dwHighDateTime = fSavedFileInfo.ftCreationTime.dwHighDateTime) and
      (info.nFileSizeLow = fSavedFileInfo.nFileSizeLow) and
      (info.nFileSizeHigh = fSavedFileInfo.nFileSizeHigh) and
      (info.nFileIndexLow = fSavedFileInfo.nFileIndexLow) and
      (info.nFileIndexHigh = fSavedFileInfo.nFileIndexHigh) and
      (info.dwFileAttributes = fSavedFileInfo.dwFileAttributes) and
      (info.dwVolumeSerialNumber = fSavedFileInfo.dwVolumeSerialNumber);
end;

function TZMWorkFile.VolName(Part: Integer): String;
begin
  Result := SPKBACK + Copy(IntToStr(1001 + Part), 2, 3);
end;

function TZMWorkFile.WBuffer(size: Integer): pByte;
begin
  if size < 1 then
    WBuf := nil
  else if HIGH(WBuf) < size then
  begin
    size := size or $3FF;
    SetLength(WBuf, size + 1); // reallocate
  end;
  Result := @WBuf[0];
end;

function TZMWorkFile.Write(const Buffer; Len: Integer): Integer;
begin
  if IsMultiPart then
    Result := WriteSplit(Buffer, Len)
  else
    Result := Write_F(Buffer, Len);
end;

function TZMWorkFile.WriteFrom(strm: TStream; Count: Integer): Int64;
const
  bsize = 20 * 1024;
var
  done: Integer;
  maxsize: Integer;
  sz: Integer;
  wbufr: array of Byte;
begin
  Result := 0;
  SetLength(wbufr, bsize);
  maxsize := strm.size - strm.Position;
  if Count > maxsize then
    Count := maxsize;
  while Count > 0 do
  begin
    sz := bsize;
    if sz > Count then
      sz := Count;
    done := strm.Read(wbufr[0], sz);
    if done > 0 then
      done := Write(wbufr[0], done); // split ok?
    if done <> sz then
    begin
      Result := -DS_FileError;
      if done < 0 then
        Result := done;
      break;
    end;
    Count := Count - sz;
    Result := Result + sz;
  end;
end;

function TZMWorkFile.Writes(const Buffer; const Lens: array of Integer)
  : Integer;
var
  c: Integer;
  i: Integer;
begin
  if IsMultiPart then
  begin
    c := 0;
    for i := Low(Lens) to High(Lens) do
      c := c + Lens[i];
    Result := Write(Buffer, -c);
  end
  else
    Result := Writes_F(Buffer, Lens);
end;

function TZMWorkFile.WriteSplit(const Buffer; ToWrite: Integer): Integer;
var
  Buf: PAnsiChar;
  Len: Cardinal;
  MaxLen: Cardinal;
  MinSize: Cardinal;
  MustFit: Boolean;
  Res: Integer;
begin { WriteSplit }
  try
    Result := 0;
    MustFit := false;
    if ToWrite >= 0 then
    begin
      Len := ToWrite;
      MinSize := 0;
    end
    else
    begin
      Len := -ToWrite;
      MustFit := (Len and MustFitFlag) <> 0;
      Len := Len and MustFitMask;
      MinSize := Len;
    end;
    Buf := @Buffer;
    Boss.KeepAlive;
    Boss.CheckCancel;

    // Keep writing until error or Buffer is empty.
    while True do
    begin
      // Check if we have an output file already opened, if not: create one,
      // do checks, gather info.
      if (not IsOpen) then
      begin
        NewDisk := DiskNr <> 0; // allow first disk in drive
        if NewSegment then
        begin
          NewDisk := True;
          continue;
        end;
      end;

      // Check if we have at least MinSize available on this disk,
      // headers are not allowed to cross disk boundaries. ( if zero than don't care.)
      if (MinSize <> 0) and (MinSize > AllowedSize) then
      begin // close this part
        // all parts must be same stamp
        if StampDate = 0 then
          StampDate := LastWritten;
        File_Close;
        FDiskWritten := 0;
        NewDisk := True;
        DiskNr := DiskNr + 1; // RCV270299
        if not MustFit then
          continue;
        Result := MustFitError;
        break;
      end;

      // Don't try to write more bytes than allowed on this disk.
      MaxLen := HIGH(Integer);
      if AllowedSize < MaxLen then
        MaxLen := Integer(AllowedSize);
      if Len < MaxLen then
        MaxLen := Len;
      if fDiskBuffer <> nil then
      begin
        Move(Buf^, fDiskBuffer[fBufferPosition], MaxLen);
        Res := MaxLen;
        Inc(fBufferPosition, MaxLen);
      end
      else
        Res := WriteToFile(Buf^, MaxLen);
      if Res < 0 then
        raise EZipMaster.CreateResDisp(DS_NoWrite, True);
      // A write error (disk removed?)

      Inc(FDiskWritten, Res);
      Inc(Result, Res);
      AllowedSize := AllowedSize - MaxLen;
      if MaxLen = Len then
        break;

      // We still have some data left, we need a new disk.
      if StampDate = 0 then
        StampDate := LastWritten;
      File_Close;
      AllowedSize := 0;
      FDiskWritten := 0;
      DiskNr := DiskNr + 1;
      NewDisk := True;
      Inc(Buf, MaxLen);
      Dec(Len, MaxLen);
    end; { while(True) }
  except
    on E: EZipMaster do
    begin
      Result := -E.ResId;
    end;
    on E: Exception do
    begin
      Result := -DS_UnknownError;
    end;
  end;
end;

function TZMWorkFile.Writes_F(const Buffer; const Lens: array of Integer)
  : Integer;
var
  c: Integer;
  i: Integer;
begin
  c := 0;
  for i := Low(Lens) to High(Lens) do
    c := c + Lens[i];
  Result := WriteToFile(Buffer, c);
end;

function TZMWorkFile.WriteToFile(const Buffer; Len: Integer): Integer;
begin
  if Len < 0 then
    Len := (-Len) and MustFitMask;
  Result := DoFileWrite(Buffer, Len);
  if Result > 0 then
    BytesWritten := BytesWritten + Len;
end;

function TZMWorkFile.Write_F(const Buffer; Len: Integer): Integer;
begin
  Result := WriteToFile(Buffer, Len);
end;

function TZMWorkFile.ZipFormat(const NewName: String): Integer;
var
  msg: String;
  Res: Integer;
  Vol: String;
begin
  if NewName <> '' then
    Vol := NewName
  else
    Vol := WorkDrive.DiskName;
  if Length(Vol) > 11 then
    Vol := Copy(Vol, 1, 11);
  Result := -3;
  if WorkDrive.DriveIsFloppy then
  begin
    if (spTryFormat in SpanOptions) then
      Result := FormatFloppy(Application.Handle, WorkDrive.DriveStr);
    if Result = -3 then
    begin
      if ConfirmErase then
      begin
        msg := Boss.ZipFmtLoadStr(FM_Erase, [WorkDrive.DriveStr]);
        Res := Boss.ZipMessageDlgEx(Boss.ZipLoadStr(FM_Confirm), msg,
          zmtWarning + DHC_FormErase, [mbYes, mbNo]);
        if Res <> idYes then
        begin
          Result := -3; // no  was -2; // cancel
          exit;
        end;
      end;
      ClearFloppy(WorkDrive.DriveStr);
      Result := 0;
    end;
    WorkDrive.HasMedia(false);
    if (Result = 0) and (Numbering = znsVolume) then
      WorkDrive.RenameDisk(Vol);
  end;
end;

end.
