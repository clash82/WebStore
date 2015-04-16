Unit ZMMsg19;
 
(* Built by ZipHelper
   DO NOT MODIFY
  ZMMsg19.pas - Message Identifiers
 
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
 
 
---------------------------------------------------------------------------*)
 
Interface
 
Const
  DT_Language = 10096;
  DT_Author = 10097;
  DT_Desc = 10098;
  GE_FatalZip = 10101;
  GE_NoZipSpecified = 10102;
  GE_NoMem = 10103;
  GE_WrongPassword = 10104;
  GE_Except = 10106;
  GE_Inactive = 10109;
  GE_RangeError = 10110;
  GE_TempZip = 10111;
  GE_WasBusy = 10112;
  GE_EventEx = 10113;
  GE_DLLCritical = 10124;
  GE_Unknown = 10125;
  GE_Skipped = 10126;
  GE_Copying = 10127;
  GE_Abort = 10128;
  GE_ExceptErr = 10130;
  GE_NoSkipping = 10131;
  GE_FileChanged = 10132;
  RN_InvalidDateTime = 10144;
  PW_UnatAddPWMiss = 10150;
  PW_UnatExtPWMiss = 10151;
  PW_Caption = 10154;
  PW_MessageEnter = 10155;
  PW_MessageConfirm = 10156;
  CF_SourceIsDest = 10180;
  CF_OverwriteYN = 10181;
  CF_CopyFailed = 10182;
  CF_SFXCopyError = 10184;
  CF_NoDest = 10187;
  LI_ReadZipError = 10201;
  LI_ErrorUnknown = 10202;
  LI_WrongZipStruct = 10203;
  ZB_Yes = 10220;
  ZB_No = 10221;
  ZB_OK = 10222;
  ZB_Cancel = 10223;
  ZB_Abort = 10224;
  ZB_Retry = 10225;
  ZB_Ignore = 10226;
  ZB_CancelAll = 10227;
  ZB_NoToAll = 10228;
  ZB_YesToAll = 10229;
  AD_NothingToZip = 10301;
  AD_UnattPassword = 10302;
  AD_AutoSFXWrong = 10304;
  AD_InIsOutStream = 10306;
  AD_InvalidName = 10307;
  AD_NoDestDir = 10308;
  AD_BadFileName = 10309;
  AD_InvalidEncode = 10310;
  AD_InvalidZip = 10311;
  AZ_NothingToDo = 10320;
  AZ_SameAsSource = 10321;
  AZ_InternalError = 10322;
  DL_NothingToDel = 10401;
  EX_UnAttPassword = 10502;
  EX_NoExtrDir = 10504;
  LD_NoDll = 10650;
  LD_DllLoaded = 10652;
  LD_DllUnloaded = 10653;
  LD_LoadErr = 10654;
  SF_StringTooLong = 10801;
  SF_NoZipSFXBin = 10802;
  SF_DetachedHeaderTooBig = 10810;
  CZ_InputNotExe = 10902;
  CZ_BrowseError = 10906;
  CZ_NoExeResource = 10907;
  CZ_ExeSections = 10908;
  CZ_NoExeIcon = 10909;
  CZ_NoIcon = 10910;
  CZ_NoCopyIcon = 10911;
  CZ_NoIconFound = 10912;
  DS_NoInFile = 11001;
  DS_FileOpen = 11002;
  DS_NotaDrive = 11003;
  DS_DriveNoMount = 11004;
  DS_NoVolume = 11005;
  DS_NoMem = 11006;
  DS_Canceled = 11007;
  DS_FailedSeek = 11008;
  DS_NoOutFile = 11009;
  DS_NoWrite = 11010;
  DS_EOCBadRead = 11011;
  DS_LOHBadRead = 11012;
  DS_CEHBadRead = 11013;
  DS_CEHWrongSig = 11015;
  DS_CENameLen = 11017;
  DS_DataDesc = 11020;
  DS_CECommentLen = 11022;
  DS_ErrorUnknown = 11024;
  DS_NoUnattSpan = 11025;
  DS_NoTempFile = 11027;
  DS_LOHBadWrite = 11028;
  DS_CEHBadWrite = 11029;
  DS_EOCBadWrite = 11030;
  DS_NoDiskSpace = 11032;
  DS_InsertDisk = 11033;
  DS_InsertVolume = 11034;
  DS_InDrive = 11035;
  DS_NoValidZip = 11036;
  DS_AskDeleteFile = 11039;
  DS_AskPrevFile = 11040;
  DS_InsertAVolume = 11046;
  DS_CopyCentral = 11047;
  DS_NoDiskSpan = 11048;
  DS_UnknownError = 11049;
  DS_NoRenamePart = 11050;
  DS_NotChangeable = 11051;
  DS_Zip64FieldError = 11052;
  DS_Unsupported = 11053;
  DS_ReadError = 11054;
  DS_WriteError = 11055;
  DS_FileError = 11056;
  DS_FileChanged = 11057;
  DS_SFXBadRead = 11058;
  DS_BadDrive = 11059;
  DS_LOHWrongName = 11060;
  DS_BadCRC = 11061;
  DS_NoEncrypt = 11062;
  DS_NoInStream = 11063;
  DS_NoOutStream = 11064;
  DS_SeekError = 11065;
  DS_DataCopy = 11066;
  DS_CopyError = 11067;
  DS_TooManyParts = 11068;
  DS_AnotherDisk = 11069;
  FM_Erase = 11101;
  FM_Confirm = 11102;
  CD_CEHDataSize = 11307;
  CD_DuplFileName = 11309;
  CD_NoProtected = 11310;
  CD_NoChangeDir = 11312;
  PR_Archive = 11401;
  PR_CopyZipFile = 11402;
  PR_SFX = 11403;
  PR_Header = 11404;
  PR_Finish = 11405;
  PR_Copying = 11406;
  PR_CentrlDir = 11407;
  PR_Checking = 11408;
  PR_Loading = 11409;
  PR_Joining = 11410;
  PR_Splitting = 11411;
  PR_Writing = 11412;
  PR_PreCalc = 11413;
  DZ_Skipped = 11450;
  DZ_InUse = 11451;
  DZ_Refused = 11452;
  DZ_NoOpen = 11453;
  DZ_NoFiles = 11454;
  DZ_SizeChanged = 11455;
  TM_Erasing = 11600;
  TM_Deleting = 11601;
  TM_GetNewDisk = 11602;
  TM_SystemError = 11603;
  TM_Trace = 11604;
  TM_Verbose = 11605;
  DZ_RES_GOOD = 11648;
  DZ_RES_CANCELLED = 11649;
  DZ_RES_ABORT = 11650;
  DZ_RES_CALLBACK = 11651;
  DZ_RES_MEMORY = 11652;
  DZ_RES_STRUCT = 11653;
  DZ_RES_ERROR = 11654;
  DZ_RES_PASSWORD_FAIL = 11655;
  DZ_RES_PASSWORD_CANCEL = 11656;
  DZ_RES_INVAL_ZIP = 11657;
  DZ_RES_NO_CENTRAL = 11658;
  DZ_RES_ZIP_EOF = 11659;
  DZ_RES_ZIP_END = 11660;
  DZ_RES_ZIP_NOOPEN = 11661;
  DZ_RES_ZIP_MULTI = 11662;
  DZ_RES_NOT_FOUND = 11663;
  DZ_RES_LOGIC_ERROR = 11664;
  DZ_RES_NOTHING_TO_DO = 11665;
  DZ_RES_BAD_OPTIONS = 11666;
  DZ_RES_TEMP_FAILED = 11667;
  DZ_RES_NO_FILE_OPEN = 11668;
  DZ_RES_ERROR_READ = 11669;
  DZ_RES_ERROR_CREATE = 11670;
  DZ_RES_ERROR_WRITE = 11671;
  DZ_RES_ERROR_SEEK = 11672;
  DZ_RES_EMPTY_ZIP = 11673;
  DZ_RES_INVAL_NAME = 11674;
  DZ_RES_GENERAL = 11675;
  DZ_RES_MISS = 11676;
  DZ_RES_WARNING = 11677;
  DZ_ERR_ERROR_DELETE = 11678;
  DZ_ERR_FATAL_IMPORT = 11679;
  DZ_ERR_SKIPPING = 11680;
  DZ_ERR_LOCKED = 11681;
  DZ_ERR_DENIED = 11682;
  DZ_ERR_DUPNAME = 11683;
 
const
  PR_Progress = PR_Archive - 1;
 
// name of compressed resource data
const 
  DZRES_Str = 'DZResStr19';  // compressed language strings
  DZRES_SFX = 'DZResSFX19';  // stored UPX Dll version as string
  DZRES_Dll = 'DZResDll19';  // stored UPX Dll
 
implementation
 
end.
