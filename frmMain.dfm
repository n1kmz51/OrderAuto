object Form1: TForm1
  Left = 1539
  Top = 331
  Width = 254
  Height = 218
  Caption = 'frmMain'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object conSysSql: TADOConnection
    CursorLocation = clUseServer
    Left = 16
    Top = 16
  end
  object tblZakaz: TADOTable
    Connection = conSysSql
    Left = 80
    Top = 16
  end
  object clrnTable: TClarionDataSet
    ReadOnly = False
    Exclusive = False
    OemConvert = False
    BlobToCache = False
    Left = 144
    Top = 16
  end
  object clrnRecBuy: TClarionDataSet
    ReadOnly = False
    Exclusive = False
    OemConvert = False
    BlobToCache = False
    Left = 200
    Top = 16
  end
  object qrySumNaklad: TADOQuery
    Connection = conSysSql
    Parameters = <>
    Left = 144
    Top = 72
  end
  object qryTmpZakazInsert: TADOQuery
    Connection = conSysSql
    Parameters = <>
    SQL.Strings = (
      'delete from tmp_dbZakazFull'
      ''
      'INSERT INTO tmp_dbZakazFull'
      ''
      
        'SELECT     dbo.dbZakazHead.ID, dbo.dbZakazHead.zhDate, dbo.dbZak' +
        'azHead.zhFirmYr, dbo.dbZakazHead.zhFirmTT, '
      
        '                      dbo.dbZakazHead.zhLPdoc, dbo.dbZakazHead.z' +
        'hIsDost, dbo.dbZakazHead.zhMemo, dbo.dbZakazHead.zhSkidka, dbo.d' +
        'bZakazHead.zhIsAuto, dbo.dbZakazData.zdCodeLP, '
      
        '                      dbo.dbLP_Goods.gooStrID, dbo.dbLP_Goods.go' +
        'oArtikul, dbo.dbZakazData.zdPriceNDS, dbo.dbZakazData.zdCount, d' +
        'bo.dbZakazData.zdAutoCount, '
      
        '                      dbo.dbZakazData.zdIDnakl, dbo.dbZakazData.' +
        'zdStatus, dbo.dbLP_Buyer.buyName, dbo.dbLP_Buyer.buyGroup, dbo.d' +
        'bLP_Buyer.ID AS buyCode, '
      
        '                      dbo.dbLP_Goods.gooProID, dbo.dbLP_Goods.go' +
        'oProPart, dbo.dbZakazHead.zhDateTo, dbo.dbZakazHead.zhAgent, dbo' +
        '.dbZakazHead.zhOperator'
      ''
      'FROM         dbo.dbZakazHead INNER JOIN'
      
        '                      dbo.dbZakazData ON dbo.dbZakazHead.ID = db' +
        'o.dbZakazData.zdIDhead INNER JOIN'
      
        '                      dbo.dbLP_Goods ON dbo.dbZakazData.zdCodeLP' +
        ' = dbo.dbLP_Goods.ID INNER JOIN'
      
        '                      dbo.dbFirmYr ON dbo.dbZakazHead.zhFirmYr =' +
        ' dbo.dbFirmYr.ID INNER JOIN'
      
        '                      dbo.dbLP_Buyer ON dbo.dbFirmYr.tmpIDlp = d' +
        'bo.dbLP_Buyer.ID'
      'WHERE     (dbo.dbZakazHead.zhIsAuto = 1)'
      'ORDER BY dbo.dbZakazHead.ID')
    Left = 48
    Top = 72
  end
  object qryTmpZakazUpload: TADOQuery
    Connection = conSysSql
    Parameters = <>
    SQL.Strings = (
      'update dbZakazHead'
      
        'set dbZakazHead.zhIsAuto = tH.zhIsAuto, dbZakazHead.zhLPdoc = tH' +
        '.zhLPdoc'
      'from tmp_dbZakazFull as tH'
      'where tH.ID = dbZakazHead.ID and tH.zhLpDoc <> 0'
      ''
      'update dbZakazData'
      
        'set dbZakazData.zdStatus = tD.zdStatus, dbZakazData.zdAutoCount ' +
        '= tD.zdAutoCount,'
      'dbZakazData.zdIDnakl = tD.zdIDnakl'
      'from tmp_dbZakazFull as tD'
      
        'where tD.ID = dbZakazData.zdIDHead and tD.zdCodeLP = dbZakazData' +
        '.zdCodeLP'
      ''
      'UPDATE dbGlobalSetting'
      
        'SET gsNaklFirst = (SELECT MIN (zdIDnakl) FROM tmp_dbZakazFull WH' +
        'ERE zdIDnakl <>0),'
      
        'gsNaklLast = (SELECT MAX (zdIDnakl) FROM tmp_dbZakazFull WHERE z' +
        'dIDnakl <>0)')
    Left = 104
    Top = 136
  end
end
