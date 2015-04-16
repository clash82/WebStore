
{$IfDef CLR}
   {$DEFINE BADCOMPILER}
    YOU ARE USING A COMPILER FOR WHICH THIS PACKAGE IS NOT DESIGNED!

    YOU HAVE BEEN WARNED !!!
{$EndIf}

{$IFDEF CONDITIONALEXPRESSIONS}
  {$WARN UNIT_PLATFORM OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$IF (RTLVersion >= 14)} // Delphi 6.0 or newer
    {$DEFINE VERD6up}
  {$IFEND}
  {$IF (RTLVersion >= 15)} // Delphi 7.0 or newer
    {$DEFINE VERD7up}
  {$IFEND}
  {$IF (RTLVersion >= 17)} // Delphi 2005 or newer
    {$DEFINE VERD2005up}
  {$IFEND}
  {$IF (RTLVersion >= 20)} // Delphi 2009 or newer   - UNICODE
    {$DEFINE VERD2009up}
  {$IFEND}
  {$IF (RTLVersion >= 21)} // Delphi 2010 or newer   - UNICODE
    {$DEFINE VERD2010up}
  {$IFEND}
  {$IF (RTLVersion >= 22)} // Delphi XE or newer   - UNICODE
    {$DEFINE VERDXEup}
  {$IFEND}
{$ELSE}
  {$DEFINE VERpre6}
  {$IfDef VER120}
     {$DEFINE KNOWNCOMPILER}
     {$DEFINE VERD4}
  {$EndIf}
  {$IfDef VER125}
     {$ObjExportAll On}
  {$EndIf}
  {$IfDef VER130}
    {$DEFINE KNOWNCOMPILER}
    {$IfDef BCB}
      {$ObjExportAll On}
    {$EndIf}
  {$EndIf}

  {$IfNDef KNOWNCOMPILER}
    YOU ARE USING A COMPILER FOR WHICH THIS PACKAGE IS NOT DESIGNED!

    YOU HAVE BEEN WARNED !!!
  {$EndIf}
{$ENDIF}   // $IFDEF CONDITIONALEXPRESSIONS

{$IfDef BADCOMPILER}
  YOU ARE USING A COMPILER FOR WHICH THIS PACKAGE IS NOT DESIGNED!

  YOU HAVE BEEN WARNED !!!
{$EndIf}

{$IfDef BCB}
  {$ObjExportAll On}
{$Endif}

//{$IFDEF VERD6up}
//{$WARN UNIT_PLATFORM OFF}
//{$WARN SYMBOL_PLATFORM OFF}
//{$ENDIF}
