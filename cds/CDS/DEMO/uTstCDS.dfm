object Form1: TForm1
  Left = 192
  Top = 124
  Width = 856
  Height = 503
  Caption = 'Clarion. '#1063#1090#1077#1085#1080#1077' '#1090#1072#1073#1083#1080#1094
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 7
    Top = 52
    Width = 834
    Height = 413
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -10
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object btnOpen: TButton
    Left = 296
    Top = 7
    Width = 89
    Height = 34
    Caption = #1058#1072#1073#1083#1080#1094#1072
    TabOrder = 1
    OnClick = btnOpenClick
  end
  object DBNavigator1: TDBNavigator
    Left = 7
    Top = 7
    Width = 280
    Height = 34
    DataSource = DataSource1
    TabOrder = 2
  end
  object DataSource1: TDataSource
    Left = 24
    Top = 56
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Clarion files|*.dat|All files|*.*'
    Left = 80
    Top = 72
  end
end
