{Version 7.71}
unit LiteAbt;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, HTMLLite, ExtCtrls;

const
  Version = '7.71';

type
  TAboutBox = class(TForm)
    BitBtn1: TBitBtn;
    Panel1: TPanel;
    Viewer: ThtmlLite;
  private
    { Private declarations }
  public
    { Public declarations }
    constructor CreateIt(Owner: TComponent);
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.DFM}

constructor TAboutBox.CreateIt(Owner: TComponent);
var
  S: string;
begin
inherited Create(Owner);
Viewer.DefFontName := 'Arial';
Viewer.DefFontSize := 9;
Viewer.DefFontColor := clNavy;
S :='<body bgcolor="ffffeb" text="000080">'+
    '<center>'+
    '<h1>'+'HTMLDemo</h1>'+
    '<font color="Maroon">A demo program for the ThtmlLite component</font>'+
    '<h3>Version '+Version+'</h3><font size="-1">Compiled with Delphi '+
{$ifdef Windows}
    '1'+
{$endif}
{$ifdef Ver90}
    '2'+
{$endif}
{$ifdef Ver100}
    '3'+
{$endif}
{$ifdef Ver120}
    '4'+
{$endif}
{$ifdef Ver130}
    '5'+
{$endif}
{$ifdef Ver140}
    '6'+
{$endif}
{$ifdef Ver150}
    '7'+
{$endif}
{$ifdef Ver170}
    '2005'+
{$endif}
{$ifdef Ver180}
    '2006'+
{$endif}
    '</font></center>'+
    '</body>';
Viewer.LoadFromString(S, '');
end;

end.
