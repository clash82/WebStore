unit ZMCore19;

(*
  ZMCore19.pas - event triggering
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

  modified 2009-08-19
  --------------------------------------------------------------------------- *)

interface

// {$DEFINE DEBUG_PROGRESS}

uses
  Classes, SysUtils, Controls, Forms, Dialogs,
  ZipMstr19, ZMXcpt19, ZMDelZip19, ZMStructs19, ZMCompat19;

const
  zprFile = 0;
  zprArchive = 1;
  zprCopyTemp = 2;
  zprSFX = 3;
  zprHeader = 4;
  zprFinish = 5;
  zprCompressed = 6;
  zprCentral = 7;
  zprChecking = 8;
  zprLoading = 9;
  zprJoining = 10;
  zprSplitting = 11;
  zprWriting = 12;

const
  EXT_EXE = '.EXE';
  EXT_EXEL = '.exe';
  EXT_ZIP = '.ZIP';
  EXT_ZIPL = '.zip';
  PRE_INTER = 'ZI$';
  PRE_SFX = 'ZX$';

type
  TZLoadOpts = (zloNoLoad, zloFull, zloSilent);

type
  TZMVerbosity = (zvOff, zvVerbose, zvTrace);
  TZMEncodingDir = (zedFromInt, zedToInt);
  TZipShowProgress = (zspNone, zspFull, zspExtra);

  TZipAllwaysItems = (zaaYesOvrwrt);
  TZipAnswerAlls = set of TZipAllwaysItems;

type
  TZipNameType = (zntExternal, zntInternal);

type
  TProgDetails = class(TZMProgressDetails)
  private
    fDelta: Int64;
    fInBatch: Boolean;
    fItemCount: Int64;
    fItemName: TZMString;
    fItemNumber: Integer;
    fItemPosition: Int64;
    fItemSize: Int64;
    fProgType: TZMProgressType;
    fTotalPosition: Int64;
    fTotalSize: Int64;
    fWritten: Int64;
  protected
    function GetBytesWritten: Int64; override;
    function GetDelta: Int64; override;
    function GetItemName: TZMString; override;
    function GetItemNumber: Integer; override;
    function GetItemPosition: Int64; override;
    function GetItemSize: Int64; override;
    function GetOrder: TZMProgressType; override;
    function GetTotalCount: Int64; override;
    function GetTotalPosition: Int64; override;
    function GetTotalSize: Int64; override;
  public
    procedure Advance(adv: Int64);
    procedure AdvanceXtra(adv: Cardinal);
    procedure Clear;
    procedure SetCount(Count: Int64);
    procedure SetEnd;
    procedure SetItem(const FName: TZMString; FSize: Int64);
    procedure SetItemXtra(const xmsg: TZMString; FSize: Int64);
    procedure SetSize(FullSize: Int64);
    procedure Written(bytes: Int64);
    property BytesWritten: Int64 read GetBytesWritten write fWritten;
    property InBatch: Boolean Read fInBatch;
    property ItemName: TZMString read GetItemName write fItemName;
    property ItemNumber: Integer read GetItemNumber write fItemNumber;
    property ItemPosition: Int64 read GetItemPosition write fItemPosition;
    property ItemSize: Int64 read GetItemSize write fItemSize;
    property Order: TZMProgressType read GetOrder write fProgType;
    property TotalCount: Int64 read GetTotalCount write fItemCount;
    property TotalPosition: Int64 read GetTotalPosition write fTotalPosition;
    property TotalSize: Int64 read GetTotalSize write fTotalSize;
  end;

type
  TZCentralValues = (zcvDirty, zcvEmpty, zcvError, zcvBadStruct, zcvBusy);
  TZCentralStatus = set of TZCentralValues;

type
  TZMPipeImp = class(TZMPipe)
  private
    FAttributes: Cardinal;
    FDOSDate: Cardinal;
    FFileName: string;
    FOwnsStream: boolean;
    FSize: Integer;
    FStream: TStream;
  protected
    function GetAttributes: Cardinal; override;
    function GetDOSDate: Cardinal; override;
    function GetFileName: string; override;
    function GetOwnsStream: boolean; override;
    function GetSize: Integer; override;
    function GetStream: TStream; override;
    procedure SetAttributes(const Value: Cardinal); override;
    procedure SetDOSDate(const Value: Cardinal); override;
    procedure SetFileName(const Value: string); override;
    procedure SetOwnsStream(const Value: boolean); override;
    procedure SetSize(const Value: Integer); override;
    procedure SetStream(const Value: TStream); override;
  public
    procedure AfterConstruction; override;
    procedure AssignTo(Dest: TZMPipeImp);
    procedure BeforeDestruction; override;
  end;

  TZMPipeListImp = class(TZMPipeList)
  private
    List: TList;
  protected
    function GetCount: Integer; override;
    function GetPipe(Index: Integer): TZMPipe; override;
    procedure SetCount(const Value: Integer); override;
    procedure SetPipe(Index: Integer; const Value: TZMPipe); override;
  public
    function Add(aStream: TStream; const FileName: string; Own: boolean): integer; override;
    procedure AfterConstruction; override;
    procedure AssignTo(Dest: TZMPipeListImp);
    procedure BeforeDestruction; override;
    procedure Clear; override;
    function HasStream(Index: Integer): boolean;
    function KillStream(Index: Integer): boolean;
  end;

const
  MAX_PIPE = 9;


type
  TZMCore = class
  private
    fAnswerAll: TZipAnswerAlls;
    fCancel: Integer;
    fCheckNo: Integer;
    fConfirmErase: Boolean;
    FEncodeAs: TZMEncodingOpts;
    FEncoding_CP: Cardinal;
    fFErrCode: Integer;
    fFileCleanup: TStringList;
    fFSpecArgs: TStrings;
    fFSpecArgsExcl: TStrings;
    fHandle: Cardinal;
    fHowToDelete: TZMDeleteOpts;
    FIgnoreDirOnly: Boolean;
    fKeepFreeOnAllDisks: Cardinal;
    fKeepFreeOnDisk1: Cardinal;
    fMaster: TCustomZipMaster19;
    FMaxVolumeSize: Int64;
    fMinFreeVolumeSize: Integer;
    FNoSkipping: TZMSkipAborts;
    fShowProgress: TZipShowProgress;
    fSniffer: Cardinal;
    fSniffNo: Integer;
    fSpanOptions: TZMSpanOpts;
    fUnattended: Boolean;
{$IFNDEF UNICODE}
    fUseUTF8: Boolean;
{$ENDIF}
    fWinXP: Boolean;
    FWriteOptions: TZMWriteOpts;
    function GetErrMessage: TZMString;
    function GetTotalWritten: Int64;
    procedure SetCancel(Value: Integer);
    procedure SetErrCode(Value: Integer);
    procedure SetProgDetail(const Value: TProgDetails);
    procedure SetTotalWritten(const Value: Int64);
  protected
    FAddOptions: TZMAddOpts;
    fBusy: Boolean;
    fEncoding: TZMEncodingOpts;
    FErrMessage: TZMString;
    fEventErr: String;
    FDllErrCode: Integer;
    fIsDestructing: Boolean;
    fNotMainTask: Boolean;
    fProgDetails: TProgDetails;
    FTempDir: String;
    fVerbosity: TZMVerbosity;
    procedure EncodingChanged(New_Enc: TZMEncodingOpts); virtual; abstract;
    procedure Encoding_CPChanged(New_CP: Cardinal); virtual; abstract;
    // 1 Locate sniffer and get overrides
    function FindSniffer: Cardinal;
    function GetTotalSizeToProcess: Int64;
    procedure ReportToSniffer(err: Integer; const msg: TZMString);
    procedure SetEncoding(const Value: TZMEncodingOpts);
    procedure SetEncoding_CP(const Value: Cardinal); //virtual;
    procedure StartUp; virtual;
    property Sniffer: Cardinal Read fSniffer Write fSniffer;
    property SniffNo: Integer Read fSniffNo Write fSniffNo;
  public
    constructor Create(AMaster: TCustomZipMaster19);
    procedure AddCleanupFile(const fn: String; always: Boolean = False);
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure CheckCancel;
    procedure CleanupFiles(IsError: Boolean);
    procedure Clear; virtual;
    procedure ClearErr;
    procedure Diag(const msg: String);
    procedure Done(Good: boolean = true); virtual;
    function FNMatch(const pattern, spec: TZMString): Boolean;
    function KeepAlive: Boolean;
    procedure Kill; virtual;
    function MakeTempFileName(Prefix, Extension: String): String;
    function NextCheckNo: Integer;
    procedure OnDirUpdate;
    procedure OnNewName(idx: Integer);
    function RemoveFileCleanup(const fn: String): Boolean;
    procedure ReportMessage(err: Integer; const msg: TZMString);
    procedure ReportMessage1(err: Integer; const msg: TZMString);
    procedure ReportMsg(id: Integer; const Args: array of const );
    procedure ReportProgress(ActionCode: TActionCodes; ErrorCode: Integer; msg:
        TZMString; File_Size: Int64);
    function ReportSkipping(const FName: String; err: Integer;
      typ: TZMSkipTypes): Boolean;
    procedure ShowExceptionError(const ZMExcept: Exception);
    procedure ShowMsg(const msg: TZMString; err: Integer; display: Boolean);
    procedure ShowZipFmtMsg(id: Integer; const Args: array of const ;
      display: Boolean);
    procedure ShowZipMessage(Ident: Integer; const UserStr: String);
    procedure ShowZipMsg(Ident: Integer; display: Boolean);
    function ZipFmtLoadStr(id: Integer; const Args: array of const ): TZMString;
    function ZipLoadStr(id: Integer): TZMString;
    function ZipMessageDialog(const title: String; var msg: String;
      context: Integer; btns: TMsgDlgButtons): TModalResult;
    procedure ZipMessageDlg(const msg: String; context: Integer);
    function ZipMessageDlgEx(const title, msg: String; context: Integer;
      btns: TMsgDlgButtons): TModalResult;
    property AddOptions: TZMAddOpts read FAddOptions write FAddOptions;
    property AnswerAll: TZipAnswerAlls Read fAnswerAll Write fAnswerAll;
    property Busy: Boolean Read fBusy Write fBusy;
    property Cancel: Integer Read fCancel Write SetCancel;
    property ConfirmErase
      : Boolean Read fConfirmErase Write fConfirmErase default True;
    property EncodeAs: TZMEncodingOpts read FEncodeAs write FEncodeAs;
    property Encoding: TZMEncodingOpts Read fEncoding Write SetEncoding;
    property ErrCode: Integer Read fFErrCode Write SetErrCode;
    property ErrMessage: TZMString read GetErrMessage write FErrMessage;
    property FSpecArgs: TStrings Read fFSpecArgs Write fFSpecArgs;
    property FSpecArgsExcl: TStrings Read fFSpecArgsExcl Write fFSpecArgsExcl;
    property DllErrCode: Integer read FDllErrCode write FDllErrCode;
    property Encoding_CP: Cardinal read FEncoding_CP write SetEncoding_CP;
    property Handle: Cardinal Read fHandle;
    property HowToDelete: TZMDeleteOpts Read fHowToDelete Write fHowToDelete;
    property IgnoreDirOnly: Boolean read FIgnoreDirOnly;
    property KeepFreeOnAllDisks
      : Cardinal Read fKeepFreeOnAllDisks Write fKeepFreeOnAllDisks;
    property KeepFreeOnDisk1
      : Cardinal Read fKeepFreeOnDisk1 Write fKeepFreeOnDisk1;
    property Master: TCustomZipMaster19 Read fMaster;
    property MaxVolumeSize: Int64 read FMaxVolumeSize write FMaxVolumeSize;
    property MinFreeVolumeSize
      : Integer Read fMinFreeVolumeSize Write fMinFreeVolumeSize;
    property NoSkipping: TZMSkipAborts read FNoSkipping;
    property NotMainTask: Boolean Read fNotMainTask Write fNotMainTask;
    property ProgDetail: TProgDetails Read fProgDetails Write SetProgDetail;
    property ShowProgress
      : TZipShowProgress Read fShowProgress Write fShowProgress;
    property SpanOptions: TZMSpanOpts Read fSpanOptions Write fSpanOptions;
    property TempDir: String read FTempDir write FTempDir;
    property TotalWritten: Int64 read GetTotalWritten write SetTotalWritten;
    property Unattended: Boolean Read fUnattended Write fUnattended;
{$IFNDEF UNICODE}
    property UseUTF8: Boolean read fUseUTF8 write fUseUTF8;
{$ENDIF}
    property Verbosity: TZMVerbosity Read fVerbosity Write fVerbosity;
    property WinXP: Boolean Read fWinXP;
    property WriteOptions: TZMWriteOpts read FWriteOptions write FWriteOptions;
  end;

implementation

{$INCLUDE '.\ZipVers19.inc'}

uses Windows, Messages, ZMUtils19, ZMDlg19, ZMMsg19, ZMCtx19, ZMMsgStr19,
  ZMUTF819, ZMMatch19;

const
  SZipMasterSniffer = 'ZipMaster Sniffer';
  STZipSniffer = 'TZipSniffer';
  WM_SNIFF_START = WM_APP + $3F42;
  WM_SNIFF_STOP = WM_APP + $3F44;
  SNIFF_MASK = $FFFFFF;
  RESOURCE_ERROR: String =
    'ZMRes19_???.res is probably not linked to the executable' + #10 +
    'Missing String ID is: %d ';

  { TProgDetails }
procedure TProgDetails.Advance(adv: Int64);
begin
  fDelta := adv;
  fTotalPosition := fTotalPosition + adv;
  fItemPosition := fItemPosition + adv;
  fProgType := ProgressUpdate;
end;

procedure TProgDetails.AdvanceXtra(adv: Cardinal);
begin
  fDelta := adv;
  Inc(fItemPosition, adv);
  fProgType := ExtraUpdate;
end;

procedure TProgDetails.Clear;
begin
  fProgType := EndOfBatch;
  fDelta := 0;
  fItemCount := 0;
  fWritten := 0;
  fTotalSize := 0;
  fTotalPosition := 0;
  fItemSize := 0;
  fItemPosition := 0;
  fItemName := '';
  fItemNumber := 0;
end;

function TProgDetails.GetBytesWritten: Int64;
begin
  Result := fWritten;
end;

function TProgDetails.GetDelta: Int64;
begin
  Result := fDelta;
end;

function TProgDetails.GetItemName: TZMString;
begin
  Result := fItemName;
end;

function TProgDetails.GetItemNumber: Integer;
begin
  Result := fItemNumber;
end;

function TProgDetails.GetItemPosition: Int64;
begin
  Result := fItemPosition;
end;

function TProgDetails.GetItemSize: Int64;
begin
  Result := fItemSize;
end;

function TProgDetails.GetOrder: TZMProgressType;
begin
  Result := fProgType;
end;

function TProgDetails.GetTotalCount: Int64;
begin
  Result := fItemCount;
end;

function TProgDetails.GetTotalPosition: Int64;
begin
  Result := fTotalPosition;
end;

function TProgDetails.GetTotalSize: Int64;
begin
  Result := fTotalSize;
end;

procedure TProgDetails.SetCount(Count: Int64);
begin
  Clear;
  fItemCount := Count;
  fItemNumber := 0;
  fProgType := TotalFiles2Process;
end;

procedure TProgDetails.SetEnd;
begin
  fItemName := '';
  fItemSize := 0;
  fInBatch := False;
  fProgType := EndOfBatch;
end;

procedure TProgDetails.SetItem(const FName: TZMString; FSize: Int64);
begin
  Inc(fItemNumber);
  fItemName := FName;
  fItemSize := FSize;
  fItemPosition := 0;
  fProgType := NewFile;
end;

procedure TProgDetails.SetItemXtra(const xmsg: TZMString; FSize: Int64);
begin
  fItemName := xmsg;
  fItemSize := FSize;
  fItemPosition := 0;
  fProgType := NewExtra;
end;

procedure TProgDetails.SetSize(FullSize: Int64);
begin
  fTotalSize := FullSize;
  fTotalPosition := 0;
  fItemName := '';
  fItemSize := 0;
  fItemPosition := 0;
  fProgType := TotalSize2Process;
  fWritten := 0;
  fInBatch := True; // start of batch
end;

procedure TProgDetails.Written(bytes: Int64);
begin
  fWritten := bytes;
end;

{ TZMCore }
constructor TZMCore.Create(AMaster: TCustomZipMaster19);
begin
  fMaster := AMaster;
end;

procedure TZMCore.AddCleanupFile(const fn: String; always: Boolean = False);
var
  f: String;
  obj: TObject;
begin
  f := ExpandFileName(fn); // need full path incase current dir changes
  obj := nil;
  if always then
    obj := TObject(self);
  fFileCleanup.AddObject(f, obj);
end;

procedure TZMCore.AfterConstruction;
begin
  inherited;
  fHandle := Application.Handle;
  fProgDetails := TProgDetails.Create;
  fFSpecArgs := TStringList.Create;
  fFSpecArgsExcl := TStringList.Create;
  fFileCleanup := TStringList.Create;
  fHowToDelete := htdAllowUndo;
  fSpanOptions := [];
  FErrMessage := '';
  fFErrCode := -1;
  fVerbosity := zvOff;
  fUnattended := True; // during construction
  fEncoding := zeoAuto;
  FEncodeAs := zeoAuto;
  fVerbosity := zvOff;
  fTempDir := '';
  fNotMainTask := False;
  fWinXP := IsWinXP; // set flag;
end;

procedure TZMCore.BeforeDestruction;
begin
  fCancel := DS_Canceled;
  fVerbosity := zvOff;
  FreeAndNil(fFileCleanup);
  FreeAndNil(fProgDetails);
  FreeAndNil(fFSpecArgsExcl);
  FreeAndNil(fFSpecArgs);
  inherited;
end;

procedure TZMCore.CheckCancel;
begin
  KeepAlive;
  if fCancel <> 0 then
    raise EZipMaster.CreateResDisp(Cancel, True);
end;

procedure TZMCore.CleanupFiles(IsError: Boolean);
var
  AlwaysClean: Boolean;
  fn: String;
  i: Integer;
begin
  if (fFileCleanup.Count > 0) then
  begin
    for i := fFileCleanup.Count - 1 downto 0 do
    begin
      fn := fFileCleanup[i];
      if Length(fn) < 2 then
        continue;
      AlwaysClean := fFileCleanup.Objects[i] <> nil;
      if IsError or AlwaysClean then
      begin
        if CharInSet(fn[Length(fn)], ['/', '\']) then
        begin
          fn := ExcludeTrailingBackslash(fn);
          if DirExists(fn) then
            RemoveDir(fn);
        end
        else
        begin
          if FileExists(fn) then
            SysUtils.DeleteFile(fn);
        end;
      end;
    end;
    fFileCleanup.Clear;
  end;
end;

procedure TZMCore.Clear;
begin
  Cancel := 0;
  ClearErr;
  fHowToDelete := htdAllowUndo;
  fUnattended := False;
  fEncoding := zeoAuto;
  FEncodeAs := zeoAuto;
  fVerbosity := zvOff;
  TProgDetails(fProgDetails).Clear;
  fFSpecArgs.Clear;
  fFSpecArgsExcl.Clear;
  fEventErr := '';
  fIsDestructing := False;
  fSpanOptions := [];
  FWriteOptions := [];
end;

procedure TZMCore.ClearErr;
begin
  FErrMessage := '';
  fFErrCode := 0;
  FDllErrCode := 0;
end;

procedure TZMCore.Diag(const msg: String);
begin
  if Verbosity >= zvVerbose then
    ShowMsg('Trace: ' + msg, 0, False); // quicker
end;

procedure TZMCore.Done(Good: boolean = true);
begin
  CleanupFiles(not Good);
  if Sniffer <> 0 then
  begin
    // send finished
    SendMessage(Sniffer, WM_SNIFF_STOP, 0, SniffNo);
    Sniffer := 0;
  end;
  fBusy := False;
end;

function TZMCore.FindSniffer: Cardinal;
var
  flgs: Cardinal;
  res: Integer;
begin
  Result := FindWindow(PChar(STZipSniffer), PChar(SZipMasterSniffer));
  if Result <> 0 then
  begin
    res := SendMessage(Result, WM_SNIFF_START, Longint(Handle), Ord(Verbosity));
    if res < 0 then
    begin
      Result := 0; // invalid
      exit;
    end;
    // in range so hopefully valid response
    flgs := Cardinal(res) shr 24;
    if flgs >= 8 then
    begin
      Result := 0; // invalid
      exit;
    end;
    // treat it as valid
    if flgs > 3 then
      Verbosity := TZMVerbosity(flgs and 3); // force it
    SniffNo := res and SNIFF_MASK; // operation number
  end;
end;

function TZMCore.FNMatch(const pattern, spec: TZMString): Boolean;
begin
{$IFDEF UNICODE}
  Result := FileNameMatch(pattern, spec);
{$ELSE}
  Result := FileNameMatch(pattern, spec, UseUTF8);
{$ENDIF}
end;

(* ? TZMCore.GetErrMessage
  1.73 13 July 2003 RP only return ErrMessage if error
*)
function TZMCore.GetErrMessage: TZMString;
begin
  Result := '';
  if ErrCode <> 0 then
  begin
    Result := FErrMessage;
    if Result = '' then
      Result := ZipLoadStr(ErrCode);
    if Result = '' then
      Result := ZipFmtLoadStr(GE_Unknown, [ErrCode]);
  end;
end;

function TZMCore.GetTotalSizeToProcess: Int64;
begin
  Result := TProgDetails(fProgDetails).TotalSize;
end;

function TZMCore.GetTotalWritten: Int64;
begin
  Result := ProgDetail.BytesWritten;
end;

function TZMCore.KeepAlive: Boolean;
var
  DoStop: Boolean;
  tmpCheckTerminate: TZMCheckTerminateEvent;
  tmpTick: TZMTickEvent;
begin
  Result := Cancel <> 0;
  tmpTick := Master.OnTick;
  if assigned(tmpTick) then
    tmpTick(Master);
  tmpCheckTerminate := Master.OnCheckTerminate;
  if assigned(tmpCheckTerminate) then
  begin
    DoStop := Cancel <> 0;
    tmpCheckTerminate(Master, DoStop);
    if DoStop then
      Cancel := DS_Canceled;
  end
  else if not fNotMainTask then
    Application.ProcessMessages;
end;

procedure TZMCore.Kill;
begin
  fCancel := DS_Canceled;
end;

(* ? TZMCore.MakeTempFileName
  Make a temporary filename like: C:\...\zipxxxx.zip
  Prefix and extension are default: 'zip' and '.zip'
*)
function TZMCore.MakeTempFileName(Prefix, Extension: String): String;
var
  buf: String;
  len: DWORD;
  tmpDir: String;
begin
  if Prefix = '' then
    Prefix := 'zip';
  if Extension = '' then
    Extension := EXT_ZIPL;
  if Length(TempDir) = 0 then // Get the system temp dir
  begin
    // 1. The path specified by the TMP environment variable.
    // 2. The path specified by the TEMP environment variable, if TMP is not defined.
    // 3. The current directory, if both TMP and TEMP are not defined.
    len := GetTempPath(0, PChar(tmpDir));
    SetLength(tmpDir, len);
    GetTempPath(len, PChar(tmpDir));
  end
  else // Use Temp dir provided by ZipMaster
  begin
    tmpDir := DelimitPath(TempDir, True);
  end;
  SetLength(buf, MAX_PATH + 12);
  if GetTempFileName(PChar(tmpDir), PChar(Prefix), 0, PChar(buf)) <> 0 then
  begin
    buf := PChar(buf);
    SysUtils.DeleteFile(buf); // Needed because GetTempFileName creates the file also.
    Result := ChangeFileExt(buf, Extension);
    // And finally change the extension.
  end;
end;

function TZMCore.NextCheckNo: Integer;
begin
  Inc(fCheckNo);
  Result := fCheckNo;
end;

procedure TZMCore.OnDirUpdate;
begin
  if assigned(Master.OnDirUpdate) then
    Master.OnDirUpdate(Master);
end;

procedure TZMCore.OnNewName(idx: Integer);
begin
  if assigned(Master.OnNewName) then
    Master.OnNewName(Master, idx);
end;

function TZMCore.RemoveFileCleanup(const fn: String): Boolean;
var
  f: String;
  i: Integer;
begin
  Result := False;
  f := ExpandFileName(fn);
  for i := fFileCleanup.Count - 1 downto 0 do
    if AnsiSameText(fFileCleanup[i], f) then
    begin
      fFileCleanup.Delete(i);
      Result := True;
      break;
    end;
end;

procedure TZMCore.ReportMessage(err: Integer; const msg: TZMString);
begin
  if Sniffer <> 0 then
    ReportToSniffer(err, msg);
  ReportMessage1(err, msg);
end;

procedure TZMCore.ReportMessage1(err: Integer; const msg: TZMString);
var
  tmpMessage: TZMMessageEvent;
begin
  if (err <> 0) and (ErrCode = 0) then // only catch first
  begin
    if DllErrCode = 0 then
      FDllErrCode := err;
    fFErrCode := err;
    FErrMessage := msg;
  end;
  tmpMessage := Master.OnMessage;
  if assigned(tmpMessage) then
    tmpMessage(Master, err, msg);
  KeepAlive; // process messages or check terminate
end;

procedure TZMCore.ReportMsg(id: Integer; const Args: array of const );
var
  msg: TZMString;
  p: Integer;
begin
  msg := ZipFmtLoadStr(id, Args);
  if msg <> '' then
  begin
    p := 0;
    case msg[1] of
      '#':
        p := TM_Trace;
      '!':
        p := TM_Verbose;
    end;
    if p <> 0 then
    begin
      msg := ZipLoadStr(p) + copy(msg, 2, Length(msg) - 1);
    end;
  end;
  ReportMessage(0, msg);
end;

(* ? TZMCore.ReportProgress
  1.77.2.0 14 September 2004 - RP fix setting ErrCode caused re-entry
  1.77.2.0 14 September 2004 - RP alter thread support & OnCheckTerminate
  1.77 16 July 2004 - RP preserve last errors ErrMessage
  1.76 24 April 2004 - only handle 'progress' and information
*)
procedure TZMCore.ReportProgress(ActionCode: TActionCodes; ErrorCode: Integer;
    msg: TZMString; File_Size: Int64);
var
  Details: TProgDetails;
  SendDetails: Boolean;
  tmpProgress: TZMProgressEvent;
begin
  if fIsDestructing then
    exit;
  if ActionCode <= zacXProgress then
  begin
    Details := fProgDetails as TProgDetails;
    SendDetails := True;
    case ActionCode of
      zacTick: { 'Tick' Just checking / processing messages }
        begin
          KeepAlive;
          SendDetails := False;
        end;

      zacItem: { progress type 1 = StartUp any ZIP operation on a new file }
        Details.SetItem(msg, File_Size);

      zacProgress: { progress type 2 = increment bar }
        Details.Advance(File_Size);

      zacEndOfBatch: { end of a batch of 1 or more files }
        begin
          if Details.InBatch then
            Details.SetEnd
          else
            SendDetails := False;
        end;

      zacCount: { total number of files to process }
        Details.SetCount(File_Size);

      zacSize: { total size of all files to be processed }
        Details.SetSize(File_Size);

      zacXItem: { progress type 15 = StartUp new extra operation }
        begin
          if ErrorCode < 20 then
            ErrorCode := PR_Progress + ErrorCode;
          msg := ZipLoadStr(ErrorCode);
          Details.SetItemXtra(msg, File_Size);
        end;

      zacXProgress: { progress type 16 = increment bar for extra operation }
        Details.AdvanceXtra(File_Size);
    end; { end case }
{$IFDEF DEBUG_PROGRESS}
    if Verbosity >= zvVerbose then
      case ActionCode of
        zacItem:
          Diag(Format('#Item - "%s" %d', [Details.ItemName, Details.ItemSize]));
        zacProgress:
          Diag(Format('#Progress - [inc:%d] ipos:%d isiz:%d, tpos:%d tsiz:%d',
              [File_Size, Details.ItemPosition, Details.ItemSize,
              Details.TotalPosition, Details.TotalSize]));
        zacEndOfBatch:
          if SendDetails then
            Diag('#End Of Batch')
          else
            Diag('#End Of Batch with no batch');
        zacCount:
          Diag(Format('#Count - %d', [Details.TotalCount]));
        zacSize:
          Diag(Format('#Size - %d', [Details.TotalSize]));
        zacXItem:
          Diag(Format('#XItem - %s size = %d', [Details.ItemName, File_Size]));
        zacXProgress:
          Diag(Format('#XProgress - [inc:%d] pos:%d siz:%d',
              [File_Size, Details.ItemPosition, Details.ItemSize]));
      end;
{$ENDIF}
    tmpProgress := Master.OnProgress;
    if SendDetails and (assigned(tmpProgress)) then
      tmpProgress(Master, Details);
  end;

  KeepAlive;
end;

// returns True if skipping not allowed
function TZMCore.ReportSkipping(const FName: String; err: Integer;
  typ: TZMSkipTypes): Boolean;
var
  ti: Integer;
  tmpMessage: ZipMstr19.TZMMessageEvent;
  tmpSkipped: TZMSkippedEvent;
begin
  Result := False;
  if typ in NoSkipping then
  begin
    if err = 0 then
      err := GE_NoSkipping;
  end;
  ti := err;
  if ti < 0 then
    ti := -ti;
  if (ti <> 0) and (typ in NoSkipping) then
    ti := -ti; // default to abort
  tmpSkipped := Master.OnSkipped;
  if assigned(tmpSkipped) then
    tmpSkipped(Master, FName, typ, ti)
  else if Verbosity >= zvVerbose then
  begin
    tmpMessage := Master.OnMessage;
    if assigned(tmpMessage) then
      tmpMessage(Master, GE_Unknown, ZipFmtLoadStr
          (GE_Skipped, [FName, Ord(typ)]));
  end;
  if ti < 0 then
    Result := True; // Skipping not allowed
  if Sniffer <> 0 then
    ReportToSniffer(0, Format('[Skipped] IN=%d,%d OUT=%d', [err, Ord(typ), Ord
          (Result)]));
end;

procedure TZMCore.ReportToSniffer(err: Integer; const msg: TZMString);
var
  aCopyData: TCopyDataStruct;
  msg8: UTF8String;
begin
  if Sniffer = 0 then // should not happen
    exit;
  // always feed Sniffer with UTF8
{$IFDEF UNICODE}
  msg8 := StrToUTF8(msg);
{$ELSE}
  if UseUTF8 then
    msg8 := msg
  else
    msg8 := StrToUTF8(msg);
{$ENDIF}
  aCopyData.dwData := Cardinal(err);
  aCopyData.cbData := (Length(msg8) + 1) * sizeof(AnsiChar);
  aCopyData.lpData := @msg8[1];
  if SendMessage(Sniffer, WM_COPYDATA, SniffNo, Longint(@aCopyData)) = 0 then
    Sniffer := 0; // could not process it -don't try again
end;

procedure TZMCore.SetCancel(Value: Integer);
begin
  fCancel := Value;
end;

procedure TZMCore.SetEncoding(const Value: TZMEncodingOpts);
begin
  if Encoding <> Value then
  begin
    FEncoding := Value;
    EncodingChanged(Value);
  end;
end;

procedure TZMCore.SetEncoding_CP(const Value: Cardinal);
begin
  if Encoding_CP <> Value then
  begin
    FEncoding_CP := Value;
    Encoding_CPChanged(Value);
  end;
end;

(* ? TZMCore.SetErrCode
  Some functions return -error - normalise these values
*)
procedure TZMCore.SetErrCode(Value: Integer);
begin
  if Value < 0 then
    fFErrCode := -Value
  else
    fFErrCode := Value;
end;

procedure TZMCore.SetProgDetail(const Value: TProgDetails);
begin
  // do not change
end;

procedure TZMCore.SetTotalWritten(const Value: Int64);
begin
  ProgDetail.Written(Value);
end;

(* ? TZMCore.ShowExceptionError
  1.80 strings already formatted
  // Somewhat different from ShowZipMessage() because the loading of the resource
  // string is already done in the constructor of the exception class.
*)
procedure TZMCore.ShowExceptionError(const ZMExcept: Exception);
var
  display: Boolean;
  msg: String;
  ResID: Integer;
begin
  if ZMExcept is EZMException then
  begin
    ResID := EZMException(ZMExcept).ResID;
    display := EZMException(ZMExcept).DisplayMsg;
{$IFDEF UNICODE}
    msg := EZMException(ZMExcept).Message;
{$ELSE}
    msg := EZMException(ZMExcept).TheMessage(UseUTF8);
{$ENDIF}
  end
  else
  begin
    ResID := GE_ExceptErr;
    display := True;
    msg := ZMExcept.Message;
  end;
  ShowMsg(msg, ResID, display);
end;

procedure TZMCore.ShowMsg(const msg: TZMString; err: Integer; display: Boolean);
const
  NotReporteds: array[0..3] of Integer =
      (GE_Abort, DS_Canceled, DS_CECommentLen, LI_WrongZipStruct);
var
  i: Integer;
begin
  FErrMessage := msg;
  if err < 0 then
    fFErrCode := -err
  else
    fFErrCode := err;
//  if display and (not fUnattended) and (ErrCode <> GE_Abort) and
//    (ErrCode <> DS_Canceled) and (ErrCode <> DS_CECommentLen) then
//    ZipMessageDlg(msg, zmtInformation + DHC_ZipMessage);
  if display and (not fUnattended) then
  begin
    for i := 0 to high(NotReporteds) do
      if ErrCode = NotReporteds[i] then
      begin
        display := False;
        Break;
      end;
    if display then
      ZipMessageDlg(msg, zmtInformation + DHC_ZipMessage);
  end;
  ReportMessage(ErrCode, msg);
end;

(* ? TZMCore.ShowZipFmtMsg
  1.79 added
*)
procedure TZMCore.ShowZipFmtMsg(id: Integer; const Args: array of const ;
  display: Boolean);
begin
  if id < 0 then
    id := -id;
  ShowMsg(ZipFmtLoadStr(id, Args), id, display);
end;

(* ? TZMCore.ShowZipMessage
*)
procedure TZMCore.ShowZipMessage(Ident: Integer; const UserStr: String);
var
  msg: String;
begin
  if Ident < 0 then
    Ident := -Ident;
  msg := ZipLoadStr(Ident);
  if msg = '' then
    msg := Format(RESOURCE_ERROR, [Ident]);
  msg := msg + UserStr;
  ShowMsg(msg, Ident, True);
end;

procedure TZMCore.ShowZipMsg(Ident: Integer; display: Boolean);
var
  msg: String;
begin
  if Ident < 0 then
    Ident := -Ident;
  msg := ZipLoadStr(Ident);
  if msg = '' then
    msg := Format(RESOURCE_ERROR, [Ident]);
  ShowMsg(msg, Ident, display);
end;

(* ? TZMCore.StartUp
*)
procedure TZMCore.StartUp;
var
  s: String;
begin
  fBusy := True;
  Cancel := 0;
  fAnswerAll := [];
  ClearErr;
{$IFNDEF UNICODE}
  fUseUTF8 := Master.UseUTF8;
{$ENDIF}
  fHandle := Master.Handle;
  FAddOptions := Master.AddOptions;
  fUnattended := Master.Unattended;
  fConfirmErase := Master.ConfirmErase;
  fKeepFreeOnAllDisks := Master.KeepFreeOnAllDisks;
  fKeepFreeOnDisk1 := Master.KeepFreeOnDisk1;
  if Master.MaxVolumeSizeKb = 0 then
    FMaxVolumeSize := Master.MaxVolumeSize
  else
    FMaxVolumeSize := Master.MaxVolumeSizeKb * 1024;
  fMinFreeVolumeSize := Master.MinFreeVolumeSize;
  FNoSkipping := Master.NoSkipping;
  fSpanOptions := Master.SpanOptions;
  FWriteOptions := Master.WriteOptions;
  if Master.Trace then
    fVerbosity := zvTrace
  else if Master.Verbose then
    fVerbosity := zvVerbose
  else
    fVerbosity := zvOff;
  {f}Encoding := Master.Encoding;
  Encoding_CP := Master.Encoding_CP;
  FEncodeAs := Master.EncodeAs;
  fHowToDelete := Master.HowToDelete;
  TempDir := Master.TempDir;
  fFSpecArgs.Assign(Master.FSpecArgs);
  fFSpecArgsExcl.Assign(Master.FSpecArgsExcl);
  FIgnoreDirOnly := not Master.UseDirOnlyEntries;
  fNotMainTask := Master.NotMainThread;
  if GetCurrentThreadID <> MainThreadID then
    fNotMainTask := True;
  Sniffer := FindSniffer;
  if Sniffer <> 0 then
  begin
    if Master.Owner <> nil then
    begin
      s := Master.Owner.Name;
      if s <> '' then
        s := s + '.';
    end;
    if Master.Name = '' then
      s := '<unknown>'
    else
      s := s + Master.Name;
    if fNotMainTask then
      s := '*' + s;
    ReportToSniffer(0, 'Starting ' + s);
  end;
  fFileCleanup.Clear;
end;

function TZMCore.ZipFmtLoadStr(id: Integer; const Args: array of const )
  : TZMString;
begin
  Result := ZipLoadStr(id);

  if Result <> '' then
    Result := Format(Result, Args);
end;

function TZMCore.ZipLoadStr(id: Integer): TZMString;
begin
  Result := LoadZipStr(id);
{$IFNDEF UNICODE}
  if (Result <> '') and UseUTF8 then
    Result := StrToUTF8(Result);
{$ENDIF}
end;

function TZMCore.ZipMessageDialog(const title: String; var msg: String;
  context: Integer; btns: TMsgDlgButtons): TModalResult;
var
  ctx: Integer;
  dlg: TZipDialogBox;
  s: String;
  t: String;
  tmpZipDialog: TZMDialogEvent;
begin
  t := title;
  if title = '' then
    t := Application.title;
  if Verbosity >= zvVerbose then
    t := Format('%s   (%d)', [t, context and MAX_WORD]);
  tmpZipDialog := Master.OnZipDialog;
  if assigned(tmpZipDialog) then
  begin
    s := msg;
    ctx := context;
    tmpZipDialog(Master, t, s, ctx, btns);
    if (ctx > 0) and (ctx <= Ord(mrYesToAll)) then
    begin
      msg := s;
      Result := TModalResult(ctx);
      exit;
    end;
  end;
  dlg := TZipDialogBox.CreateNew2(Application, context);
  try
    dlg.Build(t, msg, btns {$IFNDEF UNICODE}, UseUTF8 {$ENDIF});
    dlg.ShowModal();
    Result := dlg.ModalResult;
    if dlg.DlgType = zmtPassword then
    begin
      if (Result = mrOk) then
        msg := dlg.PWrd
      else
        msg := '';
    end;
  finally
    FreeAndNil(dlg);
  end;
end;

procedure TZMCore.ZipMessageDlg(const msg: String; context: Integer);
begin
  ZipMessageDlgEx('', msg, context, [mbOK]);
end;

function TZMCore.ZipMessageDlgEx(const title, msg: String; context: Integer;
  btns: TMsgDlgButtons): TModalResult;
var
  m: String;
begin
  m := msg;
  Result := ZipMessageDialog(title, m, context, btns);
end;

procedure TZMPipeImp.AfterConstruction;
begin
  inherited;
  FStream := nil;
  fSize := 0;
  fDOSDate := Cardinal(DateTimeToFileDate(now));
  fAttributes := 0;
end;

procedure TZMPipeImp.AssignTo(Dest: TZMPipeImp);
begin
  if Dest <> self then
  begin
    Dest.Stream := FStream;
    FStream := nil;
    Dest.Size := FSize;
    Dest.DOSDate := fDOSDate;
    Dest.Attributes := FAttributes;
    Dest.OwnsStream := FOwnsStream;
  end;
end;

procedure TZMPipeImp.BeforeDestruction;
begin
  if OwnsStream and (FStream <> nil) then
    FStream.Free;
  inherited;
end;

function TZMPipeImp.GetAttributes: Cardinal;
begin
  Result := FAttributes;
end;

function TZMPipeImp.GetDOSDate: Cardinal;
begin
  Result := FDOSDate;
end;

function TZMPipeImp.GetFileName: string;
begin
  Result := FFileName;
end;

function TZMPipeImp.GetOwnsStream: boolean;
begin
  Result := FOwnsStream;
end;

function TZMPipeImp.GetSize: Integer;
begin
  Result := FSize;
end;

function TZMPipeImp.GetStream: TStream;
begin
  Result := FStream;
end;

procedure TZMPipeImp.SetAttributes(const Value: Cardinal);
begin
  FAttributes := Value;
end;

procedure TZMPipeImp.SetDOSDate(const Value: Cardinal);
begin
  FDOSDate := Value;
end;

procedure TZMPipeImp.SetFileName(const Value: string);
begin
  if FFileName <> Value then
  begin
    FFileName := Value;
  end;
end;

procedure TZMPipeImp.SetOwnsStream(const Value: boolean);
begin
  FOwnsStream := Value;
end;

procedure TZMPipeImp.SetSize(const Value: Integer);
begin
  if Value <> FSize then
  begin
    if FStream = nil then
      FSize := 0
    else
    begin
      if Value > FStream.Size then
        FSize := Integer(FStream.Size)
      else
        FSize := Value;
    end;
  end;
end;

procedure TZMPipeImp.SetStream(const Value: TStream);
begin
  if FStream <> Value then
  begin
    if Value = nil then
      FStream.Free;
    FStream := Value;
    if Value <> nil then
    begin
      FSize := Integer(FStream.Size);
      FStream.Position := 0;
    end;
  end;
end;

function TZMPipeListImp.Add(aStream: TStream; const FileName: string; Own:
    boolean): integer;
var
  tmpPipe: TZMPipe;
begin
  Result := List.Count;
  tmpPipe := Pipe[Result];
  tmpPipe.Stream := aStream;
  tmpPipe.FileName := FileName;
  tmpPipe.OwnsStream := Own;
end;

procedure TZMPipeListImp.AfterConstruction;
begin
  inherited;
  List := TList.Create;
end;

procedure TZMPipeListImp.AssignTo(Dest: TZMPipeListImp);
var
  I: Integer;
begin
  if (Dest <> nil) and (Dest <> Self) then
  begin
    Dest.Clear;
    for I := 0 to Count - 1 do
      Dest.List.Add(List[i]);
    List.Clear;
  end;
end;

procedure TZMPipeListImp.BeforeDestruction;
begin
  Clear;
  List.Free;
  inherited;
end;

procedure TZMPipeListImp.Clear;
var
  i: Integer;
  tmp: TZMPipeImp;
begin
  if (List <> nil) and (List.Count > 0) then
  begin
    for I := 0 to List.Count - 1 do
    begin
     if TObject(List[i]) is TZMPipeImp then
      begin
        tmp := TZMPipeImp(List[i]);
        List[i] := nil;
        tmp.Free;
      end;
    end;
    List.Clear;
  end;
end;

function TZMPipeListImp.GetCount: Integer;
begin
  Result := List.Count;
end;

function TZMPipeListImp.GetPipe(Index: Integer): TZMPipe;
var
  tmpPipe: TZMPipeImp;
begin
  if (Index <0) or (Index > MAX_PIPE) then
    raise EZipMaster.CreateResFmt(GE_RangeError, [Index, MAX_PIPE]);
  if Index >= List.Count then
    List.Count := Index + 1;
   if not (TObject(List[Index]) is TZMPipeImp) then
   begin
     // need a new one
     tmpPipe := TZMPipeImp.Create;
     List[Index] := tmpPipe;
   end;
   Result := TZMPipeImp(List[Index]);
end;

function TZMPipeListImp.HasStream(Index: Integer): boolean;
begin
  Result := (Index >= 0) and (Index < count) and (Pipe[Index].Stream <> nil);
end;

function TZMPipeListImp.KillStream(Index: Integer): boolean;
var
  tmp: TZMPipe;
begin
  Result := False;
  if (Index >= 0) and (Index < count) then
  begin
    tmp := Pipe[Index];
    if tmp.OwnsStream and (tmp.Stream <> nil) then
      tmp.Stream := nil;
  end;
end;

procedure TZMPipeListImp.SetCount(const Value: Integer);
var
  I: Integer;
begin
  if (Value <0) or (Value > MAX_PIPE) then
    raise EZipMaster.CreateResInt(GE_RangeError, Value);
  if Value > List.Count then
  begin
    I := List.Count;
    while I < Value do
      List.Add(nil);
  end;
end;

procedure TZMPipeListImp.SetPipe(Index: Integer; const Value: TZMPipe);
var
  tmpPipe: TZMPipeImp;
begin
  if (Index <0) or (Index > MAX_PIPE) then
    raise EZipMaster.CreateResInt(GE_RangeError, Index);
  if Index >= List.Count then
    List.Count := Index + 1;
  if not (TObject(List[Index]) is TZMPipeImp) then
    List[Index] := Value
  else
  begin
    tmpPipe := TZMPipeImp(List[Index]);
    if Value <> tmpPipe then
    begin
      tmpPipe.Free;
      List[Index] := Value;
    end;
  end;
end;


end.
