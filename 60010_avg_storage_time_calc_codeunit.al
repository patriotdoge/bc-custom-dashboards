// ============================================================
// Codeunit 60010 — R002 Average Storage Time
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Formula:
//   Avg Stock Value      = (Opening Stock Value + Closing Stock Value) / 2
//   Inventory Turnover   = COGS / Avg Stock Value
//   Avg Storage Time     = Period Days / Inventory Turnover
//
// Opening/Closing Stock : Value Entry cumulative to date
//                         Locations: STOCK|QR|NC|FR*
//                         Include Expected Cost = ON
//
// COGS                  : Value Entry Sales entries in period
//                         Excl. Item No. starts with 'SA'
//                         Excl. Description contains 'Refurbished'
//                         = SUM(Control44) - SUM(Control46)
//                           from Customer/Item Sales report
// ============================================================

codeunit 60010 "LOG Avg Storage Time Calc"
{
    var
        LocationFilter: Text;

    procedure CalcAvgStorageTime(StartDate: Date; EndDate: Date): Decimal
    var
        OpeningStock: Decimal;
        ClosingStock: Decimal;
        AvgStock: Decimal;
        COGS: Decimal;
        TurnoverRate: Decimal;
        PeriodDays: Integer;
        AvgStorageDays: Decimal;
    begin
        LocationFilter := 'STOCK|QR|NC|FR*';

        PeriodDays   := EndDate - StartDate + 1;
        OpeningStock := CalcStockValue(StartDate);
        ClosingStock := CalcStockValue(EndDate);
        AvgStock     := (OpeningStock + ClosingStock) / 2;
        COGS         := CalcCOGS(StartDate, EndDate);

        if (AvgStock = 0) or (PeriodDays = 0) or (COGS = 0) then
            exit(0);

        TurnoverRate   := COGS / AvgStock;
        AvgStorageDays := Round(PeriodDays / TurnoverRate, 1);
        exit(AvgStorageDays);
    end;

    // ----------------------------------------------------------
    // Steps 1-5: Stock Value at a given date
    // Source: Value Entry
    //   Locations : STOCK, QR, NC, FR*
    //   Valuation : Cost Amount (Actual) + Cost Amount (Expected)
    //   Mirrors   : EndingExpectedValue from Inventory Valuation report
    //               with Include Expected Cost = ON
    // ----------------------------------------------------------
    local procedure CalcStockValue(AsOfDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        StockValue: Decimal;
    begin
        StockValue := 0;

        ValueEntry.SetFilter("Location Code", LocationFilter);
        ValueEntry.SetFilter("Posting Date", '..%1', AsOfDate);
        ValueEntry.SetFilter("Item Ledger Entry Type", '<>%1',
                             ValueEntry."Item Ledger Entry Type"::Transfer);

        if ValueEntry.FindSet() then
            repeat
                StockValue += ValueEntry."Cost Amount (Expected)" +
                              ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next() = 0;

        exit(StockValue);
    end;

    // ----------------------------------------------------------
    // Steps 7-11: Cost of Goods Sold
    // Source: Value Entry (Entry Type = Sale)
    //   Period     : StartDate..EndDate
    //   Exclusion 1: Item No. starts with 'SA'          (step 9)
    //   Exclusion 2: Item Description contains
    //                'Refurbished' (case-insensitive)   (step 10)
    //   Calculation: SUM(Control44) - SUM(Control46)
    //                = Sales Amount Actual - Profit
    //                = Abs(Cost Amount (Actual))
    // ----------------------------------------------------------
    local procedure CalcCOGS(StartDate: Date; EndDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        COGS: Decimal;
    begin
        COGS := 0;

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetFilter("Posting Date", '%1..%2', StartDate, EndDate);

        if ValueEntry.FindSet() then
            repeat
                // Exclusion 1 — SA* items
                if StrPos(ValueEntry."Item No.", 'SA') <> 1 then begin
                    // Exclusion 2 — Refurbished items; include if description can't be found
                    Item.Init();
                    if not Item.Get(ValueEntry."Item No.") or
                       (StrPos(UpperCase(Item.Description), 'REFURBISHED') = 0)
                    then
                        COGS += Abs(ValueEntry."Cost Amount (Actual)");
                end;
            until ValueEntry.Next() = 0;

        exit(COGS);
    end;

    // ----------------------------------------------------------
    // Convenience: full breakdown for drill-down page
    // ----------------------------------------------------------
    procedure GetStorageBreakdown(StartDate: Date; EndDate: Date;
                                   var OpenStock: Decimal; var CloseStock: Decimal;
                                   var COGS: Decimal; var TurnoverPct: Decimal)
    begin
        LocationFilter := 'STOCK|QR|NC|FR*';
        OpenStock      := CalcStockValue(StartDate);
        CloseStock     := CalcStockValue(EndDate);
        COGS           := CalcCOGS(StartDate, EndDate);

        if ((OpenStock + CloseStock) / 2) <> 0 then
            TurnoverPct := Round((COGS / ((OpenStock + CloseStock) / 2)) * 100, 0.01)
        else
            TurnoverPct := 0;
    end;
}
