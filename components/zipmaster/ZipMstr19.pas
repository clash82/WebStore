unit ZipMstr19;

(*
  ZipMstr19.pas - main component
  TZipMaster19 VCL by Chris Vleghert and Eric W. Engler
  v1.9
  Copyright (C) 2009, 2010  Russell Peters


  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License (licence.txt) for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with this library; if not, write to the Free Software Foundation, Inc.,
  51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  contact: problems AT delphizip DOT org
  updates: http://www.delphizip.org

  modified 2010-08-06
---------------------------------------------------------------------------*)
{$I '.\ZipVers19.inc'}
{$I '.\ZMConfig19.inc'}

interface

uses
  Classes, SysUtils, Graphics, Dialogs, Windows, Controls,
  ZMXcpt19, ZMStructs19;

const
  ZIPMASTERBUILD: String =  '1.9.0.0107';
  ZIPMASTERDATE: String  =  '12/12/2010';
  ZIPMASTERPRIV: Integer = 1900107;
  DELZIPVERSION          = 190;

const
  ZMReentry_Error: Integer = $4000000;

const
  ZMPWLEN = 80;

type
{$IFDEF UNICODE}
  TZMString     = String; // unicode
  TZMWideString = String;
  TZMRawBytes = RawByteString;
{$ELSE}
  {$IFNDEF VERD6up}
  UTF8String    = type String;
  {$ENDIF}
  TZMString     = AnsiString;  // Ansi/UTF8 depending upon UseUTF8
  TZMWideString = WideString;
  TZMRawBytes =  AnsiString;        
{$ENDIF}

type
  TZMStates = (zsDisabled, zsIdle, zsBusy);

  // options when editing a zip
  TZMAddOptsEnum = (AddDirNames, AddRecurseDirs, AddMove, AddFreshen, AddUpdate,
    AddHiddenFiles, AddArchiveOnly, AddResetArchive, AddEncrypt, AddEmptyDirs,
//    AddNoSeparateDirs, renamed and inverted - was AddSeparateDirs
    AddVolume, AddFromDate, AddSafe, AddVersion, AddNTFS);
  TZMAddOpts     = set of TZMAddOptsEnum;

  //the EncodeAs values (writing) -
  // zeoUPATH - convert to Ansi but have UTF8 proper name in data
  // zeoUTF  - convert to UTF8
  // zeoOEM  - convert to OEM
  // zeoNone - store 'as is' (Ansi on Windows)
  // 'default' (zeoAuto) - [in order of preference]
  //      is Ansi - use zeoNone
  //      can be converted to Ansi - use zeoUPath (unless comment also extended)
  //      use zeoUTF8

  //Encoded (reading)
  // zeoUPATH- use UPATH if available
  // zeoUTF  - assume name is UTF8 - convert to Ansi/Unicode
  // zeoOEM  - assume name is OEM - convert to Ansi/Unicode
  // zeoNone - assume name is Ansi - convert to Ansi/Unicode
  // zeoAuto - unless flags/versions say otherwise, or it has UTF8 name in data,
  //             treat it as OEM (FAT) / Ansi (NTFS)
  TZMEncodingOpts = (zeoAuto, zeoNone, zeoOEM, zeoUTF8, zeoUPath);

  // When changing this enum also change the pointer array in the function AddSuffix,
  // and the initialisation of ZipMaster.
  TZMAddStoreSuffixEnum = (assGIF, assPNG, assZ, assZIP, assZOO, assARC,
    assLZH, assARJ, assTAZ, assTGZ, assLHA, assRAR,
    assACE, assCAB, assGZ, assGZIP, assJAR, assEXE, assEXT,
    assJPG, assJPEG, ass7Zp, assMP3, assWMV, assWMA, assDVR, assAVI);

  TZMAddStoreExts = set of TZMAddStoreSuffixEnum;

  TZMSpanOptsEnum = (spNoVolumeName, spCompatName, spWipeFiles,
    spTryFormat, spAnyTime, spExactName);
  TZMSpanOpts     = set of TZMSpanOptsEnum;

  // options for when reading a zip file
  TZMExtrOptsEnum = (ExtrDirNames, ExtrOverWrite, ExtrFreshen, ExtrUpdate,
    ExtrTest, ExtrForceDirs, ExtrNTFS);
  TZMExtrOpts     = set of TZMExtrOptsEnum;

  // options for when writing a zip file
  TZMWriteOptsEnum = (zwoDiskSpan, zwoZipTime, zwoForceDest);
  TZMWriteOpts = set of TZMWriteOptsEnum;

  // other options
  TZMMergeOpts = (zmoConfirm, zmoAlways, zmoNewer, zmoOlder, zmoNever);
  TZMOvrOpts   = (ovrAlways, ovrNever, ovrConfirm);

  TZMReplaceOpts = (rplConfirm, rplAlways, rplNewer, rplNever);

  TZMDeleteOpts = (htdFinal, htdAllowUndo);

  TZMRenameOpts = (htrDefault, htrOnce, htrFull);

  TZMSkipTypes = (stOnFreshen, stNoOverwrite, stFileExists, stBadPassword,
    stBadName, stCompressionUnknown, stUnknownZipHost, stZipFileFormatWrong,
    stGeneralExtractError, stUser, stCannotDo, stNotFound,
    // opening files  (Zip)
    stNoShare, stNoAccess, stNoOpen, stDupName, stReadError, stSizeChange
    );
  TZMSkipAborts = set of TZMSkipTypes;

  TZMZipDiskStatusEnum = (zdsEmpty, zdsHasFiles, zdsPreviousDisk, zdsSameFileName,
    zdsNotEnoughSpace);
  TZMZipDiskStatus     = set of TZMZipDiskStatusEnum;
  TZMDiskAction        = (zdaYesToAll, zdaOk, zdaErase, zdaReject, zdaCancel);

  TZMDeflates = (zmStore, zmStoreEncrypt, zmDeflate, zmDeflateEncrypt);

type
  TZMSFXOpt = (
    soAskCmdLine,     // allow user to prevent execution of the command line
    soAskFiles,       // allow user to prevent certain files from extraction
    soHideOverWriteBox, // do not allow user to choose the overwrite mode
    soAutoRun,        // start extraction + evtl. command line automatically
    //                  only if sfx filename starts with "!" or is "setup.exe"
    soNoSuccessMsg,   // don't show success message after extraction
    soExpandVariables, // expand environment variables in path/cmd line...
    soInitiallyHideFiles, // dont show file listview on startup
    soForceHideFiles, // do not allow user to show files list
    //                (no effect if shfInitiallyShowFiles is set)
    soCheckAutoRunFileName, // can only autorun if !... or setup.exe
    soCanBeCancelled, // extraction can be cancelled
    soCreateEmptyDirs, // recreate empty directories
    soSuccessAlways   // always give success message even if soAutoRun or soNoSuccessMsg
    );

  // set of TSFXOption
  TZMSFXOpts = set of TZMSFXOpt;

type
  TZMProgressType = (NewFile, ProgressUpdate, EndOfBatch, TotalFiles2Process,
    TotalSize2Process, NewExtra, ExtraUpdate);

type
  TZMProgressDetails = class(TObject)
  protected
    function GetBytesWritten: Int64; virtual; abstract;
    function GetDelta: Int64; virtual; abstract;
    function GetItemName: TZMString; virtual; abstract;
    function GetItemNumber: Integer; virtual; abstract;
    function GetItemPerCent: Integer;
    function GetItemPosition: Int64; virtual; abstract;
    function GetItemSize: Int64; virtual; abstract;
    function GetOrder: TZMProgressType; virtual; abstract;
    function GetTotalCount: Int64; virtual; abstract;
    function GetTotalPerCent: Integer;
    function GetTotalPosition: Int64; virtual; abstract;
    function GetTotalSize: Int64; virtual; abstract;
  public
    property BytesWritten: Int64 read GetBytesWritten;
    property Delta: Int64 read GetDelta;
    property ItemName: TZMString read GetItemName;
    property ItemNumber: Integer read GetItemNumber;
    property ItemPerCent: Integer Read GetItemPerCent;
    property ItemPosition: Int64 read GetItemPosition;
    property ItemSize: Int64 read GetItemSize;
    property Order: TZMProgressType read GetOrder;
    property TotalCount: Int64 read GetTotalCount;
    property TotalPerCent: Integer Read GetTotalPerCent;
    property TotalPosition: Int64 read GetTotalPosition;
    property TotalSize: Int64 read GetTotalSize;
  end;

// ZipDirEntry status bit constants
const
  zsbDirty    = $1;
  zsbSelected = $2;
  zsbSkipped  = $4;
  zsbIgnore   = $8;
  zsbDirOnly  = $10;
  zsbInvalid  = $20;
  zsbError    = $40;  // processing error

const
  DefNoSkips{: TZMSkipAborts} = [stDupName, stReadError];
  ZMInitialCRC = $FFFFFFFF;

type
  // abstract class representing a zip central record
  TZMDirEntry = class
  private
    function GetIsDirOnly: boolean;
  protected
    function GetCompressedSize: Int64; virtual; abstract;
    function GetCompressionMethod: Word; virtual; abstract;
    function GetCRC32: Cardinal; virtual; abstract;
    function GetDateStamp: TDateTime;
    function GetDateTime: Cardinal; virtual; abstract;
    function GetEncoded: TZMEncodingOpts; virtual; abstract;
    function GetEncrypted: Boolean; virtual; abstract;
    function GetExtFileAttrib: Longword; virtual; abstract;
    function GetExtraData(Tag: Word): TZMRawBytes; virtual;
    function GetExtraField: TZMRawBytes; virtual; abstract;
    function GetExtraFieldLength: Word; virtual; abstract;
    function GetFileComment: TZMString; virtual; abstract;
    function GetFileCommentLen: Word; virtual; abstract;
    function GetFileName: TZMString; virtual; abstract;
    function GetFileNameLength: Word; virtual; abstract;
    function GetFlag: Word; virtual; abstract;
    function GetHeaderName: TZMRawBytes; virtual; abstract;
    function GetIntFileAttrib: Word; virtual; abstract;
    function GetRelOffLocalHdr: Int64; virtual; abstract;
    function GetStartOnDisk: Word; virtual; abstract;
    function GetStatusBits: Cardinal; virtual; abstract;
    function GetUncompressedSize: Int64; virtual; abstract;
    function GetVersionMadeBy: Word; virtual; abstract;
    function GetVersionNeeded: Word; virtual; abstract;
    function XData(const x: TZMRawBytes; Tag: Word; var idx, size: Integer):
        Boolean;
  public
    property CompressedSize: Int64 Read GetCompressedSize;
    property CompressionMethod: Word Read GetCompressionMethod;
    property CRC32: Cardinal Read GetCRC32;
    property DateStamp: TDateTime Read GetDateStamp;
    property DateTime: Cardinal Read GetDateTime;
    property Encoded: TZMEncodingOpts Read GetEncoded;
    property Encrypted: Boolean Read GetEncrypted;
    property ExtFileAttrib: Longword Read GetExtFileAttrib;
    property ExtraData[Tag: Word]: TZMRawBytes read GetExtraData;
    property ExtraField: TZMRawBytes read GetExtraField;
    property ExtraFieldLength: Word Read GetExtraFieldLength;
    property FileComment: TZMString Read GetFileComment;
    property FileCommentLen: Word Read GetFileCommentLen;
    property FileName: TZMString Read GetFileName;
    property FileNameLength: Word Read GetFileNameLength;
    property Flag: Word Read GetFlag;
    property HeaderName: TZMRawBytes Read GetHeaderName;
    property IntFileAttrib: Word Read GetIntFileAttrib;
    property IsDirOnly: boolean read GetIsDirOnly;
    property RelOffLocalHdr: Int64 Read GetRelOffLocalHdr;
    property StartOnDisk: Word Read GetStartOnDisk;
    property StatusBits: Cardinal Read GetStatusBits;
    property UncompressedSize: Int64 Read GetUncompressedSize;
    property VersionMadeBy: Word read GetVersionMadeBy;
    property VersionNeeded: Word Read GetVersionNeeded;
  end;

  TZMDirRec = class(TZMDirEntry)
  public
    function ChangeAttrs(nAttr: Cardinal): Integer; virtual; abstract;
    function ChangeComment(const ncomment: TZMString): Integer; virtual; abstract;
    function ChangeData(ndata: TZMRawBytes): Integer; virtual; abstract;
    function ChangeDate(ndosdate: Cardinal): Integer; virtual; abstract;
    function ChangeEncoding: Integer; virtual; abstract;
    function ChangeName(const nname: TZMString): Integer; virtual; abstract;
    function ChangeStamp(ndate: TDateTime): Integer;
  end;

type
  TZMForEachFunction = function(rec: TZMDirEntry; var Data): Integer;
  TZMChangeFunction = function(rec: TZMDirRec; var Data): Integer;

type
  TZMRenameRec = record
    Source: String;
    Dest: String;
    Comment: String;
    DateTime: Integer;
  end;
  PZMRenameRec = ^TZMRenameRec;

// structure used to 'identify' streams
type
  TZMSStats = packed record
    Size:  Int64;
    Date:  Cardinal;
    Attrs: Cardinal;
  end;
  PZMSStats = ^TZMSStats;

type
  TZMStreamOp = (zsoIdentify, zsoOpen, zsoClose);

type
  TZMCheckTerminateEvent = procedure(Sender: TObject; var abort: Boolean) of object;
  TZMCopyZippedOverwriteEvent = procedure(Sender: TObject;
    src, dst: TZMDirEntry; var DoOverwrite: Boolean) of object;
  TZMCRC32ErrorEvent = procedure(Sender: TObject; const ForFile: TZMString;
    FoundCRC, ExpectedCRC: Longword; var DoExtract: Boolean) of object;
  TZMExtractOverwriteEvent = procedure(Sender: TObject; const ForFile: TZMString;
    IsOlder: Boolean; var DoOverwrite: Boolean; DirIndex: Integer) of object;
  TZMSkippedEvent = procedure(Sender: TObject; const ForFile: TZMString;
    SkipType: TZMSkipTypes; var ExtError: Integer) of object;
  TZMFileCommentEvent = procedure(Sender: TObject; const ForFile: TZMString;
    var FileComment: TZMString; var IsChanged: Boolean) of object;
  TZMFileExtraEvent = procedure(Sender: TObject; const ForFile: TZMString;
    var Data: TZMRawBytes; var IsChanged: Boolean) of object;
  TZMGetNextDiskEvent = procedure(Sender: TObject; DiskSeqNo, DiskTotal: Integer;
    Drive: String; var AbortAction: Boolean) of object;
  TZMLoadStrEvent = procedure(Ident: Integer; var DefStr: String) of object;
  TZMMessageEvent = procedure(Sender: TObject; ErrCode: Integer;
    const ErrMsg: TZMString) of object;
  // new signiture
  TZMNewNameEvent = procedure(Sender: TObject; SeqNo: Integer) of object;
  TZMPasswordErrorEvent = procedure(Sender: TObject; IsZipAction: Boolean;
    var NewPassword: String; const ForFile: TZMString; var RepeatCount: Longword;
    var Action: TMsgDlgBtn) of object;
  TZMProgressEvent = procedure(Sender: TObject; details: TZMProgressDetails) of object;
  TZMSetAddNameEvent = procedure(Sender: TObject; var FileName: TZMString;
    const ExtName: TZMString; var IsChanged: Boolean) of object;
  TZMSetExtNameEvent = procedure(Sender: TObject; var FileName: TZMString;
    const BaseDir: TZMString; var IsChanged: Boolean) of object;
  TZMStatusDiskEvent = procedure(Sender: TObject; PreviousDisk: Integer;
    PreviousFile: String; Status: TZMZipDiskStatus;
    var Action: TZMDiskAction) of object;
  TZMTickEvent   = procedure(Sender: TObject) of object;
  TZMDialogEvent = procedure(Sender: TObject; const title: String;
    var msg: String; var Result: Integer; btns: TMsgDlgButtons) of object;
  TZMSetCompLevel = procedure(Sender: TObject; const ForFile: TZMString;
    var level: Integer; var IsChanged: Boolean) of object;
  TZMStreamEvent = procedure(Sender: TObject; opr: TZMStreamOp; snumber: integer;
    var strm: TStream; var stat: TZMSStats; var done: Boolean) of object;
  TZMStateChange = procedure(Sender: TObject; state: TZMStates;
        var NoCursor: boolean) of object;

type
  TZMPipe = class
  protected
    function GetAttributes: Cardinal; virtual; abstract;
    function GetDOSDate: Cardinal; virtual; abstract;
    function GetFileName: string; virtual; abstract;
    function GetOwnsStream: boolean; virtual; abstract;
    function GetSize: Integer; virtual; abstract;
    function GetStream: TStream; virtual; abstract;
    procedure SetAttributes(const Value: Cardinal); virtual; abstract;
    procedure SetDOSDate(const Value: Cardinal); virtual; abstract;
    procedure SetFileName(const Value: string); virtual; abstract;
    procedure SetOwnsStream(const Value: boolean); virtual; abstract;
    procedure SetSize(const Value: Integer); virtual; abstract;
    procedure SetStream(const Value: TStream); virtual; abstract;
  public
    property Attributes: Cardinal read GetAttributes write SetAttributes;
    property DOSDate: Cardinal read GetDOSDate write SetDOSDate;
    property FileName: string read GetFileName write SetFileName;
    property OwnsStream: boolean read GetOwnsStream write SetOwnsStream;
    property Size: Integer read GetSize write SetSize;
    property Stream: TStream read GetStream write SetStream;
  end;

  TZMPipeList = class
  protected
    function GetCount: Integer; virtual; abstract;
    function GetPipe(Index: Integer): TZMPipe; virtual; abstract;
    procedure SetCount(const Value: Integer); virtual; abstract;
    procedure SetPipe(Index: Integer; const Value: TZMPipe); virtual; abstract;
  public
    function Add(aStream: TStream; const FileName: string; Own: boolean): integer;
        virtual; abstract;
    procedure Clear; virtual; abstract;
    property Count: Integer read GetCount write SetCount;
    property Pipe[Index: Integer]: TZMPipe read GetPipe write SetPipe; default;
  end;

type
{$IFDEF VERD2005up}
  TCustomZipMaster19 = class;
  TZipMasterEnumerator = class
    private
      FIndex: Integer;
      FOwner: TCustomZipMaster19;
    public
      constructor Create(AMaster: TCustomZipMaster19);
      function GetCurrent: TZMDirEntry;
      function MoveNext: Boolean;
      property Current: TZMDirEntry read GetCurrent;
  end;
{$ENDIF}

  // the main component
  TCustomZipMaster19 = class(TComponent)
  private
    { Private versions of property variables }
    BusyFlag:      Integer;
    fActive:       Integer;
    fAddCompLevel: Integer;
    fAddStoreSuffixes: TZMAddStoreExts;
    fConfirmErase: Boolean;
    FCurWaitCount: Integer;
    fDelaying:     Integer;
    fDLLDirectory: String;
    fDLLLoad:      Boolean;
    FEncodeAs: TZMEncodingOpts;
    fEncoding:     TZMEncodingOpts;
    fEncoding_CP:  Cardinal;
    fEncrypt:      Boolean;
    fExtAddStoreSuffixes: String;
    fExtrBaseDir:  String;
    fExtrOptions:  TZMExtrOpts;
    fFreeOnAllDisks: Cardinal;
    fFreeOnDisk1:  Cardinal;
    fFromDate:     TDateTime;
    FFSpecArgs: TStrings;
    fFSpecArgsExcl: TStrings;
    fHandle:       HWND;
    fHowToDelete:  TZMDeleteOpts;
    FLanguage: String;
    fMaxVolumeSize: Integer;
    FMaxVolumeSizeKb: Integer;
    fMinFreeVolSize: Integer;
    FNoReadAux: Boolean;
    FNoSkipping: TZMSkipAborts;
    fNotMainThread: Boolean;
    fOnCheckTerminate: TZMCheckTerminateEvent;
    fOnCopyZippedOverwrite: TZMCopyZippedOverwriteEvent;
    fOnCRC32Error: TZMCRC32ErrorEvent;
    fOnDirUpdate:  TNotifyEvent;
    fOnExtractOverwrite: TZMExtractOverwriteEvent;
    FOnSkipped: TZMSkippedEvent;
    fOnFileComment: TZMFileCommentEvent;
    fOnFileExtra:  TZMFileExtraEvent;
    fOnGetNextDisk: TZMGetNextDiskEvent;
    fOnMessage:    TZMMessageEvent;
    fOnNewName:    TZMNewNameEvent;
    fOnPasswordError: TZMPasswordErrorEvent;
    fOnProgress: TZMProgressEvent;
    fOnSetAddName: TZMSetAddNameEvent;
    fOnSetCompLevel: TZMSetCompLevel;
    fOnSetExtName: TZMSetExtNameEvent;
    fOnStateChange: TZMStateChange;
    fOnStatusDisk: TZMStatusDiskEvent;
    fOnStream:     TZMStreamEvent;
    fOnTick:       TZMTickEvent;
    fOnZipDialog:  TZMDialogEvent;
    FPassword: String;
    fPasswordReqCount: Longword;
    FPipes: TZMPipeList;
    fReentry:      Boolean;
    FSFXRegFailPath: String;
    fRootDir:      String;
    FSaveCursor: TCursor;
    FSFXCaption: TZMString;
    FSFXCommandLine: TZMString;
    FSFXDefaultDir: String;
    FSFXMessage: TZMString;
    FSFXOptions: TZMSFXOpts;
    FSFXOverwriteMode: TZMOvrOpts;
    FSFXPath: String;
    FSpanOptions: TZMSpanOpts;
    fTempDir:      String;
    fTrace:        Boolean;
    fUnattended:   Boolean;
    fUseDelphiBin: Boolean;
    FUseDirOnlyEntries: Boolean;
{$IFNDEF UNICODE}
    FUseUTF8: Boolean;
{$ENDIF}
    fVerbose:      Boolean;
    FWriteOptions: TZMWriteOpts;
//    fWorker:       TObject;
    FZipComment:   AnsiString;
    fZipFileName:  String;
    procedure AuxWasChanged;
    function GetActive: Boolean;
    function GetBuild: Integer;
    { Property get/set functions }
    function GetBusy: Boolean;
    function GetCancel: Boolean;
    function GetCount: Integer;
    function GetDirEntry(idx: Integer): TZMDirEntry;
    function GetDirOnlyCnt: Integer;
    function GetDLL_Build: Integer;
    function GetDLL_Load: Boolean;
    function GetDLL_Path: String;
    function GetDLL_Version: String;
    function GetDLL_Version1(load: boolean): String;
    function GetErrCode: Integer;
    function GetErrMessage: TZMString;
    function GetDllErrCode: Integer;
    function GetIsSpanned: Boolean;
    function GetLanguage: string;
    class function GetLanguageInfo(Idx: Integer; info: Cardinal): String;
    function GetNoReadAux: Boolean;
    function GetOnLoadStr: TZMLoadStrEvent;
    function GetSFXOffset: Integer;
    function GetSuccessCnt: Integer;
    function GetTotalSizeToProcess: Int64;
    function GetVersion: String;
    function GetZipComment: String;
    function GetZipEOC: Int64;
    function GetZipFileSize: Int64;
    function GetZipSOC: Int64;
    function GetZipStream: TMemoryStream;
    procedure SetActive(Value: Boolean);
    procedure SetCancel(Value: Boolean);
    procedure SetDLL_Load(const Value: Boolean);
    procedure SetEncodeAs(const Value: TZMEncodingOpts);
    procedure SetEncoding(const Value: TZMEncodingOpts);
    procedure SetEncoding_CP(Value: Cardinal);
    procedure SetErrCode(Value: Integer);
    procedure SetFSpecArgs(const Value: TStrings);
    procedure SetFSpecArgsExcl(const Value: TStrings);
    procedure SetLanguage(const Value: string);
    procedure SetNoReadAux(const Value: Boolean);
    procedure SetOnLoadStr(const Value: TZMLoadStrEvent);
    procedure SetPassword(const Value: String);
    procedure SetPasswordReqCount(Value: Longword);
    procedure SetPipes(const Value: TZMPipeList);
    procedure SetSFXCaption(const Value: TZMString);
    procedure SetSFXCommandLine(const Value: TZMString);
    procedure SetSFXDefaultDir(const Value: String);
    procedure SetSFXIcon(Value: TIcon);
    procedure SetSFXMessage(const Value: TZMString);
    procedure SetSFXOptions(const Value: TZMSFXOpts);
    procedure SetSFXOverwriteMode(const Value: TZMOvrOpts);
    procedure SetSFXRegFailPath(const Value: String);
    procedure SetSpanOptions(const Value: TZMSpanOpts);
    procedure SetUseDirOnlyEntries(const Value: Boolean);
{$IFNDEF UNICODE}
    procedure SetUseUTF8(const Value: Boolean);
{$ENDIF}
    procedure SetVersion(const Value: String);
    procedure SetWriteOptions(const Value: TZMWriteOpts);
    procedure SetZipComment(const Value: String);
    procedure SetZipFileName(const Value: String);
  protected
    FAddOptions: TZMAddOpts;
    FAuxChanged: Boolean;
    fSFXIcon:    TIcon;
    fWorker:     TObject;
    function CanStart: Boolean;
    procedure DoDelays;
    procedure Done(Good: Boolean = True);
    procedure DoneBad(E: Exception);
    function IsActive: boolean;
    procedure Loaded; override;
    function Permitted: Boolean;
    procedure ReEntered;
    procedure Start;
    procedure StartNoDll;
    procedure StartWaitCursor;
    procedure StateChanged(newState: TZMStates);
    function Stopped: Boolean;
    procedure StopWaitCursor;
  public
    procedure AbortDLL;
    function Add: Integer;
    function AddStreamToFile(const FileName: String;
      FileDate, FileAttr: Dword): Integer;
    function AddStreamToStream(InStream: TMemoryStream): TMemoryStream;
    function AddZippedFiles(SrcZipMaster: TCustomZipMaster19;
      merge: TZMMergeOpts): Integer;
    procedure AfterConstruction; override;
    function AppendSlash(const sDir: String): String;
    procedure BeforeDestruction; override;
    function ChangeFileDetails(func: TZMChangeFunction; var Data): Integer;
    procedure Clear;
    function ConvertToSFX: Integer;
    function ConvertToSpanSFX(const OutFile: String): Integer;
    function ConvertToZIP: Integer;
    function CopyZippedFiles(DestZipMaster: TCustomZipMaster19; DeleteFromSource:
        Boolean; OverwriteDest: TZMMergeOpts): Integer; overload;
    function Copy_File(const InFileName, OutFileName: String): Integer;
    function Deflate(OutStream, InStream: TStream; Length: Int64; var Method:
        TZMDeflates; var CRC: Cardinal): Integer;
    function Delete: Integer;
    function EraseFile(const FName: String; How: TZMDeleteOpts): Integer;
    function Extract: Integer;
    function ExtractFileToStream(const FileName: String): TMemoryStream;
    function ExtractStreamToStream(InStream: TMemoryStream; OutSize: Longword):
        TMemoryStream;
    function Find(const fspec: TZMString; var idx: Integer): TZMDirEntry;
    function ForEach(func: TZMForEachFunction; var Data): Integer;
    function FullVersionString: String;
    function GetAddPassword: String; overload;
    function GetAddPassword(var Response: TmsgDlgBtn): String; overload;
{$IFDEF VERD2005up}
    function GetEnumerator: TZipMasterEnumerator;
{$ENDIF}
    function GetExtrPassword: String; overload;
    function GetExtrPassword(var Response: TmsgDlgBtn): String; overload;
    function GetPassword(const DialogCaption, MsgTxt: String;
      pwb: TmsgDlgButtons; var ResultStr: String): TmsgDlgBtn;
    function IndexOf(const FName: TZMString): Integer;
    function IsZipSFX(const SFXExeName: String): Integer;
    function List: Integer;
    function MakeTempFileName(const Prefix, Extension: String): String;
    function QueryZip(const FName: TFileName): Integer;
    function ReadSpan(const InFileName: String; var OutFilePath: String): Integer;
    function Rename(RenameList: TList; DateTime: Integer; How: TZMRenameOpts =
        htrDefault): Integer;
    procedure ShowExceptionError(const ZMExcept: EZMException);
    procedure ShowZipFmtMessage(Id: Integer; const Args: array of const);
    procedure ShowZipMessage(Ident: Integer; const UserStr: String);
    function TheErrorCode(errCode: Integer): Integer;
    function Undeflate(OutStream, InStream: TStream; Length: Int64; var Method:
        TZMDeflates; var CRC: Cardinal): Integer;
    function WriteSpan(const InFileName, OutFileName: String): Integer;
    function ZipLoadStr(Id: Integer): string;
    //  published
    property Active: Boolean Read GetActive Write SetActive default True;
    property AddCompLevel: Integer Read fAddCompLevel Write fAddCompLevel default 9;
    property AddFrom: TDateTime Read fFromDate Write fFromDate;
    property AddOptions: TZMAddOpts read FAddOptions write FAddOptions;
    property AddStoreSuffixes: TZMAddStoreExts
      Read fAddStoreSuffixes Write fAddStoreSuffixes;
    property Build: Integer Read GetBuild;
    property Busy: Boolean Read GetBusy;
    property Cancel: Boolean Read GetCancel Write SetCancel;
    property ConfirmErase: Boolean Read fConfirmErase Write fConfirmErase default True;
    property Count: Integer Read GetCount;
    property DirEntry[idx: Integer]: TZMDirEntry Read GetDirEntry; default;
    property DirOnlyCnt: Integer Read GetDirOnlyCnt;
    property DLLDirectory: String Read fDLLDirectory Write fDLLDirectory;
    property DLL_Build: Integer Read GetDLL_Build;
    property DLL_Load: Boolean Read GetDLL_Load Write SetDLL_Load;
    property DLL_Path: String Read GetDLL_Path;
    property DLL_Version: String Read GetDLL_Version;
    property EncodeAs: TZMEncodingOpts read FEncodeAs write SetEncodeAs;
    //1 Filename and comment character encoding
    property Encoding: TZMEncodingOpts Read fEncoding Write SetEncoding default zeoAuto;
    //1 codepage to use to decode filename
    property Encoding_CP: Cardinal Read fEncoding_CP Write SetEncoding_CP;
    property ErrCode: Integer Read GetErrCode Write SetErrCode;
    property ErrMessage: TZMString Read GetErrMessage;
    property ExtAddStoreSuffixes: String Read fExtAddStoreSuffixes
      Write fExtAddStoreSuffixes;
    property ExtrBaseDir: String Read fExtrBaseDir Write fExtrBaseDir;
    property ExtrOptions: TZMExtrOpts Read fExtrOptions Write fExtrOptions;
    property FSpecArgs: TStrings read FFSpecArgs write SetFSpecArgs;
    property FSpecArgsExcl: TStrings Read fFSpecArgsExcl Write SetFSpecArgsExcl;
    property DllErrCode: Integer read GetDllErrCode;
    property Handle: HWND Read fHandle Write fHandle;
    property HowToDelete: TZMDeleteOpts
      Read fHowToDelete Write fHowToDelete default htdAllowUndo;
    property IsSpanned: Boolean Read GetIsSpanned;
    property KeepFreeOnAllDisks: Cardinal Read fFreeOnAllDisks Write fFreeOnAllDisks;
    property KeepFreeOnDisk1: Cardinal Read fFreeOnDisk1 Write fFreeOnDisk1;
    property Language: string read GetLanguage write SetLanguage;
    property LanguageInfo[Idx: Integer; info: Cardinal]: String Read GetLanguageInfo;
    property MaxVolumeSize: Integer Read fMaxVolumeSize Write fMaxVolumeSize;
    property MaxVolumeSizeKb: Integer read FMaxVolumeSizeKb write FMaxVolumeSizeKb;
    property MinFreeVolumeSize: Integer Read fMinFreeVolSize
      Write fMinFreeVolSize default 65536;
    property NoReadAux: Boolean read GetNoReadAux write SetNoReadAux;
    property NoSkipping: TZMSkipAborts read FNoSkipping write FNoSkipping default
        DefNoSkips;
    property NotMainThread: Boolean Read fNotMainThread Write fNotMainThread;
    property Password: String read FPassword write SetPassword;
    property PasswordReqCount: Longword Read fPasswordReqCount
      Write SetPasswordReqCount default 1;
    property Pipes: TZMPipeList read FPipes write SetPipes;
    property RootDir: String Read fRootDir Write fRootDir;
    property SFXCaption: TZMString read FSFXCaption write SetSFXCaption;
    property SFXCommandLine: TZMString read FSFXCommandLine write SetSFXCommandLine;
    property SFXDefaultDir: String read FSFXDefaultDir write SetSFXDefaultDir;
    property SFXIcon: TIcon Read fSFXIcon Write SetSFXIcon;
    property SFXMessage: TZMString read FSFXMessage write SetSFXMessage;
    property SFXOffset: Integer Read GetSFXOffset;
    property SFXOptions: TZMSFXOpts read FSFXOptions write SetSFXOptions;
    property SFXOverwriteMode: TZMOvrOpts read FSFXOverwriteMode write
        SetSFXOverwriteMode default ovrConfirm;
    property SFXPath: String read FSFXPath write FSFXPath;
    property SFXRegFailPath: String read FSFXRegFailPath write SetSFXRegFailPath;
    property SpanOptions: TZMSpanOpts read FSpanOptions write SetSpanOptions;
    property SuccessCnt: Integer Read GetSuccessCnt;
    property TempDir: String Read fTempDir Write fTempDir;
    property TotalSizeToProcess: Int64 Read GetTotalSizeToProcess;
    property Trace: Boolean Read fTrace Write fTrace;
    property Unattended: Boolean Read fUnattended Write fUnattended;
    property UseDirOnlyEntries: Boolean read FUseDirOnlyEntries write
        SetUseDirOnlyEntries default False;
{$IFNDEF UNICODE}
    property UseUTF8: Boolean read FUseUTF8 write SetUseUTF8;
{$ENDIF}
    property Verbose: Boolean Read fVerbose Write fVerbose;
    property Version: String Read GetVersion Write SetVersion;
    property WriteOptions: TZMWriteOpts read FWriteOptions write SetWriteOptions;
    property ZipComment: String read GetZipComment write SetZipComment;
    property ZipEOC: Int64 Read GetZipEOC;
    property ZipFileName: String Read fZipFileName Write SetZipFileName;
    property ZipFileSize: Int64 Read GetZipFileSize;
    property ZipSOC: Int64 Read GetZipSOC;
    property ZipStream: TMemoryStream read GetZipStream;
    { Events }
    property OnCheckTerminate: TZMCheckTerminateEvent
      Read fOnCheckTerminate Write fOnCheckTerminate;
    property OnCopyZippedOverwrite: TZMCopyZippedOverwriteEvent
      Read fOnCopyZippedOverwrite Write fOnCopyZippedOverwrite;
    property OnCRC32Error: TZMCRC32ErrorEvent Read fOnCRC32Error Write fOnCRC32Error;
    property OnDirUpdate: TNotifyEvent Read fOnDirUpdate Write fOnDirUpdate;
    property OnExtractOverwrite: TZMExtractOverwriteEvent
      Read fOnExtractOverwrite Write fOnExtractOverwrite;
    property OnFileComment: TZMFileCommentEvent
      Read fOnFileComment Write fOnFileComment;
    property OnFileExtra: TZMFileExtraEvent Read fOnFileExtra Write fOnFileExtra;
    property OnGetNextDisk: TZMGetNextDiskEvent
      Read fOnGetNextDisk Write fOnGetNextDisk;
    property OnLoadStr: TZMLoadStrEvent read GetOnLoadStr write SetOnLoadStr;
    property OnMessage: TZMMessageEvent Read fOnMessage Write fOnMessage;
    property OnNewName: TZMNewNameEvent Read fOnNewName Write fOnNewName;
    property OnPasswordError: TZMPasswordErrorEvent
      Read fOnPasswordError Write fOnPasswordError;
    property OnProgress: TZMProgressEvent Read fOnProgress Write fOnProgress;
    property OnSetAddName: TZMSetAddNameEvent Read fOnSetAddName Write fOnSetAddName;
    property OnSetCompLevel: TZMSetCompLevel Read fOnSetCompLevel Write fOnSetCompLevel;
    property OnSetExtName: TZMSetExtNameEvent Read fOnSetExtName Write fOnSetExtName;
    property OnSkipped: TZMSkippedEvent read FOnSkipped write FOnSkipped;
    property OnStateChange: TZMStateChange Read fOnStateChange Write fOnStateChange;
    property OnStatusDisk: TZMStatusDiskEvent Read fOnStatusDisk Write fOnStatusDisk;
    property OnStream: TZMStreamEvent Read fOnStream Write fOnStream;
    property OnTick: TZMTickEvent Read fOnTick Write fOnTick;
    property OnZipDialog: TZMDialogEvent Read fOnZipDialog Write fOnZipDialog;
  end;

  TZipMaster19 = class(TCustomZipMaster19)
  published
    property Active default True;
    property AddCompLevel default 9;
    property AddFrom;
    property AddOptions;
    property AddStoreSuffixes;
    property ConfirmErase default True;
    property DLLDirectory;
    property DLL_Load;
    //1 Filename and comment character encoding
    property Encoding default zeoAuto;
    property ExtAddStoreSuffixes;
    property ExtrBaseDir;
    property ExtrOptions;
    property FSpecArgs;
    property FSpecArgsExcl;
    property HowToDelete;
    property KeepFreeOnAllDisks;
    property KeepFreeOnDisk1;
    property Language;
    property MaxVolumeSize;
    property MaxVolumeSizeKb;
    property MinFreeVolumeSize default 65536;
    property NoReadAux;
    property NoSkipping default DefNoSkips;
    { Events }
    property OnCheckTerminate;
    property OnCopyZippedOverwrite;
    property OnCRC32Error;
    property OnDirUpdate;
    property OnExtractOverwrite;
    property OnFileComment;
    property OnFileExtra;
    property OnGetNextDisk;
    property OnLoadStr;
    property OnMessage;
    property OnNewName;
    property OnPasswordError;
    property OnProgress;
    property OnSetAddName;
    property OnSetCompLevel;
    property OnSetExtName;
    property OnSkipped;
    property OnStatusDisk;
    property OnStream;
    property OnTick;
    property OnZipDialog;
    property Password;
    property PasswordReqCount default 1;
    // SFX
    property RootDir;
    property SFXCaption;
    property SFXCommandLine;
    property SFXDefaultDir;
    property SFXIcon;
    property SFXMessage;
    property SFXOptions;
    property SFXOverwriteMode;
    property SFXPath;
    property SFXRegFailPath;
    property SpanOptions;
    property TempDir;
    property Trace;
    property Unattended;
    property UseDirOnlyEntries;
{$IFNDEF UNICODE}
    property UseUTF8;
{$ENDIF}
    property Verbose;
    property Version;
    property WriteOptions;
    property ZipComment;
    property ZipFileName;
  end;

// default file extensions that are best 'stored'
const
  ZMDefAddStoreSuffixes = [assGIF..assJAR, assJPG..ass7Zp, assMP3..assAVI];

// Configuration options - rebuild if changed
//__ USE_COMPRESSED_STRINGS - undefine to use ResourceStrings
{$Define USE_COMPRESSED_STRINGS}

//__ STATIC_LOAD_DELZIP_DLL - define to statically load dll
//{$DEFINE STATIC_LOAD_DELZIP_DLL}

//__ SINGLE_ZIPMASTER_VERSION - define if no other version is installed
//{$DEFINE SINGLE_ZIPMASTER_VERSION}

{$IFDEF SINGLE_ZIPMASTER_VERSION}
type
  TZipMaster = TZipMaster19;
{$ENDIF}

procedure Register;

implementation

uses
  Forms,
  ZMCompat19, ZMUtils19, ZMCore19, ZMWrkr19, ZMMsg19, ZMDLLOpr19, ZMMatch19, ZMMsgStr19,
  ZMUTF819;

{$R ZipMstr19.Res ZipMstr19.rc}
{$R 'res\zmres19_str.res'}

const
  DelayingLanguage = 1;
  DelayingFileName = 2;
  DelayingComment = 4;
  DelayingDLL = 8;

procedure Register;
begin
{$IFDEF SINGLE_ZIPMASTER_VERSION}
  RegisterComponents('DelphiZip', [TZipMaster]);
{$ELSE}
  RegisterComponents('DelphiZip 19', [TZipMaster19]);
{$ENDIF}
end;

{TZMProgressDetails}
function TZMProgressDetails.GetItemPerCent: Integer;
begin
  if (ItemSize > 0) and (ItemPosition > 0) then
    Result := (100 * ItemPosition) div ItemSize
  else
    Result := 0;
end;

function TZMProgressDetails.GetTotalPerCent: Integer;
begin
  if (TotalSize > 0) and (TotalPosition > 0) then
    Result := (100 * TotalPosition) div TotalSize
  else
    Result := 0;
end;

{TZMDirEntry}
function TZMDirEntry.GetDateStamp: TDateTime;
begin
  Result := FileDateToLocalDateTime(GetDateTime);
end;

// return first data for Tag
function TZMDirEntry.GetExtraData(Tag: Word): TZMRawBytes;
var
  i: Integer;
  sz: Integer;
begin
  Result := ExtraField;
  if (ExtraFieldLength >= 4) and XData(Result, Word(Tag), i, sz) then
    Result := Copy(Result, 5, sz - 4)
  else
    Result := '';
end;

function TZMDirEntry.GetIsDirOnly: boolean;
begin
  Result := (StatusBits and zsbDirOnly) <> 0;
end;

function TZMDirEntry.XData(const x: TZMRawBytes; Tag: Word; var idx, size:
    Integer): Boolean;
var
  i: Integer;
  l: Integer;
  wsz: Word;
  wtg: Word;
begin
  Result := False;
  idx := 0;
  size := 0;
  i := 1;
  l := Length(x);
  while i <= l - 4 do
  begin
    wtg := pWord(@x[i])^;
    wsz := pWord(@x[i + 2])^;
    if wtg = Tag then
    begin
      Result := (i + wsz + 4) <= l + 1;
      if Result then
      begin
        idx  := i;
        size := wsz + 4;
      end;
      break;
    end;
    i := i + wsz + 4;
  end;
end;

{TZMDirRec}
function TZMDirRec.ChangeStamp(ndate: TDateTime): Integer;
begin
  Result := ChangeDate(DateTimeToFileDate(ndate));
end;


{$IFDEF VERD2005up}
{TZipMasterEnumerator}
constructor TZipMasterEnumerator.Create(aMaster: TCustomZipMaster19);
begin
  inherited Create;
  FIndex := -1;
  FOwner := aMaster;
end;

function TZipMasterEnumerator.GetCurrent: TZMDirEntry;
begin
  Result := FOwner[FIndex];
end;

function TCustomZipMaster19.GetEnumerator: TZipMasterEnumerator;
begin
  Result := TZipMasterEnumerator.Create(Self);
end;

function TZipMasterEnumerator.MoveNext: boolean;
begin
  Result := FIndex < (FOwner.Count- 1);
  if Result then
    Inc(FIndex);
end;
{$ENDIF}

{TCustomZipMaster19}
procedure TCustomZipMaster19.AbortDLL;
begin
  TZMDLLOpr(fWorker).AbortDLL;
end;

function TCustomZipMaster19.Add: Integer;
begin
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).Add;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

function TCustomZipMaster19.AddStreamToFile(const FileName: String;
  FileDate, FileAttr: Dword): Integer;
begin
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).AddStreamToFile(FileName, FileDate, FileAttr);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

function TCustomZipMaster19.AddStreamToStream(InStream: TMemoryStream):
    TMemoryStream;
begin
  Result := nil;
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).AddStreamToStream(InStream);
      if SuccessCnt = 1 then
        Result := ZipStream;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.AddZippedFiles(SrcZipMaster: TCustomZipMaster19;
  merge: TZMMergeOpts): Integer;
begin
  if Permitted then
    try
      Start;
      if (not assigned(SrcZipMaster)) or (SrcZipMaster.ZipFileName = '') then
        raise EZipMaster.CreateResDisp(GE_NoZipSpecified, True);
      if SrcZipMaster.Permitted then
      begin
        try
          SrcZipMaster.Start;
          TZMWorker(fWorker).AddZippedFiles(TZMWorker(SrcZipMaster.fWorker), merge);
          SrcZipMaster.Done;
        except
          on E: Exception do
          begin
            SrcZipMaster.DoneBad(E);
            raise;
          end;
        end;
      end
      else
        raise EZipMaster.CreateResStr(GE_WasBusy, 'Source');
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

procedure TCustomZipMaster19.AfterConstruction;
begin
  inherited;
  fWorker  := TZMDLLOpr.Create(Self);
  fDelaying := 0;
  BusyFlag := 0;
  fCurWaitCount := 0;
  fNotMainThread := False;
  FNoReadAux := False;
  FAuxChanged := False;
  fFSpecArgs := TStringList.Create;
  fFSpecArgsExcl := TStringList.Create;
  FPipes := TZMPipeListImp.Create;
  fAddCompLevel := 9;         // default to tightest compression
  fAddStoreSuffixes := ZMDefAddStoreSuffixes;
  fEncoding := zeoAuto;
  fEncrypt := False;
  fFromDate := 0;
  fHandle  := Application.Handle;
  fHowToDelete := htdAllowUndo;
  fPassword := '';
  fPasswordReqCount := 1;
  fUnattended := False;
  fUseDirOnlyEntries := False;
  fUseDelphiBin := True;
  fMinFreeVolSize := 65536;
  fMaxVolumeSize := 0;
  fMaxVolumeSizeKb := 0;
  fFreeOnAllDisks := 0;
  fFreeOnDisk1 := 0;
  fConfirmErase := False;
  FNoSkipping := DefNoSkips;
  fActive  := 2;
end;

function TCustomZipMaster19.AppendSlash(const sDir: String): String;
begin
  Result := DelimitPath(sDir, True);
end;

procedure TCustomZipMaster19.AuxWasChanged;
begin
  if (not fNoReadAux) or (csDesigning in ComponentState) or
  (csLoading in ComponentState) then
    FAuxChanged := True;
end;

procedure TCustomZipMaster19.BeforeDestruction;
begin
  Cancel := True;   // stop any activity
  fActive := 0;
  fOnMessage := nil;  // stop any messages being sent
  fOnStateChange := nil;
  fOnStream := nil;
  fOnTick := nil;
  fOnZipDialog := nil;
  if fWorker is TZMCore then
    TZMCore(fWorker).Kill;
  FreeAndNil(fWorker);
  FreeAndNil(fFSpecArgs);
  FreeAndNil(fFSpecArgsExcl);
  FreeAndNil(FPipes);
  inherited;
end;

function TCustomZipMaster19.CanStart: Boolean;
begin
  if not IsActive then //not Active
    Result := False
  else
    Result := Stopped;
end;

function TCustomZipMaster19.ChangeFileDetails(func: TZMChangeFunction;
  var Data): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ChangeFileDetails(@func, Data);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

procedure TCustomZipMaster19.Clear;
begin
  if Permitted then
  begin
    TZMWorker(fWorker).Clear;
    Pipes.Clear;
    Done;
    fReentry := False;
  end;
end;

function TCustomZipMaster19.ConvertToSFX: Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ConvertToSFX('', nil);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
 if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.ConvertToSpanSFX(const OutFile: String): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ConvertToSpanSFX(OutFile, nil);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
 if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.ConvertToZIP: Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ConvertToZIP;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
 if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.CopyZippedFiles(DestZipMaster: TCustomZipMaster19;
  DeleteFromSource: Boolean; OverwriteDest: TZMMergeOpts): Integer;
var
  DestWorker: TZMWorker;
  MyWorker: TZMWorker;
begin
  if not assigned(DestZipMaster) then
  begin
    Result := CF_NoDest;
    ShowZipMessage(Result, '');
    Exit;
  end;
  DestWorker := DestZipMaster.fWorker as TZMWorker;
  MyWorker := fWorker as TZMWorker;
  // destination must not be busy and must not be allowed to become busy
  if DestZipMaster.Permitted then
  begin
    try
      DestZipMaster.Start; // lock it
      if Permitted then
        try
          Start;
          MyWorker.CopyZippedFiles(DestWorker, DeleteFromSource, OverwriteDest);
          done;
        except
          on E: Exception do
            DoneBad(E);
        end;
      DestZipMaster.done; // release it
    except
      on E: Exception do
        DestZipMaster.DoneBad(E);
    end;
    Result := ErrCode;
  end
  else
  begin
    Result := GE_WasBusy;
    ShowZipFmtMessage(Result,[DestZipMaster.ZipFileName]);
  end;
end;

function TCustomZipMaster19.Copy_File(const InFileName, OutFileName: String): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).Copy_File(InFileName, OutFileName);
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.Deflate(OutStream, InStream: TStream; Length:
    Int64; var Method: TZMDeflates; var CRC: Cardinal): Integer;
begin
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).Deflate(OutStream, InStream, Length, Method, CRC);
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

function TCustomZipMaster19.Delete: Integer;
begin
  if Permitted then
    try
      Start;
      TZMWorker(fWorker).Delete;
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

procedure TCustomZipMaster19.DoDelays;
var
  delay: Integer;
begin
  if Permitted then
    try
      Start;
      delay := fDelaying;
      fDelaying := 0;
      if (delay and DelayingLanguage) <> 0 then
        SetZipMsgLanguage(fLanguage);
      if (delay and DelayingFileName) <> 0 then
        TZMWorker(fWorker).Set_ZipFileName(fZipFileName, zloFull);
      if (ErrCode = 0) and ((delay and DelayingComment) <> 0) then
        TZMWorker(fWorker).Set_ZipComment(AnsiString(fZipComment));
      if (ErrCode = 0) and ((delay and DelayingDLL) <> 0) then
      begin
        TZMDLLOpr(fWorker).DLL_Load := fDLLLoad;
        fDLLLoad := TZMDLLOpr(fWorker).DLL_Load;    // true if it loaded
      end;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

procedure TCustomZipMaster19.Done(Good: Boolean = True);
var
  z: TZMWorker;
begin
  z := fWorker as TZMWorker;
  z.Done(Good);
  if Good then
  begin
    fFSpecArgs.Assign(z.FSpecArgs);
    fFSpecArgsExcl.Assign(z.FSpecArgsExcl);
    fZipComment  := z.ZipComment;
    fZipFileName := z.ZipFileName;
    if not NoReadAux then
    begin
      // set Aux properties from current
      if z.GetAuxProperties then
        fAuxChanged := False;
    end;
  end;
  Dec(BusyFlag);
  if Trace then
    TZMCore(fWorker).Diag('done = ' + IntToStr(BusyFlag));
  if BusyFlag = 0 then
  begin
    StateChanged(zsIdle);
    // Are we waiting to go inactive?
    if fActive < 0 then
    begin
      fActive := 0;
      StateChanged(zsDisabled);
    end;
  end;
end;

procedure TCustomZipMaster19.DoneBad(E: Exception);
begin
  Done(False);
  Pipes.Clear;
  if E is EZMException then     // Catch all Zip specific errors.
    ShowExceptionError(EZMException(E))
  else
  if E is EOutOfMemory then
    ShowZipMessage(GE_NoMem, '')
  else
    ShowZipMessage(LI_ErrorUnknown, E.Message);
  // the error ErrMessage of an unknown error is displayed ...
end;

function TCustomZipMaster19.EraseFile(const FName: String; How: TZMDeleteOpts): Integer;
begin
  Result := ZMUtils19.EraseFile(FName, How = htdFinal);
end;

function TCustomZipMaster19.Extract: Integer;
begin
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).Extract;
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

function TCustomZipMaster19.ExtractFileToStream(const FileName: String):
    TMemoryStream;
begin
  Result := nil;
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).ExtractFileToStream(FileName);
      if SuccessCnt = 1 then
        Result := ZipStream;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.ExtractStreamToStream(InStream: TMemoryStream;
    OutSize: Longword): TMemoryStream;
begin
  Result := nil;
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).ExtractStreamToStream(InStream, OutSize);
      if SuccessCnt = 1 then
        Result := ZipStream;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.Find(const fspec: TZMString; var idx: Integer): TZMDirEntry;
var
  c: Integer;
begin
  if idx < 0 then
    idx := -1;
  c := pred(Count);
  while idx < c do
  begin
    Inc(idx);
    Result := GetDirEntry(idx);
    if FileNameMatch(fspec, Result.FileName{$IFNDEF UNICODE}, UseUTF8{$ENDIF}) then
      exit;
  end;
  idx := -1;
  Result := nil;
end;

function TCustomZipMaster19.ForEach(func: TZMForEachFunction; var Data): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ForEach(@func, Data);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.FullVersionString: String;
begin
  Result := 'ZipMaster ' + Version;
  Result := Result + ', DLL ' + GetDLL_Version1(True);
end;

function TCustomZipMaster19.GetActive: Boolean;
begin
  Result := fActive <> 0;
end;

function TCustomZipMaster19.GetAddPassword: String;
var
  Resp: TmsgDlgBtn;
begin
  Result := TZMDLLOpr(fWorker).GetAddPassword(Resp);
  if not Busy then
    Password := Result;
end;

function TCustomZipMaster19.GetAddPassword(var Response: TmsgDlgBtn): String;
begin
  Result := TZMDLLOpr(fWorker).GetAddPassword(Response);
  if not Busy then
    Password := Result;
end;

function TCustomZipMaster19.GetBuild: Integer;
begin
  Result := ZIPMASTERPRIV;
end;

function TCustomZipMaster19.GetBusy: Boolean;
begin
  Result := BusyFlag <> 0;
end;

function TCustomZipMaster19.GetCancel: Boolean;
begin
  Result := TZMWorker(fWorker).Cancel <> 0;
end;

function TCustomZipMaster19.GetCount: Integer;
begin
  if IsActive then
    Result := TZMWorker(fWorker).CentralDir.Count
  else
    Result := 0;
end;

function TCustomZipMaster19.GetDirEntry(idx: Integer): TZMDirEntry;
begin
  if IsActive then
    Result := TZMWorker(fWorker).CentralDir[idx]
  else
    Result := nil;
end;

function TCustomZipMaster19.GetDirOnlyCnt: Integer;
begin
  Result := TZMWorker(fWorker).CentralDir.DirOnlyCount;
end;

function TCustomZipMaster19.GetDLL_Build: Integer;
begin
  Result := 0;
  if Busy then
    Result := TZMDLLOpr(fWorker).DLL_Build
  else
  if Permitted then
    try
      Start;
      Result := TZMDLLOpr(fWorker).DLL_Build;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.GetDLL_Load: Boolean;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Result := fDLLLoad
  else
  begin
    Result := TZMDLLOpr(fWorker).DLL_Load;
    fDLLLoad := Result;
  end;
end;

function TCustomZipMaster19.GetDLL_Path: String;
begin
  Result := '';
  if Busy then
    Result := TZMDLLOpr(fWorker).DLL_Path
  else
  if Permitted then
    try
      Start;
      Result := TZMDLLOpr(fWorker).DLL_Path;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.GetDLL_Version: String;
begin
  Result := GetDLL_Version1(False);
end;

function TCustomZipMaster19.GetDLL_Version1(load: boolean): String;
begin
  Result := '';
  if Busy then
    Result := TZMDLLOpr(fWorker).DLL_Version(load)
  else
  if Permitted then
    try
      Start;
      Result := TZMDLLOpr(fWorker).DLL_Version(load);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

function TCustomZipMaster19.GetErrCode: Integer;
begin
  Result := TZMWorker(fWorker).ErrCode;
  if fReentry then
    Result := Result or ZMReentry_Error
  else
  if not IsActive then
    Result := GE_Inactive;
end;

function TCustomZipMaster19.GetErrMessage: TZMString;
begin
  if IsActive then
    Result := TZMWorker(fWorker).ErrMessage
  else
    Result := ZipLoadStr(GE_Inactive);
  if fReentry then
    Result := TZMCore(fWorker).ZipFmtLoadStr(GE_WasBusy, [Result]);
end;

function TCustomZipMaster19.GetExtrPassword: String;
var
  Resp: TmsgDlgBtn;
begin
  Result := TZMDLLOpr(fWorker).GetExtrPassword(Resp);
  if not Busy then
    Password := Result;
end;

function TCustomZipMaster19.GetExtrPassword(var Response: TmsgDlgBtn): String;
begin
  Result := TZMDLLOpr(fWorker).GetExtrPassword(Response);
  if not Busy then
    Password := Result;
end;

function TCustomZipMaster19.GetDllErrCode: Integer;
begin
  Result := TZMWorker(fWorker).DllErrCode;
end;

function TCustomZipMaster19.GetIsSpanned: Boolean;
begin
  Result := TZMWorker(fWorker).CentralDir.MultiDisk;
end;

function TCustomZipMaster19.GetLanguage: string;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    Result := fLanguage
  else
    Result := GetZipMsgLanguage(0);
end;

class function TCustomZipMaster19.GetLanguageInfo(Idx: Integer; info: Cardinal): String;
begin
  Result := GetZipMsgLanguageInfo(Idx, info);
end;

function TCustomZipMaster19.GetNoReadAux: Boolean;
begin
  Result := FNoReadAux;
  if not ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
    Result := Result or FAuxChanged;
end;

function TCustomZipMaster19.GetOnLoadStr: TZMLoadStrEvent;
begin
  Result := OnZMStr;
end;

function TCustomZipMaster19.GetPassword(const DialogCaption, MsgTxt: String;
  pwb: TmsgDlgButtons; var ResultStr: String): TmsgDlgBtn;
begin
  Result := TZMDLLOpr(fWorker).GetPassword(DialogCaption, MsgTxt, pwb, ResultStr);
end;

function TCustomZipMaster19.GetSFXOffset: Integer;
begin
  Result := TZMWorker(fWorker).CentralDir.SFXOffset;
end;

function TCustomZipMaster19.GetSuccessCnt: Integer;
begin
  Result := TZMWorker(fWorker).SuccessCnt;
end;

function TCustomZipMaster19.GetTotalSizeToProcess: Int64;
begin
  Result := TZMWorker(fWorker).TotalSizeToProcess;
end;

function TCustomZipMaster19.GetVersion: String;
begin
  Result := ZIPMASTERBUILD;
end;

function TCustomZipMaster19.GetZipComment: String;
begin
  Result := string(fZipComment);
end;

function TCustomZipMaster19.GetZipEOC: Int64;
begin
  Result := TZMWorker(fWorker).CentralDir.EOCOffset;
end;

function TCustomZipMaster19.GetZipFileSize: Int64;
begin
  Result := TZMWorker(fWorker).CentralDir.ZipFileSize;
end;

function TCustomZipMaster19.GetZipSOC: Int64;
begin
  Result := TZMWorker(fWorker).CentralDir.SOCOffset;
end;

function TCustomZipMaster19.GetZipStream: TMemoryStream;
begin
  Result := TZMDLLOpr(fWorker).ZipStream;
end;

function TCustomZipMaster19.IndexOf(const FName: TZMString): Integer;
var
  fn: TZMString;
begin
  fn := FName;
  for Result := 0 to pred(Count) do
    if FileNameMatch(fn, GetDirEntry(Result).FileName{$IFNDEF UNICODE}, UseUTF8{$ENDIF}) then
      exit;
  Result := -1;
end;

function TCustomZipMaster19.IsActive: boolean;
begin
  Result := (FActive <> 0);
  if Result and ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
    Result := False;  // never Active while loading or designing
end;

function TCustomZipMaster19.IsZipSFX(const SFXExeName: String): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).IsZipSFX(SFXExeName);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
 if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.List: Integer;
begin
  if Permitted then
    try
      Start;
      TZMWorker(fWorker).List;
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

procedure TCustomZipMaster19.Loaded;
begin
  inherited;
  if IsActive then
    DoDelays;
end;

function TCustomZipMaster19.MakeTempFileName(const Prefix, Extension: String): String;
begin
  if not Busy then
    TZMCore(fWorker).TempDir := TempDir;
  Result := TZMCore(fWorker).MakeTempFileName(Prefix, Extension);
end;

function TCustomZipMaster19.Permitted: Boolean;
begin
  Result := False;
  if IsActive then
  begin
    Inc(BusyFlag);
    if BusyFlag <> 1 then
    begin
      Dec(BusyFlag);
      ReEntered;
    end
    else
      Result := True;
  end;
  if Result then
    StateChanged(zsBusy);
end;

function TCustomZipMaster19.QueryZip(const FName: TFileName): Integer;
begin
  Result := ZMUtils19.QueryZip(FName);
end;

function TCustomZipMaster19.ReadSpan(const InFileName: String;
  var OutFilePath: String): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).ReadSpan(InFileName, OutFilePath, False);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
end;

procedure TCustomZipMaster19.ReEntered;
begin
  fReentry := True;
  if Verbose then
    TZMCore(fWorker).Diag('Re-entry');
end;

function TCustomZipMaster19.Rename(RenameList: TList; DateTime: Integer; How:
    TZMRenameOpts = htrDefault): Integer;
begin
  if Permitted then
    try
      Start;
      TZMWorker(fWorker).Rename(RenameList, DateTime, How);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

(* TCustomZipMaster19.SetActive
  sets the following values
  0 - not active
  1 - active
  -1 - active in design/loading state (no Active functions allowed)
*)
procedure TCustomZipMaster19.SetActive(Value: Boolean);
var
  was: Integer;
begin
  if (csDesigning in ComponentState) or (csLoading in ComponentState) then
  begin
    if Value then
      fActive := 1// set but ignored
    else
      fActive := 0;
    exit;
  end;
  if Value <> (FActive > 0) then
  begin
    was := FActive;
    if Value then
    begin
      fActive := 1;
      // reject change active to inactive to active while busy
      if was = 0 then
      begin
        // changed to 'active'
        StateChanged(zsIdle);
        if (fDelaying <> 0) and (BusyFlag = 0) then
          DoDelays;
      end;
    end
    else
    begin
      if BusyFlag <> 0 then
        fActive := -3  // clear when 'done'
      else
      begin
        fActive := 0;  // now inactive
        StateChanged(zsDisabled);
      end;
    end;
  end;
end;

procedure TCustomZipMaster19.SetCancel(Value: Boolean);
begin
  if Value <> Cancel then
  begin
    if Value then
      TZMWorker(fWorker).Cancel := DS_Canceled
    else
      TZMWorker(fWorker).Cancel := 0;
  end;
end;

procedure TCustomZipMaster19.SetDLL_Load(const Value: Boolean);
begin
  if Value <> fDLLLoad then
    if Permitted then
      try
        Start;
        TZMDLLOpr(fWorker).DLL_Load := Value;
        fDLLLoad := TZMDLLOpr(fWorker).DLL_Load;    // true if it loaded
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end
    else
    if not IsActive then //not Active
    begin
      fDLLLoad  := Value;
      fDelaying := fDelaying or DelayingDLL;  // delay until Active
    end;
end;

procedure TCustomZipMaster19.SetEncodeAs(const Value: TZMEncodingOpts);
begin
  if fEncodeAs <> Value then
  begin
    fEncodeAs := Value;
    if Permitted then
    begin
      try
        StartNoDll;     // avoid loading the dll
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end;
    end;
  end;
end;

procedure TCustomZipMaster19.SetEncoding(const Value: TZMEncodingOpts);
begin
  if fEncoding <> Value then
  begin
    fEncoding := Value;
    if Permitted then
    begin
      try
        StartNoDll;     // avoid loading the dll
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end;
    end;
  end;
end;

procedure TCustomZipMaster19.SetEncoding_CP(Value: Cardinal);
var
  info: TCPInfo;
begin
  if not GetCPInfo(Value, info) then
    Value := 0;
  if fEncoding_CP <> Value then
  begin
    fEncoding_CP := Value;
    if Permitted then
    begin
      try
        StartNoDll;     // avoid loading the dll
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end;
    end;
  end;
end;

procedure TCustomZipMaster19.SetErrCode(Value: Integer);
begin
  if Stopped then
    TZMWorker(fWorker).ErrCode := Value;
end;

procedure TCustomZipMaster19.SetFSpecArgs(const Value: TStrings);
begin
  if Value <> fFSpecArgs then
    fFSpecArgs.Assign(Value);
end;

procedure TCustomZipMaster19.SetFSpecArgsExcl(const Value: TStrings);
begin
  if Value <> fFSpecArgsExcl then
    fFSpecArgsExcl.Assign(Value);
end;

procedure TCustomZipMaster19.SetLanguage(const Value: string);
begin
    if Permitted then
      try
        fLanguage := Value;
        Start;
        SetZipMsgLanguage(Value);
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end
    else
    if not IsActive then //not Active
    begin
      fLanguage := Value;
      fDelaying := fDelaying or DelayingLanguage; // delay until Active
    end;
end;

procedure TCustomZipMaster19.SetNoReadAux(const Value: Boolean);
begin
  // must check changes in composite value
  if NoReadAux <> Value then
  begin
    FNoReadAux := Value;
      FAuxChanged := False; // reset
  end;
end;

procedure TCustomZipMaster19.SetOnLoadStr(const Value: TZMLoadStrEvent);
begin
  {ZMMsgStr19.}OnZMStr := Value;
end;

procedure TCustomZipMaster19.SetPassword(const Value: String);
begin
  if fPassword <> Value then
  begin
    fPassword := Value;
    if Busy then
      TZMDLLOpr(fWorker).Password := Value;  // allow changes
  end;
end;

procedure TCustomZipMaster19.SetPasswordReqCount(Value: Longword);
begin
  if Value > 15 then
    Value := 15;
  if Value <> fPasswordReqCount then
  begin
    fPasswordReqCount := Value;
    if Busy then
      TZMDLLOpr(fWorker).PasswordReqCount := Value;  // allow changes
  end;
end;

procedure TCustomZipMaster19.SetPipes(const Value: TZMPipeList);
begin
//  FPipes := Value;
end;

procedure TCustomZipMaster19.SetSFXCaption(const Value: TZMString);
begin
  if FSFXCaption <> Value then
  begin
    FSFXCaption := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXCommandLine(const Value: TZMString);
begin
  if FSFXCommandLine <> Value then
  begin
    FSFXCommandLine := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXDefaultDir(const Value: String);
begin
  if FSFXDefaultDir <> Value then
  begin
    FSFXDefaultDir := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXIcon(Value: TIcon);
begin
  if Value <> fSFXIcon then
  begin
    if Assigned(Value) and not Value.Empty then
    begin
      if not Assigned(fSFXIcon) then
        fSFXIcon := TIcon.Create;
      fSFXIcon.Assign(Value);
    end
    else
      FreeAndNil(fSFXIcon);
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXMessage(const Value: TZMString);
begin
  if FSFXMessage <> Value then
  begin
    FSFXMessage := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXOptions(const Value: TZMSFXOpts);
begin
  if FSFXOptions <> Value then
  begin
    FSFXOptions := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXOverwriteMode(const Value: TZMOvrOpts);
begin
  if FSFXOverwriteMode <> Value then
  begin
    FSFXOverwriteMode := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSFXRegFailPath(const Value: String);
begin
  if FSFXRegFailPath <> Value then
  begin
    FSFXRegFailPath := Value;
    AuxWasChanged;
  end;
end;

procedure TCustomZipMaster19.SetSpanOptions(const Value: TZMSpanOpts);
begin
  if FSpanOptions <> Value then
  begin
    if (Value * [spNoVolumeName, spCompatName]) <> (FSpanOptions * [spNoVolumeName, spCompatName]) then
      AuxWasChanged;
    FSpanOptions := Value;
  end;
end;

procedure TCustomZipMaster19.SetUseDirOnlyEntries(const Value: Boolean);
begin
  if Value <> FUseDirOnlyEntries then
  begin
    FUseDirOnlyEntries := Value;
    if Permitted then
    begin
      try
        StartNoDll;     // avoid loading the dll
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end;
    end;
  end;
end;

{$IFNDEF UNICODE}
procedure TCustomZipMaster19.SetUseUTF8(const Value: Boolean);
begin
  if Value <> FUseUTF8 then
  begin
    FUseUTF8 := Value;
    if Permitted then
    begin
      try
        StartNoDll;     // avoid loading the dll
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end;
    end;
  end;
end;
{$ENDIF}

procedure TCustomZipMaster19.SetVersion(const Value: String);
begin
  //    Read only
end;

procedure TCustomZipMaster19.SetWriteOptions(const Value: TZMWriteOpts);
begin
  if FWriteOptions <> Value then
  begin
    if (zwoDiskSpan in Value) <> (zwoDiskSpan in FWriteOptions) then
      AuxWasChanged;
    FWriteOptions := Value;
    if not Busy then
      TZMCore(fWorker).WriteOptions := Value;
  end;
end;

procedure TCustomZipMaster19.SetZipComment(const Value: String);
var
  v: AnsiString;
begin
  v := AnsiString(Value);
  if v <> fZipComment then
    if Permitted then
      try
        fZipComment := v;
        Start;
        TZMWorker(fWorker).Set_ZipComment(v);
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end
    else
    if not IsActive then //not Active
    begin
      fZipComment := v;
      fDelaying := fDelaying or DelayingComment;
    end;
end;

procedure TCustomZipMaster19.SetZipFileName(const Value: String);
begin
  if Value <> fZipFileName then
    if Permitted then
      try
        fZipFileName := Value;
        Start;
        TZMWorker(fWorker).Set_ZipFileName(Value, zloFull);
        Done;
      except
        On E: Exception do
          DoneBad(E);
      end
    else
    if not IsActive then //not Active
    begin
      fZipFileName := Value;
      fDelaying := fDelaying or DelayingFileName;
    end;
end;

procedure TCustomZipMaster19.ShowExceptionError(const ZMExcept: EZMException);
begin
  TZMWorker(fWorker).ShowExceptionError(ZMExcept);
end;

(*? TCustomZipMaster19.ShowZipFmtMessage
1.79 added
*)
procedure TCustomZipMaster19.ShowZipFmtMessage(Id: Integer; const Args: array of const);
begin
  TZMWorker(fWorker).ShowZipFmtMsg(Id, Args, True);
end;

procedure TCustomZipMaster19.ShowZipMessage(Ident: Integer; const UserStr: String);
begin
  TZMWorker(fWorker).ShowZipMessage(Ident, UserStr);
end;

procedure TCustomZipMaster19.Start;
var
  z: TZMDLLOpr;
begin
  fReentry := False;
  z := fWorker as TZMDLLOpr;
  z.StartUp;
  z.DLLDirectory := DLLDirectory;
  z.DLL_Load := fDLLLoad;
  z.NoReadAux := fNoReadAux;
  z.AuxChanged := fAuxChanged;
end;

procedure TCustomZipMaster19.StartNoDll;
var
  z: TZMWorker;
begin
  fReentry := False;
  z := fWorker as TZMWorker;
  z.StartUp;
  z.NoReadAux := fNoReadAux;
  z.AuxChanged := fAuxChanged;
end;

procedure TCustomZipMaster19.StartWaitCursor;
begin
  if FCurWaitCount = 0 then
  begin
    FSaveCursor := Screen.Cursor;
    Screen.Cursor := crHourGlass;
  end;
  inc(FCurWaitCount);
end;

procedure TCustomZipMaster19.StateChanged(newState: TZMStates);
var
  NoCursor: boolean;
begin
  NoCursor := NotMainThread;
  if assigned(OnStateChange) then
    OnStateChange(self, newState, NoCursor);
  if not NoCursor then
  begin
    if newState = zsBusy then
      StartWaitCursor
    else
      StopWaitCursor;
  end;
end;

function TCustomZipMaster19.Stopped: Boolean;
begin
  if BusyFlag = 0 then
    Result := True
  else
  begin
    Result := False;
    ReEntered;
  end;
end;

procedure TCustomZipMaster19.StopWaitCursor;
begin
  if FCurWaitCount > 0 then
  begin
    dec(FCurWaitCount);
    if FCurWaitCount < 1 then
      Screen.Cursor := FSaveCursor;
  end;
end;

function TCustomZipMaster19.TheErrorCode(errCode: Integer): Integer;
begin
  Result := errCode and (ZMReentry_Error - 1);
end;

function TCustomZipMaster19.Undeflate(OutStream, InStream: TStream; Length:
    Int64; var Method: TZMDeflates; var CRC: Cardinal): Integer;
begin
  if Permitted then
    try
      Start;
      TZMDLLOpr(fWorker).Undeflate(OutStream, InStream, Length, Method, CRC);
      Done;
    except
      on E: Exception do
        DoneBad(E);
    end;
  Result := ErrCode;
end;

function TCustomZipMaster19.WriteSpan(const InFileName, OutFileName: String): Integer;
begin
  Result := 0;
  if Permitted then
    try
      Start;
      Result := TZMWorker(fWorker).WriteSpan(InFileName, OutFileName, False);
      Done;
    except
      On E: Exception do
        DoneBad(E);
    end;
  if ErrCode <> 0 then
    Result := ErrCode;
end;

function TCustomZipMaster19.ZipLoadStr(Id: Integer): string;
begin
  if IsActive then
    Result := TZMCore(fWorker).ZipLoadStr(Id)
  else
    Result := LoadZipStr(Id);
end;

end.
