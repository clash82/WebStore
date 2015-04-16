{Version 7.71}
{Do not use this file with C++Builder 5}

{$A+,B-,F-,G+,I+,P+,T-,V+,X+,R-}

{$ifdef Win32}
  {$J+}  {typed constants are modifiable}
  {$H+}  {LongStrings On}
{$endif}

{$ifndef DebugIt}
  {$W-}  {Stack frames off}
  {$Q-}  {overflow checking off}
  {$S-}  {stack checking off}
  {$C-}  {Assertions off}
  {$ifdef Win32}
    {$O+}  {optimization on}
  {$endif}
{$else}
  {$W+}  {Stack frames on}
  {$Q+}  {overflow checking on}
  {$S+}  {stack checking on}
  {$C+}  {Assertions on}
  {$ifdef Win32}
    {$O-}  {optimization off}
  {$endif}
{$endif}

{$Define Delphi6_Plus}
{$Define ver100_plus}
{$Define ver120_plus}

{$ifdef ver100}   {Delphi 3}
{$Undef ver120_plus}
{$UnDef Delphi6_Plus}
{$endif}

{$ifdef ver110}    {C++Builder 3}
{$ObjExportAll On}
{$Define CppBuilder}
{$Undef ver120_plus}
{$UnDef Delphi6_Plus}
{$endif}

{$ifdef Ver120}   {Delphi 4}
{$UnDef Delphi6_Plus}
{$endif}

{$ifdef ver125}    {C++Builder 4}
{$ObjExportAll On}
{$Define CppBuilder}
{$UnDef Delphi6_Plus}
{$endif}

{$ifdef Ver130}   {Delphi 5}
{$UnDef Delphi6_Plus}
{$endif}

{$ifdef Delphi6_Plus}
  {$Warn Symbol_Platform Off}
{$endif}


