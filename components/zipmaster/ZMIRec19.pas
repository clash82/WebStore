unit ZMIRec19;

(*
  ZMIRec19.pas - Represents the 'Directory entry' of a Zip file
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

  modified 2010-05-12
---------------------------------------------------------------------------*)
interface

uses
  Classes, Windows, ZipMstr19, ZMWorkFile19, ZMStructs19, ZMCompat19;

type
  TZMRecStrings = (zrsName, zrsComment, zrsIName);
  TZipSelects          = (zzsClear, zzsSet, zzsToggle);
  TZMStrEncOpts = (zseDOS, zseXName, zseXComment);
  TZMStrEncodes = set of TZMStrEncOpts;

// ZipDirEntry status bit constants
const
  zsbHashed = $100;     // hash calculated
  zsbLocalDone = $200;  // local data prepared
  zsbLocal64 = $400;    // local header required zip64

  zsbEncMask = $70000;  // mask for bits holding how entry is encoded

type
  TZSExtOpts = (zsxUnkown, zsxName, zsxComment, zsxName8, zsxComment8);
  TZStrExts = set of TZSExtOpts;

type
  THowToEnc = (hteOEM, hteAnsi, hteUTF8);


type
  TZMIRec = class(TZMDirRec)
  private
    fComprMethod:    Word;            //compression method(2)
    fComprSize:      Int64;           //compressed file size  (8)
    fCRC32:          Longword;        //Cyclic redundancy check (4)
    fDiskStart:      Cardinal;        //starts on disk number xx(4)
    fExtFileAtt:     Longword;        //external file attributes(4)
    FExtraField:     TZMRawBytes;//RawByteString;
    fFileName:       TZMString;       // cache for external filename
    fFileComLen:     Word;            //(2)
    fFileNameLen:    Word;            //(2)
    fFlag:           Word;            //generalPurpose bitflag(2)
    FHash:           Cardinal;
    fHeaderComment:  TZMRawBytes;//RawByteString;   // internal comment
    fHeaderName:     TZMRawBytes;//RawByteString;
    fIntFileAtt:     Word;            //internal file attributes(2)
    FLocalData:      TZMRawBytes;//RawByteString;
    fModifDateTime:  Longword;        // dos date/time          (4)
    fOrigHeaderName: TZMRawBytes;//RawByteString;
    fOwner:          TZMWorkFile;
    fRelOffLocal:    Int64;
    FSelectArgs: string;
    fStatusBits:     Cardinal;
    fUnComprSize:    Int64;           //uncompressed file size (8)
    FVersionMadeBy: word;
    fVersionNeeded:    Word;            // version needed to extract(2)
    function GetEncodeAs: TZMEncodingOpts;
    function GetEncoding: TZMEncodingOpts;
    function GetHash: Cardinal;
    function GetHeaderComment: TZMRawBytes;
    function GetIsEncoded: TZMEncodingOpts;
    function GetSelected: Boolean;
    function GetStatusBit(Mask: Cardinal): Cardinal;
    procedure SetIsEncoded(const Value: TZMEncodingOpts);
    procedure SetSelected(const Value: Boolean);
  protected
    procedure Diag(const msg: TZMString);
    function FindDataTag(tag: Word; var idx, siz: Integer): Boolean;
//    function FindDuplicate(const Name: String): TZMIRec;
    function FixStrings(const NewName, NewComment: TZMString): Integer;
    function FixXData64: Integer;
    function GetCompressedSize: Int64; override;
    function GetCompressionMethod: Word; override;
    function GetCRC32: Cardinal; override;
    function GetDataString(Cmnt: Boolean): UTF8String;
    function GetDateTime: Cardinal; override;
    function GetDirty: Boolean;
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
    function IsZip64: Boolean;
    procedure MarkDirty;
    //1 Set Minimum VersionMadeBy and VersionNeeded
    procedure FixMinimumVers(z64: boolean);
    //1 convert internal Filename/Comment from utf
    function Int2UTF(Field: TZMRecStrings; NoUD: Boolean = False): TZMString;
    //1 return true if Zip64 fields used
    procedure PrepareLocalData;
    procedure SetDateStamp(Value: TDateTime);
    procedure SetEncrypted(const Value: Boolean);
    procedure SetExtraData(Tag: Word; const data: TZMRawBytes);
    function StrToSafe(const aString: TZMString; ToOem: boolean): AnsiString;
    function StripDrive(const FName: TZMString; NoPath: Boolean): TZMString;
    function StrToHeader(const aString: TZMString; how: THowToEnc): TZMRawBytes;
    function StrToUTF8Header(const aString: TZMString): TZMRawBytes;
    function StrTo_UTF8(const aString: TZMString): UTF8String;
    function ToIntForm(const nname: TZMString; var iname: TZMString): Integer;
    function WriteAsLocal: Integer;
    function WriteAsLocal1(Stamp, crc: Cardinal): Integer;
    function WriteDataDesc(OutZip: TZMWorkFile): Integer;
    property LocalData: TZMRawBytes read FLocalData write FLocalData;
    //1 Header name before rename - needed to verify local header
    property OrigHeaderName: TZMRawBytes read fOrigHeaderName;
  public
    constructor Create(theOwner: TZMWorkFile);
    procedure AfterConstruction; override;
    procedure AssignFrom(const zr: TZMIRec);
    procedure BeforeDestruction; override;
    function CentralSize: Cardinal;
    function ChangeAttrs(nAttr: Cardinal): Integer; override;
    function ChangeComment(const ncomment: TZMString): Integer; override;
    function ChangeData(ndata: TZMRawBytes): Integer; override;
    function ChangeDate(ndosdate: Cardinal): Integer; override;
    function ChangeEncoding: Integer; override;
    function ChangeName(const nname: TZMString): Integer; override;
    procedure ClearCachedName;
    function ClearStatusBit(const values: Cardinal): Cardinal;
    function HasChanges: Boolean;
    function LocalSize: Cardinal;
    function Process: Int64; virtual;
    function ProcessSize: Int64; virtual;
    function Read(wf: TZMWorkFile): Integer;
    function SafeHeaderName(const IntName: TZMString): TZMString;
    function SeekLocalData: Integer;
    function Select(How: TZipSelects): Boolean;
    function SetStatusBit(const Value: Cardinal): Cardinal;
    function TestStatusBit(const mask: Cardinal): Boolean;
    function Write: Integer;
    property CompressedSize: Int64 Read fComprSize Write fComprSize;
    property ComprMethod: Word Read fComprMethod Write fComprMethod;
    property CRC32: Longword Read fCRC32 Write fCRC32;
    property DiskStart: Cardinal Read fDiskStart Write fDiskStart;
    property EncodeAs: TZMEncodingOpts Read GetEncodeAs;
    property Encoded: TZMEncodingOpts Read GetEncoded;
    property Encoding: TZMEncodingOpts Read GetEncoding;
    property Encrypted: Boolean Read GetEncrypted Write SetEncrypted;
    property ExtFileAttrib: Longword Read fExtFileAtt Write fExtFileAtt;
    property ExtraData[Tag: Word]: TZMRawBytes read GetExtraData write
        SetExtraData;
    property ExtraField: TZMRawBytes read FExtraField write FExtraField;
    property ExtraFieldLength: Word read GetExtraFieldLength;
    property FileComLen: Word Read fFileComLen Write fFileComLen;
    property FileComment: TZMString Read GetFileComment;
    property FileCommentLen: Word Read fFileComLen Write fFileComLen;
    property FileName: TZMString Read GetFileName;
    property FileNameLen: Word Read fFileNameLen Write fFileNameLen;
    property FileNameLength: Word Read fFileNameLen Write fFileNameLen;
    property Flag: Word Read fFlag Write fFlag;
    property Hash: Cardinal read GetHash;
    property HeaderComment: TZMRawBytes read GetHeaderComment;
    property HeaderName: TZMRawBytes read GetHeaderName write fHeaderName;
    property IntFileAttrib: Word Read fIntFileAtt Write fIntFileAtt;
    //1 the cached value in the status
    property IsEncoded: TZMEncodingOpts read GetIsEncoded write SetIsEncoded;
    property ModifDateTime: Longword Read fModifDateTime Write fModifDateTime;
    property Owner: TZMWorkFile Read fOwner;
    property RelOffLocal: Int64 Read fRelOffLocal Write fRelOffLocal;
    property SelectArgs: string read FSelectArgs write FSelectArgs;
    property Selected: Boolean Read GetSelected Write SetSelected;
    property StatusBit[Mask: Cardinal]: Cardinal read GetStatusBit;
    property StatusBits: Cardinal Read GetStatusBits Write fStatusBits;
    property UncompressedSize: Int64 read fUnComprSize write fUnComprSize;
    property VersionMadeBy: word read FVersionMadeBy write FVersionMadeBy;
    property VersionNeeded: Word Read fVersionNeeded Write fVersionNeeded;
  end;

function XData(const x: TZMRawBytes; Tag: Word; var idx, size: Integer):
    Boolean;
function XDataAppend(var x: TZMRawBytes; const src1; siz1: Integer; const src2;
    siz2: Integer): Integer;
function XDataKeep(const x: TZMRawBytes; const tags: array of Integer):
    TZMRawBytes;
function XDataRemove(const x: TZMRawBytes; const tags: array of Integer):
    TZMRawBytes;

function HashFunc(const str: String): Cardinal;
function IsInvalidIntName(const FName: TZMString): Boolean;

implementation

uses
  SysUtils, ZMZipFile19, ZMMsg19, ZMXcpt19, ZMMsgStr19, ZMUtils19,
  ZMUTF819, ZMMatch19, ZMCore19, ZMDelZip19;

{$INCLUDE '.\ZipVers19.inc'}
{$IFDEF VER180}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

const
  MAX_BYTE = 255;

type
  Txdat64 = packed record
    tag:  Word;
    siz:  Word;
    vals: array [0..4] of Int64;  // last only cardinal
  end;

const
  ZipCenRecFields: array [0..17] of Integer =
    (4, 1, 1, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 2, 2, 4, 4);


// P. J. Weinberger Hash function
function HashFunc(const str : String) : Cardinal;
var
  i : Cardinal;
  x : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(str) do
  begin
    Result := (Result shl 4) + Ord(str[i]);
    x := Result and $F0000000;
    if (x <> 0) then
      Result := (Result xor (x shr 24)) and $0FFFFFFF;
  end;
end;

// make safe version of external comment
function SafeComment(const xcomment: String): string;
var
  c: Char;
  i: integer;
Begin
  if StrHasExt(xcomment) then
    Result := StrToOEM(xcomment)
  else
    Result := xcomment;
  for i := 1 to Length(Result) do
  begin
    c := Result[i];
    if (c < ' ') or (c > #126) then
      Result[i] := '_';
  end;
End;

{ TZMIRec }
constructor TZMIRec.Create(theOwner: TZMWorkFile);
begin
  inherited Create;
  fOwner := theOwner;
end;

procedure TZMIRec.AssignFrom(const zr: TZMIRec);
begin
  inherited;
  if (zr <> self) and (zr is TZMIRec) then
  begin
    VersionMadeBy := zr.VersionMadeBy;
    VersionNeeded := zr.VersionNeeded;
    Flag  := zr.Flag;
    ComprMethod := zr.ComprMethod;
    ModifDateTime := zr.ModifDateTime;
    CRC32 := zr.CRC32;
    CompressedSize := zr.CompressedSize;
    UncompressedSize := zr.UncompressedSize;
    FileNameLength := zr.FileNameLength;
    FileCommentLen := zr.FileCommentLen;
    DiskStart := zr.DiskStart;
    IntFileAttrib := zr.IntFileAttrib;
    ExtFileAttrib := zr.ExtFileAttrib;
    RelOffLocal := zr.RelOffLocal;
    fOrigHeaderName := zr.OrigHeaderName;
    fHeaderName := zr.HeaderName;
    fHeaderComment := zr.HeaderComment;
    fExtraField := zr.fExtraField;
    StatusBits := zr.StatusBits;
    fHash := zr.FHash;
  end;
end;

function TZMIRec.CentralSize: Cardinal;
begin
  Result := SizeOf(TZipCentralHeader);
  Inc(Result, FileNameLength + ExtraFieldLength + FileCommentLen);
end;

function TZMIRec.ChangeAttrs(nAttr: Cardinal): Integer;
begin
  Result := 0; // always allowed
  if nAttr <> GetExtFileAttrib then
  begin
    ExtFileAttrib := nAttr;
    MarkDirty;
  end;
end;

function TZMIRec.ChangeComment(const ncomment: TZMString): Integer;
begin
  Result := 0; // always allowed
  if ncomment <> GetFileComment then
    Result := FixStrings(FileName, ncomment);
end;

function TZMIRec.ChangeData(ndata: TZMRawBytes): Integer;
var
  NewData: TZMRawBytes;
  OldData: TZMRawBytes;
begin
  Result := 0; // always allowed
  if ndata <> GetExtraField then
  begin
    // preserve required tags
    OldData := XDataKeep(ExtraField, [Zip64_data_tag, UPath_Data_Tag, UCmnt_Data_Tag]);
    // do not allow changing fields
    NewData := XDataRemove(ndata, [Zip64_data_tag, UPath_Data_Tag, UCmnt_Data_Tag]);
    // will it fit?
    if (Length(OldData) + Length(NewData) + Length(GetFileComment) +
          Length(GetFileName)) < MAX_WORD then
    begin
      fExtraField := OldData + NewData;
      MarkDirty;
    end
    else
      Result := -CD_CEHDataSize;
  end;
end;

function TZMIRec.ChangeDate(ndosdate: Cardinal): Integer;
begin
  Result := -CD_NoProtected;
  if Encrypted then
    exit;
  try
    // test if valid date/time will throw error if not
    FileDateToDateTime(ndosdate);
  except
    Result := -RN_InvalidDateTime;
    if Owner.Boss.Verbosity >= zvVerbose then
      Diag('Invalid date ' + GetFileName);
    exit;
  end;
  Result := 0;
  if ndosdate <> GetDateTime then
  begin
    ModifDateTime := ndosdate;
    MarkDirty;
  end;
end;

function TZMIRec.ChangeEncoding: Integer;
begin
  Result := FixStrings(FileName, FileComment);
end;

function TZMIRec.ChangeName(const nname: TZMString): Integer;
var
  iname: TZMString;
begin
  Result := ToIntForm(nname, iname);
  if Result = 0 then
  begin
    Result := -CD_NoChangeDir;
    if IsFolder(iname) <> IsFolder(HeaderName) then
      exit; // dirOnly status must be same
    if iname <> FileName then
      Result := FixStrings(iname, FileComment);
  end;
end;

function TZMIRec.ClearStatusBit(const values: Cardinal): Cardinal;
begin
  StatusBits := StatusBits and not values;
  Result := StatusBits;
end;


procedure TZMIRec.Diag(const msg: TZMString);
begin
  if Owner.Boss.Verbosity >= zvVerbose then
    Owner.Boss.ShowMsg('Trace: ' + msg, 0, False);
end;

procedure TZMIRec.ClearCachedName;
begin
  fFileName := '';  // force reconvert - settings have changed
  ClearStatusBit(zsbHashed);
  IsEncoded := zeoAuto; // force re-evaluate
end;

function TZMIRec.FindDataTag(tag: Word; var idx, siz: Integer): Boolean;
begin
  Result := False;
  if XData(ExtraField, tag, idx, siz) then
    Result := True;
end;

//function TZMIRec.FindDuplicate(const Name: String): TZMIRec;
//var
//  ix: Integer;
//begin
//  ix := -1;  // from start
//  repeat
//    Result := (Owner as TZMZipFile).FindName(Name, ix);
//  until Result <> self;
//end;

function IsOnlyDOS(const hstr: TZMRawBytes): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 1 to Length(hstr) do
    if (hstr[i] > #126) or (hstr[i] < #32) then
    begin
      Result := False;
      Break;
    end;
end;

function TZMIRec.FixStrings(const NewName, NewComment: TZMString): Integer;
var
  dup: TZMIRec;
  enc: TZMEncodingOpts;
  HasXComment: Boolean;
  HasXName: Boolean;
  hcomment: TZMRawBytes;
  IX: Integer;
  need64: Boolean;
  NeedU8Bit: Boolean;
  newdata: Boolean;
  NewHeaderName: TZMRawBytes;
  NewIntName: string;
  NewMadeFS: Word;
  UComment: UTF8String;
  UData: TZMRawBytes;
  uheader: TUString_Data_Header;
  UName: UTF8String;
  xlen: Integer;
begin
  enc := EncodeAs;
  NewMadeFS := (FS_FAT * 256) or OUR_VEM;
  UName  := '';
  UComment := '';
  NeedU8Bit := False;
  Result := -CD_DuplFileName;
  ix := -1;  // from start
  dup := (Owner as TZMZipFile).FindName(NewName, ix, self);
  if dup <> nil then
    exit; // duplicate external name
  NewIntName := SafeHeaderName(NewName);
  // default convert new name and comment to OEM
  NewHeaderName  := StrToHeader(NewIntName, hteOEM);
  hcomment := StrToHeader(NewComment, hteOEM);
  // make entry name
  HasXName := StrHasExt(NewName);
  HasXComment := StrHasExt(NewComment);
  // form required strings
  if HasXName or HasXComment then
  begin
    if enc = zeoAuto then
    begin
      enc := zeoUPATH;  // unless both extended
      if HasXName and HasXComment then
        enc := zeoUTF8;
    end;
    // convert strings
    if enc = zeoUTF8 then
    begin
      NewHeaderName  := StrToHeader(NewIntName, hteUTF8);
      hcomment := StrToHeader(NewComment, hteUTF8);
      NeedU8Bit := True;
    end
    else
    begin
      if enc = zeoUPath then
      begin
        // we want UPATH or/and UCOMMENT
        if HasXName then
          UName  := StrTo_UTF8(NewIntName);
        if HasXComment then
          UComment := StrTo_UTF8(NewComment);
      end
      else
      if enc = zeoNone then
      begin
        // we want Ansi name and comment - NTFS
        NewHeaderName  := StrToHeader(NewIntName, hteAnsi);
        hcomment := StrToHeader(NewComment, hteAnsi);
        if StrHasExt(NewHeaderName) or StrHasExt(hcomment) then
          NewMadeFS := (FS_NTFS * 256) or OUR_VEM; // wasn't made safe FAT
      end;
    end;
  end;
  // we now have the required strings
  // remove old extra strings
  UData := XDataRemove(GetExtraField, [UPath_Data_Tag, UCmnt_Data_Tag]);
  newdata := Length(UData) <> ExtraFieldLength;
  if UName <> '' then
  begin
    uheader.tag := UPath_Data_Tag;
    uheader.totsiz := sizeof(TUString_Data_Header) + Length(UName) - (2 * sizeof(Word));
    uheader.version := 1;
    uheader.origcrc := CalcCRC32(NewHeaderName[1], length(NewHeaderName), 0);
    XDataAppend(UData, uheader, sizeof(uheader), UName[1], length(UName));
    newdata := True;
  end;

  if UComment <> '' then
  begin
    // append UComment
    uheader.tag := UCmnt_Data_Tag;
    uheader.totsiz := sizeof(TUString_Data_Header) + Length(UComment) -
      (2 * sizeof(Word));
    uheader.version := 1;
    uheader.origcrc := CalcCRC32(hcomment[1], length(hcomment), 0);
    XDataAppend(UData, uheader, sizeof(uheader), UComment[1], length(UComment));
    newdata := True;
  end;
  // will it fit?
  Result := -CD_CEHDataSize;
  xlen := Length(HeaderComment) + Length(NewHeaderName) + Length(UData);
  if xlen < MAX_WORD then
  begin                    
    // ok - make change
    fHeaderName  := NewHeaderName;
    fFileNameLen := Length(NewHeaderName);
    fHeaderComment := hcomment;
    fFileComLen := Length(hcomment);

    if newdata then
      ExtraField := UData;

    if NeedU8Bit then
      fFlag := fFlag or FLAG_UTF8_BIT
    else
      fFlag := fFlag and (not FLAG_UTF8_BIT);
    ClearCachedName;
    IsEncoded := zeoAuto;         // unknown
    need64 := (UncompressedSize >= MAX_UNSIGNED) or (CompressedSize >= MAX_UNSIGNED);
    // set versions to minimum required
    FVersionMadeBy := NewMadeFS;
    FixMinimumVers(need64);
    MarkDirty;
    Result := 0;
  end;
end;

 // 'fixes' the special Zip64  fields from extra data
 // return <0 error, 0 none, 1 Zip64
function TZMIRec.FixXData64: Integer;
var
  idx: Integer;
  p: PAnsiChar;
  wsz: Integer;
begin
  Result := 0;
  if (VersionNeeded and VerMask) < ZIP64_VER then
    exit;
  if not XData(FExtraField, Zip64_data_tag, idx, wsz) then
    Exit;
  p := @fExtraField[idx];
  Result := -DS_Zip64FieldError;  // new msg
  Inc(p, 4);  // past header
  Dec(wsz, 4);  // discount header
  if UncompressedSize = MAX_UNSIGNED then
  begin
    if wsz < 8 then
      exit;   // error
    UncompressedSize := pInt64(p)^;
    Inc(p, sizeof(Int64));
    Dec(wsz, sizeof(Int64));
  end;
  if CompressedSize = MAX_UNSIGNED then
  begin
    if wsz < 8 then
      exit;    // error
    CompressedSize := pInt64(p)^;
    Inc(p, sizeof(Int64));
    Dec(wsz, sizeof(Int64));
  end;
  if RelOffLocal = MAX_UNSIGNED then
  begin
    if wsz < 8 then
      exit;    // error
    RelOffLocal := pInt64(p)^;
    Inc(p, sizeof(Int64));
    Dec(wsz, sizeof(Int64));
  end;
  if DiskStart = MAX_WORD then
  begin
    if wsz < 4 then
      exit;   // error
    DiskStart := pCardinal(p)^;
  end;
  Result := 1;
end;

function TZMIRec.GetCompressedSize: Int64;
begin
  Result := fComprSize;
end;

function TZMIRec.GetCompressionMethod: Word;
begin
  Result := fComprMethod;
end;

function TZMIRec.GetCRC32: Cardinal;
begin
  Result := fCRC32;
end;

// will return empty if not exists or invalid
function TZMIRec.GetDataString(Cmnt: Boolean): UTF8String;
var
  crc: Cardinal;
  field: TZMRawBytes;
  idx: Integer;
  pH: PUString_Data_Header;
  pS: PAnsiChar;
  siz: Integer;
  tag: Word;
begin
  Result := '';
  if Cmnt then
  begin
    tag := UCmnt_Data_Tag;
    Field := HeaderComment;
    if field = '' then
      Exit; // no point checking
  end
  else
  begin
    tag := UPath_Data_Tag;
    field := HeaderName;
  end;
  if FindDataTag(tag, idx, siz) then
  begin
    pS := @ExtraField[idx];
    pH := PUString_Data_Header(pS);
    if pH^.version = 1 then
    begin
      crc := CalcCRC32(field[1], Length(field), 0);
      if pH^.origcrc = crc then
      begin
        siz := siz - sizeof(TUString_Data_Header);
        Inc(pS, sizeof(TUString_Data_Header));
        if (siz > 0) and (ValidUTF8(pS, siz) >= 0) then
        begin
          SetLength(Result, siz);
          move(pS^, Result[1], siz);
        end;
      end;
    end;
  end;
end;

function TZMIRec.GetDateTime: Cardinal;
begin
  Result := fModifDateTime;
end;

function TZMIRec.GetDirty: Boolean;
begin
  Result := TestStatusBit(zsbDirty);
end;

function TZMIRec.GetEncodeAs: TZMEncodingOpts;
begin
  Result := (Owner as TZMZipFile).EncodeAs;
end;

{
  Encoded as OEM for
    DOS (default)                       FS_FAT
    OS/2                                FS_HPFS
    Win95/NT with Nico Mak's WinZip     FS_NTFS && host = 5.0
  UTF8 is flag is set
  except (someone always has to be different)
    PKZIP (Win) 2.5, 2.6, 4.0 - mark as FS_FAT but local is Windows ANSI (1252)
    PKZIP (Unix) 2.51 - mark as FS_FAT but are current code page
}
function TZMIRec.GetEncoded: TZMEncodingOpts;
const
  WZIP = $0B32;//(FS_NTFS * 256) + 50;
  OS_HPFS = FS_HPFS * 256;
  OS_FAT = FS_FAT * 256;
begin
  Result := zeoNone;

  if (Flag and FLAG_UTF8_BIT) <> 0 then
    Result := zeoUTF8
  else
  if (GetDataString(false) <> '') or (GetDataString(True) <> '') then
    Result := zeoUPath
  else
  if ((VersionMadeBy and OSMask) = OS_FAT) or
      ((VersionMadeBy and OSMask) = OS_HPFS) or
      (VersionMadeBy = WZIP) then
    Result := zeoOEM;
end;


function TZMIRec.GetEncoding: TZMEncodingOpts;
begin
  Result := (Owner as TZMZipFile).Encoding;
end;

function TZMIRec.GetEncrypted: Boolean;
begin
  Result := (fFlag and 1) <> 0;
end;

function TZMIRec.GetExtFileAttrib: Longword;
begin
  Result := fExtFileAtt;
end;

// returns the 'data' without the tag
function TZMIRec.GetExtraData(Tag: Word): TZMRawBytes;
var
  i: Integer;
  sz: Integer;
  x: TZMRawBytes;
begin
  Result := '';
  x := GetExtraField;
  if XData(x, Tag, i, sz) then
    Result := Copy(x, i + 4, sz - 4);
end;

function TZMIRec.GetExtraField: TZMRawBytes;
begin
  Result := fExtraField;
end;

function TZMIRec.GetExtraFieldLength: Word;
begin
  Result := Length(fExtraField);
end;

function TZMIRec.GetFileComment: TZMString;
begin
  Result := Int2UTF(zrsComment, False);
end;

function TZMIRec.GetFileCommentLen: Word;
begin
  Result := Length(HeaderComment);
end;

 // returns the external filename interpretting the internal name by Encoding
 // still in internal form
function TZMIRec.GetFileName: TZMString;
begin
  if fFileName = '' then
    fFileName := Int2UTF(zrsName, False);
  Result := fFileName;
end;

function TZMIRec.GetFileNameLength: Word;
begin
  Result := Length(HeaderName);
end;

function TZMIRec.GetFlag: Word;
begin
  Result := fFlag;
end;

function TZMIRec.GetHash: Cardinal;
begin
  if not TestStatusBit(zsbHashed) then
  begin
    fHash := HashFunc(FileName);
    SetStatusBit(zsbHashed);
  end;
  Result := fHash;
end;

function TZMIRec.GetHeaderComment: TZMRawBytes;
begin
  Result := fHeaderComment;
end;

function TZMIRec.GetHeaderName: TZMRawBytes;
begin
  Result := fHeaderName;
end;

function TZMIRec.GetIntFileAttrib: Word;
begin
  Result := fIntFileAtt;
end;

function TZMIRec.GetIsEncoded: TZMEncodingOpts;
var
  n: Integer;
begin
  n := StatusBit[zsbEncMask] shr 16;
  if n > ord(zeoUPath) then
    n := 0;
  if n = 0 then
  begin
    // unknown - work it out and cache result
    Result := Encoded;
    SetIsEncoded(Result);
  end
  else
    Result := TZMEncodingOpts(n);
end;

function TZMIRec.GetRelOffLocalHdr: Int64;
begin
  Result := fRelOffLocal;
end;

function TZMIRec.GetSelected: Boolean;
begin
  Result := TestStatusBit(zsbSelected);
end;

function TZMIRec.GetStartOnDisk: Word;
begin
  Result := fDiskStart;
end;

function TZMIRec.GetStatusBit(Mask: Cardinal): Cardinal;
begin
  Result := StatusBits and mask;
end;

function TZMIRec.GetStatusBits: Cardinal;
begin
  Result := fStatusBits;
end;

function TZMIRec.GetUncompressedSize: Int64;
begin
  Result := fUnComprSize;
end;

function TZMIRec.GetVersionMadeBy: Word;
begin
  Result := FVersionMadeBy;
end;

function TZMIRec.GetVersionNeeded: Word;
begin
  Result := fVersionNeeded;
end;

function TZMIRec.HasChanges: Boolean;
begin
  Result := (StatusBits and zsbDirty) <> 0;
end;

function TZMIRec.Int2UTF(Field: TZMRecStrings; NoUD: Boolean = False):
    TZMString;
var
  Enc: TZMEncodingOpts;
  fld: TZMRawBytes;
begin
  if Field = zrsComment then
    fld := HeaderComment
  else
    fld := HeaderName;
  Result := '';
  Enc := Encoding;
  if Enc = zeoAuto then
  begin
    Enc := IsEncoded; // cached Encoded; // how entry is encoded
    if NoUD and (Enc = zeoUPath) then
      Enc := zeoOEM;  // use header Field
  end;
  if (Enc = zeoUPath) or StrHasExt(fld) then
  begin
{$IFDEF UNICODE} 
    case Enc of
      // use UTF8 extra data string if available
      zeoUPath: Result := UTF8ToWide(GetDataString(Field = zrsComment));
      zeoNone:  // treat as Ansi (from somewhere)
        Result := StrToUTFEx(fld, TZMZipFile(Owner).Encoding_CP, -1);
      zeoUTF8:    // treat Field as being UTF8
        Result := PUTF8ToWideStr(PAnsiChar(fld), Length(fld));
      zeoOEM:    // convert to OEM
        Result := StrToUTFEx(fld, CP_OEMCP, -1);
    end;
{$ELSE}
    if Owner.Worker.UseUtf8 then
    begin
      case Enc of
        // use UTF8 extra data string if available
        zeoUPath: Result := GetDataString(Field = zrsComment);
        zeoNone:  // treat as Ansi (from somewhere)
            Result := StrToUTFEx(fld, TZMZipFile(Owner).Encoding_CP, -1);
        zeoUTF8:    // treat Field as being UTF8
            Result := fld;
        zeoOEM:    // convert to OEM
            Result := StrToUTFEx(fld, CP_OEMCP, -1);
      end;
    end
    else
    begin
      case Enc of
        // use UTF8 extra data string if available
        zeoUPath: Result := UTF8ToSafe(GetDataString(Field = zrsComment), false);
        zeoNone:  // treat as Ansi (from somewhere)
            Result := StrToWideEx(fld, TZMZipFile(Owner).Encoding_CP, -1);  // will be converted
        zeoUTF8:    // treat Field as being UTF8
            Result := UTF8ToSafe(fld, false);
        zeoOEM:    // convert to OEM
            Result := StrToWideEx(fld, CP_OEMCP, -1);  // will be converted
      end;
    end;
{$ENDIF}
  end;
  if length(Result) = 0 then
    Result := String(fld); // better than nothing
  if Field = zrsName then
    Result := SetSlash(Result, psdExternal);
end;

// test for invalid characters
function IsInvalidIntName(const FName: TZMString): Boolean;
var
  c: Char;
  clen: Integer;
  i: Integer;
  len: Integer;
  n: Char;
  p: Char;
begin
  Result := True;
  len := Length(FName);
  if (len < 1) or (len >= MAX_PATH) then
    exit;                                   // empty or too long
  c := FName[1];
  if (c = PathDelim) or (c = '.') or (c = ' ') then
    exit;                                   // invalid from root or below
  i := 1;
  clen := 0;
  p := #0;
  while i <= len do
  begin
    Inc(clen);
    if clen > 255 then
      exit; // component too long
    c := FName[i];
    if i < len then
      n := FName[i + 1]
    else
      n := #0;
    case c of
      WILD_MULTI, DriveDelim, WILD_CHAR, '<', '>', '|', #0:
        exit;
      #1..#31:
        exit; // invalid
      PathDelimAlt:
      begin
        if p = ' ' then
          exit;   // bad - component has Trailing space
        if (n = c) or (n = '.') or (n = ' ') then
          exit; // \\ . leading space invalid
        clen := 0;
      end;
      '.':
      begin
        n := FName[succ(i)];
        if (n = PathDelim) or (n < ' ') then
          exit;
      end;
      ' ':
        if i = len then
          exit;   // invalid
    end;
    p := c;
    Inc(i);
  end;
  Result := False;
end;

procedure TZMIRec.AfterConstruction;
begin
  inherited;
  fStatusBits := 0;
end;

procedure TZMIRec.BeforeDestruction;
begin
  fExtraField := '';
  fHeaderName := '';
  fHeaderComment := '';
  inherited;
end;

function TZMIRec.IsZip64: Boolean;
begin
  Result := (UncompressedSize >= MAX_UNSIGNED) or
    (CompressedSize >= MAX_UNSIGNED) or
    (RelOffLocal >= MAX_UNSIGNED) or (DiskStart >= MAX_WORD);
end;

// also calculate required version and create extra data
function TZMIRec.LocalSize: Cardinal;
begin
  Result := SizeOf(TZipLocalHeader);
  PrepareLocalData;    // form local extra data
  Inc(Result, FileNameLength + Length(LocalData));
end;

procedure TZMIRec.MarkDirty;
begin
  SetStatusBit(zsbDirty);
end;

procedure TZMIRec.FixMinimumVers(z64: boolean);
const
  OS_FAT: Word = (FS_FAT * 256);
  WZIP = (FS_NTFS * 256) + 50;
var
  NewNeed: Word;
begin
  if ((VersionMadeBy and VerMask) <= ZIP64_VER) and
      ((VersionNeeded and VerMask) <= ZIP64_VER) then
  begin
//    Enc := IsEncoded;
    if z64 then
      VersionMadeBy := (VersionMadeBy and OSMask) or ZIP64_VER
    else
    if (VersionMadeBy and VerMask) = ZIP64_VER then
    begin
      // zip64 no longer needed
      VersionMadeBy := (VersionMadeBy and OSMask) or OUR_VEM;
    end;
    // correct bad encodings - marked ntfs should be fat
    if VersionMadeBy = WZIP then
        VersionMadeBy := OS_FAT or OUR_VEM;

    case ComprMethod of
      0: NewNeed := 10;    // stored
      1..8: NewNeed := 20;
      9: NewNeed := 21;   // enhanced deflate
      10: NewNeed := 25;  // DCL
      12: NewNeed := 46;  // BZip2
    else
      NewNeed := ZIP64_VER;
    end;
    if ((Flag and 32) <> 0) and (NewNeed < 27) then
      NewNeed := 27;
    if z64 and (NewNeed < ZIP64_VER) then
      NewNeed := ZIP64_VER;
    // keep needed os
    VersionNeeded := (VersionNeeded and OSMask) + NewNeed;
  end;
end;

// process the record (base type does nothing)
// returns bytes written, <0 _ error
function TZMIRec.Process: Int64;
begin
  Result := 0;  // default, nothing done
end;

// size of data to process - excludes central directory (virtual)
function TZMIRec.ProcessSize: Int64;
begin
  Result := 0;// default nothing to process
end;

(*? TZMIRec.Read
  Reads directory entry
  returns
  >=0 = ok   (1 = Zip64)
  <0 = -error
*)
function TZMIRec.Read(wf: TZMWorkFile): Integer;
var
  CH: TZipCentralHeader;
  ExtraLen: Word;
  n: TZMRawBytes;
  r: Integer;
  v: Integer;
begin
  StatusBits := zsbInvalid;
  //  Diag('read central' );
  r := wf.Reads(CH, ZipCenRecFields);
  if r <> SizeOf(TZipCentralHeader) then
  begin
    Result := -DS_CEHBadRead;
    exit;
  end;
  if CH.HeaderSig <> CentralFileHeaderSig then
  begin
    Result := -DS_CEHWrongSig;
    exit;
  end;
  VersionMadeBy := CH.VersionMadeBy;
  VersionNeeded := CH.VersionNeeded;
  Flag := CH.Flag;
  ComprMethod := CH.ComprMethod;
  ModifDateTime := CH.ModifDateTime;
  CRC32 := CH.CRC32;
  FileNameLength := CH.FileNameLen;
  ExtraLen := CH.ExtraLen;
  FileCommentLen := CH.FileComLen;
  DiskStart := CH.DiskStart;
  IntFileAttrib := CH.IntFileAtt;
  ExtFileAttrib := CH.ExtFileAtt;
  RelOffLocal := CH.RelOffLocal;
  CompressedSize := CH.ComprSize;
  UncompressedSize := CH.UncomprSize;
  // read variable length fields
  v := FileNameLen + ExtraLen + FileComLen;
  SetLength(n, v);
  r := wf.Reads(n[1], [FileNameLen, ExtraLen, FileComLen]);
  if r <> v then
  begin
    Result := -DS_CECommentLen;
    if r < FileNameLen then
      Result := -DS_CENameLen
    else
    if r < (FileNameLen + ExtraLen) then
      Result := -LI_ReadZipError;
    exit;
  end;
  if FileComLen > 0 then
    fHeaderComment := copy(n, FileNameLen + ExtraLen + 1, FileComLen);
  if ExtraLen > 0 then
    fExtraField := copy(n, FileNameLen + 1, ExtraLen);
  SetLength(n, FileNameLen);
  fHeaderName := n;
  fOrigHeaderName := n;
  ClearStatusBit(zsbInvalid);   // record is valid
  if n[Length(n)] = PathDelimAlt then
    SetStatusBit(zsbDirOnly);   // dir only entry
  Result := FixXData64;
end;

procedure TZMIRec.PrepareLocalData;
var
  xd: Txdat64;
  Need64: Boolean;
begin
  LocalData := '';  // empty
  ClearStatusBit(zsbLocal64);
  // check for Zip64
  Need64 := (UncompressedSize >= MAX_UNSIGNED) or (CompressedSize >= MAX_UNSIGNED);
  FixMinimumVers(Need64);
  if Need64 then
  begin
    SetStatusBit(zsbLocal64);
    xd.tag := Zip64_data_tag;
    xd.siz := 16;
    xd.vals[0] := UncompressedSize;
    xd.vals[1] := CompressedSize;
    SetLength(fLocalData, 20);
    Move(xd.tag, PAnsiChar(LocalData)^, 20);
  end;
  // remove unwanted 'old' tags
  if ExtraFieldLength > 0 then
    LocalData := LocalData + XDataRemove(ExtraField,
      [Zip64_data_tag, Ntfs_data_tag, UCmnt_Data_Tag]);
  SetStatusBit(zsbLocalDone);
end;

function TZMIRec.SafeHeaderName(const IntName: TZMString): TZMString;
const
  BadChars : TSysCharSet = [#0..#31, ':', '<', '>', '|', '*', '?', #39, '\'];
var
  c: Char;
  i: integer;
Begin
  Result := '';
  for i := 1 to Length(IntName) do
  begin
    c := IntName[i];
    if (c <= #255) and (AnsiChar(c) in BadChars) then
    begin
      if c = '\' then
        Result := Result + PathDelimAlt
      else
        Result := Result + '#$' + IntToHex(Ord(c),2);
    end
    else
      Result := Result + c;
  end;
end;

function TZMIRec.SeekLocalData: Integer;
const
  // no signature
  LOHFlds: array [0..9] of Integer = (2, 2, 2, 2, 2, 4, 4, 4, 2, 2);
var
  did: Int64;
  i: Integer;
  InWorkFile: TZMWorkFile;
  LOH: TZipLocalHeader;
  t: Integer;
  v: TZMRawBytes;
begin
  ASSERT(assigned(Owner), 'no owner');
  InWorkFile := Owner;
  //  Diag('Seeking local');
  Result := -DS_FileOpen;
  if not InWorkFile.IsOpen then
    exit;
  Result := -DS_LOHBadRead;
  try
    InWorkFile.SeekDisk(DiskStart);
    InWorkFile.Position := RelOffLocal;
    did := InWorkFile.Read(LOH, 4);
    if (did = 4) and (LOH.HeaderSig = LocalFileHeaderSig) then
    begin         // was local header
      did := InWorkFile.Reads(LOH.VersionNeeded, LOHFlds);
      if did = (sizeof(TZipLocalHeader) - 4) then
      begin
        if LOH.FileNameLen = Length(OrigHeaderName) then
        begin
          t := LOH.FileNameLen + LOH.ExtraLen;
          SetLength(v, t);
          did := InWorkFile.Reads(v[1], [LOH.FileNameLen, LOH.ExtraLen]);
          if (did = t) then
          begin
            Result := 0;
            for i := 1 to LOH.FileNameLen do
            begin
              if v[i] <> OrigHeaderName[i] then
              begin
                Result := -DS_LOHWrongName;
                break;
              end;
            end;
          end;
        end;
        v := '';
      end;
    end;
    if Result = -DS_LOHBadRead then
      Diag('could not read local header: ' + FileName);
  except
    on E: EZipMaster do
    begin
      Result := -E.ResId;
      exit;
    end;
    on E: Exception do
    begin
      Result := -DS_UnknownError;
      exit;
    end;
  end;
end;

// returns the new value
function TZMIRec.Select(How: TZipSelects): Boolean;
begin
  case How of
    zzsClear:
      Result := False;
    zzsSet:
      Result := True;
//    zzsToggle:
    else
      Result := not TestStatusBit(zsbSelected);
  end;
  SetSelected(Result);
end;

procedure TZMIRec.SetDateStamp(Value: TDateTime);
begin
  DateTimeToFileDate(Value);
end;

procedure TZMIRec.SetEncrypted(const Value: Boolean);
begin
  if Value then
    Flag := Flag or 1
  else
    Flag := Flag and $FFFE;
end;

// assumes data contains the data with no header
procedure TZMIRec.SetExtraData(Tag: Word; const data: TZMRawBytes);
var
  after: Integer;
  afterLen: integer;
  nidx: Integer;
  ix: Integer;
  newXData: TZMRawBytes;
  dataSize: Word;
  sz: Integer;
  v: Integer;
  x: TZMRawBytes;
begin
  x := GetExtraField;
  XData(x, Tag, ix, sz); // find existing Tag
  v := Length(x) - sz;   // size after old tag removed
  if Length(data) > 0 then
    v := v + Length(data) + 4;
  if v > MAX_WORD then     // new length too big?
    exit;     // maybe give error
  dataSize := Length(data);
  SetLength(newXData, v);
  nidx := 1;  // next index into newXData
  if (dataSize > 0) then
  begin
    // prefix required tag
    newXData[1] := AnsiChar(Tag and MAX_BYTE);
    newXData[2] := AnsiChar(Tag shr 8);
    newXData[3] := AnsiChar(dataSize and MAX_BYTE);
    newXData[4] := AnsiChar(dataSize shr 8);
    // add the data
    Move(data[1], newXData[5], dataSize);
    Inc(nidx, dataSize + 4);
  end;
  if ix >= 1 then
  begin
    // had existing data
    if ix > 1 then
    begin
      // append data from before existing tag
      Move(x[1], newXData[nidx], ix - 1);
      Inc(nidx, ix);
    end;
    after := ix + sz; // index after replaced tag
    if after < Length(x) then
    begin
      // append data from after existing
      afterLen := Length(x) + 1 - after;
      Move(x[after], newXData[nidx], afterLen);
    end;
  end
  else
  begin
    // did not exist
    if Length(x) > 0 then
      Move(x[1], newXData[nidx], Length(x)); // append old extra data
  end;
  ExtraField := newXData;
end;

procedure TZMIRec.SetIsEncoded(const Value: TZMEncodingOpts);
var
  n: Integer;
begin
  n := Ord(Value) shl 16;
  ClearStatusBit(zsbEncMask); // clear all
  SetStatusBit(n);            // set new value
end;

procedure TZMIRec.SetSelected(const Value: Boolean);
begin
  if Selected <> Value then
  begin
    if Value then
      SetStatusBit(zsbSelected)
    else
    begin
      ClearStatusBit(zsbSelected);
      SelectArgs := '';
    end;
  end;
end;

function TZMIRec.SetStatusBit(const Value: Cardinal): Cardinal;
begin
  StatusBits := StatusBits or Value;
  Result := StatusBits;
end;

function TZMIRec.StrToSafe(const aString: TZMString; ToOem: boolean):
    AnsiString;
begin
{$IFDEF UNICODE}
  Result := WideToSafe(aString, ToOem);
{$ELSE}
  if Owner.Worker.UseUTF8 then
    Result := UTF8ToSafe(aString, ToOem)
  else
    Result := WideToSafe(aString, ToOem);
{$ENDIF}
end;

// converts to internal delimiter
function TZMIRec.StripDrive(const FName: TZMString; NoPath: Boolean): TZMString;
var
  nam: Integer;
  posn: Integer;
begin
  Result := SetSlash(FName, psdExternal);
  // Remove drive: or //host/share
  posn := 0;
  if length(Result) > 1 then
  begin
    if Result[1] = ':' then
    begin
      posn := 2;
      if (Length(Result) > 2) and (Result[3] = PathDelim{Alt}) then
        posn := 3;
    end
    else
    if (Result[1] = PathDelimAlt) and (Result[2] = PathDelim{Alt}) then
    begin
      posn := 3;
      while (posn < Length(Result)) and (Result[posn] <> PathDelim{Alt}) do
        Inc(posn);
      Inc(posn);
      while (posn < Length(Result)) and (Result[posn] <> PathDelimAlt) do
        Inc(posn);
      if posn >= Length(Result) then
      begin
        // error - invalid host/share
        Diag('Invalid filespec: ' + Result);
        Result := '';
        exit;// { TODO : handle error }
      end;
    end;
  end;
  Inc(posn);
  // remove leading ./
  if ((posn + 1) < Length(Result)) and (Result[posn] = '.') and
    (Result[posn + 1] = PathDelim) then
    posn := posn + 2;
  // remove path if not wanted
  if NoPath then
  begin
    nam := LastPos(Result, PathDelim);
    if nam > posn then
      posn := nam + 1;
  end;
  Result := Copy(Result, posn, MAX_PATH);
end;

function TZMIRec.StrToHeader(const aString: TZMString; how: THowToEnc):
    TZMRawBytes;
begin
{$IFDEF UNICODE}
  if how = hteUTF8 then
    Result  := TZMRawBytes(WideToUTF8(aString, -1))
  else
    Result  := TZMRawBytes(WideToSafe(aString, how = hteOEM));
{$ELSE}
  if Owner.Worker.UseUTF8 then
  begin
    if how = hteUTF8 then
      Result  := TZMRawBytes(aString)
    else
      Result  := TZMRawBytes(WideToSafe(UTF8ToWide(aString), how = hteOEM));
  end
  else
  begin
    case how of
      hteOEM: Result := TZMRawBytes(StrToOEM(aString));
      hteAnsi: Result := TZMRawBytes(aString);
      hteUTF8: Result := TZMRawBytes(StrToUTF8(aString));
    end;
  end;
{$ENDIF}
end;

function TZMIRec.StrToUTF8Header(const aString: TZMString): TZMRawBytes;
begin
{$IFDEF UNICODE}
  Result := UTF8String(aString);
{$ELSE}
  if Owner.Worker.UseUtf8 then
    Result := AsUTF8Str(aString) // make sure UTF8
  else
    Result  := StrToUTF8(aString);
{$ENDIF}
end;

function TZMIRec.StrTo_UTF8(const aString: TZMString): UTF8String;
begin
{$IFDEF UNICODE}
  Result := UTF8String(aString);
{$ELSE}
  if Owner.Worker.UseUtf8 then
    Result := AsUTF8Str(aString) // make sure UTF8
  else
    Result  := StrToUTF8(aString);
{$ENDIF}
end;

function TZMIRec.TestStatusBit(const mask: Cardinal): Boolean;
begin
  Result := (StatusBits and mask) <> 0;
end;

function TZMIRec.ToIntForm(const nname: TZMString; var iname: TZMString):
    Integer;
var
  temp: TZMString;
begin
  Result := 0;
  iname := StripDrive(nname, not (AddDirNames in Owner.Worker.AddOptions));
  // truncate if too long
  if Length(iname) > MAX_PATH then
  begin
    temp := iname;
    SetLength(iname, MAX_PATH);
    Diag('Truncated ' + temp + ' to ' + iname);
  end;
  if IsInvalidIntName(iname) then
    Result := -AD_BadFileName;
end;

 // write the central entry on it's owner
 // return bytes written (< 0 = -Error)
function TZMIRec.Write: Integer;
var
  CH: PZipCentralHeader;
  l: Integer;
  Need64: Boolean;
  ni: TZMRawBytes;
  p: pByte;
  pb: pByte;
  r: Integer;
  siz: Word;
  vals: array [0..4] of Int64;
  wf: TZMWorkFile;
  x: TZMRawBytes;
begin
  wf := Owner;
  ASSERT(assigned(wf), 'no WorkFile');
  //  Diag('Write central');
  Result := -1;
  if not wf.IsOpen then
    exit;
  fOrigHeaderName := HeaderName;  // might have changed
  pb := wf.WBuffer(sizeof(TZipCentralHeader));
  CH := PZipCentralHeader(pb);
  ni := HeaderName;
  CH^.HeaderSig := CentralFileHeaderSig;
  CH^.VersionMadeBy := VersionMadeBy;
  CH^.VersionNeeded := VersionNeeded;  // assumes local was written - may be updated
  CH^.Flag := Flag;
  CH^.ComprMethod := ComprMethod;
  CH^.ModifDateTime := ModifDateTime;
  CH^.CRC32 := CRC32;
  CH^.FileNameLen := length(ni);
  CH^.FileComLen := Length(HeaderComment);
  CH^.IntFileAtt := IntFileAttrib;
  CH^.ExtFileAtt := ExtFileAttrib;

  siz := 0;
  if (UncompressedSize >= MAX_UNSIGNED) then
  begin
    vals[0] := UncompressedSize;
    siz := 8;
    CH^.UncomprSize := MAX_UNSIGNED;
  end
  else
    CH^.UncomprSize := Cardinal(UncompressedSize);

  if (CompressedSize >= MAX_UNSIGNED) then
  begin
    vals[siz div 8] := CompressedSize;
    Inc(siz, 8);
    CH^.ComprSize := MAX_UNSIGNED;
  end
  else
    CH^.ComprSize := Cardinal(CompressedSize);

  if (RelOffLocal >= MAX_UNSIGNED) then
  begin
    vals[siz div 8] := RelOffLocal;
    Inc(siz, 8);
    CH^.RelOffLocal := MAX_UNSIGNED;
  end
  else
    CH^.RelOffLocal := Cardinal(RelOffLocal);

  if (DiskStart >= MAX_WORD) then
  begin
    vals[siz div 8] := DiskStart;
    Inc(siz, 4);
    CH^.DiskStart := MAX_WORD;
  end
  else
    CH^.DiskStart := Word(DiskStart);
  Need64 := False;
  if siz > 0 then
  begin
    SetLength(x, siz);
    move(vals[0], x[1], siz);
    Need64 := True;
    if (VersionNeeded and MAX_BYTE) < ZIP64_VER then
    begin
      FixMinimumVers(True);
      CH^.VersionNeeded := VersionNeeded;
      CH^.VersionMadeBy := VersionMadeBy;
    end;
    ExtraData[Zip64_data_tag] := x;
  end
  else
    ExtraData[Zip64_data_tag] := ''; // remove old 64 data
  if (StatusBit[zsbLocalDone] = 0) or (Need64) then
    FixMinimumVers(Need64);
  CH^.VersionMadeBy := VersionMadeBy;
  CH^.VersionNeeded := VersionNeeded;
  x := '';
  CH^.ExtraLen := ExtraFieldLength;
  Result := -DS_CEHBadWrite;
  l  := sizeof(TZipCentralHeader) + CH^.FileNameLen + CH^.ExtraLen +
    CH^.FileComLen;
  pb := wf.WBuffer(l);
  p  := pb;
  Inc(p, sizeof(TZipCentralHeader));
  move(ni[1], p^, CH^.FileNameLen);
  Inc(p, CH^.FileNameLen);
  if CH^.ExtraLen > 0 then
  begin
    move(ExtraField[1], p^, CH^.ExtraLen);
    Inc(p, CH^.ExtraLen);
  end;
  if CH^.FileComLen > 0 then
    move(HeaderComment[1], p^, CH^.FileComLen);
  r := wf.Write(pb^, -l);
  if r = l then
  begin
    //    Diag('  Write central ok');
    Result := r;
    ClearStatusBit(zsbDirty);
  end//;
  else
  if r < 0 then
    Result := r;
end;

function TZMIRec.WriteAsLocal: Integer;
begin
  Result := WriteAsLocal1(ModifDateTime, CRC32);
end;

// write local header using specified stamp and crc
// return bytes written (< 0 = -Error)
function TZMIRec.WriteAsLocal1(Stamp, crc: Cardinal): Integer;
var
  cd: TZMRawBytes;
  fnlen: Integer;
  i: Integer;
  LOH: PZipLocalHeader;
  need64: Boolean;
  ni: TZMRawBytes;
  p: pByte;
  pb: pByte;
  t: Integer;
  wf: TZMWorkFile;
begin
  wf := Owner;
  ASSERT(assigned(wf), 'no WorkFile');
  if StatusBit[zsbLocalDone] = 0 then
    PrepareLocalData;
  LOH := PZipLocalHeader(wf.WBuffer(sizeof(TZipLocalHeader)));
  if ((Flag and 9) = 8) then
    Flag := Flag and $FFF7; // remove extended local data if not encrypted
  ni := HeaderName;
  fnlen := length(ni);
  LOH^.HeaderSig := LocalFileHeaderSig;
  LOH^.VersionNeeded := VersionNeeded;   // may be updated
  LOH^.Flag := Flag;
  LOH^.ComprMethod := ComprMethod;
  LOH^.ModifDateTime := Stamp;
  LOH^.CRC32 := crc;
  LOH^.FileNameLen := fnlen;
  cd := LocalData;
  LOH^.ExtraLen := Length(cd); // created by LocalSize
  need64 := (LOH^.ExtraLen > 0) and (StatusBit[zsbLocal64] <> 0);
  if need64 then
  begin
    LOH^.UnComprSize := MAX_UNSIGNED;
    LOH^.ComprSize := MAX_UNSIGNED;
  end
  else
  begin
    if (Flag and 8) <> 0 then
    begin
      LOH^.UnComprSize := 0;
      LOH^.ComprSize := 0;
      if (VersionNeeded and MAX_BYTE) < ZIP64_VER then
      begin
        FixMinimumVers(True);
        LOH^.VersionNeeded := VersionNeeded;
      end;
    end
    else
    begin
      LOH^.UnComprSize := Cardinal(UncompressedSize);
      LOH^.ComprSize := Cardinal(CompressedSize);
    end;
  end;
  t := fnlen + Length(cd);
  pb := wf.WBuffer(sizeof(TZipLocalHeader) + t);
  p  := pb;
  Inc(p, sizeof(TZipLocalHeader));
  i := Sizeof(TZipLocalHeader);  // i = destination index
  Move(ni[1], p^, fnlen);
  i := i + fnlen;
  Inc(p, fnlen);
  // copy any extra data
  if Length(cd) > 0 then
  begin
    Move(cd[1], p^, Length(cd));
    Inc(i, Length(cd));
  end;
  Result := wf.Write(pb^, -i);  // must fit
  if Result = i then
    ClearStatusBit(zsbDirty)
  else
    Result := -DS_LOHBadWrite;
end;

// return bytes written (< 0 = -Error)
function TZMIRec.WriteDataDesc(OutZip: TZMWorkFile): Integer;
var
  d: TZipDataDescriptor;
  d64: TZipDataDescriptor64;
  r: Integer;
begin
  ASSERT(assigned(OutZip), 'no WorkFile');
  if (Flag and 8) <> 0 then
  begin
    Result := 0;
    exit;
  end;
  Result := -DS_DataDesc;
  if (VersionNeeded and MAX_BYTE) < ZIP64_VER then
  begin
    d.DataDescSig := ExtLocalSig;
    d.CRC32 := CRC32;
    d.ComprSize := Cardinal(CompressedSize);
    d.UnComprSize := Cardinal(UncompressedSize);
    r := OutZip.Write(d, -sizeof(TZipDataDescriptor));
    if r = sizeof(TZipDataDescriptor) then
      Result := r;
  end
  else
  begin
    d64.DataDescSig := ExtLocalSig;
    d64.CRC32 := CRC32;
    d64.ComprSize := CompressedSize;
    d64.UnComprSize := UncompressedSize;
    r := OutZip.Write(d64, -sizeof(TZipDataDescriptor64));
    if r = sizeof(TZipDataDescriptor64) then
      Result := r;
  end;
end;

// Return true if found
// if found return idx --> tag, size = tag + data
function XData(const x: TZMRawBytes; Tag: Word; var idx, size: Integer):
    Boolean;
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
  while i < l - 4 do
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

function XData_HasTag(tag: Integer; const tags: array of Integer): Boolean;
var
  ii: Integer;
begin
  Result := False;
  for ii := 0 to HIGH(tags) do
    if tags[ii] = tag then
    begin
      Result := True;
      break;
    end;
end;

function XDataAppend(var x: TZMRawBytes; const src1; siz1: Integer; const src2;
    siz2: Integer): Integer;
var
  newlen: Integer;
begin
  Result := Length(x);
  if (siz1 < 0) or (siz2 < 0) then
    exit;
  newlen := Result + siz1 + siz2;
  SetLength(x, newlen);
  Move(src1, x[Result + 1], siz1);
  Result := Result + siz1;
  if siz2 > 0 then
  begin
    Move(src2, x[Result + 1], siz2);
    Result := Result + siz2;
  end;
end;

function XDataKeep(const x: TZMRawBytes; const tags: array of Integer):
    TZMRawBytes;
var
  di: Integer;
  i: Integer;
  l: Integer;
  siz: Integer;
  wsz: Word;
  wtg: Word;
begin
  Result := '';
  siz := 0;
  l := Length(x);
  if l < 4 then
    exit;  // invalid
  i := 1;
  while i <= l - 4 do
  begin
    wtg := pWord(@x[i])^;
    wsz := pWord(@x[i + 2])^;
    if (XData_HasTag(wtg, tags)) and ((i + wsz + 4) <= l + 1) then
    begin
      Inc(siz, wsz + 4);
    end;
    i := i + wsz + 4;
  end;
  SetLength(Result, siz);
  di := 1;
  i  := 1;
  while i <= l - 4 do
  begin
    wtg := pWord(@x[i])^;
    wsz := pWord(@x[i + 2])^;
    if (XData_HasTag(wtg, tags)) and ((i + wsz + 4) <= l + 1) then
    begin
      wsz := wsz + 4;
      while wsz > 0 do
      begin
        Result[di] := x[i];
        Inc(di);
        Inc(i);
        Dec(wsz);
      end;
    end
    else
      i := i + wsz + 4;
  end;
end;


function XDataRemove(const x: TZMRawBytes; const tags: array of Integer):
    TZMRawBytes;
var
  di: Integer;
  i: Integer;
  l: Integer;
  siz: Integer;
  wsz: Word;
  wtg: Word;
begin
  Result := '';
  siz := 0;
  l := Length(x);
  if l < 4 then
    exit;  // invalid
  i := 1;
  while i <= l - 4 do
  begin
    wtg := pWord(@x[i])^;
    wsz := pWord(@x[i + 2])^;
    if (not XData_HasTag(wtg, tags)) and ((i + wsz + 4) <= l + 1) then
    begin
      Inc(siz, wsz + 4);
    end;
    i := i + wsz + 4;
  end;
  SetLength(Result, siz);
  di := 1;
  i  := 1;
  while i <= l - 4 do
  begin
    wtg := pWord(@x[i])^;
    wsz := pWord(@x[i + 2])^;
    if (not XData_HasTag(wtg, tags)) and ((i + wsz + 4) <= l + 1) then
    begin
      wsz := wsz + 4;
      while wsz > 0 do
      begin
        Result[di] := x[i];
        Inc(di);
        Inc(i);
        Dec(wsz);
      end;
    end
    else
      i := i + wsz + 4;
  end;
end;

end.
