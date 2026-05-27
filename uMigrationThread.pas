unit uMigrationThread;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, uTypes, uSQLiteHelper, uCSVHelper, uJSONHelper;

type
  TMigrationMode = (mmExportCSV, mmExportJSON, mmImportCSV, mmImportJSON);
  TProgressType = (ptProgress, ptError, ptComplete);
  TStatusProc = procedure(const Msg: string; const pg_type: TProgressType);
  TMigrationThread = class(TThread)
  private
    FMode: TMigrationMode;
    FProgress: TProgressType;
    FDBPath, FFilePath, FMessage: string;
    FOnProgress: TStatusProc;
    procedure DoProgress;
    procedure ProgressMsg(const msg: String; prog: TProgressType = TProgressType.ptProgress);
  protected
    procedure Execute; override;
  public
    constructor Create(AMode: TMigrationMode; const ADBPath, AFilePath: string; AOnProgress: TStatusProc);
  end;

implementation

constructor TMigrationThread.Create(AMode: TMigrationMode; const ADBPath, AFilePath: string; AOnProgress: TStatusProc);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FMode := AMode;
  FDBPath := ADBPath;
  FFilePath := AFilePath;
  FOnProgress := AOnProgress;
end;

procedure TMigrationThread.DoProgress;
begin
  if Assigned(FOnProgress) then FOnProgress(FMessage, FProgress);
end;

procedure TMigrationThread.ProgressMsg(const msg: String; prog: TProgressType = TProgressType.ptProgress);
begin
  FMessage := msg;
  FProgress := prog;
  DoProgress;
end;

procedure TMigrationThread.Execute;
var
  SQLite: TSQLiteHelper;
  Data: TCountryArray;
begin
  try
    ProgressMsg('Инициализация...');
    if not Assigned(SQLite) then
      SQLite := TSQLiteHelper.Create(ExtractFileName(FDBPath));
    try
      case FMode of
        mmExportCSV, mmExportJSON:
          begin
            ProgressMsg('Экспорт из SQLite...');
            Data := SQLite.ExportToMemory;
            ProgressMsg(Format('Найдено записей: %d', [Length(Data)]));
            if FMode = mmExportCSV then
            begin
              ProgressMsg('Сохранение в CSV...');
              TCSVHelper.ExportToFile(FFilePath, Data);
            end
            else
            begin
              ProgressMsg('Сохранение в JSON...');
              TJSONHelper.ExportToFile(FFilePath, Data);
            end;
          end;
        mmImportCSV, mmImportJSON:
          begin
            ProgressMsg('Загрузка из файла...');
            if FMode = mmImportCSV then
              Data := TCSVHelper.ImportFromFile(FFilePath)
            else
              Data := TJSONHelper.ImportFromFile(FFilePath);
            ProgressMsg(Format('Загружено: %d записей', [Length(Data)]));
            ProgressMsg('Очистка таблицы...');
            SQLite.ClearTable;
            ProgressMsg('Импорт в SQLite...');
            SQLite.ImportFromArray(Data);
          end;
      end;
      ProgressMsg('Готово!');
      ProgressMsg('Операция завершена.', TProgressType.ptComplete);
    finally
      SQLite.Free;
    end;
  except
    on E: Exception do
      ProgressMsg(E.Message, TProgressType.ptError);
  end;
end;

end.
