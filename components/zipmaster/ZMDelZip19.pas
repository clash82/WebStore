unit ZMDelZip19;

(*
  ZMDelZip19.pas - port of DelZip.h (dll interface)
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
************************************************************************)

interface

uses Windows;

(* zacArg - return string
   Arg1 = argument
     0 = filename
     1 = password
     2 = RootDir
     3 = ExtractDir
     4 = FSpecArgs      Arg3 = index
     5 = FSpecArgsExcl  Arg3 = index
*)

type
  TActionCodes = (zacTick, zacItem, zacProgress, zacEndOfBatch,
    zacCount, zacSize, zacXItem, zacXProgress, zacMessage,
    zacNewName, zacPassword, zacCRCError, zacOverwrite, zacSkipped,
    zacComment, zacData, zacExtName, zacNone,
    zacKey, zacArg, zacWinErr);

  TCBArgs = (zcbFilename, zcbPassword, zcbRootDir, zcbExtractDir, zcbComment,
    zcbFSpecArgs, zcbFSpecArgsExcl, zcbSpecials, zcbTempPath);

  TZStreamActions = (zsaIdentify, zsaCreate, zsaClose, zsaPosition, zsaRead,
    zsaWrite);

//// structure used to 'identify' streams
//type
//   PZSStrats = ^TZSStats;
//   TZSStats = Packed Record
//      Size: int64;
//      Date: cardinal;
//      Attrs: cardinal;
//   end;

const
//  Callback_Except_No = 10106;
  ZCallBack_Check = $0707;
  ZStream_Check = $070B;

    { All the items in the CallBackStruct are passed to the Delphi
      program from the DLL.  Note that the "Caller" value returned
      here is the same one specified earlier in ZipParms by the
      Delphi pgm. }
type
  TZCallBackStruct = packed record
    Caller:  Pointer;         // "self" reference of the Delphi form }
    Version: Longint;         // version no. of DLL }
    IsOperationZip: Longbool; // True=zip, False=unzip }
    ActionCode: integer;
    HaveWide: integer;        // wide string passed
    MsgP: pByte;              // pointer to text/data or stream src/dst
    Msg2P: pByte;             // orig file comment
    File_Size: Int64;         // file size or stream position offset
    Written: Int64;
    Arg1: cardinal;
    Arg2: cardinal;
    Arg3: integer;            // 'older', stream cnt or from
    Check: cardinal;
  end;
  PZCallBackStruct = ^TZCallBackStruct;

//ALL interface structures BYTE ALIGNED
(* stream operation arg usage
   zacStIdentify,
//      IN BufP = name
      IN Number = number
     OUT ArgLL = size, ArgD = Date, ArgA = Attrs
   zacStCreate,
//      IN BufP = name
      IN Number = number
     OUT StrmP = stream
   zacStClose,
      IN Number = number
      IN StrmP = stream
     OUT StrmP = stream (= NULL)
   zacStPosition,
      IN Number = number
      IN StrmP = stream, ArgLL = offset, ArgI = from
     OUT ArgLL = position
   zacStRead,
      IN Number = number
      IN StrmP = stream, BufP = buf, ArgI = count
     OUT ArgI = bytes read
   zacStWrite
      IN Number = number
      IN StrmP = stream, BufP = buf, ArgI = count
     OUT ArgI = bytes written
*)
type
  TZStreamRec = packed record
    Caller:  Pointer;         // "self" reference of the Delphi form }
    Version: Longint;         // version no. of DLL }
    StrmP: pointer;           // pointer to 'tstream'
    Number: Integer;
    OpCode: integer;          // TZStreamActions
    BufP: pByte;              // pointer to stream src/dst or identifier
    ArgLL: Int64;             // file size or stream position offset
    ArgI: integer;            // stream cnt or from
    ArgD: cardinal;           // date
    ArgA: cardinal;           // attribs
    Check: cardinal;          // ZStream_Check;
  end;
  PZStreamRec = ^TZStreamRec;


(* Declare a function pointer type for the BCB/Delphi callback function, to
 * be called by the DLL to pass updated status info back to BCB/Delphi.*)
type
  TZFunctionPtrType = function(ZCallbackRec: PZCallBackStruct): Longint; STDCALL;

  TZStreamFunctionPtrType = function(ZStreamRec: PZStreamRec): Longint; STDCALL;
                  
type
  PZSSArgs = ^TZSSArgs;
  TZSSArgs = packed record     // used stream-stream
    Method: Cardinal;         // low word = method, hi word nz=encrypt
    CRC: cardinal;            // IN init encrypt crc OUT crc
    Size: Int64;
    fSSInput: pointer;
    fSSOutput: pointer;
  end;

 (* These records are very critical.  Any changes in the order of items, the
    size of items, or modifying the number of items, may have disasterous
    results.  You have been warned! *)
const    
  DLLCOMMANDCHECK = $03070505;
  DLL_OPT_OpIsZip           = $0000001;
  DLL_OPT_OpIsDelete        = $0000002; // delete - not used?
  DLL_OPT_OpIsUnz           = $0000004;
  DLL_OPT_OpIsTest          = $0000008;
  DLL_OPT_CanWide           = $0000010;
  DLL_OPT_Quiet             = $0000020;
//  DLL_OPT_NoSkip            = $0000040; // skipping is fatal
  DLL_OPT_Update            = $0000080;
  DLL_OPT_Freshen           = $0000100;
  DLL_OPT_Directories       = $0000200; // extract directories
  DLL_OPT_Overwrite         = $0000400; // overwrite all
  DLL_OPT_NoDirEntries      = $0000800;
  DLL_OPT_JunkDir           = $0001000;
  DLL_OPT_Recurse           = $0002000;
  DLL_OPT_Grow              = $0004000;
//  DLL_OPT_Force             = $0008000; // Force to DOS 8.3
  DLL_OPT_Move              = $0010000;
  DLL_OPT_System            = $0020000;
  DLL_OPT_JunkSFX           = $0040000; // remove sfx stub
  DLL_OPT_LatestTime        = $0080000; // set zip to latest file
  DLL_OPT_ArchiveFilesOnly  = $0100000; // zip when archive bit set
  DLL_OPT_ResetArchiveBit   = $0200000; // reset the archive bit after successfull zip
  DLL_OPT_Versioning        = $0400000; // rename old version instead of replace
  DLL_OPT_HowToMove         = $0800000;
  DLL_OPT_NoPrecalc         = $1000000; // don't precalc crc when encrypt
  DLL_OPT_Encrypt           = $2000000; // General encrypt, if not superseded
  DLL_OPT_Volume            = $4000000;
  DLL_OPT_NTFSStamps        = $8000000; // Generate or use NTFS time stamps

type
  TDLLCommands = packed record
    fHandle: HWND;
    fCaller: Pointer;
    fVersion: Longint;
    ZCallbackFunc: TZFunctionPtrType;
    ZStreamFunc: TZStreamFunctionPtrType;
    fVerbosity: integer; 
    fEncodedAs: Cardinal;		// Assume name encoded as (auto, raw, utf8, oem)
    fSS: PZSSArgs;         // used stream-stream   
    fFromPage: cardinal;      // country to use
    fOptions: cardinal;   // DLL_OPT_?
    fPwdReqCount: cardinal; 
    fEncodeAs: cardinal;    // encode names as 
    fLevel: integer;                 
    // General Date, if not superseded by FileData.fDate
    fDate: cardinal;    
    fNotUsed: array[0..3] of Cardinal;
    fCheck: cardinal;
  end;
  pDLLCommands = ^TDLLCommands;

  const
  ZPasswordFollows = '<';
  ZSwitchFollows = '|';
  ZForceNoRecurse = '|'; // leading
  ZForceRecurse = '>'; // leading

type
  TDLLExecFunc = function(Rec: pDLLCommands): Integer; STDCALL;
  TDLLVersionFunc = function: Integer; STDCALL;
  TDLLPrivVersionFunc = function: Integer; STDCALL;
  TAbortOperationFunc = function(Rec: Cardinal): Integer; STDCALL;
  TDLLPathFunc = function: pAnsiChar; STDCALL;
  TDLLBannerFunc = function: PAnsiChar; STDCALL;
  TDLLNameFunc = function(var buf; bufsiz: integer; wide: boolean): integer; STDCALL;

const
  _DZ_ERR_GOOD   = 0; // ZEN_OK
  _DZ_ERR_CANCELLED  = 1;
  _DZ_ERR_ABORT   = 2;
  _DZ_ERR_CALLBACK  = 3;
  _DZ_ERR_MEMORY   = 4;
  _DZ_ERR_STRUCT   = 5;
  _DZ_ERR_ERROR   = 6;
  _DZ_ERR_PASSWORD_FAIL  = 7;
  _DZ_ERR_PASSWORD_CANCEL = 8;
  _DZ_ERR_INVAL_ZIP      = 9 ; // ZEN_FORM
  _DZ_ERR_NO_CENTRAL     = 10;  // UEN_EOF01
  _DZ_ERR_ZIP_EOF        = 11;  // ZEN_EOF
  _DZ_ERR_ZIP_END        = 12;  // UEN_EOF02
  _DZ_ERR_ZIP_NOOPEN     = 13;
  _DZ_ERR_ZIP_MULTI      = 14;
  _DZ_ERR_NOT_FOUND      = 15;
  _DZ_ERR_LOGIC_ERROR    = 16;  // ZEN_LOGIC
  _DZ_ERR_NOTHING_TO_DO  = 17;  // ZEN_NONE
  _DZ_ERR_BAD_OPTIONS    = 18;  // ZEN_PARM
  _DZ_ERR_TEMP_FAILED    = 19;  // ZEN_TEMP
  _DZ_ERR_NO_FILE_OPEN   = 20;  // ZEN_OPEN
  _DZ_ERR_ERROR_READ     = 21;  // ZEN_READ
  _DZ_ERR_ERROR_CREATE   = 22;  // ZEN_CREAT
  _DZ_ERR_ERROR_WRITE    = 23;  // ZEN_WRITE
  _DZ_ERR_ERROR_SEEK     = 24;
  _DZ_ERR_EMPTY_ZIP      = 25;
  _DZ_ERR_INVAL_NAME     = 26;
  _DZ_ERR_GENERAL        = 27;
  _DZ_ERR_MISS           = 28;  // ZEN_MISS UEN_MISC03
  _DZ_ERR_WARNING        = 29;  // PK_WARN
  _DZ_ERR_ERROR_DELETE   = 30;  // PK_NODEL
  _DZ_ERR_FATAL_IMPORT   = 31;
  _DZ_ERR_SKIPPING       = 32;
  _DZ_ERR_LOCKED         = 33;
  _DZ_ERR_DENIED         = 34;
  _DZ_ERR_DUPNAME        = 35;
  _DZ_ERR_NOSKIP         = 36;

  _DZ_ERR_MAX          = 36;

//  DZ_ERR_SKIPPING       = 37;
//  DLLPARAMCHECK      = $07070505;
(*    Message code format
0FFF FFFF  LLLL LLLL   LLLL MTTT  EEEE EEEE  {31 .. 0}
F = file number (7 bits = 128 files)
L = line number (12 bits=4096 lines)
M = message instead of error string
T = type  (3 bits=8)
E = error/string code (8 bits = 256 errors)
*)
  DZM_Type_Mask = $700;
  DZM_General = $000;
  DZM_Error   = $600;	// 1 1 x (E... is identifier)
  DZM_Warning = $400;	// 1 0 x
  DZM_Trace   = $300; // 0 1 1
  DZM_Verbose = $100;	// 0 0 1
  DZM_Message = $200; // 0 1 0 (E... is identifier)
  
  DZM_MessageBit = $800;    // mask for message bit

  // callback return values
//  CALLBACK_FALSE     =      0;
  CALLBACK_UNHANDLED =      0;
  CALLBACK_TRUE      =      1;
  CALLBACK_2         =      2;
  CALLBACK_3         =      3;
  CALLBACK_4         =      4;
  CALLBACK_IGNORED   =     -1;  // invalid ActionCode
  CALLBACK_CANCEL    =     -2;  // user cancel
  CALLBACK_ABORT     =     -3;
  CALLBACK_EXCEPTION =     -4;  // handled exception
  CALLBACK_ERROR     =     -5;  // unknown error

const
//  NEW_ENCODING_OS  = 0;
//  NEW_ENCODING_VER = 25;//30;
//  NEW_ENCODING_VEM = 25;//$001E;
  OUR_VEM = 30;
  Def_VER = 20;

const
  DelZipDLL_Name = 'DelZip190.dll';
  DelZipDLL_Execfunc = 'DZ_Exec';
  DelZipDLL_Abortfunc = 'DZ_Abort';
  DelZipDLL_Versfunc = 'DZ_Version';
  DelZipDLL_Privfunc = 'DZ_PrivVersion';
  DelZipDLL_Pathfunc = 'DZ_Path';     
  DelZipDLL_Bannerfunc = 'DZ_Banner';
  DelZipDLL_Namefunc = 'DZ_Name';
(*
// 'static' loaded dll functions
function DZ_Exec(C: pDLLCommands): Integer; STDCALL; EXTERNAL DelZipDLL_Name;
function DZ_Abort(C: Cardinal): Integer; STDCALL; EXTERNAL DelZipDLL_Name;
function DZ_Version: Integer; STDCALL; EXTERNAL DelZipDLL_Name;
function DZ_PrivVersion: Integer; STDCALL; EXTERNAL DelZipDLL_Name;
function DZ_Path: pChar; STDCALL; EXTERNAL DelZipDLL_Name;       
function DZ_Banner: pChar; STDCALL; EXTERNAL DelZipDLL_Name;
 *)

implementation

end.

