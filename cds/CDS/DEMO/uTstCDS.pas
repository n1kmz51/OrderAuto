unit uTstCDS;
{ D5 ++
 Simple TClarionDataset DEMO with MEMO
 
}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, DBGrids, Db, CDS, ExtCtrls, DBCtrls, Mask;

type
  TForm1 = class(TForm)
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    OpenDialog1: TOpenDialog;
    btnOpen: TButton;
    DBNavigator1: TDBNavigator;
    procedure btnOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkUseMemoClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    tblCLA: TClarionDataset;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
     if tblCLA.Active then tblCLA.Close;
     tblCLA.TableName:=OpenDialog1.FileName;
     tblCLA.Open;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  tblCLA:=TClarionDataSet.Create(nil);
  tblCLA.OemConvert := True;
  DataSource1.DataSet:=tblCLA;
//  OpenDialog1.FileName:='TEST.DAT';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  tblCLA.Free;
end;

procedure TForm1.chkUseMemoClick(Sender: TObject);
begin
//  if tblCLA.Active then tblCLA.Close;
//  tblCLA.BlobToCache:= chkUseMemo.Checked;
//  if chkUseMemo.Checked then
//  begin
//     DBMemo1.DataSource:= DataSource1 ;
//     // DBMemo1.DataField:='MEM'
//  end else DBMemo1.DataSource:= nil;
end;

end.
