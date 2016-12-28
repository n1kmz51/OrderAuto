(*
**         Clarion Toolkit v2
** Copyright (C) by Dmitry Kudryavtsev
**       Volgograd, RUSSIA, 2000
** juliasoft@mail.ru, FIDO: 2:5055/24
*)

{ Clarion Type Definition Module }

{$A-$X+$Z1}

Unit ClDb2;

interface
(*
  1) The file header
  2) Field description
  3) Key and index descriptors
  4) Picture descriptors
  5) Array descriptors
  6) Data
  7) Memo
*)

type
  Char256 = Array [1..256] of Char;
  Char252 = Array [1..252] of Char;
  Char16  = Array [1..16] of Char;
  Char12  = Array [1..12] of Char;
  Char3   = Array [1..3] of Char;

const
  DELTA_DAYS = 36161;    (* For fast DATE conversion *)
  DELTA_DAYS2 = 657433;  (* For fast DATE conversion *)

(***** 1) THE FILE HEADER *****)

const
  SIGN_LOCKED     =   1; (* bit 0 - file is locked          *)
  SIGN_OWNED      =   2; (* bit 1 - file is owned           *)
  SIGN_ENCRYPTED  =   4; (* bit 2 - records are encrypted   *)
  SIGN_MEMO       =   8; (* bit 3 - memo file exists        *)
  SIGN_COMPRESSED =  16; (* bit 4 - file is compressed      *)
  SIGN_RECLAIM    =  32; (* bit 5 - reclaim deleted records *)
  SIGN_READONLY   =  64; (* bit 6 - file is read only       *)
  SIGN_CREATED    = 128; (* bit 7 - file may be created     *)

  VERSION_21_SIG  = $3343;

type
  PHeader = ^THeader;
  THeader = packed record
    FileSIG  : Word;    (* file signature            *)
    SFAtr    : Word;    (* file attribute and status *)

    NumKeys  : Byte;    (* number of keys in file      *)
    NumRecs  : Integer; (* number of records in file   *)
    NumDels  : Integer; (* number of deleted records   *)
    NumFlds  : Word;    (* number of fields            *)
    NumPics  : Word;    (* number of pictures          *)
    NumArrs  : Word;    (* number of array descriptors *)

    RecLen   : Word;    (* record length (including record header) *)

    Offset   : Integer; (* start of data area          *)
    LogEOF   : Integer; (* logical end of file         *)
    LogBOF   : Integer; (* logical beginning of file   *)
    FreeRec  : Integer; (* first usable deleted record *)

    RecName  : Char12;  (* record name without prefix *)
    MemName  : Char12;  (* memo name without prefix   *)
    FilPrefx : Char3;   (* file name prefix           *)
    RecPrefx : Char3;   (* record name prefix         *)

    MemoLen  : Word;    (* size of memo         *)
    MemoWid  : Word;    (* column width of memo *)

    LockCont : Integer; (* Lock Count *)

    ChgTime  : Integer; (* time of last change *)
    ChgDate  : Integer; (* date of last change *)

    CheckSum : Word;    (* checksum for encrypt *)
  end; (* TDatHeader *)

(***** 2) THE FIELD DESCRIPTORS *****)

const
  FLD_LONG    = 1;
  FLD_REAL    = 2;
  FLD_STRING  = 3;
  FLD_PICTURE = 4;
  FLD_BYTE    = 5;
  FLD_SHORT   = 6;
  FLD_GROUP   = 7;
  FLD_DECIMAL = 8;

type
  PFieldRecord = ^TFieldRecord;
  TFieldRecord = packed record
    FldType : Byte;   (* type of field *)

    FldName : Char16; (* name of field *)

    FOffset : Word;   (* offset into record *)
    Length  : Word;   (* length of field    *)
    DecSig  : Byte;   (* significance for decimals *)
    DecDec  : Byte;   (* number of decimal places  *)
    ArrNum  : Word;   (* array number   *)
    PicNum  : Word;   (* picture number *)
  end;

(***** 3) KEY AND INDEX DESCRIPTORS *****)

type
  PKeyRecord = ^TKeyRecord;
  TKeyRecord = packed record
    NumComps : Byte;   (* number of components for key *)
    KeyNams  : Char16; (* name of this key    *)
    CompType : Byte;   (* type of composite   *)
    CompLen  : Byte;   (* length of composite *)
  end;

  PKeyItem = ^TKeyItem;
  TKeyItem = packed record
    FldType : Byte; (* type of field *)
    FldNum  : Word; (* field number  *)
    ElmOff  : Word; (* record offset of this element *)
    ElmLen  : Byte; (* length of element *)
  end;

(***** 4) PICTURE DESCRIPTORS *****)

type
  PPictureRecord = ^TPictureRecord;
  TPictureRecord = packed record
    PicLen : Word;
    PicStr : Char256;
  end;

(***** 5) ARRAY DESCRIPTORS *****)

type
  PArrayRecord = ^TArrayRecord;
  TArrayRecord = packed record
    NumDim : Word; (* dims for current field         *)
    TotDim : Word; (* total number of dims for field *)
    ElmSiz : Word; (* total size of current field    *)
                   (* Array Of TArrayPart's          *)
  end;

  PArrayItem = ^TArrayItem;
  TArrayItem = packed record
    MaxDim : Word; (* number of dims for array part *)
    LenDim : Word; (* length of field *)
  end;

(***** 6) DATA *****)

const
  DATA_NEW =  1; (* bit 0 - new record     *)
  DATA_OLD =  2; (* bit 1 - old record     *)
  DATA_REV =  4; (* bit 2 - revised record *)
  DATA_DEL = 16; (* bit 4 - deleted record *)
  DATA_HLD = 64; (* bit 6 - record held    *)

type
  PDataHeader = ^TDataHeader;
  TDataHeader = packed record
    RHd  : Byte;    (* record header type and status *)
    RPtr : Integer; (* pointer for next deleted record or memo if active *)
  end;

(***** 7) MEMO *****)

const
  MEMO_21_SIG = $334D;

type
  PMemoHeader = ^TMemoHeader;
  TMemoHeader = record
    MemoSIG : Word;      (* memo signature           *)
    FirstDel : Integer;  (* first deleted memo block *)
  end;

  PMemoData = ^TMemoData;
  TMemoData = record
    NextBlock : Integer; (* next block for this memo *)
    Memo : Char252;      (* memo text                *)
  end;

implementation

end.