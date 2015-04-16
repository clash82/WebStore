
			Welcome to the Delphi Zip v1.90
                   This is the Delphi Edition for version 4 and later only
					June 22, 2010
						 
Major Changes

Delphi versions supported
 	not before 4

Directory Structure
  ZipMaster files
  Delphi - design- and run-time page files
  Demos  - Demos and SortGrid
  Dll - dll
  DLL\Source - Source code for dll (Available separately
  Docs 		- where this file resides
  Help 		- help files
  Res		- resource files for connecting to the application or SFX
  Res\Lang	- Language files
  Tools - updaters for language resource strings

Configuration
  In Source/ZipConfig19.inc 
   { $DEFINE USE_COMPRESSED_STRINGS}  // define to use compressed strings instead of 'ResourceString's. 
   { $DEFINE STATIC_LOAD_DELZIP_DLL}  // define to statically bind the dll
  

The required Delphi source files (files marked with '+' are written by ZipResMaker.exe)
    ...\
            ZipMstr19.pas	 - main component source
            ZipMstr19.res	 - components version resource 
            ZipVers19.inc	 - required defines for Delphi versions (only 4..10 supported)
            ZipConfig19.inc	 - sets compile options 
			ZMCenDir19.pas	 - allows external connections to the internal central entries
			ZMCompat19.pas	 - support for older compilers
            ZMCtx19.pas		 - Dialog box help context values
            ZMCore19.pas	 - basic support functions and event triggering
+           ZMDefMsgs19.pas	 - default message strings and tables
            ZMDelZip19.pas	 - dll interface definitions
            ZMDlg19.pas		 - dialog box support
            ZMDllLoad19.pas	 - dynamically loads and binds the dll 
            ZMDllOpr19.pas	 - operations that require the dll
            ZMDrv19.pas		 - Handles drive level parameters and methods
            ZMEOC19.pas		 - represents and finds, reads, writes the zip end of central structures
            ZMExtrLZ7719.pas - extractor for LZ77 compressed streams (used to extract stored dll)
            ZMHash19.pas	 - hash table functions
            ZMIRec19.pas	 - representation and functions on zip central entries
            ZMMatch19.pas	 - wildcard file spec matching
+           ZMMsg19.pas		 - message values
            ZMMsgStr19.pas	 - handles message string storage and language selection
            ZMSFXInt19.pas	 - SFX stub interface structures and definitions
            ZMStructs19.pas	 - definition of internal zip structures 
            ZMUTF819.pas	 - functions for handling UTF8
            ZMUtils19.pas	 - some functions to make life easier
            ZMWAux19.pas	 - support for sfx and multi-part zip files
            ZMWorkFile19.pas - primitive support for zip file
            ZMWrkr19.pas	 - does the work not requiring the dll
			ZMWUtils19.pas	 - wide file handling support
            ZMXcpt19.pas	 - EZipMaster definitions
            ZMZipFile19.pas	 - handles read and writing a zip file

            ZipFix.pas		 - (optional) component to repair damaged zip files
            ZipFix.res		 - 
            ZipFix.hlp		 - 

    ...\RES\
+          	ZMRes19_str.rc	 - resource script for compressed languages and dll
+          	ZMRes19_str.res	 - compiled resource for applications using ZipMaster (link to application)
			ZMRes19_sfx.rc	 - resource script for including sfx stub
			ZMRes19_sfx.res	 - compiled resource for including sfx stub (link to application) 
			ZMRes19_dll.rc	 - resource script for including compressed dll
			ZMRes19_dll.res	 - compiled resource for including compressed dll (link to application)(optional)
			ZMSFX.bin		 - Ansi sfx stub
			ZMSFXU.bin		 - Unicode sfx stub (requires XP or later)

    ...\Delphi\ 
            ZMstr190D?.bpk   - design and run-time package (? is compiler version)

    ...\DLL\
            DelZip190.dll	 - required dll

    ...\DOCS\
            licence.txt		 - a copy of the licence
			ReadMe.txt
			Install.txt
			Debug.txt

    ...\LANGS\
            ZipMsg.h		 - master message identifier header file
            ZipMsgUS.rc		 - master message script
            ZipMsg??.rc		 - resource language script files
            ZipMsg??.res	 - compiled language resource file
            SFX??.txt		 - language files for sfx

    ...\HELP\
            ZipMaster.hlp	 - compiled help file (Delphi 7)
            ZipMaster.chm	 - compile html file
            dzsfx.chm		 - SFX help file

    ...\HELP\SOURCE\		 - source files for help

    ...\DEMOS\DEMO1\		 - zip adder/extractor

    ...\DEMOS\DEMO2\		 - quick add/extract and dll test

    ...\DEMOS\DEMO3\		 - another add/extract example

    ...\DEMOS\DEMO4\		 - simple self installer

    ...\DEMOS\DEMO5\		 - make exe file (sfx)

    ...\DEMOS\DEMO6\		 - span multiple disks

    ...\DEMOS\DEMO7\		 - extract from stream

    ...\DEMOS\DEMO9\		 - use in thread

    ...\DEMOS\SortGrid\		 - (optional) sort grid component (used in some Demos)
            SortGrid.pas	 - 
            SortGrid.res	 - 
            SortGrid.dcr	 - 
            SortGridreg.pas	 - 
            SortGridPreview.pas	 - 
            SortGridPreview.dfm	 - 

      
     
                      Licenses
                               
	This component is subject to the 
      "GNU LESSER GENERAL PUBLIC LICENSE Version 2.1, February 1999"
     as explained in full in the Help file and in licence.txt.

 
                     DLL Source Code in C 
            
        The DLL source code is distributed separately due to it's
     size, and the fact that most Delphi users of this package
     probably don't want the C source for the DLL's.  The DLL 
     source is also freeware, and will remain that way. 
     The DLL source code needs Borland C++ Builder v5 - v6.
     
     
                     Problem Reports or Suggestions
     
     We DO want to hear your ideas!  If you find a problem with
     any part of this project, or if you just have an idea for
     us to consider, send us e-mail!
     
     But, please make sure that your bug has not already been
     reported.  Check the "official" web site often:
     
     Latest Versions and changes available at
     http://www.delphizip.org/index.html
     
     Problems
     please report any to 
     problems@delphizip.org
     
     Amended and updated by
     R.Peters 
     
