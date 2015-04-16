unit ZMCtx19;

(*
  ZMCtx19.pas - DialogBox help context values
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

const
  DHCBase = 10000;
  DHC_ZipMessage = DHCBase;
  DHC_ExMessage = DHCBase + 1;
  DHC_Password = DHCBase + 2; // just GetPassword default password
  DHC_ExtrPwrd = DHCBase + 3;
  DHC_AddPwrd1 = DHCBase + 4;
  DHC_AddPwrd2 = DHCBase + 5;
  DHC_WrtSpnDel = DHCBase + 6;
  DHC_ExSFX2EXE = DHCBase + 7;
  DHC_ExSFX2Zip = DHCBase + 8;
  DHC_SpanNxtW = DHCBase + 9;
  DHC_SpanNxtR = DHCBase + 10;  
  DHC_SpanOvr = DHCBase + 11;
  DHC_SpanNoOut = DHCBase + 12;
  DHC_SpanSpace = DHCBase + 13;
  DHC_CpyZipOvr = DHCBase + 14;
  DHC_FormErase = DHCBase + 15;
  DHC_ExSFXNew = DHCBase + 16;
  
implementation

end.
