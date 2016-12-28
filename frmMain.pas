unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, IniFiles, CDS, dateUtils, Math, ShellAPI;

type
  TForm1 = class(TForm)
    conSysSql: TADOConnection;
    tblZakaz: TADOTable;
    clrnTable: TClarionDataSet;
    clrnRecBuy: TClarionDataSet;
    qrySumNaklad: TADOQuery;
    qryTmpZakazInsert: TADOQuery;
    qryTmpZakazUpload: TADOQuery;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  {ini ���� ��� �������� ���������}
  File_ini: TIniFile;
  {log ����}
  File_log_Name: string = '';
  {������ ����������}
  SqlConnectionStr : string;
  {��� ������� � ����}
  SqlTbl : string;
  {���� � ���� clarion}
   strClarionDBRoot : string;
  {���� � �������� ������}
   strBackupPath : string;
   {��� ��������� �����}
   BkClarionDBName : string;
   {��� dat ����� Clarion}
   strclrTbl :string;
   {������ ���� � ��� ������� Clarion}
   strFullTbl : string;
   {�������� � ����-����}
   BookMark : TBookmark;

   implementation



{$R *.dfm}

{��������� ������ ������ � log-����}
Procedure WriteLog(Line: string);
Var
 F: TextFile;
 Text: String;
begin
 // if not Box.Checked then // �������� ����� �� ������
 //  exit;

if File_log_Name = '' then
   File_log_Name := extractfilepath(application.exename)+IntToStr(DayOfTheMonth(Date)) + IntToStr(MonthOfTheYear(Date))
     + IntToStr(YearOf(Date)) + '-' + IntToStr(HourOfTheDay(Now))
     + IntToStr(MinuteOfTheHour(Now)) + IntToStr(SecondOfTheMinute(Now))+'-OrderAuto.log';

 AssignFile(F, File_log_Name);

 if fileexists(File_log_Name) then
   begin
     append(f);
   end
 else
 begin
   Rewrite(F);
   WriteLn(F,'OrderAuto 1.0');
 end;

  WriteLn(F,DateTimeToStr(Now) + ': ' + Line);
  CloseFile(F);
 end;


 {�������� ��������� ������ ��������� � ������ ������ �� �������������� ���������
  }
function getNaklStr (inID: LongInt): string;
var
  tVar: LongInt;
 begin
  tVar := inID mod 100000000;
  Result := '';
  if  (tVar div 100000) < 13 then // �������� 2010 ����
     Result := IntToStr(tVar div 100000)
  else
    begin
      Result := IntToStr((tVar div 100000) Mod 12);
      if Result = '0' then
        Result := '12'; // �������
    end;
  if Length(Result) = 1 then
    Result :=  '0' + Result;
  Result := Result + '_';
  tVar := tVar Mod 100000;
  If tVar < 10000 Then
   Result := Result + Format('%.*d', [4, tVar]) + 'L'
  else
   Result := Result + chr(tVar div 1000 + 87) + Format('%.*d', [3, tVar Mod 1000]) + 'L';
   //ShowMessage(Result);
end;

{������� ��������� ��������� ������ ��������� �� ���������� �������������� � ����}
function getNaklLngID (strID: String; dtDate: TDateTime): LongInt;
begin
  If Ord(strID[1]) < 58 Then Result := StrToInt(strID)
  else
    begin
      Result := (Ord(strID[1]) - 87) * 1000;
      Result := Result + StrToInt(Copy(strID,2,Length(strID)));
    end;
  //Result := Result + 100000 * Ceil(MonthSpan(EncodeDate(2009, 12, 31),dtDate)) + 100000000;
  Result := Result + 100000 * (72 + MonthOfTheYear(dtDate)) + 100000000;
end;

{������� ��� ���������� ������ � DataSet}
function FindStr(AGrid: TClarionDataSet; ArtikulStr: String; Code_proStr: String): Boolean;
var
  OldPos: Integer;
begin
  Result := False;

  { ���������� ����� ������ ��� ������ �� ����� }
  OldPos := AGrid.RecNo;

  { ���� �������� ������ - ������ �������� ��
    ������ ������}
  if BookMark <> nil then
  begin
    AGrid.GotoBookmark(BookMark);
    AGrid.Next;
  end else begin
    AGrid.First;
    BookMark := AGrid.GetBookmark;
  end;

  repeat
    { ���� �������� ����� DataSet - ���� � ������ ������ }
    if AGrid.Eof then
      AGrid.First;

    { ���� ������ ������� - ���������� �� ��� ��������
      � ������� }
    //if Pos(NumberStr, AGrid.Fields[5].AsString) <> 0 then
      //if Pos(MonthStr, AGrid.Fields[4].AsString) <> 0 then
        //if Pos(Sel_BuyStr, AGrid.Fields[6].AsString) <> 0 then
          if Pos(ArtikulStr, AGrid.Fields[2].AsString) <> 0 then
            if AnsiCompareStr(Code_proStr, AGrid.Fields[0].AsString) = 0 then
             if AGrid.IsRecordDeleted = False  then
                begin
                  BookMark := AGrid.GetBookmark;
 //                 AGrid.Edit;
 //                 AGrid.FieldByName('PRICE').AsString := New_Price;
                  Result := True;
                  Exit;
                end;

    { ���� ������ ��� ������ - ������� }
    if OldPos = AGrid.RecNo then
      begin
//        ShowMessage('������ �� �������.');
        Result := False;
        exit;
      end;
    { ����� ��������� �� ��������� ������ }
    AGrid.Next;
  until not True;
end;

 {��������� �������� ��������}
procedure StorCorrection();
var
  intZakaz : Integer;
  intStor  : Integer;
  {������� � ��� �������������� � STOR.DAT}
  claARTIKUL  : string;
  claCODE_PRO : string;
  {����� ������}
  intNumZakaz : string;
  {������� � ��������}
  strLPArtikul : string;
  {������ �����}
  blStorEnable : Boolean;
  {������� ����� � ��������}
  intSlashPos : Integer;
begin
   WriteLog('*****************************������ �������� �������**********************');
     //�������� �������.
   strClarionDBRoot := File_ini.ReadString('ClarionDB', 'ClarionDRoot', 'default value');
   strBackupPath := File_ini.ReadString('ClarionDB', 'BackupClarionPath', 'default value');
   strclrTbl := 'stor.dat';
   strFullTbl := strClarionDBRoot + 'dat\' + strclrTbl;
   Form1.clrnTable.TableName := strFullTbl;
   WriteLog('�������� ��������� ����� STOR.DAT');
   //��������� ����� ������ STOR.DAT
     BkClarionDBName :=
     IntToStr(DayOfTheMonth(Date)) + IntToStr(MonthOfTheYear(Date))
     + IntToStr(YearOf(Date)) + '-' + IntToStr(HourOfTheDay(Now))
     + IntToStr(MinuteOfTheHour(Now)) + IntToStr(SecondOfTheMinute(Now))
     + '-' + IntToStr(MilliSecondOfTheMinute(Now)) + '-' + 'orig-'+ strclrTbl;
     try
      if CopyFile(PChar(strFullTbl), PChar(strBackupPath + BkClarionDBName), True) then
        WriteLog('��������� ����� ' + strclrTbl + ' ��������� ��� ������ ' + strBackupPath + BkClarionDBName)
      else
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������ ��������� ��������');
          ExitProcess(1);
        end;
     except
       on E : Exception do
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������: ' + E.Message);
          WriteLog('������ ��������� ��������� ��������');
          ExitProcess(1);
        end;
     end;
  Form1.clrnTable.OemConvert := True;
  try
    Form1.clrnTable.Open;
  except
    on E: Exception do
      begin
        WriteLog('�� ������� ������������ � ������� stor.dat');
        WriteLog('������: ' + E.Message);
        WriteLog('������ ��������� ��������� ��������');
        ExitProcess(1);
      end;
  end;

  Form1.tblZakaz.First;
  Form1.clrnTable.First;
  intSlashPos := AnsiPos('\', Form1.tblZakaz.FieldByName('gooStrID').AsString);
  claCODE_PRO := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, 1,intSlashPos - 1);
  claARTIKUL  := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, intSlashPos,8);
  FindStr(Form1.clrnTable, claCODE_PRO, claARTIKUL);
  while not Form1.tblZakaz.Eof
    do
      begin
        intSlashPos := AnsiPos('\', Form1.tblZakaz.FieldByName('gooStrID').AsString);
        claCODE_PRO := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, 1,intSlashPos - 1);
        claARTIKUL  := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, intSlashPos,8);
        blStorEnable := FindStr(Form1.clrnTable, claARTIKUL, claCODE_PRO) and not (Form1.clrnTable.IsRecordDeleted);;
        
        if (Form1.tblZakaz.FieldByName('zhIsAuto').AsInteger = 1)
        and (Form1.tblZakaz.FieldByName('zdStatus').AsInteger = 0)
        then
          begin
            Form1.tblZakaz.Edit;
            Form1.clrnTable.Edit;
            strLPArtikul := Form1.tblZakaz.FieldByName('gooArtikul').AsString;
            if blStorEnable = True then
              intStor  := Form1.clrnTable.FieldByName('QUANT').AsInteger
            else
              intStor  := 0;
              intZakaz := Form1.tblZakaz.FieldByName('zdCount').AsInteger;
            intNumZakaz := Form1.tblZakaz.FieldByName('ID').AsString;
            WriteLog('************************************************************************');
            WriteLog('����� �' + intNumZakaz + ' '+ claCODE_PRO + claARTIKUL + ' ' + '�������LP: ' + strLPArtikul + ' ' + '��������:' + IntToStr(intZakaz));
            WriteLog('����� �' + intNumZakaz + ' ' +' � �������:' + IntToStr(intStor));
            if intStor >= intZakaz then
              begin
                //Form1.tblZakaz.Edit;
                Form1.tblZakaz.FieldByName('zdAutocount').AsInteger := intZakaz;
                //Form1.tblZakaz.Post;
              end
            else
              begin
                //Form1.tblZakaz.Edit;
                Form1.tblZakaz.FieldByName('zdAutocount').AsInteger := intStor;
                //Form1.tblZakaz.Post;
              end;
            Form1.tblZakaz.Post;
            Form1.tblZakaz.Edit;
            Form1.tblZakaz.FieldByName('zdStatus').AsInteger := 1;
            Form1.tblZakaz.Post;
            //Form1.tblZakaz.Edit;
            //Form1.tblZakaz.FieldByName('zhIsAuto').AsInteger := 2;
            //Form1.tblZakaz.Post;
            WriteLog('����� �' + intNumZakaz + ' ' +' �������:' + Form1.tblZakaz.FieldByName('zdAutoCount').AsString);
            if intStor > 0 then
            begin
              Form1.clrnTable.Edit;
              Form1.clrnTable.FieldByName('QUANT').AsInteger := Form1.clrnTable.FieldByName('QUANT').AsInteger - Form1.tblZakaz.FieldByName('zdAutoCount').AsInteger;
              Form1.clrnTable.Post;
            end;  
            WriteLog('�������� �� ������ '  + claCODE_PRO + claARTIKUL + ' ' + Form1.clrnTable.FieldByName('QUANT').AsString);
            WriteLog('************************************************************************');


          end;
        Form1.tblZakaz.Next;
      end;
  Form1.clrnTable.Close;
  WriteLog('****************�������� ������� ���������************************');
end;

function FindMaxNaklad (month : string) : string;
var strTempNumb : string;
begin
  with Form1.clrnTable do
    begin
      //TableName := 'd:\i-local\Lparfum\Dat\NAKLAD.DAT';
      //Active := True;
      First;
      //strTempNumb := FieldByName('Number').AsString;
      strTempNumb := '';
      while not Eof
        do
          begin
            if  not IsRecordDeleted
              and
               (AnsiCompareStr(strTempNumb, FieldByName('Number').AsString) < 0)
              and
               (AnsiCompareStr(month, FieldByName('Month').AsString) = 0)
            then
              strTempNumb := FieldByName('Number').AsString;
              Next;
          end;
      Result := strTempNumb;
      //Active := False;

    end;
end;

function FindMaxInvoice (month : string) : string;
var strTempNumb : string;
begin
  with Form1.clrnTable do
    begin
      //TableName := 'd:\i-local\Lparfum\Dat\NAKLAD.DAT';
      //Active := True;
      First;
      strTempNumb := '';
      //strTempNumb := FieldByName('INV_NUMBER').AsString;
      while not Eof
        do
          begin
            if  not IsRecordDeleted
              and
               (AnsiCompareStr(strTempNumb, FieldByName('INV_NUMBER').AsString) < 0)
              and
               (AnsiCompareStr(month, FieldByName('Month').AsString) = 0)
            then
              strTempNumb := FieldByName('INV_NUMBER').AsString;
              Next;
          end;
      Result := strTempNumb;
      //Active := False;

    end;
end;

procedure CreateNaklad();
var intZakaz, intStor : Integer; flNaklSumm : Currency;
  strTmpZakazID: string;
  strTmpNakladID: string;
  intNaklNum: Integer;
  intInvoiceNum : Integer;
  strNaklId: string;
  flSumNaklad : Currency;
  {������� ����� � ��������}
  intSlashPos : Integer;
  {������ � ��������� ������� � ������ ��������� � �����-�������}
  chrFirstNumSymb : Char;
  chrLastNumSymb : Char;
  {��������� ����� ���������}
  strNaklNum : string;

begin
   WriteLog('*****************************������ ������������ ���������********');
   strClarionDBRoot := File_ini.ReadString('ClarionDB', 'ClarionDRoot', 'default value');
   strBackupPath := File_ini.ReadString('ClarionDB', 'BackupClarionPath', 'default value');
   strclrTbl := 'naklad.dat';
   strFullTbl := strClarionDBRoot + 'dat\' + strclrTbl;
   Form1.clrnTable.TableName := strFullTbl;
   WriteLog('�������� ��������� ����� NAKLAD.DAT');
   //��������� ����� ������� NAKLAD.DAT
     BkClarionDBName :=
     IntToStr(DayOfTheMonth(Date)) + IntToStr(MonthOfTheYear(Date))
     + IntToStr(YearOf(Date)) + '-' + IntToStr(HourOfTheDay(Now))
     + IntToStr(MinuteOfTheHour(Now)) + IntToStr(SecondOfTheMinute(Now))
     + '-' + IntToStr(MilliSecondOfTheMinute(Now)) + '-' + 'orig-'+ strclrTbl;
     try
      if CopyFile(PChar(strFullTbl), PChar(strBackupPath + BkClarionDBName), True) then
        WriteLog('��������� ����� ' + strclrTbl + ' ��������� ��� ������ ' + strBackupPath + BkClarionDBName)
      else
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������ ��������� ��������');
          ExitProcess(1);
        end;
     except
       on E : Exception do
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������: ' + E.Message);
          WriteLog('������ ��������� ��������� ��������');
          ExitProcess(1);
        end;
     end;

     WriteLog('�������� ��������� ����� REC_BUY.DAT');
     strclrTbl := 'rec_buy.dat';
     strFullTbl := strClarionDBRoot + 'dat\' + Format('%.5d', [MonthOfTheYear(Now)]) + '\' + strclrTbl;
     Form1.clrnRecBuy.TableName := strFullTbl;
     BkClarionDBName :=
     IntToStr(DayOfTheMonth(Date)) + IntToStr(MonthOfTheYear(Date))
     + IntToStr(YearOf(Date)) + '-' + IntToStr(HourOfTheDay(Now))
     + IntToStr(MinuteOfTheHour(Now)) + IntToStr(SecondOfTheMinute(Now))
     + '-' + IntToStr(MilliSecondOfTheMinute(Now)) + '-' + 'orig-'+ strclrTbl;
     try
      if CopyFile(PChar(strFullTbl), PChar(strBackupPath + BkClarionDBName), True) then
        WriteLog('��������� ����� ' + strclrTbl + ' ��������� ��� ������ ' + strBackupPath + BkClarionDBName)
      else
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������ ��������� ��������');
          ExitProcess(1);
        end;
     except
       on E : Exception do
        begin
          WriteLog('�� ������� ������� ��������� ����� ' + strclrTbl);
          WriteLog('������: ' + E.Message);
          WriteLog('������ ��������� ��������� ��������');
          ExitProcess(1);
        end;
     end;
     Form1.clrnTable.OemConvert := True;
     Form1.clrnTable.Exclusive := True;
     Form1.clrnTable.BlobToCache := True;
     Form1.clrnRecBuy.OemConvert := True;
     Form1.clrnRecBuy.Exclusive := True;
      try
        Form1.clrnTable.Open;
      except
        on E: Exception do
          begin
            WriteLog('�� ������� ������������ � ������� naklad.dat');
            WriteLog('������: ' + E.Message);
            WriteLog('������ ��������� ��������� ��������');
            ExitProcess(1);
          end;
      end;
      try
        Form1.clrnRecBuy.Open;
      except
        on E: Exception do
          begin
            WriteLog('�� ������� ������������ � ������� rec_buy.dat');
            WriteLog('������: ' + E.Message);
            WriteLog('������ ��������� ��������� ��������');
            ExitProcess(1);
          end;
      end;
     Form1.clrnTable.First;
     Form1.clrnRecBuy.First;

     Form1.tblZakaz.Sort := 'ID';

     Form1.tblZakaz.First;
     strTmpZakazID := '';
     strTmpNakladID := '';
     intInvoiceNum := getNaklLngID(FindMaxInvoice(Format('%.2d', [MonthOfTheYear(Now)])), Now);
     intNaklNum := getNaklLngID(FindMaxNaklad(Format('%.2d', [MonthOfTheYear(Now)])), Now);

     //���������� ����� ��������� - NAKLAD.DAT
     while not Form1.tblZakaz.Eof
      do
        begin
           if (Form1.tblZakaz.FieldByName('zdStatus').AsInteger = 1) and (Form1.tblZakaz.FieldByName('zdAutoCount').AsInteger > 0) then
           begin
             if strTmpZakazID <> form1.tblZakaz.FieldByName('ID').AsString then
              begin
                Form1.qrySumNaklad.Close;
                Form1.qrySumNaklad.SQL.Clear;
                Form1.qrySumNaklad.SQL.Add('select sum(zdPriceNDS * zdAutocount) as SumNakl'
                + ' from tmp_dbZakazFull'
                + ' where id= '
                + Form1.tblZakaz.FieldByName('ID').AsString);
//                    +  Form1.tblZakaz.FieldByName('ID').AsString + ' as SumNakl');
                Form1.qrySumNaklad.Open;
                intInvoiceNum := intInvoiceNum + 1;
                intNaklNum := intNaklNum + 1;

                {�������� ������ ��������� �� ������������ �������}
                strNaklNum := getNaklStr(intNaklNum);
                chrFirstNumSymb := strNaklNum[4];
                chrLastNumSymb := strNaklNum[7];
                if (chrFirstNumSymb in ['a' .. 'z']) and (chrLastNumSymb = '0') then
                  intNaklNum := intNaklNum + 1;

                {�������� ������ �����-������� �� ������������ �������}
                strNaklNum := getNaklStr(intInvoiceNum);
                chrFirstNumSymb := strNaklNum[4];
                chrLastNumSymb := strNaklNum[7];
                if (chrFirstNumSymb in ['a' .. 'z']) and (chrLastNumSymb = '0') then
                  intInvoiceNum := intInvoiceNum + 1;

                strTmpZakazID := Form1.tblZakaz.FieldByName('ID').AsString;
                WriteLog('������� ��������� �' + IntToStr(intNaklNum) + ' ' + '�� ������ '+ strTmpZakazID);
                Form1.clrnTable.Insert;
                Form1.clrnTable.FieldValues['SUMMA'] := Form1.qrySumNaklad.fieldbyname('SumNakl').AsCurrency;
                Form1.clrnTable.FieldValues['SUMMA_SRC'] := Form1.qrySumNaklad.fieldbyname('SumNakl').AsCurrency;
                Form1.clrnTable.FieldValues['MONTH'] := Format('%.2d', [MonthOfTheYear(Now)]);
                Form1.clrnTable.FieldValues['NUMBER'] := Copy(getNaklStr(intNaklNum), 4, 4);
                Form1.clrnTable.FieldValues['INV_NUMBER'] := Copy(getNaklStr(intInvoiceNum), 4, 4);
                Form1.clrnTable.FieldValues['DATE'] :=
                  Trunc(Now) - Trunc(EncodeDate(1899,12,30));
                                Form1.clrnTable.FieldValues['TIME'] := Trunc(GetTickCount/10);
                Form1.clrnTable.FieldValues['OTGRUZKA'] :=
                  Trunc(Form1.tblZakaz.FieldByName('zhDateTo').AsDateTime) - Trunc(EncodeDate(1800,12,28));
                Form1.clrnTable.FieldValues['SROK_OPLAT'] :=
                  Trunc(Form1.tblZakaz.FieldByName('zhDateTo').AsDateTime) - Trunc(EncodeDate(1800,12,28));
                Form1.clrnTable.FieldValues['BUYER'] :=
                  Form1.tblZakaz.FieldByName('buyName').AsString;
                Form1.clrnTable.FieldValues['GROUP_BUY'] :=
                  Form1.tblZakaz.FieldByName('buyGroup').AsInteger;
                Form1.clrnTable.FieldValues['CODE_BUY'] :=
                  Copy(Form1.tblZakaz.FieldByName('buyCode').AsString, Length(Form1.tblZakaz.FieldByName('buyCode').AsString) - 3, 4);
                Form1.clrnTable.FieldValues['DELIVERY'] :=
                  Form1.tblZakaz.FieldByName('zhIsDost').AsInteger;
                //Form1.clrnTable.FieldByName('PRIM').AsString :=
                  //Form1.tblZakaz.FieldByName('zhMemo').AsString;
                Form1.clrnTable.FieldByName('VENDOR').AsString := '�-������';
                Form1.clrnTable.FieldByName('CODE_VEN').AsInteger := 1;
                Form1.clrnTable.FieldByName('CURR').AsInteger := 1;
                Form1.clrnTable.FieldByName('TYPE_ROUND').AsInteger := 0;
                Form1.clrnTable.FieldByName('STEP_ROUND').AsFloat := 0.1;
                Form1.clrnTable.FieldByName('CODE_OPER').AsInteger :=
                  Form1.tblZakaz.FieldByName('zhOperator').AsInteger;
                Form1.clrnTable.FieldByName('CODE_MANAG').AsInteger :=
                  Form1.tblZakaz.FieldByName('zhAgent').AsInteger;
                Form1.clrnTable.Post;
              end;
           intSlashPos := AnsiPos('\', Form1.tblZakaz.FieldByName('gooStrID').AsString);
           Form1.clrnRecBuy.Insert;
           Form1.clrnRecBuy.FieldValues['CODE_PRO'] := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, 1,intSlashPos - 1);
           Form1.clrnRecBuy.FieldValues['PART'] := Form1.tblZakaz.FieldByName('gooProPart').AsInteger mod 10000;
           Form1.clrnRecBuy.FieldValues['ARTIKUL'] := Copy(Form1.tblZakaz.FieldByName('gooStrID').AsString, intSlashPos, 8);
           Form1.clrnRecBuy.FieldValues['DATE'] :=
               Trunc(Now) - Trunc(EncodeDate(1899,12,30));
           Form1.clrnRecBuy.FieldValues['MONTH'] := Format('%.2d', [MonthOfTheYear(Now)]);
           Form1.clrnRecBuy.FieldValues['NUMBER'] := Copy(getNaklStr(intNaklNum), 4, Length(getNaklStr(intNaklNum)));
           Form1.clrnRecBuy.FieldValues['SEL_BUY'] := 1;
           Form1.clrnRecBuy.FieldValues['QUANT'] := Form1.tblZakaz.FieldByName('zdAutoCount').AsInteger;
           Form1.clrnRecBuy.FieldValues['QUANT_SRC'] := Form1.tblZakaz.FieldByName('zdAutoCount').AsInteger;
           Form1.clrnRecBuy.FieldValues['CURR'] := 1;
           Form1.clrnRecBuy.FieldValues['PRICE'] := Form1.tblZakaz.FieldByName('zdPriceNDS').AsCurrency;
           Form1.clrnRecBuy.FieldValues['GOODS_GR'] := Form1.tblZakaz.FieldByName('gooProID').AsString;
           Form1.clrnRecBuy.Post;
           WriteLog('� ��������� ' + getNaklStr(intNaklNum) + ' ��������� ������ ' + Form1.tblZakaz.FieldByName('gooStrID').AsString
               + ' ����������: ' + Form1.tblZakaz.FieldByName('zdAutoCount').AsString + ' ����: ' + Form1.tblZakaz.FieldByName('zdPriceNDS').AsString);
           
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zhLPDoc').AsInteger := intNaklNum;
           Form1.tblZakaz.Post;
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zhIsAuto').AsInteger := 2;
           Form1.tblZakaz.Post;
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zdIDNakl').AsInteger := intNaklNum;
           Form1.tblZakaz.Post;
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zdStatus').AsInteger := 2;
           Form1.tblZakaz.Post;
           end;
          Form1.tblZakaz.Next;
        end;
     Form1.tblZakaz.First;
     while not Form1.tblZakaz.Eof do
      begin
        Form1.qrySumNaklad.Close;
        Form1.qrySumNaklad.SQL.Clear;
        Form1.qrySumNaklad.SQL.Add('select sum(zdPriceNDS * zdAutocount) as SumNakl'
                + ' from tmp_dbZakazFull'
                + ' where id= '
                + Form1.tblZakaz.FieldByName('ID').AsString);
//                    +  Form1.tblZakaz.FieldByName('ID').AsString + ' as SumNakl');
        Form1.qrySumNaklad.Open;
        //ShowMessage(Form1.qrySumNaklad.fieldbyname('SumNakl').AsString);
        if Form1.qrySumNaklad.fieldbyname('SumNakl').AsCurrency = 0 then
          begin
           //ShowMessage('������� �����!');
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zhIsAuto').AsInteger := -1;
           Form1.tblZakaz.Post;
           Form1.tblZakaz.Edit;
           Form1.tblZakaz.FieldByName('zhLPdoc').AsInteger := -1;
           Form1.tblZakaz.Post;
          end;
        Form1.tblZakaz.Next;  
      end;

     WriteLog('****************������������ ��������� ���������************************');
     Form1.clrnTable.Close;
     Form1.clrnRecBuy.Close;
end;

procedure RebuildKeys;
var
  strCfilCommand: string;
  strCfilParam : string;
  strRec_BuyDir : string;
begin
  WriteLog('***********************����������� ������***********************************');
  strClarionDBRoot := File_ini.ReadString('ClarionDB', 'ClarionDRoot', 'default value');

  //������� ����������� �������
  strCfilCommand := strClarionDBRoot + 'dat\cfil.exe';

  //��������� ����������� naklad.dat
  strCfilParam := strClarionDBRoot + 'FILES.DEF\naklad.CLA NAKLAD ' + strClarionDBRoot + 'dat\naklad.dat ' + strClarionDBRoot + 'dat\naklad.dat';
  //����������� ������ naklad.dat
  ShellExecute(Form1.Handle, 'open', PChar(strCfilCommand),PChar(strCfilParam),'',SW_SHOWNORMAL);

  //��������� ����������� rec_buy.dat
  strRec_BuyDir := strClarionDBRoot + 'dat\' + Format('%.5d', [MonthOfTheYear(Now)]);
  strCfilParam := strClarionDBRoot + 'FILES.DEF\rec_buy.CLA REC_BUY rec_buy.dat rec_buy.dat';
  //����������� ������ rec_buy.dat
  ShellExecute(Form1.Handle, 'open', PChar(strCfilCommand),PChar(strCfilParam),PChar(strRec_BuyDir),SW_SHOWNORMAL);

  //��������� ����������� ������ STOR.DAT
  //strCfilParam := strClarionDBRoot + 'FILES.DEF\stor.CLA stor ' + strClarionDBRoot + 'dat\stor.dat ' + strClarionDBRoot + 'dat\stor.dat';
  //����������� ������ stor.dat
  //ShellExecute(Form1.Handle, 'open', PChar(strCfilCommand),PChar(strCfilParam),PChar(strRec_BuyDir),SW_SHOWNORMAL);

  //��������� ����������� ������ PLATEG.DAT
  //strCfilParam := strClarionDBRoot + 'FILES.DEF\PLATEG.CLA PLATEG ' + strClarionDBRoot + 'dat\plateg.dat ' + strClarionDBRoot + 'dat\plateg.dat';
  //����������� ������ PLATEG.DAT
  //ShellExecute(Form1.Handle, 'open', PChar(strCfilCommand),PChar(strCfilParam),PChar(strRec_BuyDir),SW_SHOWNORMAL);
  
  WriteLog('***********************����������� ������ ���������*************************');
end;

procedure TmpZakazUpload();
begin
  WriteLog('*******************�������� ��������� ������� � �������*******************');
     Form1.qryTmpZakazUpload.Close;
     Form1.qryTmpZakazUpload.ExecSQL;
  WriteLog('*******************�������� ��������� ������� � ������� ���������*********');   
end;

procedure TmpZakazInsert();
begin
  WriteLog('*******************���������� ��������� �������***************************');
    Form1.qryTmpZakazInsert.Close;
    Form1.qryTmpZakazInsert.ExecSQL;
  WriteLog('*******************���������� ��������� ������� ���������*****************');
end;

procedure TForm1.FormCreate(Sender: TObject);
var i : Integer; //���������� �����
begin
  File_ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'OrderAuto.ini');
  SqlConnectionStr := File_ini.ReadString('SQL', 'SqlConnectionStr', 'default value');
  SqlTbl := File_ini.ReadString('SQL', 'SqlTbl', 'default value');
  WriteLog('*************************������ ������ ���������*************************');
  conSysSql.ConnectionString := SqlConnectionStr;
  conSysSql.Connected := True;
  TmpZakazInsert();
  WriteLog('*************************����������� � �����*****************************;');
  tblZakaz.Connection := conSysSql;
  tblZakaz.TableName := SqlTbl;
  //tblZakaz.CursorLocation := clUseServer;
  try
    tblZakaz.Open;
    WriteLog('������� ������� �������');
//    tblZakaz.Sort := 'ID';
//    WriteLog('������� ������� �������������');
  except
    on E : Exception do
      begin
        WriteLog('�� ������� ������������ � ������� SQL');
        WriteLog('������: ' + E.Message);
        WriteLog('������ ��������� ��������� ��������');
        ExitProcess(1);
      end;
   end;
  if ParamStr(1) = '1' then
    StorCorrection ()
  else
  if ParamStr(1) = '2' then
    begin
      CreateNaklad();
      RebuildKeys();
    end
  else
  if ParamStr(1) = '3' then
    RebuildKeys()
  else
  if ParamStr(1) = '4' then
    begin
      StorCorrection();
      CreateNaklad();
      RebuildKeys();
    end
  else
    begin
      WriteLog('****************��������� �������� ��� ����������******************');
    end;

  TmpZakazUpload();
    WriteLog('****************������ ��������� ���������************************');
  Application.Terminate;
end;

end.
