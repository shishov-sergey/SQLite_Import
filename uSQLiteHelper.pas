unit uSQLiteHelper;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}

interface

uses
  sqlite3dyn, SysUtils, Classes, sqlite3conn, sqldb, db, uTypes;

type
  TSQLiteHelper = class
  private
    FConn: TSQLite3Connection;
    FTrans: TSQLTransaction;
    FQuery: TSQLQuery;
  public
    constructor Create(const DBPath: string);
    destructor Destroy; override;
    procedure CreateTable;
    function ExportToMemory: TCountryArray;
    procedure ImportFromArray(const Data: TCountryArray);
    procedure ClearTable;
  end;

implementation

{ TSQLiteHelper }

constructor TSQLiteHelper.Create(const DBPath: string);
begin
  inherited Create;
  FConn := TSQLite3Connection.Create(nil);
  FTrans := TSQLTransaction.Create(nil);
  FQuery := TSQLQuery.Create(nil);
  FConn.CharSet := 'UTF8';
  FConn.DatabaseName := ExtractFileName(DBPath);
  FConn.Transaction := FTrans;
  FQuery.Database := FConn;
  FQuery.Transaction := FTrans;
  FQuery.SQLConnection := FConn;
  FQuery.SQL.Text := 'select * from countries_world';
  FConn.Connected := True;
end;

destructor TSQLiteHelper.Destroy;
begin
  FQuery.Free;
  FTrans.Free;
  FConn.Free;
  inherited Destroy;
end;

procedure TSQLiteHelper.CreateTable;
var
  Query: TSQLQuery;
begin
  if not Assigned(FConn) then
    raise Exception.Create('Connection is nil');

  if not FConn.Connected then
    FConn.Open;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FConn;
    if FConn.Transaction = nil then
    begin
      FConn.Transaction := TSQLTransaction.Create(nil);
      FConn.Transaction.DataBase := FConn;
    end;

    Query.SQL.Text := 'CREATE TABLE IF NOT EXISTS countries_world (' +
                      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                      'country TEXT NOT NULL, ' +
                      'capital TEXT NOT NULL, ' +
                      'area REAL, ' +
                      'population INTEGER)';

    Query.ExecSQL;
    if FConn.Transaction.Active then
      FConn.Transaction.Commit;
  except
    on E: Exception do
    begin
      if FConn.Transaction.Active then
        FConn.Transaction.Rollback;
      raise;
    end;
  end;
end;

function TSQLiteHelper.ExportToMemory: TCountryArray;
var
  I, Count: Integer;
begin
  FQuery.PacketRecords := -1;
  FQuery.SQL.Text := 'SELECT country, capital, area, population FROM countries_world';
  FQuery.Open;
  Count := FQuery.RecordCount;
  SetLength(Result, Count);
  I := 0;
  while not FQuery.EOF do
  begin
    Result[I].Country := FQuery.Fields[0].AsString;//.FieldByName('country').AsString;
    Result[I].Capital := FQuery.FieldByName('capital').AsString;
    Result[I].Area := FQuery.FieldByName('area').AsFloat;
    Result[I].Population := FQuery.FieldByName('population').AsInteger;
    Inc(I);
    FQuery.Next;
  end;
  FQuery.Close;
end;

procedure TSQLiteHelper.ImportFromArray(const Data: TCountryArray);
var
  I: Integer;
begin
  if not FConn.Transaction.Active then
    FTrans.StartTransaction;
  try
    for I := 0 to High(Data) do
    begin
      FQuery.SQL.Text :=
        'INSERT INTO countries_world (country, capital, area, population) ' +
        'VALUES (:country, :capital, :area, :population)';
      FQuery.ParamByName('country').AsString := Data[I].Country;
      FQuery.ParamByName('capital').AsString := Data[I].Capital;
      FQuery.ParamByName('area').AsFloat := Data[I].Area;
      FQuery.ParamByName('population').AsInteger := Data[I].Population;
      FQuery.ExecSQL;
    end;
    if FConn.Transaction.Active then
      FTrans.Commit;
  except
    if FConn.Transaction.Active then
      FTrans.Rollback;
    raise;
  end;
end;

procedure TSQLiteHelper.ClearTable;
begin
  if not FConn.Transaction.Active then
    FTrans.StartTransaction;
  FConn.ExecuteDirect('DELETE FROM countries_world');
  if FConn.Transaction.Active then
    FTrans.Commit;
end;

end.
