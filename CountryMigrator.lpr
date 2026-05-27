program CountryMigrator;
{$MODE DELPHIUNICODE}
{$CODEPAGE UTF8}
{$APPTYPE CONSOLE}

uses
  SysUtils, Classes,
  uTypes in 'uTypes.pas',
  uSQLiteHelper in 'uSQLiteHelper.pas',
  uCSVHelper in 'uCSVHelper.pas',
  uJSONHelper in 'uJSONHelper.pas',
  uMigrationThread in 'uMigrationThread.pas';

var
  DBPath, CSVPath, JSONPath: string;
  SQLite: TSQLiteHelper;
  Choice: Char;
  Thread: TMigrationThread;
  Finished: Boolean;

procedure PrintMenu;
begin
  Writeln('=== Миграция данных: Страны мира ===');
  Writeln('1. Экспорт в CSV');
  Writeln('2. Экспорт в JSON');
  Writeln('3. Импорт из CSV');
  Writeln('4. Импорт из JSON');
  Writeln('0. Выход');
  Write('Выбор: ');
end;

procedure OnProgress(const Msg: string; const pg_type: TProgressType);
begin
  case pg_type of
    TProgressType.ptProgress:
      Writeln('[LOG] ', Msg);
    TProgressType.ptError:
      Writeln('[ERROR] ', Msg);
    TProgressType.ptComplete:
      begin
        Writeln('[COMPLETE] ', msg);
        Finished := True;
      end;
  end;
end;

begin
  try
    DBPath := ExtractFilePath(ParamStr(0)) + 'countries.db';
    CSVPath := ExtractFilePath(ParamStr(0)) + 'countries.csv';
    JSONPath := ExtractFilePath(ParamStr(0)) + 'countries.json';

    SQLite := TSQLiteHelper.Create(DBPath);
    try
      SQLite.CreateTable;
    finally
      SQLite.Free;
    end;
    repeat
      PrintMenu;
      Readln(Choice);
      Finished := False;

      case Choice of
        '1': Thread := TMigrationThread.Create(mmExportCSV, DBPath, CSVPath, OnProgress);
        '2': Thread := TMigrationThread.Create(mmExportJSON, DBPath, JSONPath, OnProgress);
        '3': Thread := TMigrationThread.Create(mmImportCSV, DBPath, CSVPath, OnProgress);
        '4': Thread := TMigrationThread.Create(mmImportJSON, DBPath, JSONPath, OnProgress);
        '0': Break;
      else
        Writeln('Неверный выбор.');
        Continue;
      end;

      if Choice in ['1'..'4'] then
      begin
        Thread.Start;
        while not Finished do Sleep(50);
      end;
      Writeln;
    until False;

    Writeln('Программа завершена.');
  except
    on E: Exception do
      Writeln('Критическая ошибка: ', E.Message);
  end;
end.
