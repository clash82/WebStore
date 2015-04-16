unit ABOUT;

interface

uses
  Windows, Forms, ShellAPI, jpeg, Classes, Controls, ExtCtrls, StdCtrls;

type
  TAboutForm = class(TForm)
    DescriptionLabel: TLabel;
    HeaderLabel: TLabel;
    CloseButton: TButton;
    TitleLabel: TLabel;
    CopyrightLabel: TLabel;
    UrlLabel: TLabel;
    GitHubLabel: TLabel;
    LicenseLabel: TLabel;
    CompilatorLabel: TLabel;
    LogoImage: TImage;
    procedure UrlLabelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

uses MAIN;

{$R *.DFM}

procedure TAboutForm.UrlLabelClick(Sender: TObject);
begin
  ShellExecute(AboutForm.Handle, nil, PChar((Sender as TLabel).Caption), nil, nil, Sw_ShowNormal);
end;

end.
