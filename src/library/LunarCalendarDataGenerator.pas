unit LunarCalendarDataGenerator;

interface

uses
  SysUtils,
  hjLunarDateType ,hjLunarDateConverter, CalendarDataGenerator, CalendarCommons;

const
  // 한국 달이름
  LunarKoreanMonthName: array[1..12] of string = (
      '정월', '이월', '삼월', '사월', '오월',   '유월'
    , '칠월', '팔월', '구월', '시월', '동짓달', '섣달'
  );
  LunarKoreanHalfMonth: string      = '보름';
  LunarKoreanEndOfTheMonth: string  = '그믐';

type
  TLunarDispDays = array of word;

  TLunarCalendarSource = class(TCalendarSource)
  private
    FIndex: Integer;
    FDisplayDaysType: TLunarDaysDisplayType;
    FDisplayDays: TLunarDispDays;
  public
    constructor Create(ADispType: TLunarDaysDisplayType);

    procedure First; override;
    function Next: Boolean; override;
    function HasNext: Boolean; override;
    function Day: Word;

    property DisplayDaysType: TLunarDaysDisplayType read FDisplayDaysType;
  end;

  TLunarCalendarDataGenerator = class(TCalendarDataGenerator)
  private
    FCurrentDate: TSolarDateRec;
    FYear,
    FMonthIndex: Word;

    function GetLunarDateRec(AYear: Word; AMonthIndex: Integer; ADay: Word): TLunarDateRec;
    function GetSummury(ADispType: TLunarDaysDisplayType; ALunar: TLunarDateRec): string;
  protected
    procedure Initialize; override;
  public
    function Next: TCalendarData; override;
  end;

implementation

uses
  StrUtils;

{ TLunarCalendarSource }

constructor TLunarCalendarSource.Create(ADispType: TLunarDaysDisplayType);
  procedure SetData(const Args: array of word);
  var
    I: Integer;
  begin
    SetLength(FDisplayDays, Length(Args));
    for I := 0 to Length(Args) - 1 do
      FDisplayDays[I] := Args[I];
  end;
begin
  FDisplayDaysType := ADispType;

  case FDisplayDaysType of
    lddt5:    SetData([1, 5, 10, 15, 20, 25, 99]);
    lddt10:   SetData([1, 10, 20, 99]);
    lddt15:   SetData([1, 15, 99]);
    lddtKor:  SetData([1, 5, 10, 15, 20, 25, 99]);
  end;
end;

function TLunarCalendarSource.Day: Word;
begin
  Result := 0;
  if FIndex < Length(FDisplayDays) then
    Result := FDisplayDays[FIndex];
end;

procedure TLunarCalendarSource.First;
begin
  FIndex := 0;
end;

function TLunarCalendarSource.HasNext: Boolean;
begin
  Result := FIndex < Length(FDisplayDays);
end;

function TLunarCalendarSource.Next: Boolean;
begin
  Inc(FIndex);
end;

{ TLunarCalendarDataGenerate }

function TLunarCalendarDataGenerator.GetSummury(
  ADispType: TLunarDaysDisplayType; ALunar: TLunarDateRec): string;
begin
  case ADispType of
  lddt5..lddt15:
    Result := Format('%s%d.%d', [IfThen(ALunar.IsLeapMonth, '(윤)', ''), ALunar.Month, ALunar.Day]);
  lddtKor:
    begin
      case ALunar.Day of
      1:      Result := IfThen(ALunar.IsLeapMonth, '윤', '') + LunarKoreanMonthName[ALunar.Month];
      15:     Result := '보름';
      5, 10, 20, 25:
        Result := Format('%s%d.%d', [IfThen(ALunar.IsLeapMonth, '(윤)', ''), ALunar.Month, ALunar.Day]);
      else    Result := '그믐';
      end;
    end;
  end;
end;

procedure TLunarCalendarDataGenerator.Initialize;
begin
  FCurrentDate := DateRec(FStartOfRange, 1, 1);

  FYear   := FStartOfRange;
  FMonthIndex  := 1;
end;

function TLunarCalendarDataGenerator.GetLunarDateRec(AYear: Word;
  AMonthIndex: Integer; ADay: Word): TLunarDateRec;
begin
  Result.Year := FYear;

  FLunarDateConvertor.GetLunarMonthFromMonthIndex(FYear, AMonthIndex, Result.Month, Result.IsLeapMonth);

  if ADay > 30 then
    Result.Day := FLunarDateConvertor.GetLunarDaysOfMonth(FYear, Result.Month, Result.IsLeapMonth)
  else
    Result.Day := ADay;
end;

function TLunarCalendarDataGenerator.Next: TCalendarData;
var
  Lunar: TLunarDateRec;
  Solar: TSolarDateRec;
  Source: TLunarCalendarSource;
begin
  Result := nil;

  Source := TLunarCalendarSource(FCalendarSource);

  // Source에 데이터가 없으면 다음달(Month 증가)
  if not Source.HasNext then
  begin
    Inc(FMonthIndex);
    FCalendarSource.First;
  end;

  // Month가 가득차면 Year 증가
  if not FLunarDateConvertor.HasLunarMonthData(FYear, FMonthIndex) then
  begin
    Inc(FYear);
    FMonthIndex := 1;
  end;

  // Year이 FEndOfRange보다 크면 종료
  if FYear > FEndOfRange then
    Exit;

  Lunar := GetLunarDateRec(FYear, FMonthIndex, Source.Day);
  Solar := FLunarDateConvertor.LunarToSolar(Lunar);

  // Source에 Next 요청
  FCalendarData.SetData(Solar, Lunar, GetSummury(Source.DisplayDaysType, Lunar), '');
  Result := FCalendarData;

  Source.Next;
end;

end.
