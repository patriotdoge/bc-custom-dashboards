// ============================================================
// Page 60020 — Average Storage Time Drill-Down
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Card page showing every intermediate value used in the
// R002 formula so the logistics team can validate the result
// against the manual Excel calculation.
//
// Groups mirror the manual workflow sections:
//   Period → Stock Values → COGS → Result
// ============================================================

page 60020 "LOG Storage Drill-Down"
{
    PageType        = Card;
    Caption         = 'Avg. Storage Time — Calculation Detail';
    Editable        = false;
    UsageCategory   = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(PeriodGroup)
            {
                Caption = 'Period';

                field(StartDateDisp; StartDate)
                {
                    ApplicationArea = All;
                    Caption         = 'From';
                }
                field(EndDateDisp; EndDate)
                {
                    ApplicationArea = All;
                    Caption         = 'To';
                }
                field(PeriodDaysDisp; PeriodDays)
                {
                    ApplicationArea = All;
                    Caption         = 'Period Days';
                }
            }

            group(StockGroup)
            {
                Caption = 'Stock Values  (Locations: STOCK · QR · NC · FR*)';

                field(OpeningStockDisp; OpeningStock)
                {
                    ApplicationArea = All;
                    Caption         = 'Opening Stock Value (€)';
                }
                field(ClosingStockDisp; ClosingStock)
                {
                    ApplicationArea = All;
                    Caption         = 'Closing Stock Value (€)';
                }
                field(AvgStockDisp; AvgStock)
                {
                    ApplicationArea = All;
                    Caption         = 'Average Stock Value (€)';
                    Style           = Strong;
                }
            }

            group(COGSGroup)
            {
                Caption = 'Cost of Goods Sold  (excl. SA* items and Refurbished)';

                field(COGSDisp; COGS)
                {
                    ApplicationArea = All;
                    Caption         = 'COGS (€)';
                }
            }

            group(ResultGroup)
            {
                Caption = 'Result';

                field(TurnoverRateDisp; TurnoverPct)
                {
                    ApplicationArea = All;
                    Caption         = 'Inventory Turnover Rate (%)';
                }
                field(AvgStorageDisp; AvgDays)
                {
                    ApplicationArea = All;
                    Caption         = 'Average Storage Time (days)';
                    Style           = Strong;
                }
            }
        }
    }

    var
        StartDate: Date;
        EndDate: Date;
        PeriodDays: Integer;
        OpeningStock: Decimal;
        ClosingStock: Decimal;
        AvgStock: Decimal;
        COGS: Decimal;
        TurnoverPct: Decimal;
        AvgDays: Decimal;

    procedure SetDateFilter(NewStartDate: Date; NewEndDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate   := NewEndDate;
    end;

    trigger OnOpenPage()
    var
        StorageCalc: Codeunit "LOG Avg Storage Time Calc";
    begin
        if StartDate = 0D then
            StartDate := CalcDate('<-CM>', Today());
        if EndDate = 0D then
            EndDate := Today();
        PeriodDays := EndDate - StartDate + 1;

        StorageCalc.GetStorageBreakdown(StartDate, EndDate,
                                         OpeningStock, ClosingStock, COGS, TurnoverPct);
        AvgStock := (OpeningStock + ClosingStock) / 2;
        AvgDays  := StorageCalc.CalcAvgStorageTime(StartDate, EndDate);
    end;
}
