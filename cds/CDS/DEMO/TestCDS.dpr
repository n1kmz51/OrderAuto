program TestCDS;

uses
  Forms,
  uTstCDS in 'uTstCDS.pas' {Form1},
  CDS in '..\CDS.PAS',
  ClDb2 in '..\CLDB2.PAS';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
