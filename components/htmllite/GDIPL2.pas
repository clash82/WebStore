unit GDIPL2;

interface

uses Windows, SysUtils, ActiveX;

var
  GDIPlusActive: boolean = False;

procedure InitializeGDIPlus;  
procedure CloseGDIPlus;   

type
  TGpImage = class(TObject)
  private
    fHandle: integer;
    fWidth, fHeight: integer;
    fFilename: string;
    function GetHeight: integer;
    function GetWidth: integer;
  public
    constructor Create(Filename: string; TmpFile: boolean = False);
    destructor Destroy; override;
    property Height: integer read GetHeight;
    property Width: integer read GetWidth;
  end;

  TGpGraphics = class(TObject)
  private
    fGraphics: integer;
  public
    constructor Create(Handle: HDC);
    destructor Destroy; override;
    procedure DrawImage (Image: TGPImage; X, Y, Width, Height: Integer);
 end;

implementation

const
    GdiPlusLib = 'GdiPlus.dll';

type
    EGDIPlus = class (Exception);
    TRectF = record
        X: Single;
        Y: Single;
        Width: Single;
        Height: Single;
    end;

var
  GdiplusStartup: function(var Token: DWord; const Input, Output: Pointer): Integer; stdcall;
  GdiplusShutdown: procedure(Token: DWord); stdcall;
  GdipDeleteGraphics: function(Graphics: Integer): Integer; stdcall;
  GdipCreateFromHDC: function(hdc: HDC; var Graphics: Integer): Integer; stdcall;
  GdipDrawImageRectI: function (Graphics, Image, X, Y, Width, Height: Integer): Integer; stdcall;
  GdipLoadImageFromFile: function (const FileName: PWideChar; var Image: Integer): Integer; stdcall;
  GdipDisposeImage: function (Image: Integer): Integer; stdcall;
  GdipGetImageWidth: function (Image: Integer; var Width: Integer): Integer; stdcall;

  GdipGetImageHeight: function(Image: Integer; var Height: Integer): Integer; stdcall;

type
  TGDIStartup = packed record
      Version: Integer;                       // Must be one
      DebugEventCallback: Pointer;            // Only for debug builds
      SuppressBackgroundThread: Bool;         // True if replacing GDI+ background processing
      SuppressExternalCodecs: Bool;           // True if only using internal codecs
  end;

var
  Err: Integer;

{ TGpGrapnics }

constructor TGpGraphics.Create(Handle: HDC);
var
  err: integer;
begin
inherited Create;
err := GdipCreateFromHDC (Handle, fGraphics);
if err <> 0 then
  raise EGDIPlus.Create('Can''t Create Graphics');
end;

destructor TGpGraphics.Destroy;
begin
if fGraphics <> 0 then
    GdipDeleteGraphics  (fGraphics);
inherited;
end;

procedure TGpGraphics.DrawImage(Image: TGPImage; X, Y, Width, Height: Integer);
begin
GdipDrawImageRectI (fGraphics, Image.fHandle, X, Y, Width, Height);
end;

{ TGpImage }

constructor TGpImage.Create(Filename: string; TmpFile: boolean = False);
var
    err: Integer;
    Buffer: array [0..511] of WideChar;
begin
Inherited Create;
if not FileExists (FileName) then
  raise EGDIPlus.Create (Format ('Image file %s not found.', [FileName]));
err := GdipLoadImageFromFile (StringToWideChar (FileName, Buffer, sizeof (Buffer)), fHandle);
if err <> 0 then
  raise EGDIPlus.Create(Format ('Can''t load image file %s.', [FileName]));
if TmpFile then
  fFilename := Filename;
end;

destructor TGpImage.Destroy;
begin
GdipDisposeImage (fHandle);
if Length(fFilename) > 0 then
  try
    DeleteFile(fFilename);
  except
    end;
inherited;
end;

function TGpImage.GetWidth: integer;
begin
if fWidth = 0 then
  GdipGetImageWidth (fHandle, fWidth);
Result := fWidth;
end;

function TGpImage.GetHeight: integer;
begin
if fHeight = 0 then
  GdipGetImageHeight (fHandle, fHeight);
Result := fHeight;
end;

var
  LibHandle: THandle;
  GDIPInitCount: integer = 0;
  InitToken: DWord;
  Startup: TGDIStartup;

procedure InitializeGDIPlus;  
begin
if GDIPInitCount = 0 then
  begin
  LibHandle := LoadLibrary('GDIPlus.dll');
  if LibHandle <> 0 then
    begin
    @GdiplusStartup := GetProcAddress(LibHandle, 'GdiplusStartup');
    @GdiplusShutdown := GetProcAddress(LibHandle, 'GdiplusShutdown');
    @GdipDeleteGraphics := GetProcAddress(LibHandle, 'GdipDeleteGraphics');
    @GdipCreateFromHDC := GetProcAddress(LibHandle, 'GdipCreateFromHDC');
    @GdipDrawImageRectI := GetProcAddress(LibHandle, 'GdipDrawImageRectI');
    @GdipLoadImageFromFile := GetProcAddress(LibHandle, 'GdipLoadImageFromFile');
    @GdipDisposeImage := GetProcAddress(LibHandle, 'GdipDisposeImage');
    @GdipGetImageWidth := GetProcAddress(LibHandle, 'GdipGetImageWidth');
    @GdipGetImageHeight := GetProcAddress(LibHandle, 'GdipGetImageHeight');

    FillChar (Startup, sizeof (Startup), 0);
    Startup.Version := 1;
    Err := GdiPlusStartup (InitToken, @Startup, nil);
    GDIPlusActive := Err = 0;
    if not GDIPlusActive then
      FreeLibrary(LibHandle);
    end;
  end;
Inc(GDIPInitCount);
end;

procedure CloseGDIPlus;   
begin
Dec(GDIPInitCount);
if (GDIPInitCount <= 0) and GDIPlusActive then
  begin
  GdiplusShutdown (InitToken);
  FreeLibrary(LibHandle);
  GDIPlusActive := False;
  end;
end;

end.
